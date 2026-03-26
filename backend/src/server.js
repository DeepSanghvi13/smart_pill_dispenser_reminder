require('dotenv').config();

const express = require('express');
const cors = require('cors');
const https = require('https');
const { pool, query, ping } = require('./db');

const app = express();
app.use(cors());
app.use(express.json({ limit: '4mb' }));

const port = Number(process.env.PORT || 3000);
const adminEmail = (process.env.ADMIN_EMAIL || 'admin@medisafe.com').trim().toLowerCase();
const adminPassword = (process.env.ADMIN_PASSWORD || 'admin123').trim();

function boolToInt(value) {
  return value ? 1 : 0;
}

function parseDays(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.split(',').map((v) => v.trim()).filter(Boolean);
  }
  return [];
}

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
    const dosage = (ingredient?.strength || 'N/A').toString().trim() || 'N/A';
    const dosageForm = String(first.dosage_form || '').toLowerCase();
    const category = dosageForm.includes('inject')
      ? 'injection'
      : (dosageForm.includes('solution') || dosageForm.includes('syrup') || dosageForm.includes('liquid'))
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
  );
}

app.get('/api/health', async (_, res) => {
  try {
    await query('SELECT 1');
    res.json({ ok: true, message: 'API and MySQL are connected' });
  } catch (error) {
    res.status(500).json({ ok: false, message: 'MySQL connection failed', error: error.message });
  }
});

app.post('/api/auth/register', async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || '').trim();
  const ipAddress = getClientIp(req);

  if (!email || !password || password.length < 6) {
    return res.status(400).json({ ok: false, message: 'Valid email and password are required' });
  }

  if (email === adminEmail) {
    return res.status(400).json({ ok: false, message: 'Admin account cannot be registered from app' });
  }

  try {
    const existing = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    if (existing.length > 0) {
      await logAuthEvent({
        email,
        eventType: 'register',
        status: 'duplicate',
        ipAddress,
      });
      return res.status(409).json({ ok: false, message: 'Email already registered' });
    }

    const now = toSqlDate(new Date());
    await query(
      `INSERT INTO users (email, password_hash, is_admin, created_at, updated_at)
       VALUES (?, ?, 0, ?, ?)`,
      [email, password, now, now],
    );

    await logAuthEvent({
      email,
      eventType: 'register',
      status: 'success',
      ipAddress,
    });

    return res.status(200).json({ ok: true, message: 'Registration successful' });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Registration failed', error: error.message });
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
    const rows = await query(
      'SELECT id, email, password_hash AS passwordHash, is_admin AS isAdmin FROM users WHERE email = ? LIMIT 1',
      [email],
    );

    if (!rows.length || String(rows[0].passwordHash) !== password) {
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
        id: rows[0].id,
        email: rows[0].email,
        isAdmin: rows[0].isAdmin === 1,
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
    const rows = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    return res.status(200).json({ ok: true, exists: rows.length > 0 });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Lookup failed', error: error.message });
  }
});

app.get('/api/auth/stats', async (_, res) => {
  try {
    const rows = await query('SELECT COUNT(*) AS total FROM users');
    return res.status(200).json({ ok: true, totalUsers: Number(rows[0]?.total || 0) });
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
    ]);

    return res.status(200).json({
      ok: true,
      data: {
        counts: {
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
  }
});

app.post('/api/sync/all', async (req, res) => {
  const {
    userId = 'demo-user',
    userProfile = null,
    medicines = [],
    reminders = [],
    alarmLogs = [],
    caretakers = [],
  } = req.body || {};

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
    await connection.rollback();
    res.status(500).json({ ok: false, message: 'Sync failed', error: error.message });
  } finally {
    connection.release();
  }
});

app.post('/api/medicines', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertMedicine(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/medicines', async (req, res) => {
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/medicines/:id', async (req, res) => {
  const userId = (req.body?.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    const connection = await pool.getConnection();
    await upsertMedicine(connection, userId, {
      ...(req.body || {}),
      id: localId,
    });
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/medicines/:id', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM medicines WHERE user_id = ? AND local_id = ?', [userId, localId]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/reminders', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertReminder(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/reminders', async (req, res) => {
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/reminders/:id', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM reminders WHERE user_id = ? AND local_id = ?', [userId, localId]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/alarm-logs', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertAlarmLog(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/alarm-logs', async (req, res) => {
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/caretakers', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertCaretaker(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/caretakers', async (req, res) => {
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/caretakers/:id', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM caretakers WHERE user_id = ? AND local_id = ?', [userId, localId]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/user-profile', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
  try {
    const connection = await pool.getConnection();
    await upsertUserProfile(connection, userId, req.body || {});
    connection.release();
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/dependents', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      `SELECT local_id AS id, first_name AS firstName, last_name AS lastName,
              gender, birth_date AS birthDate, color, created_at AS createdAt
       FROM dependents WHERE user_id = ? ORDER BY id DESC`,
      [userId],
    );
    res.json({ ok: true, data: rows });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/dependents/:id', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  const localId = Number(req.params.id);
  try {
    await query('DELETE FROM dependents WHERE user_id = ? AND local_id = ?', [userId, localId]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/settings', async (req, res) => {
  const { userId = 'demo-user', key, value } = req.body || {};
  if (!key || value === undefined) {
    return res.status(400).json({ ok: false, message: 'key and value are required' });
  }

  try {
    await query(
      `INSERT INTO settings (user_id, key_name, value, updated_at)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         value = VALUES(value),
         updated_at = VALUES(updated_at)`,
      [userId, key, String(value), toSqlDate(new Date())],
    );
    return res.status(200).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/settings', async (req, res) => {
  const userId = (req.query.userId || 'demo-user').toString();
  try {
    const rows = await query(
      'SELECT key_name AS keyName, value, updated_at AS updatedAt FROM settings WHERE user_id = ?',
      [userId],
    );
    res.json({ ok: true, data: rows });
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
    return res.status(502).json({ ok: false, message: 'Drug lookup failed', error: error.message });
  }
});

app.post('/api/professional-reviews', async (req, res) => {
  const { userId = 'demo-user' } = req.body || {};
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

    return res.status(200).json({
      ok: true,
      message: 'Professional review request submitted',
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/professional-reviews', async (req, res) => {
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
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

async function startServer() {
  try {
    await ping();
    await ensureDefaultAdmin();
    const server = app.listen(port, () => {
      console.log(`MySQL API running on http://localhost:${port}/api`);
    });

    const shutdown = async () => {
      try {
        await pool.end();
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
    console.error('Database connection failed at startup:', error.message);
    process.exit(1);
  }
}

startServer();

