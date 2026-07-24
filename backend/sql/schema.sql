-- Create Database if not exists and select it
CREATE DATABASE IF NOT EXISTS `smart_pill_reminder` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `smart_pill_reminder`;

-- Drop existing tables in correct order of dependency if they exist
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `caretaker_connections`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `reminders`;
DROP TABLE IF EXISTS `alarmLogs`;
DROP TABLE IF EXISTS `medicines`;
DROP TABLE IF EXISTS `activity_logs`;
DROP TABLE IF EXISTS `user_sessions`;
DROP TABLE IF EXISTS `admins`;
DROP TABLE IF EXISTS `caretakers`;
DROP TABLE IF EXISTS `patients`;
DROP TABLE IF EXISTS `dependents`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `professionalReviewRequests`;
DROP TABLE IF EXISTS `userProfiles`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- Table 1: users (core identity table)
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `fullName` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) UNIQUE NOT NULL,
  `phoneNumber` VARCHAR(50) DEFAULT NULL,
  `passwordHash` VARCHAR(255) NOT NULL,
  `role` ENUM('patient', 'caretaker', 'admin') NOT NULL DEFAULT 'patient',
  `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
  `lastLoginAt` DATETIME DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_email` (`email`),
  INDEX `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: patients (patient-specific details)
CREATE TABLE IF NOT EXISTS `patients` (
  `userId` INT PRIMARY KEY,
  `gender` VARCHAR(50) DEFAULT NULL,
  `birthDate` DATE DEFAULT NULL,
  `zipCode` VARCHAR(20) DEFAULT NULL,
  CONSTRAINT `fk_patients_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: caretakers (caretaker-specific details)
