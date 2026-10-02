"""
Assignment 4: cleans the raw datasets in data/raw/ and turns them into
sql/07_real_data.sql, which loads them into the ai_entry_jobs database.

Every step is explained in docs/data_cleaning.md. The cleaned tables are also
written to data/clean/ as CSV so they can be checked by hand.

Run from the repository root:  python3 data/clean_transform.py
"""

import os
import unicodedata

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
CLEAN = os.path.join(HERE, "clean")
SQL_OUT = os.path.join(HERE, "..", "sql", "07_real_data.sql")

# Highest O*NET Job Zone we count as entry-level for a new graduate.
# Zone 4 usually needs a bachelor's degree, zone 5 a graduate degree.
MAX_ENTRY_JOB_ZONE = 4

# data_jobs only has 7 job categories, so we map them by hand to the closest
# O*NET occupation. Where O*NET's own "reported job titles" list has the exact
# title we follow it, see docs/data_cleaning.md.
CATEGORY_TO_SOC = {
    "Data Analyst":              "15-2051.01",  # Business Intelligence Analysts
    "Data Scientist":            "15-2051.00",  # Data Scientists
    "Data Engineer":             "15-1243.00",  # Database Architects
    "Business Analyst":          "13-1111.00",  # Management Analysts
    "Software Engineer":         "15-1252.00",  # Software Developers
    "Machine Learning Engineer": "15-2051.00",  # Data Scientists
    "Cloud Engineer":            "15-1299.05",  # Information Security Engineers
}

# Dataset B score columns and the AI technology each one describes
TECH_SCORES = {
    "Large Language Models": "human_rating_alpha",  # the LLM on its own
    "LLM-Powered Software":  "human_rating_gamma",  # the LLM plus software built on it
}

HOURS_PER_YEAR = 40 * 52

# Letters that Unicode does not split into "letter + accent", but that MySQL
# still treats as the plain letter (we found 'Ørsted' and 'Orsted' in the data)
SPECIAL_LETTERS = str.maketrans({"ø": "o", "ł": "l", "đ": "d", "æ": "ae", "œ": "oe"})

report = []


def log(line):
    print(line)
    report.append(line)


def match_key(text):
    """Lower case, no accents, single spaces. Matches how MySQL's default
    collation (utf8mb4_0900_ai_ci) compares text for UNIQUE constraints."""
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return " ".join(text.casefold().translate(SPECIAL_LETTERS).split())


def tidy(text):
    """Trim and collapse repeated spaces, keep the original letter case."""
    return " ".join(text.split())


def impact_level(score):
    if score < 1 / 3:
        return "Low"
    if score < 2 / 3:
        return "Medium"
    return "High"


# ---------------------------------------------------------------------------
# Dataset B: GPTs are GPTs + O*NET Job Zones  ->  EntryLevelJob, Affects
# ---------------------------------------------------------------------------

def clean_occupations():
    log("== Dataset B: GPTs are GPTs ==")
    gpts = pd.read_csv(os.path.join(RAW, "gpts_are_gpts_occ_level.csv"))
    zones = pd.read_csv(os.path.join(RAW, "onet_31_0_job_zones.csv"))
    log(f"rows read: {len(gpts)}")
    log(f"missing values per column: {gpts.isna().sum().to_dict()}")
    log(f"duplicate SOC codes: {gpts['O*NET-SOC Code'].duplicated().sum()}, "
        f"duplicate titles: {gpts['Title'].duplicated().sum()}")

    occ = gpts.merge(zones[["O*NET-SOC Code", "Job Zone"]], on="O*NET-SOC Code", how="left")
    log(f"occupations without a Job Zone: {occ['Job Zone'].isna().sum()}")
    log(f"titles longer than 100 characters: {(occ['Title'].str.len() > 100).sum()}")

    occ = occ[occ["Job Zone"] <= MAX_ENTRY_JOB_ZONE].copy()
    log(f"kept as entry-level (Job Zone <= {MAX_ENTRY_JOB_ZONE}): {len(occ)}")

    jobs = pd.DataFrame({
        "JobName": occ["Title"].map(tidy),
        "OnetSocCode": occ["O*NET-SOC Code"],
        "JobZone": occ["Job Zone"].astype(int),
    })

    affects = []
    for tech, column in TECH_SCORES.items():
        for _, row in occ.iterrows():
            score = round(float(row[column]), 4)
            if score == 0:
                continue  # 0 means the job is not exposed, so there is no Affects row
            affects.append({
                "OnetSocCode": row["O*NET-SOC Code"],
                "TechnologyName": tech,
                "ImpactLevel": impact_level(score),
                "ExposureScore": score,
            })
    affects = pd.DataFrame(affects)
    log(f"Affects rows: {len(affects)} "
        f"({affects.groupby(['TechnologyName', 'ImpactLevel']).size().to_dict()})")
    return jobs, affects


