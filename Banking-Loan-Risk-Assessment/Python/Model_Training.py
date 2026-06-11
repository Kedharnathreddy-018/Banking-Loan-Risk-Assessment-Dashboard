"""Model training for loan approval and default prediction."""

from pathlib import Path
import json
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

try:
    from xgboost import XGBClassifier
    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATASET_DIR = PROJECT_ROOT / "Dataset" / "processed"
OUTPUT_DIR = PROJECT_ROOT / "Documentation" / "Model_Outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def load_data() -> pd.DataFrame:
    df = pd.read_csv(DATASET_DIR / "master_dataset.csv", parse_dates=["Application_Date"])
    return df


def add_features(df: pd.DataFrame) -> pd.DataFrame:
    data = df.copy()
    data["Debt_to_Income_Ratio"] = data["Loan_Amount"] / data["Annual_Income"].replace(0, np.nan)
    data["Payment_Compliance_Score"] = np.where(
        data["payment_count"] > 0,
        (data["paid_payments"] / data["payment_count"]) * 100,
        0,
    )
    data["Risk_Category"] = pd.cut(
        data["Credit_Score"],
        bins=[0, 580, 680, 750, 900],
        labels=["Very High Risk", "High Risk", "Moderate Risk", "Low Risk"],
    )
    data["Customer_Risk_Score"] = (
        (1 - (data["Credit_Score"] / 900)) * 45
        + data["Debt_to_Income_Ratio"].fillna(0).clip(0, 2) * 25
        + (1 - (data["Payment_Compliance_Score"] / 100).clip(0, 1)) * 30
    ).round(2)
    data["Default_Target"] = (data["Default_Status"] == "Default").astype(int)
    data["Approval_Target"] = (data["Approval_Status"] == "Approved").astype(int)
    return data


def build_preprocessor(numeric_features: list[str], categorical_features: list[str]) -> ColumnTransformer:
    return ColumnTransformer(
        transformers=[
            (
                "numeric",
                Pipeline(
                    steps=[
                        ("imputer", SimpleImputer(strategy="median")),
                        ("scaler", StandardScaler()),
                    ]
                ),
                numeric_features,
            ),
            (
                "categorical",
                Pipeline(
                    steps=[
                        ("imputer", SimpleImputer(strategy="most_frequent")),
                        ("encoder", OneHotEncoder(handle_unknown="ignore")),
                    ]
                ),
                categorical_features,
            ),
        ]
    )


def evaluate_model(model_name: str, pipeline: Pipeline, x_test: pd.DataFrame, y_test: pd.Series) -> dict:
    predictions = pipeline.predict(x_test)
    probabilities = pipeline.predict_proba(x_test)[:, 1]
    return {
        "Model": model_name,
        "Accuracy": round(accuracy_score(y_test, predictions), 4),
        "Precision": round(precision_score(y_test, predictions, zero_division=0), 4),
        "Recall": round(recall_score(y_test, predictions, zero_division=0), 4),
        "F1_Score": round(f1_score(y_test, predictions, zero_division=0), 4),
        "ROC_AUC": round(roc_auc_score(y_test, probabilities), 4),
    }


def train_models(df: pd.DataFrame, target_column: str, output_name: str) -> None:
    feature_columns = [
        "Age", "Annual_Income", "Credit_Score", "Loan_Amount", "Loan_Term", "Interest_Rate",
        "Debt_to_Income_Ratio", "Payment_Compliance_Score", "Customer_Risk_Score",
        "Gender", "Marital_Status", "Education", "Occupation", "State", "Loan_Type", "Risk_Category",
    ]
    model_data = df[feature_columns + [target_column]].dropna(subset=[target_column]).copy()
    x = model_data[feature_columns]
    y = model_data[target_column]

    numeric_features = [
        "Age", "Annual_Income", "Credit_Score", "Loan_Amount", "Loan_Term",
        "Interest_Rate", "Debt_to_Income_Ratio", "Payment_Compliance_Score", "Customer_Risk_Score",
    ]
    categorical_features = ["Gender", "Marital_Status", "Education", "Occupation", "State", "Loan_Type", "Risk_Category"]
    preprocessor = build_preprocessor(numeric_features, categorical_features)

    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=42, stratify=y
    )

    models = {
        "Logistic Regression": LogisticRegression(max_iter=500, class_weight="balanced"),
        "Random Forest": RandomForestClassifier(
            n_estimators=250,
            max_depth=10,
            min_samples_leaf=4,
            random_state=42,
            class_weight="balanced_subsample",
        ),
    }

    if XGBOOST_AVAILABLE:
        models["XGBoost"] = XGBClassifier(
            n_estimators=300,
            max_depth=5,
            learning_rate=0.05,
            subsample=0.9,
            colsample_bytree=0.9,
            eval_metric="logloss",
            random_state=42,
        )

    results = []
    for model_name, estimator in models.items():
        pipeline = Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("model", estimator),
            ]
        )
        pipeline.fit(x_train, y_train)
        results.append(evaluate_model(model_name, pipeline, x_test, y_test))

    output_path = OUTPUT_DIR / output_name
    with output_path.open("w", encoding="utf-8") as file:
        json.dump(results, file, indent=2)


if __name__ == "__main__":
    data = add_features(load_data())
    train_models(data, "Approval_Target", "approval_model_metrics.json")
    approved_only = data[data["Approval_Target"] == 1].copy()
    train_models(approved_only, "Default_Target", "default_model_metrics.json")
    print("Model metrics saved to Documentation/Model_Outputs")
    if not XGBOOST_AVAILABLE:
        print("Install xgboost to run the XGBoost model: pip install xgboost")
