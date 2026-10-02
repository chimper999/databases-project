# Data Integration and Cleaning (Assignment 4)

This document describes how we integrated the two real-world datasets
(see `data/SOURCES.md`) into the `ai_entry_jobs` database: which schema
constraints the data violated, how we changed the schema, and every cleaning
and transformation step.

## Pipeline

```
data/raw/*.csv  ──►  data/clean_transform.py  ──►  data/clean/*.csv        (cleaned tables, for checking)
                                               ──►  data/clean/cleaning_report.txt (counts for every step)
                                               ──►  sql/07_real_data.sql    (loads the data into MySQL)
```

Run order in MySQL:

```bash
mysql -u root -p < sql/02-03_schema.sql
mysql -u root -p < sql/05_mock_data.sql
mysql -u root -p < sql/07_real_data.sql
mysql -u root -p < sql/04_crud.sql
mysql -u root -p < sql/06_queries.sql
```

`07_real_data.sql` first loads the cleaned rows into temporary staging tables
and then uses `INSERT ... SELECT` with joins to fill the real tables. That way
the foreign keys are looked up by name or O\*NET code instead of hard-coded IDs.

### Result

| Table | Mock rows | Real rows added | Total |
|---|---:|---:|---:|
| Employer | 9 | 9,345 (+2 matched to mock employers) | 9,354 |
| EntryLevelJob | 7 | 771 | 778 |
| AITechnology | 6 | 1 (+1 matched to mock) | 7 |
| Affects | 15 | 1,225 | 1,240 |
| JobPosting | 18 | 23,238 | 23,256 |

(Mock counts include the employer added by `04_crud.sql`.)

The two datasets overlap in the database in three places:
- Dataset A's postings link to the same `EntryLevelJob` rows that Dataset B's
  exposure scores describe, through the O\*NET-SOC code.
- `Booking.com` and `Philips` appear in both the mock data and Dataset A, so
  their real postings were added to the existing employers.
- `Large Language Models` already existed as a mock AI technology, and Dataset B
  reuses it.

---

## 1. Schema and constraint violations

Before changing anything, we tried inserting values from the real data into the
**original** schema (assignment 3). These are the problems we found:

| # | Constraint | Problem in the real data | What MySQL did |
|---|---|---|---|
| 1 | `EntryLevelJob.JobName VARCHAR(100)` | One O\*NET title is 105 characters long ("Grinding, Lapping, Polishing, and Buffing Machine Tool Setters, ...") | `ERROR 1406: Data too long for column 'JobName'` |
| 2 | `Employer.CompanySize ENUM(...) NOT NULL` | Dataset A has no company size | **No error.** MySQL silently stored `'Small'`, the first ENUM value, for every company. This is worse than an error, because it creates false data. |
| 3 | `Employer.CompanyName UNIQUE` | The same company is written in different ways (`AbbVie` / `Abbvie`, `a2a` / `A2A` / `A2a`, `Ørsted` / `Orsted`). MySQL's default collation `utf8mb4_0900_ai_ci` ignores case and accents, so these count as duplicates. | `ERROR 1062: Duplicate entry 'Abbvie' for key 'employer.CompanyName'` |
| 4 | `Employer.CompanyName UNIQUE` | Real companies that also appear in the mock data (`Booking.com` with 5 postings, `Philips` with 7). Because case is ignored, even a spelling like `PHILIPS` collides. | `ERROR 1062: Duplicate entry 'PHILIPS' for key 'employer.CompanyName'` |
| 5 | `JobPosting.Location NOT NULL` | 19 postings have no location | `ERROR 1048: Column 'Location' cannot be null` |
| 6 | `JobPosting` (no key besides the ID) | The same posting appears several times (found on several job sites) | **No error.** The duplicate was inserted twice. |
| 7 | `JobPosting.PostedDate DATE` | Source dates are timestamps (`2023-06-16 13:18:22`) | Accepted with `Note 1292: Incorrect date value`, time is cut off |
| 8 | `MinSalary` / `MaxSalary` | Source only gives one average salary, as a yearly, hourly or monthly rate, in USD. The mock data is in EUR. | Would mix currencies and rates in one column without any error |
| 9 | `EntryLevelJob`, `Affects` | No column to store the O\*NET code or the numeric exposure score, so Dataset A and B cannot be linked and the score would be lost | n/a (missing design) |

## 2. Schema changes

All changes are in `sql/02-03_schema.sql`, marked with `A4`.

