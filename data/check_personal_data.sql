-- =========================================================
-- Group Project: AI and entry level jobs
-- Personal data check (final assignment, Task 3)
--
-- Run this against the fully loaded database before making a
-- dump for Zenodo. Every row it returns must show 0 hits.
--
--   mariadb -u root --table < data/check_personal_data.sql
--
-- What it does: scans every text column in the database for
-- things that could identify a real person (e-mail addresses,
-- phone numbers) and confirms that the invented graduate
-- addresses all use the reserved example.com domain.
-- =========================================================

USE ai_entry_jobs;

-- An e-mail address anywhere EXCEPT the reserved example.com
-- domain. The "@" in job titles such as "Junior Data Analyst
-- @ ELEKS" is not an address, so the pattern asks for a dot
-- and a top level domain after the "@" as well.
SET @mail = _utf8mb4'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}' COLLATE utf8mb4_unicode_ci;

-- Seven or more digits in a row, with optional spaces, dots or
-- dashes: the shape of a phone number. This one is deliberately
-- wide, so it also catches things that only look like a phone
-- number. We checked all 60 hits by hand on 2026-10-09: every one
-- is a salary ("$60000.00 - $70000.00"), a job requisition number
-- ("JR-0000178", "T500-9578") or a year range ("2022-2023"), and
-- none is a phone number. Any new hit has to be checked the same
-- way before publishing.
SET @phone = _utf8mb4'[0-9][0-9 .-]{5,}[0-9]' COLLATE utf8mb4_unicode_ci;

SELECT 'Graduate.Email outside example.com' AS Check_, COUNT(*) AS Hits
FROM Graduate WHERE Email NOT LIKE '%@example.com'
UNION ALL
SELECT 'Graduate: other columns with an e-mail', COUNT(*) FROM Graduate
WHERE CONCAT_WS(' ', FirstName, LastName, DegreeField, University) REGEXP @mail
UNION ALL
SELECT 'Employer.CompanyName with an e-mail', COUNT(*) FROM Employer
WHERE CompanyName REGEXP @mail
UNION ALL
SELECT 'EntryLevelJob.JobName with an e-mail', COUNT(*) FROM EntryLevelJob
WHERE JobName REGEXP @mail
UNION ALL
SELECT 'AITechnology.TechnologyName with an e-mail', COUNT(*) FROM AITechnology
WHERE TechnologyName REGEXP @mail
UNION ALL
SELECT 'JobPosting: text columns with an e-mail', COUNT(*) FROM JobPosting
WHERE CONCAT_WS(' ', JobTitle, COALESCE(JobDescription, ''), Location) REGEXP @mail
UNION ALL
SELECT 'JobPosting: text columns with a phone number', COUNT(*) FROM JobPosting
WHERE CONCAT_WS(' ', JobTitle, COALESCE(JobDescription, ''), Location) REGEXP @phone
UNION ALL
SELECT 'WorkplaceTraining: text columns with an e-mail', COUNT(*) FROM WorkplaceTraining
WHERE CONCAT_WS(' ', TrainingName, TrainingType) REGEXP @mail
UNION ALL
SELECT 'Adopts.ImplementationType with an e-mail', COUNT(*) FROM Adopts
WHERE ImplementationType REGEXP @mail;
