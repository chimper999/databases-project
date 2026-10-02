# Limitations and Future Work, Revisited (Assignment 4, Task 5)

In our week 4 stakeholder video we listed limitations and future work, based on
made-up data. Here we check them again now that the database contains real-world
data (`data/SOURCES.md`), and whether our queries (`sql/06_queries.sql`) give
meaningful results.

## Limitations from the video

| Limitation (video) | Status with real data |
|---|---|
| "The data is made up. Real job ads are the next step." | ✅ Solved: 23,238 real entry-level postings and AI exposure scores for 771 occupations. New limits: the postings are only from 2023, only data and tech jobs, and only 654 (all US) have a salary. |
| "No outcomes. We know who applied, not who got hired." | ❌ Still open: no open data on applications, so `Graduate` and `Applies` still contain only mock data. |
| "Only advertised jobs. A role that quietly vanished leaves no trace." | ❌ Still open: the real data is also a list of job ads. |

## Future work from the video

| Future work (video) | Status |
|---|---|
| "Swap the sample data for real job ads from a job board." | ✅ Done, using an open dataset of postings collected from Google Jobs. |
| "Record what happened to each application." | ❌ Not done, no open data available. |
| "Turn the snapshot into a timeline, track job types month by month." | ❌ Not done yet. The real postings have dates, but only for one year (2023), so they cannot show a long-term trend. |

## Do our queries give meaningful results?

| Query | Meaningful? | Update required |
|---|---|---|
| 1. High-impact AI technologies and postings per job | 🟡 Partly. The posting counts are real, but the real data only has two AI technologies, so all six real jobs have exactly 1 high-impact technology and can't be told apart. | Rank by the average `ExposureScore` instead of counting high-impact technologies. |
| 2. Employers ranked within their size group | ❌ No. Real employers have no company size, so they all fall into one "Unknown" group, and its top 5 are staffing agencies and job sites (e.g. `SynergisticIT`, `Emprego`), not real employers. | Get company sizes from another open source and filter out recruiters and job sites. |
| 3. Graduates without an AI degree applying to AI-adopting employers | ⚪ Not tested. It only uses tables that still have mock data (`Graduate`, `Applies`, `Adopts`). | Needs real data on applications and AI adoption by companies. |
| 4. Average salary for jobs with high AI impact | 🟡 Partly. Correct, but based on only 654 US postings that give one average salary, so Min = Max. | Add a source with salary ranges, ideally in EUR. |
