# 📊 How to View MySQL Database Tables - Complete Guide

## 🔗 MySQL Connection Details

From your `backend/src/db.js` file:

```javascript
const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || '127.0.0.1',
  port: Number(process.env.MYSQL_PORT || 3306),
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || '',
  database: process.env.MYSQL_DATABASE || 'smart_pill_reminder',
  ...
});
```

### Default Connection Info:
| Property | Value |
|----------|-------|
| **Host** | `127.0.0.1` (localhost) |
| **Port** | `3306` |
| **User** | `root` |
| **Password** | (empty by default) |
| **Database** | `smart_pill_reminder` |

---

## 🛠️ Method 1: Using MySQL Command Line (Windows CMD)

### Step 1: Open Command Prompt
Press `Win + R`, type `cmd`, and press Enter.

### Step 2: Connect to MySQL
```bash
mysql -h localhost -u root -p
```

When prompted, press Enter if no password is set (default).

### Step 3: View All Databases
```sql
SHOW DATABASES;
```

**Output should show:**
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| smart_pill_reminder| ← Your database
+--------------------+
```

### Step 4: Select Your Database
```sql
USE smart_pill_reminder;
```

### Step 5: View All Tables
```sql
SHOW TABLES;
```

**Output should show:**
```
+----------------------------------+
| Tables_in_smart_pill_reminder    |
+----------------------------------+
| alarm_logs                       |
| barcode_lookup_cache             |
| caretakers                       |
| medicines                        |
| missed_medicine_alerts           |
| professional_review_requests     |
| reminders                        |
| user_profiles                    |
| users                            |
+----------------------------------+
```

### Step 6: View Table Structure
```sql
DESCRIBE medicines;
```

Or view data:
```sql
SELECT * FROM medicines;
```

### Common Commands:
```sql
-- View all medicines
SELECT * FROM medicines;

-- View all reminders
SELECT * FROM reminders;

-- View all caretakers
SELECT * FROM caretakers;

-- View all users
SELECT * FROM users;

-- View all alarm logs
SELECT * FROM alarm_logs;

-- View professional review requests
SELECT * FROM professional_review_requests;

-- View user profiles
SELECT * FROM user_profiles;

-- Count records in a table
SELECT COUNT(*) FROM medicines;

-- Exit MySQL
EXIT;
```

---

## 🛠️ Method 2: Using MySQL Workbench (GUI - Recommended)

### Step 1: Download MySQL Workbench
Download from: https://www.mysql.com/products/workbench/

### Step 2: Install and Open
Run the installer and launch MySQL Workbench.

### Step 3: Create New Connection
1. Click **"+"** button next to "MySQL Connections"
2. Fill in:
   - **Connection Name:** `smart_pill_reminder`
   - **Hostname:** `127.0.0.1`
   - **Port:** `3306`
   - **Username:** `root`
   - **Password:** (leave empty if none)
3. Click **"Test Connection"**
4. Click **"OK"**

### Step 4: Open Connection
Double-click your new connection to open it.

### Step 5: Browse Tables
In the left sidebar, expand:
```
Schemas
  └── smart_pill_reminder
      ├── Tables
      │   ├── alarm_logs
      │   ├── barcode_lookup_cache
      │   ├── caretakers
      │   ├── medicines
      │   ├── missed_medicine_alerts
      │   ├── professional_review_requests
      │   ├── reminders
      │   ├── user_profiles
      │   └── users
