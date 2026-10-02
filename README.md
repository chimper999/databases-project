# AI and Entry Level Jobs Database

Group project for the Databases course, DSAI, Maastricht University.

This database stores data about how AI affects entry-level job opportunities for new graduates: which employers adopt which AI technologies, which entry-level jobs those technologies affect, which jobs are posted, and which graduates apply to them.

## Files

The file numbers match the task numbers from the assignment:

- `sql/02-03_schema.sql` - relational schema, tables and constraints
- `sql/04_crud.sql` - insert, update and delete statements
- `sql/05_mock_data.sql` - mock data
- `sql/06_queries.sql` - advanced queries
- `docs/erd.png` - ERD from assignment 2
- `data/SOURCES.md` - real-world data sources, publication dates and licenses (assignment 4)
- `data/raw/` - raw dataset files (data_jobs filtered to entry-level rows, otherwise unchanged)
- `data/download_data.py` - downloads the raw datasets again

## How to run

**Requirements:** MySQL 8.0.16 or newer (older versions ignore CHECK constraints).

Run the files in this order. Each step depends on the previous one:

```bash
mysql -u root -p < sql/02-03_schema.sql
mysql -u root -p < sql/05_mock_data.sql
mysql -u root -p < sql/04_crud.sql
mysql -u root -p < sql/06_queries.sql
```

Or from inside the MySQL shell (started from the repository root):

```sql
SOURCE sql/02-03_schema.sql;
SOURCE sql/05_mock_data.sql;
SOURCE sql/04_crud.sql;
SOURCE sql/06_queries.sql;
```

The schema file drops and recreates the `ai_entry_jobs` database, so you can always start over by running it again.
Note: `04_crud.sql` should only be run once after loading the mock data. Running it a second time fails on a duplicate email. Rerun the schema and mock data first to reset.

## Group members

- Cinar Akinoglu
- Ahmad Nasser
- Mohammad Albdour
