# utils/data_handler.py
import pandas as pd

def load_user_data(csv_path="data/user_data.csv"):
    try:
        return pd.read_csv(csv_path)
    except:
        # Empty DataFrame with default columns
        return pd.DataFrame(columns=["sleep_hours","energy_level","stress_level","mood_today"])

def save_user_data(df, csv_path="data/user_data.csv"):
    df.to_csv(csv_path, index=False)