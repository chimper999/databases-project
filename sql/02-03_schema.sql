-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 3 - Task 2 and 3: relational schema and
-- schema implementation (MySQL 8)
--
-- Run this file first. 04_crud.sql, 05_mock_data.sql and
-- 06_queries.sql all depend on the tables created here.
-- Run 05_mock_data.sql next, so the other two have data
-- to work with.
-- =========================================================

DROP DATABASE IF EXISTS ai_entry_jobs;
CREATE DATABASE ai_entry_jobs;
USE ai_entry_jobs;

-- ---------------------------------------------------------
-- Parent tables (no foreign keys, so these go first)
-- ---------------------------------------------------------

CREATE TABLE Graduate (
    GraduateID      INT             NOT NULL AUTO_INCREMENT,
    FirstName       VARCHAR(50)     NOT NULL,
    LastName        VARCHAR(50)     NOT NULL,
    Email           VARCHAR(255)    NOT NULL UNIQUE,
    GraduationYear  INT             NOT NULL,
    DegreeField     VARCHAR(100)    NOT NULL,
    University      VARCHAR(150)    NOT NULL,
    PRIMARY KEY (GraduateID),
    CHECK (GraduationYear BETWEEN 1950 AND 2100)
);

CREATE TABLE Employer (
    EmployerID      INT             NOT NULL AUTO_INCREMENT,
    CompanyName     VARCHAR(150)    NOT NULL UNIQUE,
    CompanySize     ENUM('Small', 'Medium', 'Large') NOT NULL,
    PRIMARY KEY (EmployerID)
);

CREATE TABLE EntryLevelJob (
    EntryLevelJobID INT             NOT NULL AUTO_INCREMENT,
    JobName         VARCHAR(100)    NOT NULL UNIQUE,
    PRIMARY KEY (EntryLevelJobID)
);

CREATE TABLE AITechnology (
    AITechnologyID  INT             NOT NULL AUTO_INCREMENT,
    TechnologyName  VARCHAR(100)    NOT NULL UNIQUE,
    PRIMARY KEY (AITechnologyID)
);

-- ---------------------------------------------------------
-- Child tables (one to many relationships)
-- ---------------------------------------------------------

CREATE TABLE JobPosting (
    JobPostingID    INT             NOT NULL AUTO_INCREMENT,
    EmployerID      INT             NOT NULL,
    EntryLevelJobID INT             NOT NULL,
    JobTitle        VARCHAR(150)    NOT NULL,
    JobDescription  TEXT,
    PostedDate      DATE            NOT NULL,
    ClosingDate     DATE,
    MinSalary       DECIMAL(8,2),
    MaxSalary       DECIMAL(8,2),
    Location        VARCHAR(100)    NOT NULL,
    PRIMARY KEY (JobPostingID),
    FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID),
    FOREIGN KEY (EntryLevelJobID) REFERENCES EntryLevelJob (EntryLevelJobID),
    CHECK (MaxSalary >= MinSalary),
    CHECK (ClosingDate >= PostedDate)
);

CREATE TABLE WorkplaceTraining (
    TrainingID      INT             NOT NULL AUTO_INCREMENT,
    EmployerID      INT             NOT NULL,
    AITechnologyID  INT,            -- empty if the training is not about AI
    TrainingName    VARCHAR(150)    NOT NULL,
    TrainingType    VARCHAR(100)    NOT NULL,
    Duration        INT             NOT NULL,   -- in hours
    Format          ENUM('Online', 'In person', 'Hybrid') NOT NULL,
    PRIMARY KEY (TrainingID),
    FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID)
        ON DELETE CASCADE,
    FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE SET NULL,
    CHECK (Duration > 0)
);

-- ---------------------------------------------------------
-- Bridge tables (many to many relationships)
-- ---------------------------------------------------------

CREATE TABLE Applies (
    GraduateID      INT             NOT NULL,
    JobPostingID    INT             NOT NULL,
    PRIMARY KEY (GraduateID, JobPostingID),
    FOREIGN KEY (GraduateID) REFERENCES Graduate (GraduateID)
        ON DELETE CASCADE,
    FOREIGN KEY (JobPostingID) REFERENCES JobPosting (JobPostingID)
        ON DELETE CASCADE
);

CREATE TABLE Adopts (
    EmployerID          INT             NOT NULL,
    AITechnologyID      INT             NOT NULL,
    AdoptionDate        DATE            NOT NULL,
    ImplementationType  VARCHAR(150)    NOT NULL,
    PRIMARY KEY (EmployerID, AITechnologyID),
    FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID)
        ON DELETE CASCADE,
    FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE CASCADE
);

CREATE TABLE Affects (
    AITechnologyID  INT             NOT NULL,
    EntryLevelJobID INT             NOT NULL,
    ImpactLevel     ENUM('Low', 'Medium', 'High') NOT NULL,
    PRIMARY KEY (AITechnologyID, EntryLevelJobID),
    FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE CASCADE,
    FOREIGN KEY (EntryLevelJobID) REFERENCES EntryLevelJob (EntryLevelJobID)
        ON DELETE CASCADE
);
