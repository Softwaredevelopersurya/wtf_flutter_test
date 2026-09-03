const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;
const isVercel = Boolean(process.env.VERCEL);
const STATE_FILE_PATH = isVercel
  ? path.join('/tmp', 'state.json')
  : path.join(__dirname, 'state.json');

app.use(cors());
app.use(express.json());

const AGORA_APP_ID = process.env.AGORA_APP_ID || '5f80f33fd1d74126a1a810b136401168';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '3f98aba92ac3451dbc52bd9d2cd67b33';
const AGORA_DEFAULT_CHANNEL = process.env.AGORA_DEFAULT_CHANNEL || 'wtf_flutter_test';
const AGORA_TEMP_TOKEN = process.env.AGORA_TEMP_TOKEN || '007eJxTYIjbl1sul/OoJFKKo/GLnno010fdH4WqL19zv78lJfLzwgYFBtM0C4M0Y+O0FMMUcxNDI7NEw0QLQ4MkQ2MzEwNDQzMLReuZWQ2BjAyfHPazMDJAIIgvwFBekhafllNaUpJaFF+SWlzCwAAAoWYjlQ==';

// Masking helper for security & privacy
function maskSecret(str) {
  if (!str || str.length < 6) return '******';
  return str.slice(0, 4) + '***' + str.slice(-4);
}

