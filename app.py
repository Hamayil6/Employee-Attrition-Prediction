from pathlib import Path

import numpy as np
import pandas as pd
import streamlit as st
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import precision_recall_curve, roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

DATA_PATH = Path(__file__).parent / "data" / "WA_Fn-UseC_-HR-Employee-Attrition.csv"
RANDOM_STATE = 42

# Columns removed in the notebook: constant values (EmployeeCount, Over18, StandardHours) and the ID.
DROP_COLS = ["EmployeeCount", "Over18", "StandardHours", "EmployeeNumber"]

FEATURE_GROUPS = {
    "Personal": ["Age", "Gender", "MaritalStatus", "Education", "EducationField", "DistanceFromHome"],
    "Job": ["Department", "JobRole", "JobLevel", "BusinessTravel", "OverTime", "JobInvolvement", "PerformanceRating"],
    "Pay & tenure": [
        "MonthlyIncome", "DailyRate", "HourlyRate", "MonthlyRate", "PercentSalaryHike", "StockOptionLevel",
        "TotalWorkingYears", "NumCompaniesWorked", "YearsAtCompany", "YearsInCurrentRole",
        "YearsSinceLastPromotion", "YearsWithCurrManager", "TrainingTimesLastYear",
    ],
    "Satisfaction": ["EnvironmentSatisfaction", "JobSatisfaction", "RelationshipSatisfaction", "WorkLifeBalance"],
}

# Value labels from the Kaggle dataset description
RATING_LABELS = {
    "Education": {1: "1 - Below College", 2: "2 - College", 3: "3 - Bachelor", 4: "4 - Master", 5: "5 - Doctor"},
    "EnvironmentSatisfaction": {1: "1 - Low", 2: "2 - Medium", 3: "3 - High", 4: "4 - Very High"},
    "JobInvolvement": {1: "1 - Low", 2: "2 - Medium", 3: "3 - High", 4: "4 - Very High"},
    "JobSatisfaction": {1: "1 - Low", 2: "2 - Medium", 3: "3 - High", 4: "4 - Very High"},
    "RelationshipSatisfaction": {1: "1 - Low", 2: "2 - Medium", 3: "3 - High", 4: "4 - Very High"},
    "PerformanceRating": {1: "1 - Low", 2: "2 - Good", 3: "3 - Excellent", 4: "4 - Outstanding"},
    "WorkLifeBalance": {1: "1 - Bad", 2: "2 - Good", 3: "3 - Better", 4: "4 - Best"},
}


def add_features(data):
    """Same engineered features as the notebook (section 5)."""
    data = data.copy()
    data["TenureRatio"] = data["YearsAtCompany"] / (data["TotalWorkingYears"] + 1)
    data["AvgYearsPerCompany"] = data["TotalWorkingYears"] / (data["NumCompaniesWorked"] + 1)
    data["IncomePerJobLevel"] = data["MonthlyIncome"] / data["JobLevel"]
    data["SatisfactionScore"] = data[
        ["EnvironmentSatisfaction", "JobSatisfaction", "RelationshipSatisfaction", "WorkLifeBalance"]
    ].mean(axis=1)
    return data


def build_pipeline(columns, frame):
    """Logistic Regression (balanced) - the model selected in the notebook."""
    cat_cols = [c for c in columns if not pd.api.types.is_numeric_dtype(frame[c])]
    num_cols = [c for c in columns if c not in cat_cols]
    preprocessor = ColumnTransformer(
        transformers=[
            ("cat", OneHotEncoder(handle_unknown="ignore", drop="if_binary"), cat_cols),
            ("num", StandardScaler(), num_cols),
        ],
        remainder="passthrough",
    )
    model = LogisticRegression(max_iter=2000, class_weight="balanced")
    return Pipeline(steps=[("preprocess", preprocessor), ("model", model)])


@st.cache_resource(show_spinner="Training model...")
def train_model():
    raw = pd.read_csv(DATA_PATH).drop(columns=DROP_COLS)
    y = (raw["Attrition"] == "Yes").astype(int)
    X_base = raw.drop(columns=["Attrition"])
    X = add_features(X_base)

    pipe = build_pipeline(X.columns.tolist(), X)

    # Out-of-fold scores: used for the decision threshold, risk tiers and a fair AUC estimate
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
    oof = cross_val_predict(pipe, X, y, cv=cv, method="predict_proba")[:, 1]

    prec, rec, thr = precision_recall_curve(y, oof)
    f1 = 2 * prec[:-1] * rec[:-1] / (prec[:-1] + rec[:-1] + 1e-12)
    threshold = float(thr[np.argmax(f1)])

    low_cut, high_cut = np.quantile(oof, [1 / 3, 2 / 3])
    tiers = pd.cut(oof, [-np.inf, low_cut, high_cut, np.inf], labels=["Low", "Medium", "High"])
    tier_rates = y.groupby(tiers, observed=True).mean()

    pipe.fit(X, y)
    return {
        "pipe": pipe,
        "reference": X_base,
        "oof": oof,
        "threshold": threshold,
        "low_cut": float(low_cut),
        "high_cut": float(high_cut),
        "tier_rates": tier_rates,
        "cv_auc": roc_auc_score(y, oof),
        "base_rate": float(y.mean()),
    }


