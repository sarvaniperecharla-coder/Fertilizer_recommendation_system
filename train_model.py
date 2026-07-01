import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
import joblib

# Load dataset
df = pd.read_csv("data/fertilizer.csv")

# Encode categorical columns
soil_encoder = LabelEncoder()
crop_encoder = LabelEncoder()
fertilizer_encoder = LabelEncoder()

df["Soil Type"] = soil_encoder.fit_transform(df["Soil Type"])
df["Crop Type"] = crop_encoder.fit_transform(df["Crop Type"])
df["Fertilizer Name"] = fertilizer_encoder.fit_transform(df["Fertilizer Name"])

# Features and target
X = df.drop("Fertilizer Name", axis=1)
y = df["Fertilizer Name"]

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Train model
model = RandomForestClassifier(random_state=42)
model.fit(X_train, y_train)

# Save model
joblib.dump(model, "model/fertilizer_model.pkl")

encoders = {
    "soil_encoder": soil_encoder,
    "crop_encoder": crop_encoder,
    "fertilizer_encoder": fertilizer_encoder
}

joblib.dump(encoders, "model/label_encoders.pkl")

print("Model training completed successfully")