```

### Step 6: View Table Data
Right-click any table → **"Select Rows - Limit 1000"**

Or double-click to open the table.

---

## 🛠️ Method 3: Using DBeaver (Free & Powerful)

### Step 1: Download DBeaver
Download from: https://dbeaver.io/download/

### Step 2: Create Connection
1. Click **"New Database Connection"** (top left)
2. Select **"MySQL"**
3. Fill in connection details:
   - **Server Host:** `localhost`
   - **Port:** `3306`
   - **Database:** `smart_pill_reminder`
   - **Username:** `root`
   - **Password:** (empty)
4. Click **"Test Connection"**
5. Click **"Finish"**

### Step 3: Browse Tables
In the left panel, expand your connection and view all tables with GUI.

---

## 🛠️ Method 4: Using VS Code Extension

### Step 1: Install Extension
1. Open VS Code
2. Go to **Extensions**
3. Search for **"MySQL"** or **"MySQL - Database Explorer"**
4. Install **"MySQL - Database Explorer"** by Taha Zamani

### Step 2: Configure Connection
1. Click database icon in left sidebar
2. Click **"Add Connection"**
3. Fill in details:
   ```
   Host: localhost
   Port: 3306
   User: root
   Password: (empty)
   Database: smart_pill_reminder
   ```
4. Click **"Connect"**

### Step 3: View Tables
All tables appear in the left panel with data preview.

---

## 📋 Database Tables Structure

Here are all your tables:

### 1. **medicines**
Stores medicine information
```sql
DESC medicines;
```
Columns: id, user_id, local_id, name, dosage, time, category, expiry_date, is_scanned, scanned_text, image_path, health_condition, created_at

### 2. **reminders**
Stores medication reminders
```sql
DESC reminders;
```
Columns: id, user_id, local_id, medicine_id, medicine_name, time, days_of_week, is_active, last_notified_at, created_at

### 3. **caretakers**
Stores caretaker information
```sql
DESC caretakers;
```
Columns: id, user_id, local_id, first_name, last_name, phone_number, email, relationship, notify_via_sms, notify_via_email, notify_via_notification, is_active, created_at

### 4. **users**
Stores user accounts
```sql
DESC users;
```
Columns: id, email, password_hash, created_at, updated_at

### 5. **user_profiles**
Stores detailed user profile information
```sql
DESC user_profiles;
```
Columns: id, user_id, first_name, last_name, gender, birth_date, zip_code, phone_number, email, created_at, updated_at

### 6. **alarm_logs**
Stores alarm/reminder trigger logs
```sql
DESC alarm_logs;
```
Columns: id, user_id, local_id, medicine_id, medicine_name, scheduled_time, triggered_time, status, snooze_count, taken_at, notes

### 7. **missed_medicine_alerts**
Stores missed medicine alerts
```sql
DESC missed_medicine_alerts;
```
Columns: id, medicine_id, medicine_name, scheduled_time, detected_time, notification_sent, caretakers_notified, status, notes

### 8. **professional_review_requests**
Stores doctor/hospital review requests
```sql
DESC professional_review_requests;
```
Columns: id, user_id, patient_name, contact, concern, preferred_hospital, urgency, status, created_at

### 9. **barcode_lookup_cache**
Stores cached barcode lookups
```sql
DESC barcode_lookup_cache;
```
Columns: barcode, name, dosage, category, cached_at

---

## ✅ Sample Queries to Try

### View All Users
```sql
SELECT * FROM users;
```

### View All Medicines for a User
```sql
SELECT * FROM medicines WHERE user_id = 'email@example.com';
```

### View All Reminders for a User
```sql
SELECT * FROM reminders WHERE user_id = 'email@example.com';
```

### View All Caretakers for a User
```sql
SELECT * FROM caretakers WHERE user_id = 'email@example.com';
```

### View Professional Review Requests
```sql
SELECT * FROM professional_review_requests;
```

### Count Total Records
```sql
SELECT 
  (SELECT COUNT(*) FROM medicines) AS total_medicines,
  (SELECT COUNT(*) FROM reminders) AS total_reminders,
  (SELECT COUNT(*) FROM caretakers) AS total_caretakers,
  (SELECT COUNT(*) FROM users) AS total_users;
```

### View Recent Activity
```sql
SELECT 
  m.name AS medicine_name,
  r.time AS reminder_time,
  r.days_of_week,
  m.created_at
FROM medicines m
LEFT JOIN reminders r ON m.id = r.medicine_id
ORDER BY m.created_at DESC
LIMIT 10;
```

---

## 🔧 Troubleshooting

### Problem: "Can't connect to MySQL server"
**Solution:**
1. Make sure MySQL is installed and running
2. Check if port 3306 is not blocked by firewall
3. Verify credentials in `.env` file

### Problem: "Database doesn't exist"
**Solution:**
Run the schema creation script from `backend/sql/schema.sql`:
```bash
mysql -h localhost -u root -p smart_pill_reminder < backend/sql/schema.sql
```

### Problem: "Access denied for user 'root'"
**Solution:**
1. Reset MySQL password
2. Or use different user credentials in `.env`

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Connect to MySQL | `mysql -h localhost -u root -p` |
| List databases | `SHOW DATABASES;` |
| Select database | `USE smart_pill_reminder;` |
| List tables | `SHOW TABLES;` |
| View table structure | `DESCRIBE medicines;` |
| View all data | `SELECT * FROM medicines;` |
| View with limit | `SELECT * FROM medicines LIMIT 10;` |
| Count records | `SELECT COUNT(*) FROM medicines;` |
| Exit MySQL | `EXIT;` |

---

## 🎯 Recommended: Use MySQL Workbench or DBeaver

Both provide:
- ✅ Visual interface (no command line)
- ✅ Data editing
- ✅ Query builder
- ✅ Table relationships view
- ✅ Export/Import data
- ✅ Better performance for large tables

**Start with MySQL Workbench** - it's the official MySQL GUI tool!

---

Need help with any specific query? Let me know! 🚀

