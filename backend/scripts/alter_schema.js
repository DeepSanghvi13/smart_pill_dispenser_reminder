require('dotenv').config({ path: '../.env' });
const { connectMySQL, query, disconnectMySQL } = require('../src/db');

async function alterSchema() {
  await connectMySQL();
  try {
    console.log("Applying schema alterations...");
    
    // Users table
    try {
      await query("ALTER TABLE users ADD COLUMN timezone VARCHAR(100) DEFAULT 'UTC'");
      console.log("Added timezone to users.");
    } catch(e) { console.log(e.message); }

    // Medicines table
    try {
      await query("ALTER TABLE medicines ADD COLUMN sideEffects TEXT DEFAULT NULL");
      await query("ALTER TABLE medicines ADD COLUMN storageInstructions TEXT DEFAULT NULL");
      console.log("Added sideEffects, storageInstructions to medicines.");
    } catch(e) { console.log(e.message); }

    // Doctors table
    try {
      await query("ALTER TABLE doctors ADD COLUMN isVerified BOOLEAN DEFAULT FALSE");
      console.log("Added isVerified to doctors.");
    } catch(e) { console.log(e.message); }

    // Shop medicines
    try {
      await query("ALTER TABLE shop_medicines ADD COLUMN sideEffects TEXT DEFAULT NULL");
      await query("ALTER TABLE shop_medicines ADD COLUMN storageInstructions TEXT DEFAULT NULL");
      console.log("Added sideEffects, storageInstructions to shop_medicines.");
    } catch(e) { console.log(e.message); }

    // Prescriptions
    try {
      await query("ALTER TABLE prescriptions ADD COLUMN isRenewable BOOLEAN DEFAULT FALSE");
      await query("ALTER TABLE prescriptions ADD COLUMN renewalsLeft INT DEFAULT 0");
      console.log("Added isRenewable, renewalsLeft to prescriptions.");
    } catch(e) { console.log(e.message); }

    // Doctor feedback table
    try {
      await query(`CREATE TABLE IF NOT EXISTS doctor_feedback (
        id INT AUTO_INCREMENT PRIMARY KEY,
        doctorId INT NOT NULL,
        patientId INT NOT NULL,
        medicineId INT DEFAULT NULL,
        feedbackText TEXT NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_feedback_doctorId FOREIGN KEY (doctorId) REFERENCES users (id) ON DELETE CASCADE,
        CONSTRAINT fk_feedback_patientId FOREIGN KEY (patientId) REFERENCES users (id) ON DELETE CASCADE,
        CONSTRAINT fk_feedback_medicineId FOREIGN KEY (medicineId) REFERENCES medicines (id) ON DELETE SET NULL,
        INDEX idx_feedback_patient (patientId)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
      console.log("Created doctor_feedback table.");
    } catch(e) { console.log(e.message); }

    console.log("Schema update complete.");
  } catch (error) {
    console.error("Failed to alter schema:", error);
  } finally {
    await disconnectMySQL();
  }
}

alterSchema();
