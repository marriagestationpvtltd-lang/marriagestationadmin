# Socket.IO Server — Marriage Station

Node.js + Socket.IO real-time server that powers live chat, presence, typing
indicators, and admin dashboard notifications for the Marriage Station app.

## Architecture

```
Flutter App (socket_io_client)
        ↕  WebSocket / polling
Node.js Socket.IO Server  (:3001)
        ↕  MySQL (optional persistence)
        ↑  HTTP POST /internal/emit
PHP Backend (digitallami.com)
```

## Events reference

| Direction | Event | Payload |
|-----------|-------|---------|
| C→S | `authenticate` | `{ userId }` |
| C→S | `join_room` | `{ roomId }` |
| C→S | `leave_room` | `{ roomId }` |
| C→S | `send_message` | `{ roomId, senderId, receiverId, message, messageType, timestamp }` |
| C→S | `mark_read` | `{ roomId, readerId }` |
| C→S | `typing_start` | `{ roomId, userId }` |
| C→S | `typing_stop` | `{ roomId, userId }` |
| S→C | `new_message` | same as `send_message` |
| S→C | `presence_update` | `{ userId, isOnline, lastSeen? }` |
| S→C | `typing_status` | `{ roomId, userId, isTyping }` |
| S→C | `messages_read` | `{ roomId, readerId }` |
| S→C | `unread_update` | `{ roomId, unreadCount }` |
| S→C | `new_member` | `{ userId, name, timestamp }` |
| S→C | `doc_update` | `{ docId, userId, status }` |
| S→C | `stats_update` | `{ totalMembers, activeToday, ... }` |

## Setup

### 1. Install dependencies
```bash
cd server
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your DB credentials and secrets
```

### 3. Run the server
```bash
# Production
npm start

# Development (auto-reload)
npm run dev
```

### 4. Run with PM2 (recommended for production)
```bash
npm install -g pm2
pm2 start server.js --name "ms-socket"
pm2 save
pm2 startup
```

## PHP → Node.js bridge

When a PHP endpoint needs to push a real-time event (e.g. after a new member
registers or a document is approved), include the bridge helper:

```php
require_once '/path/to/server/php_bridge/socket_emit.php';

// Broadcast to all clients
socketEmit('new_member', ['userId' => $newUserId, 'name' => $name]);

// Send to a specific chat room
socketEmit('new_message', $msgData, $roomId);
```

Make sure `SOCKET_INTERNAL_SECRET` in the PHP environment matches the
`INTERNAL_SECRET` in your `.env` file.

## Health check
```
GET http://localhost:3001/health
→ { "status": "ok", "onlineUsers": 5, "uptime": 3600 }
```
