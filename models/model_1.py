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
def predict_mood():
    data_dict = {}

    print("\nEnter your daily details:\n")
    data_arr = ["sleep_hours","activity_minutes","energy_level","stress_level","task_completion","screen_time","previous_day_mood"]

    # Input with validation
    for feature in data_arr:
        while True:
            try:
                value = float(input(f"Enter {feature}: "))

                # Basic validation rules
                if feature == "sleep_hours" and not (0 <= value <= 12):
                    raise ValueError("Sleep should be between 0-12 hours")

                if feature in ["energy_level", "stress_level", "previous_day_mood"] and not (1 <= value <= 5):
                    raise ValueError("Value should be between 1-5")

                if feature == "activity_minutes" and value < 0:
                    raise ValueError("Activity can't be negative")

                if feature == "task_completion" and not (0 <= value <= 100):
                    raise ValueError("Task completion should be 0-100")

                if feature == "screen_time" and value < 0:
                    raise ValueError("Screen time can't be negative")

                data_dict[feature] = value
                break

            except ValueError as e:
                print("Invalid input:", e)

    # Convert to DataFrame
    new_day = pd.DataFrame([data_dict])

    # Ensure correct column order
    new_day = new_day[X.columns]

    # Scale input
    new_day_scaled = scaler.transform(new_day)

    # Predict
    predicted_mood = model.predict(new_day_scaled)[0]

    # Round mood
    rounded_mood = round(predicted_mood)

    # Mood interpretation
    mood_map = {
        1: "Very Bad 😞",
        2: "Low 😕",
        3: "Neutral 😐",
        4: "Good 🙂",
        5: "Excellent 😄"
    }

    print("\n📊 Input Data:")
    print(new_day)

    print("\n🎯 Predicted Mood Score:", round(predicted_mood, 2))
    print("🧠 Interpreted Mood:", mood_map.get(rounded_mood, "Unknown"))




predict_mood()
