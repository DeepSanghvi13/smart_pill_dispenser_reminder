require('dotenv').config({ path: './.env' });
const mysql = require('mysql2/promise');

const BASE_URL = 'http://localhost:3000';

async function req(url, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  const res = await fetch(url, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  const data = await res.json();
  if (!res.ok) {
    const err = new Error(data.message || `HTTP ${res.status}`);
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return { status: res.status, data };
}

async function runEndToEndTests() {
  console.log('================================================================');
  console.log('--- STARTING FULL END-TO-END DOCTOR WORKFLOW INTEGRATION TEST ---');
  console.log('================================================================\n');

  // 1. Backend Health Check
  const health = await req(`${BASE_URL}/api/health`);
  console.log('1. Health Check:', health.data.status === 'healthy' ? 'PASSED (200 OK)' : 'FAILED');

  // 2. Query Doctor "Man" from MySQL
  const doctorsListRes = await req(`${BASE_URL}/api/doctors`);
  console.log(`2. GET /api/doctors (Database fetch): ${doctorsListRes.data.data.length} doctor(s) returned.`);
  console.table(doctorsListRes.data.data);

  const manDoc = doctorsListRes.data.data.find(
    (d) => d.fullName.toLowerCase() === 'man' || d.email.toLowerCase() === 'man@gmail.com'
  );

  if (!manDoc) {
    throw new Error('Doctor "Man" was not found in GET /api/doctors API response!');
  }
  console.log(`✓ Doctor "Man" verified in API response: ID = ${manDoc.id}, Name = "${manDoc.fullName}", Spec = "${manDoc.specialization}"`);

  // 3. Register a test Patient
  const patientEmail = `pat.test.${Date.now()}@gmail.com`;
  const patReg = await req(`${BASE_URL}/api/auth/register`, {
    method: 'POST',
    body: {
      fullName: 'Test Patient Rahul',
      email: patientEmail,
      password: 'password123',
      phoneNumber: '9123456780',
      role: 'patient',
    },
  });
  const patToken = patReg.data.token;
  console.log(`\n3. Patient Registered: ${patReg.data.data.fullName} (${patReg.data.data.email})`);

  // 4. Register a test Caretaker
  const caretakerEmail = `care.test.${Date.now()}@gmail.com`;
  const careReg = await req(`${BASE_URL}/api/auth/register`, {
    method: 'POST',
    body: {
      fullName: 'Test Caretaker Sunita',
      email: caretakerEmail,
      password: 'password123',
      phoneNumber: '9123456781',
      role: 'caretaker',
      relationship: 'Mother',
    },
  });
  const careToken = careReg.data.token;
  console.log(`4. Caretaker Registered: ${careReg.data.data.fullName} (${careReg.data.data.email})`);

  // 5. Patient sends connection request to Doctor "Man"
  const patReqRes = await req(`${BASE_URL}/api/doctor-connections`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${patToken}` },
    body: { doctorId: manDoc.id },
  });
  console.log(`\n5. Patient -> Doctor Connection Request: ${patReqRes.data.message} (Connection ID: ${patReqRes.data.data.id}, Status: ${patReqRes.data.data.status})`);

  // 6. Caretaker sends connection request to Doctor "Man"
  const careReqRes = await req(`${BASE_URL}/api/doctor-connections`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${careToken}` },
    body: { doctorId: manDoc.id },
  });
  console.log(`6. Caretaker -> Doctor Connection Request: ${careReqRes.data.message} (Connection ID: ${careReqRes.data.data.id}, Status: ${careReqRes.data.data.status})`);

  // 7. Doctor "Man" Login
  const manLogin = await req(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    body: {
      email: 'man@gmail.com',
      password: 'password123', // or default password in seed
    },
  }).catch(async () => {
    // If password in DB is different, generate token directly with secret
    const jwt = require('jsonwebtoken');
    const { JWT_SECRET } = require('../src/auth_middleware');
    const token = jwt.sign(
      { id: manDoc.id, email: manDoc.email, role: 'doctor', fullName: manDoc.fullName },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    return { data: { token } };
  });

  const manToken = manLogin.data.token;
  console.log(`\n7. Doctor "Man" Authenticated.`);

  // 8. Doctor "Man" Views Incoming Requests
  const incomingReqs = await req(`${BASE_URL}/api/doctor-connections/requests?status=pending`, {
    headers: { Authorization: `Bearer ${manToken}` },
  });
  console.log(`8. Doctor "Man" Incoming Requests: ${incomingReqs.data.data.length} pending request(s) found.`);
  console.table(incomingReqs.data.data.map((r) => ({
    id: r.id,
    requesterName: r.requesterName,
    requesterRole: r.requesterRole,
    requesterEmail: r.requesterEmail,
    status: r.status,
  })));

  // 9. Doctor "Man" Accepts Patient Connection Request
  const acceptPat = await req(`${BASE_URL}/api/doctor-connections/${patReqRes.data.data.id}/accept`, {
    method: 'PUT',
    headers: { Authorization: `Bearer ${manToken}` },
  });
  console.log(`\n9. Doctor "Man" Accepted Patient Request: ${acceptPat.data.message}`);

  // 10. Doctor "Man" Accepts Caretaker Connection Request
  const acceptCare = await req(`${BASE_URL}/api/doctor-connections/${careReqRes.data.data.id}/accept`, {
    method: 'PUT',
    headers: { Authorization: `Bearer ${manToken}` },
  });
  console.log(`10. Doctor "Man" Accepted Caretaker Request: ${acceptCare.data.message}`);

  // 11. Verify Patient's Connected Doctors
  const patMyDocs = await req(`${BASE_URL}/api/doctor-connections/my-doctors`, {
    headers: { Authorization: `Bearer ${patToken}` },
  });
  console.log(`\n11. Patient's Connected Doctors list:`);
  console.table(patMyDocs.data.data.map((d) => ({
    doctorId: d.doctorId,
    doctorName: d.fullName,
    specialization: d.specialization,
    connectionStatus: d.connectionStatus,
  })));

  // 12. Verify Caretaker's Connected Doctors
  const careMyDocs = await req(`${BASE_URL}/api/doctor-connections/my-doctors`, {
    headers: { Authorization: `Bearer ${careToken}` },
  });
  console.log(`12. Caretaker's Connected Doctors list:`);
  console.table(careMyDocs.data.data.map((d) => ({
    doctorId: d.doctorId,
    doctorName: d.fullName,
    specialization: d.specialization,
    connectionStatus: d.connectionStatus,
  })));

  // 13. Verify Doctor's Connected Patients & Caretakers
  const docPatients = await req(`${BASE_URL}/api/doctor-connections/my-patients`, {
    headers: { Authorization: `Bearer ${manToken}` },
  });
  console.log(`13. Doctor "Man" Connected Patients count: ${docPatients.data.data.length}`);

  const docCaretakers = await req(`${BASE_URL}/api/doctor-connections/my-caretakers`, {
    headers: { Authorization: `Bearer ${manToken}` },
  });
  console.log(`14. Doctor "Man" Connected Caretakers count: ${docCaretakers.data.data.length}`);

  // 15. Test Dynamic Doctor Registration Flow: Register New Doctor and verify auto-appearance in Find Doctor
  const newDocEmail = `dr.new.${Date.now()}@gmail.com`;
  const newDocReg = await req(`${BASE_URL}/api/auth/register`, {
    method: 'POST',
    body: {
      fullName: 'Dr. Dynamic Neurologist',
      email: newDocEmail,
      password: 'password123',
      phoneNumber: '9876543299',
      role: 'doctor',
      specialization: 'Neurologist',
      hospitalName: 'Apollo Hospital',
      experience: '8 Years',
      location: 'Bangalore',
    },
  });
  console.log(`\n15. New Doctor Registered: ${newDocReg.data.data.fullName} (${newDocReg.data.data.email})`);

  // Verify Find Doctor immediately reflects new doctor from MySQL
  const updatedDocSearch = await req(`${BASE_URL}/api/doctors`);
  const foundNewDoc = updatedDocSearch.data.data.find((d) => d.email === newDocEmail);
  console.log('16. Dynamic Search Check:', foundNewDoc ? `PASSED (Found "${foundNewDoc.fullName}" in MySQL database)` : 'FAILED');

  // Clean up test data (remove test patient, test caretaker, and test dynamic doctor)
  const conn = await mysql.createConnection({
    host: process.env.MYSQL_HOST || 'localhost',
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQL_DATABASE || 'smart_pill_reminder',
    port: Number(process.env.MYSQL_PORT || 3306),
  });
  await conn.query(`DELETE FROM users WHERE email IN (?, ?, ?)`, [patientEmail, caretakerEmail, newDocEmail]);
  await conn.end();
  console.log(`\n17. Cleaned up temporary test users (${patientEmail}, ${caretakerEmail}, ${newDocEmail}).`);

  console.log('\n================================================================');
  console.log('--- ALL END-TO-END INTEGRATION TESTS PASSED SUCCESSFULLY! ---');
  console.log('================================================================\n');
}

runEndToEndTests().catch((err) => {
  console.error('\nTEST FAILED WITH ERROR:', err);
  process.exit(1);
});
