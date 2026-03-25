# utils/ml_predictor.py
from sklearn.ensemble import RandomForestClassifier
import pickle

def train_model(X, y, model_path="data/model_data.pkl"):
    model = RandomForestClassifier()
    model.fit(X, y)
    with open(model_path, "wb") as f:
        pickle.dump(model, f)

def predict(model, X_new):
    return model.predict(X_new)