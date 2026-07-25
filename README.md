# 💊 Smart Pill Dispenser & Reminder

A comprehensive, full-stack cross-platform Flutter application and Node.js/MySQL backend system designed to ensure medication adherence, streamline prescription management, and enable real-time collaboration between **Patients**, **Caretakers**, and **Administrators**.

---

## 🌟 Key Features & Role Dashboards

### 👨‍⚕️ 1. Patient Module
- **Medication Management**: Add, edit, track, and delete medicines (Tablets, Syrups, Injections).
- **Smart Reminders**: Audio & push notifications configured via `flutter_local_notifications`.
- **OCR Prescription Scanning**: Extract dosage and medicine schedules directly from physical prescriptions using Google ML Kit Text Recognition.
- **Barcode Lookup**: Quickly fetch medication details by scanning standard medicine barcodes using `mobile_scanner`.
- **Expiry Tracker**: Visual calendar view highlighting upcoming medication expirations.
- **Text-to-Speech (TTS)**: Voice playback of dosage instructions for accessible healthcare management.

### 🛡️ 2. Caretaker Module
- **Multi-Patient Connection**: Connect to patients using unique Connection Codes (e.g., `SPD-XXXXXX`) or Email/Phone verification.
- **Remote Monitoring**: Track medication logs, adherence statuses, and missed dose alerts in real-time.
- **Caretaker Audit Logs**: Full trackability showing which caretaker scheduled or updated a patient's prescription.

### ⚙️ 3. Admin Module
- **System Dashboard**: Complete system summary analytics (Total Users, Active Patients, Caretakers, System Health, Database Connections).
- **User Management**: Search, filter, edit roles, toggle active/inactive status, reset user passwords, or delete accounts.
- **Caretaker-Patient Connections**: Manually link or unlink caretakers and patients from the admin console.
- **System Reports & Audit Trails**: View full compliance statistics and user activity logs (`REGISTER`, `LOGIN`, `MEDICINE_ADD`, `LOGOUT`).
- **Announcements & Broadcasts**: Post application-wide system updates and alerts.

---

## 🏗️ Architecture & Technology Stack

```text
┌─────────────────────────────────────────────────────────┐
│                 Flutter Application (Client)            │
│  - Hive Box (Local Persistence & Offline First)         │
│  - Provider / ThemeController (State Management)        │
│  - MySQLSyncHelper / MySQLApiService (Network Gateway)  │
└────────────────────────────┬────────────────────────────┘
                             │ REST API (JSON / JWT)
┌────────────────────────────▼────────────────────────────┐
│                 Node.js Express API (Backend)           │
│  - Auth Middleware & BCrypt Password Hashing            │
│  - Comprehensive Activity Logging System                │
│  - MySQL Connection Pool (mysql2)                       │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│               MySQL Database (XAMPP / Server)           │
│  - Smart Pill Reminder Relational Schema (15 Tables)    │
└─────────────────────────────────────────────────────────┘
```

### Stack Overview
- **Frontend Framework**: Flutter 3.x (Dart 3.x)
- **Local Persistence**: Hive (Key-Value NoSQL for local speed & offline capability)
- **Remote Persistence**: MySQL (Server audit trail, cross-device sync, identity management)
- **Backend API**: Node.js, Express.js, JWT, BCrypt, MySQL2 connection pooling
- **Hardware & ML Integrations**: Google ML Kit Text Recognition, Mobile Scanner, Flutter TTS

---

## 🗄️ Database Schema Summary (15 Relational Tables)

The MySQL database schema (`backend/sql/schema.sql`) consists of 15 relational tables:
1. `users` — Core identity & authentication table (Patients, Caretakers, Admins).
2. `userProfiles` — Comprehensive user profile metadata (First Name, Last Name, Phone, Gender).
3. `patients` — Patient specific demographic records.
4. `caretakers` — Caretaker preferences & alert settings.
5. `admins` — Administrator role mappings.
6. `user_sessions` — Session audit tracking login/logout times and session duration.
7. `activity_logs` — Comprehensive real-time user activity audit trail.
8. `medicines` — Medication schedules, dosage, and scanned prescription data.
9. `reminders` — Scheduled notification triggers and frequency details.
10. `alarmLogs` — Logged alarm triggers, taken doses, and snooze counts.
11. `notifications` — Push notification history.
12. `caretaker_connections` — Mapping between caretakers and assigned patients.
13. `dependents` — Family member/dependent profiles.
14. `settings` — User preferences & configuration settings.
15. `professionalReviewRequests` — Medical review & hospital consultation requests.

