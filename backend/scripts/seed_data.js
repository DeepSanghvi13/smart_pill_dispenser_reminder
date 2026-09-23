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
    const doctorIds = [];
    const caretakerIds = [];
    const shopIds = [];

    // 1. Seed Patients
    console.log('Seeding 10 Patients...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Patient ${i}`, `patient${i}_${ts}@test.com`, `111${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'patient', 'active']
      );
      patientIds.push(res.insertId);
      await query(`INSERT INTO patients (userId, gender, birthDate, zipCode) VALUES (?, ?, ?, ?)`, [res.insertId, 'Male', '1990-01-01', '10001']);
    }

    // 2. Seed Doctors
    console.log('Seeding 10 Doctors...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Doctor ${i}`, `doctor${i}_${ts}@test.com`, `222${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'doctor', 'active']
      );
      doctorIds.push(res.insertId);
      await query(`INSERT INTO doctors (userId, specialization, hospitalName) VALUES (?, ?, ?)`, [res.insertId, 'General Practice', 'General Hospital']);
    }

    // 3. Seed Caretakers
    console.log('Seeding 10 Caretakers...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Caretaker ${i}`, `caretaker${i}_${ts}@test.com`, `333${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'caretaker', 'active']
      );
      caretakerIds.push(res.insertId);
      await query(`INSERT INTO caretakers (userId, relationship) VALUES (?, ?)`, [res.insertId, 'Family Member']);
    }

    // 4. Seed Pharmacies
    console.log('Seeding 10 Pharmacies...');
    for (let i = 1; i <= 10; i++) {
      const res = await query(
        `INSERT INTO users (fullName, email, phoneNumber, passwordHash, role, status) VALUES (?, ?, ?, ?, ?, ?)`,
        [`Pharmacy Owner ${i}`, `pharmacy${i}_${ts}@test.com`, `444${ts.toString().slice(-4)}${i.toString().padStart(3, '0')}`, passwordHash, 'pharmacy', 'active']
      );
      await query(`INSERT INTO medical_shops (userId, shopName, ownerName, email) VALUES (?, ?, ?, ?)`, [res.insertId, `City Pharmacy ${i}`, `Owner ${i}`, `shop${i}@test.com`]);
      const shopRes = await query(`SELECT id FROM medical_shops WHERE userId = ?`, [res.insertId]);
      shopIds.push(shopRes[0].id);
    }

    // 5. Seed Connections & Features
    console.log('Seeding Connections and Features...');
    for (let i = 0; i < 10; i++) {
      const pId = patientIds[i];
      const dId = doctorIds[i];
      const cId = caretakerIds[i];
      const sId = shopIds[i];

      // Connections
      await query(`INSERT IGNORE INTO doctor_connections (doctorId, requesterId, requesterRole, status) VALUES (?, ?, 'patient', 'accepted')`, [dId, pId]);
      await query(`INSERT IGNORE INTO caretaker_connections (patientId, caretakerId, connectionCode, status) VALUES (?, ?, 'CODE123', 'connected')`, [pId, cId]);
      await query(`INSERT IGNORE INTO pharmacy_connections (patientId, shopId, status) VALUES (?, ?, 'accepted')`, [pId, sId]);

      // Medicines for Patient
      const medRes = await query(`INSERT INTO medicines (userId, name, type, dosage, quantity, frequency, time, startDate, endDate, status, createdBy, updatedBy) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, 
        [pId, `Aspirin ${i}`, 'tablets', '500mg', '1 Pill', 'Daily', '08:00', '2026-01-01', '2026-12-31', 'active', pId, pId]);
      
      // Shop Medicine Inventory
      const shopMedRes = await query(`INSERT INTO shop_medicines (shopId, name, category, price, stockQuantity, expiryDate) VALUES (?, ?, ?, ?, ?, ?)`, 
        [sId, `Paracetamol ${i}`, 'Tablets', 10.99, 100, '2028-01-01']);
        
      // Prescription
      await query(`INSERT INTO prescriptions (doctorId, patientId, medicineName, dosage, frequency, duration, quantity) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [dId, pId, `Ibuprofen ${i}`, '200mg', 'Twice daily', '7 days', 14]);

      // Medicine Order
      await query(`INSERT INTO medicine_orders (orderNumber, patientId, shopId, totalAmount, status) VALUES (?, ?, ?, ?, ?)`,
        [`ORD-${Date.now()}-${i}`, pId, sId, 10.99, 'pending']);
        
      // Appointment
      await query(`INSERT INTO appointments (patientId, doctorId, appointmentDate, appointmentTime, status) VALUES (?, ?, ?, ?, ?)`,
        [pId, dId, '2026-10-01', '10:00 AM', 'approved']);
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
