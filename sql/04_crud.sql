USE ai_entry_jobs;

INSERT INTO Graduate (FirstName, LastName, Email, GraduationYear, DegreeField, University)
VALUES ('Julia', 'Novak', 'julia.novak@gmail.com', 2025, 'Data Science & AI', 'Maastricht University');

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

INSERT INTO Applies (GraduateID, JobPostingID)
VALUES (
    (SELECT GraduateID FROM Graduate WHERE Email = 'julia.novak@gmail.com'),
    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Robotics Ops')
);

UPDATE JobPosting
SET ClosingDate = '2025-06-01'
WHERE JobTitle = 'Junior Data Analyst - Client Insights';

UPDATE Employer
SET CompanySize = 'Large'
WHERE CompanyName = 'Mollie';

UPDATE Graduate
SET DegreeField = 'Artificial Intelligence'
WHERE Email = 'julia.novak@gmail.com';

DELETE FROM Applies
WHERE GraduateID = (SELECT GraduateID FROM Graduate WHERE Email = 'zoe.mulder@gmail.com')
  AND JobPostingID = (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Entry-Level UX Researcher - Traveler App');

DELETE FROM WorkplaceTraining
WHERE TrainingName = 'Client Communication Skills';

DELETE FROM JobPosting
WHERE JobTitle = 'Junior Data Analyst - Robotics Ops';
