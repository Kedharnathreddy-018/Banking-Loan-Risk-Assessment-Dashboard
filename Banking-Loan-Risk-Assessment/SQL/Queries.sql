USE banking_loan_risk_assessment;

/* Views */
CREATE OR REPLACE VIEW vw_customer_loan_profile AS
SELECT
    c.Customer_ID,
    c.Name,
    c.State,
    c.City,
    c.Occupation,
    c.Annual_Income,
    c.Credit_Score,
    COUNT(l.Loan_ID) AS Total_Loans,
    SUM(CASE WHEN l.Approval_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Loans,
    SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Defaulted_Loans,
    ROUND(SUM(CASE WHEN l.Approval_Status = 'Approved' THEN l.Loan_Amount ELSE 0 END), 2) AS Approved_Amount
FROM customers c
LEFT JOIN loans l ON c.Customer_ID = l.Customer_ID
GROUP BY c.Customer_ID, c.Name, c.State, c.City, c.Occupation, c.Annual_Income, c.Credit_Score;

CREATE OR REPLACE VIEW vw_branch_portfolio_summary AS
SELECT
    b.Branch_ID,
    b.Branch_Name,
    b.State,
    COUNT(DISTINCT l.Loan_ID) AS Loans_Handled,
    ROUND(SUM(CASE WHEN l.Approval_Status = 'Approved' THEN l.Loan_Amount ELSE 0 END), 2) AS Approved_Loan_Amount,
    ROUND(SUM(COALESCE(p.Payment_Amount, 0)), 2) AS Collected_Amount,
    ROUND(AVG(CASE WHEN l.Approval_Status = 'Approved' THEN l.Interest_Rate END), 2) AS Avg_Interest_Rate
FROM branches b
LEFT JOIN loans l ON b.Branch_ID = l.Branch_ID
LEFT JOIN payments p ON l.Loan_ID = p.Loan_ID
GROUP BY b.Branch_ID, b.Branch_Name, b.State;

/* Stored Procedures */
DROP PROCEDURE IF EXISTS sp_high_risk_customers;
DELIMITER $$
CREATE PROCEDURE sp_high_risk_customers(IN min_dti DECIMAL(10,2), IN min_credit_score INT)
BEGIN
    SELECT
        c.Customer_ID,
        c.Name,
        c.State,
        c.Credit_Score,
        ROUND(MAX(l.Loan_Amount) / NULLIF(c.Annual_Income, 0), 2) AS Debt_To_Income_Ratio,
        SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Defaulted_Loans
    FROM customers c
    JOIN loans l ON c.Customer_ID = l.Customer_ID
    WHERE l.Approval_Status = 'Approved'
    GROUP BY c.Customer_ID, c.Name, c.State, c.Credit_Score, c.Annual_Income
    HAVING Debt_To_Income_Ratio >= min_dti
       AND c.Credit_Score <= min_credit_score;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_state_approval_summary;
DELIMITER $$
CREATE PROCEDURE sp_state_approval_summary()
BEGIN
    SELECT
        c.State,
        COUNT(*) AS Total_Applications,
        SUM(CASE WHEN l.Approval_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Applications,
        ROUND(100 * SUM(CASE WHEN l.Approval_Status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Approval_Rate
    FROM customers c
    JOIN loans l ON c.Customer_ID = l.Customer_ID
    GROUP BY c.State
    ORDER BY Approval_Rate DESC;
END$$
DELIMITER ;

/* Trigger */
DROP TRIGGER IF EXISTS trg_log_default_change;
DELIMITER $$
CREATE TRIGGER trg_log_default_change
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
    IF OLD.Default_Status <> NEW.Default_Status THEN
        INSERT INTO loan_audit (Loan_ID, Old_Default_Status, New_Default_Status)
        VALUES (NEW.Loan_ID, OLD.Default_Status, NEW.Default_Status);
    END IF;
END$$
DELIMITER ;

/* 25+ Business Queries */

-- 1. Top default-prone customer segments
SELECT
    Education,
    Occupation,
    CASE
        WHEN Age BETWEEN 21 AND 30 THEN '21-30'
        WHEN Age BETWEEN 31 AND 40 THEN '31-40'
        WHEN Age BETWEEN 41 AND 50 THEN '41-50'
        ELSE '51+'
    END AS Age_Band,
    COUNT(*) AS Applications,
    SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Defaults,
    ROUND(100 * SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS Default_Rate
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY Education, Occupation, Age_Band
HAVING COUNT(*) >= 40
ORDER BY Default_Rate DESC, Defaults DESC
LIMIT 10;

-- 2. Loan approval rate by state
SELECT
    c.State,
    COUNT(*) AS Total_Applications,
    SUM(CASE WHEN l.Approval_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Applications,
    ROUND(100 * SUM(CASE WHEN l.Approval_Status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Approval_Rate
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
GROUP BY c.State
ORDER BY Approval_Rate DESC;

-- 3. Branch-wise revenue collection
SELECT
    b.Branch_ID,
    b.Branch_Name,
    ROUND(SUM(p.Payment_Amount), 2) AS Revenue_Collected
FROM branches b
JOIN loans l ON b.Branch_ID = l.Branch_ID
JOIN payments p ON l.Loan_ID = p.Loan_ID
GROUP BY b.Branch_ID, b.Branch_Name
ORDER BY Revenue_Collected DESC;

-- 4. Average credit score by loan type
SELECT
    l.Loan_Type,
    ROUND(AVG(c.Credit_Score), 2) AS Avg_Credit_Score
FROM loans l
JOIN customers c ON l.Customer_ID = c.Customer_ID
GROUP BY l.Loan_Type
ORDER BY Avg_Credit_Score DESC;

-- 5. Monthly loan disbursement trend
SELECT
    DATE_FORMAT(Application_Date, '%Y-%m') AS Loan_Month,
    COUNT(*) AS Approved_Loans,
    ROUND(SUM(Loan_Amount), 2) AS Total_Disbursed
FROM loans
WHERE Approval_Status = 'Approved'
GROUP BY DATE_FORMAT(Application_Date, '%Y-%m')
ORDER BY Loan_Month;

-- 6. High-risk customer identification
SELECT
    c.Customer_ID,
    c.Name,
    c.State,
    c.Credit_Score,
    ROUND(MAX(l.Loan_Amount) / c.Annual_Income, 2) AS Debt_To_Income,
    SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Defaulted_Loans
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY c.Customer_ID, c.Name, c.State, c.Credit_Score, c.Annual_Income
HAVING Debt_To_Income >= 0.75 OR c.Credit_Score < 580
ORDER BY Defaulted_Loans DESC, Debt_To_Income DESC;

-- 7. Default rate by city
SELECT
    c.State,
    c.City,
    COUNT(*) AS Approved_Loans,
    ROUND(100 * SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Default_Rate
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY c.State, c.City
HAVING COUNT(*) >= 50
ORDER BY Default_Rate DESC;

-- 8. Loan portfolio mix by occupation
SELECT
    c.Occupation,
    l.Loan_Type,
    COUNT(*) AS Loans_Count,
    ROUND(SUM(l.Loan_Amount), 2) AS Portfolio_Amount
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
GROUP BY c.Occupation, l.Loan_Type
ORDER BY Portfolio_Amount DESC;

-- 9. Repeat borrowers
SELECT
    c.Customer_ID,
    c.Name,
    COUNT(l.Loan_ID) AS Loan_Count,
    ROUND(SUM(l.Loan_Amount), 2) AS Total_Borrowed
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
GROUP BY c.Customer_ID, c.Name
HAVING COUNT(l.Loan_ID) > 1
ORDER BY Loan_Count DESC, Total_Borrowed DESC
LIMIT 20;

-- 10. Loans above state average
SELECT
    l.Loan_ID,
    c.State,
    l.Loan_Amount
FROM loans l
JOIN customers c ON l.Customer_ID = c.Customer_ID
JOIN (
    SELECT c2.State, AVG(l2.Loan_Amount) AS Avg_State_Loan
    FROM loans l2
    JOIN customers c2 ON l2.Customer_ID = c2.Customer_ID
    WHERE l2.Approval_Status = 'Approved'
    GROUP BY c2.State
) x ON c.State = x.State
WHERE l.Approval_Status = 'Approved'
  AND l.Loan_Amount > x.Avg_State_Loan
ORDER BY l.Loan_Amount DESC;

-- 11. Payment delinquency by loan type
SELECT
    l.Loan_Type,
    COUNT(*) AS Total_Payments,
    SUM(CASE WHEN p.Payment_Status IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS Delinquent_Payments,
    ROUND(100 * SUM(CASE WHEN p.Payment_Status IN ('Late', 'Missed') THEN 1 ELSE 0 END) / COUNT(*), 2) AS Delinquency_Rate
FROM loans l
JOIN payments p ON l.Loan_ID = p.Loan_ID
GROUP BY l.Loan_Type
ORDER BY Delinquency_Rate DESC;

-- 12. Customer lifetime collections
SELECT
    c.Customer_ID,
    c.Name,
    ROUND(SUM(p.Payment_Amount), 2) AS Lifetime_Collections
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
JOIN payments p ON l.Loan_ID = p.Loan_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY Lifetime_Collections DESC
LIMIT 20;

-- 13. Branch NPA ratio
SELECT
    b.Branch_Name,
    COUNT(*) AS Approved_Loans,
    SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Defaulted_Loans,
    ROUND(100 * SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) / COUNT(*), 2) AS NPA_Ratio
FROM branches b
JOIN loans l ON b.Branch_ID = l.Branch_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY b.Branch_Name
HAVING COUNT(*) >= 40
ORDER BY NPA_Ratio DESC;

-- 14. State-wise personal loan demand
SELECT
    c.State,
    COUNT(*) AS Personal_Loan_Applications,
    ROUND(SUM(l.Loan_Amount), 2) AS Total_Requested_Amount
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
WHERE l.Loan_Type = 'Personal'
GROUP BY c.State
ORDER BY Total_Requested_Amount DESC;

-- 15. Credit score deciles using window function
SELECT
    Customer_ID,
    Name,
    Credit_Score,
    NTILE(10) OVER (ORDER BY Credit_Score DESC) AS Credit_Score_Decile
FROM customers;

-- 16. Rolling 3-month disbursement trend using window function
WITH monthly_disbursal AS (
    SELECT
        DATE_FORMAT(Application_Date, '%Y-%m') AS Loan_Month,
        SUM(Loan_Amount) AS Monthly_Disbursal
    FROM loans
    WHERE Approval_Status = 'Approved'
    GROUP BY DATE_FORMAT(Application_Date, '%Y-%m')
)
SELECT
    Loan_Month,
    Monthly_Disbursal,
    ROUND(AVG(Monthly_Disbursal) OVER (
        ORDER BY Loan_Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_3_Month_Avg
FROM monthly_disbursal;

-- 17. Rank branches by revenue
SELECT
    Branch_ID,
    Branch_Name,
    Revenue_Collected,
    RANK() OVER (ORDER BY Revenue_Collected DESC) AS Revenue_Rank
FROM (
    SELECT
        b.Branch_ID,
        b.Branch_Name,
        SUM(p.Payment_Amount) AS Revenue_Collected
    FROM branches b
    JOIN loans l ON b.Branch_ID = l.Branch_ID
    JOIN payments p ON l.Loan_ID = p.Loan_ID
    GROUP BY b.Branch_ID, b.Branch_Name
) ranked;

-- 18. Rank state and loan type pairs by default volume
SELECT
    State,
    Loan_Type,
    Default_Count,
    DENSE_RANK() OVER (ORDER BY Default_Count DESC) AS Default_Rank
FROM (
    SELECT
        c.State,
        l.Loan_Type,
        SUM(CASE WHEN l.Default_Status = 'Default' THEN 1 ELSE 0 END) AS Default_Count
    FROM customers c
    JOIN loans l ON c.Customer_ID = l.Customer_ID
    GROUP BY c.State, l.Loan_Type
) s;

-- 19. CTE for customer risk summary
WITH payment_summary AS (
    SELECT
        l.Customer_ID,
        COUNT(*) AS Payment_Count,
        SUM(CASE WHEN p.Payment_Status = 'Paid' THEN 1 ELSE 0 END) AS Paid_Count,
        SUM(CASE WHEN p.Payment_Status IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS Delinquent_Count
    FROM loans l
    JOIN payments p ON l.Loan_ID = p.Loan_ID
    GROUP BY l.Customer_ID
)
SELECT
    c.Customer_ID,
    c.Name,
    c.Credit_Score,
    ps.Payment_Count,
    ps.Delinquent_Count,
    ROUND(100 * ps.Paid_Count / NULLIF(ps.Payment_Count, 0), 2) AS Payment_Compliance
FROM customers c
JOIN payment_summary ps ON c.Customer_ID = ps.Customer_ID
ORDER BY Payment_Compliance ASC, c.Credit_Score ASC;

-- 20. First defaulting loan per customer
WITH defaulted_loans AS (
    SELECT
        l.*,
        ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Application_Date) AS rn
    FROM loans l
    WHERE Default_Status = 'Default'
)
SELECT
    Customer_ID,
    Loan_ID,
    Application_Date,
    Loan_Amount
FROM defaulted_loans
WHERE rn = 1;

-- 21. Customers without any approved loans
SELECT
    c.Customer_ID,
    c.Name,
    c.State
FROM customers c
LEFT JOIN loans l
    ON c.Customer_ID = l.Customer_ID
   AND l.Approval_Status = 'Approved'
WHERE l.Loan_ID IS NULL;

-- 22. State approval funnel by status
SELECT
    c.State,
    l.Approval_Status,
    COUNT(*) AS Application_Count
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
GROUP BY c.State, l.Approval_Status
ORDER BY c.State, Application_Count DESC;

-- 23. Payment gap analysis using LAG
SELECT
    Loan_ID,
    Payment_Date,
    LAG(Payment_Date) OVER (PARTITION BY Loan_ID ORDER BY Payment_Date) AS Previous_Payment_Date,
    DATEDIFF(
        Payment_Date,
        LAG(Payment_Date) OVER (PARTITION BY Loan_ID ORDER BY Payment_Date)
    ) AS Days_Between_Payments
FROM payments;

-- 24. Average ticket size by branch and loan type
SELECT
    b.Branch_Name,
    l.Loan_Type,
    ROUND(AVG(l.Loan_Amount), 2) AS Avg_Ticket_Size
FROM branches b
JOIN loans l ON b.Branch_ID = l.Branch_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY b.Branch_Name, l.Loan_Type
ORDER BY Avg_Ticket_Size DESC;

-- 25. Portfolio exposure by risk bucket
SELECT
    CASE
        WHEN c.Credit_Score >= 750 THEN 'Low Risk'
        WHEN c.Credit_Score BETWEEN 650 AND 749 THEN 'Moderate Risk'
        ELSE 'High Risk'
    END AS Risk_Bucket,
    COUNT(*) AS Loans_Count,
    ROUND(SUM(l.Loan_Amount), 2) AS Exposure
FROM customers c
JOIN loans l ON c.Customer_ID = l.Customer_ID
WHERE l.Approval_Status = 'Approved'
GROUP BY Risk_Bucket
ORDER BY Exposure DESC;

-- 26. Query from customer profile view
SELECT *
FROM vw_customer_loan_profile
ORDER BY Defaulted_Loans DESC, Approved_Amount DESC
LIMIT 25;

-- 27. Query from branch summary view
SELECT *
FROM vw_branch_portfolio_summary
ORDER BY Collected_Amount DESC
LIMIT 20;

-- 28. Execute stored procedure examples
CALL sp_high_risk_customers(0.70, 620);
CALL sp_state_approval_summary();
