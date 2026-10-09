# Final Check of the Database and Repository (Final Assignment, Task 1)

Task 1 asks us to finalise the database and schema "with input from the previous
assignments". We had not received written feedback on the earlier weeks when we
did this work, so instead we went back through the brief for every week and
checked the repository against it ourselves. This file records what we checked,
what was wrong and what we changed.

Checked by `chimper999` on 2026-10-09, against a full load of the database
(schema, mock data, real data, CRUD) on MySQL-compatible MariaDB 10.11.

## Is every week still represented?

| Week | What the brief asked for | Where it is | OK? |
|---|---|---|---|
| 1 | Societal problem, stakeholders, sources | `docs/week1_societal_problem.pdf` | yes |
| 2 | Scope, entities, relationships, keys, ERD, 3NF | `docs/week2_data_modeling.pdf`, `docs/erd.png`, `docs/normalization.md` | ERD was stale, fixed below |
| 3 | Schema with constraints, CRUD, mock data, queries | `sql/02-03_schema.sql`, `04_crud.sql`, `05_mock_data.sql`, `06_queries.sql` | yes |
| 4 | Two open datasets, cleaning, normalisation recheck, limitations, video | `data/SOURCES.md`, `data/clean_transform.py`, `docs/data_cleaning.md`, `docs/normalization.md`, `docs/limitations.md`, video in README | yes |
| Final | Finalised schema, 2 documented queries per member, open publication | `sql/08_queries.sql`, `docs/queries.md`, this file | in progress |

## What was wrong, and what we changed

### 1. The ERD no longer matched the schema

`docs/erd.png` still showed the week 2 design. It was missing
`EntryLevelJob.OnetSocCode`, `EntryLevelJob.JobZone`, `JobPosting.SalaryCurrency`
and `Affects.ExposureScore`, and it still showed `Affects.ImpactLevel`, which is
the column we **removed** in assignment 4 as our 3NF fix. So the diagram
contradicted `docs/normalization.md`.

Fixed: regenerated `docs/erd.png` from the current schema, including the
`AffectsWithLevel` view, and added the editable source as `docs/erd.mmd` so it
does not go stale again. The week 2 PDF keeps its own older diagram, because
that is what we handed in that week.

### 2. Real-looking e-mail addresses in the Graduate table

The thirteen invented graduates had addresses at `gmail.com`. Those were never
real people, but an address like `sofia.bakker@gmail.com` can easily belong to
someone, and the final assignment asks us to confirm there is no personal data
before publishing openly.

Fixed: all thirteen now use `example.com`, which RFC 2606 reserves for
documentation so that it can never be registered by anyone (41 places across
`05_mock_data.sql` and `04_crud.sql`). `05_mock_data.sql` also got a header
stating plainly that nothing in it describes a real person.

We also added `data/check_personal_data.sql`, which scans every text column in
the loaded database for e-mail addresses and phone numbers, so the claim can be
rerun instead of taken on trust. It currently returns 0 for every check except
the deliberately wide phone number pattern, whose 60 hits we checked by hand:
all are salary figures (`$60000.00`), job requisition numbers (`JR-0000178`) or
year ranges (`2022-2023`).

### 3. The schema never declared a character set

`CREATE DATABASE ai_entry_jobs;` left the character set to whatever the server
happens to default to. MySQL 8 defaults to `utf8mb4`, so it worked for us, but
an older or differently configured server defaults to `latin1` and would store
non-ASCII names as question marks. That matters here: 419 employers, 1,103
locations and 718 job titles contain non-ASCII characters, including Chinese,
Hungarian and Portuguese.

Fixed: the database is now created with `CHARACTER SET utf8mb4 COLLATE
utf8mb4_unicode_ci`. We reloaded everything afterwards and all row counts are
unchanged, so the stricter collation causes no new `UNIQUE` collisions.

### 4. Stale and unclear comments

- `sql/02-03_schema.sql` and `sql/06_queries.sql` both described a run order
  from assignment 3 that no longer included `07_real_data.sql`.
- The README note about rerunning `04_crud.sql` was an unfinished sentence.
- `sql/05_mock_data.sql` had no header comment, while every other file had one.
- The README did not list the final assignment or its new files.

All fixed.

## Verification

After the changes, the database was dropped and rebuilt from scratch in the
documented order. Every file ran without warnings, and the row counts match the
table in `docs/data_cleaning.md` exactly:

| Table | Rows | Expected |
|---|---:|---:|
| Employer | 9,354 | 9,354 |
| EntryLevelJob | 778 | 778 |
| AITechnology | 7 | 7 |
| Affects | 1,240 | 1,240 |
| JobPosting | 23,256 | 23,256 |

The four queries in `06_queries.sql` return the same results as before these
changes, and the new queries in `08_queries.sql` were also checked under
`ONLY_FULL_GROUP_BY`, which MySQL 8 turns on by default.
