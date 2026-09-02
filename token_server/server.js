const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

const HMS_APP_ACCESS_KEY = process.env.HMS_APP_ACCESS_KEY || 'dev_access_key_placeholder';
const HMS_APP_SECRET = process.env.HMS_APP_SECRET || 'dev_secret_placeholder';
const HMS_DEFAULT_ROOM_ID = process.env.HMS_DEFAULT_ROOM_ID || 'room_wtf_default_01';

// Masking helper for security & privacy
function maskSecret(str) {
  if (!str || str.length < 6) return '******';
  return str.slice(0, 3) + '***' + str.slice(-3);
}

// Observability logger
function logStructured(tag, message, meta = {}) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${tag}] ${message}`, Object.keys(meta).length ? JSON.stringify(meta) : '');
}

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '100ms-token-server',
    accessKey: maskSecret(HMS_APP_ACCESS_KEY),
    defaultRoom: HMS_DEFAULT_ROOM_ID,
  });
});

/**
 * Main 100ms Auth Token endpoint
 * GET /token?userId=<id>&role=<role>&roomId=<roomId>
 */
app.get('/token', (req, res) => {
  const { userId = 'user_' + uuidv4().slice(0, 6), role = 'member', roomId = HMS_DEFAULT_ROOM_ID } = req.query;

  if (!role) {
    logStructured('RTC', 'Token generation failed: missing role', { userId });
    return res.status(400).json({ error: 'Role is required (trainer|member)' });
  }

  try {
    const nowSec = Math.floor(Date.now() / 1000);
    const payload = {
      access_key: HMS_APP_ACCESS_KEY,
      room_id: roomId,
      user_id: userId,
      role: role.toLowerCase(),
      type: 'app',
      version: 2,
      iat: nowSec,
      nbf: nowSec,
      exp: nowSec + (24 * 60 * 60), // 24 hours validity
      jti: uuidv4(),
    };

    const token = jwt.sign(payload, HMS_APP_SECRET, { algorithm: 'HS256' });

    logStructured('RTC', `Generated auth token for user=${userId}, role=${role}, room=${roomId}`);

    return res.json({
      token,
      userId,
      role,
      roomId,
      expiresIn: 86400,
    });
  } catch (error) {
    logStructured('RTC', 'Token generation error', { error: error.message });
    return res.status(500).json({ error: 'Failed to generate token', details: error.message });
  }
});

/**
 * Mock Room Management helper endpoint
 * POST /api/rooms
 */
app.post('/api/rooms', (req, res) => {
  const { name = 'Consultation Room', description = '1-on-1 Fitness Session' } = req.body;
  const newRoomId = 'room_' + uuidv4().slice(0, 8);
  logStructured('RTC', `Created virtual room: ${newRoomId}`, { name, description });
  res.status(201).json({
    id: newRoomId,
    name,
    description,
    createdAt: new Date().toISOString(),
    roles: ['trainer', 'member']
  });
});

app.listen(PORT, () => {
  logStructured('AUTH', `100ms Token Server running on http://localhost:${PORT}`);
  logStructured('AUTH', `App Access Key: ${maskSecret(HMS_APP_ACCESS_KEY)}`);
});
