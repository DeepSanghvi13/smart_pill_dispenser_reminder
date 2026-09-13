require('dotenv').config({ path: './.env' });
const mysql = require('mysql2/promise');

async function main() {
  const conn = await mysql.createConnection({
    host: process.env.MYSQL_HOST || 'localhost',
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQL_DATABASE || 'smart_pill_reminder',
    port: Number(process.env.MYSQL_PORT || 3306)
  });

  const [allUsers] = await conn.query("SELECT id, fullName, email, role FROM users");
  console.log('--- ALL USERS ---');
  console.table(allUsers);

  const [doctorUsers] = await conn.query("SELECT id, fullName, email, role FROM users WHERE role = 'doctor'");
  console.log('--- DOCTOR USERS ---');
  console.table(doctorUsers);

  const [doctorProfiles] = await conn.query("SELECT * FROM doctors");
  console.log('--- DOCTOR PROFILES ---');
  console.table(doctorProfiles);

  const [connections] = await conn.query("SELECT * FROM doctor_connections");
  console.log('--- DOCTOR CONNECTIONS ---');
  console.table(connections);

  const [patients] = await conn.query("SELECT * FROM patients");
  console.log('--- PATIENTS ---');
  console.table(patients);

  const [caretakers] = await conn.query("SELECT * FROM caretakers");
  console.log('--- CARETAKERS ---');
  console.table(caretakers);

  await conn.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
