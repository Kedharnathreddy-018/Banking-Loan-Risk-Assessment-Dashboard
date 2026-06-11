# Interview Questions and Answers

## 1. Why did you add `Branch_ID` to the loans table?
The original business requirement asked for branch-wise analytics. To support branch-level revenue, risk, and approval analysis, each loan must be tied to the branch that handled the application.

## 2. Why did you use a normalized schema first and a star schema later?
Normalization supports clean transaction storage and reduces redundancy in the operational database. The star schema is better for Power BI because it simplifies relationships and improves reporting performance.

## 3. Which SQL concepts does this project demonstrate?
It covers DDL, DML, constraints, indexes, CTEs, window functions, views, stored procedures, triggers, and business reporting queries.

## 4. How did you identify risky customers?
I combined credit score, debt-to-income ratio, payment compliance, delinquency counts, and historical defaults to create a composite customer risk score and risk categories.

## 5. Why did you build separate approval and default models?
Loan approval is a front-door decision before a loan is issued. Default prediction is a post-approval risk problem, so the features, target population, and business use case are different.

## 6. Why use Random Forest and XGBoost in addition to Logistic Regression?
Logistic Regression gives a strong baseline and explainability. Random Forest and XGBoost capture non-linear relationships and interactions that are common in borrower behavior.

## 7. What metrics matter most for risk models?
Accuracy alone is not enough. Precision, recall, F1 score, and ROC-AUC matter because false approvals and missed defaults have direct financial impact.

## 8. How would you productionize this project?
I would automate ingestion, data validation, model retraining, and dashboard refresh. I would also add model monitoring, audit logs, and role-based access controls.

## 9. What business value does the dashboard provide?
It helps decision-makers monitor approval trends, identify risky segments, compare branches, and optimize collections strategy using near real-time KPIs.

## 10. What would you improve next?
I would add bureau data, repayment history depth, SHAP-based model explainability, and scheduled ETL into a cloud warehouse.
