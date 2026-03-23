# 🎯 MySQL Database - Cheat Sheet

## 🔌 Connection Details (Copy This!)

```
Host:     127.0.0.1
Port:     3306
User:     root
Password: (empty)
Database: smart_pill_reminder
```

---

## ⚡ Instant Access (Choose One)

### Option A: Command Line (Copy & Paste)
```bash
mysql -h localhost -u root
USE smart_pill_reminder;
SHOW TABLES;
SELECT * FROM medicines;
EXIT;
```

### Option B: MySQL Workbench GUI
1. Download: https://www.mysql.com/products/workbench/
2. Host: `127.0.0.1` | User: `root` | DB: `smart_pill_reminder`
3. Click connect → Browse tables visually

### Option C: DBeaver GUI
1. Download: https://dbeaver.io/
2. Same connection details above
3. Click connect → Browse tables

---

## 📊 9 Database Tables

```
users                         → Login accounts
user_profiles                 → User info
medicines                     → Medicines list
reminders                     → Medicine reminders
caretakers                    → Caretaker contacts
alarm_logs                    → Alarm history
missed_medicine_alerts        → Missed doses
professional_review_requests  → Doctor reviews
barcode_lookup_cache          → Cached barcodes
```

---

## 💾 Essential SQL Commands

### View All Data
```sql
SELECT * FROM medicines;
SELECT * FROM reminders;
SELECT * FROM caretakers;
SELECT * FROM users;
SELECT * FROM alarm_logs;
```

### Count Records
```sql
SELECT COUNT(*) FROM medicines;
SELECT COUNT(*) FROM reminders;
SELECT COUNT(*) FROM users;
```

### Find Specific Data
```sql
-- All medicines for a user
SELECT * FROM medicines WHERE user_id = 'email@example.com';

-- Active reminders
SELECT * FROM reminders WHERE is_active = 1;

-- Caretakers for a user
SELECT * FROM caretakers WHERE user_id = 'email@example.com';

-- Today's alarms
SELECT * FROM alarm_logs WHERE DATE(scheduled_time) = CURDATE();
```

### Table Structure
```sql
DESCRIBE medicines;
DESCRIBE reminders;
DESCRIBE caretakers;
```

### Get First N Records
```sql
SELECT * FROM medicines LIMIT 10;
SELECT * FROM reminders LIMIT 5;
```

### Search by Name
```sql
SELECT * FROM medicines WHERE name LIKE '%Paracetamol%';
SELECT * FROM users WHERE email LIKE '%@example.com%';
```

---

## 🔑 Key Fields in Each Table

### users
- `id` - User ID
- `email` - Email (unique)
- `password_hash` - Hashed password
- `created_at` - Join date

### medicines
- `id` - Medicine ID
- `user_id` - Owner
- `name` - Medicine name
- `dosage` - Dosage amount
- `time` - Time to take
- `expiry_date` - Expiry date

### reminders
- `id` - Reminder ID
- `medicine_id` - Which medicine
- `time` - Reminder time
- `days_of_week` - Days schedule
- `is_active` - 1=on, 0=off

### caretakers
- `id` - Caretaker ID
- `user_id` - Owner
- `first_name` - First name
- `email` - Email
- `is_active` - 1=on, 0=off

### alarm_logs
- `id` - Log ID
- `medicine_id` - Which medicine
- `scheduled_time` - Scheduled time
- `status` - pending/taken/missed

---

## 📈 Common Queries

### Get user's complete medicine schedule
```sql
SELECT m.*, r.time, r.days_of_week
FROM medicines m
LEFT JOIN reminders r ON m.id = r.medicine_id
WHERE m.user_id = 'user@example.com'
ORDER BY r.time;
```

### Get pending alarms
```sql
SELECT * FROM alarm_logs 
WHERE status = 'pending' 
AND DATE(scheduled_time) = CURDATE()
ORDER BY scheduled_time;
```

### Get missed medicines for a user
```sql
SELECT * FROM alarm_logs 
WHERE user_id = 'user@example.com'
AND status = 'missed'
ORDER BY scheduled_time DESC;
```

### Get user's caretakers
```sql
SELECT * FROM caretakers 
WHERE user_id = 'user@example.com'
AND is_active = 1;
```

### Get professional review requests
```sql
SELECT * FROM professional_review_requests
WHERE status = 'pending'
ORDER BY created_at DESC;
```

---

## 🛠️ Data Modification

### Add New User (Don't use - use app instead!)
```sql
INSERT INTO users (email, password_hash, created_at) 
VALUES ('new@example.com', 'hash_here', NOW());
```

### Update Medicine
```sql
UPDATE medicines 
SET name = 'New Name', dosage = '500mg'
WHERE id = 1;
```

### Delete Medicine
```sql
DELETE FROM medicines WHERE id = 1;
```

### Deactivate Reminder
```sql
UPDATE reminders SET is_active = 0 WHERE id = 1;
```

### Deactivate Caretaker
```sql
UPDATE caretakers SET is_active = 0 WHERE id = 1;
```

---

## ⚠️ Important Notes

- ✅ All changes save automatically
- ✅ Data is per-user (isolated)
- ✅ Timestamps in UTC
- ✅ Passwords are hashed (can't be viewed)
- ✅ No data sharing between users
- 🔒 Always backup before bulk changes

---

## 📞 Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| "Can't connect" | Check MySQL server running (Start > Services) |
| "Access denied" | Password wrong, try: `mysql -h localhost -u root` |
| "No tables" | Run schema.sql file first |
| "Empty table" | Register user in app and add data |
| "Command not found" | Add MySQL to system PATH |

---

## 🚀 Quick Reference

```
┌─── MYSQL ACCESS ───┐
│ Command Line:      │
│ mysql -h localhost │
│ -u root            │
└────────────────────┘

┌─── SELECT DATA ────┐
│ SELECT * FROM X;   │
│ SHOW TABLES;       │
│ DESC table_name;   │
└────────────────────┘

┌─── EXIT ───────────┐
│ EXIT;              │
│ or Ctrl+C          │
└────────────────────┘
```

---

## 📚 Related Documents

- `MYSQL_STEP_BY_STEP.md` - Detailed walkthrough
- `MYSQL_DATABASE_GUIDE.md` - Complete reference
- `DATABASE_SCHEMA.md` - Structure diagram

---

**Print this sheet or bookmark it!** 📌

Last updated: March 23, 2026

