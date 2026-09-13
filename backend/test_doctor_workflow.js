// Integration test for Doctor Connection Feature APIs using native fetch

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
  console.log('--- Starting Doctor Connection Feature Integration Tests ---');
  
  try {
    // 1. Health check
    const health = await req(`${BASE_URL}/api/health`);
    console.log('✓ Backend Health Check:', health.data.status);

    // 2. Register Doctor 1 (Dr. Aarti Sharma)
    const docEmail = `dr.aarti.${Date.now()}@gmail.com`;
    const docReg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Dr. Aarti Sharma',
        email: docEmail,
        password: 'password123',
        phoneNumber: '9876543210',
        role: 'doctor',
        specialization: 'Cardiologist',
        hospitalName: 'Apollo Heart Institute',
        experience: '12 Years',
        location: 'Mumbai'
      }
    });
    console.log('✓ Doctor 1 Registered:', docReg.data.data.fullName, docReg.data.data.email);
    const docToken = docReg.data.token;
    const docId = docReg.data.data.id;

    // 3. Register Doctor 2 (Dr. Rajiv Mehta)
    const doc2Email = `dr.rajiv.${Date.now()}@gmail.com`;
    const doc2Reg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Dr. Rajiv Mehta',
        email: doc2Email,
        password: 'password123',
        phoneNumber: '9876543211',
        role: 'doctor',
        specialization: 'Neurologist',
        hospitalName: 'Max Super Speciality',
        experience: '15 Years',
        location: 'Delhi'
      }
    });
    console.log('✓ Doctor 2 Registered:', doc2Reg.data.data.fullName);
    const doc2Token = doc2Reg.data.token;
    const doc2Id = doc2Reg.data.data.id;

    // 4. Register Patient
    const patientEmail = `patient.rahul.${Date.now()}@gmail.com`;
    const patReg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Rahul Verma',
        email: patientEmail,
        password: 'password123',
        phoneNumber: '9123456780',
        role: 'patient',
        gender: 'Male',
        birthDate: '1990-05-15'
      }
    });
    console.log('✓ Patient Registered:', patReg.data.data.fullName);
    const patToken = patReg.data.token;

    // 5. Register Caretaker
    const caretakerEmail = `caretaker.sunita.${Date.now()}@gmail.com`;
    const careReg = await req(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: {
        fullName: 'Sunita Verma',
        email: caretakerEmail,
        password: 'password123',
        phoneNumber: '9123456781',
        role: 'caretaker',
        relationship: 'Mother'
      }
    });
    console.log('✓ Caretaker Registered:', careReg.data.data.fullName);
    const careToken = careReg.data.token;

    // 6. Test Doctor Search
    const searchAll = await req(`${BASE_URL}/api/doctors`, {
      headers: { Authorization: `Bearer ${patToken}` }
    });
    console.log(`✓ Doctor Search (Total found: ${searchAll.data.data.length})`);
    
    const searchCardio = await req(`${BASE_URL}/api/doctors?specialization=Cardiologist`, {
      headers: { Authorization: `Bearer ${patToken}` }
    });
    console.log(`✓ Doctor Search by Specialization 'Cardiologist': found ${searchCardio.data.data.length}`);

    // 7. Patient Sends Connection Request to Doctor 1
    const sendReq1 = await req(`${BASE_URL}/api/doctor-connections`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${patToken}` },
      body: { doctorId: docId }
    });
    console.log('✓ Patient Sent Request to Doctor 1:', sendReq1.data.message);
    const req1Id = sendReq1.data.data.id;

    // 8. Test Duplicate Prevention (Patient tries sending again)
    try {
      await req(`${BASE_URL}/api/doctor-connections`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${patToken}` },
        body: { doctorId: docId }
      });
      console.error('✗ Duplicate request was NOT prevented!');
      process.exit(1);
    } catch (err) {
      console.log('✓ Duplicate Request Successfully Prevented:', err.data?.message || err.message);
    }

    // 9. Doctor 1 Views Incoming Requests
    const doc1Requests = await req(`${BASE_URL}/api/doctor-connections/requests`, {
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor 1 Received Incoming Requests:', doc1Requests.data.data.length);
    console.log('  Requester:', doc1Requests.data.data[0].requesterName, 'Role:', doc1Requests.data.data[0].requesterRole);

    // 10. Doctor 1 Accepts Request
    const acceptRes = await req(`${BASE_URL}/api/doctor-connections/${req1Id}/accept`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor 1 Accepted Request:', acceptRes.data.message);

    // 11. Patient Checks My Doctors
    const myDoctors = await req(`${BASE_URL}/api/doctor-connections/my-doctors`, {
      headers: { Authorization: `Bearer ${patToken}` }
    });
    console.log('✓ Patient My Doctors:', myDoctors.data.data.map(d => `${d.fullName} (${d.specialization})`));

    // 12. Doctor 1 Checks My Patients
    const myPatients = await req(`${BASE_URL}/api/doctor-connections/my-patients`, {
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor 1 My Patients:', myPatients.data.data.map(p => `${p.fullName} (${p.email})`));

    // 13. Caretaker Sends Connection Request to Doctor 1
    const careReq = await req(`${BASE_URL}/api/doctor-connections`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${careToken}` },
      body: { doctorId: docId }
    });
    console.log('✓ Caretaker Sent Request to Doctor 1:', careReq.data.message);
    const careReqId = careReq.data.data.id;

    // 14. Doctor 1 Accepts Caretaker Request
    await req(`${BASE_URL}/api/doctor-connections/${careReqId}/accept`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor 1 Accepted Caretaker Request');

    // 15. Doctor 1 Checks My Caretakers
    const myCaretakers = await req(`${BASE_URL}/api/doctor-connections/my-caretakers`, {
      headers: { Authorization: `Bearer ${docToken}` }
    });
    console.log('✓ Doctor 1 My Caretakers:', myCaretakers.data.data.map(c => `${c.fullName} (${c.relationship})`));

    // 16. Workflow 3: Reject Flow (Patient requests Doctor 2, Doctor 2 rejects)
    const patReq2 = await req(`${BASE_URL}/api/doctor-connections`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${patToken}` },
      body: { doctorId: doc2Id }
    });
    console.log('✓ Patient Sent Request to Doctor 2');
    const req2Id = patReq2.data.data.id;

    const rejectRes = await req(`${BASE_URL}/api/doctor-connections/${req2Id}/reject`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${doc2Token}` }
    });
    console.log('✓ Doctor 2 Rejected Request:', rejectRes.data.message);

    // 17. Patient checks search results for Doctor 2 status
    const searchAfterReject = await req(`${BASE_URL}/api/doctors?name=Rajiv`, {
      headers: { Authorization: `Bearer ${patToken}` }
    });
    console.log('✓ Status for Doctor 2 after rejection:', searchAfterReject.data.data[0]?.connectionStatus);

    // 18. Patient re-requests after rejection (Allowed)
    const reRequest = await req(`${BASE_URL}/api/doctor-connections`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${patToken}` },
      body: { doctorId: doc2Id }
    });
    console.log('✓ Patient Re-requested after rejection:', reRequest.data.message);

    console.log('\n========================================');
    console.log('🎉 ALL 18 BACKEND DOCTOR WORKFLOW TESTS PASSED!');
    console.log('========================================\n');
  } catch (error) {
    console.error('✗ Test failed:', error.data || error.message);
    process.exit(1);
  }
}

runTests();
