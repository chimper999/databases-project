-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 4 - Task 4: basic SQL operations (add / update /
-- remove data)
--
-- Run this AFTER 02-03_schema.sql and 05_mock_data.sql, since
-- it operates on rows that mock data already created.
--
-- Same rule as the mock data file: IDs are AUTO_INCREMENT, so
-- foreign keys are looked up by a unique natural column
-- (Email, CompanyName, JobTitle, TrainingName) via a subquery
-- instead of hardcoded numbers.
-- =========================================================

USE ai_entry_jobs;

-- ---------------------------------------------------------
-- 1. ADD DATA (INSERT)
-- ---------------------------------------------------------

-- 1a. A new graduate registers
INSERT INTO Graduate (FirstName, LastName, Email, GraduationYear, DegreeField, University)
VALUES ('Julia', 'Novak', 'julia.novak@gmail.com', 2025, 'Data Science & AI', 'Maastricht University');

-- 1b. A new employer joins the platform and posts a job
INSERT INTO Employer (CompanyName, CompanySize)
VALUES ('Nexora Robotics', 'Small');

INSERT INTO JobPosting
    (EmployerID, EntryLevelJobID, JobTitle, JobDescription, PostedDate, ClosingDate, MinSalary, MaxSalary, Location)
VALUES (
    (SELECT EmployerID FROM Employer WHERE CompanyName = 'Nexora Robotics'),
    (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),
    'Junior Data Analyst - Robotics Ops',
    'Analyze sensor data from warehouse robots.',
    '2025-09-10', '2025-10-24', 34000.00, 41000.00, 'Eindhoven'
);

-- 1c. The new graduate applies to that new posting
INSERT INTO Applies (GraduateID, JobPostingID)
VALUES (
    (SELECT GraduateID FROM Graduate WHERE Email = 'julia.novak@gmail.com'),
    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Robotics Ops')
);

-- ---------------------------------------------------------
-- 2. UPDATE DATA
-- ---------------------------------------------------------

-- 2a. Extend the application deadline on an existing posting
UPDATE JobPosting
SET ClosingDate = '2025-06-01'
WHERE JobTitle = 'Junior Data Analyst - Client Insights';

-- 2b. Mollie has grown since the posting was made, so its size changes
UPDATE Employer
SET CompanySize = 'Large'
WHERE CompanyName = 'Mollie';

-- 2c. Fix/update the new graduate's degree field
UPDATE Graduate
SET DegreeField = 'Artificial Intelligence'
WHERE Email = 'julia.novak@gmail.com';

-- ---------------------------------------------------------
-- 3. REMOVE DATA (DELETE)
-- ---------------------------------------------------------

-- 3a. A graduate withdraws one specific application
DELETE FROM Applies
WHERE GraduateID = (SELECT GraduateID FROM Graduate WHERE Email = 'zoe.mulder@gmail.com')
  AND JobPostingID = (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Entry-Level UX Researcher - Traveler App');

-- 3b. A training session gets cancelled
DELETE FROM WorkplaceTraining
WHERE TrainingName = 'Client Communication Skills';

-- 3c. The Robotics Ops posting from step 1b is closed and removed.
-- Applies has ON DELETE CASCADE to JobPosting, so the application
-- we inserted in 1c is deleted automatically along with it - no
-- separate DELETE needed for that row.
DELETE FROM JobPosting
WHERE JobTitle = 'Junior Data Analyst - Robotics Ops';
