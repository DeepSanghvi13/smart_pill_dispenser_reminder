# 🚀 Smart Pill Dispenser Reminder - Quick Start Guide

## ✅ Features Status

All features are **fully working and tested**:

| Feature | Status | Access |
|---------|--------|--------|
| 📱 User-Scoped Home | ✅ Working | Auto-opens per login |
| 💊 Medicine Management | ✅ Working | Home → Medications tab |
| ⏰ Reminders (Add/Edit/Delete) | ✅ Working | Manage → Manage Reminders |
| 👥 Caretaker Mode | ✅ Working | Drawer → Caretaker Mode |
| 👫 Invite Medfriend | ✅ Working | Drawer → Invite Medfriend |
| 📷 Barcode Scanner | ✅ Working | Add Medicine → Scan barcode |
| 🏥 Doctor/Hospital Review | ✅ Working | Manage → Doctor/Hospital Review |
| 🔊 Voice Reminders (TTS) | ✅ Working | When alarm triggers |
| 📅 Medicine Expiry Calendar | ✅ Working | Medications → Calendar icon |

---

## 🔑 Key Features

### 1️⃣ **Register & Login**
```
1. Open app → "New user? Create an account"
2. Enter email and password (min 6 chars)
3. Confirm password and click "Register"
4. Auto-redirect to login with email pre-filled
5. Click "Log In" → Your home opens
```

### 2️⃣ **Each User Has Their Own Data**
- Your medicines are **only yours**
- Your reminders are **only yours**
- Your caretakers are **only yours**
- Switching accounts = switching data (no mixing)

---

## 💊 Medicine Management

### Add a Medicine
```
Home Screen → Medications tab → Click + Button
OR
Home Screen → Click + FAB (Floating Action Button)

Fill in:
- Medicine Name
- Dosage
- Time
- Health Condition (optional)
- Category (tablets, syrup, injection, etc.)
- Expiry Date (optional)

Options:
🔍 Scan medicine label (image) → extracts name & dosage
📱 Scan barcode → looks up in online drug database
```

### Edit Medicine
- Medications tab → Click medicine → Edit

### Delete Medicine
- Medications tab → Click medicine → Delete

---

## ⏰ Reminders

### Add a Reminder
```
Drawer → "Manage" → "Manage Reminders" → Click + Button

Fill in:
- Medicine (dropdown)
- Time (hours:minutes)
- Days (Mon, Tue, Wed, etc.)
- Active (toggle on/off)
```

### Edit Reminder
- Manage Reminders → Click medicine → Edit icon

### Delete Reminder
- Manage Reminders → Click medicine → Delete icon

### Toggle Reminder On/Off
- Manage Reminders → Click switch next to reminder

---

## 👥 Caretaker Mode

### What is a Caretaker?
A caretaker is someone (family, friend, nurse) who gets notified if you miss a medicine dose. They can:
- Get SMS alerts
- Get Email alerts
- Get App notifications

### Add Caretaker
```
Drawer → "Caretaker Mode" → Click + Button

Fill in:
- First Name
- Last Name
- Phone Number
- Email
- Relationship (Son, Daughter, Nurse, etc.)
- Notification preferences (SMS, Email, App)

Save → Caretaker added!
```

### Edit Caretaker
- Caretaker Mode → Medicine name → Click menu → Edit

### Activate/Deactivate Caretaker
- Caretaker Mode → Medicine name → Click menu → Activate/Deactivate

### Delete Caretaker
- Caretaker Mode → Medicine name → Click menu → Delete

---

## 👫 Invite Medfriend

### What is a Medfriend?
A Medfriend is someone you invite to help you remember to take your medicines. They receive your invitation via SMS or Email.

### How to Invite
```
Drawer → "Invite Medfriend"

Fill in:
- Friend's Name
- Phone Number (for SMS)
- Email (for Email)
- Toggle: "Share my meds with this Medfriend" (optional)

Click "SEND"
→ SMS sent to phone
→ Email sent to email
→ Confirmation message
→ Auto-close
```

**Example Invite Message:**
> "Hi John, I'm using Smart Pill Dispenser Reminder app to manage my medications. I'd like you to be my Medfriend and get notifications if I miss my medicines. Please download the app and I'll add you as my Medfriend."

---

## 🎤 Voice Reminders

When an alarm triggers at reminder time:
- App speaks the medicine name and dosage
- Audio plays: "Medication reminder. Please take [Medicine], dosage [Dosage] now."
- Can be customized in app settings

---

## 📱 Barcode Scanner

### Scan Medicine Package
```
Add Medicine → Click "Scan barcode" button
→ Camera opens
→ Point at barcode on medicine package
→ Auto-detects and looks up medicine in database
→ Fills in medicine name and dosage
```

**Lookup Sources (in order):**
1. Backend API proxy (fastest)
2. Direct OpenFDA online database
3. Local app cache
4. Local fallback list

---

## 📅 Expiry Notifications

### Set Expiry Date
- Add/Edit Medicine → Click "Expiry Date" field
- Select date from calendar
- Save

### View Expiry Calendar
- Home → Medications tab → Click calendar icon
- See all medicines with expiry dates
- Get notified before expiry

---

## 🏥 Doctor/Hospital Review

### Request Professional Review
```
Drawer → "Manage" → "Doctor/Hospital Review"

Fill in:
- Patient Name
- Contact (phone/email)
- Urgency (Normal, High, Critical)
- Preferred Doctor/Hospital (optional)
- Concern Details

Click "Submit for professional review"
→ Submitted to backend
→ Can be reviewed by hospital admin
```

---

## 🔐 Logout & Switch Accounts

### Logout
```
Drawer → Click "Logout"
→ All data cleared from session
→ Back to login screen
```

### Switch Accounts
```
1. Logout
2. Login with different email
3. Your home opens with ONLY your data
4. Your medicines, reminders, caretakers load
```

---

## ⚙️ Settings & Admin

### Admin Dashboard
```
Email: admin@medisafe.com
Password: admin123

→ Opens admin dashboard with:
- All users' data
- All medicines
- All reminders
- Professional review requests
```

### Regular User Account
```
Any email: example@example.com
Password: (your password, min 6 chars)

→ Opens your user home with only your data
```

---

## 📞 Troubleshooting

| Issue | Solution |
|-------|----------|
| Medicines not showing | Make sure you're logged in as same user who added them |
| Reminders not triggering | Check that reminder is Active (toggle on) |
| Barcode scan fails | Manual enter medicine name, or use fallback list |
| Caretaker not notified | Make sure caretaker is Active, and notification pref checked |
| Invite not sent | Check phone format (10+ digits) or email format |

---

## 🎯 Next Steps

1. **Register** your account
2. **Add medicines** you take regularly
3. **Create reminders** for each medicine
4. **Add caretakers** who should be notified
5. **Invite medfriends** to help you remember
6. **Set expiry dates** to get notifications
7. **Test alarm** to hear voice reminder

---

## 📝 Notes

- All data is **automatically synced to MySQL** (if backend available)
- Offline mode supported (syncs when online)
- Web and mobile supported (SQLite on mobile, Hive on web)
- No data sharing between different user accounts
- Admin can view all users' data for management

---

**Happy reminder taking! 💊**

