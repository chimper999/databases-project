-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 4 - Task 5: realistic mock data
--
-- Run this AFTER 02-03_schema.sql (it depends on those tables
-- existing and being empty). Re-running 02-03_schema.sql wipes
-- everything, so re-run this file again afterwards.
--
-- Load order matches the FK dependencies: parent tables first
-- (Graduate, Employer, EntryLevelJob, AITechnology), then the
-- child tables that reference them (JobPosting, WorkplaceTraining),
-- then the many-to-many bridge tables last (Applies, Adopts,
-- Affects).
--
-- IDs are AUTO_INCREMENT, so we never write them by hand. Every
-- INSERT that needs a foreign key looks it up with a subquery on
-- a unique natural column (Email, CompanyName, JobName,
-- TechnologyName, JobTitle) instead of guessing the numeric ID.
--
-- Dates/employers/locations are deliberately spread out (not
-- flat) so GROUP BY / trend-style queries have something
-- interesting to show.
-- =========================================================

USE ai_entry_jobs;

-- ---------------------------------------------------------
-- Parent tables
-- ---------------------------------------------------------

INSERT INTO Graduate (FirstName, LastName, Email, GraduationYear, DegreeField, University) VALUES
('Sofia',   'Bakker',     'sofia.bakker@gmail.com',    2023, 'Computer Science',       'Maastricht University'),
('Liam',    'de Vries',   'liam.devries@gmail.com',    2024, 'Data Science & AI',      'Maastricht University'),
('Noor',    'El Amrani',  'noor.elamrani@gmail.com',   2022, 'Business Analytics',     'Tilburg University'),
('Finn',    'Jansen',     'finn.jansen@gmail.com',     2023, 'Artificial Intelligence','Utrecht University'),
('Mia',     'Petrova',    'mia.petrova@gmail.com',     2024, 'Computer Science',       'VU Amsterdam'),
('Daan',    'Visser',     'daan.visser@gmail.com',     2023, 'Information Science',    'Maastricht University'),
('Elena',   'Rossi',      'elena.rossi@gmail.com',     2022, 'Marketing',              'Erasmus University Rotterdam'),
('Youssef', 'Haddad',     'youssef.haddad@gmail.com',  2024, 'Data Science & AI',      'Maastricht University'),
('Anna',    'Kowalski',   'anna.kowalski@gmail.com',   2023, 'Computer Science',       'TU Delft'),
('Lucas',   'Silva',      'lucas.silva@gmail.com',     2025, 'Business Analytics',     'Maastricht University'),
('Zoe',     'Mulder',     'zoe.mulder@gmail.com',      2022, 'Communication Science',  'Radboud University'),
('Ravi',    'Patel',      'ravi.patel@gmail.com',      2024, 'Artificial Intelligence','Maastricht University');

INSERT INTO Employer (CompanyName, CompanySize) VALUES
('Booking.com',              'Large'),
('Adyen',                    'Large'),
('Bright Cape',              'Small'),
('DataRobot Analytics BV',   'Medium'),
('Philips',                  'Large'),
('Mollie',                   'Medium'),
('Elastic',                  'Medium'),
('FreshMind Consulting',     'Small');

INSERT INTO EntryLevelJob (JobName) VALUES
('Junior Data Analyst'),
('Graduate Software Engineer'),
('AI Support Specialist'),
('Junior Marketing Analyst'),
('Associate Consultant'),
('Junior QA Engineer'),
('Entry-Level UX Researcher');

INSERT INTO AITechnology (TechnologyName) VALUES
('Large Language Models'),
('Computer Vision'),
('Robotic Process Automation'),
('Predictive Analytics'),
('AI Coding Assistants'),
('Recommendation Systems');

-- ---------------------------------------------------------
-- Child tables (reference parents via subquery lookups)
-- ---------------------------------------------------------

