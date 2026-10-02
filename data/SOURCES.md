# Data Sources (Assignment 4 - Task 1)

We use two openly available real-world datasets that complement each other.
They cover different parts of our schema and only partly overlap, so neither one
is a subset of the other (A ⊈ B and B ⊈ A). A third source, O\*NET, is only used
as a lookup table to connect the two (see below).

We downloaded all files on **2026-10-02**. Running
`python3 data/download_data.py` downloads them again into `data/raw/`.

---

## Dataset A: data_jobs (2023 data and AI job postings)

| | |
|---|---|
| **Publisher** | Luke Barousse, on Hugging Face |
| **URL** | https://huggingface.co/datasets/lukebarousse/data_jobs |
| **Direct download** | https://huggingface.co/datasets/lukebarousse/data_jobs/resolve/ed776e5a0a8c40ea9d5efbd800772ae52e140f3e/data_jobs.csv |
| **Publication date** | First published 2024-03-21, last updated 2025-06-03 (we use revision `ed776e5`). The postings themselves are from 2023-01-01 to 2023-12-31. |
| **License** | Apache License 2.0, stated in the dataset card. No login or registration needed. |
| **Raw file** | `data/raw/data_jobs_entry_level.csv` (23,449 rows, 17 columns) |
| **SHA-256** | full file `635241ed09ccee18bdae1f83b45f26d6759e0aa2513c529f6190e9054062436c`, entry-level subset `b6000ba997ea890a8875b0e08ee5e31593a61527e556abbca68af45685ca80e2` |

**What it contains:** Real job postings for data and AI roles (data analyst,
data scientist, data engineer, software engineer, ML engineer and others),
collected from Google Jobs. It includes job title, company, location, country,
posting date, schedule type, salary (when given) and required skills.

**Schema tables it fills:** `Employer` (companies), `JobPosting`, and
`EntryLevelJob` (through the job title).

**Coverage:** The full file has 785,741 postings (231 MB, too big for git). We
only store the 23,449 postings whose title marks them as entry-level ("junior",
"jr", "entry level", "graduate" or "trainee"). These come from 9,767 companies,
so there are well over 50 unique rows. The rows are not changed in any way, only
filtered.

> Note on provenance: the author scraped the postings from Google Jobs and
> released the dataset under Apache 2.0. The license is the one stated by the
> dataset author.

---

## Dataset B: "GPTs are GPTs" occupation-level AI exposure scores

| | |
|---|---|
| **Publisher** | OpenAI / Eloundou, Manning, Mishkin & Rock |
| **Paper** | Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). *GPTs are GPTs: Labor market impact potential of LLMs.* Science, 384(6702), 1306–1308. https://doi.org/10.1126/science.adj0998 |
| **URL** | https://github.com/openai/GPTs-are-GPTs |
| **Direct download** | https://raw.githubusercontent.com/openai/GPTs-are-GPTs/main/data/occ_level.csv |
| **Publication date** | Repository published 2024-06-17. `occ_level.csv` was last changed 2025-10-03. |
| **License** | MIT License (Copyright (c) 2024 OpenAI). This is an open license. |
| **Raw file** | `data/raw/gpts_are_gpts_occ_level.csv` (923 rows, 8 columns) |
| **SHA-256** | `40c74f53de40aec91c0017d80690cbba915f83a8bb414bcf2f884692f1749acb` |

**What it contains:** For each O\*NET occupation, a score from 0 to 1 for how
exposed it is to large language models. Each occupation has three scores, from
both human raters and GPT-4:
- `alpha`: exposure to an LLM alone
- `beta`: alpha plus half of the exposure to software built on top of LLMs
- `gamma`: alpha plus all of the exposure to software built on top of LLMs

**Schema tables it fills:** `EntryLevelJob` (occupations), `AITechnology` (LLMs
alone and LLM-powered software), and `Affects` (the score turned into
`ImpactLevel` Low / Medium / High).

**Coverage:** 337 of the 923 occupations are in O\*NET Job Zone 1-2 ("little or
some preparation needed", meaning entry-level), so there are well over 50
unique rows.

---

## Auxiliary reference: O\*NET 31.0 Database

We do not treat O\*NET as one of the two main datasets. We use it only as a
lookup table to (a) decide which occupations count as entry-level (Job Zones)
and (b) link job titles from Dataset A to O\*NET occupations (reported job titles).

| | |
|---|---|
| **Publisher** | U.S. Department of Labor, Employment and Training Administration (USDOL/ETA) |
| **URL** | https://www.onetcenter.org/database.html |
| **Release** | O\*NET 31.0 (current release as of 2026-10-02) |
| **License** | Creative Commons Attribution 4.0 International (CC BY 4.0). The optional developer registration is not required to download. |
| **Raw files** | `data/raw/onet_31_0_job_zones.csv`, `data/raw/onet_31_0_occupation_data.csv`, `data/raw/onet_31_0_sample_of_reported_titles.csv` |

Attribution: *This product includes information from the O\*NET 31.0 Database by
the U.S. Department of Labor, Employment and Training Administration (USDOL/ETA).
Used under the CC BY 4.0 license. O\*NET® is a trademark of USDOL/ETA.*

---

## Why the datasets are complementary (A ⊈ B, B ⊈ A)

| Schema table | Dataset A (data_jobs) | Dataset B (GPTs are GPTs) |
|---|:---:|:---:|
| Employer | ✔ | |
| JobPosting | ✔ | |
| EntryLevelJob | ✔ (job titles) | ✔ (O\*NET occupations) |
| AITechnology | | ✔ |
| Affects | | ✔ |
| Graduate, Applies, Adopts, WorkplaceTraining | (kept from mock data) | (kept from mock data) |

- **A ⊈ B:** B has no employers, job postings, salaries or dates.
- **B ⊈ A:** A has nothing about AI exposure scores, and only covers data and
  tech jobs, while B covers all 923 occupations.
- **Overlap:** both datasets describe *job types*. We link them through the
  `EntryLevelJob` table using the O\*NET lookup, so we can ask questions such as
  "which companies hire most for entry-level jobs that are highly exposed to LLMs?"

Neither dataset covers `Graduate`, `Applies`, `Adopts` or `WorkplaceTraining`.
The assignment allows this, so those tables keep their mock data.