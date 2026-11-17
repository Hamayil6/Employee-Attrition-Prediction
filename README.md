# Employee Attrition Prediction

Predicting whether an employee will leave the company from job, compensation, and satisfaction data (overtime, job role, income, tenure, satisfaction ratings, etc.) using classification models.

## Approach

1. **EDA** — attrition distribution (237 of 1,470 employees left, 16.1%), attrition rate by overtime / marital status / business travel / department / job role, numeric drivers (age, income, tenure, distance), correlation heatmap.
2. **Cleaning** — removed 3 constant columns (`EmployeeCount`, `Over18`, `StandardHours`); the data has no missing values or duplicate rows.
3. **Data leakage check** — scanned every feature on its own for target leakage (best single feature: `JobLevel`, ROC AUC ≈ 0.66 — far from the ≈ 1.0 a leak would show), confirmed the tenure columns are logically consistent, and dropped `EmployeeNumber` (an identifier, AUC ≈ 0.50). No leakage was found.
4. **Feature engineering** — `TenureRatio`, `AvgYearsPerCompany`, `IncomePerJobLevel`, `SatisfactionScore`, plus one-hot encoded categoricals. These add only ≈ +0.002 CV ROC AUC (within noise); they are kept because they are cheap and easy to explain.
5. **Modeling** — built a `scikit-learn` `Pipeline` (so preprocessing never leaks across the train/test split) and compared Logistic Regression, Random Forest (with and without class weighting) and Gradient Boosting against a majority-class baseline. The final model was chosen by cross-validation on the training data only.
6. **Evaluation** — stratified 5-fold cross-validation plus a held-out stratified test set (294 employees, 47 leavers), scored with ROC AUC, PR AUC, precision, recall and F1 (accuracy is misleading with only 16% leavers). The decision threshold was tuned on out-of-fold training predictions, and a bootstrap gives a confidence interval for the test AUC.

## Results

Test-set metrics at the default 0.5 threshold:

| Model | CV ROC AUC (mean) | Test ROC AUC | Test PR AUC | Test Recall | Test Precision | Test F1 |
|---|---|---|---|---|---|---|
| Baseline (always "stays") | 0.500 | 0.500 | 0.160 | 0.000 | 0.000 | 0.000 |
| **Logistic Regression (balanced)** | **0.830** | **0.799** | **0.553** | **0.596** | **0.322** | **0.418** |
| Random Forest | 0.808 | 0.778 | 0.417 | 0.085 | 0.444 | 0.143 |
| Random Forest (balanced) | 0.813 | 0.769 | 0.388 | 0.085 | 0.571 | 0.148 |
| Gradient Boosting | 0.808 | 0.797 | 0.491 | 0.213 | 0.625 | 0.317 |

**Logistic Regression (balanced)** had the best cross-validated ROC AUC and was selected. Its test ROC AUC is 0.799 (95% bootstrap CI 0.72–0.87; the test set has only 47 leavers, so the interval is wide). The tree models were close but not better, so the simplest model won. Random Forest numbers can shift by about ±0.01–0.02 between `scikit-learn` versions; Logistic Regression is deterministic.

**Choosing the decision threshold.** A threshold tuned for F1 on out-of-fold *training* predictions was applied once to the test set:

| Threshold | Precision | Recall | F1 | Accuracy |
|---|---|---|---|---|
| 0.50 (default) | 0.322 | 0.596 | 0.418 | 0.735 |
| 0.70 (tuned) | 0.550 | 0.468 | 0.506 | 0.854 |

Which one is right depends on the cost of missing a leaver versus holding an unnecessary retention conversation. Note that always predicting "stays" already reaches 0.840 accuracy, which is why accuracy is not the metric used here.

**Useful for ranking.** On the test set, the highest-risk third of employees had a 33.7% attrition rate versus 4.1% in the lowest-risk third, and contained 70% of all leavers.

**Strongest predictors:** `OverTime` by a wide margin (permutation importance ≈ 0.10 AUC vs ≈ 0.02 or less for everything else), then `MaritalStatus`, `YearsSinceLastPromotion`, `BusinessTravel` and `YearsAtCompany`. Job roles differ sharply (Sales Representative 40% attrition vs Research Director 2.5%), consistent with the EDA.

**Limitations.** The data is fictional (created by IBM data scientists) and a single snapshot; the test set is small; coefficient signs of correlated features (e.g. `MonthlyIncome`, `YearsAtCompany`) can be misleading; and `Gender`, `Age` and `MaritalStatus` are protected-type attributes, so any real HR use would need a fairness and legal review.

## Project structure

```
Employee-Attrition-Prediction/
├── README.md
├── requirements.txt
├── data/
│   └── WA_Fn-UseC_-HR-Employee-Attrition.csv
├── employee_attrition_prediction.ipynb    # full analysis: EDA, leakage check, pipeline, model comparison
├── app.py                                 # Streamlit demo for interactive predictions
├── employee_attrition_analysis_excel.xlsx # Excel analysis (live formulas + charts)
└── sql/
    ├── create_and_load_table.sql          # SQL Server: create table + bulk load the CSV
    └── employee_attrition_analysis.sql    # SQL Server: attrition analysis queries and views
```

## How to run

```bash
git clone https://github.com/<your-username>/Employee-Attrition-Prediction.git
cd Employee-Attrition-Prediction
pip install -r requirements.txt
jupyter notebook employee_attrition_prediction.ipynb
```

### Interactive demo

```bash
streamlit run app.py
```

Enter an employee's details and the app returns a risk score, a risk tier (Low / Medium / High) and whether the employee is flagged by the tuned threshold. The model is trained on startup from the CSV in `data/`.

### SQL and Excel analysis

- **SQL Server:** edit the file path in `sql/create_and_load_table.sql`, run it, then run `sql/employee_attrition_analysis.sql`.
- **Excel:** open `employee_attrition_analysis_excel.xlsx`. Every number on the analysis sheets is a live formula over the `Data` sheet.

## Dataset

[IBM HR Analytics Employee Attrition & Performance](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset) (Kaggle): 1,470 employees and 35 columns, including `Age`, `JobRole`, `OverTime`, `MonthlyIncome`, `YearsAtCompany`, several satisfaction ratings, and the target `Attrition` (`Yes` / `No`). It is a fictional dataset created by IBM data scientists.

## Next steps

- Hyperparameter tuning with `GridSearchCV`.
- Try XGBoost / LightGBM.
- SHAP values for per-employee explanations.
- Calibrate the predicted probabilities and audit performance across gender and age groups.
