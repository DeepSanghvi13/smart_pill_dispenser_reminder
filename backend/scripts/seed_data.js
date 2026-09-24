const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { connectMySQL, query, disconnectMySQL } = require('../src/db');
const bcrypt = require('bcryptjs');

async function seedDatabase() {
  console.log('Connecting to database...');
  await connectMySQL();
  console.log('Connected!');

  try {
    const passwordHash = await bcrypt.hash('password123', 10);
    
    const ts = Date.now();
    
    // Arrays to hold inserted IDs
    const patientIds = [];
    const caretakerIds = [];
    const shopIds = [];

    // Seed Admin
    console.log('Seeding Admin...');
    const adminEmail = 'admin_test@smartpill.com';
    const existingAdmin = await query('SELECT id FROM users WHERE email = ?', [adminEmail]);
    if (existingAdmin.length === 0) {
      const aRes = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        ['Super Admin Test', adminEmail, '9999999999', passwordHash, 'admin', 'active']
      );
      await query(`INSERT IGNORE INTO admins (userId) VALUES (?)`, [aRes.insertId]);
    }

    // 1. Seed 10 Patients
    console.log('Seeding 10 Patients...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Patient ${i}`, `patient${i}_${ts}@test.com`, `111${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'patient', 'active']
      );
      patientIds.push(res.insertId);
      await query(`INSERT INTO patients (userId, gender, birthDate, zipCode) VALUES (?, ?, ?, ?)`, [res.insertId, 'Male', '1990-01-01', '10001']);
      await query(`INSERT INTO userProfiles (userId, firstName, lastName, email) VALUES (?, ?, ?, ?)`, [res.insertId, 'Patient', `${i}`, `patient${i}_${ts}@test.com`]);
    }

    // 2. Seed 10 Caretakers
    console.log('Seeding 10 Caretakers...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Caretaker ${i}`, `caretaker${i}_${ts}@test.com`, `333${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'caretaker', 'active']
      );
      caretakerIds.push(res.insertId);
      await query(`INSERT INTO caretakers (userId, relationship) VALUES (?, ?)`, [res.insertId, 'Family Member']);
    }

    // 3. Seed 10 Pharmacies
    console.log('Seeding 10 Pharmacies...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Pharmacy Owner ${i}`, `pharmacy${i}_${ts}@test.com`, `444${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'pharmacy', 'active']
      );
      await query(`INSERT INTO medical_shops (userId, shopName, ownerName, email) VALUES (?, ?, ?, ?)`, [res.insertId, `City Pharmacy ${i}`, `Owner ${i}`, `shop${i}_${ts}@test.com`]);
      const shopRes = await query(`SELECT id FROM medical_shops WHERE userId = ?`, [res.insertId]);
      shopIds.push(shopRes[0].id);
    }

    // 4. Connect and Seed All Data for Patients
    console.log('Seeding 10 Doctors per patient, Prescriptions, Orders, and all features...');
    for (let i = 0; i < 10; i++) {
      const pId = patientIds[i];
      const cId = caretakerIds[i];
      const sId = shopIds[i];

      // A) Caretaker Connection (Allocate 1 individual caretaker)
      await query(`INSERT IGNORE INTO caretaker_connections (patientId, caretakerId, connectionCode, status) VALUES (?, ?, 'CODE123', 'connected')`, [pId, cId]);

      // B) Pharmacy Connection
      await query(`INSERT IGNORE INTO pharmacy_connections (patientId, shopId, status) VALUES (?, ?, 'accepted')`, [pId, sId]);

      // C) Create a shop medicine
      const shopMedRes = await query(`INSERT INTO shop_medicines (shopId, name, category, price, stockQuantity, expiryDate) VALUES (?, ?, ?, ?, ?, ?)`, 
        [sId, `Paracetamol ${i}`, 'Tablets', 15.00, 100, '2028-01-01']);
      const shopMedId = shopMedRes.insertId;

      // Add patient medicine
      const medRes = await query(`INSERT INTO medicines (userId, name, type, dosage, quantity, frequency, time, startDate, endDate, status, createdBy, updatedBy) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, 
        [pId, `Aspirin ${i}`, 'tablets', '500mg', '1 Pill', 'Daily', '08:00', '2026-01-01', '2026-12-31', 'active', pId, pId]);
      const medId = medRes.insertId;

      // D) Add 10 Doctors for EACH patient, and 1 prescription from each
      for (let j = 1; j <= 10; j++) {
        const dRes = await query(
          `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
          [`Doctor ${i}_${j}`, `doctor${i}_${j}_${ts}@test.com`, `222${ts.toString().slice(-5)}${i}${j.toString().padStart(2, '0')}`, passwordHash, 'doctor', 'active']
        );
        const dId = dRes.insertId;
        await query(`INSERT INTO doctors (userId, specialization, hospitalName) VALUES (?, ?, ?)`, [dId, 'General Practice', 'General Hospital']);
        
        // Connect Doctor
        await query(`INSERT IGNORE INTO doctor_connections (doctorId, requesterId, requesterRole, status) VALUES (?, ?, 'patient', 'accepted')`, [dId, pId]);

        // Add Prescription (Total 10 per patient)
        await query(`INSERT INTO prescriptions (doctorId, patientId, medicineName, dosage, frequency, duration, quantity, shopMedicineId) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [dId, pId, `Medicine ${j}`, '200mg', 'Twice daily', '7 days', 14, shopMedId]);
          
        // Appointment
        await query(`INSERT INTO appointments (patientId, doctorId, appointmentDate, appointmentTime, status) VALUES (?, ?, ?, ?, ?)`,
          [pId, dId, '2026-10-01', '10:00 AM', 'approved']);
          
        // Doctor feedback
        await query(`INSERT INTO doctor_feedback (doctorId, patientId, feedbackText, medicineId) VALUES (?, ?, ?, ?)`, [dId, pId, 'Patient is adhering well to the medication schedule.', medId]);
      }

      // Add Reminder and Alarm Log
      await query(`INSERT INTO reminders (userId, medicineId, time, daysOfWeek, isActive) VALUES (?, ?, ?, ?, ?)`, [pId, medId, '08:00', '["Monday","Tuesday"]', 1]);
      await query(`INSERT INTO alarmLogs (userId, medicineId, medicineName, scheduledTime, status) VALUES (?, ?, ?, NOW(), ?)`, [pId, medId, `Aspirin ${i}`, 'taken']);

      // Buy medicine & Payment Gateway integration
      // Creating a medicine order via 'Online Payment Gateway'
      const orderNumber = `ORD-${ts}-${i}`;
      const orderRes = await query(`INSERT INTO medicine_orders (orderNumber, patientId, shopId, totalAmount, status, paymentMethod) VALUES (?, ?, ?, ?, ?, ?)`,
        [orderNumber, pId, sId, 150.00, 'accepted', 'Online Payment Gateway (Stripe)']);
      const orderId = orderRes.insertId;
      
      await query(`INSERT INTO medicine_order_items (orderId, shopMedicineId, medicineName, price, quantity, subtotal) VALUES (?, ?, ?, ?, ?, ?)`,
        [orderId, shopMedId, `Paracetamol ${i}`, 15.00, 10, 150.00]);

      // All other features:
      // Notifications
      await query(`INSERT INTO notifications (userId, title, body, type, isRead) VALUES (?, ?, ?, ?, ?)`, [pId, 'Welcome', 'Welcome to Smart Pill Dispenser', 'alert', 0]);
      // Activity Logs
      await query(`INSERT INTO activity_logs (userId, userRole, activityType, description, status) VALUES (?, 'patient', 'LOGIN', 'User logged in', 'SUCCESS')`, [pId]);
      await query(`INSERT INTO activity_logs (userId, userRole, activityType, description, status) VALUES (?, 'patient', 'PAYMENT', 'Payment successful via Gateway', 'SUCCESS')`, [pId]);
      // Dependents
      await query(`INSERT INTO dependents (userId, firstName, lastName, gender, birthDate, color) VALUES (?, ?, ?, ?, ?, ?)`, [pId, 'Child', 'One', 'Male', '2015-01-01', '#ff0000']);
      // Professional Review Requests
      await query(`INSERT INTO professionalReviewRequests (userId, patientName, contact, concern) VALUES (?, ?, ?, ?)`, [pId, `Patient ${i}`, '1234567890', 'Routine review.']);
    }

    console.log('Seeding Complete! You can log in with:');
    console.log('Email: patient1@test.com / password123');
    console.log('Email: doctor1@test.com / password123');
    console.log('Email: caretaker1@test.com / password123');
    console.log('Email: pharmacy1@test.com / password123');

  } catch (error) {
    console.error('Seeding Error:', error);
  } finally {
    await disconnectMySQL();
  }
}

seedDatabase();
