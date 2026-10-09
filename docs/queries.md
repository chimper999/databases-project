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
| 7 | `08_queries.sql` | `ahmadnasser731` | *to be added* | | |
| 8 | `08_queries.sql` | `ahmadnasser731` | *to be added* | | |
| 9 | `08_queries.sql` | `mbdour11` | *to be added* | | |
| 10 | `08_queries.sql` | `mbdour11` | *to be added* | | |

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

## How to run them

```bash
mysql -u root -p < sql/02-03_schema.sql
mysql -u root -p < sql/05_mock_data.sql
mysql -u root -p < sql/07_real_data.sql
mysql -u root -p < sql/04_crud.sql
mysql -u root -p < sql/06_queries.sql
mysql -u root -p < sql/08_queries.sql
```
