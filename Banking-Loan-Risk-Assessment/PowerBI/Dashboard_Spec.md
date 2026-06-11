# Power BI Dashboard Build Guide

This project ships the dataset, SQL layer, feature engineering logic, and the dashboard specification needed to build the `.pbix` file in Power BI Desktop.

## Data model

Use a star schema for Power BI:

- `Fact_Loans`: one row per loan application
- `Fact_Payments`: one row per payment
- `Dim_Customers`: customer attributes
- `Dim_Branches`: branch attributes
- `Dim_Date`: calendar table for application and payment dates

Relationships:

- `Dim_Customers[Customer_ID]` -> `Fact_Loans[Customer_ID]`
- `Dim_Branches[Branch_ID]` -> `Fact_Loans[Branch_ID]`
- `Fact_Loans[Loan_ID]` -> `Fact_Payments[Loan_ID]`
- `Dim_Date[Date]` -> `Fact_Loans[Application_Date]`
- `Dim_Date[Date]` -> `Fact_Payments[Payment_Date]`

## Pages

### Executive Overview

KPIs:

- Total Customers
- Total Loans
- Approval Rate
- Default Rate
- Revenue
- Average Risk Score

Visuals:

- KPI cards across the top
- Monthly disbursement line chart
- Approval status donut chart
- State-wise filled map
- Revenue by loan type clustered bar chart

### Loan Analytics

Visuals:

- Loan Type Analysis: stacked bar by loan type and approval status
- Monthly Trend: line chart by approved loan amount
- State-wise Distribution: map or treemap
- Approval Funnel: funnel chart by application stage
- Ticket Size Box Summary: box-and-whisker custom visual or column chart by loan type

### Risk Analytics

Visuals:

- Default prediction probability by state
- High-risk customers table with conditional formatting
- Credit score histogram
- Risk segmentation matrix by risk category and loan type
- Payment compliance scatter plot

### Branch Performance

Visuals:

- Revenue by Branch
- Top 10 Branches
- Branch Risk Comparison
- Collections vs Defaults scatter

## Interactions

- Add slicers for State, City, Branch, Loan Type, Approval Status, Risk Category, and Date
- Enable drill-through from state to branch and branch to customer
- Add tooltips with loan amount, credit score, compliance score, and predicted risk
- Use bookmarks for executive vs operational views

## Refresh workflow

1. Load cleaned CSVs from `Dataset/processed`
2. Validate data types in Power Query
3. Create the date table
4. Add DAX measures from `DAX_Measures.md`
5. Publish to Power BI Service when the PBIX is ready
