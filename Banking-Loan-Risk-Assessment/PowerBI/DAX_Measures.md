# DAX Measures

```DAX
Total Customers = DISTINCTCOUNT(Dim_Customers[Customer_ID])

Total Loans = COUNTROWS(Fact_Loans)

Approved Loans = CALCULATE([Total Loans], Fact_Loans[Approval_Status] = "Approved")

Approval Rate = DIVIDE([Approved Loans], [Total Loans], 0)

Defaulted Loans =
    CALCULATE(
        COUNTROWS(Fact_Loans),
        Fact_Loans[Default_Status] = "Default"
    )

Default Rate = DIVIDE([Defaulted Loans], [Approved Loans], 0)

Revenue = SUM(Fact_Payments[Payment_Amount])

Avg Credit Score = AVERAGE(Dim_Customers[Credit_Score])

Avg Risk Score = AVERAGE(Fact_Loans[Customer_Risk_Score])

Avg Loan Amount = AVERAGE(Fact_Loans[Loan_Amount])

Approval Rate Dynamic =
    VAR CurrentState = SELECTEDVALUE(Dim_Customers[State], "All States")
    RETURN [Approval Rate]

High Risk Customers =
    CALCULATE(
        DISTINCTCOUNT(Fact_Loans[Customer_ID]),
        Fact_Loans[Risk_Category] IN {"Very High Risk", "High Risk"}
    )

Compliance Score =
    AVERAGE(Fact_Loans[Payment_Compliance_Score])

Revenue Per Branch =
    DIVIDE([Revenue], DISTINCTCOUNT(Dim_Branches[Branch_ID]), 0)

YoY Loan Growth =
    VAR CurrentYearLoans = [Approved Loans]
    VAR PreviousYearLoans =
        CALCULATE([Approved Loans], DATEADD(Dim_Date[Date], -1, YEAR))
    RETURN DIVIDE(CurrentYearLoans - PreviousYearLoans, PreviousYearLoans, 0)
```

## Calculated columns

```DAX
Risk Segment =
    SWITCH(
        TRUE(),
        Fact_Loans[Customer_Risk_Score] >= 70, "High Risk",
        Fact_Loans[Customer_Risk_Score] >= 40, "Moderate Risk",
        "Low Risk"
    )

Approval Funnel Stage =
    SWITCH(
        Fact_Loans[Approval_Status],
        "Pending", "Under Review",
        "Rejected", "Rejected",
        "Approved", "Approved",
        "Unknown"
    )
```