INSERT INTO JobPosting
    (EmployerID, EntryLevelJobID, JobTitle, JobDescription, PostedDate, ClosingDate, MinSalary, MaxSalary, Location)
VALUES
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),
 'Junior Data Analyst - Pricing Team', 'Support the pricing team with dashboards and ad-hoc analysis.',
 '2025-01-15', '2025-03-01', 34000.00, 40000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),
 'Graduate Software Engineer - Web Platform', 'Join the platform team building booking.com core web apps.',
 '2025-03-03', '2025-04-15', 40000.00, 50000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'AI Support Specialist'),
 'AI Support Specialist - Merchant Risk', 'Help tune and monitor ML-based merchant risk scoring.',
 '2025-02-10', '2025-03-24', 38000.00, 46000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),
 'Graduate Software Engineer - Payments Core', 'Work on the core payments processing engine.',
 '2025-06-05', '2025-07-20', 42000.00, 52000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Bright Cape'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),
 'Junior Data Analyst - Client Insights', 'Build reporting for consulting clients across industries.',
 '2025-04-02', '2025-05-15', 33000.00, 39000.00, 'Maastricht'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Bright Cape'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Associate Consultant'),
 'Associate Consultant - Data Strategy', 'Advise SME clients on data and analytics strategy.',
 '2025-07-01', '2025-08-12', 36000.00, 44000.00, 'Maastricht'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'DataRobot Analytics BV'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'AI Support Specialist'),
 'AI Support Specialist - Internal Tools', 'Support internal teams using DataRobot''s ML platform.',
 '2025-01-20', '2025-03-05', 35000.00, 41000.00, 'Eindhoven'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'DataRobot Analytics BV'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),
 'Junior Data Analyst - Forecasting', 'Prepare and validate data for forecasting models.',
 '2025-05-12', '2025-06-25', 34000.00, 40000.00, 'Eindhoven'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),
 'Graduate Software Engineer - Imaging Systems', 'Build software for medical imaging devices.',
 '2025-02-18', '2025-04-01', 39000.00, 48000.00, 'Eindhoven'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior QA Engineer'),
 'Junior QA Engineer - Connected Devices', 'Test connected health devices before release.',
 '2025-08-04', '2025-09-18', 33000.00, 38000.00, 'Eindhoven'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'AI Support Specialist'),
 'AI Support Specialist - Diagnostics Team', 'Support AI models used in diagnostic imaging.',
 '2025-05-22', '2025-07-05', 37000.00, 45000.00, 'Eindhoven'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Mollie'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),
 'Graduate Software Engineer - Checkout Experience', 'Improve the merchant checkout experience.',
 '2025-03-14', '2025-04-28', 41000.00, 51000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Mollie'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Marketing Analyst'),
 'Junior Marketing Analyst - Growth Team', 'Analyze campaign performance for the growth team.',
 '2025-06-19', '2025-08-01', 32000.00, 38000.00, 'Amsterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Elastic'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),
 'Graduate Software Engineer - Search Infrastructure', 'Work on distributed search infrastructure.',
 '2025-04-09', '2025-05-23', 40000.00, 49000.00, 'Remote'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Elastic'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior QA Engineer'),
 'Junior QA Engineer - Cloud Platform', 'Test the managed cloud platform release pipeline.',
 '2025-07-15', '2025-08-29', 34000.00, 41000.00, 'Remote'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'FreshMind Consulting'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Associate Consultant'),
 'Associate Consultant - AI Adoption Advisory', 'Help clients plan responsible AI adoption.',
 '2025-02-25', '2025-04-10', 35000.00, 43000.00, 'Rotterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'FreshMind Consulting'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Entry-Level UX Researcher'),
 'Entry-Level UX Researcher - Client Experience', 'Run usability studies for consulting clients.',
 '2025-08-11', '2025-09-24', 33000.00, 40000.00, 'Rotterdam'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),
 (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Entry-Level UX Researcher'),
 'Entry-Level UX Researcher - Traveler App', 'Study traveler behaviour in the mobile app.',
 '2025-09-01', '2025-10-15', 32000.00, 39000.00, 'Amsterdam');

