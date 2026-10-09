# Query Catalogue (Final Assignment, Task 2)

Every SELECT query in this repository, who wrote it, the question it answers
and why that question matters for our societal problem.

Authors are given as GitHub names, as the assignment asks. The mapping from
GitHub names to student names is submitted separately on Canvas and is
deliberately **not** in this repository.

| GitHub name | Student |
|---|---|
| `chimper999` | see the Canvas file |
| `ahmadnasser731` | see the Canvas file |
| `mbdour11` | see the Canvas file |

## The societal problem these queries serve

From our week 1 and week 2 reports: companies increasingly use AI for work that
used to be done by junior employees, so fewer entry level jobs are advertised,
which closes the usual way into a career for new graduates. The database was
built to answer three questions:

- **S1.** How is the demand for entry level jobs changing over time?
- **S2.** Which entry level jobs are affected the most by AI?
- **S3.** How do employers respond when they adopt AI?

## Query list

| # | File | Author | Question it answers | Serves | Why that matters for the societal problem |
|---|---|---|---|---|---|
| 1 | `06_queries.sql` | `mbdour11` | For every entry level job, how many AI technologies hit it with High impact, and how many job ads exist for it? | S2, S1 | Puts exposure next to hiring, so you can see whether the jobs AI touches are also the jobs that are disappearing. |
| 2 | `06_queries.sql` | `mbdour11` | Which employers post the most entry level jobs, ranked inside their own size group? | S3 | The Reuters survey behind our week 1 report found that medium and large employers cut entry level roles far more than small ones, so employer size is the comparison that matters. |
| 3 | `06_queries.sql` | `mbdour11` | Which graduates without an AI or data degree applied to a company that has already adopted AI? | S3 | These are the graduates most likely to meet AI at work without having been taught it, so they are who a careers service should reach first. |
| 4 | `06_queries.sql` | `mbdour11` | What is the average advertised salary for job types that at least one AI technology hits hard? | S2 | If AI pressure is real it should eventually show up in pay, not only in the number of ads. |
| 5 | `08_queries.sql` | `chimper999` | Is it the AI model itself that threatens entry level jobs, or the software built on top of it? | S2 | Graduates are told to "learn to use ChatGPT". If the exposure sits in the tooling rather than the chatbot, that advice does not protect their first job. |
| 6 | `08_queries.sql` | `chimper999` | Does AI exposure rise or fall with how much education and training a job needs? | S2 | Tests the assumption our whole project rests on. If the least prepared jobs were the exposed ones, this would be a problem for school leavers, not graduates, and our framing would be wrong. |
| 7 | `08_queries.sql` | `ahmadnasser731` | Do the entry level jobs that AI tooling can do best pay new graduates less? | S2 | If employers expect AI to take over junior work, the most exposed jobs should pay least, so graduates there would lose on both hiring and pay. 
| 8 | `08_queries.sql` | `ahmadnasser731` | Are the entry level jobs most exposed to AI tooling more often fully remote? | S2, S1 | Remote work is done entirely on a computer, where AI tooling reaches, and is open to applicants from anywhere, so graduates in those jobs are squeezed by AI and by a wider applicant pool.
| 9 | `08_queries.sql` | `mbdour11` | Over 2023, did the share of entry level ads for the jobs most exposed to AI tooling go down? | S1, S2 | 2023 is the first full year of LLM tools at work. If AI replaces junior work, the most exposed jobs should make up less and less of entry level hiring. 
| 10 | `08_queries.sql` | `mbdour11` | When an employer adopts an AI technology, does it train its staff on that technology? | S3 | If employers do not train staff on the AI they adopt, they expect new hires to already know it, which raises the bar for graduates. 

Queries 1 to 4 were written by `mbdour11` for assignment 3 and adapted by the
same author in assignment 4 when the real data was loaded (commits `f992a98`
and `0595d2e`). Queries 5 onwards are new for this assignment.

## What the new queries found

### Query 5: the gap is in the tooling, not the model

