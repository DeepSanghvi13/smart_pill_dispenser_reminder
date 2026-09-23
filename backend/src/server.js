require('dotenv').config();

const express = require('express');
const cors = require('cors');
const https = require('https');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const {
  connectMySQL,
  query,
  ping,
  disconnectMySQL,
} = require('./db');

const { parseUserAgent } = require('./ua_parser');
const { authenticateToken, requireRole, JWT_SECRET } = require('./auth_middleware');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

const app = express();
app.use(cors());
app.use(express.json({ limit: '4mb' }));

// Ensure uploads directories exist
const uploadDir = path.join(__dirname, '..', 'uploads');
const profileUploadDir = path.join(uploadDir, 'profiles');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
if (!fs.existsSync(profileUploadDir)) {
  fs.mkdirSync(profileUploadDir, { recursive: true });
}

// Serve static uploads
app.use('/uploads', express.static(uploadDir));

// Multer Storage Configuration
const profileStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, profileUploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const userId = req.user ? req.user.id : 'anon';
    const uniqueSuffix = `${Date.now()}_${Math.round(Math.random() * 1e9)}`;
    cb(null, `user_${userId}_${uniqueSuffix}${ext}`);
  }
});

const profileUpload = multer({
  storage: profileStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  fileFilter: function (req, file, cb) {
    const allowedMime = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    const allowedExt = ['.jpg', '.jpeg', '.png', '.webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedMime.includes(file.mimetype) || allowedExt.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Please select a valid image file (.jpg, .jpeg, .png, .webp).'));
    }
  }
});

const port = Number(process.env.PORT || 3000);
const adminEmail = (process.env.ADMIN_EMAIL || 'admin@medisafe.com')
  .trim()
  .toLowerCase();
const adminPassword = (process.env.ADMIN_PASSWORD || 'admin123').trim();

// Health Check Endpoint
app.get(['/api/health', '/health'], async (req, res) => {
  const start = Date.now();
  let dbStatus = 'disconnected';
  try {
    await ping();
    dbStatus = 'connected';
  } catch (err) {
    dbStatus = 'error';
  }
  const latency = Date.now() - start;
  
  const memoryUsage = process.memoryUsage();
  
  res.status(200).json({ 
    ok: dbStatus === 'connected', 
    status: dbStatus === 'connected' ? 'healthy' : 'degraded', 
    timestamp: new Date().toISOString(),
    uptimeSeconds: process.uptime(),
    db: {
      status: dbStatus,
      latencyMs: latency
    },
    memory: {
      rssMb: Math.round(memoryUsage.rss / 1024 / 1024),
      heapTotalMb: Math.round(memoryUsage.heapTotal / 1024 / 1024),
      heapUsedMb: Math.round(memoryUsage.heapUsed / 1024 / 1024),
    }
  });
});

// Auxiliary helper functions
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

const GMAIL_REGEX = /^[A-Za-z0-9._%+-]+@gmail\.com$/;
const PHONE_REGEX = /^[0-9]{10}$/;
const LICENSE_REGEX = /^[0-9]{5}$/;

function isValidGmail(email) {
  if (!email || typeof email !== 'string') return false;
  return GMAIL_REGEX.test(email.trim());
}

function isValidPhone(phone) {
  if (!phone || typeof phone !== 'string') return false;
  return PHONE_REGEX.test(phone.trim());
}

function isValidLicense(license) {
  if (!license || typeof license !== 'string') return false;
  return LICENSE_REGEX.test(license.trim());
}

function isAdminEmail(email) {
  if (!email) return false;
  const norm = normalizeEmail(email);
  return norm === adminEmail || norm === 'admin@smartpill.com';
}

function getClientIp(req) {
  if (!req) return null;
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || null;
}

// Map user ID (email or numeric string) to database integer ID
async function resolveUserId(val) {
  if (!val || val === 'guest') return null;
  const str = String(val).trim();
  if (/^\d+$/.test(str)) {
    const num = Number(str);
    return num > 0 ? num : null;
  }
  const normEmail = normalizeEmail(str);
  if (!normEmail) return null;

  const rows = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [normEmail]);
  if (rows.length > 0) {
    return rows[0].id;
  }
  // Auto-create user if email provided but not in MySQL table yet (from offline Hive sync)
  if (normEmail.includes('@')) {
    try {
      const hash = await bcrypt.hash('defaultpass123', 10);
      const namePart = normEmail.split('@')[0];
      const res = await query(
        `INSERT INTO users (fullName, email, passwordHash, role, status)
         VALUES (?, ?, ?, 'patient', 'active')`,
        [namePart, normEmail, hash]
      );
      const newId = res.insertId;
      await query(
        'INSERT INTO patients (userId) VALUES (?) ON DUPLICATE KEY UPDATE userId=userId',
        [newId]
      );
      await query(
        'INSERT INTO userProfiles (userId, firstName, email) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE userId=userId',
        [newId, namePart, normEmail]
      );
      return newId;
    } catch (err) {
      console.error('Error auto-creating user in resolveUserId:', err.message);
      return null;
    }
  }
  return null;
}

// Comprehensive Activity Logging
async function logActivity({
  userId = null,
  userRole = 'guest',
  userName = null,
  userEmail = null,
  activityType,
  description = null,
  status = 'SUCCESS',
  sessionId = null,
  req
}) {
  try {
    const ipAddress = getClientIp(req);
    const userAgent = req ? req.headers['user-agent'] || '' : '';
    const { device, browser, os } = parseUserAgent(userAgent);

    await query(
      `INSERT INTO activity_logs 
       (userId, userRole, userName, userEmail, activityType, description, ipAddress, device, browser, operatingSystem, status, sessionId)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        userRole,
        userName,
        userEmail,
        activityType,
        description,
        ipAddress,
        device,
        browser,
        os,
        status,
        sessionId
      ]
    );
  } catch (err) {
    console.error('Failed to write activity log:', err.message);
  }
}

// Seed admin account
async function ensureDefaultAdmin() {
  try {
    const adminEmails = [adminEmail, 'admin@smartpill.com'];
    for (const email of adminEmails) {
      const users = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
      const hash = await bcrypt.hash(adminPassword, 10);
      let adminUserId;

      if (users.length === 0) {
        const result = await query(
          'INSERT INTO users (fullName, email, passwordHash, role, status) VALUES (?, ?, ?, ?, ?)',
          ['System Admin', email, hash, 'admin', 'active']
        );
        adminUserId = result.insertId;
        await query('INSERT INTO admins (userId) VALUES (?)', [adminUserId]);
        await query(
          'INSERT INTO userProfiles (userId, firstName, lastName, email) VALUES (?, ?, ?, ?)',
          [adminUserId, 'System', 'Admin', email]
        );
      } else {
        adminUserId = users[0].id;
        await query(
          'UPDATE users SET fullName = ?, passwordHash = ?, role = ?, status = ?, updatedAt = NOW() WHERE id = ?',
          ['System Admin', hash, 'admin', 'active', adminUserId]
        );
        const adminExists = await query('SELECT 1 FROM admins WHERE userId = ? LIMIT 1', [adminUserId]);
        if (adminExists.length === 0) {
          await query('INSERT INTO admins (userId) VALUES (?)', [adminUserId]);
        }
      }
    }
    console.log('Default admin accounts verified in MySQL');
  } catch (error) {
    console.error('Error seeding default admin:', error.message);
  }
}

// ------------------------------------------------------------------
// Health Check Endpoint
// ------------------------------------------------------------------
app.get('/api/health', async (req, res) => {
  try {
    let dbStatus = 'disconnected';
    let latency = 0;
    
    const start = Date.now();
    try {
      const [rows] = await db.query('SELECT 1');
      if (rows) {
        dbStatus = 'connected';
        latency = Date.now() - start;
      }
    } catch (e) {
      console.error('DB Health Check Error:', e);
    }
    
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: {
        status: dbStatus,
        latency_ms: latency,
      },
      memory: process.memoryUsage(),
    });
  } catch (error) {
    res.status(500).json({ error: 'Health check failed', details: error.message });
  }
});

// Middleware: authenticate token with fallback context supporting legacy sync parameters
function authenticateTokenOrFallback(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (token) {
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        return res.status(403).json({ ok: false, message: 'Invalid or expired token' });
      }
      req.user = decoded;
      next();
    });
  } else {
    const fallbackId = req.body?.userId || req.query?.userId || req.body?.patientId || req.body?.email;
    if (fallbackId && fallbackId !== 'guest') {
      resolveUserId(fallbackId).then((resolvedId) => {
        if (!resolvedId || resolvedId <= 0) {
          return res.status(400).json({ ok: false, message: 'User mapping failed' });
        }
        req.user = {
          id: resolvedId,
          email: String(fallbackId).includes('@') ? String(fallbackId) : 'fallback@smartpill.com',
          role: 'patient',
          isAdmin: false
        };
        next();
      }).catch(() => res.status(500).json({ ok: false, message: 'User resolution failed' }));
    } else {
      next();
    }
  }
}

// Convert model objects to API responses (DTO mapping)
function medicineToDto(doc) {
  return {
    id: doc.id,
    name: doc.name,
    dosage: doc.dosage,
    time: doc.time,
    category: doc.type,
    startDate: doc.startDate,
    endDate: doc.endDate,
    expiryDate: doc.expiryDate || doc.endDate,
    notes: doc.notes,
    status: doc.status,
    lastActionDate: doc.lastActionDate,
    isScanned: doc.isScanned === 1 || doc.isScanned === true,
    scannedText: doc.scannedText,
    imagePath: doc.imagePath,
    healthCondition: doc.healthCondition,
    sideEffects: doc.sideEffects,
    storageInstructions: doc.storageInstructions,
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
    time: doc.time,
    daysOfWeek: days || [],
    isActive: doc.isActive === 1 || doc.isActive === true,
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

// Database upsert scripts

async function upsertMedicine(userId, medicine, creatorId) {
  const id = medicine.id && Number.isInteger(Number(medicine.id)) ? Number(medicine.id) : null;
  const updater = creatorId || userId;
  const expiry = parseDate(medicine.expiryDate) || parseDate(medicine.endDate) || new Date();

  if (id) {
    await query(
      `INSERT INTO medicines 
       (id, userId, name, type, dosage, quantity, frequency, time, startDate, endDate, expiryDate, notes, status, lastActionDate, isScanned, scannedText, imagePath, healthCondition, sideEffects, storageInstructions, createdBy, updatedBy)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       name=VALUES(name), type=VALUES(type), dosage=VALUES(dosage), quantity=VALUES(quantity), frequency=VALUES(frequency),
       time=VALUES(time), startDate=VALUES(startDate), endDate=VALUES(endDate), expiryDate=VALUES(expiryDate), notes=VALUES(notes), status=VALUES(status),
       lastActionDate=VALUES(lastActionDate), isScanned=VALUES(isScanned), scannedText=VALUES(scannedText), imagePath=VALUES(imagePath),
       healthCondition=VALUES(healthCondition), sideEffects=VALUES(sideEffects), storageInstructions=VALUES(storageInstructions), updatedBy=VALUES(updatedBy)`,
      [
        id,
        userId,
        medicine.name || '',
        medicine.category || medicine.type || 'tablets',
        medicine.dosage || '',
        medicine.quantity || '1 Pill',
        medicine.frequency || 'Daily',
        medicine.time || '',
        parseDate(medicine.startDate) || new Date(),
        parseDate(medicine.endDate) || new Date(),
        expiry,
        medicine.notes || null,
        medicine.status || 'pending',
        parseDate(medicine.lastActionDate),
        medicine.isScanned === true ? 1 : 0,
        medicine.scannedText || null,
        medicine.imagePath || null,
        medicine.healthCondition || null,
        medicine.sideEffects || null,
        medicine.storageInstructions || null,
        updater,
        updater
      ]
    );
    return id;
  } else {
    const result = await query(
      `INSERT INTO medicines 
       (userId, name, type, dosage, quantity, frequency, time, startDate, endDate, expiryDate, notes, status, lastActionDate, isScanned, scannedText, imagePath, healthCondition, sideEffects, storageInstructions, createdBy, updatedBy)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        medicine.name || '',
        medicine.category || medicine.type || 'tablets',
        medicine.dosage || '',
        medicine.quantity || '1 Pill',
        medicine.frequency || 'Daily',
        medicine.time || '',
        parseDate(medicine.startDate) || new Date(),
        parseDate(medicine.endDate) || new Date(),
        expiry,
        medicine.notes || null,
        medicine.status || 'pending',
        parseDate(medicine.lastActionDate),
        medicine.isScanned === true ? 1 : 0,
        medicine.scannedText || null,
        medicine.imagePath || null,
        medicine.healthCondition || null,
        medicine.sideEffects || null,
        medicine.storageInstructions || null,
        updater,
        updater
      ]
    );
    return result.insertId;
  }
}