INSERT INTO WorkplaceTraining
    (EmployerID, AITechnologyID, TrainingName, TrainingType, Duration, Format)
VALUES
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),
 'Prompt Engineering Basics', 'Technical Upskilling', 8, 'Online'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),
 'Secure Coding with AI Assistants', 'Technical Upskilling', 6, 'Hybrid'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Bright Cape'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Robotic Process Automation'),
 'Intro to RPA', 'Technical Upskilling', 4, 'In person'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'DataRobot Analytics BV'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),
 'Predictive Modeling Bootcamp', 'Technical Upskilling', 16, 'Hybrid'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Computer Vision'),
 'Computer Vision for QA', 'Technical Upskilling', 12, 'In person'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Mollie'),
 NULL,
 'Effective Onboarding', 'General Onboarding', 3, 'Online'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Elastic'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),
 'AI Coding Assistants Workshop', 'Technical Upskilling', 5, 'Online'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'FreshMind Consulting'),
 NULL,
 'Client Communication Skills', 'Soft Skills', 4, 'In person'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Recommendation Systems'),
 'Recommendation Systems Deep Dive', 'Technical Upskilling', 10, 'Hybrid'),

((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),
 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),
 'Fraud Detection with LLMs', 'Technical Upskilling', 8, 'Online');

-- ---------------------------------------------------------
-- Bridge tables (many to many) - go last
-- ---------------------------------------------------------

