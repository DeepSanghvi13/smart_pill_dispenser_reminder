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

async function runTests() {
  console.log('--- Starting Appointment Feature Integration Tests ---');
  
  try {
    // 1. Register Doctor
    const docEmail = `dr.appointment.${Date.now()}@gmail.com`;
    const docReg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Dr. John Doe',
        email: docEmail,
        password: 'password123',
        phoneNumber: '9876543220',
        role: 'doctor',
      }
    });
    console.log('✓ Doctor Registered');
    const docToken = docReg.data.token;
    const docId = docReg.data.data.id;

    // 2. Register Patient
    const patientEmail = `patient.appointment.${Date.now()}@gmail.com`;
    const patReg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Jane Doe',
        email: patientEmail,
        password: 'password123',
        phoneNumber: '9123456790',
        role: 'patient',
      }
    });
    console.log('✓ Patient Registered');
    const patToken = patReg.data.token;

    // 3. Patient Book Appointment
    const apptReq = await req(`${BASE_URL}/api/appointments`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${patToken}` },
      body: { doctorId: docId, appointmentDate: '2024-12-01', appointmentTime: '10:00 AM', reason: 'Fever' }
    });
    console.log('✓ Patient Booked Appointment:', apptReq.data.message);
    const apptId = apptReq.data.data.id;

    // 4. Patient Views Appointments
    const patAppts = await req(`${BASE_URL}/api/appointments/patient`, {
      headers: { Authorization: `Bearer ${patToken}` }
    });
    console.log('✓ Patient Views Appointments:', patAppts.data.data.length);

    // 5. Doctor Views Appointments
    const docAppts = await req(`${BASE_URL}/api/appointments/doctor`, {
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor Views Appointments:', docAppts.data.data.length);

    // 6. Doctor Approves Appointment
    const acceptRes = await req(`${BASE_URL}/api/appointments/${apptId}/status`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${docToken}` },
      body: { status: 'approved' }
    });
    console.log('✓ Doctor Approved Appointment:', acceptRes.data.message);

    console.log('\n========================================');
    console.log('🎉 ALL APPOINTMENT BACKEND TESTS PASSED!');
    console.log('========================================\n');
  } catch (error) {
    console.error('✗ Test failed:', error.data || error.message);
    process.exit(1);
  }
}

runTests();
