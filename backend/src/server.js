require('dotenv').config();

const express = require('express');
const cors = require('cors');
const https = require('https');
const {
  connectMySQL,
  query,
  ping,
  disconnectMySQL,
  generateNextId,
} = require('./db');

const app = express();
app.use(cors());
app.use(express.json({ limit: '4mb' }));

const port = Number(process.env.PORT || 3000);
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
  }
  return [];
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
  await query(
    'INSERT INTO authLogs (email, eventType, status, source, ipAddress) VALUES (?, ?, ?, ?, ?)',
    [normalizeEmail(email), eventType, status, source, ipAddress]
  );
}

async function ensureDefaultAdmin() {
  const users = await query('SELECT 1 FROM users WHERE email = ? LIMIT 1', [adminEmail]);
  if (users.length === 0) {
    await query(
      'INSERT INTO users (email, passwordHash, isAdmin) VALUES (?, ?, ?)',
      [adminEmail, adminPassword, true]
    );
  } else {
    await query(
      'UPDATE users SET passwordHash = ?, isAdmin = ?, updatedAt = NOW() WHERE email = ?',
      [adminPassword, true, adminEmail]
    );
  }
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

const barcodeOverrides = {
  '8901234567890': {
    expiryDate: '2026-12-31',
    healthCondition: 'Fever / pain relief',
  },
  '012345678905': {
    expiryDate: '2026-06-30',
    healthCondition: 'Allergy relief',
  },
  '4902430780006': {
    expiryDate: '2026-09-30',
    healthCondition: 'Cough / cold relief',
  },
};

async function lookupDrugByBarcode(barcodeDigits) {
  const baseUrl = process.env.OPENFDA_BASE_URL || 'https://api.fda.gov';
  const apiKey = process.env.OPENFDA_API_KEY || '';

  for (const ndc of toNdcCandidates(barcodeDigits)) {
    const queryText = `product_ndc:"${ndc}"+OR+package_ndc:"${ndc}"`;
    const params = new URLSearchParams({ search: queryText, limit: '1' });
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
    const dosage = (ingredient?.strength || 'N/A').toString().trim() || 'N/A';
    const dosageForm = String(first.dosage_form || '').toLowerCase();
    const category = dosageForm.includes('inject')
      ? 'injection'
      : dosageForm.includes('solution') ||
          dosageForm.includes('syrup') ||
          dosageForm.includes('liquid')
        ? 'syrup'
        : 'tablets';

    const override = barcodeOverrides[barcodeDigits] || null;

    return {
      barcode: barcodeDigits,
      name,
      dosage,
      category,
      expiryDate: override?.expiryDate || null,
      healthCondition: override?.healthCondition || null,
      source: 'onlineApi',
    };
  }

  return null;
}

function asEntityId(value) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function medicineToDto(doc) {
  return {
    id: doc.id,
    name: doc.name,
    dosage: doc.dosage,
    time: doc.time,
    category: doc.category,
    expiryDate: doc.expiryDate,
    isScanned: doc.isScanned === 1 || doc.isScanned === true,
    scannedText: doc.scannedText,
    imagePath: doc.imagePath,
    healthCondition: doc.healthCondition,
    createdAt: doc.createdAt,
  };
}

function reminderToDto(doc) {
  let days = [];
  try {
    if (typeof doc.daysOfWeek === 'string') {
      days = JSON.parse(doc.daysOfWeek);
    } else if (Array.isArray(doc.daysOfWeek)) {
      days = doc.daysOfWeek;
    }
  } catch (_) {
    days = [];
  }
  return {
    id: doc.id,
    medicineId: doc.medicineId,
    medicineName: doc.medicineName,
    time: doc.time,
    daysOfWeek: days || [],
    isActive: doc.isActive === 1 || doc.isActive === true,
    lastNotifiedAt: doc.lastNotifiedAt,
    createdAt: doc.createdAt,
  };
}

function alarmLogToDto(doc) {
  return {
    id: doc.id,
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
    id: doc.id,
    firstName: doc.firstName,
    lastName: doc.lastName,
    phoneNumber: doc.phoneNumber,
    email: doc.email,
    relationship: doc.relationship,
    notifyViaSMS: doc.notifyViaSMS === 1 || doc.notifyViaSMS === true,
    notifyViaEmail: doc.notifyViaEmail === 1 || doc.notifyViaEmail === true,
    notifyViaNotification: doc.notifyViaNotification === 1 || doc.notifyViaNotification === true,
    isActive: doc.isActive === 1 || doc.isActive === true,
    createdAt: doc.createdAt,
  };
}

function dependentToDto(doc) {
  return {
    id: doc.id,
    firstName: doc.firstName,
    lastName: doc.lastName,
    gender: doc.gender,
    birthDate: doc.birthDate,
    color: doc.color,
    createdAt: doc.createdAt,
  };
}

async function requireMedicine(userId, medicineIdCandidate) {
  const medicineId = asEntityId(medicineIdCandidate);
  if (medicineId === null) {
    throw new Error('medicineId must be a valid positive integer');
  }

  const rows = await query(
    'SELECT id, name FROM medicines WHERE userId = ? AND id = ? LIMIT 1',
    [userId, medicineId]
  );

  if (rows.length === 0) {
    throw new Error(
      `Foreign key violation: medicine ${medicineId} not found for user ${userId}`,
    );
  }

  return {
    id: rows[0].id,
    name: rows[0].name,
  };
}

async function upsertMedicine(userId, medicine) {
  const id = medicine.id && Number.isInteger(Number(medicine.id))
    ? Number(medicine.id)
    : await generateNextId('medicines', userId);

  await query(
    `INSERT INTO medicines 
     (userId, id, name, dosage, time, category, expiryDate, isScanned, scannedText, imagePath, healthCondition, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     name=VALUES(name), dosage=VALUES(dosage), time=VALUES(time), category=VALUES(category), 
     expiryDate=VALUES(expiryDate), isScanned=VALUES(isScanned), scannedText=VALUES(scannedText), 
     imagePath=VALUES(imagePath), healthCondition=VALUES(healthCondition)`,
    [
      userId,
      id,
      medicine.name || '',
      medicine.dosage || '',
      medicine.time || '',
      medicine.category || 'tablets',
      parseDate(medicine.expiryDate),
      medicine.isScanned === true ? 1 : 0,
      medicine.scannedText || null,
      medicine.imagePath || null,
      medicine.healthCondition || null,
      parseDate(medicine.createdAt) || new Date()
    ]
  );

  await query('UPDATE reminders SET medicineName = ? WHERE userId = ? AND medicineId = ?', [medicine.name || '', userId, id]);
  await query('UPDATE alarmLogs SET medicineName = ? WHERE userId = ? AND medicineId = ?', [medicine.name || '', userId, id]);

  return id;
}

async function upsertReminder(userId, reminder) {
  const medicine = await requireMedicine(userId, reminder.medicineId);
  const id = reminder.id && Number.isInteger(Number(reminder.id))
    ? Number(reminder.id)
    : await generateNextId('reminders', userId);

  await query(
    `INSERT INTO reminders 
     (userId, id, medicineId, medicineName, time, daysOfWeek, isActive, lastNotifiedAt, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     medicineId=VALUES(medicineId), medicineName=VALUES(medicineName), time=VALUES(time), 
     daysOfWeek=VALUES(daysOfWeek), isActive=VALUES(isActive), lastNotifiedAt=VALUES(lastNotifiedAt)`,
    [
      userId,
      id,
      medicine.id,
      reminder.medicineName || medicine.name || '',
      reminder.time || '',
      JSON.stringify(parseDays(reminder.daysOfWeek)),
      reminder.isActive !== false ? 1 : 0,
      parseDate(reminder.lastNotifiedAt),
      parseDate(reminder.createdAt) || new Date()
    ]
  );
  return id;
}

async function upsertAlarmLog(userId, alarmLog) {
  const medicine = await requireMedicine(userId, alarmLog.medicineId);
  const id = alarmLog.id && Number.isInteger(Number(alarmLog.id))
    ? Number(alarmLog.id)
    : await generateNextId('alarmLogs', userId);

  await query(
    `INSERT INTO alarmLogs 
     (userId, id, medicineId, medicineName, scheduledTime, triggeredTime, status, snoozeCount, takenAt, notes, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     medicineId=VALUES(medicineId), medicineName=VALUES(medicineName), scheduledTime=VALUES(scheduledTime), 
     triggeredTime=VALUES(triggeredTime), status=VALUES(status), snoozeCount=VALUES(snoozeCount), 
     takenAt=VALUES(takenAt), notes=VALUES(notes)`,
    [
      userId,
      id,
      medicine.id,
      alarmLog.medicineName || medicine.name || '',
      parseDate(alarmLog.scheduledTime) || new Date(),
      parseDate(alarmLog.triggeredTime),
      alarmLog.status || 'pending',
      Number(alarmLog.snoozeCount || 0),
      parseDate(alarmLog.takenAt),
      alarmLog.notes || null,
      parseDate(alarmLog.createdAt) || new Date()
    ]
  );
  return id;
}

async function upsertCaretaker(userId, caretaker) {
  const id = caretaker.id && Number.isInteger(Number(caretaker.id))
    ? Number(caretaker.id)
    : await generateNextId('caretakers', userId);

  await query(
    `INSERT INTO caretakers 
     (userId, id, firstName, lastName, phoneNumber, email, relationship, notifyViaSMS, notifyViaEmail, notifyViaNotification, isActive, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     firstName=VALUES(firstName), lastName=VALUES(lastName), phoneNumber=VALUES(phoneNumber), email=VALUES(email), 
     relationship=VALUES(relationship), notifyViaSMS=VALUES(notifyViaSMS), notifyViaEmail=VALUES(notifyViaEmail), 
     notifyViaNotification=VALUES(notifyViaNotification), isActive=VALUES(isActive)`,
    [
      userId,
      id,
      caretaker.firstName || '',
      caretaker.lastName || '',
      caretaker.phoneNumber || '',
      caretaker.email || '',
      caretaker.relationship || '',
      caretaker.notifyViaSMS !== false ? 1 : 0,
      caretaker.notifyViaEmail !== false ? 1 : 0,
      caretaker.notifyViaNotification !== false ? 1 : 0,
      caretaker.isActive !== false ? 1 : 0,
      parseDate(caretaker.createdAt) || new Date()
    ]
  );
  return id;
}

async function upsertDependent(userId, dependent) {
  const id = dependent.id && Number.isInteger(Number(dependent.id))
    ? Number(dependent.id)
    : await generateNextId('dependents', userId);

  await query(
    `INSERT INTO dependents 
     (userId, id, firstName, lastName, gender, birthDate, color, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     firstName=VALUES(firstName), lastName=VALUES(lastName), gender=VALUES(gender), 
     birthDate=VALUES(birthDate), color=VALUES(color)`,
    [
      userId,
      id,
      dependent.firstName || '',
      dependent.lastName || '',
      dependent.gender || null,
      dependent.birthDate || null,
      dependent.color || null,
      parseDate(dependent.createdAt) || new Date()
    ]
  );
  return id;
}

async function upsertUserProfile(userId, profile) {
  if (!profile) return;
  await query(
    `INSERT INTO userProfiles 
     (userId, firstName, lastName, gender, birthDate, zipCode, phoneNumber, email, createdAt, updatedAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
     ON DUPLICATE KEY UPDATE 
     firstName=VALUES(firstName), lastName=VALUES(lastName), gender=VALUES(gender), 
     birthDate=VALUES(birthDate), zipCode=VALUES(zipCode), phoneNumber=VALUES(phoneNumber), 
     email=VALUES(email), updatedAt=NOW()`,
    [
      userId,
      profile.firstName || '',
      profile.lastName || '',
      profile.gender || null,
      profile.birthDate || null,
      profile.zipCode || null,
      profile.phoneNumber || null,
      profile.email || null
    ]
  );
}

app.get('/api/health', async (_, res) => {
  try {
    await ping();
    res.json({ ok: true, message: 'API and MySQL are connected' });
  } catch (error) {
    res
      .status(500)
      .json({ ok: false, message: 'MySQL connection failed', error: error.message });
  }
});

app.post('/api/auth/register', async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || '').trim();
  const ipAddress = getClientIp(req);

  if (!email || !password || password.length < 6) {
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

    await query(
      'INSERT INTO users (email, passwordHash, isAdmin) VALUES (?, ?, ?)',
      [email, password, false]
    );

    await logAuthEvent({
      email,
      eventType: 'register',
      status: 'success',
      ipAddress,
    });

    return res.status(200).json({ ok: true, message: 'Registration successful' });
  } catch (error) {
    return res
      .status(500)
      .json({ ok: false, message: 'Registration failed', error: error.message });
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
    const rows = await query('SELECT id, email, passwordHash, isAdmin FROM users WHERE email = ? LIMIT 1', [email]);
    const user = rows[0];
    if (!user || String(user.passwordHash) !== password) {
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
        id: user.id,
        email: user.email,
        isAdmin: user.isAdmin === 1 || user.isAdmin === true,
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
    const rows = await query('SELECT COUNT(*) as count FROM users');
    return res.status(200).json({ ok: true, totalUsers: Number(rows[0].count || 0) });
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
      userCountRows,
      medicineCountRows,
      reminderCountRows,
      alarmCountRows,
      caretakerCountRows,
      dependentCountRows,
      settingCountRows,
    ] = await Promise.all([
      query('SELECT * FROM users ORDER BY id DESC LIMIT 250'),
      query('SELECT * FROM authLogs ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM medicines ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM reminders ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM alarmLogs ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM caretakers ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM dependents ORDER BY id DESC LIMIT 500'),
      query('SELECT * FROM settings ORDER BY keyName DESC LIMIT 500'),
      query('SELECT COUNT(*) as count FROM users'),
      query('SELECT COUNT(*) as count FROM medicines'),
      query('SELECT COUNT(*) as count FROM reminders'),
      query('SELECT COUNT(*) as count FROM alarmLogs'),
      query('SELECT COUNT(*) as count FROM caretakers'),
      query('SELECT COUNT(*) as count FROM dependents'),
      query('SELECT COUNT(*) as count FROM settings'),
    ]);

    return res.status(200).json({
      ok: true,
      data: {
        counts: {
          users: Number(userCountRows[0].count || 0),
          medicines: Number(medicineCountRows[0].count || 0),
          reminders: Number(reminderCountRows[0].count || 0),
          alarmLogs: Number(alarmCountRows[0].count || 0),
          caretakers: Number(caretakerCountRows[0].count || 0),
          dependents: Number(dependentCountRows[0].count || 0),
          settings: Number(settingCountRows[0].count || 0),
          authLogs: Number(authLogs.length || 0),
        },
        users: users.map((u) => ({
          id: u.id,
          email: u.email,
          isAdmin: u.isAdmin === 1 || u.isAdmin === true,
          createdAt: u.createdAt,
          updatedAt: u.updatedAt,
        })),
        authLogs: authLogs.map((a) => ({
          id: a.id,
          email: a.email,
          eventType: a.eventType,
          status: a.status,
          source: a.source,
          ipAddress: a.ipAddress,
          createdAt: a.createdAt,
        })),
        medicines: medicines.map((m) => ({
          id: m.id,
          userId: m.userId,
          name: m.name,
          dosage: m.dosage,
          time: m.time,
          category: m.category,
          createdAt: m.createdAt,
        })),
        reminders: reminders.map((r) => ({
          id: r.id,
          userId: r.userId,
          medicineName: r.medicineName,
          time: r.time,
          isActive: r.isActive === 1 || r.isActive === true,
          createdAt: r.createdAt,
        })),
        alarmLogs: alarmLogs.map((a) => ({
          id: a.id,
          userId: a.userId,
          medicineName: a.medicineName,
          status: a.status,
          scheduledTime: a.scheduledTime,
          triggeredTime: a.triggeredTime,
        })),
        caretakers: caretakers.map((c) => ({
          id: c.id,
          userId: c.userId,
          firstName: c.firstName,
          lastName: c.lastName,
          email: c.email,
          relationship: c.relationship,
          isActive: c.isActive === 1 || c.isActive === true,
          createdAt: c.createdAt,
        })),
        dependents: dependents.map(dependentToDto),
        settings: settings.map((s) => ({
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
  }
});

app.post('/api/sync/all', async (req, res) => {
  const {
    userId = 'guest',
    userProfile = null,
    medicines = [],
    reminders = [],
    alarmLogs = [],
    caretakers = [],
  } = req.body || {};
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
    res.status(500).json({ ok: false, message: 'Sync failed', error: error.message });
  }
});

app.post('/api/medicines', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertMedicine(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/medicines', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM medicines WHERE userId = ? ORDER BY id DESC', [scopedUserId]);
    res.json({ ok: true, data: rows.map(medicineToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/medicines/:id', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  const id = Number(req.params.id);
  try {
    await upsertMedicine(scopedUserId, { ...(req.body || {}), id });
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/medicines/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);

  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ ok: false, error: 'Invalid medicine id' });
  }

  try {
    const [medicineRes, remindersRes, alarmLogsRes] = await Promise.all([
      query('DELETE FROM medicines WHERE userId = ? AND id = ?', [scopedUserId, id]),
      query('DELETE FROM reminders WHERE userId = ? AND medicineId = ?', [scopedUserId, id]),
      query('DELETE FROM alarmLogs WHERE userId = ? AND medicineId = ?', [scopedUserId, id]),
    ]);

    if (medicineRes.affectedRows === 0) {
      return res.status(404).json({ ok: false, error: 'Medicine not found' });
    }

    return res.json({
      ok: true,
      deleted: {
        medicine: Number(medicineRes.affectedRows || 0),
        reminders: Number(remindersRes.affectedRows || 0),
        alarmLogs: Number(alarmLogsRes.affectedRows || 0),
      },
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/reminders', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertReminder(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/reminders', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM reminders WHERE userId = ? ORDER BY id DESC', [scopedUserId]);
    res.json({ ok: true, data: rows.map(reminderToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/reminders/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await query('DELETE FROM reminders WHERE userId = ? AND id = ?', [scopedUserId, id]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/alarm-logs', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertAlarmLog(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/alarm-logs', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM alarmLogs WHERE userId = ? ORDER BY id DESC', [scopedUserId]);
    res.json({ ok: true, data: rows.map(alarmLogToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/caretakers', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    const id = await upsertCaretaker(scopedUserId, req.body || {});
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/caretakers', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM caretakers WHERE userId = ? ORDER BY id DESC', [scopedUserId]);
    res.json({ ok: true, data: rows.map(caretakerToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/caretakers/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await query('DELETE FROM caretakers WHERE userId = ? AND id = ?', [scopedUserId, id]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/user-profile', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  try {
    await upsertUserProfile(scopedUserId, req.body || {});
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/user-profile/:userId', async (req, res) => {
  const scopedUserId = asUserId(req.params.userId);
  try {
    const rows = await query('SELECT * FROM userProfiles WHERE userId = ? LIMIT 1', [scopedUserId]);
    const profile = rows[0];
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/dependents', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM dependents WHERE userId = ? ORDER BY id DESC', [scopedUserId]);
    res.json({ ok: true, data: rows.map(dependentToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/dependents/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await query('DELETE FROM dependents WHERE userId = ? AND id = ?', [scopedUserId, id]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/settings', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
  const { key, value } = req.body || {};
  if (!key || value === undefined) {
    return res.status(400).json({ ok: false, message: 'key and value are required' });
  }

  try {
    await query(
      `INSERT INTO settings (userId, keyName, value, updatedAt) 
       VALUES (?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE value = VALUES(value), updatedAt = NOW()`,
      [scopedUserId, String(key), String(value)]
    );
    return res.status(200).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/settings', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query('SELECT * FROM settings WHERE userId = ?', [scopedUserId]);
    res.json({
      ok: true,
      data: rows.map((row) => ({
        keyName: row.keyName,
        value: row.value,
        updatedAt: row.updatedAt,
      })),
    });
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
    return res
      .status(502)
      .json({ ok: false, message: 'Drug lookup failed', error: error.message });
  }
});

app.post('/api/professional-reviews', async (req, res) => {
  const scopedUserId = asUserId(req.body?.userId);
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
      `INSERT INTO professionalReviewRequests 
       (userId, patientName, contact, concern, preferredHospital, urgency, status, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        scopedUserId,
        patientName.trim(),
        contact.trim(),
        concern.trim(),
        preferredHospital ? String(preferredHospital).trim() : null,
        urgency,
        'pending'
      ]
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
  const scopedUserId = asUserId(req.query.userId);
  try {
    const rows = await query(
      'SELECT * FROM professionalReviewRequests WHERE userId = ? ORDER BY id DESC',
      [scopedUserId]
    );
    return res.json({
      ok: true,
      data: rows.map((row) => ({
        id: row.id,
        patientName: row.patientName,
        contact: row.contact,
        concern: row.concern,
        preferredHospital: row.preferredHospital,
        urgency: row.urgency,
        status: row.status,
        createdAt: row.createdAt,
      })),
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

async function startServer() {
  try {
    await connectMySQL();
    await ensureDefaultAdmin();

    const server = app.listen(port, () => {
      console.log(`MySQL API running on http://localhost:${port}/api`);
    });

    const shutdown = async () => {
      try {
        await disconnectMySQL();
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
    console.error('MySQL connection failed at startup:', error.message);
    process.exit(1);
  }
}

startServer();
