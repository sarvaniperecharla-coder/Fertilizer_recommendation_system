-- =====================================================================
-- AI-BASED FERTILIZER RECOMMENDATION SYSTEM
-- Database Schema File: database.sql
-- =====================================================================
-- This file creates the entire database structure used by the project.
--
-- HOW TO RUN THIS FILE (Windows):
--   1. Open MySQL Workbench (or the "MySQL Command Line Client").
--   2. Connect to your local MySQL server using your root password.
--   3. Open this file (File > Open SQL Script) and click the lightning
--      bolt icon to execute the whole script, OR
--   4. From a terminal, run:
--         mysql -u root -p < database.sql
--
-- This script is SAFE TO RE-RUN: it drops the database first so you
-- always start from a clean, known state while developing.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1: Create the database
-- ---------------------------------------------------------------------

-- Remove any old version of the database so this script can be re-run
-- safely during development without leftover/corrupted tables.
DROP DATABASE IF EXISTS fertilizer_db;

-- Create the database that will hold all our tables.
-- utf8mb4 is used so the database can store any character (emojis,
-- accented letters, etc.) without errors.
CREATE DATABASE fertilizer_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Tell MySQL to use this database for every statement that follows.
USE fertilizer_db;


-- ---------------------------------------------------------------------
-- STEP 2: Create the "users" table
-- ---------------------------------------------------------------------
-- Stores every registered user of the system (the people who will log
-- in, request fertilizer predictions, and view their own history).

CREATE TABLE users (
    -- Primary key: a unique, auto-incrementing ID for every user.
    user_id        INT AUTO_INCREMENT PRIMARY KEY,

    -- The username chosen at registration. Must be unique so two
    -- people cannot register with the same username.
    username        VARCHAR(50)  NOT NULL UNIQUE,

    -- The user's email address. Also unique, used for login and to
    -- prevent duplicate accounts.
    email           VARCHAR(100) NOT NULL UNIQUE,

    -- The user's full name, shown on the dashboard and profile page.
    full_name       VARCHAR(100) NOT NULL,

    -- We NEVER store plain-text passwords. This column stores a
    -- one-way hash produced by werkzeug's generate_password_hash()
    -- in app.py. 255 characters is enough room for any hash format.
    password_hash   VARCHAR(255) NOT NULL,

    -- Optional phone number for the user's profile page.
    phone           VARCHAR(20)  NULL,

    -- Automatically set to the current date/time the row is created.
    -- This gives us a permanent record of when each account was made.
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Automatically updated every time the row is modified (e.g. if
    -- the user edits their profile). Useful for auditing.
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                     ON UPDATE CURRENT_TIMESTAMP,

    -- A simple flag the admin can use to disable an account without
    -- deleting it outright (not required by the spec, but harmless
    -- and useful — defaults to active for every new user).
    is_active       TINYINT(1) DEFAULT 1,

    -- Indexes speed up the most common lookups: logging in by email
    -- or username, which happens on every login attempt.
    INDEX idx_users_email (email),
    INDEX idx_users_username (username)
) ENGINE=InnoDB;
-- InnoDB is required (not MyISAM) because it supports the FOREIGN KEY
-- constraints we use below.


-- ---------------------------------------------------------------------
-- STEP 3: Create the "admin" table
-- ---------------------------------------------------------------------
-- Admin accounts are kept completely separate from regular "users".
-- This is intentional: an admin is not a "user with extra rights" in
-- this design — it is a distinct login realm with its own table and
-- its own /admin login route in Flask. This keeps the permission
-- model simple and avoids accidentally exposing admin powers through
-- the normal user-login code path.

