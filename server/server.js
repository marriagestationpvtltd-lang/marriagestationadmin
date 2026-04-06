'use strict';

require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const mysql = require('mysql2/promise');

// ── Config ────────────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '3001', 10);
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

// Require INTERNAL_SECRET to be explicitly configured — no insecure default.
const INTERNAL_SECRET = process.env.INTERNAL_SECRET;
if (!INTERNAL_SECRET) {
  console.error('[Config] INTERNAL_SECRET env variable is not set. Exiting.');
  process.exit(1);
}

// ── MySQL connection pool ─────────────────────────────────────────────────────
const db = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'marriagestation',
  waitForConnections: true,
  connectionLimit: 10,
});

// ── Express + Socket.IO ───────────────────────────────────────────────────────
const app = express();
app.use(express.json());

// Require explicit ALLOWED_ORIGINS in production to avoid broad CORS access.
if (!ALLOWED_ORIGINS.length) {
  console.warn('[Config] ALLOWED_ORIGINS is not set — allowing all origins (development only).');
}
const corsOrigin = ALLOWED_ORIGINS.length ? ALLOWED_ORIGINS : false;
app.use(cors({ origin: corsOrigin }));

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: corsOrigin,
    methods: ['GET', 'POST'],
  },
  transports: ['websocket', 'polling'],
});

// ── In-memory presence map: userId → socketId ─────────────────────────────────
/** @type {Map<string, string>} */
const onlineUsers = new Map();

// ── Helper: broadcast presence change ─────────────────────────────────────────
function broadcastPresence(userId, isOnline) {
  io.emit('presence_update', {
    userId,
    isOnline,
    lastSeen: isOnline ? null : new Date().toISOString(),
  });
}

// ── Socket.IO ─────────────────────────────────────────────────────────────────
io.on('connection', (socket) => {
  let authedUserId = null;

  // ── authenticate ────────────────────────────────────────────────────────────
  socket.on('authenticate', ({ userId }) => {
    if (!userId) return;
    authedUserId = String(userId);
    onlineUsers.set(authedUserId, socket.id);
    console.log(`[Socket] User ${authedUserId} connected (${socket.id})`);
    broadcastPresence(authedUserId, true);
  });

  // ── join_room ────────────────────────────────────────────────────────────────
  socket.on('join_room', ({ roomId }) => {
    if (!roomId) return;
    socket.join(roomId);
    console.log(`[Socket] ${authedUserId} joined room ${roomId}`);
  });

  // ── leave_room ───────────────────────────────────────────────────────────────
  socket.on('leave_room', ({ roomId }) => {
    if (!roomId) return;
    socket.leave(roomId);
  });

  // ── send_message ─────────────────────────────────────────────────────────────
  socket.on('send_message', async (data) => {
    const { roomId, senderId, receiverId, message, messageType, timestamp } = data;
    if (!roomId || !senderId || !message) return;

    const msgData = {
      roomId,
      senderId,
      receiverId,
      message,
      messageType: messageType || 'text',
      timestamp: timestamp || new Date().toISOString(),
    };

    // Broadcast to everyone in the room (including sender for confirmation)
    io.to(roomId).emit('new_message', msgData);

    // Update unread count for receiver
    const receiverSocketId = onlineUsers.get(String(receiverId));
    if (!receiverSocketId) {
      // Receiver is offline — persist unread count via DB if needed
    }

    // Optionally persist to DB here (or let PHP handle it)
    try {
      await db.execute(
        `INSERT INTO socket_messages (room_id, sender_id, receiver_id, message, message_type, created_at)
         VALUES (?, ?, ?, ?, ?, NOW())`,
        [roomId, senderId, receiverId, message, msgData.messageType]
      );
    } catch (err) {
      // Non-fatal: Firestore/PHP is the source of truth
      console.error('[Socket] DB insert error:', err.message);
    }
  });

  // ── mark_read ─────────────────────────────────────────────────────────────────
  socket.on('mark_read', ({ roomId, readerId }) => {
    if (!roomId) return;
    socket.to(roomId).emit('messages_read', { roomId, readerId });
  });

  // ── typing_start ──────────────────────────────────────────────────────────────
  socket.on('typing_start', ({ roomId, userId }) => {
    socket.to(roomId).emit('typing_status', { roomId, userId, isTyping: true });
  });

  // ── typing_stop ───────────────────────────────────────────────────────────────
  socket.on('typing_stop', ({ roomId, userId }) => {
    socket.to(roomId).emit('typing_status', { roomId, userId, isTyping: false });
  });

  // ── disconnect ────────────────────────────────────────────────────────────────
  socket.on('disconnect', () => {
    if (authedUserId) {
      onlineUsers.delete(authedUserId);
      console.log(`[Socket] User ${authedUserId} disconnected`);
      broadcastPresence(authedUserId, false);
    }
  });
});

// ── Internal HTTP endpoint (PHP → Node.js bridge) ─────────────────────────────
//
// PHP calls: POST http://localhost:3001/internal/emit
// Headers:   { X-Internal-Secret: <INTERNAL_SECRET> }
// Body:      { event: string, data: object, room?: string }
//
app.post('/internal/emit', (req, res) => {
  const secret = req.headers['x-internal-secret'];
  if (secret !== INTERNAL_SECRET) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const { event, data, room } = req.body;
  if (!event || !data) {
    return res.status(400).json({ error: 'event and data are required' });
  }

  if (room) {
    io.to(room).emit(event, data);
  } else {
    io.emit(event, data);
  }

  const target = room ? `room ${room}` : '(broadcast)';
  console.log('[Internal] Emitted event to', target);
  return res.json({ ok: true });
});

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    onlineUsers: onlineUsers.size,
    uptime: Math.floor(process.uptime()),
  });
});

// ── Start ─────────────────────────────────────────────────────────────────────
server.listen(PORT, () => {
  console.log(`[Socket.IO] Server running on port ${PORT}`);
});