Of the six job types that appear in both datasets, every single one scores
**Low** for exposure to a large language model on its own (0.05 to 0.30) and
**High** once software built on that model is included (0.81 to 0.95).

| Job type | Entry level ads | Share | Model alone | With tooling | Gap |
|---|---:|---:|---:|---:|---:|
| Database Architects | 4,223 | 18.2% | 0.24 | 0.95 | 0.71 |
| Information Security Engineers | 248 | 1.1% | 0.30 | 0.95 | 0.65 |
| Business Intelligence Analysts | 9,060 | 39.0% | 0.21 | 0.94 | 0.73 |
| Data Scientists | 6,856 | 29.5% | 0.25 | 0.94 | 0.69 |
| Software Developers | 1,032 | 4.4% | 0.05 | 0.84 | 0.79 |
| Management Analysts | 1,819 | 7.8% | 0.19 | 0.81 | 0.62 |

The largest category of entry level ads in our data, Business Intelligence
Analysts at 39%, is also among the most exposed once tooling is counted.

### Query 6: the degree level jobs are the exposed ones

Across all 771 occupations, exposure rises with the amount of preparation a job
needs, which is the opposite of the usual worry that automation takes the least
skilled jobs first.

| Job Zone | Preparation needed | Occupations | Model alone | With tooling | Over half exposed |
|---:|---|---:|---:|---:|---|
| 2 | some preparation | 337 | 0.070 | 0.240 | 55 (16%) |
| 3 | medium preparation | 208 | 0.117 | 0.428 | 71 (34%) |
| 4 | considerable preparation (degree level) | 226 | 0.227 | 0.710 | 195 (86%) |

86% of degree level occupations are more than half exposed, against 16% of the
least prepared ones. This supports the way we framed the problem in week 1:
the people being squeezed are the ones who just finished a degree.

Job Zone 1 is absent because no Job Zone 1 occupation survived the match with
Dataset B, and Job Zone 5 was excluded as not entry level during cleaning
(`docs/data_cleaning.md`).

### Query 9: entry level hiring moved slightly away from the most exposed jobs

We look at the share of ads, not the number, because how many ads were
collected per month depends on the scraping (2,771 in January, 1,490 in May).

| Month | Entry level ads | In the 4 most exposed jobs | Share |
|---:|---:|---:|---:|
| Jan | 2,771 | 2,477 | 89.4% |
| Feb | 1,970 | 1,758 | 89.2% |
| Mar | 1,852 | 1,635 | 88.3% |
| Apr | 1,836 | 1,624 | 88.5% |
| May | 1,490 | 1,355 | 90.9% |
| Jun | 1,764 | 1,589 | 90.1% |
| Jul | 1,868 | 1,638 | 87.7% |
| Aug | 2,060 | 1,742 | 84.6% |
| Sep | 1,875 | 1,662 | 88.6% |
| Oct | 2,105 | 1,820 | 86.5% |
| Nov | 2,011 | 1,723 | 85.7% |
| Dec | 1,636 | 1,364 | 83.4% |

The share was 89.3% from January to June and 86.1% from July to December,
with December the lowest month. The ads went to Management Analysts and
Software Developers instead, which are also exposed, but less. It is one
year and about 3 percentage points, so it does not prove AI caused it, but
it goes in the direction our societal problem expects.

### Query 10: half of the AI adoptions come without training on that technology

| Response | Adoptions |
|---|---:|
| Trains staff on this technology | 6 |
| Trains staff, but not on this technology | 5 |
| No training at all | 1 |

Adopts and WorkplaceTraining are mock data (`docs/limitations.md`), so this
shows what the database can answer, not a fact about real companies.

## How to run them


```bash
mysql -u root -p < sql/02-03_schema.sql
mysql -u root -p < sql/05_mock_data.sql
mysql -u root -p < sql/07_real_data.sql
mysql -u root -p < sql/04_crud.sql
mysql -u root -p < sql/06_queries.sql
mysql -u root -p < sql/08_queries.sql
```
