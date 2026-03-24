# STEP 1: Import libraries
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_absolute_error

# STEP 2: Load dataset
df = pd.read_csv("data3.csv")

# STEP 3: Select ONLY morning features
morning_features = [
    "sleep_hours",
    "energy_level",
    "stress_level",
    "previous_day_mood"
]

X = df[morning_features]
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

# STEP 7: Predict
y_pred = model.predict(X_test)

print("Predictions:", y_pred)
print("Actual:", y_test.values)

# STEP 8: Evaluate
mae = mean_absolute_error(y_test, y_pred)
print("MAE:", mae)

# STEP 9: Feature importance
print("\nFeature Importance:")
for name, coef in zip(morning_features, model.coef_):
    print(f"{name}: {coef}")