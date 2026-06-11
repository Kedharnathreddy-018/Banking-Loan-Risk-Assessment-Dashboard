"""Exploratory Data Analysis for Banking Loan Risk Assessment."""

from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = PROJECT_ROOT / "Dataset" / "processed"
OUTPUT_DIR = PROJECT_ROOT / "Documentation" / "EDA_Assets"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def load_master() -> pd.DataFrame:
    if (DATASET_DIR / "master_dataset.csv").exists():
        return pd.read_csv(DATASET_DIR / "master_dataset.csv", parse_dates=["Application_Date"])
    return pd.read_csv(PROJECT_ROOT / "Dataset" / "loans.csv")


def create_features(df: pd.DataFrame) -> pd.DataFrame:
    data = df.copy()
    data["Debt_to_Income_Ratio"] = data["Loan_Amount"] / data["Annual_Income"].replace(0, pd.NA)
    data["Default_Flag"] = (data["Default_Status"] == "Default").astype(int)
    data["Approval_Flag"] = (data["Approval_Status"] == "Approved").astype(int)
    return data


def save_plot(fig_name: str) -> None:
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / fig_name, dpi=180, bbox_inches="tight")
    plt.close()


def run_eda() -> None:
    df = create_features(load_master())

    corr_cols = ["Age", "Annual_Income", "Credit_Score", "Loan_Amount", "Interest_Rate", "Debt_to_Income_Ratio", "Default_Flag"]
    corr = df[corr_cols].corr(numeric_only=True)

    plt.figure(figsize=(8, 5))
    plt.imshow(corr, cmap="Blues", aspect="auto")
    plt.xticks(range(len(corr.columns)), corr.columns, rotation=45, ha="right")
    plt.yticks(range(len(corr.columns)), corr.columns)
    plt.colorbar()
    plt.title("Correlation Heatmap")
    save_plot("correlation_heatmap.png")

    approved = df[df["Approval_Status"] == "Approved"].copy()
    plt.figure(figsize=(7, 5))
    plt.scatter(approved["Annual_Income"], approved["Loan_Amount"], alpha=0.15)
    plt.xlabel("Annual Income")
    plt.ylabel("Loan Amount")
    plt.title("Income vs Loan Amount")
    save_plot("income_vs_loan_amount.png")

    plt.figure(figsize=(7, 5))
    plt.hist(df["Credit_Score"], bins=30, color="#2a9d8f", edgecolor="white")
    plt.title("Credit Score Distribution")
    plt.xlabel("Credit Score")
    plt.ylabel("Customer Count")
    save_plot("credit_score_distribution.png")

    default_trend = (
        approved.assign(Loan_Month=approved["Application_Date"].dt.to_period("M").astype(str))
        .groupby("Loan_Month")["Default_Flag"]
        .mean()
        .reset_index()
    )
    plt.figure(figsize=(10, 4))
    plt.plot(default_trend["Loan_Month"], default_trend["Default_Flag"], color="#e76f51", linewidth=2)
    plt.xticks(rotation=90)
    plt.ylabel("Default Rate")
    plt.title("Default Trend by Month")
    save_plot("default_trend.png")

    state_defaults = (
        approved.groupby("State")["Default_Flag"]
        .mean()
        .sort_values(ascending=False)
        .head(10)
    )
    plt.figure(figsize=(9, 5))
    state_defaults.sort_values().plot(kind="barh", color="#264653")
    plt.title("Top 10 States by Default Rate")
    plt.xlabel("Default Rate")
    save_plot("state_wise_default_rate.png")

    print("EDA charts saved to Documentation/EDA_Assets")


if __name__ == "__main__":
    run_eda()