---

## 🚀 Complete Step-by-Step Setup & Execution Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
- [Node.js](https://nodejs.org/) (v16 or higher)
- [XAMPP](https://www.apachefriends.org/) (MySQL Server running on port `3306`)

---

### Step 1: Database Setup (XAMPP / MySQL)
1. Launch **XAMPP Control Panel** (or WAMP).
2. Start **MySQL** (ensure port `3306` turns green).
3. Open **phpMyAdmin** in your web browser: `http://localhost/phpmyadmin`.
   *(Note: Database `smart_pill_reminder` and all 15 tables are automatically created when `backend/src/server.js` runs).*

---

### Step 2: Backend Setup (Node.js API Server)
1. Open a terminal and navigate to the `backend` directory:
   ```powershell
   cd backend
   ```
2. Install project dependencies (if not installed yet):
   ```powershell
   npm install
   ```
3. Ensure `.env` exists in `backend/` directory:
   ```env
   PORT=3000
   MYSQL_HOST=localhost
   MYSQL_USER=root
   MYSQL_PASSWORD=
   MYSQL_DATABASE=smart_pill_reminder
   MYSQL_PORT=3306
   ADMIN_EMAIL=admin@smartpill.com
   ADMIN_PASSWORD=adminpassword
   ```
4. Start the Node.js backend server:
   ```powershell
   node src/server.js
   ```
   *Output on success:*
   ```text
   Default admin accounts verified in MySQL
   MySQL API running on http://localhost:3000/api
   ```

---

### Step 3: Flutter App Setup & Launch
1. Open a new terminal in the root project folder (`smart_pill_dispenser_reminder`).
2. Fetch Flutter packages:
   ```powershell
   flutter pub get
   ```
3. Run the app on your target device (Chrome Web, Windows Desktop, or Android Emulator):
   ```powershell
   flutter run -d chrome
   # Or for Windows desktop:
   flutter run -d windows
   # Or for Android emulator:
   flutter run
   ```

---

## 🔍 How to View Database Data (phpMyAdmin & In-App)

1. **Via phpMyAdmin**:
   - Open `http://localhost/phpmyadmin`.
   - Click on `smart_pill_reminder` database on the left sidebar.
   - Click on tables such as `users`, `userProfiles`, `medicines`, or `activity_logs` to view all stored data.

2. **Via In-App SQL Explorer**:
   - Log in as Admin (`admin@smartpill.com` / `adminpassword`).
   - Navigate to the **Admin Dashboard** -> **SQL Entries & System Status** to inspect table counts and database logs directly inside the app.

---

## 🛠️ Troubleshooting & FAQ

### ❌ Error: `listen EADDRINUSE: address already in use :::3000`
**Cause**: Another instance of Node.js is already running on port `3000`.

**Solutions**:
- **Option A (If backend is already running)**: If you previously launched `node src/server.js`, the server is already active and running! You don't need to launch it a second time.
- **Option B (Kill process on Port 3000 in PowerShell)**:
  ```powershell
  Stop-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess -Force
  ```
- **Option C (Kill all Node processes in Command Prompt)**:
  ```cmd
  taskkill /F /IM node.exe
  ```
  After stopping the old process, rerun `node src/server.js`.

---

### ❌ Error: `MySQL connection failed at startup: ECONNREFUSED`
**Cause**: MySQL service is not running in XAMPP or port 3306 is blocked.

**Solution**:
1. Open **XAMPP Control Panel**.
2. Click **Start** next to **MySQL**.
3. Re-run `node src/server.js`.

---

## 🔐 Default Credentials

| Role | Email | Password |
|---|---|---|
| **System Admin** | `admin@smartpill.com` | `adminpassword` |