def input_widget(col, ref):
    """One input per feature, with ranges and defaults taken from the dataset."""
    series = ref[col]
    if col in RATING_LABELS:
        options = sorted(series.unique().tolist())
        if col == "Education":
            options = [1, 2, 3, 4, 5]
        default = int(round(series.median()))
        return st.selectbox(col, options, index=options.index(default), format_func=RATING_LABELS[col].get, key=col)
    if not pd.api.types.is_numeric_dtype(series):
        options = sorted(series.unique().tolist())
        return st.selectbox(col, options, index=options.index(series.mode().iloc[0]), key=col)
    lo, hi = int(series.min()), int(series.max())
    return st.number_input(col, min_value=lo, max_value=hi, value=int(series.median()), step=1, key=col,
                           help=f"Range seen in the data: {lo} to {hi}")


st.set_page_config(page_title="Employee Attrition Prediction", page_icon="👥", layout="wide")
st.title("👥 Employee Attrition Prediction")
st.caption(
    "Estimates how likely an employee is to leave, using Logistic Regression trained on the fictional "
    "IBM HR Analytics dataset. Demonstration only - not for real HR decisions."
)

state = train_model()
reference = state["reference"]
feature_cols = reference.columns.tolist()

st.write("Fill in the employee's details (defaults are the typical values in the dataset) and click **Predict**.")

values = {}
for tab, (group, cols) in zip(st.tabs(list(FEATURE_GROUPS)), FEATURE_GROUPS.items()):
    with tab:
        grid = st.columns(3)
        for i, col in enumerate(cols):
            with grid[i % 3]:
                values[col] = input_widget(col, reference)

assert sorted(values) == sorted(feature_cols), "Form fields do not match the model's input columns"

if st.button("Predict attrition risk", type="primary"):
    problems = []
    if values["YearsAtCompany"] > values["TotalWorkingYears"]:
        problems.append("YearsAtCompany cannot exceed TotalWorkingYears.")
    for col in ["YearsInCurrentRole", "YearsSinceLastPromotion", "YearsWithCurrManager"]:
        if values[col] > values["YearsAtCompany"]:
            problems.append(f"{col} cannot exceed YearsAtCompany.")

    if problems:
        for message in problems:
            st.error(message)
    else:
        row = add_features(pd.DataFrame([values])[feature_cols])
        score = float(state["pipe"].predict_proba(row)[0, 1])
        percentile = float((state["oof"] <= score).mean())

        if score >= state["high_cut"]:
            tier = "High"
        elif score >= state["low_cut"]:
            tier = "Medium"
        else:
            tier = "Low"

        c1, c2, c3 = st.columns(3)
        c1.metric("Risk score", f"{score:.2f}")
        c2.metric("Risk tier", tier)
        c3.metric("Higher than", f"{percentile:.0%} of employees")
        st.progress(min(max(score, 0.0), 1.0))

        if score >= state["threshold"]:
            st.error(f"Flagged as likely to leave (score is above the tuned threshold of {state['threshold']:.2f}).")
        else:
            st.success(f"Not flagged (score is below the tuned threshold of {state['threshold']:.2f}).")

        st.caption(
            f"In this dataset, employees in the **{tier}** tier actually left "
            f"{state['tier_rates'][tier]:.0%} of the time (overall: {state['base_rate']:.0%})."
        )

with st.expander("About this model"):
    st.markdown(
        f"""
- **Model:** Logistic Regression with balanced class weights, plus 4 engineered features (see the notebook).
- **Cross-validated ROC AUC:** {state['cv_auc']:.3f} on the full dataset.
- **Risk score:** the model is trained with class weighting, so the score is **not** a literal probability.
  Use the tier and the percentile to interpret it.
- **Limits:** the data is fictional and small (1,470 employees); `Gender`, `Age` and `MaritalStatus` are
  protected-type attributes. A real deployment would need a fairness and legal review.
"""
    )
