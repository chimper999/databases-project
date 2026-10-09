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

-- ---------------------------------------------------------
-- Query 7: Do the entry level jobs that AI tooling can do
-- best pay new graduates less?
--
-- QUESTION
-- For every job type that has real entry level ads with a
-- salary, show its exposure to LLM-powered software next to
-- the average advertised salary, how far that salary is above
-- or below the average of all these ads, and rank the job
-- types once by exposure and once by salary.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- S2 asks which entry level jobs AI affects most. If employers
-- expect AI tooling to take over junior work, they have no
-- reason pay highly of it, so the jobs that have high AI exposure
-- will have a bad pay. If that is true, a graduate who goes into
-- an exposed job is has a low chance of getting higher and
-- his pay will be lower, which makes a very concerning problem. If it is not
-- true, the pressure from AI is not visible in pay yet.
--
-- SQL TECHNIQUE
-- Two CTEs, a window function over an aggregate
-- (SUM(SUM(...)) OVER () / SUM(COUNT(*)) OVER ()) for the
-- average over all ads rather than over job types, and two
-- RANK() functions with different orderings in one query.
--
-- WHY ONLY USD
-- Real salaries are in USD and mock salaries in EUR, and the
-- source only gives salaries for US postings
-- (docs/data_cleaning.md), so mixing them would compare two
-- currencies. Every real salary is one yearly figure, so
-- MinSalary and MaxSalary are the same and MinSalary is used.
--
-- WHAT WE GOT
-- No: salary does not follow exposure. The average over all
-- 654 ads is $75,528. Business Intelligence Analysts and Data
-- Scientists have the same exposure (0.94), but Data
-- Scientists earn $88,757 and BI Analysts $63,670, a gap of
-- $25,000. The best paid job type, Software Developers
-- ($94,177), is one of the least exposed, but the second best
-- paid, Database Architects ($91,183), is the most exposed.
-- So pay depends on the kind of work (technical versus
-- analyst), not on how exposed it is. The pressure from AI
-- does not show up in salaries in 2023.
-- Only 654 of the 23,256 ads (2.8%) have a salary, all from
-- the US, and Information Security Engineers has only 2, so
-- this is a very small sample.
-- ---------------------------------------------------------
WITH paid AS (
    -- Real entry level ads that state a salary
    SELECT
        jp.EntryLevelJobID,
        jp.MinSalary AS SalaryUSD
    FROM JobPosting jp
    WHERE jp.SalaryCurrency = 'USD'
      AND jp.MinSalary IS NOT NULL
),
tooling AS (
    -- Exposure of each job type to LLM-powered software
    SELECT
        af.EntryLevelJobID,
        af.ExposureScore
    FROM Affects af
             JOIN AITechnology ai ON ai.AITechnologyID = af.AITechnologyID
    WHERE ai.TechnologyName = 'LLM-Powered Software'
)
SELECT
    elj.JobName,
    ROUND(t.ExposureScore, 2)                    AS ExpWithTooling,
    COUNT(*)                                     AS AdsWithSalary,
    ROUND(AVG(p.SalaryUSD))                      AS AvgSalaryUSD,
    ROUND(AVG(p.SalaryUSD)
          - SUM(SUM(p.SalaryUSD)) OVER () / SUM(COUNT(*)) OVER ()) AS VsAllAdsUSD,
    RANK() OVER (ORDER BY t.ExposureScore DESC)  AS ExposureRank,
    RANK() OVER (ORDER BY AVG(p.SalaryUSD) DESC) AS SalaryRank
FROM paid p
         JOIN tooling t         ON t.EntryLevelJobID   = p.EntryLevelJobID
         JOIN EntryLevelJob elj ON elj.EntryLevelJobID = p.EntryLevelJobID
