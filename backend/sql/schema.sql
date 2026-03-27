<<<<<<< HEAD
-- MongoDB migration note:
-- SQL schema is deprecated for this project.
-- Active database is MongoDB via MONGODB_URI in backend/.env.
-- Use MongoDB Compass with URI: mongodb://localhost:27017/
=======
CREATE DATABASE IF NOT EXISTS smart_pill_reminder;
USE smart_pill_reminder;

CREATE TABLE IF NOT EXISTS user_profiles (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender VARCHAR(32) NULL,
  birth_date VARCHAR(32) NULL,
  zip_code VARCHAR(32) NULL,
  phone_number VARCHAR(32) NULL,
  email VARCHAR(190) NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  is_admin TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_users_email (email)
);

CREATE TABLE IF NOT EXISTS auth_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  event_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  source VARCHAR(32) NOT NULL,
  ip_address VARCHAR(64) NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_auth_logs_email (email),
  INDEX idx_auth_logs_created_at (created_at)
);

CREATE TABLE IF NOT EXISTS dependents (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender VARCHAR(32) NULL,
  birth_date VARCHAR(32) NULL,
  color VARCHAR(32) NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_dependents_user_local (user_id, local_id),
  INDEX idx_dependents_user (user_id)
);

CREATE TABLE IF NOT EXISTS settings (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  key_name VARCHAR(128) NOT NULL,
  value TEXT NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE KEY uq_settings_user_key (user_id, key_name),
  INDEX idx_settings_user (user_id)
);

CREATE TABLE IF NOT EXISTS medicines (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  name VARCHAR(190) NOT NULL,
  dosage VARCHAR(190) NOT NULL,
  time VARCHAR(32) NOT NULL,
  category VARCHAR(32) NOT NULL DEFAULT 'tablets',
  expiry_date DATETIME NULL,
  is_scanned TINYINT(1) NOT NULL DEFAULT 0,
  scanned_text TEXT NULL,
  image_path VARCHAR(512) NULL,
  health_condition VARCHAR(190) NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_medicines_user_local (user_id, local_id),
  INDEX idx_medicines_user (user_id)
);

CREATE TABLE IF NOT EXISTS reminders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  medicine_id BIGINT NOT NULL,
  medicine_name VARCHAR(190) NOT NULL,
  time VARCHAR(32) NOT NULL,
  days_of_week JSON NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_notified_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_reminders_user_local (user_id, local_id),
  INDEX idx_reminders_user (user_id)
);

CREATE TABLE IF NOT EXISTS alarm_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  medicine_id BIGINT NOT NULL,
  medicine_name VARCHAR(190) NOT NULL,
  scheduled_time DATETIME NOT NULL,
  triggered_time DATETIME NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  snooze_count INT NOT NULL DEFAULT 0,
  taken_at DATETIME NULL,
  notes TEXT NULL,
  UNIQUE KEY uq_alarm_logs_user_local (user_id, local_id),
  INDEX idx_alarm_logs_user (user_id)
);

CREATE TABLE IF NOT EXISTS caretakers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(32) NOT NULL,
  email VARCHAR(190) NOT NULL,
  relationship VARCHAR(100) NOT NULL,
  notify_via_sms TINYINT(1) NOT NULL DEFAULT 1,
  notify_via_email TINYINT(1) NOT NULL DEFAULT 1,
  notify_via_notification TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_caretakers_user_local (user_id, local_id),
  INDEX idx_caretakers_user (user_id)
);

CREATE TABLE IF NOT EXISTS professional_review_requests (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  patient_name VARCHAR(190) NOT NULL,
  contact VARCHAR(190) NOT NULL,
  concern TEXT NOT NULL,
  preferred_hospital VARCHAR(255) NULL,
  urgency VARCHAR(32) NOT NULL DEFAULT 'normal',
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL,
  INDEX idx_review_requests_user (user_id),
  INDEX idx_review_requests_status (status)
);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26

