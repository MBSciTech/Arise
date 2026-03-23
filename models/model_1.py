# STEP 1: Import libraries
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_absolute_error

# STEP 2: Load dataset
# csv_path = Path(__file__).resolve().parents[1] / "dataset" / "data3.csv"
df = pd.read_csv("C:\\Users\\MaharshiJB\\Downloads\\Projects\\Arise\\Arise\\dataset\\data3.csv")

# STEP 3: Separate features and target
X = df.drop("mood_today", axis=1)
y = df["mood_today"]

# STEP 4: Scale features
scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X)

# STEP 5: Train-test split (time-based)
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, shuffle=False
)

# STEP 6: Train model
model = LinearRegression()
model.fit(X_train, y_train)

# STEP 7: Predictions
y_pred = model.predict(X_test)

print("Predictions:", y_pred)
print("Actual:", y_test.values)

# STEP 8: Evaluate
mae = mean_absolute_error(y_test, y_pred)
print("MAE:", mae)

# STEP 9: Feature importance (coefficients)
feature_names = X.columns

print("\nFeature Importance:")
for name, coef in zip(feature_names, model.coef_):
    print(f"{name}: {coef}")

# STEP 10: Predict for new day (IMPORTANT: use DataFrame)
new_day = pd.DataFrame([{
    "sleep_hours": 7,
    "activity_minutes": 50,
    "energy_level": 4,
    "stress_level": 2,
    "task_completion": 75,
    "screen_time": 3,
    "previous_day_mood": 4
}])

# Scale new input
new_day_scaled = scaler.transform(new_day)

# Predict
predicted_mood = model.predict(new_day_scaled)

print("\nPredicted Mood:", predicted_mood[0])