| Table | Change | Fixes |
|---|---|---|
| `Employer` | `CompanySize` can now be `NULL` | #2: an unknown size is stored as unknown, not as a false `'Small'` |
| `EntryLevelJob` | `JobName` widened to `VARCHAR(150)` | #1 |
| `EntryLevelJob` | New `OnetSocCode CHAR(10) UNIQUE` | #9: the shared key that links Dataset A and B. `NULL` for mock jobs. |
| `EntryLevelJob` | New `JobZone TINYINT` with `CHECK (JobZone BETWEEN 1 AND 5)` | Stores why a job counts as entry-level (see 3.5) |
| `JobPosting` | New `SalaryCurrency CHAR(3)` and `CHECK (MinSalary IS NULL OR SalaryCurrency IS NOT NULL)` | #8: real salaries are `USD`, mock salaries `EUR`. A salary without a currency is rejected. |
| `JobPosting` | New `UNIQUE (EmployerID, JobTitle, Location, PostedDate)` | #6: the database itself now blocks duplicate postings |
| `Affects` | New `ExposureScore DECIMAL(5,4)` with `CHECK (ExposureScore BETWEEN 0 AND 1)` | #9: keeps the original score behind `ImpactLevel` |

`05_mock_data.sql` and `04_crud.sql` now set `SalaryCurrency = 'EUR'` on their
job postings, because of the new CHECK.

Problems #3, #4, #5 and #7 are fixed in the data cleaning instead (section 3).

---

## 3. Data cleaning and transformation

Exact counts for every step are in `data/clean/cleaning_report.txt`.

### 3.1 How is missing data reported?

**Dataset A (data_jobs):** missing values are **empty fields** in the CSV
(`,,`). There is no `NULL`, `NA` or `N/A` text. We read every column as text so
pandas would not guess, and counted the empty strings:

| Column | Empty | Out of 23,449 | How we handled it |
|---|---:|---:|---|
| `salary_rate` | 22,577 | 96% | Not loaded |
| `salary_year_avg` | 22,935 | 98% | Salary becomes `NULL` |
| `salary_hour_avg` | 23,110 | 99% | Salary becomes `NULL` |
| `job_skills`, `job_type_skills` | 4,001 | 17% | Not loaded |
| `job_schedule_type` | 369 | 2% | Not loaded |
| `job_location` | 19 | 0.1% | Filled from `search_location` (the city or country the source searched in), because `Location` is `NOT NULL` |
| `job_country` | 2 | | Only used for the salary currency check |

Other forms of missing data in Dataset A:
- **A rate without a value.** 19 postings have `salary_rate = 'month'` but no
  salary value in any column, so salary is `NULL`.
- **Missing columns.** There is no closing date, job description or company
  size anywhere, so `ClosingDate`, `JobDescription` and `CompanySize` are
  `NULL` for all real rows.
- **Hidden missing values.** `job_location = 'Anywhere'` means "remote", not a
  missing location (see 3.4).
- **Unknown currency.** 199 non-US postings have a salary, but the source does
  not say which currency it is in. We set these to `NULL` and keep only US
  salaries, as `USD`.

**Dataset B (GPTs are GPTs):** no missing values in any column. A score of
`0.0` is a real value ("not exposed"), not a missing one, so it is kept apart
from `NULL`: an occupation with score 0 for a technology simply gets no
`Affects` row.

**O\*NET:** every Dataset B occupation has a Job Zone, so nothing is missing.

### 3.2 How are dates formatted?

| Source | Column | Format | Example | Transformation |
|---|---|---|---|---|
| Dataset A | `job_posted_date` | `YYYY-MM-DD HH:MM:SS` timestamp, no time zone | `2023-06-16 13:18:22` | Parsed with a strict format (0 failures), time removed, stored as `DATE` `2023-06-16` |
| O\*NET | `Date` (in Job Zones) | `MM/YYYY`, month and year only | `08/2023` | Not loaded (it is when O\*NET last updated the rating) |
| Mock data | `PostedDate`, `ClosingDate`, `AdoptionDate` | ISO `YYYY-MM-DD` | `2025-01-15` | none |

