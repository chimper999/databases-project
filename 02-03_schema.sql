-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 3 - Task 3: schema implementation (MySQL 8)
--
-- Run this file first. 02_crud.sql, 03_mock_data.sql and
-- 04_queries.sql all depend on the tables created here.
-- =========================================================

DROP DATABASE IF EXISTS ai_entry_jobs;
CREATE DATABASE ai_entry_jobs
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE ai_entry_jobs;

-- ---------------------------------------------------------
-- Parent tables (no foreign keys, so these go first)
-- ---------------------------------------------------------

CREATE TABLE Graduate (
    GraduateID      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    FirstName       VARCHAR(50)     NOT NULL,
    LastName        VARCHAR(50)     NOT NULL,
    Email           VARCHAR(255)    NOT NULL,
    GraduationYear  SMALLINT UNSIGNED NOT NULL,
    DegreeField     VARCHAR(100)    NOT NULL,
    University      VARCHAR(150)    NOT NULL,
    PRIMARY KEY (GraduateID),
    CONSTRAINT uq_graduate_email UNIQUE (Email),
    CONSTRAINT chk_graduation_year
        CHECK (GraduationYear BETWEEN 1950 AND 2100),
    CONSTRAINT chk_email_format
        CHECK (Email LIKE '%_@_%._%')
) ENGINE = InnoDB;

CREATE TABLE Employer (
    EmployerID      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    CompanyName     VARCHAR(150)    NOT NULL,
    CompanySize     ENUM('Small', 'Medium', 'Large') NOT NULL,
    PRIMARY KEY (EmployerID),
    CONSTRAINT uq_employer_name UNIQUE (CompanyName)
) ENGINE = InnoDB;

CREATE TABLE EntryLevelJob (
    EntryLevelJobID INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    JobName         VARCHAR(100)    NOT NULL,
    PRIMARY KEY (EntryLevelJobID),
    CONSTRAINT uq_job_name UNIQUE (JobName)
) ENGINE = InnoDB;

CREATE TABLE AITechnology (
    AITechnologyID  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    TechnologyName  VARCHAR(100)    NOT NULL,
    PRIMARY KEY (AITechnologyID),
    CONSTRAINT uq_technology_name UNIQUE (TechnologyName)
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- Child tables (one to many relationships)
-- ---------------------------------------------------------

CREATE TABLE JobPosting (
    JobPostingID    INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    EmployerID      INT UNSIGNED    NOT NULL,
    EntryLevelJobID INT UNSIGNED    NOT NULL,
    JobTitle        VARCHAR(150)    NOT NULL,
    JobDescription  TEXT            NULL,
    PostedDate      DATE            NOT NULL,
    ClosingDate     DATE            NULL,
    MinSalary       DECIMAL(8,2)    NULL,
    MaxSalary       DECIMAL(8,2)    NULL,
    Location        VARCHAR(100)    NOT NULL,
    PRIMARY KEY (JobPostingID),
    CONSTRAINT fk_posting_employer
        FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_posting_job
        FOREIGN KEY (EntryLevelJobID) REFERENCES EntryLevelJob (EntryLevelJobID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_salary_order
        CHECK (MaxSalary IS NULL OR MinSalary IS NULL OR MaxSalary >= MinSalary),
    CONSTRAINT chk_salary_positive
        CHECK (MinSalary IS NULL OR MinSalary >= 0),
    CONSTRAINT chk_date_order
        CHECK (ClosingDate IS NULL OR ClosingDate >= PostedDate)
) ENGINE = InnoDB;

CREATE TABLE WorkplaceTraining (
    TrainingID      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    EmployerID      INT UNSIGNED    NOT NULL,
    AITechnologyID  INT UNSIGNED    NULL,   -- NULL if the training is not about AI
    TrainingName    VARCHAR(150)    NOT NULL,
    TrainingType    VARCHAR(100)    NOT NULL,
    Duration        SMALLINT UNSIGNED NOT NULL,   -- in hours
    Format          ENUM('Online', 'In person', 'Hybrid') NOT NULL,
    PRIMARY KEY (TrainingID),
    CONSTRAINT fk_training_employer
        FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_training_technology
        FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_duration
        CHECK (Duration > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- Bridge tables (many to many relationships)
-- ---------------------------------------------------------

CREATE TABLE Applies (
    GraduateID      INT UNSIGNED    NOT NULL,
    JobPostingID    INT UNSIGNED    NOT NULL,
    PRIMARY KEY (GraduateID, JobPostingID),
    CONSTRAINT fk_applies_graduate
        FOREIGN KEY (GraduateID) REFERENCES Graduate (GraduateID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_applies_posting
        FOREIGN KEY (JobPostingID) REFERENCES JobPosting (JobPostingID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE Adopts (
    EmployerID          INT UNSIGNED    NOT NULL,
    AITechnologyID      INT UNSIGNED    NOT NULL,
    AdoptionDate        DATE            NOT NULL,
    ImplementationType  VARCHAR(150)    NOT NULL,
    PRIMARY KEY (EmployerID, AITechnologyID),
    CONSTRAINT fk_adopts_employer
        FOREIGN KEY (EmployerID) REFERENCES Employer (EmployerID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_adopts_technology
        FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE Affects (
    AITechnologyID  INT UNSIGNED    NOT NULL,
    EntryLevelJobID INT UNSIGNED    NOT NULL,
    ImpactLevel     ENUM('Low', 'Medium', 'High') NOT NULL,
    PRIMARY KEY (AITechnologyID, EntryLevelJobID),
    CONSTRAINT fk_affects_technology
        FOREIGN KEY (AITechnologyID) REFERENCES AITechnology (AITechnologyID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_affects_job
        FOREIGN KEY (EntryLevelJobID) REFERENCES EntryLevelJob (EntryLevelJobID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- Indexes on the foreign keys we filter and join on most.
-- MySQL indexes FK columns automatically, so these are the
-- extra ones for our scope questions (demand over time).
-- ---------------------------------------------------------

CREATE INDEX idx_posting_date ON JobPosting (PostedDate);
CREATE INDEX idx_adoption_date ON Adopts (AdoptionDate);