async function upsertReminder(userId, reminder) {
  const id = reminder.id && Number.isInteger(Number(reminder.id)) ? Number(reminder.id) : null;

  if (id) {
    await query(
      `INSERT INTO reminders (id, userId, medicineId, time, daysOfWeek, isActive, lastNotifiedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       medicineId=VALUES(medicineId), time=VALUES(time), daysOfWeek=VALUES(daysOfWeek), isActive=VALUES(isActive), lastNotifiedAt=VALUES(lastNotifiedAt)`,
      [
        id,
        userId,
        Number(reminder.medicineId),
        reminder.time || '',
        JSON.stringify(parseDays(reminder.daysOfWeek)),
        reminder.isActive !== false ? 1 : 0,
        parseDate(reminder.lastNotifiedAt)
      ]
    );
    return id;
  } else {
    const result = await query(
      `INSERT INTO reminders (userId, medicineId, time, daysOfWeek, isActive, lastNotifiedAt)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        userId,
        Number(reminder.medicineId),
        reminder.time || '',
        JSON.stringify(parseDays(reminder.daysOfWeek)),
        reminder.isActive !== false ? 1 : 0,
        parseDate(reminder.lastNotifiedAt)
      ]
    );
    return result.insertId;
  }
}

async function upsertAlarmLog(userId, alarmLog) {
  const id = alarmLog.id && Number.isInteger(Number(alarmLog.id)) ? Number(alarmLog.id) : null;
  let finalId = id;

  if (id) {
    await query(
      `INSERT INTO alarmLogs (id, userId, medicineId, medicineName, scheduledTime, triggeredTime, status, snoozeCount, takenAt, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       medicineId=VALUES(medicineId), medicineName=VALUES(medicineName), scheduledTime=VALUES(scheduledTime), 
       triggeredTime=VALUES(triggeredTime), status=VALUES(status), snoozeCount=VALUES(snoozeCount), 
       takenAt=VALUES(takenAt), notes=VALUES(notes)`,
      [
        id,
        userId,
        Number(alarmLog.medicineId),
        alarmLog.medicineName || '',
        parseDate(alarmLog.scheduledTime) || new Date(),
        parseDate(alarmLog.triggeredTime),
        alarmLog.status || 'pending',
        Number(alarmLog.snoozeCount || 0),
        parseDate(alarmLog.takenAt),
        alarmLog.notes || null
      ]
    );
  } else {
    const result = await query(
      `INSERT INTO alarmLogs (userId, medicineId, medicineName, scheduledTime, triggeredTime, status, snoozeCount, takenAt, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        Number(alarmLog.medicineId),
        alarmLog.medicineName || '',
        parseDate(alarmLog.scheduledTime) || new Date(),
        parseDate(alarmLog.triggeredTime),
        alarmLog.status || 'pending',
        Number(alarmLog.snoozeCount || 0),
        parseDate(alarmLog.takenAt),
        alarmLog.notes || null
      ]
    );
    finalId = result.insertId;
  }
  
  // Strict Adherence Escalation Logic
  if ((alarmLog.status || 'pending') === 'missed') {
    try {
      const caretakers = await query(`SELECT caretakerId FROM caretaker_connections WHERE patientId = ? AND status = 'connected'`, [userId]);
      for (const c of caretakers) {
        await query(`INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)`, 
          [c.caretakerId, 'Missed Medication Alert', `Patient missed their medication: ${alarmLog.medicineName}`, 'critical_alert', false]);
      }
      
      const doctors = await query(`SELECT doctorId FROM doctor_connections WHERE requesterId = ? AND status = 'accepted'`, [userId]);
      for (const d of doctors) {
        await query(`INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)`, 
          [d.doctorId, 'Patient Missed Medication', `Your patient missed their medication: ${alarmLog.medicineName}`, 'critical_alert', false]);
      }
    } catch (err) {
      console.error("Escalation failed", err);
    }
  }
  
  return finalId;
}

async function upsertCaretaker(userId, caretaker) {
  const id = caretaker.id && Number.isInteger(Number(caretaker.id)) ? Number(caretaker.id) : null;

  if (id) {
    await query(
      `INSERT INTO caretakers (userId, relationship, notifyViaSMS, notifyViaEmail, notifyViaNotification)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       relationship=VALUES(relationship), notifyViaSMS=VALUES(notifyViaSMS), 
       notifyViaEmail=VALUES(notifyViaEmail), notifyViaNotification=VALUES(notifyViaNotification)`,
      [
        userId,
        caretaker.relationship || '',
        caretaker.notifyViaSMS !== false ? 1 : 0,
        caretaker.notifyViaEmail !== false ? 1 : 0,
        caretaker.notifyViaNotification !== false ? 1 : 0
      ]
    );
    return id;
  } else {
    await query(
      `INSERT INTO caretakers (userId, relationship, notifyViaSMS, notifyViaEmail, notifyViaNotification)
       VALUES (?, ?, ?, ?, ?)`,
      [
        userId,
        caretaker.relationship || '',
        caretaker.notifyViaSMS !== false ? 1 : 0,
        caretaker.notifyViaEmail !== false ? 1 : 0,
        caretaker.notifyViaNotification !== false ? 1 : 0
      ]
    );
    return userId;
  }
}

async function upsertDependent(userId, dependent) {
  const id = dependent.id && Number.isInteger(Number(dependent.id)) ? Number(dependent.id) : null;

  if (id) {
    await query(
      `INSERT INTO dependents (id, userId, firstName, lastName, gender, birthDate, color)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       firstName=VALUES(firstName), lastName=VALUES(lastName), gender=VALUES(gender), 
       birthDate=VALUES(birthDate), color=VALUES(color)`,
      [
        id,
        userId,
        dependent.firstName || '',
        dependent.lastName || '',
        dependent.gender || null,
        dependent.birthDate || null,
        dependent.color || null
      ]
    );
    return id;
  } else {
    const result = await query(
      `INSERT INTO dependents (userId, firstName, lastName, gender, birthDate, color)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        userId,
        dependent.firstName || '',
        dependent.lastName || '',
        dependent.gender || null,
        dependent.birthDate || null,
        dependent.color || null
      ]
    );
    return result.insertId;
  }
}

async function upsertUserProfile(userId, profile) {
  if (!profile) return;
  
  await query(
    `INSERT INTO userProfiles (userId, firstName, lastName, gender, birthDate, zipCode, phoneNumber, email, profilePicture)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     firstName=VALUES(firstName), lastName=VALUES(lastName), gender=VALUES(gender), 
     birthDate=VALUES(birthDate), zipCode=VALUES(zipCode), phoneNumber=VALUES(phoneNumber), 
     email=VALUES(email),
     profilePicture=COALESCE(VALUES(profilePicture), profilePicture)`,
    [
      userId,
      profile.firstName || '',
      profile.lastName || '',
      profile.gender || null,
      profile.birthDate || null,
      profile.zipCode || null,
      profile.phoneNumber || null,
      profile.email || null,
      profile.profilePicture || null
    ]
  );

  if (profile.phoneNumber && String(profile.phoneNumber).trim().length > 0) {
    await query('UPDATE users SET phoneNumber = ? WHERE id = ?', [String(profile.phoneNumber).trim(), userId]);
  }
}

async function upsertDoctor(userId, doctor) {
  if (!doctor) return;
  await query(
    `INSERT INTO doctors (userId, specialization, licenseNumber, hospitalName, experience, location)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
     specialization=VALUES(specialization), licenseNumber=VALUES(licenseNumber), 
     hospitalName=VALUES(hospitalName), experience=VALUES(experience), location=VALUES(location)`,
    [
      userId,
      doctor.specialization || 'General Physician',
      doctor.licenseNumber || '',
      doctor.hospitalName || '',
      doctor.experience || '',
      doctor.location || ''
    ]
  );
}

// ----------------- API ENDPOINTS -----------------

// Registration Endpoint
app.post(['/api/auth/register', '/register'], async (req, res) => {
  const {
    fullName = '',
    email = '',
    password = '',
    phoneNumber = null,
    role = 'patient',
    gender = null,
    birthDate = null,
    zipCode = null,
    relationship = null,
    specialization = null,
    licenseNumber = null,
    hospitalName = null,
    experience = null,
    location = null
  } = req.body || {};

  const normEmail = normalizeEmail(email);
  const trimmedPassword = String(password).trim();

  // Validate Input
  if (!normEmail || !trimmedPassword || trimmedPassword.length < 6 || !fullName.trim()) {
    const errorMsg = 'Validation failed: Full Name, email and password (min 6 chars) are required';
    await logActivity({
      activityType: 'REGISTER_FAILED',
      userEmail: normEmail || 'unknown',
      description: errorMsg,
      status: 'FAILED',
      req
    });
    return res.status(400).json({ ok: false, message: errorMsg });
  }

  const validRoles = ['patient', 'caretaker', 'doctor', 'pharmacy', 'admin'];
  const userRole = validRoles.includes(role.toLowerCase()) ? role.toLowerCase() : 'patient';

  // Medical License 5-digit validation for Doctor
  if (userRole === 'doctor' && (licenseNumber !== undefined && licenseNumber !== null)) {
    if (!isValidLicense(String(licenseNumber).trim())) {
      const errorMsg = 'Medical license/registration number must be exactly 5 digits.';
      await logActivity({
        activityType: 'REGISTER_FAILED',
        userEmail: normEmail || 'unknown',
        description: errorMsg,
        status: 'FAILED',
        req
      });
      return res.status(400).json({ ok: false, message: errorMsg });
    }
  }

  // Gmail and Phone Validation for Patient, Caretaker, Doctor, and Pharmacy accounts
  if (userRole !== 'admin') {
    if (!isValidGmail(normEmail)) {
      const errorMsg = 'Please enter a valid Gmail address ending with @gmail.com.';
      await logActivity({
        activityType: 'REGISTER_FAILED',
        userEmail: normEmail || 'unknown',
        description: errorMsg,
        status: 'FAILED',
        req
      });
      return res.status(400).json({ ok: false, message: errorMsg });
    }

    if (phoneNumber && String(phoneNumber).trim().length > 0) {
      if (!isValidPhone(String(phoneNumber).trim())) {
        const errorMsg = 'Phone number must be exactly 10 digits.';
        await logActivity({
          activityType: 'REGISTER_FAILED',
          userEmail: normEmail || 'unknown',
          description: errorMsg,
          status: 'FAILED',
          req
        });
        return res.status(400).json({ ok: false, message: errorMsg });
      }
    }
  }

  try {
    // Check if email already registered
    const existing = await query('SELECT id FROM users WHERE email = ? LIMIT 1', [normEmail]);
    if (existing.length > 0) {
      const errorMsg = 'Email already registered';
      await logActivity({
        activityType: 'REGISTER_FAILED',
        userEmail: normEmail,
        description: errorMsg,
        status: 'FAILED',
        req
      });
      return res.status(409).json({ ok: false, message: errorMsg });
    }

    // Hash Password using BCrypt
    const passwordHash = await bcrypt.hash(trimmedPassword, 10);
    
    // Save to users table
    const result = await query(
      `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status)
       VALUES (?, ?, ?, ?, ?, 'active')`,
      [fullName.trim(), normEmail, phoneNumber, passwordHash, userRole]
    );
    const userId = result.insertId;

    // Create role-specific profiles
    if (userRole === 'patient') {
      await query(
        'INSERT INTO patients (userId, gender, birthDate, zipCode) VALUES (?, ?, ?, ?)',
        [userId, gender, birthDate ? parseDate(birthDate) : null, zipCode]
      );
    } else if (userRole === 'caretaker') {
      await query(
        'INSERT INTO caretakers (userId, relationship) VALUES (?, ?)',
        [userId, relationship]
      );
    } else if (userRole === 'doctor') {
      await query(
        `INSERT INTO doctors (userId, specialization, licenseNumber, hospitalName, experience, location)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [userId, specialization || 'General Physician', licenseNumber || '', hospitalName || '', experience || '', location || '']
      );
    } else if (userRole === 'pharmacy') {
      await query(
        `INSERT INTO medical_shops (userId, shopName, ownerName, phoneNumber, email, address, licenseNumber, imageUrl)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          req.body?.shopName || `${fullName.trim()}'s Pharmacy`,
          fullName.trim(),
          phoneNumber || null,
          normEmail,
          req.body?.address || null,
          req.body?.licenseNumber || licenseNumber || null,
          req.body?.imageUrl || null
        ]
      );
    } else if (userRole === 'admin') {
      await query('INSERT INTO admins (userId) VALUES (?)', [userId]);
    }

    // Always create userProfile entry in userProfiles table
    const nameParts = fullName.trim().split(' ');
    const fName = nameParts.length > 0 ? nameParts[0] : fullName.trim();
    const lName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';
    await query(
      `INSERT INTO userProfiles (userId, firstName, lastName, email, phoneNumber, gender)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       firstName=VALUES(firstName), lastName=VALUES(lastName), email=VALUES(email), phoneNumber=VALUES(phoneNumber)`,
      [userId, fName, lName, normEmail, phoneNumber, gender]
    );

    // Log Registration Activity
    await logActivity({
      userId,
      userRole,
      userName: fullName.trim(),
      userEmail: normEmail,
      activityType: 'REGISTER',
      description: `Successful user registration as ${userRole}`,
      status: 'SUCCESS',
      req
    });

    const token = jwt.sign(
      { id: userId, email: normEmail, role: userRole, isAdmin: userRole === 'admin' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      ok: true,
      message: 'Registration successful',
      token,
      data: {
        id: userId,
        email: normEmail,
        fullName: fullName.trim(),
        role: userRole
      }
    });
  } catch (error) {
    await logActivity({
      activityType: 'REGISTER_FAILED',
      userEmail: normEmail,
      description: `Registration failed with error: ${error.message}`,
      status: 'FAILED',
      req
    });
    return res.status(500).json({ ok: false, message: 'Registration failed', error: error.message });
  }
});