CREATE TABLE IF NOT EXISTS `caretakers` (
  `userId` INT PRIMARY KEY,
  `relationship` VARCHAR(100) DEFAULT NULL,
  `notifyViaSMS` BOOLEAN DEFAULT TRUE,
  `notifyViaEmail` BOOLEAN DEFAULT TRUE,
  `notifyViaNotification` BOOLEAN DEFAULT TRUE,
  CONSTRAINT `fk_caretakers_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: admins (admin-specific details)
CREATE TABLE IF NOT EXISTS `admins` (
  `userId` INT PRIMARY KEY,
  CONSTRAINT `fk_admins_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: user_sessions (session audit log)
CREATE TABLE IF NOT EXISTS `user_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `token` VARCHAR(500) NOT NULL,
  `ipAddress` VARCHAR(100) DEFAULT NULL,
  `device` VARCHAR(255) DEFAULT NULL,
  `browser` VARCHAR(255) DEFAULT NULL,
  `operatingSystem` VARCHAR(100) DEFAULT NULL,
  `loginAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `logoutAt` DATETIME DEFAULT NULL,
  `sessionDuration` INT DEFAULT NULL, -- session duration in seconds
  CONSTRAINT `fk_sessions_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: activity_logs (comprehensive action logs)
CREATE TABLE IF NOT EXISTS `activity_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT DEFAULT NULL,
  `userRole` VARCHAR(50) NOT NULL,
  `userName` VARCHAR(255) DEFAULT NULL,
  `userEmail` VARCHAR(255) DEFAULT NULL,
  `activityType` VARCHAR(100) NOT NULL, -- REGISTER, REGISTER_FAILED, LOGIN, LOGIN_FAILED, LOGOUT
  `description` TEXT DEFAULT NULL,
  `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `ipAddress` VARCHAR(100) DEFAULT NULL,
  `device` VARCHAR(255) DEFAULT NULL,
  `browser` VARCHAR(255) DEFAULT NULL,
  `operatingSystem` VARCHAR(100) DEFAULT NULL,
  `status` VARCHAR(50) DEFAULT NULL, -- SUCCESS, FAILED
  `sessionId` INT DEFAULT NULL,
  CONSTRAINT `fk_activity_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_activity_sessionId` FOREIGN KEY (`sessionId`) REFERENCES `user_sessions` (`id`) ON DELETE SET NULL,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_activityType` (`activityType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 7: medicines (patient medication schedules)
CREATE TABLE IF NOT EXISTS `medicines` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` VARCHAR(100) NOT NULL, -- tablets, syrup, injection
  `dosage` VARCHAR(255) NOT NULL,
  `quantity` VARCHAR(100) NOT NULL,
  `frequency` VARCHAR(100) NOT NULL, -- Daily, Weekly
  `time` VARCHAR(255) NOT NULL, -- e.g. "08:00 AM"
  `startDate` DATE NOT NULL,
  `endDate` DATE NOT NULL,
  `notes` TEXT DEFAULT NULL,
  `status` VARCHAR(50) DEFAULT 'pending',
  `lastActionDate` DATE DEFAULT NULL,
  `isScanned` BOOLEAN DEFAULT FALSE,
  `scannedText` TEXT DEFAULT NULL,
  `imagePath` VARCHAR(255) DEFAULT NULL,
  `healthCondition` VARCHAR(255) DEFAULT NULL,
  `createdBy` INT NOT NULL,
  `updatedBy` INT NOT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_medicines_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_medicines_createdBy` FOREIGN KEY (`createdBy`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_medicines_updatedBy` FOREIGN KEY (`updatedBy`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 8: reminders
CREATE TABLE IF NOT EXISTS `reminders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `medicineId` INT NOT NULL,
  `time` VARCHAR(255) NOT NULL,
  `daysOfWeek` TEXT DEFAULT NULL, -- JSON array
  `isActive` BOOLEAN DEFAULT TRUE,
  `lastNotifiedAt` DATETIME DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_reminders_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reminders_medicineId` FOREIGN KEY (`medicineId`) REFERENCES `medicines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 9: alarmLogs
CREATE TABLE IF NOT EXISTS `alarmLogs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `medicineId` INT NOT NULL,
  `medicineName` VARCHAR(255) NOT NULL,
  `scheduledTime` DATETIME NOT NULL,
  `triggeredTime` DATETIME DEFAULT NULL,
  `status` VARCHAR(100) DEFAULT 'pending',
  `snoozeCount` INT DEFAULT 0,
  `takenAt` DATETIME DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_alarm_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_alarm_medicineId` FOREIGN KEY (`medicineId`) REFERENCES `medicines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 10: notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `body` TEXT NOT NULL,
  `type` VARCHAR(50) DEFAULT 'alert',
  `isRead` BOOLEAN DEFAULT FALSE,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_notifications_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 11: caretaker_connections (caretaker relationships mapping)
CREATE TABLE IF NOT EXISTS `caretaker_connections` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `patientId` INT NOT NULL,
  `caretakerId` INT NOT NULL,
  `connectionCode` VARCHAR(100) NOT NULL,
  `status` VARCHAR(50) DEFAULT 'connected',
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_conn_patientId` FOREIGN KEY (`patientId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conn_caretakerId` FOREIGN KEY (`caretakerId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  UNIQUE KEY `unique_connection` (`patientId`, `caretakerId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 12: dependents
CREATE TABLE IF NOT EXISTS `dependents` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `firstName` VARCHAR(255) NOT NULL,
  `lastName` VARCHAR(255) NOT NULL,
  `gender` VARCHAR(100) DEFAULT NULL,
  `birthDate` VARCHAR(100) DEFAULT NULL,
  `color` VARCHAR(100) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_dependents_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 13: settings
CREATE TABLE IF NOT EXISTS `settings` (
  `userId` INT NOT NULL,
  `keyName` VARCHAR(255) NOT NULL,
  `value` TEXT NOT NULL,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `keyName`),
  CONSTRAINT `fk_settings_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 14: professionalReviewRequests
CREATE TABLE IF NOT EXISTS `professionalReviewRequests` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `patientName` VARCHAR(255) NOT NULL,
  `contact` VARCHAR(255) NOT NULL,
  `concern` TEXT NOT NULL,
  `preferredHospital` VARCHAR(255) DEFAULT NULL,
  `urgency` VARCHAR(100) DEFAULT 'normal',
  `status` VARCHAR(100) DEFAULT 'pending',
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_reviews_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 15: userProfiles
CREATE TABLE IF NOT EXISTS `userProfiles` (
  `userId` INT PRIMARY KEY,
  `firstName` VARCHAR(255) NOT NULL,
  `lastName` VARCHAR(255) NOT NULL,
  `gender` VARCHAR(100) DEFAULT NULL,
  `birthDate` VARCHAR(100) DEFAULT NULL,
  `zipCode` VARCHAR(100) DEFAULT NULL,
  `phoneNumber` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_profiles_userId` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
