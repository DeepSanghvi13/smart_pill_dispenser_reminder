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

CREATE TABLE IF NOT EXISTS medicines (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL,
  local_id BIGINT NULL,
  name VARCHAR(190) NOT NULL,
  dosage VARCHAR(190) NOT NULL,
  time VARCHAR(32) NOT NULL,
  category VARCHAR(32) NOT NULL DEFAULT 'tablets',
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