CREATE TABLE admin (
    -- Primary key for the admin table.
    admin_id        INT AUTO_INCREMENT PRIMARY KEY,

    -- Admin login username (unique).
    username        VARCHAR(50)  NOT NULL UNIQUE,

    -- Admin's email, kept for reference/contact purposes.
    email           VARCHAR(100) NOT NULL UNIQUE,

    -- Hashed password, exactly like the users table — never plain text.
    password_hash   VARCHAR(255) NOT NULL,

    -- When this admin account was created.
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Last time this admin actually logged in. Updated by app.py on
    -- every successful admin login — useful for the admin dashboard
    -- statistics screen in Phase 7.
    last_login      TIMESTAMP NULL,

    INDEX idx_admin_username (username)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- STEP 4: Create the "prediction_history" table
-- ---------------------------------------------------------------------
-- Stores every single fertilizer prediction ever made, linked back to
-- the user who made it. This table is the source of truth for both
-- the user's personal "Prediction History" page and the admin's
-- "View Prediction History" page.

CREATE TABLE prediction_history (
    -- Primary key for each prediction record.
    prediction_id           INT AUTO_INCREMENT PRIMARY KEY,

    -- Foreign key linking this prediction to the user who made it.
    -- ON DELETE CASCADE means: if an admin deletes a user, all of
    -- that user's prediction history is automatically deleted too,
    -- so we never end up with "orphaned" predictions pointing to a
    -- user that no longer exists.
    user_id                  INT NOT NULL,

    -- ---------------- INPUT PARAMETERS (what the user submitted) ----------------
    crop_type                VARCHAR(50)  NOT NULL,
    soil_type                VARCHAR(50)  NOT NULL,
    temperature               FLOAT NOT NULL,   -- in Celsius
    humidity                  FLOAT NOT NULL,   -- in percent
    rainfall                   FLOAT NOT NULL,   -- in millimeters
    moisture                    FLOAT NOT NULL,   -- in percent
    nitrogen                     FLOAT NOT NULL,   -- N value (mg/kg)
    phosphorus                    FLOAT NOT NULL,   -- P value (mg/kg)
    potassium                      FLOAT NOT NULL,   -- K value (mg/kg)
    soil_ph                         FLOAT NOT NULL,   -- pH value (0-14 scale)

    -- ---------------- OUTPUT (what the ML model returned) ----------------
    recommended_fertilizer            VARCHAR(100) NOT NULL,
    confidence_score                   FLOAT NOT NULL,  -- 0-100 (%)
    reason                               TEXT NULL,       -- short ML-generated explanation
    nutrient_status                      VARCHAR(255) NULL, -- e.g. "Nitrogen: Low, Phosphorus: Adequate..."
    usage_instructions                    TEXT NULL,
    application_tips                       TEXT NULL,

    -- When this prediction was made.
    created_at                              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- The actual foreign key constraint enforcing the relationship
    -- described above.
    CONSTRAINT fk_prediction_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Indexes for the two most common queries on this table:
    -- "show me this user's history" and "show predictions sorted by date".
    INDEX idx_prediction_user (user_id),
    INDEX idx_prediction_created (created_at)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- STEP 5: Seed a default admin account
-- ---------------------------------------------------------------------
-- This inserts one ready-to-use admin account so you can log into the
-- admin dashboard immediately after setup, without writing a separate
-- registration flow for admins (the spec only requires "Admin Login",
-- not "Admin Registration").
--
-- Login credentials for this seeded account:
--     Username: admin
--     Password: Admin@123
--
-- The password below is NOT stored in plain text — it is a real
-- pbkdf2:sha256 hash generated with werkzeug's generate_password_hash(),
-- the exact same function app.py uses for every other password in
-- this system. Change this password after your first login in a real
-- deployment.

INSERT INTO admin (username, email, password_hash)
VALUES (
    'admin',
    'admin@fertilizer-system.local',
    'pbkdf2:sha256:1000000$59hjFbGBaq59wLND$52f3e4503f0e9ece686af52d35d9cb0b0d0b33558b4e0df93702fe6be12ed23f'
);


-- ---------------------------------------------------------------------
-- STEP 6: Verification queries (optional — safe to run manually)
-- ---------------------------------------------------------------------
-- Uncomment and run these any time to sanity-check the schema:
--
-- SHOW TABLES;
-- DESCRIBE users;
-- DESCRIBE admin;
-- DESCRIBE prediction_history;
-- SELECT * FROM admin;

-- =====================================================================
-- END OF database.sql
-- =====================================================================