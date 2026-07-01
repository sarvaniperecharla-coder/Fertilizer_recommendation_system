# Fertilizer Recommendation System

## Project Description
This project is an AI-based web application that recommends the most suitable fertilizer based on soil conditions, crop type, and environmental parameters. It uses a Machine Learning model integrated with a Flask web application and MySQL database for storing user predictions.

## Objective
The main objective of this project is to assist farmers or users in selecting the appropriate fertilizer based on agricultural data inputs such as soil type, crop type, and nutrient levels.

## Features
- User registration and login system
- Fertilizer prediction using a trained ML model
- Input handling for soil, crop, and environmental factors
- Storage of prediction history in a MySQL database
- History page to view previous predictions

## Technologies Used
- Python
- Flask
- Scikit-learn
- Pandas
- NumPy
- MySQL
- HTML
- CSS

## Input Features
The model considers the following inputs:
- Temperature
- Humidity
- Moisture
- Soil Type
- Crop Type
- Nitrogen
- Phosphorus
- Potassium

## Project Structure
- app.py: Main Flask application
- train_model.py: Script used to train the machine learning model
- model/: Contains trained ML model and encoders
- templates/: HTML templates for frontend
- data/: Dataset used for training
- database.sql: SQL file for database schema

## How to Run the Project
1. Clone the repository
2. Install dependencies using:
   pip install -r requirements.txt
3. Run the Flask application:
   python app.py
4. Open browser and go to:
   http://127.0.0.1:5000

## Database Setup
- Import database.sql into MySQL
- Update database credentials in app.py

## Future Improvements
- Improve model accuracy using advanced algorithms
- Add explainable AI for prediction insights
- Deploy the application on cloud platforms
- Improve UI using modern frontend frameworks

## Author
Sarvani


## Screenshots

### Registration Page
![image_alt](https://github.com/sarvaniperecharla-coder/Fertilizer_recommendation_system/blob/eee0eb67f9bc6aae83f63718643e74a4eaeae3e6/register.png)

### Login Page
![Login Page](screenshots/login.png)

### Prediction Page
![Prediction Page](screenshots/predict.png)

### History Page
![History Page](screenshots/history.png)
