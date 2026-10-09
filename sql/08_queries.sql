-- =========================================================
-- Group Project: AI and entry level jobs
-- Final assignment - Task 2: more query examples
--
-- Two SELECT queries per group member. Every query says who
-- wrote it (GitHub name), which question it answers and why
-- that question matters for our societal problem.
-- The same table is in docs/queries.md.
--
-- The four queries from assignment 3 are still in
-- sql/06_queries.sql and are not repeated here.
--
-- Run after: 02-03_schema.sql, 05_mock_data.sql,
--            07_real_data.sql, 04_crud.sql
-- =========================================================

USE ai_entry_jobs;

-- =========================================================
-- Queries 5 and 6         Author: chimper999 (Cinar Akinoglu)
-- =========================================================

-- ---------------------------------------------------------
-- Query 5: Is it the AI model itself that threatens entry
-- level jobs, or the software built on top of it?
--
-- QUESTION
-- For every job type that we actually have real entry level
-- job ads for, compare two things: how exposed it is to a
-- large language model on its own, and how exposed it is once
-- you add the software built on top of that model. Show the
-- gap between the two next to how much hiring there is.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- Our scope asks which entry level jobs are affected most by
-- AI. "AI" is usually discussed as if it were one thing, so
-- the advice graduates get is "learn to use ChatGPT". This
-- query splits the two apart. If the danger sits in the
-- tooling rather than the chatbot, then learning to prompt a
-- chatbot is not the skill that protects your first job, and
-- careers advisors are telling students the wrong thing.
--
-- SQL TECHNIQUE
-- Two CTEs, a pivot with conditional aggregation (one row per
-- job instead of one row per technology), a window function
-- for each job's share of all these ads, and RANK().
--
-- WHAT WE GOT
-- All six job types score Low on the model alone (0.05 to
-- 0.30) but High once tooling is included (0.81 to 0.95). The
-- gap is 0.62 to 0.79 everywhere. Business Intelligence
-- Analysts is both the biggest category of entry level ads
-- (39%) and one of the most exposed (0.94).
-- ---------------------------------------------------------
WITH exposure AS (
    -- One row per job type, with a column per AI technology
    SELECT
        af.EntryLevelJobID,
        MAX(CASE WHEN ai.TechnologyName = 'Large Language Models'
                 THEN af.ExposureScore END) AS LlmAlone,
        MAX(CASE WHEN ai.TechnologyName = 'LLM-Powered Software'
                 THEN af.ExposureScore END) AS LlmSoftware
    FROM Affects af
             JOIN AITechnology ai ON ai.AITechnologyID = af.AITechnologyID
    GROUP BY af.EntryLevelJobID
),
demand AS (
    -- How much real hiring there is for each job type
    SELECT
        EntryLevelJobID,
        COUNT(*)                   AS EntryLevelAds,
        COUNT(DISTINCT EmployerID) AS Employers
    FROM JobPosting
    GROUP BY EntryLevelJobID
)
SELECT
    elj.JobName,
    d.EntryLevelAds,
    d.Employers,
    ROUND(100.0 * d.EntryLevelAds / SUM(d.EntryLevelAds) OVER (), 1) AS PctOfTheseAds,
    ROUND(e.LlmAlone, 2)                      AS ExpModelAlone,
    ROUND(e.LlmSoftware, 2)                   AS ExpWithTooling,
    ROUND(e.LlmSoftware - e.LlmAlone, 2)      AS ToolingGap,
    RANK() OVER (ORDER BY e.LlmSoftware DESC) AS ExposureRank
FROM EntryLevelJob elj
         JOIN exposure e ON e.EntryLevelJobID = elj.EntryLevelJobID
         JOIN demand   d ON d.EntryLevelJobID = elj.EntryLevelJobID
-- Both scores are needed to compare them. Only job types that
-- appear in BOTH datasets survive these joins, which is the
-- point: it is where the job ads meet the exposure scores.
WHERE e.LlmAlone IS NOT NULL
  AND e.LlmSoftware IS NOT NULL
ORDER BY e.LlmSoftware DESC;

