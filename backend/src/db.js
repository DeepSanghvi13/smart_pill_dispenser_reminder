const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || '127.0.0.1',
  port: Number(process.env.MYSQL_PORT || 3306),
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || '',
  database: process.env.MYSQL_DATABASE || 'smart_pill_reminder',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

async function query(sql, params = []) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

async function ping() {
  const connection = await pool.getConnection();
  try {
    await connection.ping();
    await connection.query('SELECT 1');
  } finally {
    connection.release();
  }
}

module.exports = {
  pool,
  query,
  ping,
};

