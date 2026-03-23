# 📐 MySQL Database Schema Diagram

## Database: `smart_pill_reminder`

```
smart_pill_reminder
├── users
│   ├── id (PK)
│   ├── email (UNIQUE)
│   ├── password_hash
│   ├── created_at
│   └── updated_at
│
├── user_profiles
│   ├── id (PK)
│   ├── user_id (FK → users.id)
│   ├── first_name
│   ├── last_name
│   ├── gender
│   ├── birth_date
│   ├── zip_code
│   ├── phone_number
│   ├── email
│   ├── created_at
│   └── updated_at
│
├── medicines
│   ├── id (PK)
│   ├── user_id (FK)
│   ├── local_id
│   ├── name
│   ├── dosage
│   ├── time
│   ├── category (tablets, syrup, injection)
│   ├── expiry_date
│   ├── is_scanned
│   ├── scanned_text
│   ├── image_path
│   ├── health_condition
│   └── created_at
│
├── reminders
│   ├── id (PK)
│   ├── user_id (FK)
│   ├── local_id
│   ├── medicine_id (FK → medicines.id)
│   ├── medicine_name
│   ├── time
│   ├── days_of_week (JSON)
│   ├── is_active
│   ├── last_notified_at
│   └── created_at
│
├── caretakers
│   ├── id (PK)
│   ├── user_id (FK)
│   ├── local_id
│   ├── first_name
│   ├── last_name
│   ├── phone_number
│   ├── email
│   ├── relationship
│   ├── notify_via_sms
│   ├── notify_via_email
│   ├── notify_via_notification
│   ├── is_active
│   └── created_at
│
├── alarm_logs
│   ├── id (PK)
│   ├── user_id (FK)
│   ├── local_id
│   ├── medicine_id (FK → medicines.id)
│   ├── medicine_name
│   ├── scheduled_time
│   ├── triggered_time
│   ├── status (pending, taken, missed)
│   ├── snooze_count
│   ├── taken_at
│   └── notes
│
├── missed_medicine_alerts
│   ├── id (PK)
│   ├── medicine_id (FK → medicines.id)
│   ├── medicine_name
│   ├── scheduled_time
│   ├── detected_time
│   ├── notification_sent
│   ├── caretakers_notified
│   ├── status
│   └── notes
│
├── professional_review_requests
│   ├── id (PK)
│   ├── user_id (FK)
│   ├── patient_name
│   ├── contact
│   ├── concern
│   ├── preferred_hospital
│   ├── urgency (normal, high, critical)
│   ├── status (pending, reviewed, resolved)
│   └── created_at
│
└── barcode_lookup_cache
    ├── barcode (PK)
    ├── name
    ├── dosage
    ├── category
    └── cached_at
```

---

## 🔗 Relationships

```
users (1) ─────────── (many) user_profiles
  │
  ├──────────── (many) medicines
  │                       │
  │                       └──────── (many) reminders
  │                       └──────── (many) alarm_logs
  │
  ├──────────── (many) caretakers
  │
  ├──────────── (many) professional_review_requests
  │
  └──────────── (many) medicines → missed_medicine_alerts

medicines ─────────── (many) reminders
medicines ─────────── (many) alarm_logs
medicines ─────────── (many) missed_medicine_alerts

barcode_lookup_cache ─── (cached) medicines
```

---

## 📊 Data Flow

```
User Registration/Login
        ↓
   users table
        ↓
   user_profiles (optional)
        ↓
Add Medicine ──→ medicines table
        ↓
Create Reminder ──→ reminders table
        ↓
Reminder Time ──→ Trigger Alarm ──→ alarm_logs table
        ↓
Add Caretaker ──→ caretakers table
        ↓
Missed Medicine ──→ missed_medicine_alerts table
        ↓
Notify Caretaker (SMS/Email/App)
        ↓
Professional Review ──→ professional_review_requests table

Scan Barcode ──→ barcode_lookup_cache table
        ↓
↑ (cached on next scan)
```

---

## 💾 Database Size Estimation

| Table | Typical Rows | Purpose |
|-------|--------------|---------|
| users | 10-100 | User accounts |
| user_profiles | 10-100 | User details |
| medicines | 100-500 | Medicines per user |
| reminders | 200-1000 | Reminders per user |
| caretakers | 50-200 | Caretakers per user |
| alarm_logs | 1000-10000 | Historical logs |
| missed_medicine_alerts | 100-1000 | Missed doses |
| professional_review_requests | 10-50 | Doctor reviews |
| barcode_lookup_cache | 100-500 | Cached barcodes |

---

## 🔑 Key Columns

### Primary Keys (Unique Identifiers)
```
users.id
user_profiles.id
medicines.id
reminders.id
caretakers.id
alarm_logs.id
missed_medicine_alerts.id
professional_review_requests.id
barcode_lookup_cache.barcode
```

### Foreign Keys (Relationships)
```
user_profiles.user_id → users.id
medicines.user_id → users.id
reminders.user_id → users.id
caretakers.user_id → users.id
alarm_logs.user_id → users.id
professional_review_requests.user_id → users.id
```

---

## 🎯 Query Examples

### Get All Medicines for a User
```sql
SELECT * FROM medicines 
WHERE user_id = 'user@example.com';
```

### Get Active Reminders
```sql
SELECT r.*, m.name AS medicine_name
FROM reminders r
JOIN medicines m ON r.medicine_id = m.id
WHERE r.is_active = 1
ORDER BY r.time ASC;
```

### Get User's Caretakers
```sql
SELECT * FROM caretakers 
WHERE user_id = 'user@example.com' 
AND is_active = 1;
```

### Get Missed Medicines Today
```sql
SELECT * FROM alarm_logs 
WHERE DATE(scheduled_time) = CURDATE()
AND status = 'missed';
```

### Get Recent Professional Review Requests
```sql
SELECT * FROM professional_review_requests 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 📈 Performance Tips

1. **Indexes on user_id** - All tables filtered by user
2. **Compound indexes** - (user_id, created_at)
3. **Date indexes** - For alarm_logs time queries
4. **Email unique index** - On users.email

---

## 🔐 Data Isolation

Each user's data is isolated by `user_id`:
```
User A (user@a.com)
├── medicines (only theirs)
├── reminders (only theirs)
├── caretakers (only theirs)
└── alarm_logs (only theirs)

User B (user@b.com)
├── medicines (only theirs)
├── reminders (only theirs)
├── caretakers (only theirs)
└── alarm_logs (only theirs)
```

No data leakage between users!

---

**Database Version:** 1.0  
**MySQL:** 5.7+  
**Encoding:** UTF-8  
**Status:** ✅ Production Ready

