-- Create Database if not exists
CREATE DATABASE IF NOT EXISTS `smart_pill_reminder` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `smart_pill_reminder`;

-- Table 1: users
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) UNIQUE NOT NULL,
  `passwordHash` VARCHAR(255) NOT NULL,
  `isAdmin` BOOLEAN DEFAULT FALSE,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: authLogs
CREATE TABLE IF NOT EXISTS `authLogs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL,
  `eventType` VARCHAR(100) NOT NULL,
  `status` VARCHAR(100) NOT NULL,
  `source` VARCHAR(100) DEFAULT 'mobile',
  `ipAddress` VARCHAR(100) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: medicines
CREATE TABLE IF NOT EXISTS `medicines` (
  `userId` VARCHAR(255) NOT NULL,
  `id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `dosage` VARCHAR(255) NOT NULL,
  `time` VARCHAR(255) NOT NULL,
  `category` VARCHAR(100) DEFAULT 'tablets',
  `expiryDate` DATETIME DEFAULT NULL,
  `isScanned` BOOLEAN DEFAULT FALSE,
  `scannedText` TEXT DEFAULT NULL,
  `imagePath` VARCHAR(255) DEFAULT NULL,
  `healthCondition` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: reminders
CREATE TABLE IF NOT EXISTS `reminders` (
  `userId` VARCHAR(255) NOT NULL,
  `id` INT NOT NULL,
  `medicineId` INT NOT NULL,
  `medicineName` VARCHAR(255) NOT NULL,
  `time` VARCHAR(255) NOT NULL,
  `daysOfWeek` TEXT DEFAULT NULL, -- Stored as JSON array string
  `isActive` BOOLEAN DEFAULT TRUE,
  `lastNotifiedAt` DATETIME DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: alarmLogs
CREATE TABLE IF NOT EXISTS `alarmLogs` (
  `userId` VARCHAR(255) NOT NULL,
  `id` INT NOT NULL,
  `medicineId` INT NOT NULL,
  `medicineName` VARCHAR(255) NOT NULL,
  `scheduledTime` DATETIME NOT NULL,
  `triggeredTime` DATETIME DEFAULT NULL,
  `status` VARCHAR(100) DEFAULT 'pending',
  `snoozeCount` INT DEFAULT 0,
  `takenAt` DATETIME DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: caretakers
CREATE TABLE IF NOT EXISTS `caretakers` (
  `userId` VARCHAR(255) NOT NULL,
  `id` INT NOT NULL,
  `firstName` VARCHAR(255) NOT NULL,
  `lastName` VARCHAR(255) NOT NULL,
  `phoneNumber` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `relationship` VARCHAR(255) NOT NULL,
  `notifyViaSMS` BOOLEAN DEFAULT TRUE,
  `notifyViaEmail` BOOLEAN DEFAULT TRUE,
  `notifyViaNotification` BOOLEAN DEFAULT TRUE,
  `isActive` BOOLEAN DEFAULT TRUE,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 7: dependents
CREATE TABLE IF NOT EXISTS `dependents` (
  `userId` VARCHAR(255) NOT NULL,
  `id` INT NOT NULL,
  `firstName` VARCHAR(255) NOT NULL,
  `lastName` VARCHAR(255) NOT NULL,
  `gender` VARCHAR(100) DEFAULT NULL,
  `birthDate` VARCHAR(100) DEFAULT NULL,
  `color` VARCHAR(100) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 8: settings
CREATE TABLE IF NOT EXISTS `settings` (
  `userId` VARCHAR(255) NOT NULL,
  `keyName` VARCHAR(255) NOT NULL,
  `value` TEXT NOT NULL,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`userId`, `keyName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 9: userProfiles
CREATE TABLE IF NOT EXISTS `userProfiles` (
  `userId` VARCHAR(255) PRIMARY KEY,
  `firstName` VARCHAR(255) NOT NULL,
  `lastName` VARCHAR(255) NOT NULL,
  `gender` VARCHAR(100) DEFAULT NULL,
  `birthDate` VARCHAR(100) DEFAULT NULL,
  `zipCode` VARCHAR(100) DEFAULT NULL,
  `phoneNumber` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 10: professionalReviewRequests
CREATE TABLE IF NOT EXISTS `professionalReviewRequests` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` VARCHAR(255) NOT NULL,
  `patientName` VARCHAR(255) NOT NULL,
  `contact` VARCHAR(255) NOT NULL,
  `concern` TEXT NOT NULL,
  `preferredHospital` VARCHAR(255) DEFAULT NULL,
  `urgency` VARCHAR(100) DEFAULT 'normal',
  `status` VARCHAR(100) DEFAULT 'pending',
  `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
