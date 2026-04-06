/// All Socket.IO event name constants used by the app.
/// Keep in sync with the Node.js server event names.
class SocketEvents {
  SocketEvents._();

  // ── Connection lifecycle ──────────────────────────────────────────────────
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';

  // ── Auth ─────────────────────────────────────────────────────────────────
  /// Client → Server: authenticate after connecting
  /// payload: { userId: String, token: String }
  static const String authenticate = 'authenticate';

  // ── Presence ─────────────────────────────────────────────────────────────
  /// Server → Client: another user came online / went offline
  /// payload: { userId: String, isOnline: bool, lastSeen: String? }
  static const String presenceUpdate = 'presence_update';

  // ── Chat rooms ────────────────────────────────────────────────────────────
  /// Client → Server: join a specific chat room
  /// payload: { roomId: String }
  static const String joinRoom = 'join_room';

  /// Client → Server: leave a specific chat room
  /// payload: { roomId: String }
  static const String leaveRoom = 'leave_room';

  // ── Messages ──────────────────────────────────────────────────────────────
  /// Client → Server: send a new message
  /// payload: { roomId, senderId, receiverId, message, messageType, timestamp }
  static const String sendMessage = 'send_message';

  /// Server → Client: a new message arrived in a room the client is in
  /// payload: same as sendMessage payload
  static const String newMessage = 'new_message';

  /// Client → Server: mark messages as read
  /// payload: { roomId: String, readerId: String }
  static const String markRead = 'mark_read';

  /// Server → Client: messages in room were read by the other party
  /// payload: { roomId: String, readerId: String }
  static const String messagesRead = 'messages_read';

  // ── Typing ────────────────────────────────────────────────────────────────
  /// Client → Server: user started typing
  /// payload: { roomId: String, userId: String }
  static const String typingStart = 'typing_start';

  /// Client → Server: user stopped typing
  /// payload: { roomId: String, userId: String }
  static const String typingStop = 'typing_stop';

  /// Server → Client: the other person in the room started/stopped typing
  /// payload: { roomId: String, userId: String, isTyping: bool }
  static const String typingStatus = 'typing_status';

  // ── Dashboard / admin notifications ───────────────────────────────────────
  /// Server → Client (admin): a new member registered
  /// payload: { userId: String, name: String, timestamp: String }
  static const String newMember = 'new_member';

  /// Server → Client (admin): a document was approved / rejected
  /// payload: { docId: String, userId: String, status: String }
  static const String docUpdate = 'doc_update';

  /// Server → Client (admin): dashboard stats changed
  /// payload: { totalMembers: int, activeToday: int, ... }
  static const String statsUpdate = 'stats_update';

  // ── Unread counts ─────────────────────────────────────────────────────────
  /// Server → Client: unread message count changed for a room
  /// payload: { roomId: String, unreadCount: int }
  static const String unreadUpdate = 'unread_update';
}
