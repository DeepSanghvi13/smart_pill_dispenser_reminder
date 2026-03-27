const mongoose = require('mongoose');

const mongoUri =
  process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_pill_reminder';

const baseSchemaOptions = {
  versionKey: false,
  strict: false,
  minimize: false,
};

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true },
    passwordHash: { type: String, required: true },
    isAdmin: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { ...baseSchemaOptions, collection: 'users' },
);

const authLogSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true },
    eventType: { type: String, required: true },
    status: { type: String, required: true },
    source: { type: String, default: 'mobile' },
    ipAddress: { type: String, default: null },
    createdAt: { type: Date, default: Date.now },
  },
  { ...baseSchemaOptions, collection: 'authLogs' },
);

const upsertSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    localId: { type: Number, default: null },
    createdAt: { type: Date, default: Date.now },
  },
  baseSchemaOptions,
);

const medicineSchema = new mongoose.Schema(
  {
    ...upsertSchema.obj,
    name: { type: String, required: true },
    dosage: { type: String, required: true },
    time: { type: String, required: true },
    category: { type: String, default: 'tablets' },
    expiryDate: { type: Date, default: null },
    isScanned: { type: Boolean, default: false },
    scannedText: { type: String, default: null },
    imagePath: { type: String, default: null },
    healthCondition: { type: String, default: null },
  },
  { ...baseSchemaOptions, collection: 'medicines' },
);

const reminderSchema = new mongoose.Schema(
  {
    ...upsertSchema.obj,
    medicineId: { type: Number, required: true },
    medicineName: { type: String, required: true },
    time: { type: String, required: true },
    daysOfWeek: { type: [String], default: [] },
    isActive: { type: Boolean, default: true },
    lastNotifiedAt: { type: Date, default: null },
  },
  { ...baseSchemaOptions, collection: 'reminders' },
);

const alarmLogSchema = new mongoose.Schema(
  {
    ...upsertSchema.obj,
    medicineId: { type: Number, required: true },
    medicineName: { type: String, required: true },
    scheduledTime: { type: Date, required: true },
    triggeredTime: { type: Date, default: null },
    status: { type: String, default: 'pending' },
    snoozeCount: { type: Number, default: 0 },
    takenAt: { type: Date, default: null },
    notes: { type: String, default: null },
  },
  { ...baseSchemaOptions, collection: 'alarmLogs' },
);

const caretakerSchema = new mongoose.Schema(
  {
    ...upsertSchema.obj,
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    phoneNumber: { type: String, required: true },
    email: { type: String, required: true },
    relationship: { type: String, required: true },
    notifyViaSMS: { type: Boolean, default: true },
    notifyViaEmail: { type: Boolean, default: true },
    notifyViaNotification: { type: Boolean, default: true },
    isActive: { type: Boolean, default: true },
  },
  { ...baseSchemaOptions, collection: 'caretakers' },
);

const dependentSchema = new mongoose.Schema(
  {
    ...upsertSchema.obj,
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    gender: { type: String, default: null },
    birthDate: { type: String, default: null },
    color: { type: String, default: null },
  },
  { ...baseSchemaOptions, collection: 'dependents' },
);

const settingSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    keyName: { type: String, required: true },
    value: { type: String, required: true },
    updatedAt: { type: Date, default: Date.now },
  },
  { ...baseSchemaOptions, collection: 'settings' },
);

const userProfileSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, unique: true, index: true },
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    gender: { type: String, default: null },
    birthDate: { type: String, default: null },
    zipCode: { type: String, default: null },
    phoneNumber: { type: String, default: null },
    email: { type: String, default: null },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { ...baseSchemaOptions, collection: 'userProfiles' },
);

const professionalReviewRequestSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    patientName: { type: String, required: true },
    contact: { type: String, required: true },
    concern: { type: String, required: true },
    preferredHospital: { type: String, default: null },
    urgency: { type: String, default: 'normal' },
    status: { type: String, default: 'pending' },
    createdAt: { type: Date, default: Date.now },
  },
  {
    ...baseSchemaOptions,
    collection: 'professionalReviewRequests',
  },
);

medicineSchema.index(
  { userId: 1, localId: 1 },
  {
    unique: true,
    partialFilterExpression: { localId: { $type: 'number' } },
  },
);
reminderSchema.index(
  { userId: 1, localId: 1 },
  {
    unique: true,
    partialFilterExpression: { localId: { $type: 'number' } },
  },
);
alarmLogSchema.index(
  { userId: 1, localId: 1 },
  {
    unique: true,
    partialFilterExpression: { localId: { $type: 'number' } },
  },
);
caretakerSchema.index(
  { userId: 1, localId: 1 },
  {
    unique: true,
    partialFilterExpression: { localId: { $type: 'number' } },
  },
);
dependentSchema.index(
  { userId: 1, localId: 1 },
  {
    unique: true,
    partialFilterExpression: { localId: { $type: 'number' } },
  },
);
settingSchema.index({ userId: 1, keyName: 1 }, { unique: true });

const User = mongoose.model('User', userSchema);
const AuthLog = mongoose.model('AuthLog', authLogSchema);
const Medicine = mongoose.model('Medicine', medicineSchema);
const Reminder = mongoose.model('Reminder', reminderSchema);
const AlarmLog = mongoose.model('AlarmLog', alarmLogSchema);
const Caretaker = mongoose.model('Caretaker', caretakerSchema);
const Dependent = mongoose.model('Dependent', dependentSchema);
const Setting = mongoose.model('Setting', settingSchema);
const UserProfile = mongoose.model('UserProfile', userProfileSchema);
const ProfessionalReviewRequest = mongoose.model(
  'ProfessionalReviewRequest',
  professionalReviewRequestSchema,
);

async function connectMongo() {
  await mongoose.connect(mongoUri, {
    serverSelectionTimeoutMS: 5000,
  });
}

async function ping() {
  if (mongoose.connection.readyState !== 1) {
    throw new Error('MongoDB is not connected');
  }
  await mongoose.connection.db.admin().ping();
}

async function disconnectMongo() {
  await mongoose.disconnect();
}

async function generateNextLocalId(Model, userId) {
  const last = await Model.findOne({ userId, localId: { $type: 'number' } })
    .sort({ localId: -1 })
    .select({ localId: 1 })
    .lean();
  return Number(last?.localId || 0) + 1;
}

module.exports = {
  mongoose,
  connectMongo,
  ping,
  disconnectMongo,
  generateNextLocalId,
  models: {
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
  },
};

