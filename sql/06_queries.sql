-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 3 - Task 6: advanced queries
--
-- Run 02-03_schema.sql, then 05_mock_data.sql, then this
-- file (04_crud.sql can run before or after this one).
--
-- Assignment 4: queries were run again on the real-world data
-- (07_real_data.sql) and adapted where needed. Changes are
-- marked "A4" below, see docs/data_cleaning.md section 5.
-- =========================================================

USE ai_entry_jobs;

-- ---------------------------------------------------------
-- Query 1: For every entry-level job, how many AI
-- technologies affect it with "High" impact, and how many
-- job postings currently exist for it. Shows which roles are
-- most exposed to AI disruption alongside how much hiring is
-- still happening for them.
-- Technique: LEFT JOIN with conditional aggregation
-- (COUNT + CASE) so jobs with zero postings or zero AI
-- impact still show up with 0 instead of disappearing.
-- A4: only jobs with at least one posting. The real data adds
-- 771 O*NET jobs, and 765 of them have no postings.
-- ---------------------------------------------------------
SELECT
    elj.JobName,
    COUNT(DISTINCT CASE WHEN af.ImpactLevel = 'High' THEN af.AITechnologyID END) AS HighImpactTechCount,
    COUNT(DISTINCT jp.JobPostingID) AS TotalPostings
FROM EntryLevelJob elj
         LEFT JOIN AffectsWithLevel af ON af.EntryLevelJobID = elj.EntryLevelJobID   -- A4: view, see 02-03_schema.sql
         LEFT JOIN JobPosting jp ON jp.EntryLevelJobID = elj.EntryLevelJobID
GROUP BY elj.EntryLevelJobID, elj.JobName
HAVING TotalPostings > 0                                   -- A4
ORDER BY HighImpactTechCount DESC, TotalPostings DESC;

-- ---------------------------------------------------------
-- Query 2: Rank employers by number of job postings, within
-- their own company-size group (Small / Medium / Large), so
-- a small startup isn't unfairly compared to Philips.
-- Technique: window function RANK() OVER (PARTITION BY ...)
-- A4: the real employers have no company size, so they are
-- shown as 'Unknown', and only the top 5 per group are kept
-- (otherwise the result has 9,354 rows). Needs a derived
-- table, because a window function cannot be used in WHERE.
-- ---------------------------------------------------------
SELECT CompanyName, CompanySize, PostingCount, RankInSizeGroup
FROM (
    SELECT
        e.CompanyName,
        COALESCE(e.CompanySize, 'Unknown') AS CompanySize,
        COUNT(jp.JobPostingID) AS PostingCount,
        RANK() OVER (
            PARTITION BY e.CompanySize
            ORDER BY COUNT(jp.JobPostingID) DESC
        ) AS RankInSizeGroup
    FROM Employer e
             LEFT JOIN JobPosting jp ON jp.EmployerID = e.EmployerID
    GROUP BY e.EmployerID, e.CompanyName, e.CompanySize
) ranked
WHERE RankInSizeGroup <= 5
ORDER BY CompanySize, RankInSizeGroup;

-- ---------------------------------------------------------
-- Query 3: Graduates who applied to a job at a company that
-- has adopted AI technology, but whose own degree is not an
-- AI/data-focused field. Useful for spotting graduates who
-- may want extra AI upskilling before interviewing there.
-- Technique: correlated subquery with EXISTS, combined with
-- a NOT IN filter on the outer query.
-- ---------------------------------------------------------
SELECT DISTINCT
    g.FirstName,
    g.LastName,
    g.DegreeField,
    e.CompanyName
FROM Graduate g
         JOIN Applies a ON a.GraduateID = g.GraduateID
         JOIN JobPosting jp ON jp.JobPostingID = a.JobPostingID
         JOIN Employer e ON e.EmployerID = jp.EmployerID
WHERE EXISTS (
    SELECT 1 FROM Adopts ad WHERE ad.EmployerID = e.EmployerID
)
  AND g.DegreeField NOT IN ('Data Science & AI', 'Artificial Intelligence')
ORDER BY g.LastName, g.FirstName;

-- ---------------------------------------------------------
-- Query 4: Average advertised salary range per entry-level
-- job, limited to jobs that are affected by at least one
-- "High" impact AI technology and have at least 2 postings
-- (so the average isn't based on a single outlier).
-- Technique: subquery in WHERE + GROUP BY + HAVING.
-- A4: most real postings have no salary, so only postings
-- with a salary are counted (before, PostingCount included
-- them and the HAVING check was wrong). Grouped by currency,
-- because real salaries are in USD and mock salaries in EUR.
-- Real postings give one average salary, so Min = Max there.
-- ---------------------------------------------------------
SELECT
    elj.JobName,
    jp.SalaryCurrency,
    ROUND(AVG(jp.MinSalary), 2) AS AvgMinSalary,
    ROUND(AVG(jp.MaxSalary), 2) AS AvgMaxSalary,
    COUNT(jp.JobPostingID) AS PostingCount
FROM EntryLevelJob elj
         JOIN JobPosting jp ON jp.EntryLevelJobID = elj.EntryLevelJobID
WHERE elj.EntryLevelJobID IN (
    SELECT af.EntryLevelJobID FROM AffectsWithLevel af WHERE af.ImpactLevel = 'High'   -- A4: view
)
  AND jp.MinSalary IS NOT NULL                             -- A4
GROUP BY elj.EntryLevelJobID, elj.JobName, jp.SalaryCurrency
HAVING COUNT(jp.JobPostingID) >= 2
ORDER BY jp.SalaryCurrency, AvgMaxSalary DESC;
