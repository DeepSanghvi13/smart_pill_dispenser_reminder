require('dotenv').config({ path: './.env' });
const mysql = require('mysql2/promise');

async function cleanDoctors() {
  console.log('====================================================');
  console.log('Starting MySQL Safe Doctor Records Cleanup...');
  console.log('====================================================\n');

  const conn = await mysql.createConnection({
    host: process.env.MYSQL_HOST || 'localhost',
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQL_DATABASE || 'smart_pill_reminder',
    port: Number(process.env.MYSQL_PORT || 3306),
    multipleStatements: true,
  });

  try {
    // 1. Inspect all existing doctor accounts
    const [doctors] = await conn.query(
      `SELECT u.id, u.fullName, u.email, u.role, u.createdAt,
              d.specialization, d.licenseNumber, d.hospitalName, d.location
       FROM users u
       LEFT JOIN doctors d ON u.id = d.userId
       WHERE u.role = 'doctor'`
    );

    console.log(`Found ${doctors.length} doctor account(s) in database:`);
    console.table(doctors);

    // 2. Identify Doctor "Man"
    const manDoctor = doctors.find(
      (d) =>
        d.fullName.trim().toLowerCase() === 'man' ||
        d.email.trim().toLowerCase() === 'man@gmail.com'
    );

    if (!manDoctor) {
      console.error('ERROR: Doctor "Man" was not found in the database. Aborting to avoid data loss.');
      process.exit(1);
    }

    console.log(`\nDoctor "Man" identified:`);
    console.log(`- ID: ${manDoctor.id}`);
    console.log(`- Full Name: ${manDoctor.fullName}`);
    console.log(`- Email: ${manDoctor.email}`);
    console.log(`- Specialization: ${manDoctor.specialization || 'Cardiologist'}`);
    console.log(`- Status: PRESERVE & KEEP ACTIVE\n`);

    // 3. Identify Doctors to remove
    const doctorsToRemove = doctors.filter((d) => d.id !== manDoctor.id);

    if (doctorsToRemove.length === 0) {
      console.log('No unwanted/extra doctor accounts found in the database.');
      console.log('Doctor "Man" is already the only doctor record.\n');
    } else {
      console.log(`Identified ${doctorsToRemove.length} unwanted doctor account(s) to remove:`);
      console.table(doctorsToRemove);

      const idsToRemove = doctorsToRemove.map((d) => d.id);

      // Begin Transaction
      await conn.beginTransaction();

      // Delete connection records for unwanted doctors
      await conn.query(
        `DELETE FROM doctor_connections WHERE doctorId IN (?)`,
        [idsToRemove]
      );

      // Delete doctor profile records
      await conn.query(
        `DELETE FROM doctors WHERE userId IN (?)`,
        [idsToRemove]
      );

      // Delete userProfile records for unwanted doctors
      await conn.query(
        `DELETE FROM userProfiles WHERE userId IN (?)`,
        [idsToRemove]
      );

      // Delete user account records for unwanted doctors
      await conn.query(
        `DELETE FROM users WHERE id IN (?) AND role = 'doctor'`,
        [idsToRemove]
      );

      await conn.commit();
      console.log(`Successfully removed ${doctorsToRemove.length} unwanted doctor account(s).\n`);
    }

    // 4. Verify post-cleanup database state
    console.log('====================================================');
    console.log('Post-Cleanup Verification:');
    console.log('====================================================\n');

    const [remainingDoctorUsers] = await conn.query(
      `SELECT id, fullName, email, role FROM users WHERE role = 'doctor'`
    );
    console.log('Remaining Doctor Users in `users` table:');
    console.table(remainingDoctorUsers);

    const [remainingDoctorProfiles] = await conn.query(
      `SELECT * FROM doctors`
    );
    console.log('Remaining Doctor Profiles in `doctors` table:');
    console.table(remainingDoctorProfiles);

    const [nonDoctorUsers] = await conn.query(
      `SELECT id, fullName, email, role FROM users WHERE role != 'doctor'`
    );
    console.log('Preserved Non-Doctor Users (Patients, Caretakers, Admins):');
    console.table(nonDoctorUsers);

    const [patientProfiles] = await conn.query(`SELECT * FROM patients`);
    console.log(`Preserved Patient records: ${patientProfiles.length}`);

    const [caretakerProfiles] = await conn.query(`SELECT * FROM caretakers`);
    console.log(`Preserved Caretaker records: ${caretakerProfiles.length}`);

    console.log('\nDatabase cleanup and safety verification completed successfully!');
  } catch (error) {
    await conn.rollback().catch(() => {});
    console.error('Error during doctor cleanup:', error);
    process.exit(1);
  } finally {
    await conn.end();
  }
}

cleanDoctors();