INSERT INTO Applies (GraduateID, JobPostingID) VALUES
((SELECT GraduateID FROM Graduate WHERE Email = 'sofia.bakker@gmail.com'),    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Pricing Team')),
((SELECT GraduateID FROM Graduate WHERE Email = 'sofia.bakker@gmail.com'),    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Web Platform')),
((SELECT GraduateID FROM Graduate WHERE Email = 'sofia.bakker@gmail.com'),    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior QA Engineer - Connected Devices')),
((SELECT GraduateID FROM Graduate WHERE Email = 'liam.devries@gmail.com'),    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'AI Support Specialist - Merchant Risk')),
((SELECT GraduateID FROM Graduate WHERE Email = 'liam.devries@gmail.com'),    (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'AI Support Specialist - Internal Tools')),
((SELECT GraduateID FROM Graduate WHERE Email = 'noor.elamrani@gmail.com'),   (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Client Insights')),
((SELECT GraduateID FROM Graduate WHERE Email = 'noor.elamrani@gmail.com'),   (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Associate Consultant - Data Strategy')),
((SELECT GraduateID FROM Graduate WHERE Email = 'finn.jansen@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'AI Support Specialist - Diagnostics Team')),
((SELECT GraduateID FROM Graduate WHERE Email = 'finn.jansen@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Imaging Systems')),
((SELECT GraduateID FROM Graduate WHERE Email = 'mia.petrova@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Payments Core')),
((SELECT GraduateID FROM Graduate WHERE Email = 'mia.petrova@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Checkout Experience')),
((SELECT GraduateID FROM Graduate WHERE Email = 'daan.visser@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior QA Engineer - Connected Devices')),
((SELECT GraduateID FROM Graduate WHERE Email = 'daan.visser@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior QA Engineer - Cloud Platform')),
((SELECT GraduateID FROM Graduate WHERE Email = 'elena.rossi@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Marketing Analyst - Growth Team')),
((SELECT GraduateID FROM Graduate WHERE Email = 'elena.rossi@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Entry-Level UX Researcher - Client Experience')),
((SELECT GraduateID FROM Graduate WHERE Email = 'youssef.haddad@gmail.com'),  (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Forecasting')),
((SELECT GraduateID FROM Graduate WHERE Email = 'youssef.haddad@gmail.com'),  (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'AI Support Specialist - Internal Tools')),
((SELECT GraduateID FROM Graduate WHERE Email = 'anna.kowalski@gmail.com'),   (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Search Infrastructure')),
((SELECT GraduateID FROM Graduate WHERE Email = 'anna.kowalski@gmail.com'),   (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior QA Engineer - Cloud Platform')),
((SELECT GraduateID FROM Graduate WHERE Email = 'lucas.silva@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Associate Consultant - AI Adoption Advisory')),
((SELECT GraduateID FROM Graduate WHERE Email = 'lucas.silva@gmail.com'),     (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Junior Data Analyst - Forecasting')),
((SELECT GraduateID FROM Graduate WHERE Email = 'zoe.mulder@gmail.com'),      (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Entry-Level UX Researcher - Traveler App')),
((SELECT GraduateID FROM Graduate WHERE Email = 'zoe.mulder@gmail.com'),      (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Entry-Level UX Researcher - Client Experience')),
((SELECT GraduateID FROM Graduate WHERE Email = 'ravi.patel@gmail.com'),      (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'AI Support Specialist - Merchant Risk')),
((SELECT GraduateID FROM Graduate WHERE Email = 'ravi.patel@gmail.com'),      (SELECT JobPostingID FROM JobPosting WHERE JobTitle = 'Graduate Software Engineer - Imaging Systems'));

INSERT INTO Adopts (EmployerID, AITechnologyID, AdoptionDate, ImplementationType) VALUES
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),            (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),      '2024-09-01', 'In-house LLM-powered customer support chatbot'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Booking.com'),            (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Recommendation Systems'),      '2023-05-15', 'Personalized search ranking engine'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),                  (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),        '2024-11-10', 'Company-wide GitHub Copilot rollout'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Adyen'),                  (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        '2023-08-20', 'Real-time fraud risk scoring model'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Bright Cape'),            (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Robotic Process Automation'), '2024-02-14', 'Automated client reporting pipelines'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'DataRobot Analytics BV'), (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        '2022-11-01', 'Core forecasting product offering'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),                (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Computer Vision'),            '2023-03-10', 'Automated defect detection on production lines'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Philips'),                (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        '2024-06-01', 'Predictive maintenance for connected devices'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Mollie'),                 (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),        '2025-01-15', 'Developer productivity pilot program'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Elastic'),                (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),      '2024-04-22', 'Semantic search and RAG features'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'FreshMind Consulting'),   (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Robotic Process Automation'), '2023-09-05', 'Client workflow automation service line'),
((SELECT EmployerID FROM Employer WHERE CompanyName = 'Elastic'),                (SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Recommendation Systems'),      '2024-08-30', 'Content relevance ranking for search clients');

INSERT INTO Affects (AITechnologyID, EntryLevelJobID, ImpactLevel) VALUES
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),      (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'AI Support Specialist'),       'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),      (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Marketing Analyst'),    'Medium'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Large Language Models'),      (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Entry-Level UX Researcher'),   'Medium'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Computer Vision'),             (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior QA Engineer'),          'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Computer Vision'),             (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),  'Low'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Robotic Process Automation'),  (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),         'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Robotic Process Automation'),  (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Associate Consultant'),        'Medium'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Data Analyst'),         'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Associate Consultant'),        'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Graduate Software Engineer'),  'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior QA Engineer'),          'Medium'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'AI Coding Assistants'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'AI Support Specialist'),       'Low'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Recommendation Systems'),      (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Marketing Analyst'),    'High'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Recommendation Systems'),      (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Entry-Level UX Researcher'),   'Low'),
((SELECT AITechnologyID FROM AITechnology WHERE TechnologyName = 'Predictive Analytics'),        (SELECT EntryLevelJobID FROM EntryLevelJob WHERE JobName = 'Junior Marketing Analyst'),    'Medium');
