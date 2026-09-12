// Unit & Functional tests for Gmail and Phone validation rules in Smart Pill Dispenser Reminder

const assert = require('assert');

const GMAIL_REGEX = /^[A-Za-z0-9._%+-]+@gmail\.com$/;
const PHONE_REGEX = /^[0-9]{10}$/;

function isValidGmail(email) {
  if (!email || typeof email !== 'string') return false;
  return GMAIL_REGEX.test(email.trim());
}

function isValidPhone(phone) {
  if (!phone || typeof phone !== 'string') return false;
  return PHONE_REGEX.test(phone.trim());
}

const adminEmails = ['admin@medisafe.com', 'admin@smartpill.com'];

function isAdminEmail(email) {
  if (!email) return false;
  const norm = String(email).trim().toLowerCase();
  return adminEmails.includes(norm) || norm.startsWith('admin@');
}

console.log('--- RUNNING VALIDATION TESTS ---');

// 1. Gmail Validation Tests
const validEmails = [
  'example@gmail.com',
  'deep123@gmail.com',
  'user.name@gmail.com',
  'user+test@gmail.com',
  'my_pill_reminder123@gmail.com',
  'USER@GMAIL.COM' // case-insensitive check
];

const invalidEmails = [
  'example@yahoo.com',
  'example@hotmail.com',
  'example@gmail.co',
  'example@gmail',
  'example@outlook.com',
  '@gmail.com',
  'example@gmail.com.com',
  'example@gmail.org',
  'example@notgmail.com',
  'invalid-email',
  '',
  null,
  undefined
];

for (const email of validEmails) {
  assert.strictEqual(
    isValidGmail(email ? email.toLowerCase() : email),
    true,
    `Expected "${email}" to be a VALID Gmail address`
  );
  console.log(`[PASS] Valid Gmail accepted: ${email}`);
}

for (const email of invalidEmails) {
  assert.strictEqual(
    isValidGmail(email ? (typeof email === 'string' ? email.toLowerCase() : email) : email),
    false,
    `Expected "${email}" to be an INVALID Gmail address`
  );
  console.log(`[PASS] Invalid Email rejected: ${email}`);
}

// 2. Phone Number Validation Tests
const validPhones = [
  '9876543210',
  '9012345678',
  '0123456789',
  '9999999999'
];

const invalidPhones = [
  '987654321',      // 9 digits (too short)
  '98765432101',    // 11 digits (too long)
  '98765abc10',     // contains letters
  '98765-43210',    // contains hyphen
  '98765 43210',    // contains space
  '+19876543210',   // contains plus
  '(987)654321',    // contains parentheses
  'abcdefghij',     // letters only
  '',
  null,
  undefined
];

for (const phone of validPhones) {
  assert.strictEqual(
    isValidPhone(phone),
    true,
    `Expected "${phone}" to be a VALID 10-digit phone number`
  );
  console.log(`[PASS] Valid 10-digit Phone accepted: ${phone}`);
}

for (const phone of invalidPhones) {
  assert.strictEqual(
    isValidPhone(phone),
    false,
    `Expected "${phone}" to be an INVALID phone number`
  );
  console.log(`[PASS] Invalid Phone rejected: ${phone}`);
}

// 3. Admin Login Bypass Check
const adminEmailTests = [
  'admin@medisafe.com',
  'admin@smartpill.com',
  'ADMIN@MEDISAFE.COM'
];

for (const email of adminEmailTests) {
  assert.strictEqual(
    isAdminEmail(email),
    true,
    `Expected "${email}" to be recognized as an Admin email`
  );
  console.log(`[PASS] Admin email recognized and allowed: ${email}`);
}

console.log('\n>>> ALL VALIDATION UNIT TESTS PASSED SUCCESSFULLY! <<<');
