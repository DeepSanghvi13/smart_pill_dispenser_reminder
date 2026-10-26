const jwt = require('jsonwebtoken');
const { query } = require('./db');
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_pill_dispenser';

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ ok: false, message: 'Access token required' });
  }
  
  jwt.verify(token, JWT_SECRET, async (err, decoded) => {
    if (err) {
      return res.status(403).json({ ok: false, message: 'Invalid or expired token' });
    }
    try {
      const users = await query('SELECT id, email, role, status FROM users WHERE id = ? LIMIT 1', [decoded.id]);
      const user = users[0];
      if (!user || user.status !== 'active') {
        return res.status(403).json({ ok: false, message: 'Account is inactive' });
      }
      req.user = {
        ...decoded,
        id: user.id,
        email: user.email,
        role: user.role,
        isAdmin: user.role === 'admin'
      };
      next();
    } catch (error) {
      console.error('Authenticated user status lookup failed:', error.message);
      return res.status(500).json({ ok: false, message: 'Unable to verify account status' });
    }
  });
}

function requireRole(roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ ok: false, message: 'Access token required' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ ok: false, message: 'Access denied: unauthorized role' });
    }
    next();
  };
}

module.exports = {
  authenticateToken,
  requireRole,
  JWT_SECRET
};
