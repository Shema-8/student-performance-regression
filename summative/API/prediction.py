"""
Student Academic Performance Prediction API
--------------------------------------------
Serves the model trained in summative/linear_regression/multivariate.ipynb
to predict a student's average exam score (0-100) from information known
before any exam is taken: gender, race/ethnicity group, parental level of
education, lunch type, and whether a test-preparation course was completed.

Run locally:
    uv run uvicorn prediction:app --reload

Interactive docs (Swagger UI): http://127.0.0.1:8000/docs
"""

from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

from preprocessing import align_to_training_columns, encode_features, raw_record_to_dataframe

# ---------------------------------------------------------------------------
# Load trained artifacts
# ---------------------------------------------------------------------------
model = joblib.load("best_model.pkl")
scaler = joblib.load("scaler.pkl")
meta = joblib.load("model_meta.pkl")
FEATURE_COLUMNS = meta["feature_columns"]
NEEDS_SCALING = meta["needs_scaling"]
BEST_MODEL_NAME = meta["best_model_name"]

app = FastAPI(
    title="Student Academic Performance Prediction API",
    description=(
        "Predicts a student's average exam score (0-100) from demographic and "
        "background data known before any exam is taken, so schools can identify "
        "students who may benefit from outreach or test-preparation support."
    ),
    version="1.0.0",
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
# Reasoning:
# - allow_origins is an explicit whitelist, NOT "*". Only the Flutter web
#   build (if hosted) and local development origins may call this API from
#   a browser context. This stops arbitrary third-party websites from
#   embedding calls to our model (which would waste compute / could be
#   abused for scraping predictions at scale).
# - Native mobile apps (Android/iOS Flutter builds) are NOT subject to
#   browser CORS at all -- CORS only applies to requests made from inside
#   a browser -- so this list only matters for the Swagger UI / any web
#   client, not for the graded mobile app itself.
# - allow_methods is limited to GET (docs, health check) and POST (predict,
#   retrain); there is no PUT/DELETE/PATCH functionality to expose.
# - allow_headers is limited to Content-Type, which is all a JSON POST body
#   requires.
# - allow_credentials is False because the API uses no cookies or auth
#   tokens, so there is nothing that needs cross-origin credential sharing.
ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    # Add your deployed Swagger/Flutter-web origin(s) here, e.g.:
    # "https://your-flutter-web-app.onrender.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)


# ---------------------------------------------------------------------------
# Request schema — one field per raw predictor, each with an enforced type
# and a realistic range/allowed-value constraint (Task 2 requirement).
# ---------------------------------------------------------------------------
class StudentFeatures(BaseModel):
    gender: Literal[0, 1] = Field(..., description="0 = female, 1 = male")
    race_ethnicity: Literal["group A", "group B", "group C", "group D", "group E"] = Field(
        ..., description="Race/ethnicity group"
    )
    parental_level_of_education: Literal[
        "some high school", "high school", "some college",
        "associate's degree", "bachelor's degree", "master's degree",
    ] = Field(..., description="Highest level of parental education")
    lunch: Literal[0, 1] = Field(..., description="0 = free/reduced, 1 = standard")
    test_preparation_course: Literal[0, 1] = Field(..., description="0 = none, 1 = completed")

    class Config:
        json_schema_extra = {
            "example": {
                "gender": 0,
                "race_ethnicity": "group B",
                "parental_level_of_education": "bachelor's degree",
                "lunch": 1,
                "test_preparation_course": 0,
            }
        }


class PredictionResponse(BaseModel):
    predicted_average_score: float
    model_used: str
    performance_flag: str


def _predict_from_features(features: StudentFeatures) -> float:
    df_raw = raw_record_to_dataframe(features.model_dump())
    df_encoded = encode_features(df_raw)
    df_aligned = align_to_training_columns(df_encoded, FEATURE_COLUMNS)

    if NEEDS_SCALING:
        X = scaler.transform(df_aligned)
    else:
        X = df_aligned

    return float(model.predict(X)[0])


def _flag(predicted_average_score: float) -> str:
    # Thresholds are the 25th/75th percentile of average_score in the
    # training data (~58.3 / ~77.7), i.e. roughly the bottom and top quartiles.
    if predicted_average_score < 58.3:
        return "Below Average - may benefit from support"
    if predicted_average_score < 77.7:
        return "Average"
    return "Above Average"


@app.get("/")
def root():
    return {
        "message": "Student Academic Performance Prediction API is running.",
        "docs": "/docs",
        "model": BEST_MODEL_NAME,
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(features: StudentFeatures):
    try:
        pred = _predict_from_features(features)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=400, detail=str(exc))

    pred = max(0.0, min(100.0, pred))  # clip to the valid score range
    return PredictionResponse(
        predicted_average_score=round(pred, 2),
        model_used=BEST_MODEL_NAME,
        performance_flag=_flag(pred),
    )


@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    """
    Trigger a model retrain with new labelled data.

    Upload a CSV with the same 5 raw feature columns as the original
    training data (gender, race_ethnicity, parental_level_of_education,
    lunch, test_preparation_course) PLUS an average_score column with the
    true score for each new row. The new rows are combined with the
    original training set, a fresh OLS Linear Regression is fit, and the
    deployed best_model.pkl is overwritten.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    try:
        new_df = pd.read_csv(file.file)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV: {exc}")

    required_cols = set(StudentFeatures.model_fields.keys()) | {"average_score"}
    missing = required_cols - set(new_df.columns)
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"Uploaded CSV is missing required columns: {sorted(missing)}",
        )

    base_df = pd.read_csv("students_performance.csv")
    combined = pd.concat(
        [base_df[list(required_cols)], new_df[list(required_cols)]], ignore_index=True
    )
    # Note: unlike a wide feature set, exact-row dedup isn't reliable here —
    # with only 5 categorical features + a rounded score, distinct students
    # can legitimately share every value, so no drop_duplicates() is applied.

    y = combined["average_score"]
    X_raw = combined.drop(columns=["average_score"])
    X_encoded = encode_features(X_raw)
    X_aligned = align_to_training_columns(X_encoded, FEATURE_COLUMNS)

    X_train, X_test, y_train, y_test = train_test_split(
        X_aligned, y, test_size=0.2, random_state=42
    )

    X_train_scaled = scaler.transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    new_model = LinearRegression()
    new_model.fit(X_train_scaled, y_train)
    new_mse = mean_squared_error(y_test, new_model.predict(X_test_scaled))
    new_r2 = r2_score(y_test, new_model.predict(X_test_scaled))

    joblib.dump(new_model, "best_model.pkl")
    combined.to_csv("students_performance.csv", index=False)

    global model
    model = new_model

    return {
        "message": "Model retrained and deployed successfully.",
        "new_rows_added": len(new_df),
        "total_training_rows": len(combined),
        "test_mse": round(new_mse, 3),
        "test_r2": round(new_r2, 3),
    }
