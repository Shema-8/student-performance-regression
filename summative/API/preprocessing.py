"""
Shared preprocessing logic for the Student Performance Prediction API.

This mirrors EXACTLY the feature engineering performed in
summative/linear_regression/multivariate.ipynb, so that a raw student
record (the 5 source fields: gender, race_ethnicity,
parental_level_of_education, lunch, test_preparation_course) can be
turned into the one-hot encoded feature vector the saved model expects.
"""

import pandas as pd

NOMINAL_COLS = ["race_ethnicity", "parental_level_of_education"]


def raw_record_to_dataframe(record: dict) -> pd.DataFrame:
    """Turn a single raw student record (dict) into a one-row DataFrame."""
    return pd.DataFrame([record])


def encode_features(df_raw: pd.DataFrame) -> pd.DataFrame:
    """Apply the same encoding used during training (see multivariate.ipynb).

    gender, lunch, and test_preparation_course are already 0/1 integers.
    race_ethnicity and parental_level_of_education are one-hot encoded.
    """
    df = df_raw.copy()
    df = pd.get_dummies(df, columns=NOMINAL_COLS, drop_first=True)

    bool_cols = df.select_dtypes(include="bool").columns
    df[bool_cols] = df[bool_cols].astype(int)

    return df


def align_to_training_columns(df_encoded: pd.DataFrame, feature_columns: list) -> pd.DataFrame:
    """Reindex to the exact column set/order the model was trained on.

    Any one-hot column not present for this particular record (e.g. the
    reference categories 'group A' / "some high school" that were dropped
    during training only when drop_first was used) is filled with 0.
    """
    return df_encoded.reindex(columns=feature_columns, fill_value=0)