# ---------------------------------------------------------------------------
# Dataset A: data_jobs  ->  Employer, JobPosting
# ---------------------------------------------------------------------------

def clean_postings(entry_level_codes):
    log("== Dataset A: data_jobs ==")
    # Read everything as text so we see exactly how missing values look
    raw = pd.read_csv(os.path.join(RAW, "data_jobs_entry_level.csv"),
                      dtype=str, keep_default_na=False)
    log(f"rows read: {len(raw)}")
    empty = (raw == "").sum()
    log(f"empty strings per column: {empty[empty > 0].to_dict()}")

    df = raw.copy()

    # 1. Exact duplicate rows
    n = df.duplicated().sum()
    df = df.drop_duplicates()
    log(f"[duplicates] exact duplicate rows removed: {n}")

    # 2. Whitespace in free-text fields
    for col in ["job_title", "company_name", "job_location", "search_location"]:
        changed = (df[col] != df[col].map(tidy)).sum()
        df[col] = df[col].map(tidy)
        log(f"[naming] {col}: {changed} values had extra spaces")

    # 3. Job category: a few junior titles were labelled "Senior ..." by the
    #    source's classifier. We drop the "Senior " prefix.
    senior = df["job_title_short"].str.startswith("Senior ")
    log(f"[naming] 'Senior ...' category on a junior title fixed: {senior.sum()}")
    df["job_title_short"] = df["job_title_short"].str.removeprefix("Senior ")
    df["OnetSocCode"] = df["job_title_short"].map(CATEGORY_TO_SOC)
    assert df["OnetSocCode"].notna().all()
    assert df["OnetSocCode"].isin(entry_level_codes).all()

    # 4. Dates: "YYYY-MM-DD HH:MM:SS" timestamp -> DATE
    posted = pd.to_datetime(df["job_posted_date"], format="%Y-%m-%d %H:%M:%S", errors="coerce")
    log(f"[dates] unparseable posting dates: {posted.isna().sum()}")
    df["PostedDate"] = posted.dt.date.astype(str)

    # 5. Location: "Anywhere" means remote, empty location falls back to the
    #    place the source searched in.
    anywhere = df["job_location"].eq("Anywhere")
    df.loc[anywhere, "job_location"] = "Remote"
    log(f"[naming] 'Anywhere' renamed to 'Remote' (as in the mock data): {anywhere.sum()}")
    missing_loc = df["job_location"].eq("")
    df.loc[missing_loc, "job_location"] = df.loc[missing_loc, "search_location"]
    log(f"[missing] empty location filled from search_location: {missing_loc.sum()}")

    # 6. Salary: only one average value, as year, hour or month rate.
    #    Only US salaries are kept, because the currency is not given.
    year = pd.to_numeric(df["salary_year_avg"], errors="coerce")
    hour = pd.to_numeric(df["salary_hour_avg"], errors="coerce")
    salary = year.fillna(hour * HOURS_PER_YEAR)
    log(f"[missing] salary given: {salary.notna().sum()} "
        f"(year {year.notna().sum()}, hour {hour.notna().sum()}), "
        f"rate is 'month' but no value: {((df['salary_rate'] == 'month') & salary.isna()).sum()}")
    non_us = salary.notna() & df["job_country"].ne("United States")
    salary[non_us] = float("nan")
    log(f"[missing] non-US salaries dropped (unknown currency): {non_us.sum()}")
    df["Salary"] = salary.round(2)

    # 7. Company names: the same company is written in different ways
    #    ("AbbVie" / "Abbvie"). Use the most common spelling per company.
    df["company_key"] = df["company_name"].map(match_key)
    counts = df.groupby(["company_key", "company_name"]).size().reset_index(name="n")
    counts = counts.sort_values(["company_key", "n", "company_name"], ascending=[True, False, True])
    canonical = counts.drop_duplicates("company_key").set_index("company_key")["company_name"]
    variants = df["company_name"].nunique() - len(canonical)
    df["CompanyName"] = df["company_key"].map(canonical)
    log(f"[naming] company spellings merged: {variants} "
        f"({df['company_name'].nunique()} spellings -> {len(canonical)} companies)")

    # 8. Same posting listed more than once (same company, title, location
    #    and day, usually found on several job sites). Keep the one with a salary.
    df["dup_key"] = (df["company_key"] + "|" + df["job_title"].map(match_key) + "|"
                     + df["job_location"].map(match_key) + "|" + df["PostedDate"])
    df = df.sort_values("Salary", na_position="last")
    n = df["dup_key"].duplicated().sum()
    df = df.drop_duplicates("dup_key").sort_index()
    log(f"[duplicates] same posting on several job sites removed: {n}")

    assert df["job_title"].str.len().max() <= 150
    assert df["job_location"].str.len().max() <= 100
    assert df["CompanyName"].str.len().max() <= 150

    postings = pd.DataFrame({
        "CompanyName": df["CompanyName"],
        "OnetSocCode": df["OnetSocCode"],
        "JobTitle": df["job_title"],
        "PostedDate": df["PostedDate"],
        "MinSalary": df["Salary"],
        "MaxSalary": df["Salary"],
        "SalaryCurrency": df["Salary"].notna().map({True: "USD", False: None}),
        "Location": df["job_location"],
    })
    employers = pd.DataFrame({"CompanyName": sorted(postings["CompanyName"].unique())})
    log(f"final: {len(employers)} employers, {len(postings)} job postings, "
        f"{postings['MinSalary'].notna().sum()} with salary")
    return employers, postings