All postings are from 2023-01-01 to 2023-12-31. We parse dates in Python
instead of letting MySQL cut off the time (violation #7), so a badly formatted
date would show up as an error instead of a warning.

### 3.3 Are there duplicate records?

**Dataset A, yes, at two levels:**

1. **Exact duplicate rows:** 2 rows were identical in every column.
   Removed.
2. **The same posting on several job sites:** the source scraped Google Jobs,
   which lists the same job once for every site it appears on (LinkedIn, Indeed,
   BeBee, ...). We count two rows as the same posting when **company, job title,
   location and posting day** are equal, compared without case and accents (the
   same way MySQL compares them). **209** such duplicates were removed. When
   only one copy had a salary, we kept that one.

We did **not** remove postings that have the same company and title on
*different* days (6,923 rows). A company can hire for the same role several
times a year, and we cannot tell a repost from a new opening.

The new `UNIQUE (EmployerID, JobTitle, Location, PostedDate)` constraint makes
sure no duplicate can be inserted later.

**Duplicate entities across sources:** `Booking.com` and `Philips` exist in the
mock data and in Dataset A, and `Large Language Models` exists in the mock data
and Dataset B. `07_real_data.sql` inserts these only `WHERE NOT EXISTS`, so the
real postings are attached to the existing rows instead of creating duplicates.

**Dataset B:** no duplicate SOC codes and no duplicate titles.

### 3.4 Are there inconsistent naming conventions?

Dataset A, yes:

| Issue | Example | Count | Handling |
|---|---|---:|---|
| Same company, different case or accents | `AbbVie` / `Abbvie`, `7Eleven` / `7eleven`, `a2a` / `A2A` / `A2a`, `Accenture GmbH` / `Accenture Gmbh`, `Ørsted` / `Orsted` | 416 extra spellings (9,763 spellings → 9,347 companies) | Grouped by a key without case or accents, then the most common spelling is used for all of them |
| Extra or double spaces | in job titles, company names, locations | 104 / 25 / 37 values | Trimmed and collapsed to one space |
| Remote jobs called "Anywhere" | `Anywhere` | 1,801 | Renamed to `Remote`, the word the mock data uses |
| Category does not match title | Titles like `Jr Data` or `STORAGE ANALYST JR` labelled `Senior Data Analyst` by the source's classifier | 30 | `Senior ` removed from the category |
| Different spellings of "junior" | `junior`, `jr`, `jr.`, `entry level`, `entry-level` | 16,336 / 2,486 / 11 / 1,661 / 193 | Kept as written in `JobTitle`, because they are part of the real title. The job type is taken from the category column instead. |
| Inconsistent letter case in titles | `STORAGE ANALYST JR` (all caps), `jr data analyst` (all lower case) | 279 / 209 | Kept as written. Changing the case would break acronyms like `SQL` or `AWS`. Duplicate detection ignores case. |
| Cut-off titles | `jr Java software programmer/Data Analyst/Data Scientists/Machine...` | 629 | Kept as is. The source cut them off and the full title is not available. |
| Different ways of naming the same country | `London, UK` vs `United Kingdom` | 1,306 vs 222 | Kept as is. `Location` is free text in our schema. |
| Prefix in the source site name | `via LinkedIn` | all | Not loaded |

We did **not** merge different legal entities of the same group (for example
`Accenture` and `Accenture GmbH`), because they are different employers.

**Dataset B:** names follow O\*NET exactly. Titles are identical to the O\*NET
31.0 titles for all 923 codes, so we found no inconsistencies.

**Between the datasets:** Dataset A uses its own 7 job categories and B uses
O\*NET occupation titles. These are linked through the crosswalk in 3.5.

### 3.5 Other transformations

**Entry-level jobs (Dataset B + O\*NET).** O\*NET puts every occupation into a
*Job Zone* from 1 (little preparation) to 5 (extensive preparation). We count
Job Zones 1-4 as entry-level for a new graduate, because zone 4 typically needs
a bachelor's degree, while zone 5 needs a graduate degree and years of
experience. This keeps **771** of the 923 occupations. The Job Zone is stored
in `EntryLevelJob.JobZone`.

**Job category → occupation crosswalk (Dataset A → B).** Dataset A only has 7
categories. We mapped them by hand to O\*NET codes, following O\*NET's own
"Sample of Reported Titles" wherever it contains the exact title:

| data_jobs category | O\*NET code | O\*NET occupation | Reason |
|---|---|---|---|
| Data Analyst | 15-2051.01 | Business Intelligence Analysts | O\*NET lists "Data Analyst" under Survey Researchers, which is too narrow for these postings |
| Data Scientist | 15-2051.00 | Data Scientists | same name |
| Data Engineer | 15-1243.00 | Database Architects | O\*NET reported title |
| Business Analyst | 13-1111.00 | Management Analysts | O\*NET reported title |
| Software Engineer | 15-1252.00 | Software Developers | O\*NET reported title |
| Machine Learning Engineer | 15-2051.00 | Data Scientists | no O\*NET match, closest occupation |
| Cloud Engineer | 15-1299.05 | Information Security Engineers | O\*NET reported title |

All 7 targets are in Job Zone 4, so they are entry-level by our definition.

**AI exposure → `Affects` (Dataset B).** We use the **human** ratings (not the
GPT-4 ratings) and turn two of the scores into two AI technologies:

| AITechnology | Score column | Meaning |
|---|---|---|
| Large Language Models | `human_rating_alpha` | Tasks an LLM can speed up on its own |
| LLM-Powered Software | `human_rating_gamma` | Tasks an LLM can speed up with extra software built on it |

`ImpactLevel` comes from the score: **Low** below 1/3, **Medium** from 1/3 to
2/3, **High** from 2/3. A score of 0 creates no row. The exact score is kept in
`Affects.ExposureScore`, rounded to 4 decimal places.

**Salary.** Dataset A gives one average value, not a range:
- yearly: used directly (514 postings)
- hourly: multiplied by 2,080 (40 hours × 52 weeks) to get a yearly amount
  (339 postings)
- monthly: no value given (19 postings), stored as `NULL`

Because only one value exists, `MinSalary = MaxSalary`. Only US postings keep
their salary (`SalaryCurrency = 'USD'`). Other countries' salaries become
`NULL` (199 postings), because the currency is unknown. In total 654 real
postings have a salary.

**Columns we did not load:** `job_via`, `job_schedule_type`,
`job_work_from_home` (same information as `Location = 'Remote'`),
`job_no_degree_mention`, `job_health_insurance`, `job_skills` and
`job_type_skills`. None of them has a matching attribute in our schema.

---

## 4. Checks after loading

After running the full pipeline (schema → mock → real data → CRUD), we checked:

- all 23,238 cleaned postings were inserted (each one found its employer and job)
- 0 postings without an employer
- 0 salaries without a currency
- the employer count adds up: 9,347 cleaned companies + 9 mock/CRUD
  employers − 2 overlapping (Booking.com, Philips) = 9,354
- `04_crud.sql` and `06_queries.sql` still run without errors

While doing this check we found one more naming problem: `Ørsted` and `Orsted`
are the same company to MySQL (`'Ørsted' = 'Orsted'` is true), but our first
Python version did not treat them as the same, because Unicode does not split
`Ø` into `O` + accent. We added a small table for such letters (ø, ł, đ, æ, œ)
in `clean_transform.py`, so the cleaning step and the database now agree.

---

## 5. Example queries on the real data (Task 3)

We ran the queries from assignment 3 (`sql/06_queries.sql`) again on the full
database (schema → mock → real data → CRUD). All four still ran without errors,
but two of them no longer gave useful results. Changes are marked `A4` in the
file.

| Query | Result on the real data | Expected? | Change |
|---|---|---|---|
| 1. High-impact AI technologies and postings per job | 778 rows, 765 of them O\*NET jobs with 0 postings | No, the jobs with postings get lost among the empty ones | `HAVING TotalPostings > 0`. 13 rows: 6 real jobs and 7 mock jobs. Jobs with 0 high-impact technologies (e.g. `Entry-Level UX Researcher`) still show up. |
| 2. Rank employers within their size group | 9,354 rows, 9,345 employers in one `NULL` size group | No, the real employers have no size (see 1, #2), and every employer is listed | Shown as `Unknown` with `COALESCE`, and only the top 5 per group are kept. 14 rows. |
| 3. Graduates without an AI degree applying to AI-adopting employers | 13 rows, same as before | Yes, it only uses tables that have mock data only (`Graduate`, `Applies`, `Adopts`) | None |
| 4. Average salary for jobs with high AI impact | `PostingCount` 1,032 for `Software Developers`, but only 12 of those postings have a salary. USD and EUR averages were sorted together. | No, the count and the `HAVING >= 2` check included postings without a salary | Only postings with a salary are counted, and the query groups and sorts by `SalaryCurrency`. 11 rows: 5 in EUR, 6 in USD. |

The averages in query 4 were already correct, because `AVG` skips `NULL`.
Only the count was wrong. For real postings `AvgMinSalary = AvgMaxSalary`,
because the source gives one average salary instead of a range (see 3.5).

We also checked that the adapted queries give the same results as before on
the mock data only (without `07_real_data.sql`).
