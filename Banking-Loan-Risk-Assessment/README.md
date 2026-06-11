# Banking Loan Risk Assessment & Analytics Dashboard

A portfolio-ready end-to-end banking analytics project that combines SQL, Python, and Power BI to analyze customer applications, identify default risk drivers, and build interactive business dashboards.

## Why this project stands out

- Uses a production-style workflow: OLTP schema -> cleaned data -> feature engineering -> machine learning -> reporting layer
- Includes realistic synthetic data: 10,000 customers, 15,000 loans, 100 branches, and 50,000 payments
- Covers fresher-friendly implementation with industry-level structure and documentation
- Demonstrates database design, analytical SQL, Python EDA, predictive modeling, and BI storytelling in one repo

## Tech stack

- SQL: MySQL 8 compatible scripts
- Python: `pandas`, `matplotlib`, `scikit-learn`, `xgboost`
- Power BI: dashboard specification, DAX measures, and modeling guide
- GitHub: repository structure and documentation

## Project structure

```text
Banking-Loan-Risk-Assessment/
├── Dataset/
│   ├── branches.csv
│   ├── customers.csv
│   ├── loans.csv
│   ├── payments.csv
│   └── processed/
├── SQL/
│   ├── DDL.sql
│   ├── DML.sql
│   └── Queries.sql
├── Python/
│   ├── Data_Cleaning.py
│   ├── EDA.py
│   ├── Model_Training.py
│   └── requirements.txt
├── PowerBI/
│   ├── Dashboard_Spec.md
│   └── DAX_Measures.md
├── Documentation/
│   ├── Architecture.png
│   ├── Data_Model.png
│   ├── Resume_Project_Description.md
│   ├── Interview_QA.md
│   ├── STAR_Explanation.md
│   ├── Data_Warehouse_Design.md
│   └── Business_Recommendations.md
└── README.md
```

## Data model

The OLTP schema includes:

- `customers`
- `loans`
- `branches`
- `payments`

`Branch_ID` was added to `loans` so the project can support branch-wise analytics, which is required for revenue and performance reporting.

## Step-by-step workflow

### 1. Generate or inspect the dataset

The repository already includes realistic synthetic CSV files. Use them directly in SQL, Python, or Power BI.

### 2. Run SQL scripts

1. Execute `SQL/DDL.sql`
2. Execute `SQL/DML.sql`
3. Execute `SQL/Queries.sql`

These scripts create the schema, load the data, define views/procedures/triggers, and provide 25+ business questions.

### 3. Run Python analysis

Install dependencies:

```bash
pip install -r Python/requirements.txt --break-system-packages
```

Run the pipeline:

```bash
python Python/Data_Cleaning.py
python Python/EDA.py
python Python/Model_Training.py
```

Outputs:

- Cleaned files in `Dataset/processed`
- EDA charts in `Documentation/EDA_Assets`
- Model metrics in `Documentation/Model_Outputs`

### 4. Build the Power BI dashboard

Use `PowerBI/Dashboard_Spec.md` and `PowerBI/DAX_Measures.md` to create the final `.pbix` file in Power BI Desktop.

Suggested pages:

- Executive Overview
- Loan Analytics
- Risk Analytics
- Branch Performance

## Business questions answered

- Which customer segments are most likely to default?
- Which states have the highest approval rates?
- Which branches generate the most collections revenue?
- Which loan products carry the highest credit risk?
- How are disbursement volumes trending over time?
- Which customers should be flagged as high-risk?

## Industry-level enhancements

- Data warehouse star schema design
- ETL pipeline explanation
- Branch-level risk monitoring
- Predictive approval and default scoring
- Business recommendations and future roadmap

## How to present this in interviews

Focus on four things:

1. The schema design and why normalization matters
2. The SQL layer and how queries answer business questions
3. The feature engineering and model evaluation approach
4. The way Power BI converts technical analysis into decision-ready visuals

## Notes

- The repo includes everything needed to build the dashboard, but the actual `.pbix` file must be created in Power BI Desktop because PBIX is a binary desktop artifact.
- The data is synthetic and safe for public GitHub use.
