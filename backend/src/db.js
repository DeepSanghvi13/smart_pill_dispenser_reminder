const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

let pool;

async function connectMySQL() {
  const host = process.env.MYSQL_HOST || 'localhost';
  const user = process.env.MYSQL_USER || 'root';
  const password = process.env.MYSQL_PASSWORD || '';
  const port = Number(process.env.MYSQL_PORT || 3306);
  const database = process.env.MYSQL_DATABASE || 'smart_pill_reminder';

  // Read the schema.sql file
  const schemaPath = path.join(__dirname, '..', 'sql', 'schema.sql');
  const schemaSql = fs.readFileSync(schemaPath, 'utf8');

  // Create connection with multipleStatements enabled to run the schema DDL
  const tempConn = await mysql.createConnection({
    host,
    user,
    password,
    port,
    multipleStatements: true
  });
  
  // Run DDL script (creates database and all tables)
  await tempConn.query(schemaSql);
  await tempConn.end();

  // Initialize pool
  pool = mysql.createPool({
    host,
    user,
    password,
    database,
    port,
    waitForConnections: true,
    connectionLimit: 10,
    maxIdle: 10,
    idleTimeout: 60000,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
  });

  // Verify pool works
  const conn = await pool.getConnection();
  conn.release();
}

async function query(sql, params) {
  if (!pool) {
    throw new Error('MySQL connection pool has not been initialized');
  }
  const [results] = await pool.query(sql, params);
  return results;
}

async function ping() {
  await query('SELECT 1');
}

async function disconnectMySQL() {
  if (pool) {
    await pool.end();
  }
}

async function generateNextId(tableName, userId) {
  const rows = await query(
    `SELECT COALESCE(MAX(id), 0) AS maxId FROM \`${tableName}\` WHERE userId = ?`,
    [userId]
  );
  return Number(rows[0]?.maxId ?? 0) + 1;
}

module.exports = {
  connectMySQL,
  query,
  ping,
  disconnectMySQL,
  generateNextId
};
