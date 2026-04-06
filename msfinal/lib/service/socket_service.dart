import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'socket_events.dart';

/// Singleton service that manages the Socket.IO connection for the app.
///
/// Usage:
///   await SocketService.instance.connect();   // on login
///   SocketService.instance.onNewMessage(roomId, callback);
///   SocketService.instance.disconnect();      // on logout
class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  // ── Server URL ────────────────────────────────────────────────────────────
  /// The Node.js Socket.IO server URL.  Override via _kSocketUrl if needed.
  static const String _kSocketUrl = 'https://digitallami.com:3001';

  // ── Internal state ────────────────────────────────────────────────────────
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnected = false;

  /// Notifier that widgets can listen to for connection-state changes.
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);

  // Per-room typing debounce timers
  final Map<String, Timer?> _typingTimers = {};

  // ── Stream controllers ────────────────────────────────────────────────────
  final StreamController<Map<String, dynamic>> _newMessageCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _presenceCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messagesReadCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _unreadCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _newMemberCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _docUpdateCtrl =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _statsUpdateCtrl =
      StreamController.broadcast();

  // ── Public streams ────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>> get onNewMessage => _newMessageCtrl.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceCtrl.stream;
  Stream<Map<String, dynamic>> get onTypingStatus => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadCtrl.stream;
  Stream<Map<String, dynamic>> get onUnreadUpdate => _unreadCtrl.stream;
  Stream<Map<String, dynamic>> get onNewMember => _newMemberCtrl.stream;
  Stream<Map<String, dynamic>> get onDocUpdate => _docUpdateCtrl.stream;
  Stream<Map<String, dynamic>> get onStatsUpdate => _statsUpdateCtrl.stream;

  bool get isConnected => _isConnected;

  // ── Connection lifecycle ───────────────────────────────────────────────────

  /// Connect to the Socket.IO server.
  /// Reads the auth token and userId from SharedPreferences automatically.
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) return;

    final userData = jsonDecode(userDataString);
    _currentUserId = userData['id']?.toString() ?? '';

    _socket = IO.io(
      _kSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(2000)
          .setExtraHeaders({'Authorization': token})
          .setQuery({'userId': _currentUserId})
          .build(),
    );

    _bindListeners();
    _socket!.connect();
  }

  /// Disconnect and release resources (call on logout).
  void disconnect() {
    _typingTimers.forEach((_, t) => t?.cancel());
    _typingTimers.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _isConnected = false;
    isConnectedNotifier.value = false;
  }

  // ── Room helpers ──────────────────────────────────────────────────────────

  void joinRoom(String roomId) {
    _emit(SocketEvents.joinRoom, {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _emit(SocketEvents.leaveRoom, {'roomId': roomId});
  }

  // ── Chat helpers ──────────────────────────────────────────────────────────

  /// Send a chat message via Socket.IO (server then persists + broadcasts).
  void sendMessage({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String message,
    String messageType = 'text',
  }) {
    _emit(SocketEvents.sendMessage, {
      'roomId': roomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void markRead(String roomId, String readerId) {
    _emit(SocketEvents.markRead, {'roomId': roomId, 'readerId': readerId});
  }

  // ── Typing helpers ────────────────────────────────────────────────────────

  /// Call on every keystroke; automatically sends a stop event after [debounce].
  void sendTypingStart(String roomId, {Duration debounce = const Duration(seconds: 2)}) {
    _emit(SocketEvents.typingStart, {
      'roomId': roomId,
      'userId': _currentUserId,
    });
    _typingTimers[roomId]?.cancel();
    _typingTimers[roomId] = Timer(debounce, () {
      sendTypingStop(roomId);
    });
  }

  void sendTypingStop(String roomId) {
    _typingTimers[roomId]?.cancel();
    _typingTimers[roomId] = null;
    _emit(SocketEvents.typingStop, {
      'roomId': roomId,
      'userId': _currentUserId,
    });
  }

  // ── Presence ──────────────────────────────────────────────────────────────

  /// Filter the shared presence stream for a specific user.
  Stream<Map<String, dynamic>> presenceOf(String userId) =>
      onPresenceUpdate.where((e) => e['userId']?.toString() == userId);

  // ── Private helpers ───────────────────────────────────────────────────────

  void _emit(String event, Map<String, dynamic> data) {
    if (_socket == null || !_isConnected) {
      debugPrint('[Socket] ⚠️  Cannot emit "$event" — not connected.');
      return;
    }
    _socket!.emit(event, data);
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);
    } catch (_) {
      return {'raw': data.toString()};
    }
  }

  void _bindListeners() {
    final socket = _socket!;

    socket.onConnect((_) {
      debugPrint('[Socket] ✅ Connected');
      _isConnected = true;
      isConnectedNotifier.value = true;
      // Authenticate immediately after connecting
      socket.emit(SocketEvents.authenticate, {
        'userId': _currentUserId,
      });
    });

    socket.onDisconnect((_) {
      debugPrint('[Socket] ❌ Disconnected');
      _isConnected = false;
      isConnectedNotifier.value = false;
    });

    socket.onConnectError((err) {
      debugPrint('[Socket] connect_error: $err');
      _isConnected = false;
      isConnectedNotifier.value = false;
    });

    socket.on(SocketEvents.newMessage, (data) {
      debugPrint('[Socket] new_message: $data');
      _newMessageCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.presenceUpdate, (data) {
      debugPrint('[Socket] presence_update: $data');
      _presenceCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.typingStatus, (data) {
      _typingCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.messagesRead, (data) {
      _messagesReadCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.unreadUpdate, (data) {
      _unreadCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.newMember, (data) {
      debugPrint('[Socket] new_member: $data');
      _newMemberCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.docUpdate, (data) {
      debugPrint('[Socket] doc_update: $data');
      _docUpdateCtrl.add(_toMap(data));
    });

    socket.on(SocketEvents.statsUpdate, (data) {
      _statsUpdateCtrl.add(_toMap(data));
    });
  }
}