GROUP BY elj.EntryLevelJobID, elj.JobName, t.ExposureScore
ORDER BY t.ExposureScore DESC, AvgSalaryUSD DESC;
-- ---------------------------------------------------------
-- Query 8: Are the entry level jobs most exposed to AI
-- tooling more often fully remote?
--
-- QUESTION
-- For every job type with real entry level ads, count how
-- many of its ads are fully remote, split the job types into
-- the most exposed (0.9 or higher, the same cut-off as query
-- 9) and the rest, and show the remote share for each job
-- type and for each of the two groups.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- A job that can be done fully remote is a job done entirely
-- on a computer, which is exactly the kind of work AI tooling
-- can reach. A remote ad is also open to applicants from
-- anywhere, so a new graduate competes with far more people
-- for it. If the most exposed jobs are also the most remote,
-- graduates in those fields are squeezed from two sides at
-- once: by AI and by a wider pool of applicants.
--
-- SQL TECHNIQUE
-- Two CTEs, conditional aggregation to count remote ads, a
-- CASE label for the exposure group, SUM() OVER (PARTITION BY
-- ...) to show each group's share on every row without a
-- second query, and RANK().
--
-- WHY Location = 'Remote' EXACTLY
-- The source writes fully remote jobs as 'Remote'. There are
-- also 7 ads in 'Remote, OR', which is a town in Oregon, not
-- a remote job, so LIKE 'Remote%' would count them wrongly.
--
-- WHAT WE GOT
-- Yes. In the four most exposed job types, 8.2% of ads are
-- fully remote, against 4.3% in the two less exposed ones,
-- almost twice as many. Database Architects (9.3%) and
-- Business Intelligence Analysts (8.3%) are the most remote.
-- The exception is Information Security Engineers, which is
-- among the most exposed but only 2.0% remote, probably
-- because security work often needs access to the office
-- network. Remote jobs are still a small part of all entry
-- level ads, but they are concentrated where AI exposure is
-- highest.
-- ---------------------------------------------------------
WITH remote AS (
    -- Entry level ads and fully remote ads per job type
    SELECT
        jp.EntryLevelJobID,
        COUNT(*)                                                AS EntryLevelAds,
        SUM(CASE WHEN jp.Location = 'Remote' THEN 1 ELSE 0 END) AS RemoteAds
    FROM JobPosting jp
    GROUP BY jp.EntryLevelJobID
),
tooling AS (
    -- Exposure of each job type to LLM-powered software
    SELECT
        af.EntryLevelJobID,
        af.ExposureScore
    FROM Affects af
             JOIN AITechnology ai ON ai.AITechnologyID = af.AITechnologyID
    WHERE ai.TechnologyName = 'LLM-Powered Software'
)
SELECT
    elj.JobName,
    ROUND(t.ExposureScore, 2)                     AS ExpWithTooling,
    CASE WHEN t.ExposureScore >= 0.9 THEN 'Most exposed (0.9+)'
         ELSE 'Less exposed'
    END                                           AS ExposureGroup,
    r.EntryLevelAds,
    r.RemoteAds,
    ROUND(100 * r.RemoteAds / r.EntryLevelAds, 1) AS PctRemote,
    ROUND(100 * SUM(r.RemoteAds)     OVER (PARTITION BY t.ExposureScore >= 0.9)
              / SUM(r.EntryLevelAds) OVER (PARTITION BY t.ExposureScore >= 0.9), 1) AS PctRemoteInGroup,
    RANK() OVER (ORDER BY r.RemoteAds / r.EntryLevelAds DESC) AS RemoteRank
FROM remote r
         JOIN tooling t         ON t.EntryLevelJobID   = r.EntryLevelJobID
         JOIN EntryLevelJob elj ON elj.EntryLevelJobID = r.EntryLevelJobID
ORDER BY t.ExposureScore DESC, PctRemote DESC;
-- =========================================================
-- Queries 9 and 10   Author: mbdour11 (Mohammad Albdour)
-- =========================================================

-- ---------------------------------------------------------
-- Query 9: Over 2023, did entry level hiring move away from
-- the jobs that AI tooling can do best?
--
-- QUESTION
-- For every month of 2023, count the real entry level job ads
-- and how many of them are for the four job types that are
-- most exposed to LLM-powered software (exposure 0.9 or
-- higher: Business Intelligence Analysts, Data Scientists,
-- Database Architects, Information Security Engineers).
-- Show that share per month, the change from the month
-- before, and the share for each half of the year.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- S1 asks how demand for entry level jobs changes over time.
-- 2023 is the first full year after ChatGPT came out, so it
-- is when employers started to use LLM tools at work. If AI
-- replaces junior work, the ads for the most exposed jobs
-- should make up a smaller and smaller part of entry level
-- hiring. We look at the share and not the raw number of
-- ads, because the number of ads collected per month depends
-- on how the dataset was scraped (January alone has 2,771,
-- May only 1,490), while the share is not affected by that.
--
-- SQL TECHNIQUE
-- A CTE that groups by MONTH() with a conditional SUM, then
-- three window functions on top of it: LAG() to compare each
-- month with the month before, and SUM() OVER (PARTITION BY
-- ...) to get the share for each half of the year next to
-- every month without a second query.
--
-- WHAT WE GOT
-- The share of ads in the most exposed jobs went down. It
-- was 89.3% from January to June and 86.1% from July to
-- December. The five lowest months are all in the second
-- half, and December is the lowest at 83.4%. The ads did not
-- disappear: what grew instead were Management Analysts and
-- Software Developers, which are also exposed, but less.
-- This is one year of data and a shift of about 3
-- percentage points, so it does not prove that AI caused it,
-- but it goes in the direction our societal problem expects.
-- ---------------------------------------------------------
WITH monthly AS (
    SELECT
    MONTH(jp.PostedDate)                                     AS PostedMonth,
    COUNT(*)                                                 AS EntryLevelAds,
    SUM(CASE WHEN af.ExposureScore >= 0.9 THEN 1 ELSE 0 END) AS AdsMostExposed
FROM JobPosting jp
    JOIN Affects af       ON af.EntryLevelJobID = jp.EntryLevelJobID
    JOIN AITechnology ait ON ait.AITechnologyID = af.AITechnologyID
WHERE ait.TechnologyName = 'LLM-Powered Software'
  AND jp.PostedDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY MONTH(jp.PostedDate)
    )