// Login Endpoint
app.post(['/api/auth/login', '/login'], async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || '').trim();
  const ipAddress = getClientIp(req);
  const userAgent = req.headers['user-agent'] || '';
  const { device, browser, os } = parseUserAgent(userAgent);

  if (!email || !password) {
    await logActivity({
      activityType: 'LOGIN_FAILED',
      userEmail: email || 'unknown',
      description: 'Email and password are required',
      status: 'FAILED',
      req
    });
    return res.status(400).json({ ok: false, message: 'Email and password are required' });
  }

  // Gmail Validation for Patient & Caretaker logins (Admin logins bypass)
  if (!isAdminEmail(email) && !isValidGmail(email)) {
    const adminCheck = await query('SELECT id FROM users WHERE email = ? AND role = "admin" LIMIT 1', [email]);
    if (adminCheck.length === 0) {
      const errorMsg = 'Please enter a valid Gmail address ending with @gmail.com.';
      await logActivity({
        activityType: 'LOGIN_FAILED',
        userEmail: email,
        description: errorMsg,
        status: 'FAILED',
        req
      });
      return res.status(400).json({ ok: false, message: errorMsg });
    }
  }

  try {
    const rows = await query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    const user = rows[0];

    // Verify Credentials
    if (!user) {
      await logActivity({
        activityType: 'LOGIN_FAILED',
        userEmail: email,
        description: 'Login failed: Account not found',
        status: 'FAILED',
        req
      });
      return res.status(401).json({ ok: false, message: 'Invalid credentials' });
    }

    if (user.status !== 'active') {
      await logActivity({
        userId: user.id,
        userRole: user.role,
        userName: user.fullName,
        userEmail: user.email,
        activityType: 'LOGIN_FAILED',
        description: 'Login failed: Account is suspended',
        status: 'FAILED',
        req
      });
      return res.status(403).json({ ok: false, message: 'Account is suspended' });
    }

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      await logActivity({
        userId: user.id,
        userRole: user.role,
        userName: user.fullName,
        userEmail: user.email,
        activityType: 'LOGIN_FAILED',
        description: 'Login failed: Incorrect password',
        status: 'FAILED',
        req
      });
      return res.status(401).json({ ok: false, message: 'Invalid credentials' });
    }

    // Create JWT Session
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
        isAdmin: user.role === 'admin'
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Save Session record
    const sessionRes = await query(
      `INSERT INTO user_sessions (userId, token, ipAddress, device, browser, operatingSystem, loginAt)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [user.id, token, ipAddress, device, browser, os]
    );
    const sessionId = sessionRes.insertId;

    // Update last login
    await query('UPDATE users SET lastLoginAt = NOW() WHERE id = ?', [user.id]);

    // Record Login Activity
    await logActivity({
      userId: user.id,
      userRole: user.role,
      userName: user.fullName,
      userEmail: user.email,
      activityType: 'LOGIN',
      description: 'Successful login session started',
      status: 'SUCCESS',
      sessionId,
      req
    });

    return res.status(200).json({
      ok: true,
      token,
      data: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        status: user.status,
        lastLoginAt: user.lastLoginAt
      }
    });
  } catch (error) {
    await logActivity({
      activityType: 'LOGIN_FAILED',
      userEmail: email,
      description: `Internal login failed: ${error.message}`,
      status: 'FAILED',
      req
    });
    return res.status(500).json({ ok: false, message: 'Login failed', error: error.message });
  }
});

// Logout Endpoint
app.post(['/api/auth/logout', '/logout'], authenticateToken, async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  try {
    const sessions = await query(
      'SELECT id, loginAt FROM user_sessions WHERE token = ? AND logoutAt IS NULL LIMIT 1',
      [token]
    );
    
    let sessionDuration = 0;
    let sessionId = null;
    
    if (sessions.length > 0) {
      sessionId = sessions[0].id;
      const loginTime = new Date(sessions[0].loginAt);
      const now = new Date();
      sessionDuration = Math.max(0, Math.floor((now.getTime() - loginTime.getTime()) / 1000));
      
      // Update session logout time and duration
      await query(
        `UPDATE user_sessions 
         SET logoutAt = NOW(), sessionDuration = ? 
         WHERE id = ?`,
        [sessionDuration, sessionId]
      );
    }

    // Record Logout Activity
    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'LOGOUT',
      description: `Successful logout. Session Duration: ${sessionDuration} seconds`,
      status: 'SUCCESS',
      sessionId,
      req
    });

    return res.status(200).json({ ok: true, message: 'Logout successful' });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Logout failed', error: error.message });
  }
});

// Sync data endpoint
app.post('/api/sync/all', authenticateTokenOrFallback, async (req, res) => {
  const {
    userId = 'guest',
    userProfile = null,
    medicines = [],
    reminders = [],
    alarmLogs = [],
    caretakers = [],
  } = req.body || {};
  
  const idStr = req.user ? req.user.id : await resolveUserId(userId);
  if (!idStr) {
    return res.status(400).json({ ok: false, message: 'Invalid or unknown user ID for sync' });
  }

  try {
    await upsertUserProfile(idStr, userProfile);
    for (const medicine of medicines) {
      await upsertMedicine(idStr, medicine || {});
    }
    for (const reminder of reminders) {
      await upsertReminder(idStr, reminder || {});
    }
    for (const alarmLog of alarmLogs) {
      await upsertAlarmLog(idStr, alarmLog || {});
    }
    for (const caretaker of caretakers) {
      await upsertCaretaker(idStr, caretaker || {});
    }

    await logActivity({
      userId: idStr,
      userEmail: req.user ? req.user.email : String(userId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'SYNC',
      description: `Sync data: ${medicines.length} medicines, ${reminders.length} reminders`,
      status: 'SUCCESS',
      req
    });

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

// Medicines CRUD
app.post('/api/medicines', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const id = await upsertMedicine(userId, req.body || {}, req.user?.id);
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'ADD_MEDICINE',
      description: `Added medicine schedule: ${req.body?.name || 'Unnamed'}`,
      status: 'SUCCESS',
      req
    });
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/medicines', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query('SELECT * FROM medicines WHERE userId = ? ORDER BY id DESC', [userId]);
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'VIEW_MEDICINE',
      description: 'Viewed medicine schedule details list',
      status: 'SUCCESS',
      req
    });
    res.json({ ok: true, data: rows.map(medicineToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/medicines/:id', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  const id = Number(req.params.id);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    await upsertMedicine(userId, { ...(req.body || {}), id }, req.user?.id);
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'EDIT_MEDICINE',
      description: `Edited medicine details: ${req.body?.name || 'Unnamed'}`,
      status: 'SUCCESS',
      req
    });
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/medicines/:id', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  const id = Number(req.params.id);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const medicineRes = await query('DELETE FROM medicines WHERE userId = ? AND id = ?', [userId, id]);
    await query('DELETE FROM reminders WHERE userId = ? AND medicineId = ?', [userId, id]);
    await query('DELETE FROM alarmLogs WHERE userId = ? AND medicineId = ?', [userId, id]);

    if (medicineRes.affectedRows === 0) {
      return res.status(404).json({ ok: false, error: 'Medicine not found' });
    }

    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'DELETE_MEDICINE',
      description: `Deleted medicine schedule ID: ${id}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Reminders
app.post('/api/reminders', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const id = await upsertReminder(userId, req.body || {});
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'UPDATE_REMINDER',
      description: `Scheduled reminder time: ${req.body?.time || '08:00 AM'}`,
      status: 'SUCCESS',
      req
    });
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/reminders', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query('SELECT * FROM reminders WHERE userId = ? ORDER BY id DESC', [userId]);
    res.json({ ok: true, data: rows.map(reminderToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/reminders/:id', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  const id = Number(req.params.id);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    await query('DELETE FROM reminders WHERE userId = ? AND id = ?', [userId, id]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Alarm logs
app.post('/api/alarm-logs', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const id = await upsertAlarmLog(userId, req.body || {});
    const actionType = req.body?.status === 'taken' ? 'MARK_MEDICINE_TAKEN' : (req.body?.status === 'skipped' ? 'SKIP_MEDICINE' : 'ALARM_TRIGGERED');
    
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: actionType,
      description: `Action logged on medicine: ${req.body?.medicineName || 'Unnamed'} status: ${req.body?.status || 'pending'}`,
      status: 'SUCCESS',
      req
    });

    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/alarm-logs', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query('SELECT * FROM alarmLogs WHERE userId = ? ORDER BY id DESC', [userId]);
    res.json({ ok: true, data: rows.map(alarmLogToDto) });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Caretakers
app.post('/api/caretakers', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  if (req.body?.email && String(req.body.email).trim().length > 0) {
    if (!isValidGmail(String(req.body.email).trim())) {
      return res.status(400).json({
        ok: false,
        message: 'Please enter a valid Gmail address ending with @gmail.com.'
      });
    }
  }

  const phone = req.body?.phoneNumber || req.body?.phone;
  if (phone && String(phone).trim().length > 0) {
    if (!isValidPhone(String(phone).trim())) {
      return res.status(400).json({
        ok: false,
        message: 'Phone number must be exactly 10 digits.'
      });
    }
  }

  try {
    const id = await upsertCaretaker(userId, req.body || {});
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'INVITE_CARETAKER',
      description: `Invited caretaker: ${req.body?.email || 'Unnamed'}`,
      status: 'SUCCESS',
      req
    });
    res.status(200).json({ ok: true, id });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/caretakers', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query(
      `SELECT c.*, u.fullName, u.email as caretakerEmail, u.phoneNumber 
       FROM caretakers c 
       JOIN users u ON c.userId = u.id`,
      []
    );
    res.json({ ok: true, data: rows });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/caretakers/:id', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  const id = Number(req.params.id);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    await query('DELETE FROM caretakers WHERE userId = ?', [id]);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Profile & Settings
app.post('/api/user-profile', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  const role = req.user?.role || 'patient';
  if (role !== 'admin') {
    if (req.body?.email && String(req.body.email).trim().length > 0) {
      if (!isValidGmail(String(req.body.email).trim())) {
        return res.status(400).json({
          ok: false,
          message: 'Please enter a valid Gmail address ending with @gmail.com.'
        });
      }
    }

    const phone = req.body?.phoneNumber || req.body?.mobileNumber;
    if (phone && String(phone).trim().length > 0) {
      if (!isValidPhone(String(phone).trim())) {
        return res.status(400).json({
          ok: false,
          message: 'Phone number must be exactly 10 digits.'
        });
      }
    }
  }

  try {
    await upsertUserProfile(userId, req.body || {});
    await logActivity({
      userId,
      userEmail: req.user ? req.user.email : String(inputUserId),
      userRole: req.user ? req.user.role : 'patient',
      activityType: 'UPDATE_PROFILE',
      description: `Updated profile details`,
      status: 'SUCCESS',
      req
    });
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/user-profile/:userId', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.params.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query(
      `SELECT up.*, u.fullName, u.email as userEmail, u.phoneNumber 
       FROM userProfiles up 
       JOIN users u ON up.userId = u.id 
       WHERE up.userId = ? LIMIT 1`, 
      [userId]
    );
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
        email: profile.userEmail,
        profilePicture: profile.profilePicture || null,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      },
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Multipart Profile Photo Upload (Patient, Caretaker, Doctor, Admin)
app.post(['/api/user-profile/photo', '/api/profile/photo'], authenticateToken, (req, res) => {
  profileUpload.single('photo')(req, res, async (err) => {
    if (err) {
      const isSize = err.code === 'LIMIT_FILE_SIZE';
      return res.status(400).json({
        ok: false,
        message: isSize
          ? 'Image size is too large. Maximum size allowed is 5MB.'
          : (err.message || 'Please select a valid image file (.jpg, .jpeg, .png, .webp).')
      });
    }

    if (!req.file) {
      return res.status(400).json({
        ok: false,
        message: 'No photo file provided. Please select an image.'
      });
    }

    const userId = req.user.id;
    const relativePath = `/uploads/profiles/${req.file.filename}`;

    try {
      // Find old photo to delete safely if it exists in local storage
      const oldRows = await query('SELECT profilePicture FROM userProfiles WHERE userId = ? LIMIT 1', [userId]);
      if (oldRows.length > 0 && oldRows[0].profilePicture) {
        const oldPath = oldRows[0].profilePicture;
        if (oldPath.startsWith('/uploads/profiles/')) {
          const oldFull = path.join(__dirname, '..', oldPath.replace(/^\//, ''));
          fs.unlink(oldFull, () => {}); // Non-blocking cleanup
        }
      }

      // Update userProfiles with new photo path
      await query(
        `INSERT INTO userProfiles (userId, profilePicture)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE profilePicture = VALUES(profilePicture)`,
        [userId, relativePath]
      );

      await logActivity({
        userId,
        userEmail: req.user.email,
        userRole: req.user.role,
        activityType: 'UPDATE_PROFILE_PHOTO',
        description: 'Uploaded and updated profile photo',
        status: 'SUCCESS',
        req
      });

      const protocol = req.protocol || 'http';
      const host = req.get('host') || `localhost:${port}`;
      const fullUrl = `${protocol}://${host}${relativePath}`;

      return res.status(200).json({
        ok: true,
        message: 'Profile photo uploaded successfully.',
        profilePicture: relativePath,
        photoUrl: fullUrl
      });
    } catch (dbError) {
      return res.status(500).json({ ok: false, error: dbError.message });
    }
  });
});

// Remove Profile Photo
app.delete(['/api/user-profile/photo', '/api/profile/photo'], authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    const oldRows = await query('SELECT profilePicture FROM userProfiles WHERE userId = ? LIMIT 1', [userId]);
    if (oldRows.length > 0 && oldRows[0].profilePicture) {
      const oldPath = oldRows[0].profilePicture;
      if (oldPath.startsWith('/uploads/profiles/')) {
        const oldFull = path.join(__dirname, '..', oldPath.replace(/^\//, ''));
        fs.unlink(oldFull, () => {});
      }
    }

    await query('UPDATE userProfiles SET profilePicture = NULL WHERE userId = ?', [userId]);

    await logActivity({
      userId,
      userEmail: req.user.email,
      userRole: req.user.role,
      activityType: 'REMOVE_PROFILE_PHOTO',
      description: 'Removed profile photo',
      status: 'SUCCESS',
      req
    });

    return res.status(200).json({ ok: true, message: 'Profile photo removed successfully.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/settings', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.body?.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  const { key, value } = req.body || {};
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });
  if (!key || value === undefined) {
    return res.status(400).json({ ok: false, message: 'key and value are required' });
  }

  try {
    await query(
      `INSERT INTO settings (userId, keyName, value, updatedAt) 
       VALUES (?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE value = VALUES(value), updatedAt = NOW()`,
      [userId, String(key), String(value)]
    );
    return res.status(200).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/settings', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.query.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, error: 'User mapping failed' });

  try {
    const rows = await query('SELECT * FROM settings WHERE userId = ?', [userId]);
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
    return res.status(502).json({ ok: false, message: 'Drug lookup failed', error: error.message });
  }
});

// Barcode Lookup logic
const barcodeOverrides = {
  '8901234567890': { expiryDate: '2026-12-31', healthCondition: 'Fever / pain relief' },
  '012345678905': { expiryDate: '2026-06-30', healthCondition: 'Allergy relief' },
  '4902430780006': { expiryDate: '2026-09-30', healthCondition: 'Cough / cold relief' },
};

async function lookupDrugByBarcode(barcodeDigits) {
  const baseUrl = process.env.OPENFDA_BASE_URL || 'https://api.fda.gov';
  const apiKey = process.env.OPENFDA_API_KEY || '';

  const toNdcCandidates = (digits) => {
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
  };

  const getJson = (url) => {
    return new Promise((resolve, reject) => {
      https.get(url, (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
          if (res.statusCode < 200 || res.statusCode >= 300) return resolve(null);
          try { resolve(JSON.parse(body)); } catch (_) { resolve(null); }
        });
      }).on('error', reject);
    });
  };

  for (const ndc of toNdcCandidates(barcodeDigits)) {
    const queryText = `product_ndc:"${ndc}"+OR+package_ndc:"${ndc}"`;
    const params = new URLSearchParams({ search: queryText, limit: '1' });
    if (apiKey) params.set('api_key', apiKey);

    const body = await getJson(`${baseUrl}/drug/ndc.json?${params.toString()}`);
    const first = Array.isArray(body?.results) ? body.results[0] : null;
    if (!first || typeof first !== 'object') continue;

    const name = (first.brand_name || first.generic_name || first.labeler_name || 'Unknown medicine').trim();
    const ingredient = Array.isArray(first.active_ingredients) ? first.active_ingredients[0] : null;
    const dosage = (ingredient?.strength || 'N/A').toString().trim() || 'N/A';
    const dosageForm = String(first.dosage_form || '').toLowerCase();
    const category = dosageForm.includes('inject') ? 'injection' : (dosageForm.includes('solution') || dosageForm.includes('syrup') || dosageForm.includes('liquid') ? 'syrup' : 'tablets');
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

// ----------------- DOCTOR & CONNECTION APIs -----------------

// Doctor Search API (for Patients and Caretakers, or public lookup)
app.get('/api/doctors', authenticateTokenOrFallback, async (req, res) => {
  const { name = '', specialization = '', hospital = '', location = '', search = '' } = req.query;
  const currentUserId = req.user ? req.user.id : null;

  let sql = `
    SELECT 
      u.id, 
      u.fullName, 
      u.email, 
      u.phoneNumber, 
      COALESCE(d.specialization, 'General Physician') AS specialization, 
      COALESCE(d.licenseNumber, '') AS licenseNumber, 
      COALESCE(d.hospitalName, '') AS hospitalName, 
      COALESCE(d.experience, '') AS experience, 
      COALESCE(d.location, '') AS location
    FROM users u
    LEFT JOIN doctors d ON u.id = d.userId
    WHERE u.role = 'doctor' AND u.status = 'active'
  `;
  const params = [];

  if (search && search.trim()) {
    const term = `%${search.trim()}%`;
    sql += ` AND (u.fullName LIKE ? OR d.specialization LIKE ? OR d.hospitalName LIKE ? OR d.location LIKE ?)`;
    params.push(term, term, term, term);
  }
  if (name && name.trim()) {
    sql += ` AND u.fullName LIKE ?`;
    params.push(`%${name.trim()}%`);
  }
  if (specialization && specialization.trim() && specialization.toLowerCase() !== 'all') {
    sql += ` AND d.specialization LIKE ?`;
    params.push(`%${specialization.trim()}%`);
  }
  if (hospital && hospital.trim()) {
    sql += ` AND d.hospitalName LIKE ?`;
    params.push(`%${hospital.trim()}%`);
  }
  if (location && location.trim()) {
    sql += ` AND d.location LIKE ?`;
    params.push(`%${location.trim()}%`);
  }

  sql += ' ORDER BY u.fullName ASC';

  try {
    const doctors = await query(sql, params);

    // If requester is logged in, attach connectionStatus & connectionId
    if (currentUserId) {
      const connRows = await query(
        `SELECT id, doctorId, status FROM doctor_connections WHERE requesterId = ?`,
        [currentUserId]
      );
      const connMap = new Map();
      for (const c of connRows) {
        connMap.set(c.doctorId, { id: c.id, status: c.status });
      }

      const result = doctors.map(doc => {
        const conn = connMap.get(doc.id);
        return {
          ...doc,
          connectionStatus: conn ? conn.status : 'none',
          connectionId: conn ? conn.id : null,
        };
      });
      return res.json({ ok: true, data: result });
    }

    return res.json({
      ok: true,
      data: doctors.map(doc => ({
        ...doc,
        connectionStatus: 'none',
        connectionId: null,
      }))
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Send Doctor Connection Request (Patient or Caretaker -> Doctor)
app.post('/api/doctor-connections', authenticateToken, requireRole(['patient', 'caretaker']), async (req, res) => {
  const doctorId = Number(req.body?.doctorId);
  const requesterId = req.user.id;
  const requesterRole = req.user.role;

  if (!doctorId || Number.isNaN(doctorId)) {
    return res.status(400).json({ ok: false, message: 'Valid doctorId is required' });
  }

  if (doctorId === requesterId) {
    return res.status(400).json({ ok: false, message: 'You cannot connect with yourself.' });
  }

  try {
    // Verify doctor exists and has role 'doctor'
    const docRows = await query('SELECT id, fullName, email, role FROM users WHERE id = ? LIMIT 1', [doctorId]);
    if (docRows.length === 0 || docRows[0].role !== 'doctor') {
      return res.status(404).json({ ok: false, message: 'Doctor not found or invalid doctor account.' });
    }

    // Check existing connection
    const existing = await query(
      'SELECT id, status FROM doctor_connections WHERE doctorId = ? AND requesterId = ? LIMIT 1',
      [doctorId, requesterId]
    );

    if (existing.length > 0) {
      const currentStatus = existing[0].status;
      if (currentStatus === 'pending') {
        return res.status(400).json({
          ok: false,
          message: 'You have already sent a connection request to this doctor.'
        });
      }
      if (currentStatus === 'accepted') {
        return res.status(400).json({
          ok: false,
          message: 'You are already connected with this doctor.'
        });
      }
      if (currentStatus === 'rejected') {
        // Re-request: update back to pending
        await query(
          'UPDATE doctor_connections SET status = "pending", requesterRole = ?, updatedAt = NOW() WHERE id = ?',
          [requesterRole, existing[0].id]
        );
        await logActivity({
          userId: requesterId,
          userRole: requesterRole,
          userEmail: req.user.email,
          activityType: 'DOCTOR_CONNECT_REQUEST',
          description: `Re-sent doctor connection request to Dr. ${docRows[0].fullName}`,
          status: 'SUCCESS',
          req
        });
        return res.status(200).json({
          ok: true,
          message: 'Doctor connection request sent successfully.',
          data: { id: existing[0].id, status: 'pending' }
        });
      }
    }

    // Insert new pending connection
    const insertRes = await query(
      `INSERT INTO doctor_connections (doctorId, requesterId, requesterRole, status)
       VALUES (?, ?, ?, 'pending')`,
      [doctorId, requesterId, requesterRole]
    );

    await logActivity({
      userId: requesterId,
      userRole: requesterRole,
      userEmail: req.user.email,
      activityType: 'DOCTOR_CONNECT_REQUEST',
      description: `Sent doctor connection request to Dr. ${docRows[0].fullName}`,
      status: 'SUCCESS',
      req
    });

    return res.status(200).json({
      ok: true,
      message: 'Doctor connection request sent successfully.',
      data: { id: insertRes.insertId, status: 'pending' }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Failed to send connection request', error: error.message });
  }
});

// View Doctor's Incoming Requests (Doctor only)
app.get('/api/doctor-connections/requests', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;
  const { status = 'pending' } = req.query;

  try {
    let sql = `
      SELECT 
        dc.id, 
        dc.doctorId, 
        dc.requesterId, 
        dc.requesterRole, 
        dc.status, 
        dc.createdAt, 
        dc.updatedAt,
        u.fullName as requesterName,
        u.email as requesterEmail,
        u.phoneNumber as requesterPhone,
        up.gender as requesterGender,
        up.birthDate as requesterBirthDate
      FROM doctor_connections dc
      JOIN users u ON dc.requesterId = u.id
      LEFT JOIN userProfiles up ON u.id = up.userId
      WHERE dc.doctorId = ?
    `;
    const params = [doctorId];

    if (status && status !== 'all') {
      sql += ' AND dc.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY dc.id DESC';

    const rows = await query(sql, params);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Accept Doctor Connection Request (Doctor only)
app.put('/api/doctor-connections/:id/accept', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const id = Number(req.params.id);
  const doctorId = req.user.id;

  try {
    const rows = await query('SELECT * FROM doctor_connections WHERE id = ? AND doctorId = ? LIMIT 1', [id, doctorId]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Connection request not found or unauthorized.' });
    }

    await query('UPDATE doctor_connections SET status = "accepted", updatedAt = NOW() WHERE id = ?', [id]);

    await logActivity({
      userId: doctorId,
      userRole: 'doctor',
      userEmail: req.user.email,
      activityType: 'ACCEPT_DOCTOR_REQUEST',
      description: `Doctor accepted connection request ID: ${id}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Doctor connection request accepted.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Reject Doctor Connection Request (Doctor only)
app.put('/api/doctor-connections/:id/reject', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const id = Number(req.params.id);
  const doctorId = req.user.id;

  try {
    const rows = await query('SELECT * FROM doctor_connections WHERE id = ? AND doctorId = ? LIMIT 1', [id, doctorId]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Connection request not found or unauthorized.' });
    }

    await query('UPDATE doctor_connections SET status = "rejected", updatedAt = NOW() WHERE id = ?', [id]);

    await logActivity({
      userId: doctorId,
      userRole: 'doctor',
      userEmail: req.user.email,
      activityType: 'REJECT_DOCTOR_REQUEST',
      description: `Doctor rejected connection request ID: ${id}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Doctor connection request rejected.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Get Connected Doctors for logged-in Patient/Caretaker
app.get('/api/doctor-connections/my-doctors', authenticateToken, requireRole(['patient', 'caretaker']), async (req, res) => {
  const requesterId = req.user.id;

  try {
    const sql = `
      SELECT 
        dc.id as connectionId,
        dc.status as connectionStatus,
        dc.createdAt as connectedAt,
        u.id as doctorId,
        u.fullName,
        u.email,
        u.phoneNumber,
        COALESCE(d.specialization, 'General Physician') as specialization,
        COALESCE(d.licenseNumber, '') as licenseNumber,
        COALESCE(d.hospitalName, '') as hospitalName,
        COALESCE(d.experience, '') as experience,
        COALESCE(d.location, '') as location
      FROM doctor_connections dc
      JOIN users u ON dc.doctorId = u.id
      LEFT JOIN doctors d ON u.id = d.userId
      WHERE dc.requesterId = ? AND dc.status = 'accepted'
      ORDER BY dc.updatedAt DESC
    `;
    const rows = await query(sql, [requesterId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Get Connected Patients for logged-in Doctor
app.get('/api/doctor-connections/my-patients', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;

  try {
    const sql = `
      SELECT 
        dc.id as connectionId,
        dc.createdAt as connectedAt,
        u.id as patientId,
        u.fullName,
        u.email,
        u.phoneNumber,
        up.gender,
        up.birthDate,
        up.zipCode
      FROM doctor_connections dc
      JOIN users u ON dc.requesterId = u.id
      LEFT JOIN userProfiles up ON u.id = up.userId
      WHERE dc.doctorId = ? AND dc.requesterRole = 'patient' AND dc.status = 'accepted'
      ORDER BY dc.updatedAt DESC
    `;
    const rows = await query(sql, [doctorId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Get Connected Caretakers for logged-in Doctor
app.get('/api/doctor-connections/my-caretakers', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;

  try {
    const sql = `
      SELECT 
        dc.id as connectionId,
        dc.createdAt as connectedAt,
        u.id as caretakerId,
        u.fullName,
        u.email,
        u.phoneNumber,
        c.relationship
      FROM doctor_connections dc
      JOIN users u ON dc.requesterId = u.id
      LEFT JOIN caretakers c ON u.id = c.userId
      WHERE dc.doctorId = ? AND dc.requesterRole = 'caretaker' AND dc.status = 'accepted'
      ORDER BY dc.updatedAt DESC
    `;
    const rows = await query(sql, [doctorId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Get All Connected Users (Patients & Caretakers) for logged-in Doctor
app.get('/api/doctor-connections/my-connections', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;

  try {
    const [patients, caretakers] = await Promise.all([
      query(
        `SELECT 
          dc.id as connectionId,
          dc.createdAt as connectedAt,
          u.id as patientId,
          u.fullName,
          u.email,
          u.phoneNumber,
          up.gender,
          up.birthDate,
          up.zipCode
        FROM doctor_connections dc
        JOIN users u ON dc.requesterId = u.id
        LEFT JOIN userProfiles up ON u.id = up.userId
        WHERE dc.doctorId = ? AND dc.requesterRole = 'patient' AND dc.status = 'accepted'
        ORDER BY dc.updatedAt DESC`,
        [doctorId]
      ),
      query(
        `SELECT 
          dc.id as connectionId,
          dc.createdAt as connectedAt,
          u.id as caretakerId,
          u.fullName,
          u.email,
          u.phoneNumber,
          c.relationship
        FROM doctor_connections dc
        JOIN users u ON dc.requesterId = u.id
        LEFT JOIN caretakers c ON u.id = c.userId
        WHERE dc.doctorId = ? AND dc.requesterRole = 'caretaker' AND dc.status = 'accepted'
        ORDER BY dc.updatedAt DESC`,
        [doctorId]
      )
    ]);

    return res.json({ ok: true, data: { patients, caretakers } });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete or cancel doctor connection (by Patient, Caretaker, or Doctor)
app.delete('/api/doctor-connections/:id', authenticateToken, async (req, res) => {
  const id = Number(req.params.id);
  const userId = req.user.id;

  try {
    const rows = await query('SELECT * FROM doctor_connections WHERE id = ? LIMIT 1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Connection not found.' });
    }
    const conn = rows[0];
    if (conn.doctorId !== userId && conn.requesterId !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ ok: false, message: 'Unauthorized to delete this connection.' });
    }

    await query('DELETE FROM doctor_connections WHERE id = ?', [id]);
    return res.json({ ok: true, message: 'Connection removed successfully.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Doctor Profile Upsert (Doctor or Admin)
app.post('/api/doctor/profile', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
  const targetUserId = req.user.role === 'admin' && req.body?.userId ? Number(req.body.userId) : req.user.id;
  const {
    specialization = '',
    licenseNumber = '',
    hospitalName = '',
    experience = '',
    location = '',
    fullName = '',
    phoneNumber = ''
  } = req.body || {};

  if (phoneNumber && String(phoneNumber).trim().length > 0) {
    if (!isValidPhone(String(phoneNumber).trim())) {
      return res.status(400).json({ ok: false, message: 'Phone number must be exactly 10 digits.' });
    }
  }

  if (licenseNumber !== undefined && licenseNumber !== null) {
    if (!isValidLicense(String(licenseNumber).trim())) {
      return res.status(400).json({
        ok: false,
        message: 'Medical license/registration number must be exactly 5 digits.'
      });
    }
  }

  try {
    await upsertDoctor(targetUserId, { specialization, licenseNumber, hospitalName, experience, location });
    if (fullName && fullName.trim()) {
      await query('UPDATE users SET fullName = ? WHERE id = ?', [fullName.trim(), targetUserId]);
    }
    if (phoneNumber && String(phoneNumber).trim().length > 0) {
      await query('UPDATE users SET phoneNumber = ? WHERE id = ?', [String(phoneNumber).trim(), targetUserId]);
      await query('UPDATE userProfiles SET phoneNumber = ? WHERE userId = ?', [String(phoneNumber).trim(), targetUserId]);
    }

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'UPDATE_DOCTOR_PROFILE',
      description: `Updated doctor profile details for user ID ${targetUserId}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Doctor profile updated successfully.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Doctor Profile Fetch by userId
app.get('/api/doctor/profile/:userId', authenticateTokenOrFallback, async (req, res) => {
  const inputUserId = req.params.userId;
  const userId = req.user ? req.user.id : await resolveUserId(inputUserId);
  if (!userId) return res.status(400).json({ ok: false, message: 'User mapping failed' });

  try {
    const rows = await query(
      `SELECT u.id, u.fullName, u.email, u.phoneNumber, u.role,
              COALESCE(d.specialization, 'General Physician') as specialization, 
              COALESCE(d.licenseNumber, '') as licenseNumber, 
              COALESCE(d.hospitalName, '') as hospitalName, 
              COALESCE(d.experience, '') as experience, 
              COALESCE(d.location, '') as location
       FROM users u
       LEFT JOIN doctors d ON u.id = d.userId
       WHERE u.id = ? LIMIT 1`,
      [userId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Doctor not found' });
    }
    return res.json({ ok: true, data: rows[0] });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// ----------------- ADMINISTRATIVE CONTROL APIs -----------------

// Admin Dashboard stats
app.get('/api/admin/stats', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const [
      usersCount,
      patientsCount,
      caretakersCount,
      doctorsCount,
      adminsCount,
      todayRegistrationsCount,
      todayLoginsCount,
      activeSessionsCount,
      failedLoginsCount,
      recentLogs
    ] = await Promise.all([
      query("SELECT COUNT(*) as count FROM users"),
      query("SELECT COUNT(*) as count FROM users WHERE role = 'patient'"),
      query("SELECT COUNT(*) as count FROM users WHERE role = 'caretaker'"),
      query("SELECT COUNT(*) as count FROM users WHERE role = 'doctor'"),
      query("SELECT COUNT(*) as count FROM users WHERE role = 'admin'"),
      query("SELECT COUNT(*) as count FROM users WHERE createdAt >= CURDATE()"),
      query("SELECT COUNT(*) as count FROM user_sessions WHERE loginAt >= CURDATE()"),
      query("SELECT COUNT(*) as count FROM user_sessions WHERE logoutAt IS NULL"),
      query("SELECT COUNT(*) as count FROM activity_logs WHERE activityType = 'LOGIN_FAILED' AND timestamp >= CURDATE()"),
      query("SELECT * FROM activity_logs ORDER BY id DESC LIMIT 50")
    ]);

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userName: 'Admin',
      userEmail: req.user.email,
      activityType: 'VIEW_DASHBOARD',
      description: 'Admin viewed stats dashboard',
      status: 'SUCCESS',
      req
    });

    return res.status(200).json({
      ok: true,
      data: {
        totalRegisteredUsers: Number(usersCount[0].count || 0),
        totalPatients: Number(patientsCount[0].count || 0),
        totalCaretakers: Number(caretakersCount[0].count || 0),
        totalDoctors: Number(doctorsCount[0].count || 0),
        totalAdmins: Number(adminsCount[0].count || 0),
        todayRegistrations: Number(todayRegistrationsCount[0].count || 0),
        todayLogins: Number(todayLoginsCount[0].count || 0),
        activeSessions: Number(activeSessionsCount[0].count || 0),
        failedLoginAttempts: Number(failedLoginsCount[0].count || 0),
        recentActivities: recentLogs
      }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, message: 'Stats lookup failed', error: error.message });
  }
});

// Admin User list
app.get('/api/admin/users', authenticateToken, requireRole(['admin']), async (req, res) => {
  const { role = '', search = '' } = req.query;
  let sql = `
    SELECT id, fullName, email, phoneNumber, role, status, lastLoginAt, createdAt, updatedAt 
    FROM users
  `;
  const params = [];
  const conditions = [];
  
  if (role && role !== 'All') {
    conditions.push('role = ?');
    params.push(role.toLowerCase());
  }
  if (search) {
    conditions.push('(fullName LIKE ? OR email LIKE ? OR phoneNumber LIKE ?)');
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  
  if (conditions.length > 0) {
    sql += ` WHERE ${conditions.join(' AND ')}`;
  }
  
  sql += ' ORDER BY id DESC';
  
  try {
    const rows = await query(sql, params);
    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'MANAGE_USERS',
      description: 'Admin queried users list',
      status: 'SUCCESS',
      req
    });
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Admin User: Activate/Deactivate
app.put('/api/admin/users/:id/status', authenticateToken, requireRole(['admin']), async (req, res) => {
  const id = Number(req.params.id);
  const { status } = req.body || {};
  
  if (!['active', 'inactive'].includes(status)) {
    return res.status(400).json({ ok: false, message: 'Invalid status' });
  }
  
  try {
    const rows = await query('SELECT email, role FROM users WHERE id = ? LIMIT 1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'User not found' });
    }
    
    await query('UPDATE users SET status = ? WHERE id = ?', [status, id]);
    
    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'ACTIVATE_DEACTIVATE_USER',
      description: `Set status of user ${rows[0].email} to ${status}`,
      status: 'SUCCESS',
      req
    });
    
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Admin User: Reset Password
app.post('/api/admin/users/:id/reset-password', authenticateToken, requireRole(['admin']), async (req, res) => {
  const id = Number(req.params.id);
  const { password } = req.body || {};
  
  if (!password || password.length < 6) {
    return res.status(400).json({ ok: false, message: 'Password must be at least 6 characters' });
  }
  
  try {
    const rows = await query('SELECT email FROM users WHERE id = ? LIMIT 1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'User not found' });
    }
    
    const passwordHash = await bcrypt.hash(password, 10);
    await query('UPDATE users SET passwordHash = ? WHERE id = ?', [passwordHash, id]);
    
    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'RESET_PASSWORD',
      description: `Reset password for user ${rows[0].email}`,
      status: 'SUCCESS',
      req
    });
    
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Admin Activity logs history listing
app.get('/api/admin/activity-logs', authenticateToken, requireRole(['admin']), async (req, res) => {
  const {
    user = '',
    role = '',
    type = '',
    startDate = '',
    endDate = '',
    sortBy = 'timestamp',
    order = 'DESC',
    page = 1,
    limit = 10
  } = req.query;

  const pageNum = Math.max(1, Number(page || 1));
  const limitNum = Math.max(1, Number(limit || 10));
  const offset = (pageNum - 1) * limitNum;

  const conditions = [];
  const params = [];

  if (user) {
    conditions.push('(userEmail LIKE ? OR userName LIKE ? OR description LIKE ?)');
    params.push(`%${user}%`, `%${user}%`, `%${user}%`);
  }

  if (role) {
    conditions.push('userRole = ?');
    params.push(role.toLowerCase());
  }

  if (startDate) {
    conditions.push('timestamp >= ?');
    params.push(startDate);
  }

  if (endDate) {
    conditions.push('timestamp <= ?');
    params.push(`${endDate} 23:59:59`);
  }

  // Handle history categories
  if (type) {
    if (type === 'LoginHistory') {
      conditions.push('activityType IN (?, ?)');
      params.push('LOGIN', 'LOGIN_FAILED');
    } else if (type === 'RegistrationHistory') {
      conditions.push('activityType IN (?, ?)');
      params.push('REGISTER', 'REGISTER_FAILED');
    } else if (type === 'LogoutHistory') {
      conditions.push('activityType = ?');
      params.push('LOGOUT');
    } else {
      conditions.push('activityType = ?');
      params.push(type);
    }
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const validSortColumns = ['id', 'userEmail', 'userRole', 'activityType', 'timestamp'];
  const sortCol = validSortColumns.includes(sortBy) ? sortBy : 'timestamp';
  const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  try {
    const dataQuery = `
      SELECT * FROM activity_logs 
      ${whereClause} 
      ORDER BY ${sortCol} ${sortOrder} 
      LIMIT ? OFFSET ?
    `;
    const countQuery = `
      SELECT COUNT(*) as total FROM activity_logs 
      ${whereClause}
    `;

    const [rows, countRows] = await Promise.all([
      query(dataQuery, [...params, limitNum, offset]),
      query(countQuery, params)
    ]);

    const total = countRows[0].total;

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'VIEW_ACTIVITY_LOGS',
      description: 'Admin viewed activity logs history list',
      status: 'SUCCESS',
      req
    });

    return res.status(200).json({
      ok: true,
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
      data: rows
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Admin entries inspect legacy route
app.get('/api/admin/sql-entries', authenticateToken, requireRole(['admin']), async (_, res) => {
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
      query('SELECT * FROM activity_logs ORDER BY id DESC LIMIT 500'),
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
          role: u.role,
          status: u.status,
          createdAt: u.createdAt,
          updatedAt: u.updatedAt,
        })),
        authLogs: authLogs.map((a) => ({
          id: a.id,
          email: a.userEmail,
          eventType: a.activityType,
          status: a.status,
          source: a.device,
          ipAddress: a.ipAddress,
          createdAt: a.timestamp,
        })),
        medicines: medicines.map((m) => ({
          id: m.id,
          userId: m.userId,
          name: m.name,
          dosage: m.dosage,
          time: m.time,
          category: m.type,
          createdAt: m.createdAt,
        })),
        reminders: reminders.map((r) => ({
          id: r.id,
          userId: r.userId,
          medicineId: r.medicineId,
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
          id: c.userId,
          userId: c.userId,
          relationship: c.relationship,
          isActive: c.isActive === 1 || c.isActive === true,
        })),
        dependents: dependents.map(dependentToDto),
        settings: settings.map((s) => ({
          userId: s.userId,
          keyName: s.keyName,
          value: s.value,
        })),
      },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Failed to fetch admin entries',
      error: error.message,
    });
  }
});

// ----------------- MEDICAL SHOP & PHARMACY APIS -----------------

// Helper to get or create shop for user
async function resolveShopForUser(userId, fallbackUser = null) {
  const rows = await query('SELECT * FROM medical_shops WHERE userId = ? LIMIT 1', [userId]);
  if (rows.length > 0) return rows[0];

  const userRows = await query('SELECT fullName, email, phoneNumber FROM users WHERE id = ? LIMIT 1', [userId]);
  const user = userRows[0] || fallbackUser || {};
  const shopName = `${user.fullName || 'Medical'}'s Pharmacy`;

  const res = await query(
    `INSERT INTO medical_shops (userId, shopName, ownerName, phoneNumber, email, address)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE shopName=VALUES(shopName), ownerName=VALUES(ownerName)`,
    [userId, shopName, user.fullName || 'Shop Owner', user.phoneNumber || null, user.email || 'shop@smartpill.com', '']
  );

  const newRows = await query('SELECT * FROM medical_shops WHERE id = ? LIMIT 1', [res.insertId]);
  return newRows[0];
}

// 1. Pharmacy Profile
app.get('/api/pharmacy/profile', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  try {
    const targetUserId = req.user.role === 'admin' && req.query.userId ? Number(req.query.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    return res.json({ ok: true, data: shop });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/pharmacy/profile', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  const targetUserId = req.user.role === 'admin' && req.body.userId ? Number(req.body.userId) : req.user.id;
  const {
    shopName = '',
    ownerName = '',
    phoneNumber = '',
    email = '',
    address = '',
    licenseNumber = '',
    imageUrl = null
  } = req.body || {};

  if (phoneNumber && String(phoneNumber).trim().length > 0) {
    if (!isValidPhone(String(phoneNumber).trim())) {
      return res.status(400).json({ ok: false, message: 'Phone number must be exactly 10 digits.' });
    }
  }

  try {
    await query(
      `INSERT INTO medical_shops (userId, shopName, ownerName, phoneNumber, email, address, licenseNumber, imageUrl)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       shopName=VALUES(shopName), ownerName=VALUES(ownerName), phoneNumber=VALUES(phoneNumber),
       email=VALUES(email), address=VALUES(address), licenseNumber=VALUES(licenseNumber), imageUrl=VALUES(imageUrl)`,
      [
        targetUserId,
        shopName.trim() || 'Medical Shop',
        ownerName.trim() || req.user.email,
        phoneNumber ? String(phoneNumber).trim() : null,
        email ? normalizeEmail(email) : req.user.email,
        address ? address.trim() : '',
        licenseNumber ? licenseNumber.trim() : null,
        imageUrl || null
      ]
    );

    if (ownerName.trim()) {
      await query('UPDATE users SET fullName = ? WHERE id = ?', [ownerName.trim(), targetUserId]);
    }

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'UPDATE_PHARMACY_PROFILE',
      description: `Updated pharmacy profile for user ID ${targetUserId}`,
      status: 'SUCCESS',
      req
    });

    const updated = await resolveShopForUser(targetUserId);
    return res.json({ ok: true, message: 'Pharmacy profile updated successfully.', data: updated });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/pharmacy/profile/:id', authenticateTokenOrFallback, async (req, res) => {
  const shopId = Number(req.params.id);
  try {
    const rows = await query('SELECT * FROM medical_shops WHERE id = ? LIMIT 1', [shopId]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Medical shop not found.' });
    }
    return res.json({ ok: true, data: rows[0] });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// 2. Pharmacy Dashboard Stats
app.get('/api/pharmacy/dashboard-stats', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  try {
    const targetUserId = req.user.role === 'admin' && req.query.userId ? Number(req.query.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const [
      totalProductsRows,
      availableStockRows,
      lowStockRows,
      expiredRows,
      pendingOrdersRows,
      completedOrdersRows
    ] = await Promise.all([
      query('SELECT COUNT(*) as count FROM shop_medicines WHERE shopId = ?', [shopId]),
      query('SELECT COALESCE(SUM(stockQuantity), 0) as totalStock FROM shop_medicines WHERE shopId = ? AND isAvailable = 1 AND expiryDate >= CURDATE()', [shopId]),
      query('SELECT COUNT(*) as count FROM shop_medicines WHERE shopId = ? AND stockQuantity <= 5 AND stockQuantity > 0', [shopId]),
      query('SELECT COUNT(*) as count FROM shop_medicines WHERE shopId = ? AND expiryDate < CURDATE()', [shopId]),
      query("SELECT COUNT(*) as count FROM medicine_orders WHERE shopId = ? AND status = 'pending'", [shopId]),
      query("SELECT COUNT(*) as count FROM medicine_orders WHERE shopId = ? AND status = 'delivered'", [shopId])
    ]);

    return res.json({
      ok: true,
      data: {
        totalProducts: Number(totalProductsRows[0]?.count || 0),
        availableStock: Number(availableStockRows[0]?.totalStock || 0),
        lowStockMedicines: Number(lowStockRows[0]?.count || 0),
        expiredMedicines: Number(expiredRows[0]?.count || 0),
        pendingOrders: Number(pendingOrdersRows[0]?.count || 0),
        completedOrders: Number(completedOrdersRows[0]?.count || 0),
        shop
      }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// 3. Pharmacy Inventory CRUD
app.get('/api/pharmacy/inventory', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  try {
    const targetUserId = req.user.role === 'admin' && req.query.userId ? Number(req.query.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const rows = await query('SELECT * FROM shop_medicines WHERE shopId = ? ORDER BY id DESC', [shopId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/api/pharmacy/inventory', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  try {
    const targetUserId = req.user.role === 'admin' && req.body.userId ? Number(req.body.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const {
      name,
      category = 'Tablets',
      manufacturer = '',
      batchNumber = '',
      price = 0,
      stockQuantity = 0,
      expiryDate,
      imageUrl = null,
      description = '',
      prescriptionRequired = false,
      isAvailable = true
    } = req.body || {};

    if (!name || !name.trim()) {
      return res.status(400).json({ ok: false, message: 'Medicine name is required.' });
    }
    if (!expiryDate) {
      return res.status(400).json({ ok: false, message: 'Expiry date is required.' });
    }

    const parsedExpiry = parseDate(expiryDate);
    if (!parsedExpiry) {
      return res.status(400).json({ ok: false, message: 'Invalid expiry date format.' });
    }

    const result = await query(
      `INSERT INTO shop_medicines 
       (shopId, name, category, manufacturer, batchNumber, price, stockQuantity, expiryDate, imageUrl, description, prescriptionRequired, isAvailable)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        shopId,
        name.trim(),
        category.trim(),
        manufacturer.trim(),
        batchNumber.trim(),
        Math.max(0, Number(price) || 0),
        Math.max(0, parseInt(stockQuantity, 10) || 0),
        parsedExpiry,
        imageUrl,
        description.trim(),
        prescriptionRequired === true || prescriptionRequired === 1 ? 1 : 0,
        isAvailable === false || isAvailable === 0 ? 0 : 1
      ]
    );

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'ADD_SHOP_MEDICINE',
      description: `Added medicine ${name.trim()} to pharmacy inventory`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Medicine added to inventory successfully.', id: result.insertId });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/pharmacy/inventory/:id', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  const medicineId = Number(req.params.id);
  try {
    const targetUserId = req.user.role === 'admin' && req.body.userId ? Number(req.body.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const existing = await query('SELECT * FROM shop_medicines WHERE id = ? AND shopId = ? LIMIT 1', [medicineId, shopId]);
    if (existing.length === 0 && req.user.role !== 'admin') {
      return res.status(404).json({ ok: false, message: 'Medicine not found in your inventory.' });
    }

    const {
      name,
      category,
      manufacturer,
      batchNumber,
      price,
      stockQuantity,
      expiryDate,
      imageUrl,
      description,
      prescriptionRequired,
      isAvailable
    } = req.body || {};

    const prev = existing[0] || {};
    const updatedExpiry = expiryDate ? parseDate(expiryDate) : prev.expiryDate;

    await query(
      `UPDATE shop_medicines SET 
       name = ?, category = ?, manufacturer = ?, batchNumber = ?, price = ?,
       stockQuantity = ?, expiryDate = ?, imageUrl = ?, description = ?,
       prescriptionRequired = ?, isAvailable = ?, updatedAt = NOW()
       WHERE id = ? AND shopId = ?`,
      [
        name !== undefined ? name.trim() : prev.name,
        category !== undefined ? category.trim() : prev.category,
        manufacturer !== undefined ? manufacturer.trim() : prev.manufacturer,
        batchNumber !== undefined ? batchNumber.trim() : prev.batchNumber,
        price !== undefined ? Math.max(0, Number(price)) : prev.price,
        stockQuantity !== undefined ? Math.max(0, parseInt(stockQuantity, 10)) : prev.stockQuantity,
        updatedExpiry,
        imageUrl !== undefined ? imageUrl : prev.imageUrl,
        description !== undefined ? description.trim() : prev.description,
        prescriptionRequired !== undefined ? (prescriptionRequired ? 1 : 0) : prev.prescriptionRequired,
        isAvailable !== undefined ? (isAvailable ? 1 : 0) : prev.isAvailable,
        medicineId,
        shopId
      ]
    );

    return res.json({ ok: true, message: 'Medicine updated successfully.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.delete('/api/pharmacy/inventory/:id', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  const medicineId = Number(req.params.id);
  try {
    const targetUserId = req.user.role === 'admin' && req.query.userId ? Number(req.query.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const del = await query('DELETE FROM shop_medicines WHERE id = ? AND shopId = ?', [medicineId, shopId]);
    if (del.affectedRows === 0 && req.user.role !== 'admin') {
      return res.status(404).json({ ok: false, message: 'Medicine not found in your inventory.' });
    }

    return res.json({ ok: true, message: 'Medicine deleted from inventory.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// 4. Public / Patient / Caretaker Medical Shop Catalog Search
app.get('/api/shop/catalog', authenticateTokenOrFallback, async (req, res) => {
  const { search = '', category = '', shopId = '', includePrescriptionOnly = 'true' } = req.query;

  try {
    let sql = `
      SELECT 
        sm.id, sm.shopId, sm.name, sm.category, sm.manufacturer, sm.batchNumber,
        sm.price, sm.stockQuantity, sm.expiryDate, sm.imageUrl, sm.description,
        sm.prescriptionRequired, sm.isAvailable, sm.createdAt,
        ms.shopName, ms.ownerName, ms.phoneNumber as shopPhone, ms.address as shopAddress, ms.imageUrl as shopLogo
      FROM shop_medicines sm
      JOIN medical_shops ms ON sm.shopId = ms.id
      WHERE sm.isAvailable = 1 AND sm.stockQuantity > 0 AND sm.expiryDate >= CURDATE()
    `;
    const params = [];

    if (search && search.trim().length > 0) {
      sql += ' AND (sm.name LIKE ? OR sm.manufacturer LIKE ? OR sm.description LIKE ?)';
      params.push(`%${search.trim()}%`, `%${search.trim()}%`, `%${search.trim()}%`);
    }

    if (category && category.trim().length > 0 && category.toLowerCase() !== 'all') {
      sql += ' AND sm.category = ?';
      params.push(category.trim());
    }

    if (shopId && Number(shopId) > 0) {
      sql += ' AND sm.shopId = ?';
      params.push(Number(shopId));
    }

    sql += ' ORDER BY sm.name ASC';

    const rows = await query(sql, params);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// 5. Doctor Prescriptions
app.post('/api/prescriptions', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
  const doctorId = req.user.id;
  const {
    patientId,
    medicineName,
    dosage,
    frequency,
    duration,
    quantity = 1,
    instructions = '',
    shopMedicineId = null,
    isRenewable = false,
    renewalsLeft = 0
  } = req.body || {};

  if (!patientId || !medicineName || !dosage || !frequency || !duration) {
    return res.status(400).json({
      ok: false,
      message: 'patientId, medicineName, dosage, frequency, and duration are required.'
    });
  }

  try {
    // Verify connection if not admin
    if (req.user.role !== 'admin') {
      const conn = await query(
        `SELECT 1 FROM doctor_connections 
         WHERE doctorId = ? AND requesterId = ? AND status = 'accepted' LIMIT 1`,
        [doctorId, Number(patientId)]
      );
      if (conn.length === 0) {
        return res.status(403).json({
          ok: false,
          message: 'You can only prescribe to patients who are actively connected with you.'
        });
      }
    }

    const result = await query(
      `INSERT INTO prescriptions 
       (doctorId, patientId, medicineName, dosage, frequency, duration, quantity, instructions, shopMedicineId, status, isRenewable, renewalsLeft)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?)`,
      [
        doctorId,
        Number(patientId),
        medicineName.trim(),
        dosage.trim(),
        frequency.trim(),
        duration.trim(),
        Math.max(1, parseInt(quantity, 10) || 1),
        instructions ? instructions.trim() : null,
        shopMedicineId ? Number(shopMedicineId) : null,
        isRenewable ? 1 : 0,
        Math.max(0, parseInt(renewalsLeft, 10) || 0)
      ]
    );

    await logActivity({
      userId: doctorId,
      userRole: 'doctor',
      userEmail: req.user.email,
      activityType: 'CREATE_PRESCRIPTION',
      description: `Doctor prescribed ${medicineName.trim()} to patient ID ${patientId}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Prescription created successfully.', prescriptionId: result.insertId });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Patient / Caretaker get active prescriptions
app.get('/api/prescriptions/patient/:patientId', authenticateToken, async (req, res) => {
  const patientId = Number(req.params.patientId);
  const userId = req.user.id;

  try {
    // Security check
    if (req.user.role === 'patient' && userId !== patientId) {
      return res.status(403).json({ ok: false, message: 'Access denied to other patient prescriptions.' });
    }
    if (req.user.role === 'caretaker') {
      const conn = await query(
        `SELECT 1 FROM caretaker_connections WHERE caretakerId = ? AND patientId = ? AND status = 'connected' LIMIT 1`,
        [userId, patientId]
      );
      if (conn.length === 0) {
        return res.status(403).json({ ok: false, message: 'Access denied: Unconnected patient.' });
      }
    }

    const sql = `
      SELECT 
        p.*,
        uDoc.fullName as doctorName,
        uDoc.email as doctorEmail,
        uDoc.phoneNumber as doctorPhone,
        d.specialization as doctorSpecialization,
        d.hospitalName as doctorHospital,
        sm.price as shopMedicinePrice,
        sm.stockQuantity as shopMedicineStock,
        sm.isAvailable as shopMedicineAvailable
      FROM prescriptions p
      JOIN users uDoc ON p.doctorId = uDoc.id
      LEFT JOIN doctors d ON uDoc.id = d.userId
      LEFT JOIN shop_medicines sm ON p.shopMedicineId = sm.id
      WHERE p.patientId = ? AND p.status = 'active'
      ORDER BY p.id DESC
    `;
    const rows = await query(sql, [patientId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Get prescriptions for currently logged-in user
app.get('/api/prescriptions/my-prescriptions', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { patientId } = req.query;

  try {
    let targetPatientId = userId;
    if (req.user.role === 'caretaker') {
      if (patientId) {
        targetPatientId = Number(patientId);
      } else {
        const conns = await query(
          `SELECT patientId FROM caretaker_connections WHERE caretakerId = ? AND status = 'connected' LIMIT 1`,
          [userId]
        );
        if (conns.length > 0) targetPatientId = conns[0].patientId;
      }
    }

    const sql = `
      SELECT 
        p.*,
        uDoc.fullName as doctorName,
        uDoc.email as doctorEmail,
        uDoc.phoneNumber as doctorPhone,
        d.specialization as doctorSpecialization,
        d.hospitalName as doctorHospital,
        sm.price as shopMedicinePrice,
        sm.stockQuantity as shopMedicineStock,
        sm.isAvailable as shopMedicineAvailable
      FROM prescriptions p
      JOIN users uDoc ON p.doctorId = uDoc.id
      LEFT JOIN doctors d ON uDoc.id = d.userId
      LEFT JOIN shop_medicines sm ON p.shopMedicineId = sm.id
      WHERE p.patientId = ? AND p.status = 'active'
      ORDER BY p.id DESC
    `;
    const rows = await query(sql, [targetPatientId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Doctor get their prescribed prescriptions
app.get('/api/prescriptions/doctor', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
  const doctorId = req.user.id;
  try {
    const sql = `
      SELECT 
        p.*,
        uPat.fullName as patientName,
        uPat.email as patientEmail,
        uPat.phoneNumber as patientPhone
      FROM prescriptions p
      JOIN users uPat ON p.patientId = uPat.id
      WHERE p.doctorId = ?
      ORDER BY p.id DESC
    `;
    const rows = await query(sql, [doctorId]);
    return res.json({ ok: true, data: rows });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Request prescription renewal
app.post('/api/prescriptions/:id/renew', authenticateToken, async (req, res) => {
  const patientId = req.user.id;
  const prescriptionId = Number(req.params.id);
  
  try {
    const rows = await query('SELECT * FROM prescriptions WHERE id = ? AND patientId = ?', [prescriptionId, patientId]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Prescription not found.' });
    }
    const prescription = rows[0];
    
    if (prescription.isRenewable !== 1 || prescription.renewalsLeft <= 0) {
      return res.status(400).json({ ok: false, message: 'This prescription is not eligible for renewal.' });
    }
    
    await query('UPDATE prescriptions SET renewalsLeft = renewalsLeft - 1 WHERE id = ?', [prescriptionId]);
    
    await query(
      'INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)',
      [prescription.doctorId, 'Prescription Renewal Requested', `Patient requested renewal for ${prescription.medicineName}`, 'alert', false]
    );

    await logActivity({
      userId: patientId,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'RENEW_PRESCRIPTION',
      description: `Requested renewal for prescription ID ${prescriptionId}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: 'Renewal requested successfully.' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// 6. Orders (Patient & Caretaker create order, Pharmacy manages)
app.post('/api/orders', authenticateToken, requireRole(['patient', 'caretaker', 'admin']), async (req, res) => {
  const requesterId = req.user.id;
  const isCaretaker = req.user.role === 'caretaker';

  const {
    patientId,
    shopId,
    prescriptionId = null,
    deliveryAddress = '',
    paymentMethod = 'Cash on Delivery',
    notes = '',
    items = []
  } = req.body || {};

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ ok: false, message: 'Cart items cannot be empty.' });
  }
  if (!shopId) {
    return res.status(400).json({ ok: false, message: 'shopId is required.' });
  }

  // Resolve target patient ID
  let targetPatientId = requesterId;
  let caretakerId = null;

  if (isCaretaker) {
    if (!patientId) {
      return res.status(400).json({ ok: false, message: 'patientId is required when ordering as caretaker.' });
    }
    targetPatientId = Number(patientId);
    caretakerId = requesterId;

    // Verify caretaker connection
    const conn = await query(
      `SELECT 1 FROM caretaker_connections WHERE caretakerId = ? AND patientId = ? AND status = 'connected' LIMIT 1`,
      [caretakerId, targetPatientId]
    );
    if (conn.length === 0 && req.user.role !== 'admin') {
      return res.status(403).json({ ok: false, message: 'You are not connected to this patient.' });
    }
  }

  try {
    // Verify shop exists
    const shopRows = await query('SELECT id, shopName, userId FROM medical_shops WHERE id = ? LIMIT 1', [Number(shopId)]);
    if (shopRows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Selected medical shop not found.' });
    }

    // Verify each item in inventory
    let totalAmount = 0.0;
    const validatedItems = [];

    for (const item of items) {
      const medId = Number(item.shopMedicineId || item.id);
      const qty = Math.max(1, parseInt(item.quantity, 10) || 1);

      const medRows = await query(
        'SELECT * FROM shop_medicines WHERE id = ? AND shopId = ? LIMIT 1',
        [medId, Number(shopId)]
      );
      if (medRows.length === 0) {
        return res.status(400).json({
          ok: false,
          message: `Medicine ID ${medId} is not available at this medical shop.`
        });
      }

      const med = medRows[0];

      // Check availability and stock
      if (med.isAvailable !== 1 || med.stockQuantity < qty) {
        return res.status(400).json({
          ok: false,
          message: `Insufficient stock for ${med.name}. Available: ${med.stockQuantity}, requested: ${qty}.`
        });
      }

      // Check expiry date
      const expiry = new Date(med.expiryDate);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      if (expiry < today) {
        return res.status(400).json({
          ok: false,
          message: `Medicine ${med.name} has expired and cannot be ordered.`
        });
      }

      // Check prescription required
      if (med.prescriptionRequired === 1 && !prescriptionId) {
        return res.status(400).json({
          ok: false,
          message: `${med.name} requires a doctor prescription. Please select an active prescription.`
        });
      }

      const unitPrice = Number(med.price) || 0.0;
      const subtotal = unitPrice * qty;
      totalAmount += subtotal;

      validatedItems.push({
        shopMedicineId: med.id,
        medicineName: med.name,
        price: unitPrice,
        quantity: qty,
        subtotal
      });
    }

    // Generate unique order number
    const orderNumber = `ORD-${Date.now().toString().slice(-6)}-${Math.floor(1000 + Math.random() * 9000)}`;

    const orderRes = await query(
      `INSERT INTO medicine_orders 
       (orderNumber, patientId, caretakerId, shopId, prescriptionId, totalAmount, status, deliveryAddress, paymentMethod, notes)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
      [
        orderNumber,
        targetPatientId,
        caretakerId,
        Number(shopId),
        prescriptionId ? Number(prescriptionId) : null,
        totalAmount,
        deliveryAddress ? deliveryAddress.trim() : null,
        paymentMethod || 'Cash on Delivery',
        notes ? notes.trim() : null
      ]
    );

    const orderId = orderRes.insertId;

    // Insert order items
    for (const vItem of validatedItems) {
      await query(
        `INSERT INTO medicine_order_items 
         (orderId, shopMedicineId, medicineName, price, quantity, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [orderId, vItem.shopMedicineId, vItem.medicineName, vItem.price, vItem.quantity, vItem.subtotal]
      );
    }

    await logActivity({
      userId: requesterId,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'PLACE_MEDICINE_ORDER',
      description: `Placed order ${orderNumber} totaling ₹${totalAmount.toFixed(2)} with ${validatedItems.length} items`,
      status: 'SUCCESS',
      req
    });

    // Notify the pharmacist
    if (shopRows[0].userId) {
      await query(
        `INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)`,
        [shopRows[0].userId, 'New Order Received', `You have received a new order (${orderNumber}) for ₹${totalAmount.toFixed(2)}.`, 'alert', false]
      );
    }

    return res.json({
      ok: true,
      message: 'Order placed successfully.',
      order: {
        id: orderId,
        orderNumber,
        totalAmount,
        status: 'pending',
        patientId: targetPatientId,
        shopId: Number(shopId)
      }
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Patient / Caretaker get order history
app.get('/api/orders/my-orders', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const isCaretaker = req.user.role === 'caretaker';

  try {
    let sql = `
      SELECT 
        mo.*,
        ms.shopName,
        ms.phoneNumber as shopPhone,
        ms.address as shopAddress,
        uPat.fullName as patientName,
        uPat.email as patientEmail,
        uCare.fullName as caretakerName,
        pr.medicineName as prescribedMedicineName,
        pr.dosage as prescribedDosage,
        uDoc.fullName as prescribedDoctorName
      FROM medicine_orders mo
      JOIN medical_shops ms ON mo.shopId = ms.id
      JOIN users uPat ON mo.patientId = uPat.id
      LEFT JOIN users uCare ON mo.caretakerId = uCare.id
      LEFT JOIN prescriptions pr ON mo.prescriptionId = pr.id
      LEFT JOIN users uDoc ON pr.doctorId = uDoc.id
    `;
    const params = [];

    if (isCaretaker) {
      sql += ` WHERE (mo.caretakerId = ? OR mo.patientId IN (SELECT patientId FROM caretaker_connections WHERE caretakerId = ? AND status = 'connected'))`;
      params.push(userId, userId);
    } else {
      sql += ' WHERE mo.patientId = ?';
      params.push(userId);
    }

    sql += ' ORDER BY mo.id DESC';

    const orders = await query(sql, params);

    // Fetch items for each order
    for (const order of orders) {
      const items = await query(
        `SELECT moi.*, sm.imageUrl, sm.category 
         FROM medicine_order_items moi
         LEFT JOIN shop_medicines sm ON moi.shopMedicineId = sm.id
         WHERE moi.orderId = ?`,
        [order.id]
      );
      order.items = items;
    }

    return res.json({ ok: true, data: orders });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Pharmacy get orders for their shop
app.get('/api/orders/shop', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  try {
    const targetUserId = req.user.role === 'admin' && req.query.userId ? Number(req.query.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const sql = `
      SELECT 
        mo.*,
        uPat.fullName as patientName,
        uPat.email as patientEmail,
        uPat.phoneNumber as patientPhone,
        uCare.fullName as caretakerName,
        uCare.phoneNumber as caretakerPhone,
        pr.medicineName as prescribedMedicineName,
        pr.dosage as prescribedDosage,
        pr.frequency as prescribedFrequency,
        pr.duration as prescribedDuration,
        uDoc.fullName as prescribedDoctorName,
        uDoc.phoneNumber as prescribedDoctorPhone
      FROM medicine_orders mo
      JOIN users uPat ON mo.patientId = uPat.id
      LEFT JOIN users uCare ON mo.caretakerId = uCare.id
      LEFT JOIN prescriptions pr ON mo.prescriptionId = pr.id
      LEFT JOIN users uDoc ON pr.doctorId = uDoc.id
      WHERE mo.shopId = ?
      ORDER BY mo.id DESC
    `;
    const orders = await query(sql, [shopId]);

    for (const order of orders) {
      const items = await query(
        `SELECT moi.*, sm.stockQuantity as currentStock, sm.expiryDate 
         FROM medicine_order_items moi
         LEFT JOIN shop_medicines sm ON moi.shopMedicineId = sm.id
         WHERE moi.orderId = ?`,
        [order.id]
      );
      order.items = items;
    }

    return res.json({ ok: true, data: orders });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Update order status (by Pharmacy owner or Admin)
app.put('/api/orders/:id/status', authenticateToken, requireRole(['pharmacy', 'admin']), async (req, res) => {
  const orderId = Number(req.params.id);
  const { status } = req.body || {};

  const validStatuses = ['pending', 'accepted', 'packed', 'ready', 'delivered', 'rejected'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ ok: false, message: 'Invalid order status.' });
  }

  try {
    const targetUserId = req.user.role === 'admin' && req.body.userId ? Number(req.body.userId) : req.user.id;
    const shop = await resolveShopForUser(targetUserId, req.user);
    const shopId = shop.id;

    const orderRows = await query('SELECT * FROM medicine_orders WHERE id = ? LIMIT 1', [orderId]);
    if (orderRows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Order not found.' });
    }

    const order = orderRows[0];
    if (order.shopId !== shopId && req.user.role !== 'admin') {
      return res.status(403).json({ ok: false, message: 'Unauthorized to update this order.' });
    }

    const prevStatus = order.status;

    // If accepting order, verify inventory and deduct stock automatically
    if (status === 'accepted' && prevStatus === 'pending') {
      const items = await query('SELECT * FROM medicine_order_items WHERE orderId = ?', [orderId]);
      for (const item of items) {
        const medRows = await query('SELECT * FROM shop_medicines WHERE id = ? LIMIT 1', [item.shopMedicineId]);
        if (medRows.length > 0) {
          const med = medRows[0];
          if (med.stockQuantity < item.quantity) {
            return res.status(400).json({
              ok: false,
              message: `Cannot accept order: Insufficient stock for ${med.name}. Available: ${med.stockQuantity}, required: ${item.quantity}.`
            });
          }
          // Reduce inventory
          await query(
            'UPDATE shop_medicines SET stockQuantity = GREATEST(0, stockQuantity - ?) WHERE id = ?',
            [item.quantity, item.shopMedicineId]
          );
        }
      }
    }

    // If rejecting an order that was already accepted, restore inventory
    if (status === 'rejected' && prevStatus === 'accepted') {
      const items = await query('SELECT * FROM medicine_order_items WHERE orderId = ?', [orderId]);
      for (const item of items) {
        await query(
          'UPDATE shop_medicines SET stockQuantity = stockQuantity + ? WHERE id = ?',
          [item.quantity, item.shopMedicineId]
        );
      }
    }

    await query('UPDATE medicine_orders SET status = ?, updatedAt = NOW() WHERE id = ?', [status, orderId]);

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      userEmail: req.user.email,
      activityType: 'UPDATE_ORDER_STATUS',
      description: `Updated order ${order.orderNumber} status from ${prevStatus} to ${status}`,
      status: 'SUCCESS',
      req
    });

    return res.json({ ok: true, message: `Order status updated to ${status}.` });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// Single Order Details
app.get('/api/orders/:id', authenticateToken, async (req, res) => {
  const orderId = Number(req.params.id);
  const userId = req.user.id;

  try {
    const sql = `
      SELECT 
        mo.*,
        ms.shopName,
        ms.phoneNumber as shopPhone,
        ms.address as shopAddress,
        uPat.fullName as patientName,
        uPat.email as patientEmail,
        uPat.phoneNumber as patientPhone,
        uCare.fullName as caretakerName,
        uCare.phoneNumber as caretakerPhone,
        pr.medicineName as prescribedMedicineName,
        pr.dosage as prescribedDosage,
        uDoc.fullName as prescribedDoctorName
      FROM medicine_orders mo
      JOIN medical_shops ms ON mo.shopId = ms.id
      JOIN users uPat ON mo.patientId = uPat.id
      LEFT JOIN users uCare ON mo.caretakerId = uCare.id
      LEFT JOIN prescriptions pr ON mo.prescriptionId = pr.id
      LEFT JOIN users uDoc ON pr.doctorId = uDoc.id
      WHERE mo.id = ? LIMIT 1
    `;
    const rows = await query(sql, [orderId]);
    if (rows.length === 0) {
      return res.status(404).json({ ok: false, message: 'Order not found.' });
    }

    const order = rows[0];

    // Security check
    if (req.user.role === 'patient' && order.patientId !== userId) {
      return res.status(403).json({ ok: false, message: 'Unauthorized to view this order.' });
    }

    const items = await query(
      `SELECT moi.*, sm.imageUrl, sm.category 
       FROM medicine_order_items moi
       LEFT JOIN shop_medicines sm ON moi.shopMedicineId = sm.id
       WHERE moi.orderId = ?`,
      [orderId]
    );
    order.items = items;

    return res.json({ ok: true, data: order });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message });
  }
});

// ----------------- DOCTOR FEEDBACK -----------------
app.post('/api/doctor-feedback', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
  const doctorId = req.user.id;
  const { patientId, medicineId, feedbackText } = req.body || {};
  
  if (!patientId || !feedbackText) {
    return res.status(400).json({ ok: false, message: 'patientId and feedbackText are required.' });
  }
  
  try {
    await query(
      'INSERT INTO doctor_feedback (doctorId, patientId, medicineId, feedbackText) VALUES (?, ?, ?, ?)',
      [doctorId, Number(patientId), medicineId ? Number(medicineId) : null, feedbackText.trim()]
    );
    
    // Notify Patient
    await query(
      'INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)',
      [patientId, 'New Doctor Feedback', 'Your doctor has left new feedback for you.', 'alert', false]
    );

    res.json({ ok: true, message: 'Feedback submitted successfully.' });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/doctor-feedback/:patientId', authenticateToken, async (req, res) => {
  const patientId = req.params.patientId === 'me' ? req.user.id : Number(req.params.patientId);
  try {
    const rows = await query('SELECT df.*, d.fullName as doctorName FROM doctor_feedback df JOIN users d ON df.doctorId = d.id WHERE df.patientId = ? ORDER BY df.createdAt DESC', [patientId]);
    res.json({ ok: true, data: rows });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ----------------- DOCTOR VERIFICATION -----------------
app.post('/api/admin/verify-doctor/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const doctorId = Number(req.params.id);
  const { isVerified = true } = req.body || {};
  try {
    const result = await query('UPDATE doctors SET isVerified = ? WHERE userId = ?', [isVerified ? 1 : 0, doctorId]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ ok: false, message: 'Doctor not found.' });
    }
    res.json({ ok: true, message: `Doctor verification status set to ${isVerified}.` });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});


// ----------------- APPOINTMENTS -----------------
app.post('/api/appointments', authenticateToken, async (req, res) => {
  const patientId = req.user.id;
  const { doctorId, appointmentDate, appointmentTime, reason } = req.body || {};
  
  if (!doctorId || !appointmentDate || !appointmentTime) {
    return res.status(400).json({ ok: false, message: 'doctorId, appointmentDate, and appointmentTime are required.' });
  }
  
  try {
    const result = await query(
      'INSERT INTO appointments (patientId, doctorId, appointmentDate, appointmentTime, reason) VALUES (?, ?, ?, ?, ?)',
      [patientId, Number(doctorId), appointmentDate, appointmentTime, reason || null]
    );
    
    // Notify Doctor
    await query(
      'INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)',
      [doctorId, 'New Appointment Request', 'You have a new appointment request pending.', 'alert', false]
    );

    res.json({ ok: true, message: 'Appointment requested successfully.', data: { id: result.insertId } });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/appointments/patient', authenticateToken, async (req, res) => {
  const patientId = req.user.id;
  try {
    const rows = await query(`
      SELECT a.*, d.fullName as doctorName, dp.specialization, up.profilePicture as doctorPicture
      FROM appointments a
      JOIN users d ON a.doctorId = d.id
      LEFT JOIN doctors dp ON d.id = dp.userId
      LEFT JOIN userProfiles up ON d.id = up.userId
      WHERE a.patientId = ?
      ORDER BY a.appointmentDate DESC, a.appointmentTime DESC
    `, [patientId]);
    res.json({ ok: true, data: rows });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get('/api/appointments/doctor', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;
  try {
    const rows = await query(`
      SELECT a.*, p.fullName as patientName, up.profilePicture as patientPicture
      FROM appointments a
      JOIN users p ON a.patientId = p.id
      LEFT JOIN userProfiles up ON p.id = up.userId
      WHERE a.doctorId = ?
      ORDER BY a.appointmentDate DESC, a.appointmentTime DESC
    `, [doctorId]);
    res.json({ ok: true, data: rows });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.put('/api/appointments/:id/status', authenticateToken, requireRole(['doctor']), async (req, res) => {
  const doctorId = req.user.id;
  const appointmentId = Number(req.params.id);
  const { status } = req.body || {};
  
  if (!['approved', 'rejected', 'completed', 'cancelled'].includes(status)) {
    return res.status(400).json({ ok: false, message: 'Invalid status.' });
  }
  
  try {
    const check = await query('SELECT * FROM appointments WHERE id = ? AND doctorId = ?', [appointmentId, doctorId]);
    if (check.length === 0) {
      return res.status(404).json({ ok: false, message: 'Appointment not found or unauthorized.' });
    }
    
    await query('UPDATE appointments SET status = ? WHERE id = ?', [status, appointmentId]);
    
    const patientId = check[0].patientId;
    await query(
      'INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)',
      [patientId, 'Appointment Status Updated', `Your appointment on ${check[0].appointmentDate} was ${status}.`, 'alert', false]
    );

    res.json({ ok: true, message: `Appointment status updated to ${status}.` });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ----------------- BOOTSTRAP AND SHUTDOWN -----------------

async function startServer() {
  try {
    await connectMySQL();
    await ensureDefaultAdmin();

    const server = app.listen(port, () => {
      console.log(`MySQL API running on http://localhost:${port}/api`);
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`\n⚠️ Port ${port} is ALREADY in use by another running server instance.`);
        console.error(`The backend API is ALREADY active and serving requests on http://localhost:${port}/api.`);
        console.error(`If you wish to restart it, run: Stop-Process -Name node -Force in PowerShell.\n`);
        process.exit(1);
      } else {
        console.error('Server startup error:', err.message);
      }
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
