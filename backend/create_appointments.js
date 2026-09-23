require('dotenv').config();
const { query, connectMySQL, disconnectMySQL } = require('./src/db');

async function run() {
  await connectMySQL();
  try {
    await query(`
      CREATE TABLE IF NOT EXISTS \`appointments\` (
        \`id\` INT AUTO_INCREMENT PRIMARY KEY,
        \`patientId\` INT NOT NULL,
        \`doctorId\` INT NOT NULL,
        \`appointmentDate\` DATE NOT NULL,
        \`appointmentTime\` VARCHAR(50) NOT NULL,
        \`reason\` TEXT DEFAULT NULL,
        \`status\` ENUM('pending', 'approved', 'rejected', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
        \`createdAt\` DATETIME DEFAULT CURRENT_TIMESTAMP,
        \`updatedAt\` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT \`fk_appt_patientId\` FOREIGN KEY (\`patientId\`) REFERENCES \`users\` (\`id\`) ON DELETE CASCADE,
        CONSTRAINT \`fk_appt_doctorId\` FOREIGN KEY (\`doctorId\`) REFERENCES \`users\` (\`id\`) ON DELETE CASCADE,
        INDEX \`idx_appt_date\` (\`appointmentDate\`),
        INDEX \`idx_appt_patient\` (\`patientId\`),
        INDEX \`idx_appt_doctor\` (\`doctorId\`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log('Appointments table created.');
  } catch (err) {
    console.error(err);
  } finally {
    await disconnectMySQL();
  }
}
run();
