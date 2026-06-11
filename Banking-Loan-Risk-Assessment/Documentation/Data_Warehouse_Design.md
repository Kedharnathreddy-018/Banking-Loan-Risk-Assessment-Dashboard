# Data Warehouse and ETL Design

## Warehouse schema

Recommended star schema:

- `Dim_Customers`
- `Dim_Branches`
- `Dim_Date`
- `Dim_Loan_Type`
- `Fact_Loans`
- `Fact_Payments`

Grain:

- `Fact_Loans`: one row per loan application
- `Fact_Payments`: one row per payment transaction

## ETL flow

1. Extract customer, loan, branch, and payment data from CSV or OLTP tables
2. Clean missing values, enforce schema, and deduplicate records in Python
3. Generate analytical features such as DTI, payment compliance, and risk score
4. Load facts and dimensions into the reporting layer
5. Refresh the Power BI dataset and validate KPI reconciliation

## Best practices

- Separate raw, cleaned, and reporting-ready layers
- Use surrogate keys in the warehouse if this becomes a real production model
- Add data quality checks for null keys, duplicate IDs, and out-of-range scores
- Track model versions and dashboard refresh timestamps
