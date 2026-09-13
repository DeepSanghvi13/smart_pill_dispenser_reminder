const fs = require('fs');
const path = require('path');
const http = require('http');

const BASE_URL = 'http://localhost:3000';

function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        let json = null;
        try {
          json = JSON.parse(data);
        } catch (_) {}
        resolve({ statusCode: res.statusCode, headers: res.headers, body: json || data });
      });
    });
    req.on('error', reject);
    if (postData) {
      if (typeof postData === 'string' || Buffer.isBuffer(postData)) {
        req.write(postData);
      }
    }
    req.end();
  });
}

function buildMultipartBody(boundary, fieldName, filename, contentType, fileBuffer) {
  const head = Buffer.from(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="${fieldName}"; filename="${filename}"\r\n` +
    `Content-Type: ${contentType}\r\n\r\n`
  );
  const tail = Buffer.from(`\r\n--${boundary}--\r\n`);
  return Buffer.concat([head, fileBuffer, tail]);
}

async function runTests() {
  console.log('=== STARTING TESTS: 5-DIGIT LICENSE & PERSISTENT PHOTO UPLOAD ===\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${message}`);
      failed++;
    }
  }

  // 1. Health check
  try {
    const health = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: '/api/health',
      method: 'GET',
    });
    assert(health.statusCode === 200, 'Server health check returns 200');
  } catch (e) {
    console.error('Server is not reachable:', e);
    return;
  }

  // 2. Doctor Registration License Validation (Invalid cases)
  const invalidLicenses = ['1234', '123456', '1234A', 'ABCDE', '12-345', '12 345', '1234567', ''];
  for (const lic of invalidLicenses) {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/api/auth/register',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      JSON.stringify({
        email: `doctest_invalid_${Date.now()}_${Math.floor(Math.random()*1000)}@gmail.com`,
        password: 'password123',
        fullName: 'Dr. Test Invalid',
        role: 'doctor',
        licenseNumber: lic,
      })
    );
    assert(
      res.statusCode === 400 && res.body.message && res.body.message.includes('5 digits'),
      `Doctor registration with invalid license '${lic}' rejected with 400 (Got ${res.statusCode}: ${res.body?.message})`
    );
  }

  // 3. Doctor Registration License Validation (Valid cases)
  const testDocEmail = `doctest_valid_${Date.now()}@gmail.com`;
  const validReg = await makeRequest(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/register',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    JSON.stringify({
      email: testDocEmail,
      password: 'password123',
      fullName: 'Dr. Test Valid 5-Digit',
      role: 'doctor',
      licenseNumber: '12345',
      specialization: 'Cardiologist',
      hospitalName: 'Apollo Hospital',
      location: 'New York',
    })
  );
  assert(
    validReg.statusCode === 200 && validReg.body.ok === true,
    `Doctor registration with valid 5-digit license '12345' succeeds with 200`
  );

  const docToken = validReg.body.token;

  // 4. Doctor Profile Update with Invalid License
  const invalidDocProfileUpdate = await makeRequest(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/doctor/profile',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${docToken}`,
      },
    },
    JSON.stringify({
      fullName: 'Dr. Test Valid',
      licenseNumber: '9999', // 4 digits
    })
  );
  assert(
    invalidDocProfileUpdate.statusCode === 400,
    `Doctor profile update with invalid license '9999' rejected with 400`
  );

  // 5. Doctor Profile Update with Valid 5-digit License
  const validDocProfileUpdate = await makeRequest(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/doctor/profile',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${docToken}`,
      },
    },
    JSON.stringify({
      fullName: 'Dr. Test Valid Updated',
      licenseNumber: '54321', // valid 5 digits
      specialization: 'Cardiologist',
    })
  );
  assert(
    validDocProfileUpdate.statusCode === 200 && validDocProfileUpdate.body.ok === true,
    `Doctor profile update with valid 5-digit license '54321' succeeds with 200`
  );

  // 6. Patient/Caretaker Registration & Photo Upload Testing
  const patientEmail = `patient_photo_${Date.now()}@gmail.com`;
  const patientReg = await makeRequest(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/register',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    JSON.stringify({
      email: patientEmail,
      password: 'password123',
      fullName: 'Jane Patient Doe',
      role: 'patient',
    })
  );
  assert(patientReg.statusCode === 200, `Patient registration succeeds`);
  const patientToken = patientReg.body.token;

  // Create a dummy image buffer (1x1 PNG)
  const dummyPngBuffer = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64'
  );

  const boundary = `----WebKitFormBoundary${Date.now()}`;
  const multipartBody = buildMultipartBody(boundary, 'photo', 'profile_test.png', 'image/png', dummyPngBuffer);

  const uploadRes = await makeRequest(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/user-profile/photo',
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': multipartBody.length,
        Authorization: `Bearer ${patientToken}`,
      },
    },
    multipartBody
  );

  assert(
    uploadRes.statusCode === 200 && uploadRes.body?.ok === true && uploadRes.body?.profilePicture,
    `Profile photo upload returns 200 and relative profilePicture path: ${uploadRes.body?.profilePicture}`
  );

  const photoPath = uploadRes.body?.profilePicture;

  // Verify file exists on backend disk
  if (photoPath) {
    const cleanRelative = photoPath.replace(/^\//, '');
    const diskPath = path.join(__dirname, '..', cleanRelative);
    assert(fs.existsSync(diskPath), `Uploaded image file exists on backend disk at: ${diskPath}`);

    // Verify static serving via HTTP GET
    const staticRes = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: photoPath,
      method: 'GET',
    });
    assert(staticRes.statusCode === 200, `Static file served at '${photoPath}' returns HTTP 200 OK`);
  }

  // 7. Verify GET /api/user-profile returns profilePicture
  const profileFetch = await makeRequest({
    hostname: 'localhost',
    port: 3000,
    path: `/api/user-profile/${encodeURIComponent(patientEmail)}`,
    method: 'GET',
    headers: {
      Authorization: `Bearer ${patientToken}`,
    },
  });
  assert(
    profileFetch.statusCode === 200 && profileFetch.body?.data?.profilePicture === photoPath,
    `GET /api/user-profile/:userId returns persistent profilePicture path '${profileFetch.body?.data?.profilePicture}'`
  );

  // 8. Delete photo test
  const deleteRes = await makeRequest({
    hostname: 'localhost',
    port: 3000,
    path: '/api/user-profile/photo',
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${patientToken}`,
    },
  });
  assert(
    deleteRes.statusCode === 200 && deleteRes.body?.ok === true,
    `DELETE /api/user-profile/photo succeeds with HTTP 200`
  );

  const profileAfterDelete = await makeRequest({
    hostname: 'localhost',
    port: 3000,
    path: `/api/user-profile/${encodeURIComponent(patientEmail)}`,
    method: 'GET',
    headers: {
      Authorization: `Bearer ${patientToken}`,
    },
  });
  assert(
    profileAfterDelete.statusCode === 200 && profileAfterDelete.body?.data?.profilePicture === null,
    `Profile after photo deletion has profilePicture = null in MySQL`
  );

  console.log(`\n=============================================`);
  console.log(`SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`=============================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch((err) => {
  console.error('Fatal error in tests:', err);
  process.exit(1);
});
