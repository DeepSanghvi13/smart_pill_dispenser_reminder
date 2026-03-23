# 🚀 MySQL Database - Quick Start (30 seconds)

## 📌 Your MySQL Connection Details

```
Host:     127.0.0.1  (or localhost)
Port:     3306
User:     root
Password: (empty - just press Enter)
Database: smart_pill_reminder
```

---

## ⚡ Quickest Way: Command Line (Copy & Paste)

### Step 1: Open Command Prompt (Windows)
Press: `Win + R` → Type: `cmd` → Press `Enter`

### Step 2: Connect to MySQL
Paste this command:
```bash
mysql -h localhost -u root
```
Press `Enter`. If asked for password, just press `Enter` again.

### Step 3: View Your Database
Paste these commands one by one:

**See all databases:**
```sql
SHOW DATABASES;
```

**Select your database:**
```sql
USE smart_pill_reminder;
```

**See all tables:**
```sql
SHOW TABLES;
```

**View medicines:**
```sql
SELECT * FROM medicines;
```

**View reminders:**
```sql
SELECT * FROM reminders;
```

**View caretakers:**
```sql
SELECT * FROM caretakers;
```

**View users:**
```sql
SELECT * FROM users;
```

**Exit:**
```sql
EXIT;
```

---

## 🖥️ Visual Way: MySQL Workbench (Recommended)

1. **Download:** https://www.mysql.com/products/workbench/
2. **Install** it
3. **Open** MySQL Workbench
4. **Click "+"** next to "MySQL Connections"
5. **Fill in:**
   - Connection Name: `smart_pill_reminder`
   - Hostname: `127.0.0.1`
   - Port: `3306`
   - Username: `root`
   - Leave password empty
6. **Click "Test Connection"** → Should say "Successfully"
7. **Click "OK"**
8. **Double-click** the connection to open
9. **Done!** Now you can see all tables and data visually

---

## 📊 Your 9 Tables

1. **medicines** - Medicine information
2. **reminders** - Medication reminders
3. **caretakers** - Caretaker contacts
4. **users** - User accounts
5. **user_profiles** - User details
6. **alarm_logs** - Alarm history
7. **missed_medicine_alerts** - Missed dose alerts
8. **professional_review_requests** - Doctor reviews
9. **barcode_lookup_cache** - Cached barcode data

---

## ✅ Test Your Connection

After opening mysql, run:
```sql
SELECT COUNT(*) AS total_medicines FROM medicines;
```

Should show a number (count of medicines).

---

## 🎯 That's It!

You now have access to your MySQL database. You can:
- ✅ View all data
- ✅ Add new records
- ✅ Edit existing data
- ✅ Delete records
- ✅ Run queries

**Need visual interface?** Use MySQL Workbench (easiest!)  
**Prefer command line?** Use the commands above.

---

**Created:** March 23, 2026  
**Database:** smart_pill_reminder  
**Status:** Ready to explore! 🚀

