CREATE DATABASE IF NOT EXISTS banking_loan_risk_assessment;
USE banking_loan_risk_assessment;

DROP TABLE IF EXISTS loan_audit;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS branches;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    Customer_ID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Age INT NOT NULL CHECK (Age BETWEEN 18 AND 75),
    Gender VARCHAR(20) NOT NULL,
    Marital_Status VARCHAR(20) NOT NULL,
    Education VARCHAR(50) NOT NULL,
    Occupation VARCHAR(50) NOT NULL,
    Annual_Income DECIMAL(12,2) NOT NULL CHECK (Annual_Income >= 0),
    Credit_Score INT NOT NULL CHECK (Credit_Score BETWEEN 300 AND 900),
    City VARCHAR(80) NOT NULL,
    State VARCHAR(80) NOT NULL
);

CREATE TABLE branches (
    Branch_ID INT PRIMARY KEY,
    Branch_Name VARCHAR(120) NOT NULL,
    City VARCHAR(80) NOT NULL,
    State VARCHAR(80) NOT NULL
);

CREATE TABLE loans (
    Loan_ID INT PRIMARY KEY,
    Customer_ID INT NOT NULL,
    Branch_ID INT NOT NULL,
    Loan_Amount DECIMAL(12,2) NOT NULL CHECK (Loan_Amount > 0),
    Loan_Term INT NOT NULL CHECK (Loan_Term BETWEEN 6 AND 360),
    Interest_Rate DECIMAL(5,2) NOT NULL CHECK (Interest_Rate BETWEEN 0 AND 40),
    Loan_Type VARCHAR(30) NOT NULL,
    Application_Date DATE NOT NULL,
    Approval_Status VARCHAR(20) NOT NULL,
    Default_Status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_loans_customer FOREIGN KEY (Customer_ID) REFERENCES customers(Customer_ID),
    CONSTRAINT fk_loans_branch FOREIGN KEY (Branch_ID) REFERENCES branches(Branch_ID),
    CONSTRAINT chk_approval_status CHECK (Approval_Status IN ('Approved', 'Rejected', 'Pending')),
    CONSTRAINT chk_default_status CHECK (Default_Status IN ('No Default', 'Default', 'Not Applicable'))
);

CREATE TABLE payments (
    Payment_ID INT PRIMARY KEY,
    Loan_ID INT NOT NULL,
    Payment_Date DATE NOT NULL,
    Payment_Amount DECIMAL(12,2) NOT NULL CHECK (Payment_Amount >= 0),
    Payment_Status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_payments_loan FOREIGN KEY (Loan_ID) REFERENCES loans(Loan_ID),
    CONSTRAINT chk_payment_status CHECK (Payment_Status IN ('Paid', 'Late', 'Missed', 'Partial'))
);

CREATE TABLE loan_audit (
    Audit_ID INT AUTO_INCREMENT PRIMARY KEY,
    Loan_ID INT NOT NULL,
    Old_Default_Status VARCHAR(20),
    New_Default_Status VARCHAR(20),
    Changed_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Note VARCHAR(255) DEFAULT 'Default status changed by trigger'
);

CREATE INDEX idx_customers_state_city ON customers(State, City);
CREATE INDEX idx_customers_credit_score ON customers(Credit_Score);
CREATE INDEX idx_loans_customer ON loans(Customer_ID);
CREATE INDEX idx_loans_branch ON loans(Branch_ID);
CREATE INDEX idx_loans_status_date ON loans(Approval_Status, Application_Date);
CREATE INDEX idx_loans_type_default ON loans(Loan_Type, Default_Status);
CREATE INDEX idx_payments_loan_date ON payments(Loan_ID, Payment_Date);
CREATE INDEX idx_payments_status ON payments(Payment_Status);
