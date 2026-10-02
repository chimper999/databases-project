"""
Downloads the raw datasets used in assignment 4 into data/raw/.

Dataset A (data_jobs) is 231 MB, which is too big for git, so we only keep
the rows whose job title marks the job as entry-level. Those rows are written
out unchanged. All cleaning happens in a later step.

Run from the repository root:  python3 data/download_data.py
"""

import os
import urllib.request

import pandas as pd

RAW_DIR = os.path.join(os.path.dirname(__file__), "raw")

# Pinned to a specific revision so the download is reproducible
DATA_JOBS_URL = (
    "https://huggingface.co/datasets/lukebarousse/data_jobs/resolve/"
    "ed776e5a0a8c40ea9d5efbd800772ae52e140f3e/data_jobs.csv"
)
GPTS_URL = "https://raw.githubusercontent.com/openai/GPTs-are-GPTs/main/data/occ_level.csv"
ONET_BASE = "https://www.onetcenter.org/dl_files/database/db_31_0_csv/"
ONET_FILES = ["job_zones", "occupation_data", "sample_of_reported_titles"]

# Job titles that mark a posting as entry-level
ENTRY_LEVEL_PATTERN = r"\b(?:junior|jr\.?|entry[- ]level|graduate|trainee)\b"


def download(url, path):
    print(f"Downloading {url}")
    urllib.request.urlretrieve(url, path)


def main():
    os.makedirs(RAW_DIR, exist_ok=True)

    # Dataset A: keep only the entry-level postings, all columns unchanged
    full_path = os.path.join(RAW_DIR, "data_jobs_full.csv")
    download(DATA_JOBS_URL, full_path)
    jobs = pd.read_csv(full_path, dtype=str, keep_default_na=False)
    is_entry = jobs["job_title"].str.contains(ENTRY_LEVEL_PATTERN, case=False, regex=True)
    jobs[is_entry].to_csv(os.path.join(RAW_DIR, "data_jobs_entry_level.csv"), index=False)
    os.remove(full_path)
    print(f"Kept {is_entry.sum()} of {len(jobs)} postings")

    # Dataset B
    download(GPTS_URL, os.path.join(RAW_DIR, "gpts_are_gpts_occ_level.csv"))

    # Auxiliary lookup tables
    for name in ONET_FILES:
        download(ONET_BASE + name + ".csv", os.path.join(RAW_DIR, f"onet_31_0_{name}.csv"))


if __name__ == "__main__":
    main()