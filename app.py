

import pandas as pd
from flask import Flask, render_template, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash
import pickle
import numpy as np
import joblib
import mysql.connector
import joblib

import joblib

model = joblib.load("model/fertilizer_model.pkl")
encoders = joblib.load("model/label_encoders.pkl")

soil_encoder = encoders["soil_encoder"]
crop_encoder = encoders["crop_encoder"]
fertilizer_encoder = encoders["fertilizer_encoder"]

soil_types = list(soil_encoder.classes_)
crop_types = list(crop_encoder.classes_)



app = Flask(__name__)
app.secret_key = "your_secret_key"


# Load dataset once
import pandas as pd

def load_dropdown_values():
    try:
        df = pd.read_csv("data/fertilizer.csv")

        print("CSV loaded successfully")
        print(df.head())
        print(df.columns)

        df.columns = df.columns.str.strip()

        soil_types = sorted(df["Soil Type"].dropna().unique())
        crop_types = sorted(df["Crop Type"].dropna().unique())

        print("Soil types:", soil_types)
        print("Crop types:", crop_types)

        return soil_types, crop_types

    except Exception as e:
        print("Error in load_dropdown_values:", e)
        return [], []

# Load model and encoders
model = joblib.load("model/fertilizer_model.pkl")
encoders = joblib.load("model/label_encoders.pkl")

soil_encoder = encoders["soil_encoder"]
crop_encoder = encoders["crop_encoder"]
fertilizer_encoder = encoders["fertilizer_encoder"]

import mysql.connector

def get_db_connection():
    return mysql.connector.connect(
    host="localhost",
    user="root",
    password="Sarvani@2006",
    database="fertilizer_db"
)


  

@app.route('/')
def home():
   
    soil_types, crop_types = load_dropdown_values()

    print("SOIL:", soil_types)
    print("CROP:", crop_types)

    return render_template(
        "index.html",
        soil_types=soil_types,
        crop_types=crop_types
    )

@app.route('/register', methods=['GET', 'POST'])
def register():

    if request.method == 'POST':

        full_name = request.form['full_name']
        username = request.form['username']
        email = request.form['email']
        phone = request.form['phone']
        password = request.form['password']
        confirm_password = request.form['confirm_password']

        if password != confirm_password:
            return "Passwords do not match"

        password_hash = generate_password_hash(password)

        db = get_db_connection()
        cursor = db.cursor()

        # Check if username or email already exists
        cursor.execute(
            "SELECT * FROM users WHERE username=%s OR email=%s",
            (username, email)
        )

        existing_user = cursor.fetchone()

        print("existing_user =", existing_user)
        print("username =", username)
        print("email =", email)

        if existing_user:
           cursor.close()
           db.close()
           return "Username or Email already exists."

        # Insert new user
        sql = """
        INSERT INTO users
        (username, email, full_name, phone, password_hash)
        VALUES (%s, %s, %s, %s, %s)
        """

        values = (
            username,
            email,
            full_name,
            phone,
            password_hash
        )

        cursor.execute(sql, values)
        db.commit()

        cursor.close()
        db.close()

        return redirect(url_for('login'))

    return render_template("register.html")

@app.route('/login', methods=['GET', 'POST'])
def login():

    if request.method == 'POST':

        email = request.form["email"]
        password = request.form["password"]

        db = get_db_connection()
        cursor = db.cursor(dictionary=True)

        cursor.execute(
            "SELECT * FROM users WHERE email=%s",
            (email,)
        )

        user = cursor.fetchone()

        print("User:", user)

        if user:
            print("Stored Hash:", user["password_hash"])
            print("Entered Password:", password)
            print("Password Match:", check_password_hash(user["password_hash"], password))

        if user and check_password_hash(user["password_hash"], password):

            session["user_id"] = user["user_id"]
            session["username"] = user["username"]

            cursor.close()
            db.close()

            return redirect(url_for("home"))

        cursor.close()
        db.close()

        return "Invalid Email or Password"

    return render_template("login.html")

@app.route('/predict', methods=['POST'])
def predict():
    try:
        db = get_db_connection()
        cursor = db.cursor()
        # Step 1: Get logged-in user
        user_id = session["user_id"]

        # Step 2: Get form values
        soil = request.form['soil']
        crop = request.form['crop']

        nitrogen = float(request.form['nitrogen'])
        phosphorus = float(request.form['phosphorus'])
        potassium = float(request.form['potassium'])

        temperature = float(request.form['temperature'])
        humidity = float(request.form['humidity'])
        moisture = float(request.form['moisture'])

        # Step 3: Encode categorical values
        soil_val = soil_encoder.transform([soil])[0]
        crop_val = crop_encoder.transform([crop])[0]

        # Step 4: Prepare model input (IMPORTANT ORDER)
        features = np.array([[
            temperature,
            humidity,
            moisture,
            soil_val,
            crop_val,
            nitrogen,
            phosphorus,
            potassium
        ]])

        # Step 5: Predict fertilizer
        prediction = model.predict(features)
        fertilizer = fertilizer_encoder.inverse_transform(prediction)[0]


        



        # Step 6: Save to database
        sql = """
        INSERT INTO predictions_history
        (user_id, soil_type, crop_type,
         nitrogen, phosphorus, potassium,
         temperature, humidity, moisture,
         result)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """

        values = (
            user_id,
            soil,
            crop,
            nitrogen,
            phosphorus,
            potassium,
            temperature,
            humidity,
            moisture,
            fertilizer
        )
        
        
        cursor.execute(sql, values)
        db.commit()

        # Step 7: Send result to UI
        return render_template(
            "index.html",
            prediction_text=f"Recommended Fertilizer: {fertilizer}",
            soil_types=soil_types,
            crop_types=crop_types
        )

    except Exception as e:
        return render_template(
            "index.html",
            prediction_text=f"Error: {str(e)}",
            soil_types=soil_types,
            crop_types=crop_types
        )

@app.route("/history")
def history():
    db = get_db_connection()
    cursor = db.cursor()

    user_id = session.get("user_id")

    cursor.execute(
        "SELECT * FROM predictions_history WHERE user_id=%s ORDER BY id DESC",
        (user_id,)
    )

    data = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template("history.html", data=data)
    
    


if __name__ == "__main__":
    app.run(debug=True)