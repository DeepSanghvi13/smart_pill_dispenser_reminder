const request = require('supertest');
const jwt = require('jsonwebtoken');

jest.mock('../src/db', () => ({
  query: jest.fn(),
  transaction: jest.fn(),
  ping: jest.fn(),
  connectMySQL: jest.fn(),
  disconnectMySQL: jest.fn()
}));

const db = require('../src/db');
const { app } = require('../src/server');

const JWT_SECRET = 'super_secret_key_pill_dispenser';

function token(user) {
  return jwt.sign(user, JWT_SECRET);
}

const adminToken = () => token({ id: 1, email: 'admin@example.com', role: 'admin' });
const patientToken = () => token({ id: 2, email: 'patient@example.com', role: 'patient' });

beforeEach(() => {
  jest.clearAllMocks();
  db.query.mockImplementation(async (sql, params = []) => {
    if (sql.includes('SELECT id, email, role, status FROM users WHERE id =')) {
      return params[0] === 2
        ? [{ id: 2, email: 'patient@example.com', role: 'patient', status: 'active' }]
        : params[0] === 3
          ? [{ id: 3, email: 'inactive@example.com', role: 'admin', status: 'inactive' }]
        : [{ id: 1, email: 'admin@example.com', role: 'admin', status: 'active' }];
    }
    if (sql.includes('SELECT email, role FROM users WHERE id =')) return [];
    if (sql.includes('SELECT id, role FROM users WHERE id =')) {
      return [{ id: 2, role: 'patient' }];
    }
    if (sql.includes('SELECT id FROM users WHERE email =')) return [];
    if (sql.includes('SELECT COUNT(*) AS total')) return [{ total: 0 }];
    if (sql.includes('SELECT id, fullName, email, phoneNumber')) return [];
    if (sql.includes('SELECT role, COUNT(*)')) return [];
    if (sql.includes('COUNT(*)')) return [{ count: 0 }];
    if (sql.startsWith('DELETE FROM')) return { affectedRows: 0 };
    if (sql.includes('FROM doctor_connections')) return [];
    if (sql.includes('FROM caretaker_connections')) return [];
    if (sql.includes('FROM pharmacy_connections')) return [];
    if (sql.startsWith('INSERT INTO activity_logs')) return { affectedRows: 1 };
    return { affectedRows: 1 };
  });
  db.transaction.mockImplementation(async (callback) => callback({
    query: jest.fn(async (sql) => {
      if (sql.includes('SELECT id FROM users WHERE email =')) return [];
      if (sql.startsWith('INSERT INTO users')) return { insertId: 7 };
      return { affectedRows: 1 };
    })
  }));
});

describe('admin dashboard', () => {
  test('returns independent statistics', async () => {
    const response = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${adminToken()}`);

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      ok: true,
      stats: { activeUsers: 0, medicines: 0, prescriptions: 0, orders: 0 }
    });
  });

  test('rejects a non-admin token', async () => {
    const response = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${patientToken()}`);

    expect(response.status).toBe(403);
  });

  test('rejects an inactive account token', async () => {
    const response = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${token({ id: 3, email: 'inactive@example.com', role: 'admin' })}`);

    expect(response.status).toBe(403);
  });
});

describe('admin users', () => {
  test('creates a user and profile transactionally', async () => {
    const response = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({
        fullName: 'New Patient',
        email: 'new.patient@example.com',
        password: 'password8',
        role: 'patient'
      });

    expect(response.status).toBe(201);
    expect(db.transaction).toHaveBeenCalledTimes(1);
  });

  test('rejects invalid password input', async () => {
    const response = await request(app)
      .post('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({
        fullName: 'New Patient',
        email: 'new.patient@example.com',
        password: 'short',
        role: 'patient'
      });

    expect(response.status).toBe(400);
  });

  test('returns 404 for a nonexistent user update', async () => {
    db.query.mockImplementationOnce(async () => [
      { id: 1, email: 'admin@example.com', role: 'admin', status: 'active' }
    ]).mockImplementationOnce(async () => []);

    const response = await request(app)
      .put('/api/admin/users/999')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ fullName: 'Missing User' });

    expect(response.status).toBe(404);
  });

  test('rejects a non-admin user management request', async () => {
    const response = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${patientToken()}`);

    expect(response.status).toBe(403);
  });
});

describe('admin connections', () => {
  test('returns all connection groups', async () => {
    const response = await request(app)
      .get('/api/admin/connections')
      .set('Authorization', `Bearer ${adminToken()}`);

    expect(response.status).toBe(200);
    expect(response.body.connections).toEqual({
      doctorConnections: [],
      caretakerConnections: [],
      pharmacyConnections: []
    });
  });

  test('rejects an invalid connection type', async () => {
    const response = await request(app)
      .post('/api/admin/connections')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ type: 'invalid', patientId: 2, targetId: 3 });

    expect(response.status).toBe(400);
  });

  test('returns 404 for a nonexistent connection deletion', async () => {
    const response = await request(app)
      .delete('/api/admin/connections/doctor/999')
      .set('Authorization', `Bearer ${adminToken()}`);

    expect(response.status).toBe(404);
  });

  test('rejects a non-admin connection request', async () => {
    const response = await request(app)
      .get('/api/admin/connections')
      .set('Authorization', `Bearer ${patientToken()}`);

    expect(response.status).toBe(403);
  });
});
