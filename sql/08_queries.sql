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
-- query 5: is the model itself the problem for entry level jobs,
-- or the software built on top of it?
--
-- for every job type we have real ads for, compares exposure to
-- an LLM alone against exposure once software built on it counts,
-- with the ad numbers beside them
--
-- why it matters: graduates get told to learn ChatGPT. if the
-- exposure sits in the tooling, that advice does not protect
-- their first job
--
-- two CTEs, conditional aggregation for one row per job instead
-- of one per technology, SUM() OVER () for share of ads, RANK()
--
-- result: every job type is Low against the model alone (0.05 to
-- 0.30), High once tooling counts (0.81 to 0.95). Business
-- Intelligence Analysts is 39% of our ads and still scores 0.94
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
-- query 6: does AI hit the jobs that need a degree, or the ones
-- that need almost no training?
--
-- groups all 771 occupations by O*NET Job Zone (how much
-- education the job needs) and averages exposure per zone
--
-- why it matters: our project assumes graduates are the ones
-- getting squeezed, and i wanted to check that rather than just
-- repeat it. if the least prepared jobs were the exposed ones it
-- would be a school leaver problem, not a graduate one
--
-- a CTE with the same pivot, CASE for the zone label,
-- AVG(AVG(...)) OVER () to compare each zone to the overall
-- average, conditional SUM for the count past 0.5
--
-- the LEFT JOIN and COALESCE are deliberate: clean_transform.py
-- skips a score of exactly 0, so an occupation with no Affects
-- row is not missing data, its exposure is 0. an inner join drops
-- 259 occupations and pushes every average up
--
-- result: the opposite of what i expected. exposure rises with
-- preparation needed, 0.240 then 0.428 then 0.710. 86% of degree
-- level occupations are over half exposed against 16% at the
-- bottom
--
-- Job Zone 1 is missing because none matched Dataset B, and
-- Zone 5 was dropped as not entry level in cleaning
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
