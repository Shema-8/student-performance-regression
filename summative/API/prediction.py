from pathlib import Path
from typing import Literal

import joblib
import pandas as pd

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

from preprocessing import (
    align_to_training_columns,
    encode_features,
    raw_record_to_dataframe,
)


# ============================================================
# PATHS
# ============================================================

API_DIR = Path(__file__).resolve().parent
MODEL_DIR = API_DIR.parent / "linear_regression"

MODEL_PATH = MODEL_DIR / "best_model.pkl"
SCALER_PATH = MODEL_DIR / "scaler.pkl"
META_PATH = MODEL_DIR / "model_meta.pkl"
DATA_PATH = MODEL_DIR / "students_performance.csv"


# ============================================================
# LOAD MODEL
# ============================================================

model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
meta = joblib.load(META_PATH)

FEATURE_COLUMNS = meta["feature_columns"]
NEEDS_SCALING = meta["needs_scaling"]
BEST_MODEL_NAME = meta["best_model_name"]


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="Student Academic Performance Prediction API",
    description="Predicts a student's average academic score.",
    version="1.0.0",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)


# ============================================================
# INPUT SCHEMA
# ============================================================

class StudentFeatures(BaseModel):

    gender: Literal[0, 1] = Field(
        ...,
        description="0 = female, 1 = male"
    )

    race_ethnicity: Literal[
        "group A",
        "group B",
        "group C",
        "group D",
        "group E",
    ]

    parental_level_of_education: Literal[
        "some high school",
        "high school",
        "some college",
        "associate's degree",
        "bachelor's degree",
        "master's degree",
    ]

    lunch: Literal[0, 1] = Field(
        ...,
        description="0 = free/reduced, 1 = standard"
    )

    test_preparation_course: Literal[0, 1] = Field(
        ...,
        description="0 = none, 1 = completed"
    )


class PredictionResponse(BaseModel):
    predicted_average_score: float
    model_used: str
    performance_flag: str


# ============================================================
# PREDICTION
# ============================================================

def make_prediction(features: StudentFeatures) -> float:

    data = raw_record_to_dataframe(features.model_dump())

    data = encode_features(data)

    data = align_to_training_columns(
        data,
        FEATURE_COLUMNS
    )

    if NEEDS_SCALING:
        data = scaler.transform(data)

    return float(model.predict(data)[0])


def performance_flag(score: float) -> str:

    if score < 58.3:
        return "Below Average - may benefit from support"

    if score < 77.7:
        return "Average"

    return "Above Average"


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {
        "message": "Student Academic Performance Prediction API is running.",
        "docs": "/docs",
        "model": BEST_MODEL_NAME,
    }


# ============================================================
# PREDICTION ENDPOINT
# ============================================================

@app.post(
    "/predict",
    response_model=PredictionResponse
)
def predict(features: StudentFeatures):

    try:

        score = make_prediction(features)

        score = max(
            0.0,
            min(100.0, score)
        )

        return {
            "predicted_average_score": round(score, 2),
            "model_used": BEST_MODEL_NAME,
            "performance_flag": performance_flag(score),
        }

    except Exception as error:

        raise HTTPException(
            status_code=400,
            detail=str(error)
        )


# ============================================================
# RETRAINING ENDPOINT
# ============================================================

@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):

    if not file.filename.lower().endswith(".csv"):

        raise HTTPException(
            status_code=400,
            detail="Please upload a CSV file."
        )

    try:

        new_data = pd.read_csv(file.file)

    except Exception as error:

        raise HTTPException(
            status_code=400,
            detail=f"Could not read CSV file: {error}"
        )

    required_columns = [
        "gender",
        "race_ethnicity",
        "parental_level_of_education",
        "lunch",
        "test_preparation_course",
        "average_score",
    ]

    missing = [
        column
        for column in required_columns
        if column not in new_data.columns
    ]

    if missing:

        raise HTTPException(
            status_code=400,
            detail=f"Missing required columns: {missing}"
        )

    old_data = pd.read_csv(DATA_PATH)

    combined_data = pd.concat(
        [
            old_data[required_columns],
            new_data[required_columns],
        ],
        ignore_index=True
    )

    y = combined_data["average_score"]

    X = combined_data.drop(
        columns=["average_score"]
    )

    X = encode_features(X)

    X = align_to_training_columns(
        X,
        FEATURE_COLUMNS
    )

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42
    )

    if NEEDS_SCALING:

        X_train = scaler.transform(X_train)
        X_test = scaler.transform(X_test)

    new_model = LinearRegression()

    new_model.fit(
        X_train,
        y_train
    )

    predictions = new_model.predict(X_test)

    mse = mean_squared_error(
        y_test,
        predictions
    )

    r2 = r2_score(
        y_test,
        predictions
    )

    joblib.dump(
        new_model,
        MODEL_PATH
    )

    global model
    model = new_model

    return {
        "message": "Model retrained successfully.",
        "new_rows_added": len(new_data),
        "total_training_rows": len(combined_data),
        "test_mse": round(mse, 3),
        "test_r2": round(r2, 3),
    }