require('dotenv').config();

const express = require('express');
const cors = require('cors');
const https = require('https');
const {
  connectMongo,
  ping,
  disconnectMongo,
  generateNextId,
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

function asEntityId(value) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function byEntityId(userId, id) {
  return { userId, $or: [{ id }, { localId: id }] };
}

async function resolveId(Model, userId, idCandidate) {
  if (Number.isInteger(Number(idCandidate))) {
    return Number(idCandidate);
  }
  return generateNextId(Model, userId);
}

function medicineToDto(doc) {
  const id = doc.id ?? doc.localId;
  return {
    id,
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
  const id = doc.id ?? doc.localId;
  return {
    id,
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
  const id = doc.id ?? doc.localId;
  return {
    id,
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
  const id = doc.id ?? doc.localId;
  return {
    id,
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
  const id = doc.id ?? doc.localId;
  return {
    id,
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

  const medicine = await Medicine.findOne(byEntityId(userId, medicineId))
    .select({ id: 1, localId: 1, name: 1 })
    .lean();

  if (!medicine) {
    throw new Error(
      `Foreign key violation: medicine ${medicineId} not found for user ${userId}`,
    );
  }

  return {
    ...medicine,
    id: Number(medicine.id ?? medicine.localId),
  };
}

async function upsertMedicine(userId, medicine) {
  const id = await resolveId(Medicine, userId, medicine.id);
  await Medicine.findOneAndUpdate(
    byEntityId(userId, id),
    {
      userId,
      id,
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
      $unset: { localId: '' },
    },
    { upsert: true },
  );

  await Reminder.updateMany(
    { userId, medicineId: id },
    { $set: { medicineName: medicine.name || '' } },
  );
  await AlarmLog.updateMany(
    { userId, medicineId: id },
    { $set: { medicineName: medicine.name || '' } },
  );

  return id;
}

async function upsertReminder(userId, reminder) {
  const medicine = await requireMedicine(userId, reminder.medicineId);
  const id = await resolveId(Reminder, userId, reminder.id);
  await Reminder.findOneAndUpdate(
    byEntityId(userId, id),
    {
      userId,
      id,
      medicineId: medicine.id,
      medicineName: reminder.medicineName || medicine.name || '',
      time: reminder.time || '',
      daysOfWeek: parseDays(reminder.daysOfWeek),
      isActive: reminder.isActive !== false,
      lastNotifiedAt: parseDate(reminder.lastNotifiedAt),
      createdAt: parseDate(reminder.createdAt) || new Date(),
      $unset: { localId: '' },
    },
    { upsert: true },
  );
  return id;
}

async function upsertAlarmLog(userId, alarmLog) {
  const medicine = await requireMedicine(userId, alarmLog.medicineId);
  const id = await resolveId(AlarmLog, userId, alarmLog.id);
  await AlarmLog.findOneAndUpdate(
    byEntityId(userId, id),
    {
      userId,
      id,
      medicineId: medicine.id,
      medicineName: alarmLog.medicineName || medicine.name || '',
      scheduledTime: parseDate(alarmLog.scheduledTime) || new Date(),
      triggeredTime: parseDate(alarmLog.triggeredTime),
      status: alarmLog.status || 'pending',
      snoozeCount: Number(alarmLog.snoozeCount || 0),
      takenAt: parseDate(alarmLog.takenAt),
      notes: alarmLog.notes || null,
      createdAt: parseDate(alarmLog.createdAt) || new Date(),
      $unset: { localId: '' },
    },
    { upsert: true },
  );
  return id;
}

async function upsertCaretaker(userId, caretaker) {
  const id = await resolveId(Caretaker, userId, caretaker.id);
  await Caretaker.findOneAndUpdate(
    byEntityId(userId, id),
    {
      userId,
      id,
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
      $unset: { localId: '' },
    },
    { upsert: true },
  );
  return id;
}

async function upsertDependent(userId, dependent) {
  const id = await resolveId(Dependent, userId, dependent.id);
  await Dependent.findOneAndUpdate(
    byEntityId(userId, id),
    {
      userId,
      id,
      firstName: dependent.firstName || '',
      lastName: dependent.lastName || '',
      gender: dependent.gender || null,
      birthDate: dependent.birthDate || null,
      color: dependent.color || null,
      createdAt: parseDate(dependent.createdAt) || new Date(),
      $unset: { localId: '' },
    },
    { upsert: true },
  );
  return id;
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
  );
}

app.get('/api/health', async (_, res) => {
  try {
    await ping();
    res.json({ ok: true, message: 'API and MongoDB are connected' });
  } catch (error) {
    res
      .status(500)
      .json({ ok: false, message: 'MongoDB connection failed', error: error.message });
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
    const existing = await User.findOne({ email }).select({ _id: 1 }).lean();
    if (existing) {
      await logAuthEvent({
        email,
        eventType: 'register',
        status: 'duplicate',
        ipAddress,
      });
      return res.status(409).json({ ok: false, message: 'Email already registered' });
    }

    await User.create({
      email,
      passwordHash: password,
      isAdmin: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

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
    const user = await User.findOne({ email }).lean();
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
        id: Number(String(user._id).slice(-6), 16) || 0,
        email: user.email,
        isAdmin: user.isAdmin === true,
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
    const existing = await User.findOne({ email }).select({ _id: 1 }).lean();
    return res.status(200).json({ ok: true, exists: !!existing });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Lookup failed', error: error.message });
  }
});

app.get('/api/auth/stats', async (_, res) => {
  try {
    const totalUsers = await User.countDocuments();
    return res.status(200).json({ ok: true, totalUsers: Number(totalUsers || 0) });
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
    ]);

    return res.status(200).json({
      ok: true,
      data: {
        counts: {
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
          id: m.id ?? m.localId,
          userId: m.userId,
          name: m.name,
          dosage: m.dosage,
          time: m.time,
          category: m.category,
          createdAt: m.createdAt,
        })),
        reminders: reminders.map((r) => ({
          id: r.id ?? r.localId,
          userId: r.userId,
          medicineName: r.medicineName,
          time: r.time,
          isActive: !!r.isActive,
          createdAt: r.createdAt,
        })),
        alarmLogs: alarmLogs.map((a) => ({
          id: a.id ?? a.localId,
          userId: a.userId,
          medicineName: a.medicineName,
          status: a.status,
          scheduledTime: a.scheduledTime,
          triggeredTime: a.triggeredTime,
        })),
        caretakers: caretakers.map((c) => ({
          id: c.id ?? c.localId,
          userId: c.userId,
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
    const docs = await Medicine.find({ userId: scopedUserId })
      .sort({ id: -1, localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(medicineToDto) });
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
    const [medicineDeleteResult, remindersDeleteResult, alarmLogsDeleteResult] =
      await Promise.all([
        Medicine.deleteOne(byEntityId(scopedUserId, id)),
        Reminder.deleteMany({ userId: scopedUserId, medicineId: id }),
        AlarmLog.deleteMany({ userId: scopedUserId, medicineId: id }),
      ]);

    if (!medicineDeleteResult.deletedCount) {
      return res.status(404).json({ ok: false, error: 'Medicine not found' });
    }

    return res.json({
      ok: true,
      deleted: {
        medicine: Number(medicineDeleteResult.deletedCount || 0),
        reminders: Number(remindersDeleteResult.deletedCount || 0),
        alarmLogs: Number(alarmLogsDeleteResult.deletedCount || 0),
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
    const docs = await Reminder.find({ userId: scopedUserId })
      .sort({ id: -1, localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(reminderToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/reminders/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await Reminder.deleteOne(byEntityId(scopedUserId, id));
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
    const docs = await AlarmLog.find({ userId: scopedUserId })
      .sort({ id: -1, localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(alarmLogToDto) });
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
    const docs = await Caretaker.find({ userId: scopedUserId })
      .sort({ id: -1, localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(caretakerToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/caretakers/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await Caretaker.deleteOne(byEntityId(scopedUserId, id));
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
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/dependents', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  try {
    const docs = await Dependent.find({ userId: scopedUserId })
      .sort({ id: -1, localId: -1 })
      .lean();
    res.json({ ok: true, data: docs.map(dependentToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/dependents/:id', async (req, res) => {
  const scopedUserId = asUserId(req.query.userId);
  const id = Number(req.params.id);
  try {
    await Dependent.deleteOne(byEntityId(scopedUserId, id));
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
    await Setting.findOneAndUpdate(
      { userId: scopedUserId, keyName: String(key) },
      {
        userId: scopedUserId,
        keyName: String(key),
        value: String(value),
        updatedAt: new Date(),
      },
      { upsert: true },
    );
    return res.status(200).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/settings', async (req, res) => {
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
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

async function startServer() {
  try {
    await connectMongo();
    await ping();
    await ensureDefaultAdmin();

    const server = app.listen(port, () => {
      console.log(`Mongo API running on http://localhost:${port}/api`);
    });

    const shutdown = async () => {
      try {
        await disconnectMongo();
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
    console.error('MongoDB connection failed at startup:', error.message);
    process.exit(1);
  }
}

startServer();