# ---------------------------------------------------------------------------
# SQL output
# ---------------------------------------------------------------------------

def sql_value(v):
    if v is None or (isinstance(v, float) and pd.isna(v)):
        return "NULL"
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"


def inserts(table, columns, df, batch=500):
    out = []
    rows = [tuple(r) for r in df[columns].itertuples(index=False)]
    for i in range(0, len(rows), batch):
        values = ",\n".join("(" + ", ".join(sql_value(v) for v in r) + ")" for r in rows[i:i + batch])
        out.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n{values};\n")
    return "\n".join(out)


def write_sql(jobs, affects, employers, postings):
    parts = [f"""-- =========================================================
-- Group Project: AI and entry level jobs
-- Assignment 4: load the real-world data
--
-- GENERATED by data/clean_transform.py, do not edit by hand.
-- Sources: data/SOURCES.md, cleaning steps: docs/data_cleaning.md
--
-- Run after 02-03_schema.sql and 05_mock_data.sql.
-- =========================================================

USE ai_entry_jobs;

-- Needed for non-English company names
SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- AI technologies (Dataset B). "Large Language Models"
-- already exists in the mock data, so it is only added if missing.
-- ---------------------------------------------------------
INSERT INTO AITechnology (TechnologyName)
SELECT t.TechnologyName
FROM (SELECT 'Large Language Models' AS TechnologyName
      UNION ALL SELECT 'LLM-Powered Software') t
WHERE NOT EXISTS (SELECT 1 FROM AITechnology a WHERE a.TechnologyName = t.TechnologyName);

-- ---------------------------------------------------------
-- Entry-level jobs: O*NET occupations with Job Zone <= {MAX_ENTRY_JOB_ZONE}
-- ---------------------------------------------------------
""",
        inserts("EntryLevelJob", ["JobName", "OnetSocCode", "JobZone"], jobs),
        """
-- ---------------------------------------------------------
-- Affects (Dataset B). Staging table first, then join to get
-- the generated IDs.
-- ---------------------------------------------------------
CREATE TEMPORARY TABLE stg_affects (
    OnetSocCode     CHAR(10)        NOT NULL,
    TechnologyName  VARCHAR(100)    NOT NULL,
    ExposureScore   DECIMAL(5,4)    NOT NULL
);

""",
        inserts("stg_affects", ["OnetSocCode", "TechnologyName", "ExposureScore"], affects),
        """
INSERT INTO Affects (AITechnologyID, EntryLevelJobID, ExposureScore)
SELECT t.AITechnologyID, j.EntryLevelJobID, s.ExposureScore
FROM stg_affects s
         JOIN AITechnology t ON t.TechnologyName = s.TechnologyName
         JOIN EntryLevelJob j ON j.OnetSocCode = s.OnetSocCode;

DROP TEMPORARY TABLE stg_affects;

-- ---------------------------------------------------------
-- Employers and job postings (Dataset A)
-- ---------------------------------------------------------
CREATE TEMPORARY TABLE stg_posting (
    CompanyName     VARCHAR(150)    NOT NULL,
    OnetSocCode     CHAR(10)        NOT NULL,
    JobTitle        VARCHAR(150)    NOT NULL,
    PostedDate      DATE            NOT NULL,
    MinSalary       DECIMAL(8,2),
    MaxSalary       DECIMAL(8,2),
    SalaryCurrency  CHAR(3),
    Location        VARCHAR(100)    NOT NULL
);

""",
        inserts("stg_posting", ["CompanyName", "OnetSocCode", "JobTitle", "PostedDate",
                                "MinSalary", "MaxSalary", "SalaryCurrency", "Location"], postings),
        """
-- Employers that are already in the mock data (e.g. Booking.com,
-- Philips) are matched by name and not inserted a second time.
-- Their size is unknown in the real data, so CompanySize stays NULL.
INSERT INTO Employer (CompanyName)
SELECT DISTINCT s.CompanyName
FROM stg_posting s
WHERE NOT EXISTS (SELECT 1 FROM Employer e WHERE e.CompanyName = s.CompanyName);

INSERT INTO JobPosting
    (EmployerID, EntryLevelJobID, JobTitle, PostedDate, MinSalary, MaxSalary, SalaryCurrency, Location)
SELECT e.EmployerID, j.EntryLevelJobID, s.JobTitle, s.PostedDate,
       s.MinSalary, s.MaxSalary, s.SalaryCurrency, s.Location
FROM stg_posting s
         JOIN Employer e ON e.CompanyName = s.CompanyName
         JOIN EntryLevelJob j ON j.OnetSocCode = s.OnetSocCode;

DROP TEMPORARY TABLE stg_posting;
"""]
    with open(SQL_OUT, "w", encoding="utf-8") as f:
        f.write("".join(parts))


def main():
    os.makedirs(CLEAN, exist_ok=True)
    jobs, affects = clean_occupations()
    employers, postings = clean_postings(set(jobs["OnetSocCode"]))

    jobs.to_csv(os.path.join(CLEAN, "entry_level_job.csv"), index=False)
    affects.to_csv(os.path.join(CLEAN, "affects.csv"), index=False)
    employers.to_csv(os.path.join(CLEAN, "employer.csv"), index=False)
    postings.to_csv(os.path.join(CLEAN, "job_posting.csv"), index=False)
    write_sql(jobs, affects, employers, postings)

    with open(os.path.join(CLEAN, "cleaning_report.txt"), "w") as f:
        f.write("\n".join(report) + "\n")


if __name__ == "__main__":
    main()