// Observability logger
function logStructured(tag, message, meta = {}) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${tag}] ${message}`, Object.keys(meta).length ? JSON.stringify(meta) : '');
}

const DEFAULT_USERS = [
  {
    id: 'user_trainer_aarav',
    role: 'trainer',
    name: 'Aarav (Lead Trainer)',
    email: 'aarav.trainer@wtf.fitness',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  },
  {
    id: 'user_member_dk',
    role: 'member',
    name: 'DK',
    email: 'dk.member@wtf.fitness',
    assignedTrainerId: 'user_trainer_aarav',
    avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
  },
];

// In-Memory Shared Cross-App Sync State
let syncState = {
  version: 1,
  updatedAt: new Date().toISOString(),
  users: DEFAULT_USERS,
  messages: [],
  callRequests: [],
  sessionLogs: [],
  typing: {},
};

// State persistence helpers
function loadStateFromDisk() {
  try {
    if (fs.existsSync(STATE_FILE_PATH)) {
      const raw = fs.readFileSync(STATE_FILE_PATH, 'utf-8');
      if (raw.trim()) {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') {
          syncState = {
            version: parsed.version || 1,
            updatedAt: parsed.updatedAt || new Date().toISOString(),
            users: Array.isArray(parsed.users) && parsed.users.length ? parsed.users : DEFAULT_USERS,
            messages: Array.isArray(parsed.messages) ? parsed.messages : [],
            callRequests: Array.isArray(parsed.callRequests) ? parsed.callRequests : [],
            sessionLogs: Array.isArray(parsed.sessionLogs) ? parsed.sessionLogs : [],
            typing: parsed.typing || {},
          };
          logStructured('AUTH', `Restored sync state from disk (${syncState.users.length} users, ${syncState.messages.length} msgs, ${syncState.callRequests.length} calls)`);
        }
      }
    }
  } catch (err) {
    logStructured('AUTH', `Error loading state from disk: ${err.message}`);
  }
}

function saveStateToDisk() {
  try {
    fs.writeFileSync(STATE_FILE_PATH, JSON.stringify(syncState, null, 2), 'utf-8');
  } catch (err) {
    logStructured('AUTH', `Error saving state to disk: ${err.message}`);
  }
}

// Initial state load from disk
loadStateFromDisk();

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'agora-rtc-token-server',
    appId: maskSecret(AGORA_APP_ID),
    hasCertificate: Boolean(AGORA_APP_CERTIFICATE),
    defaultChannel: AGORA_DEFAULT_CHANNEL,
    messagesCount: syncState.messages.length,
    callRequestsCount: syncState.callRequests.length,
    usersCount: syncState.users.length,
  });
});

/**
 * Main Agora RTC Auth Token endpoint
 * GET /token?userId=<id>&role=<role>&channelName=<channel>&roomId=<channel>&uid=<uid>
 */
app.get(['/token', '/rtc/token', '/agora/token'], (req, res) => {
  const {
    userId = 'user_' + uuidv4().slice(0, 6),
    role = 'broadcaster',
    channelName = req.query.roomId || AGORA_DEFAULT_CHANNEL,
    roomId,
    uid = 0,
  } = req.query;

  const targetChannel = channelName || roomId || AGORA_DEFAULT_CHANNEL;
  const numericUid = Number(uid) || 0;

  try {
    let token = '';

    if (AGORA_APP_ID && AGORA_APP_CERTIFICATE) {
      // Generate official token using agora-token
      const rtcRole = role.toLowerCase() === 'audience' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
      const expireTime = 86400; // 24 hours

      token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        targetChannel,
        numericUid,
        rtcRole,
        expireTime,
        expireTime
      );
    } else if (AGORA_TEMP_TOKEN && (targetChannel === AGORA_DEFAULT_CHANNEL || targetChannel === 'wtf_flutter_test')) {
      token = AGORA_TEMP_TOKEN;
    } else {
      token = AGORA_TEMP_TOKEN;
    }

    logStructured('RTC', `Generated Agora token for user=${userId}, uid=${numericUid}, channel=${targetChannel}`);

    return res.json({
      token,
      rtcToken: token,
      appId: AGORA_APP_ID,
      userId,
      uid: numericUid,
      role,
      channelName: targetChannel,
      roomId: targetChannel,
      expiresIn: 86400,
    });
  } catch (error) {
    logStructured('RTC', 'Token generation error, falling back to temp token', { error: error.message });
    return res.json({
      token: AGORA_TEMP_TOKEN,
      rtcToken: AGORA_TEMP_TOKEN,
      appId: AGORA_APP_ID,
      userId,
      uid: numericUid,
      role,
      channelName: targetChannel,
      roomId: targetChannel,
      expiresIn: 86400,
    });
  }
});

/**
 * --- Cross-App Real-Time Sync API Endpoints ---
 */

// 1. Get full sync state
app.get('/api/sync', (req, res) => {
  res.json(syncState);
});

// 2. Post whole state or delta
app.post('/api/sync', (req, res) => {
  const incoming = req.body;
  if (incoming && typeof incoming === 'object') {
    if (Array.isArray(incoming.messages)) syncState.messages = incoming.messages;
    if (Array.isArray(incoming.callRequests)) syncState.callRequests = incoming.callRequests;
    if (Array.isArray(incoming.sessionLogs)) syncState.sessionLogs = incoming.sessionLogs;
    if (incoming.typing) syncState.typing = incoming.typing;
    if (Array.isArray(incoming.users)) syncState.users = incoming.users;
    syncState.updatedAt = new Date().toISOString();
    syncState.version += 1;
    saveStateToDisk();
  }
  res.json({ success: true, version: syncState.version, updatedAt: syncState.updatedAt });
});

// 3. Add or update single user
app.post('/api/sync/user', (req, res) => {
  const user = req.body;
  if (!user || !user.id) {
    return res.status(400).json({ error: 'Valid user object required' });
  }

  const existingIndex = syncState.users.findIndex((u) => u.id === user.id);
  if (existingIndex >= 0) {
    syncState.users[existingIndex] = user;
  } else {
    syncState.users.push(user);
  }

  syncState.updatedAt = new Date().toISOString();
  syncState.version += 1;
  saveStateToDisk();
  logStructured('AUTH', `Synced user: ${user.name} (id=${user.id}, role=${user.role})`);
  res.json({ success: true, user, version: syncState.version });
});

// 4. Add single message
app.post('/api/sync/message', (req, res) => {
  const message = req.body;
  if (!message || !message.id) {
    return res.status(400).json({ error: 'Valid message object required' });
  }

  const existingIndex = syncState.messages.findIndex((m) => m.id === message.id);
  if (existingIndex >= 0) {
    syncState.messages[existingIndex] = message;
  } else {
    syncState.messages.push(message);
  }

  syncState.updatedAt = new Date().toISOString();
  syncState.version += 1;
  saveStateToDisk();
  logStructured('CHAT', `Synced message: "${message.text}" (${message.senderId} -> ${message.receiverId})`);
  res.json({ success: true, message, version: syncState.version });
});

// 5. Mark messages as read
app.post('/api/sync/read', (req, res) => {
  const { chatId, currentUserId, otherUserId } = req.body;
  let updatedCount = 0;
  syncState.messages = syncState.messages.map((m) => {
    const matchesChat = m.chatId === chatId ||
      (otherUserId && ((m.senderId === currentUserId && m.receiverId === otherUserId) || (m.senderId === otherUserId && m.receiverId === currentUserId)));
    if (matchesChat && m.receiverId === currentUserId && m.status !== 'read') {
      updatedCount++;
      return { ...m, status: 'read' };
    }
    return m;
  });

  syncState.updatedAt = new Date().toISOString();
  syncState.version += 1;
  saveStateToDisk();
  res.json({ success: true, updatedCount, version: syncState.version });
});

// 6. Add / Update Call Request
app.post('/api/sync/call_request', (req, res) => {
  const request = req.body;
  if (!request || !request.id) {
    return res.status(400).json({ error: 'Valid call request required' });
  }

  const existingIndex = syncState.callRequests.findIndex((r) => r.id === request.id);
  if (existingIndex >= 0) {
    syncState.callRequests[existingIndex] = request;
  } else {
    syncState.callRequests.push(request);
  }

  syncState.updatedAt = new Date().toISOString();
  syncState.version += 1;
  saveStateToDisk();
  logStructured('SCHEDULE', `Synced call request: ${request.id} (Status: ${request.status})`);
  res.json({ success: true, request, version: syncState.version });
});

// 7. Add / Update Session Log
app.post('/api/sync/session_log', (req, res) => {
  const sessionLog = req.body;
  if (!sessionLog || !sessionLog.id) {
    return res.status(400).json({ error: 'Valid session log required' });
  }

  const existingIndex = syncState.sessionLogs.findIndex((s) => s.id === sessionLog.id);
  if (existingIndex >= 0) {
    syncState.sessionLogs[existingIndex] = sessionLog;
  } else {
    syncState.sessionLogs.unshift(sessionLog);
  }

  syncState.updatedAt = new Date().toISOString();
  syncState.version += 1;
  saveStateToDisk();
  logStructured('RTC', `Synced session log: ${sessionLog.id}`);
  res.json({ success: true, sessionLog, version: syncState.version });
});

// 8. Update Typing status
app.post('/api/sync/typing', (req, res) => {
  const { userId, isTyping } = req.body;
  if (userId) {
    syncState.typing[userId] = Boolean(isTyping);
    syncState.updatedAt = new Date().toISOString();
  }
  res.json({ success: true, typing: syncState.typing });
});

/**
 * Virtual Channel Management helper endpoint
 */
app.post(['/api/channels', '/api/rooms'], (req, res) => {
  const { name = 'Consultation Channel', description = '1-on-1 Fitness Session' } = req.body;
  const newChannelId = AGORA_DEFAULT_CHANNEL;
  logStructured('RTC', `Virtual Agora channel: ${newChannelId}`, { name, description });
  res.status(201).json({
    id: newChannelId,
    channelName: newChannelId,
    name,
    description,
    createdAt: new Date().toISOString(),
    roles: ['broadcaster', 'audience', 'publisher']
  });
});

// JSON parse error & general error handling middleware
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    logStructured('AUTH', `Handled malformed JSON request`);
    return res.status(400).json({ error: 'Malformed JSON request' });
  }
  logStructured('ERROR', `Server request error: ${err.message}`);
  res.status(500).json({ error: 'Internal Server Error' });
});

if (!isVercel) {
  const server = app.listen(PORT, () => {
    logStructured('AUTH', `Agora RTC Token & Sync Server running on http://localhost:${PORT}`);
    logStructured('AUTH', `Agora App ID: ${maskSecret(AGORA_APP_ID)}`);
    logStructured('AUTH', `Agora Default Channel: ${AGORA_DEFAULT_CHANNEL}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`\n[FATAL ERROR] Port ${PORT} is already in use!`);
      console.error(`Another instance of token_server (or another process) is listening on port ${PORT}.`);
      console.error(`To stop the process holding port ${PORT}:`);
      console.error(`  - Run npm run kill`);
      console.error(`  - Or run: powershell -Command "Stop-Process -Id (Get-NetTCPConnection -LocalPort ${PORT}).OwningProcess -Force"\n`);
      process.exit(1);
    } else {
      console.error('[FATAL ERROR] Server error:', err);
      process.exit(1);
    }
  });

  const gracefulShutdown = (signal) => {
    logStructured('AUTH', `Received ${signal}. Gracefully closing HTTP server on port ${PORT}...`);
    server.close(() => {
      logStructured('AUTH', 'HTTP server closed. Exiting process.');
      process.exit(0);
    });
  };

  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
}

process.on('uncaughtException', (err) => {
  logStructured('ERROR', `Uncaught exception trapped: ${err.message}`);
});

process.on('unhandledRejection', (reason) => {
  logStructured('ERROR', `Unhandled promise rejection trapped: ${reason}`);
});

module.exports = app;