SELECT
    PostedMonth,
    EntryLevelAds,
    AdsMostExposed,
    ROUND(100 * AdsMostExposed / EntryLevelAds, 1)                  AS PctMostExposed,
    ROUND(100 * AdsMostExposed / EntryLevelAds
              - 100 * LAG(AdsMostExposed) OVER (ORDER BY PostedMonth)
              / LAG(EntryLevelAds)  OVER (ORDER BY PostedMonth), 1) AS ChangeVsPrevMonth,
    CASE WHEN PostedMonth <= 6 THEN 'Jan-Jun' ELSE 'Jul-Dec' END    AS HalfYear,
    ROUND(100 * SUM(AdsMostExposed) OVER (PARTITION BY PostedMonth <= 6)
              / SUM(EntryLevelAds)  OVER (PARTITION BY PostedMonth <= 6), 1) AS PctMostExposedHalfYear
FROM monthly
ORDER BY PostedMonth;

-- ---------------------------------------------------------
-- Query 10: When an employer adopts an AI technology, does
-- it train its staff on that technology?
--
-- QUESTION
-- For every AI adoption in the database, check whether the
-- same employer offers workplace training on that same
-- technology, only training on other topics, or no training
-- at all, and count how many adoptions fall in each group.
--
-- WHY IT MATTERS FOR OUR SOCIETAL PROBLEM
-- S3 asks how employers respond when they adopt AI. If they
-- train their own staff on the new tool, a new graduate can
-- still get in and learn it on the job. If they do not, the
-- employer expects people to arrive already knowing it, so
-- the bar for an entry level job goes up and graduates have
-- to learn it at university or on their own first.
--
-- SQL TECHNIQUE
-- A CTE with a CASE that uses two correlated EXISTS
-- subqueries (same employer and same technology, then same
-- employer and any technology), and COUNT(*) OVER (PARTITION
-- BY ...) to show the size of each group on every row.
--
-- WHAT WE GOT
-- Only half of the 12 adoptions (6) come with training on the
-- adopted technology. 5 belong to employers that do train,
-- but on something else (for example Elastic adopted Large
-- Language Models and Mollie adopted AI Coding Assistants,
-- but neither trains on them), and 1 (FreshMind Consulting,
-- Robotic Process Automation) has no training at all.
--
-- NOTE: Adopts and WorkplaceTraining are mock data, because
-- no open dataset covers them (docs/limitations.md). So this
-- result shows what the database can answer, not a finding
-- about real companies. With real data the same query would
-- work without changes.
-- ---------------------------------------------------------
WITH response AS (
    SELECT
        e.CompanyName,
        ait.TechnologyName AS AdoptedTechnology,
        ad.AdoptionDate,
        CASE
            WHEN EXISTS (SELECT 1
                         FROM WorkplaceTraining wt
                         WHERE wt.EmployerID     = ad.EmployerID
                           AND wt.AITechnologyID = ad.AITechnologyID)
                THEN 'Trains staff on this technology'
            WHEN EXISTS (SELECT 1
                         FROM WorkplaceTraining wt
                         WHERE wt.EmployerID = ad.EmployerID)
                THEN 'Trains staff, but not on this technology'
            ELSE 'No training at all'
            END AS TrainingResponse
    FROM Adopts ad
             JOIN Employer e       ON e.EmployerID       = ad.EmployerID
             JOIN AITechnology ait ON ait.AITechnologyID = ad.AITechnologyID
)
SELECT
    CompanyName,
    AdoptedTechnology,
    AdoptionDate,
    TrainingResponse,
    COUNT(*) OVER (PARTITION BY TrainingResponse) AS AdoptionsWithThisResponse
FROM response
ORDER BY AdoptionsWithThisResponse DESC, CompanyName, AdoptedTechnology;