# Student Academic Performance Prediction

## Mission & Problem
This project predicts a student's average exam score using only information known
**before any exam is taken**: gender, race/ethnicity group, parental level of education,
lunch type (a proxy for socio-economic background), and whether a test-preparation
course was completed. Raw subject scores are intentionally excluded from the features
to avoid leakage, since `average_score` is directly computed from them. Dataset:
[Students Performance in Exams](https://www.kaggle.com/datasets/spscientist/students-performance-in-exams)
(Kaggle, cleaned version) — 1,000 students, 10 columns.

## Live API
- Swagger UI: `<PASTE_YOUR_RENDER_URL>/docs`
- Predict endpoint: `POST <PASTE_YOUR_RENDER_URL>/predict`
- Retrain endpoint: `POST <PASTE_YOUR_RENDER_URL>/retrain`

## Video Demo
`<PASTE_YOUR_YOUTUBE_LINK>`

## Repository Structure
```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb      # EDA, feature engineering, 4 models, evaluation
│   │   ├── students_performance.csv
│   │   ├── best_model.pkl / scaler.pkl / model_meta.pkl
│   ├── API/
│   │   ├── prediction.py           # FastAPI app (endpoints, CORS, Pydantic schema)
│   │   ├── preprocessing.py        # shared feature-encoding logic
│   │   ├── requirements.txt
│   ├── FlutterApp/                 # mobile app (1-page predictor)
├── pyproject.toml
├── uv.lock
```

## Running the API locally
```bash
cd summative/API
uv run uvicorn prediction:app --reload
# Swagger UI at http://127.0.0.1:8000/docs
```

Example request body for `/predict`:
```json
{
  "gender": 0,
  "race_ethnicity": "group B",
  "parental_level_of_education": "bachelor's degree",
  "lunch": 1,
  "test_preparation_course": 0
}
```

To trigger `/retrain`, upload a CSV containing the same 5 feature columns above plus
an `average_score` column with the true score for each new row.

## Running the Mobile App
See `summative/FlutterApp/README.md`.
