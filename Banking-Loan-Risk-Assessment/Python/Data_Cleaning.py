"""Data cleaning pipeline for Banking Loan Risk Assessment project."""

from pathlib import Path
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = PROJECT_ROOT / "Dataset"
OUTPUT_DIR = DATASET_DIR / "processed"
OUTPUT_DIR.mkdir(exist_ok=True)


def cap_outliers(df: pd.DataFrame, numeric_columns: list[str]) -> pd.DataFrame:
    cleaned = df.copy()
    for col in numeric_columns:
        q1 = cleaned[col].quantile(0.25)
        q3 = cleaned[col].quantile(0.75)
        iqr = q3 - q1
        lower = q1 - 1.5 * iqr
        upper = q3 + 1.5 * iqr
        cleaned[col] = cleaned[col].clip(lower=lower, upper=upper)
    return cleaned


def clean_customers() -> pd.DataFrame:
    customers = pd.read_csv(DATASET_DIR / "customers.csv")
    customers = customers.drop_duplicates(subset=["Customer_ID"])
    customers["Annual_Income"] = customers["Annual_Income"].fillna(customers["Annual_Income"].median())
    customers["Credit_Score"] = customers["Credit_Score"].fillna(customers["Credit_Score"].median())
    customers["Marital_Status"] = customers["Marital_Status"].fillna("Single")
    customers = cap_outliers(customers, ["Age", "Annual_Income", "Credit_Score"])
    customers.to_csv(OUTPUT_DIR / "customers_clean.csv", index=False)
    return customers


def clean_loans() -> pd.DataFrame:
    loans = pd.read_csv(DATASET_DIR / "loans.csv", parse_dates=["Application_Date"])
    loans = loans.drop_duplicates(subset=["Loan_ID"])
    loans["Loan_Amount"] = loans["Loan_Amount"].fillna(loans["Loan_Amount"].median())
    loans["Interest_Rate"] = loans["Interest_Rate"].fillna(loans["Interest_Rate"].median())
    loans["Approval_Status"] = loans["Approval_Status"].fillna("Pending")
    loans["Default_Status"] = loans["Default_Status"].fillna("Not Applicable")
    loans = cap_outliers(loans, ["Loan_Amount", "Loan_Term", "Interest_Rate"])
    loans.to_csv(OUTPUT_DIR / "loans_clean.csv", index=False)
    return loans


def clean_payments() -> pd.DataFrame:
    payments = pd.read_csv(DATASET_DIR / "payments.csv", parse_dates=["Payment_Date"])
    payments = payments.drop_duplicates(subset=["Payment_ID"])
    payments["Payment_Amount"] = payments["Payment_Amount"].fillna(0)
    payments["Payment_Status"] = payments["Payment_Status"].fillna("Missed")
    payments = cap_outliers(payments, ["Payment_Amount"])
    payments.to_csv(OUTPUT_DIR / "payments_clean.csv", index=False)
    return payments


def clean_branches() -> pd.DataFrame:
    branches = pd.read_csv(DATASET_DIR / "branches.csv")
    branches = branches.drop_duplicates(subset=["Branch_ID"])
    branches.to_csv(OUTPUT_DIR / "branches_clean.csv", index=False)
    return branches


def create_master_dataset(customers: pd.DataFrame, loans: pd.DataFrame, payments: pd.DataFrame) -> pd.DataFrame:
    payment_summary = (
        payments.groupby("Loan_ID")
        .agg(
            payment_count=("Payment_ID", "count"),
            total_payment_amount=("Payment_Amount", "sum"),
            paid_payments=("Payment_Status", lambda s: (s == "Paid").sum()),
            late_or_missed=("Payment_Status", lambda s: s.isin(["Late", "Missed"]).sum()),
        )
        .reset_index()
    )

    master = loans.merge(customers, on="Customer_ID", how="left").merge(payment_summary, on="Loan_ID", how="left")
    master["payment_count"] = master["payment_count"].fillna(0)
    master["total_payment_amount"] = master["total_payment_amount"].fillna(0)
    master["paid_payments"] = master["paid_payments"].fillna(0)
    master["late_or_missed"] = master["late_or_missed"].fillna(0)
    master.to_csv(OUTPUT_DIR / "master_dataset.csv", index=False)
    return master


if __name__ == "__main__":
    customers_df = clean_customers()
    loans_df = clean_loans()
    payments_df = clean_payments()
    clean_branches()
    create_master_dataset(customers_df, loans_df, payments_df)
    print("Cleaned datasets saved to Dataset/processed")
