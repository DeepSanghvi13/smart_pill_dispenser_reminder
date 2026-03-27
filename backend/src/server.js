require('dotenv').config();

const express = require('express');
const cors = require('cors');
const https = require('https');
<<<<<<< HEAD
const {
  connectMongo,
  ping,
  disconnectMongo,
  generateNextLocalId,
  models,
} = require('./db');

const {
  User,
  AuthLog,
  Medicine,
  Reminder,
  AlarmLog,
  Caretaker,
  Dependent,
  Setting,
  UserProfile,
  ProfessionalReviewRequest,
} = models;
=======
const { pool, query, ping } = require('./db');
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26

const app = express();
app.use(cors());
app.use(express.json({ limit: '4mb' }));

const port = Number(process.env.PORT || 3000);
<<<<<<< HEAD
const adminEmail = (process.env.ADMIN_EMAIL || 'admin@medisafe.com')
  .trim()
  .toLowerCase();
const adminPassword = (process.env.ADMIN_PASSWORD || 'admin123').trim();

function parseDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function parseDays(value) {
  if (Array.isArray(value)) return value.map((d) => String(d));
  if (typeof value === 'string' && value.trim().length > 0) {
    return value
      .split(',')
      .map((v) => v.trim())
      .filter(Boolean);
=======
const adminEmail = (process.env.ADMIN_EMAIL || 'admin@medisafe.com').trim().toLowerCase();
const adminPassword = (process.env.ADMIN_PASSWORD || 'admin123').trim();

function boolToInt(value) {
  return value ? 1 : 0;
}

function parseDays(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.split(',').map((v) => v.trim()).filter(Boolean);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
  return [];
}

<<<<<<< HEAD
=======
function toSqlDate(value) {
  const date = value ? new Date(value) : new Date();
  if (Number.isNaN(date.getTime())) {
    const fallback = new Date();
    return fallback.toISOString().slice(0, 19).replace('T', ' ');
  }
  return date.toISOString().slice(0, 19).replace('T', ' ');
}

function decodeDaysJson(value) {
  if (Array.isArray(value)) return value;
  if (typeof value !== 'string') return [];
  try {
    const parsed = JSON.parse(value);
    return parseDays(parsed);
  } catch (_) {
    return parseDays(value);
  }
}

>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
function digitsOnly(value) {
  return String(value || '').replace(/[^0-9]/g, '');
}

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || null;
}

<<<<<<< HEAD
function asUserId(value) {
  const normalized = String(value || '').trim();
  return normalized || 'guest';
}

async function logAuthEvent({
  email,
  eventType,
  status,
  source = 'mobile',
  ipAddress = null,
}) {
  await AuthLog.create({
    email: normalizeEmail(email),
    eventType,
    status,
    source,
    ipAddress,
    createdAt: new Date(),
  });
}

async function ensureDefaultAdmin() {
  await User.findOneAndUpdate(
    { email: adminEmail },
    {
      email: adminEmail,
      passwordHash: adminPassword,
      isAdmin: true,
      updatedAt: new Date(),
      $setOnInsert: { createdAt: new Date() },
    },
    { upsert: true },
=======
async function logAuthEvent({ email, eventType, status, source = 'mobile', ipAddress = null }) {
  await query(
    `INSERT INTO auth_logs (email, event_type, status, source, ip_address, created_at)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [normalizeEmail(email), eventType, status, source, ipAddress, toSqlDate(new Date())],
  );
}

async function ensureDefaultAdmin() {
  await query(
    `INSERT INTO users (email, password_hash, is_admin, created_at, updated_at)
     VALUES (?, ?, 1, ?, ?)
     ON DUPLICATE KEY UPDATE
       password_hash = VALUES(password_hash),
       is_admin = 1,
       updated_at = VALUES(updated_at)`,
    [adminEmail, adminPassword, toSqlDate(new Date()), toSqlDate(new Date())],
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  );
}

function toNdcCandidates(digits) {
  const ndc = new Set();

  if (digits.length === 11) {
    ndc.add(`${digits.slice(0, 5)}-${digits.slice(5, 9)}-${digits.slice(9, 11)}`);
  }

  if (digits.length >= 10) {
    const tail10 = digits.slice(-10);
    ndc.add(`${tail10.slice(0, 4)}-${tail10.slice(4, 8)}-${tail10.slice(8, 10)}`);
    ndc.add(`${tail10.slice(0, 5)}-${tail10.slice(5, 8)}-${tail10.slice(8, 10)}`);
    ndc.add(`${tail10.slice(0, 5)}-${tail10.slice(5, 9)}-${tail10.slice(9, 10)}`);
  }

  return [...ndc];
}

function getJson(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (response) => {
        let body = '';
        response.setEncoding('utf8');
        response.on('data', (chunk) => {
          body += chunk;
        });
        response.on('end', () => {
          if (response.statusCode < 200 || response.statusCode >= 300) {
            resolve(null);
            return;
          }
          try {
            resolve(JSON.parse(body));
          } catch (_) {
            resolve(null);
          }
        });
      })
      .on('error', reject);
  });
}

async function lookupDrugByBarcode(barcodeDigits) {
  const baseUrl = process.env.OPENFDA_BASE_URL || 'https://api.fda.gov';
  const apiKey = process.env.OPENFDA_API_KEY || '';

  for (const ndc of toNdcCandidates(barcodeDigits)) {
    const queryText = `product_ndc:"${ndc}"+OR+package_ndc:"${ndc}"`;
    const params = new URLSearchParams({ search: queryText, limit: '1' });
<<<<<<< HEAD
    if (apiKey) params.set('api_key', apiKey);

    const body = await getJson(`${baseUrl}/drug/ndc.json?${params.toString()}`);
    const first = Array.isArray(body?.results) ? body.results[0] : null;
    if (!first || typeof first !== 'object') continue;

    const name = (
      first.brand_name ||
      first.generic_name ||
      first.labeler_name ||
      'Unknown medicine'
    ).trim();
    const ingredient = Array.isArray(first.active_ingredients)
      ? first.active_ingredients[0]
      : null;
=======
    if (apiKey) {
      params.set('api_key', apiKey);
    }

    const body = await getJson(`${baseUrl}/drug/ndc.json?${params.toString()}`);
    const first = Array.isArray(body?.results) ? body.results[0] : null;
    if (!first || typeof first !== 'object') {
      continue;
    }

    const name = (first.brand_name || first.generic_name || first.labeler_name || 'Unknown medicine').trim();
    const ingredient = Array.isArray(first.active_ingredients) ? first.active_ingredients[0] : null;
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    const dosage = (ingredient?.strength || 'N/A').toString().trim() || 'N/A';
    const dosageForm = String(first.dosage_form || '').toLowerCase();
    const category = dosageForm.includes('inject')
      ? 'injection'
<<<<<<< HEAD
      : dosageForm.includes('solution') ||
          dosageForm.includes('syrup') ||
          dosageForm.includes('liquid')
=======
      : (dosageForm.includes('solution') || dosageForm.includes('syrup') || dosageForm.includes('liquid'))
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
        ? 'syrup'
        : 'tablets';

    return {
      barcode: barcodeDigits,
      name,
      dosage,
      category,
      source: 'onlineApi',
    };
  }

  return null;
}

<<<<<<< HEAD
async function resolveLocalId(Model, userId, idCandidate) {
  if (Number.isInteger(Number(idCandidate))) {
    return Number(idCandidate);
  }
  return generateNextLocalId(Model, userId);
}

function medicineToDto(doc) {
  return {
    id: doc.localId,
    name: doc.name,
    dosage: doc.dosage,
    time: doc.time,
    category: doc.category,
    expiryDate: doc.expiryDate,
    isScanned: doc.isScanned,
    scannedText: doc.scannedText,
    imagePath: doc.imagePath,
    healthCondition: doc.healthCondition,
    createdAt: doc.createdAt,
  };
}

function reminderToDto(doc) {
  return {
    id: doc.localId,
    medicineId: doc.medicineId,
    medicineName: doc.medicineName,
    time: doc.time,
    daysOfWeek: doc.daysOfWeek || [],
    isActive: !!doc.isActive,
    lastNotifiedAt: doc.lastNotifiedAt,
    createdAt: doc.createdAt,
  };
}

function alarmLogToDto(doc) {
  return {
    id: doc.localId,
    medicineId: doc.medicineId,
    medicineName: doc.medicineName,
    scheduledTime: doc.scheduledTime,
    triggeredTime: doc.triggeredTime,
    status: doc.status,
    snoozeCount: doc.snoozeCount || 0,
    takenAt: doc.takenAt,
    notes: doc.notes,
  };
}

function caretakerToDto(doc) {
  return {
    id: doc.localId,
    firstName: doc.firstName,
    lastName: doc.lastName,
    phoneNumber: doc.phoneNumber,
    email: doc.email,
    relationship: doc.relationship,
    notifyViaSMS: !!doc.notifyViaSMS,
    notifyViaEmail: !!doc.notifyViaEmail,
    notifyViaNotification: !!doc.notifyViaNotification,
    isActive: !!doc.isActive,
    createdAt: doc.createdAt,
  };
}

function dependentToDto(doc) {
  return {
    id: doc.localId,
    firstName: doc.firstName,
    lastName: doc.lastName,
    gender: doc.gender,
    birthDate: doc.birthDate,
    color: doc.color,
    createdAt: doc.createdAt,
  };
}

async function upsertMedicine(userId, medicine) {
  const localId = await resolveLocalId(Medicine, userId, medicine.id);
  await Medicine.findOneAndUpdate(
    { userId, localId },
    {
      userId,
      localId,
      name: medicine.name || '',
      dosage: medicine.dosage || '',
      time: medicine.time || '',
      category: medicine.category || 'tablets',
      expiryDate: parseDate(medicine.expiryDate),
      isScanned: medicine.isScanned === true,
      scannedText: medicine.scannedText || null,
      imagePath: medicine.imagePath || null,
      healthCondition: medicine.healthCondition || null,
      createdAt: parseDate(medicine.createdAt) || new Date(),
    },
    { upsert: true },
  );
  return localId;
}

async function upsertReminder(userId, reminder) {
  const localId = await resolveLocalId(Reminder, userId, reminder.id);
  await Reminder.findOneAndUpdate(
    { userId, localId },
    {
      userId,
      localId,
      medicineId: Number(reminder.medicineId || 0),
      medicineName: reminder.medicineName || '',
      time: reminder.time || '',
      daysOfWeek: parseDays(reminder.daysOfWeek),
      isActive: reminder.isActive !== false,
      lastNotifiedAt: parseDate(reminder.lastNotifiedAt),
      createdAt: parseDate(reminder.createdAt) || new Date(),
    },
    { upsert: true },
  );
  return localId;
}

async function upsertAlarmLog(userId, alarmLog) {
  const localId = await resolveLocalId(AlarmLog, userId, alarmLog.id);
  await AlarmLog.findOneAndUpdate(
    { userId, localId },
    {
      userId,
      localId,
      medicineId: Number(alarmLog.medicineId || 0),
      medicineName: alarmLog.medicineName || '',
      scheduledTime: parseDate(alarmLog.scheduledTime) || new Date(),
      triggeredTime: parseDate(alarmLog.triggeredTime),
      status: alarmLog.status || 'pending',
      snoozeCount: Number(alarmLog.snoozeCount || 0),
      takenAt: parseDate(alarmLog.takenAt),
      notes: alarmLog.notes || null,
      createdAt: parseDate(alarmLog.createdAt) || new Date(),
    },
    { upsert: true },
  );
  return localId;
}

async function upsertCaretaker(userId, caretaker) {
  const localId = await resolveLocalId(Caretaker, userId, caretaker.id);
  await Caretaker.findOneAndUpdate(
    { userId, localId },
    {
      userId,
      localId,
      firstName: caretaker.firstName || '',
      lastName: caretaker.lastName || '',
      phoneNumber: caretaker.phoneNumber || '',
      email: caretaker.email || '',
      relationship: caretaker.relationship || '',
      notifyViaSMS: caretaker.notifyViaSMS !== false,
      notifyViaEmail: caretaker.notifyViaEmail !== false,
      notifyViaNotification: caretaker.notifyViaNotification !== false,
      isActive: caretaker.isActive !== false,
      createdAt: parseDate(caretaker.createdAt) || new Date(),
    },
    { upsert: true },
  );
  return localId;
}

async function upsertDependent(userId, dependent) {
  const localId = await resolveLocalId(Dependent, userId, dependent.id);
  await Dependent.findOneAndUpdate(
    { userId, localId },
    {
      userId,
      localId,
      firstName: dependent.firstName || '',
      lastName: dependent.lastName || '',
      gender: dependent.gender || null,
      birthDate: dependent.birthDate || null,
      color: dependent.color || null,
      createdAt: parseDate(dependent.createdAt) || new Date(),
    },
    { upsert: true },
  );
  return localId;
}

async function upsertUserProfile(userId, profile) {
  if (!profile) return;
  await UserProfile.findOneAndUpdate(
    { userId },
    {
      userId,
      firstName: profile.firstName || '',
      lastName: profile.lastName || '',
      gender: profile.gender || null,
      birthDate: profile.birthDate || null,
      zipCode: profile.zipCode || null,
      phoneNumber: profile.phoneNumber || null,
      email: profile.email || null,
      updatedAt: new Date(),
      $setOnInsert: { createdAt: new Date() },
    },
    { upsert: true },
=======
async function upsertMedicine(connection, userId, medicine) {
  await connection.execute(
    `INSERT INTO medicines (
      user_id, local_id, name, dosage, time, category, expiry_date,
      is_scanned, scanned_text, image_path, health_condition, created_at
    )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       name = VALUES(name),
       dosage = VALUES(dosage),
       time = VALUES(time),
       category = VALUES(category),
       expiry_date = VALUES(expiry_date),
       is_scanned = VALUES(is_scanned),
       scanned_text = VALUES(scanned_text),
       image_path = VALUES(image_path),
       health_condition = VALUES(health_condition),
       created_at = VALUES(created_at)`,
    [
      userId,
      medicine.id ?? null,
      medicine.name ?? '',
      medicine.dosage ?? '',
      medicine.time ?? '',
      medicine.category ?? 'tablets',
      medicine.expiryDate ? toSqlDate(medicine.expiryDate) : null,
      boolToInt(medicine.isScanned),
      medicine.scannedText ?? null,
      medicine.imagePath ?? null,
      medicine.healthCondition ?? null,
      toSqlDate(medicine.createdAt),
    ],
  );
}

async function upsertReminder(connection, userId, reminder) {
  await connection.execute(
    `INSERT INTO reminders (
      user_id, local_id, medicine_id, medicine_name, time, days_of_week,
      is_active, last_notified_at, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      medicine_id = VALUES(medicine_id),
      medicine_name = VALUES(medicine_name),
      time = VALUES(time),
      days_of_week = VALUES(days_of_week),
      is_active = VALUES(is_active),
      last_notified_at = VALUES(last_notified_at),
      created_at = VALUES(created_at)`,
    [
      userId,
      reminder.id ?? null,
      reminder.medicineId ?? 0,
      reminder.medicineName ?? '',
      reminder.time ?? '',
      JSON.stringify(parseDays(reminder.daysOfWeek)),
      boolToInt(reminder.isActive),
      reminder.lastNotifiedAt ? toSqlDate(reminder.lastNotifiedAt) : null,
      toSqlDate(reminder.createdAt),
    ],
  );
}

async function upsertAlarmLog(connection, userId, alarmLog) {
  await connection.execute(
    `INSERT INTO alarm_logs (
      user_id, local_id, medicine_id, medicine_name, scheduled_time,
      triggered_time, status, snooze_count, taken_at, notes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      medicine_id = VALUES(medicine_id),
      medicine_name = VALUES(medicine_name),
      scheduled_time = VALUES(scheduled_time),
      triggered_time = VALUES(triggered_time),
      status = VALUES(status),
      snooze_count = VALUES(snooze_count),
      taken_at = VALUES(taken_at),
      notes = VALUES(notes)`,
    [
      userId,
      alarmLog.id ?? null,
      alarmLog.medicineId ?? 0,
      alarmLog.medicineName ?? '',
      toSqlDate(alarmLog.scheduledTime),
      alarmLog.triggeredTime ? toSqlDate(alarmLog.triggeredTime) : null,
      alarmLog.status ?? 'pending',
      Number(alarmLog.snoozeCount ?? 0),
      alarmLog.takenAt ? toSqlDate(alarmLog.takenAt) : null,
      alarmLog.notes ?? null,
    ],
  );
}

async function upsertCaretaker(connection, userId, caretaker) {
  await connection.execute(
    `INSERT INTO caretakers (
      user_id, local_id, first_name, last_name, phone_number, email,
      relationship, notify_via_sms, notify_via_email, notify_via_notification,
      is_active, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      first_name = VALUES(first_name),
      last_name = VALUES(last_name),
      phone_number = VALUES(phone_number),
      email = VALUES(email),
      relationship = VALUES(relationship),
      notify_via_sms = VALUES(notify_via_sms),
      notify_via_email = VALUES(notify_via_email),
      notify_via_notification = VALUES(notify_via_notification),
      is_active = VALUES(is_active),
      created_at = VALUES(created_at)`,
    [
      userId,
      caretaker.id ?? null,
      caretaker.firstName ?? '',
      caretaker.lastName ?? '',
      caretaker.phoneNumber ?? '',
      caretaker.email ?? '',
      caretaker.relationship ?? '',
      boolToInt(caretaker.notifyViaSMS),
      boolToInt(caretaker.notifyViaEmail),
      boolToInt(caretaker.notifyViaNotification),
      boolToInt(caretaker.isActive ?? true),
      toSqlDate(caretaker.createdAt),
    ],
  );
}

async function upsertUserProfile(connection, userId, profile) {
  if (!profile) return;

  await connection.execute(
    `INSERT INTO user_profiles (
      user_id, first_name, last_name, gender, birth_date, zip_code,
      phone_number, email, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      first_name = VALUES(first_name),
      last_name = VALUES(last_name),
      gender = VALUES(gender),
      birth_date = VALUES(birth_date),
      zip_code = VALUES(zip_code),
      phone_number = VALUES(phone_number),
      email = VALUES(email),
      updated_at = VALUES(updated_at)`,
    [
      userId,
      profile.firstName ?? '',
      profile.lastName ?? '',
      profile.gender ?? null,
      profile.birthDate ?? null,
      profile.zipCode ?? null,
      profile.phoneNumber ?? null,
      profile.email ?? null,
      toSqlDate(profile.createdAt),
      toSqlDate(new Date()),
    ],
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  );
}

app.get('/api/health', async (_, res) => {
  try {
<<<<<<< HEAD
    await ping();
    res.json({ ok: true, message: 'API and MongoDB are connected' });
  } catch (error) {
    res
      .status(500)
      .json({ ok: false, message: 'MongoDB connection failed', error: error.message });
=======
    await query('SELECT 1');
    res.json({ ok: true, message: 'API and MySQL are connected' });
  } catch (error) {
    res.status(500).json({ ok: false, message: 'MySQL connection failed', error: error.message });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
});

app.post('/api/auth/register', async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || '').trim();
  const ipAddress = getClientIp(req);

  if (!email || !password || password.length < 6) {
<<<<<<< HEAD
    return res
      .status(400)
      .json({ ok: false, message: 'Valid email and password are required' });
  }

  if (email === adminEmail) {
    return res
      .status(400)
      .json({ ok: false, message: 'Admin account cannot be registered from app' });
  }

  try {
    const existing = await User.findOne({ email }).select({ _id: 1 }).lean();
    if (existing) {
=======
    return res.status(400).json({ ok: false, message: 'Valid email and password are required' });
  }

  if (email === adminEmail) {
    return res.status(400).json({ ok: false, message: 'Admin account cannot be registered from app' });
  }

  try {
    const existing = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    if (existing.length > 0) {
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      await logAuthEvent({
        email,
        eventType: 'register',
        status: 'duplicate',
        ipAddress,
      });
      return res.status(409).json({ ok: false, message: 'Email already registered' });
    }

<<<<<<< HEAD
    await User.create({
      email,
      passwordHash: password,
      isAdmin: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
=======
    const now = toSqlDate(new Date());
    await query(
      `INSERT INTO users (email, password_hash, is_admin, created_at, updated_at)
       VALUES (?, ?, 0, ?, ?)`,
      [email, password, now, now],
    );
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26

    await logAuthEvent({
      email,
      eventType: 'register',
      status: 'success',
      ipAddress,
    });

    return res.status(200).json({ ok: true, message: 'Registration successful' });
  } catch (error) {
<<<<<<< HEAD
    return res
      .status(500)
      .json({ ok: false, message: 'Registration failed', error: error.message });
=======
    return res.status(500).json({ ok: false, message: 'Registration failed', error: error.message });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
});

app.post('/api/auth/login', async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || '').trim();
  const ipAddress = getClientIp(req);

  if (!email || !password) {
    return res.status(400).json({ ok: false, message: 'Email and password are required' });
  }

  try {
<<<<<<< HEAD
    const user = await User.findOne({ email }).lean();
    if (!user || String(user.passwordHash) !== password) {
=======
    const rows = await query(
      'SELECT id, email, password_hash AS passwordHash, is_admin AS isAdmin FROM users WHERE email = ? LIMIT 1',
      [email],
    );

    if (!rows.length || String(rows[0].passwordHash) !== password) {
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      await logAuthEvent({
        email,
        eventType: 'login',
        status: 'failed',
        ipAddress,
      });
      return res.status(401).json({ ok: false, message: 'Invalid credentials' });
    }

    await logAuthEvent({
      email,
      eventType: 'login',
      status: 'success',
      ipAddress,
    });

    return res.status(200).json({
      ok: true,
      data: {
<<<<<<< HEAD
        id: Number(String(user._id).slice(-6), 16) || 0,
        email: user.email,
        isAdmin: user.isAdmin === true,
=======
        id: rows[0].id,
        email: rows[0].email,
        isAdmin: rows[0].isAdmin === 1,
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      },
    });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Login failed', error: error.message });
  }
});

app.get('/api/auth/exists', async (req, res) => {
  const email = normalizeEmail(req.query.email);
  if (!email) {
    return res.status(400).json({ ok: false, message: 'email query param is required' });
  }

  try {
<<<<<<< HEAD
    const existing = await User.findOne({ email }).select({ _id: 1 }).lean();
    return res.status(200).json({ ok: true, exists: !!existing });
=======
    const rows = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    return res.status(200).json({ ok: true, exists: rows.length > 0 });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Lookup failed', error: error.message });
  }
});

app.get('/api/auth/stats', async (_, res) => {
  try {
<<<<<<< HEAD
    const totalUsers = await User.countDocuments();
    return res.status(200).json({ ok: true, totalUsers: Number(totalUsers || 0) });
=======
    const rows = await query('SELECT COUNT(*) AS total FROM users');
    return res.status(200).json({ ok: true, totalUsers: Number(rows[0]?.total || 0) });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Stats lookup failed', error: error.message });
  }
});

app.get('/api/admin/sql-entries', async (_, res) => {
  try {
    const [
      users,
      authLogs,
      medicines,
      reminders,
      alarmLogs,
      caretakers,
      dependents,
      settings,
      userCount,
      medicineCount,
      reminderCount,
      alarmCount,
      caretakerCount,
      dependentCount,
      settingCount,
    ] = await Promise.all([
<<<<<<< HEAD
      User.find({}).sort({ _id: -1 }).limit(250).lean(),
      AuthLog.find({}).sort({ _id: -1 }).limit(500).lean(),
      Medicine.find({}).sort({ _id: -1 }).limit(500).lean(),
      Reminder.find({}).sort({ _id: -1 }).limit(500).lean(),
      AlarmLog.find({}).sort({ _id: -1 }).limit(500).lean(),
      Caretaker.find({}).sort({ _id: -1 }).limit(500).lean(),
      Dependent.find({}).sort({ _id: -1 }).limit(500).lean(),
      Setting.find({}).sort({ _id: -1 }).limit(500).lean(),
      User.countDocuments(),
      Medicine.countDocuments(),
      Reminder.countDocuments(),
      AlarmLog.countDocuments(),
      Caretaker.countDocuments(),
      Dependent.countDocuments(),
      Setting.countDocuments(),
=======
      query('SELECT id, email, is_admin AS isAdmin, created_at AS createdAt, updated_at AS updatedAt FROM users ORDER BY id DESC LIMIT 250'),
      query('SELECT id, email, event_type AS eventType, status, source, ip_address AS ipAddress, created_at AS createdAt FROM auth_logs ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, local_id AS localId, name, dosage, time, category, created_at AS createdAt FROM medicines ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, local_id AS localId, medicine_name AS medicineName, time, is_active AS isActive, created_at AS createdAt FROM reminders ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, local_id AS localId, medicine_name AS medicineName, status, scheduled_time AS scheduledTime, triggered_time AS triggeredTime FROM alarm_logs ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, local_id AS localId, first_name AS firstName, last_name AS lastName, email, relationship, is_active AS isActive, created_at AS createdAt FROM caretakers ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, local_id AS localId, first_name AS firstName, last_name AS lastName, gender, birth_date AS birthDate, color, created_at AS createdAt FROM dependents ORDER BY id DESC LIMIT 500'),
      query('SELECT id, user_id AS userId, key_name AS keyName, value, updated_at AS updatedAt FROM settings ORDER BY id DESC LIMIT 500'),
      query('SELECT COUNT(*) AS total FROM users'),
      query('SELECT COUNT(*) AS total FROM medicines'),
      query('SELECT COUNT(*) AS total FROM reminders'),
      query('SELECT COUNT(*) AS total FROM alarm_logs'),
      query('SELECT COUNT(*) AS total FROM caretakers'),
      query('SELECT COUNT(*) AS total FROM dependents'),
      query('SELECT COUNT(*) AS total FROM settings'),
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    ]);

    return res.status(200).json({
      ok: true,
      data: {
        counts: {
<<<<<<< HEAD
          users: Number(userCount || 0),
          medicines: Number(medicineCount || 0),
          reminders: Number(reminderCount || 0),
          alarmLogs: Number(alarmCount || 0),
          caretakers: Number(caretakerCount || 0),
          dependents: Number(dependentCount || 0),
          settings: Number(settingCount || 0),
          authLogs: Number(authLogs.length || 0),
        },
        users: users.map((u) => ({
          id: Number(String(u._id).slice(-6), 16) || 0,
          email: u.email,
          isAdmin: !!u.isAdmin,
          createdAt: u.createdAt,
          updatedAt: u.updatedAt,
        })),
        authLogs: authLogs.map((a) => ({
          id: Number(String(a._id).slice(-6), 16) || 0,
          email: a.email,
          eventType: a.eventType,
          status: a.status,
          source: a.source,
          ipAddress: a.ipAddress,
          createdAt: a.createdAt,
        })),
        medicines: medicines.map((m) => ({
          id: m.localId,
          userId: m.userId,
          localId: m.localId,
          name: m.name,
          dosage: m.dosage,
          time: m.time,
          category: m.category,
          createdAt: m.createdAt,
        })),
        reminders: reminders.map((r) => ({
          id: r.localId,
          userId: r.userId,
          localId: r.localId,
          medicineName: r.medicineName,
          time: r.time,
          isActive: !!r.isActive,
          createdAt: r.createdAt,
        })),
        alarmLogs: alarmLogs.map((a) => ({
          id: a.localId,
          userId: a.userId,
          localId: a.localId,
          medicineName: a.medicineName,
          status: a.status,
          scheduledTime: a.scheduledTime,
          triggeredTime: a.triggeredTime,
        })),
        caretakers: caretakers.map((c) => ({
          id: c.localId,
          userId: c.userId,
          localId: c.localId,
          firstName: c.firstName,
          lastName: c.lastName,
          email: c.email,
          relationship: c.relationship,
          isActive: !!c.isActive,
          createdAt: c.createdAt,
        })),
        dependents: dependents.map(dependentToDto),
        settings: settings.map((s) => ({
          id: Number(String(s._id).slice(-6), 16) || 0,
          userId: s.userId,
          keyName: s.keyName,
          value: s.value,
          updatedAt: s.updatedAt,
        })),
      },
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: 'Failed to fetch admin entries',
      error: error.message,
    });
=======
          users: Number(userCount[0]?.total || 0),
          medicines: Number(medicineCount[0]?.total || 0),
          reminders: Number(reminderCount[0]?.total || 0),
          alarmLogs: Number(alarmCount[0]?.total || 0),
          caretakers: Number(caretakerCount[0]?.total || 0),
          dependents: Number(dependentCount[0]?.total || 0),
          settings: Number(settingCount[0]?.total || 0),
          authLogs: authLogs.length,
        },
        users,
        authLogs,
        medicines,
        reminders,
        alarmLogs,
        caretakers,
        dependents,
        settings,
      },
    });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Failed to fetch SQL entries', error: error.message });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
});

app.post('/api/sync/all', async (req, res) => {
  const {
<<<<<<< HEAD
    userId = 'guest',
=======
    userId = 'demo-user',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    userProfile = null,
    medicines = [],
    reminders = [],
    alarmLogs = [],
    caretakers = [],
  } = req.body || {};
<<<<<<< HEAD
  const scopedUserId = asUserId(userId);

  try {
    await upsertUserProfile(scopedUserId, userProfile);
    for (const medicine of medicines) {
      await upsertMedicine(scopedUserId, medicine || {});
    }
    for (const reminder of reminders) {
      await upsertReminder(scopedUserId, reminder || {});
    }
    for (const alarmLog of alarmLogs) {
      await upsertAlarmLog(scopedUserId, alarmLog || {});
    }
    for (const caretaker of caretakers) {
      await upsertCaretaker(scopedUserId, caretaker || {});
    }

=======

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    await upsertUserProfile(connection, userId, userProfile);

    for (const medicine of medicines) {
      await upsertMedicine(connection, userId, medicine);
    }
    for (const reminder of reminders) {
      await upsertReminder(connection, userId, reminder);
    }
    for (const alarmLog of alarmLogs) {
      await upsertAlarmLog(connection, userId, alarmLog);
    }
    for (const caretaker of caretakers) {
      await upsertCaretaker(connection, userId, caretaker);
    }

    await connection.commit();
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.status(200).json({
      ok: true,
      message: 'All data synced successfully',
      counts: {
        medicines: medicines.length,
        reminders: reminders.length,
        alarmLogs: alarmLogs.length,
        caretakers: caretakers.length,
        profile: userProfile ? 1 : 0,
      },
    });
  } catch (error) {
<<<<<<< HEAD
    res.status(500).json({ ok: false, message: 'Sync failed', error: error.message });
=======
    await connection.rollback();
    res.status(500).json({ ok: false, message: 'Sync failed', error: error.message });
  } finally {
    connection.release();
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
});

app.post('/api/medicines', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertMedicine(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
=======
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertMedicine(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/medicines', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await Medicine.find({ userId: scopedUserId })
      .sort({ localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(medicineToDto) });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, name, dosage, time, category,
              expiry_date AS expiryDate, is_scanned AS isScanned,
              scanned_text AS scannedText, image_path AS imagePath,
              health_condition AS healthCondition,
              created_at AS createdAt
       FROM medicines WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );
    res.json({ ok: true, data: rows });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/medicines/:id', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  const localId = Number(req.params.id);
  try {
    await upsertMedicine(scopedUserId, { ...(req.body || {}), id: localId });
=======
  const userId = (req.body?.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    const connection = await pool.getConnection();
    await upsertMedicine(connection, userId, {
      ...(req.body || {}),
      id: localId,
    });
    connection.release();
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/medicines/:id', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  const localId = Number(req.params.id);
  try {
    await Medicine.deleteOne({ userId: scopedUserId, localId });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM medicines WHERE user_id = ? AND local_id = ?', [userId, localId]);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/reminders', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertReminder(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
=======
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertReminder(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/reminders', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await Reminder.find({ userId: scopedUserId })
      .sort({ localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(reminderToDto) });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, medicine_id AS medicineId, medicine_name AS medicineName,
              time, days_of_week AS daysOfWeek, is_active AS isActive,
              last_notified_at AS lastNotifiedAt, created_at AS createdAt
       FROM reminders WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );

    const data = rows.map((row) => ({
      ...row,
      daysOfWeek: decodeDaysJson(row.daysOfWeek),
    }));

    res.json({ ok: true, data });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/reminders/:id', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  const localId = Number(req.params.id);
  try {
    await Reminder.deleteOne({ userId: scopedUserId, localId });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM reminders WHERE user_id = ? AND local_id = ?', [userId, localId]);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/alarm-logs', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertAlarmLog(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
=======
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertAlarmLog(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/alarm-logs', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await AlarmLog.find({ userId: scopedUserId })
      .sort({ localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(alarmLogToDto) });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, medicine_id AS medicineId, medicine_name AS medicineName,
              scheduled_time AS scheduledTime, triggered_time AS triggeredTime,
              status, snooze_count AS snoozeCount, taken_at AS takenAt, notes
       FROM alarm_logs WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );
    res.json({ ok: true, data: rows });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/caretakers', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertCaretaker(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
=======
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertCaretaker(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/caretakers', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await Caretaker.find({ userId: scopedUserId })
      .sort({ localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(caretakerToDto) });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, first_name AS firstName, last_name AS lastName,
              phone_number AS phoneNumber, email, relationship,
              notify_via_sms AS notifyViaSMS, notify_via_email AS notifyViaEmail,
              notify_via_notification AS notifyViaNotification,
              is_active AS isActive, created_at AS createdAt
       FROM caretakers WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );
    res.json({ ok: true, data: rows });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/caretakers/:id', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  const localId = Number(req.params.id);
  try {
    await Caretaker.deleteOne({ userId: scopedUserId, localId });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM caretakers WHERE user_id = ? AND local_id = ?', [userId, localId]);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/user-profile', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  try {
    await upsertUserProfile(scopedUserId, req.body || {});
=======
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertUserProfile(connection, userId, req.body || {});
    connection.release();
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

<<<<<<< HEAD
app.get('/api/user-profile/:userId', async (req, res) => {
  const scopedUserId = asUserId(req.params.userId);
  try {
    const profile = await UserProfile.findOne({ userId: scopedUserId }).lean();
    if (!profile) {
      return res.status(404).json({ ok: false, message: 'Profile not found' });
    }

    return res.json({
      ok: true,
      data: {
        firstName: profile.firstName,
        lastName: profile.lastName,
        gender: profile.gender,
        birthDate: profile.birthDate,
        zipCode: profile.zipCode,
        phoneNumber: profile.phoneNumber,
        email: profile.email,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      },
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/dependents', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertDependent(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
=======
app.post('/api/dependents', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  const {
    id = null,
    firstName = '',
    lastName = '',
    gender = null,
    birthDate = null,
    color = null,
  } = req.body || {};

  try {
    await query(
      `INSERT INTO dependents (
        user_id, local_id, first_name, last_name, gender, birth_date, color, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        first_name = VALUES(first_name),
        last_name = VALUES(last_name),
        gender = VALUES(gender),
        birth_date = VALUES(birth_date),
        color = VALUES(color)`,
      [
        userId,
        id,
        firstName,
        lastName,
        gender,
        birthDate,
        color,
        toSqlDate(new Date()),
      ],
    );

    res.status(200).json({ ok: true });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/dependents', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await Dependent.find({ userId: scopedUserId })
      .sort({ localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(dependentToDto) });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, first_name AS firstName, last_name AS lastName,
              gender, birth_date AS birthDate, color, created_at AS createdAt
       FROM dependents WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );
    res.json({ ok: true, data: rows });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/dependents/:id', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  const localId = Number(req.params.id);
  try {
    await Dependent.deleteOne({ userId: scopedUserId, localId });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM dependents WHERE user_id = ? AND local_id = ?', [userId, localId]);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/settings', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
  const { key, value } = req.body || {};
=======
  const { userId = 'demo-user', key, value } = req.body || {};
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  if (!key || value === undefined) {
    return res.status(400).json({ ok: false, message: 'key and value are required' });
  }

  try {
<<<<<<< HEAD
    await Setting.findOneAndUpdate(
      { userId: scopedUserId, keyName: String(key) },
      {
        userId: scopedUserId,
        keyName: String(key),
        value: String(value),
        updatedAt: new Date(),
      },
      { upsert: true },
=======
    await query(
      `INSERT INTO settings (user_id, key_name, value, updated_at)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         value = VALUES(value),
         updated_at = VALUES(updated_at)`,
      [userId, key, String(value), toSqlDate(new Date())],
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    );
    return res.status(200).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/settings', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await Setting.find({ userId: scopedUserId }).lean();
    res.json({
      ok: true,
      data: rows.map((row) => ({
        keyName: row.keyName,
        value: row.value,
        updatedAt: row.updatedAt,
      })),
    });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      'SELECT key_name AS keyName, value, updated_at AS updatedAt FROM settings WHERE user_id = ?',
      [userId],
    );
    res.json({ ok: true, data: rows });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/barcode-lookup/:barcode', async (req, res) => {
  const digits = digitsOnly(req.params.barcode);
  if (digits.length < 8) {
    return res.status(400).json({ ok: false, message: 'Invalid barcode' });
  }

  try {
    const match = await lookupDrugByBarcode(digits);
    return res.json({ ok: true, data: match });
  } catch (error) {
<<<<<<< HEAD
    return res
      .status(502)
      .json({ ok: false, message: 'Drug lookup failed', error: error.message });
=======
    return res.status(502).json({ ok: false, message: 'Drug lookup failed', error: error.message });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  }
});

app.post('/api/professional-reviews', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.body?.userId);
=======
  const { userId = 'demo-user' } = req.body || {};
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  const {
    patientName = '',
    contact = '',
    concern = '',
    preferredHospital = null,
    urgency = 'normal',
  } = req.body || {};

  if (!patientName.trim() || !contact.trim() || !concern.trim()) {
    return res.status(400).json({
      ok: false,
      message: 'patientName, contact and concern are required',
    });
  }

  try {
<<<<<<< HEAD
    await ProfessionalReviewRequest.create({
      userId: scopedUserId,
      patientName: patientName.trim(),
      contact: contact.trim(),
      concern: concern.trim(),
      preferredHospital: preferredHospital ? String(preferredHospital).trim() : null,
      urgency,
      status: 'pending',
      createdAt: new Date(),
    });
=======
    await query(
      `INSERT INTO professional_review_requests (
        user_id, patient_name, contact, concern, preferred_hospital,
        urgency, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)`,
      [
        userId,
        patientName.trim(),
        contact.trim(),
        concern.trim(),
        preferredHospital ? preferredHospital.trim() : null,
        urgency,
        toSqlDate(new Date()),
      ],
    );
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26

    return res.status(200).json({
      ok: true,
      message: 'Professional review request submitted',
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/professional-reviews', async (req, res) => {
<<<<<<< HEAD
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await ProfessionalReviewRequest.find({ userId: scopedUserId })
      .sort({ _id: -1 })
      .lean();
    return res.json({
      ok: true,
      data: rows.map((row) => ({
        id: Number(String(row._id).slice(-6), 16) || 0,
        patientName: row.patientName,
        contact: row.contact,
        concern: row.concern,
        preferredHospital: row.preferredHospital,
        urgency: row.urgency,
        status: row.status,
        createdAt: row.createdAt,
      })),
    });
=======
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT id, patient_name AS patientName, contact, concern,
              preferred_hospital AS preferredHospital, urgency,
              status, created_at AS createdAt
       FROM professional_review_requests
       WHERE user_id = ?
       ORDER BY id DESC`,
      [userId],
    );
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/user-profile/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const rows = await query(
      `SELECT first_name AS firstName, last_name AS lastName, gender,
              birth_date AS birthDate, zip_code AS zipCode,
              phone_number AS phoneNumber, email,
              created_at AS createdAt, updated_at AS updatedAt
       FROM user_profiles WHERE user_id = ? LIMIT 1`,
      [userId],
    );

    if (!rows.length) {
      return res.status(404).json({ ok: false, message: 'Profile not found' });
    }

    return res.json({ ok: true, data: rows[0] });
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

async function startServer() {
  try {
<<<<<<< HEAD
    await connectMongo();
    await ping();
    await ensureDefaultAdmin();

    const server = app.listen(port, () => {
      console.log(`Mongo API running on http://localhost:${port}/api`);
=======
    await ping();
    await ensureDefaultAdmin();
    const server = app.listen(port, () => {
      console.log(`MySQL API running on http://localhost:${port}/api`);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    });

    const shutdown = async () => {
      try {
<<<<<<< HEAD
        await disconnectMongo();
=======
        await pool.end();
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      } catch (_) {
        // ignore during shutdown
      }
      server.close(() => {
        process.exit(0);
      });
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  } catch (error) {
<<<<<<< HEAD
    console.error('MongoDB connection failed at startup:', error.message);
=======
    console.error('Database connection failed at startup:', error.message);
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    process.exit(1);
  }
}

startServer();