-- ---------------------------------------------------------
-- Query 6: Does AI hit the jobs that need a degree, or the
-- jobs that need no preparation at all?
--
-- QUESTION
-- Group all 771 occupations by their O*NET Job Zone, which
-- says how much education and training a job needs, and show
-- the average AI exposure of each group.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- Our whole project assumes that new graduates are the ones
-- getting squeezed. That assumption should be tested, not
-- repeated. The common worry is that automation removes the
-- jobs needing the least training, which would make this a
-- problem for school leavers rather than for graduates. This
-- query checks which of the two is actually true in the data,
-- and so decides whether our societal problem is aimed at the
-- right group of people.
--
-- SQL TECHNIQUE
-- A CTE with a pivot, LEFT JOIN with COALESCE, a CASE label,
-- a window function over an aggregate (AVG(AVG(...)) OVER ())
-- to compare each zone against the overall average, and a
-- conditional SUM to count occupations past the halfway mark.
--
-- WHY LEFT JOIN AND COALESCE
-- data/clean_transform.py skips a score of exactly 0, so an
-- occupation with no Affects row for a technology is NOT
-- missing data: its exposure really is 0. An inner join would
-- silently drop those 259 occupations and push every average
-- up. The LEFT JOIN plus COALESCE(...,0) keeps all 771.
--
-- WHAT WE GOT
-- The opposite of the common worry. Exposure RISES with the
-- amount of preparation a job needs: 0.240 average for "some
-- preparation" jobs, 0.428 for medium, 0.710 for degree level.
-- 195 of the 226 degree level occupations (86%) are more than
-- half exposed, against 55 of 337 (16%) at the bottom. So the
-- graduate entry jobs really are the exposed ones, which
-- supports the framing of our societal problem.
--
-- Job Zone 1 ("little or no preparation") is missing from the
-- result because no Job Zone 1 occupation survived the match
-- with Dataset B, and Job Zone 5 was excluded as not entry
-- level during cleaning (docs/data_cleaning.md).
-- ---------------------------------------------------------
WITH scored AS (
    SELECT
        elj.EntryLevelJobID,
        elj.JobZone,
        COALESCE(MAX(CASE WHEN ai.TechnologyName = 'Large Language Models'
                          THEN af.ExposureScore END), 0) AS LlmAlone,
        COALESCE(MAX(CASE WHEN ai.TechnologyName = 'LLM-Powered Software'
                          THEN af.ExposureScore END), 0) AS LlmSoftware
    FROM EntryLevelJob elj
             LEFT JOIN Affects      af ON af.EntryLevelJobID = elj.EntryLevelJobID
             LEFT JOIN AITechnology ai ON ai.AITechnologyID  = af.AITechnologyID
    WHERE elj.JobZone IS NOT NULL
    GROUP BY elj.EntryLevelJobID, elj.JobZone
)
SELECT
    s.JobZone,
    CASE s.JobZone
        WHEN 1 THEN 'little or no preparation'
        WHEN 2 THEN 'some preparation'
        WHEN 3 THEN 'medium preparation'
        WHEN 4 THEN 'considerable preparation (degree level)'
    END AS PreparationNeeded,
    COUNT(*)                                                       AS Occupations,
    ROUND(AVG(s.LlmAlone), 3)                                      AS AvgExpModelAlone,
    ROUND(AVG(s.LlmSoftware), 3)                                   AS AvgExpWithTooling,
    ROUND(AVG(s.LlmSoftware) - AVG(AVG(s.LlmSoftware)) OVER (), 3) AS VsOverallAvg,
    SUM(CASE WHEN s.LlmSoftware >= 0.5 THEN 1 ELSE 0 END)          AS OccsOverHalfExposed
FROM scored s
GROUP BY s.JobZone
ORDER BY s.JobZone;

-- =========================================================
-- Queries 7 and 8      Author: ahmadnasser731 (Ahmad Nasser)
-- =========================================================
-- TODO Ahmad: add your two SELECT queries below, using the
-- same comment block as queries 5 and 6:
--   QUESTION                        what it answers
--   WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
--   SQL TECHNIQUE                   what you used
--   WHAT WE GOT                     the result you saw
-- Then add two rows to the table in docs/queries.md.
--
-- Ideas nobody has used yet: the 654 postings that have a
-- salary, the Location column, the 2023 posting dates
-- (monthly trend), or WorkplaceTraining versus Adopts.

-- =========================================================
-- Queries 9 and 10   Author: mbdour11 (Mohammad Albdour)
-- =========================================================
-- TODO Mohammad: same as above.
