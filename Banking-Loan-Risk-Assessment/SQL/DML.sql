USE banking_loan_risk_assessment;

/*
MySQL bulk load instructions.
Update the file paths to match your environment.
*/

LOAD DATA LOCAL INFILE 'Dataset/branches.csv'
INTO TABLE branches
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'Dataset/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'Dataset/loans.csv'
INTO TABLE loans
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'Dataset/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/*
Optional SQL Server alternative
BULK INSERT dbo.customers
FROM 'C:\Data\customers.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
*/

/*
Small sample inserts for manual testing
*/
INSERT INTO branches (Branch_ID, Branch_Name, City, State)
VALUES
(1001, 'Demo Central Branch', 'Bengaluru', 'Karnataka');

INSERT INTO customers (
    Customer_ID, Name, Age, Gender, Marital_Status, Education, Occupation,
    Annual_Income, Credit_Score, City, State
)
VALUES
(90001, 'Demo Applicant', 31, 'Female', 'Single', 'Graduate', 'IT Professional', 950000, 782, 'Bengaluru', 'Karnataka');

INSERT INTO loans (
    Loan_ID, Customer_ID, Branch_ID, Loan_Amount, Loan_Term, Interest_Rate,
    Loan_Type, Application_Date, Approval_Status, Default_Status
)
VALUES
(80001, 90001, 1001, 550000, 36, 9.25, 'Auto', '2025-01-15', 'Approved', 'No Default');

INSERT INTO payments (
    Payment_ID, Loan_ID, Payment_Date, Payment_Amount, Payment_Status
)
VALUES
(70001, 80001, '2025-02-15', 17650.00, 'Paid');
