# 🎯 Step-by-Step: View Your MySQL Database Tables

## 📍 Your Database Location

**Host:** `127.0.0.1` (localhost)  
**Port:** `3306`  
**Database Name:** `smart_pill_reminder`  
**User:** `root`  
**Password:** (empty)  

---

## 🔧 Method 1: Command Line (Windows) - Easiest for Quick View

### Step-by-Step:

**Step 1:** Open Command Prompt
```
Press: Windows Key + R
Type: cmd
Press: Enter
```

**Step 2:** Launch MySQL
```bash
mysql -h localhost -u root
```
Then press `Enter`. It will show:
```
Welcome to the MySQL monitor.
Type 'help;' or '\h' for help.
mysql>
```

**Step 3:** Select Your Database
```sql
USE smart_pill_reminder;
```
Output: `Database changed`

**Step 4:** View All Tables
```sql
SHOW TABLES;
```
Output will show all 9 tables:
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

**Step 5:** View Table Contents

View medicines:
```sql
SELECT * FROM medicines;
```

View reminders:
```sql
SELECT * FROM reminders;
```

View caretakers:
```sql
SELECT * FROM caretakers;
```

View users:
```sql
SELECT * FROM users;
```

View alarm logs:
```sql
SELECT * FROM alarm_logs;
```

**Step 6:** Exit MySQL
```sql
EXIT;
```

---

## 🖥️ Method 2: MySQL Workbench (GUI - Recommended)

### Step-by-Step:

**Step 1:** Download MySQL Workbench
- Go to: https://www.mysql.com/products/workbench/
- Download for Windows
- Install it

**Step 2:** Open MySQL Workbench
- Launch MySQL Workbench from Start Menu

**Step 3:** Create Connection
- Click the **"+"** button next to "MySQL Connections"
- Dialog appears

**Step 4:** Fill Connection Details
Fill in these fields:
```
Connection Name: smart_pill_reminder
Hostname: 127.0.0.1
Port: 3306
Username: root
Password: (leave empty)
Default Schema: smart_pill_reminder
```

**Step 5:** Test Connection
- Click **"Test Connection"**
- Should say: "Successfully made the MySQL connection"
- Click **"OK"**

**Step 6:** Open Connection
- Double-click your new connection
- Connection opens

**Step 7:** Browse Tables
In left panel, you'll see:
```
smart_pill_reminder (database)
├── Tables
    ├── alarm_logs
    ├── barcode_lookup_cache
    ├── caretakers
    ├── medicines
    ├── missed_medicine_alerts
    ├── professional_review_requests
    ├── reminders
    ├── user_profiles
    └── users
```

**Step 8:** View Table Data
- Right-click any table (e.g., `medicines`)
- Select **"Select Rows - Limit 1000"**
- Data appears in main panel
- You can see, edit, add, delete records

**Step 9:** View Table Structure
- Right-click any table
- Select **"Alter Table"**
- Shows all columns and data types

---

## 🗄️ Method 3: DBeaver (Free GUI - Most Powerful)

### Step-by-Step:

**Step 1:** Download DBeaver
- Go to: https://dbeaver.io/download/
- Download Community Edition
- Install it

**Step 2:** Open DBeaver
- Launch DBeaver from Start Menu

**Step 3:** Create New Connection
- Click **"New Database Connection"** (icon on top left)
- Select **"MySQL"**
- Click **"Next"**

**Step 4:** Configure Connection
Fill in:
```
Server Host: 127.0.0.1
Port: 3306
Database: smart_pill_reminder
Username: root
Password: (leave empty)
```
Click **"Test Connection"**

**Step 5:** Complete Setup
- Click **"Finish"**
- Connection created

**Step 6:** Browse Database
Left panel shows:
```
Database Navigator
└── MySQL - localhost
    └── smart_pill_reminder [Database]
        └── Tables
            ├── alarm_logs
            ├── barcode_lookup_cache
            ├── caretakers
            ├── medicines
            ├── missed_medicine_alerts
            ├── professional_review_requests
            ├── reminders
            ├── user_profiles
            └── users
```

**Step 7:** View Data
- Double-click any table
- Data opens in center panel
- Edit directly in the grid
- Click **"Save"** to commit changes

---

## 📊 What You'll See in Each Table

### `users` table
```
id | email              | password_hash | created_at
1  | user@example.com   | hash...       | 2026-03-23
2  | admin@example.com  | hash...       | 2026-03-23
```

### `medicines` table
```
id | user_id | name        | dosage    | time  | category  | expiry_date
1  | user1   | Paracetamol | 500 MG    | 10:00 | tablets   | 2026-12-31
2  | user1   | Cough Syrup | 5 ML      | 09:00 | syrup     | 2026-11-30
```

### `reminders` table
```
id | user_id | medicine_id | medicine_name | time  | days_of_week | is_active
1  | user1   | 1           | Paracetamol   | 10:00 | Mon,Tue...   | 1
```

### `caretakers` table
```
id | user_id | first_name | last_name | phone_number | email            | relationship | is_active
1  | user1   | John       | Doe       | 555-1234     | john@example.com | Son          | 1
```

---

## ✅ Quick Command Reference

| Task | Command |
|------|---------|
| Connect | `mysql -h localhost -u root` |
| Show databases | `SHOW DATABASES;` |
| Select database | `USE smart_pill_reminder;` |
| Show all tables | `SHOW TABLES;` |
| Show table structure | `DESCRIBE medicines;` |
| View all records | `SELECT * FROM medicines;` |
| View first 10 records | `SELECT * FROM medicines LIMIT 10;` |
| Count records | `SELECT COUNT(*) FROM medicines;` |
| Search medicines | `SELECT * FROM medicines WHERE name LIKE '%Paracetamol%';` |
| Get user's medicines | `SELECT * FROM medicines WHERE user_id='user@example.com';` |
| Exit MySQL | `EXIT;` |

---

## 🎯 Recommended Tool

**For Beginners:** MySQL Workbench (most user-friendly)  
**For Developers:** DBeaver (most powerful features)  
**For Quick View:** Command line (fastest, no install)  

---

## 🔒 Important Notes

- ✅ All user data is isolated (no mixing)
- ✅ Each user only sees their medicines, reminders, caretakers
- ✅ Password stored as hash (secured)
- ✅ Timestamps in UTC format
- ✅ JSON data in `days_of_week` (for reminders)

---

## 📞 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Can't connect" | Make sure MySQL server is running (Windows Services) |
| "Access denied" | Check username/password in `.env` file |
| "Database not found" | Run schema.sql to create tables |
| "Port already in use" | Change port in `.env` to 3307 or higher |
| "Table is empty" | Register a user and add medicines in the app first |

---

## 🎬 Video Alternative

If you prefer video tutorials:
- MySQL Workbench Tutorial: Search "MySQL Workbench Tutorial" on YouTube
- MySQL Command Line: Search "MySQL Command Line Tutorial" on YouTube

---

**You're ready to explore your database!** 🚀

Pick a method above and start viewing your data. Enjoy!

