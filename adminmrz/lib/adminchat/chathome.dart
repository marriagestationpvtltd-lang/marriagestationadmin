import 'package:adminmrz/adminchat/services/pushservice.dart';
import 'package:adminmrz/adminchat/video_call_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'OutgoingCall.dart';
import 'audiocall.dart';
import 'chat_screen.dart';
import 'chatprovider.dart';
import 'chatscreen.dart';
import 'constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'chat_theme.dart';
import 'left.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:firebase_storage/firebase_storage.dart';

class ChatWindow extends StatefulWidget {
  final String name;
  final bool isOnline;
  final dynamic receiverIdd;

  const ChatWindow({super.key, required this.name, required this.isOnline, required this.receiverIdd});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final int senderId = 1;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isListening = false;
  bool _userStoppedListening = false;
  bool _isSearching = false;
  bool _isSendingImage = false;
  bool _showMatchInfo = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  List<QueryDocumentSnapshot> _filteredMessages = [];
  js.JsObject? _webSpeechRecognition;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ScrollController _scrollController = ScrollController();
  QuerySnapshot? _lastSnapshot;
  String? _lastUploadedImageUrl;

  // Cached streams – recreated only when the selected receiver changes.
  int? _cachedReceiverId;
  Stream<QuerySnapshot>? _messagesStream;

  // Voice typing state
  String _selectedLanguage = 'en-US'; // 'en-US' or 'ne-NP'
  String _textBeforeVoice = ''; // text already in field before listening started

  // Pagination
  static const int _pageSize = 20;
  int _currentLimit = 20;
  int? _cachedLimit;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int? _prevUserId;

  // Match-related data
  Map<String, dynamic>? _matchDetails;
  bool _isLoadingMatchDetails = false;
  List<Map<String, dynamic>> _mutualMatches = [];

  // Active call overlay
  OverlayEntry? _callOverlayEntry;

  // Typing indicator state
  Timer? _typingTimer;
  StreamSubscription<DocumentSnapshot>? _typingSubscription;
  bool _userIsTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSpeech();
    _initializeRecorder();
    _fetchMatchDetails();
    _scrollController.addListener(_onScrollForPagination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_messageFocusNode);
      // Set up typing listener for the initially selected user.
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.id != null) _setupTypingListener(chatProvider.id!);
    });
  }

  Future<void> _fetchMatchDetails() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    setState(() {
      _isLoadingMatchDetails = true;
    });

    try {
      final response = await http.get(
          Uri.parse('https://digitallami.com/get_match_details.php?user_id=${chatProvider.id}')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _matchDetails = data['match_details'];
            _mutualMatches = List<Map<String, dynamic>>.from(data['mutual_matches'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching match details: $e');
    } finally {
      setState(() {
        _isLoadingMatchDetails = false;
      });
    }
  }

  // ── TYPING INDICATOR ────────────────────────────────────────────────────

  /// Subscribe to the selected user's typing status in Firestore.
  void _setupTypingListener(int userId) {
    _typingSubscription?.cancel();
    _typingSubscription = _firestore
        .collection('typing_status')
        .doc(userId.toString())
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (!snap.exists) {
        setState(() => _userIsTyping = false);
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      final bool isTyping = data['isTyping'] == true;
      final String? typingTo = data['typingTo']?.toString();
      // Only show if user is typing TO admin ('1').
      setState(() => _userIsTyping = isTyping && typingTo == senderId.toString());
    });
  }

  /// Update admin's typing status in Firestore.
  void _updateAdminTypingStatus(String text, String receiverId) {
    _typingTimer?.cancel();
    final isTyping = text.isNotEmpty;
    _firestore.collection('typing_status').doc(senderId.toString()).set({
      'isTyping': isTyping,
      'typingTo': receiverId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (isTyping) {
      // Auto-clear after 3 seconds of no new keystrokes.
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _clearAdminTypingStatus();
      });
    }
  }

  /// Clear admin's typing status (on send, user switch, or dispose).
  void _clearAdminTypingStatus() {
    _typingTimer?.cancel();
    _firestore.collection('typing_status').doc(senderId.toString()).set({
      'isTyping': false,
      'typingTo': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  // ── SEEN STATUS ─────────────────────────────────────────────────────────

  /// Batch-mark all unread incoming messages as seen by admin.
  void _markIncomingMessagesAsSeen(List<QueryDocumentSnapshot> messages) {
    final batch = _firestore.batch();
    bool hasPending = false;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.id == null) return;
    final String userId = chatProvider.id.toString();
    for (final doc in messages) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['senderid'] == userId &&
          data['receiverid'] == senderId.toString() &&
          data['seen'] != true) {
        batch.update(doc.reference, {
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
        hasPending = true;
      }
    }
    if (hasPending) batch.commit().catchError((_) {});
  }

  // ── CALL HISTORY ─────────────────────────────────────────────────────────

  /// Save a call history message to the `adminchat` collection.
  Future<void> _saveCallHistory(
      String receiverId, String callType, String status, int durationSeconds) async {
    try {
      final String label = _callLabel(callType, status, durationSeconds);
      await _firestore.collection('adminchat').add({
        'message': label,
        'senderid': senderId.toString(),
        'receiverid': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'call',
        'callType': callType,
        'callStatus': status,
        'callDuration': durationSeconds,
        'seen': false,
      });

      final String conversationId =
          getConversationId(senderId.toString(), receiverId);
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set({
        'participants': [senderId.toString(), receiverId],
        'lastMessage': label,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _callLabel(String callType, String status, int seconds) {
    final bool isVideo = callType == 'video';
    if (status == 'missed') {
      return isVideo ? '📹 Missed Video Call' : '📞 Missed Call';
    }
    final String dur = _formatCallDuration(seconds);
    return isVideo ? '📹 Video Call • $dur' : '📞 Audio Call • $dur';
  }

  String _formatCallDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _initializeWebSpeech() {
    // Prefer the unprefixed SpeechRecognition (Firefox/Edge) with a fallback to
    // the webkit-prefixed version used by Chrome.
    final dynamic speechClass = js.context.hasProperty('SpeechRecognition')
        ? js.context['SpeechRecognition']
        : js.context.hasProperty('webkitSpeechRecognition')
            ? js.context['webkitSpeechRecognition']
            : null;

    if (speechClass == null) return;

    _webSpeechRecognition = js.JsObject(speechClass as js.JsFunction);
    _webSpeechRecognition!['continuous'] = true;
    _webSpeechRecognition!['interimResults'] = true;
    _webSpeechRecognition!['lang'] = _selectedLanguage;

    _webSpeechRecognition!['onresult'] = js.allowInterop((dynamic event) {
      final eventObj = js.JsObject.fromBrowserObject(event);
      final results = eventObj['results'];
      if (results == null) return;

      final resultList = js.JsObject.fromBrowserObject(results);
      // Use safe num→int cast; JS numbers come through as num, not int.
      final int length = (resultList['length'] as num).toInt();
      // Only process new results starting at resultIndex to avoid double-counting
      // previous finals every time onresult fires.
      final int resultIndex = (eventObj['resultIndex'] as num).toInt();

      String interimTranscript = '';
      String finalTranscript = '';

      for (int i = resultIndex; i < length; i++) {
        final result = js.JsObject.fromBrowserObject(
            resultList.callMethod('item', [i]));
        final transcript =
            js.JsObject.fromBrowserObject(result.callMethod('item', [0]))['transcript'] as String;
        // Use == true instead of `as bool` — JS booleans may not cast to Dart bool directly.
        final isFinal = result['isFinal'] == true;
        if (isFinal) {
          finalTranscript += transcript;
        } else {
          interimTranscript += transcript;
        }
      }

      if (finalTranscript.isNotEmpty) {
        _textBeforeVoice = _textBeforeVoice + finalTranscript;
      }

      final displayText = interimTranscript.isNotEmpty
          ? _textBeforeVoice + interimTranscript
          : _textBeforeVoice;

      setState(() {
        _messageController.text = displayText;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: displayText.length),
        );
      });
    });

    _webSpeechRecognition!['onend'] = js.allowInterop((dynamic _) {
      // With continuous=true the browser may still fire onend after silence.
      // Restart automatically unless the user explicitly stopped listening.
      if (!_userStoppedListening && _isListening && mounted) {
        try {
          _webSpeechRecognition!.callMethod('start');
        } catch (e) {
          setState(() => _isListening = false);
        }
      } else {
        if (mounted) setState(() => _isListening = false);
      }
    });

    _webSpeechRecognition!['onerror'] = js.allowInterop((dynamic event) {
      final error =
          js.JsObject.fromBrowserObject(event)['error'] as String? ?? '';
      if (error == 'aborted') return; // user-initiated stop, onend handles state

      // Prevent auto-restart only for unrecoverable errors (permission denied).
      if (error == 'not-allowed' || error == 'service-not-allowed') {
        _userStoppedListening = true;
      }

      final resetText = _textBeforeVoice.trimRight();
      setState(() {
        _isListening = false;
        _messageController.text = resetText;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: resetText.length),
        );
      });

      String errorMsg;
      switch (error) {
        case 'not-allowed':
        case 'service-not-allowed':
          errorMsg =
              'Microphone access denied. Please allow microphone permission in your browser settings.';
          break;
        case 'no-speech':
          errorMsg = 'No speech detected. Please try again.';
          break;
        default:
          errorMsg = 'Speech error: $error';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    });
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
    }
  }

  void _startListening() {
    if (_webSpeechRecognition != null && !_isListening) {
      _textBeforeVoice = _messageController.text;
      if (_textBeforeVoice.isNotEmpty && !_textBeforeVoice.endsWith(' ')) {
        _textBeforeVoice += ' ';
      }
      _webSpeechRecognition!['lang'] = _selectedLanguage;
      _userStoppedListening = false;
      _webSpeechRecognition!.callMethod('start');
      setState(() => _isListening = true);
    }
  }

  void _stopListening() {
    if (_isListening && _webSpeechRecognition != null) {
      _userStoppedListening = true;
      _webSpeechRecognition!.callMethod('stop');
      setState(() => _isListening = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } else {
      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _onScrollForPagination() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 && !_isLoadingMore && _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    if (_isLoadingMore || !_hasMoreMessages) return;
    setState(() {
      _isLoadingMore = true;
      _currentLimit += _pageSize;
    });
    // _isLoadingMore is cleared in the StreamBuilder once the new snapshot arrives
    // (via the _hasMoreMessages/noMore logic). As a safety fallback, clear it after
    // a short delay so the UI never gets stuck.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoadingMore) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _sendMatchProfile(Map<String, dynamic> profileData) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      await _firestore.collection('adminchat').add({
        'message': 'Match Profile',
        'liked': false,
        'replyto': '',
        'senderid': senderId.toString(),
        'receiverid': chatProvider.id.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'profile_card',
        'profileData': profileData,
      });

      String conversationId = getConversationId(
        senderId.toString(),
        chatProvider.id.toString(),
      );

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
        'participants': [senderId.toString(), chatProvider.id.toString()],
        'lastMessage': 'Sent a match profile',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send match profile")),
      );
    }
  }

  // ── CALL OVERLAY HELPERS ─────────────────────────────────────────────────

  /// Remove the active call overlay and clean up.
  void _removeCallOverlay() {
    _callOverlayEntry?.remove();
    _callOverlayEntry = null;
  }

  /// Launch a call (video or audio) in a floating overlay so the admin can
  /// minimize it and continue browsing other conversations without ending it.
  void _launchCall(ChatProvider chatProvider, {required bool isVideo}) {
    if (_callOverlayEntry != null) return; // call already active

    final userId = chatProvider.id.toString();
    final userName = chatProvider.namee.toString();
    final isMinimizedNotifier = ValueNotifier<bool>(false);

    void onCallEnded(String callType, String status, int durationSeconds) {
      _removeCallOverlay();
      _saveCallHistory(userId, callType, status, durationSeconds);
    }

    _callOverlayEntry = OverlayEntry(
      builder: (ctx) => ValueListenableBuilder<bool>(
        valueListenable: isMinimizedNotifier,
        builder: (_, isMin, __) {
          final callWidget = isVideo
              ? VideoCallScreen(
                  currentUserId: '1',
                  currentUserName: 'Admin',
                  otherUserId: userId,
                  otherUserName: userName,
                  onMinimize: () => isMinimizedNotifier.value = true,
                  onEnd: _removeCallOverlay,
                  onCallEnded: onCallEnded,
                )
              : CallScreen(
                  currentUserId: '1',
                  currentUserName: 'Admin',
                  otherUserId: userId,
                  otherUserName: userName,
                  onMinimize: () => isMinimizedNotifier.value = true,
                  onEnd: _removeCallOverlay,
                  onCallEnded: onCallEnded,
                );

          return Stack(
            children: [
              // Full-screen call – kept alive via Offstage while minimized
              Offstage(offstage: isMin, child: callWidget),
              // Floating mini-bar shown when minimized
              if (isMin)
                _buildMiniCallBar(
                  userName: userName,
                  isVideo: isVideo,
                  onMaximize: () => isMinimizedNotifier.value = false,
                  onEnd: _removeCallOverlay,
                ),
            ],
          );
        },
      ),
    );
    Overlay.of(context).insert(_callOverlayEntry!);
  }

  void _launchVideoCall(ChatProvider chatProvider) =>
      _launchCall(chatProvider, isVideo: true);

  void _launchAudioCall(ChatProvider chatProvider) =>
      _launchCall(chatProvider, isVideo: false);

  /// A compact floating bar shown at the bottom-right when the call is
  /// minimized.  The admin can tap it to expand back or end the call.
  Widget _buildMiniCallBar({
    required String userName,
    required bool isVideo,
    required VoidCallback onMaximize,
    required VoidCallback onEnd,
  }) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onMaximize,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  isVideo ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onEnd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 14),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onMaximize,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.open_in_full, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ICON BUTTON HELPER ────────────────────────────────────────────
  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    Color? iconColor,
  }) {
    final c = ChatColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? c.primaryLight : c.searchFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? (active ? c.primary : c.muted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);

    final chatProvider = Provider.of<ChatProvider>(context);

    // Rebuild the Firestore stream only when the selected user changes so that
    // StreamBuilder keeps its existing subscription and never flashes a loading
    // spinner while switching conversations.
    final bool userChanged = chatProvider.id != _cachedReceiverId;
    final bool limitChanged = _currentLimit != _cachedLimit;
    if (userChanged) {
      _cachedReceiverId = chatProvider.id;
      _currentLimit = _pageSize;
      _hasMoreMessages = true;
      _lastSnapshot = null; // clear stale messages from the previous user
      // Re-fetch match details for the newly selected user
      if (chatProvider.id != null) Future.microtask(_fetchMatchDetails);
      // Reset user-typing state and subscribe to new user's typing status.
      _userIsTyping = false;
      if (chatProvider.id != null) Future.microtask(() => _setupTypingListener(chatProvider.id!));
      // Clear admin typing status for the previous user.
      Future.microtask(_clearAdminTypingStatus);
      // Auto-focus the message input so the admin can type immediately.
      Future.microtask(() {
        if (mounted) FocusScope.of(context).requestFocus(_messageFocusNode);
      });
    }
    if (userChanged || limitChanged) {
      _cachedLimit = _currentLimit;
      _messagesStream = chatProvider.id == null
          ? null
          : _firestore
              .collection('adminchat')
              .where('senderid', whereIn: [senderId.toString(), chatProvider.id.toString()])
              .where('receiverid', whereIn: [senderId.toString(), chatProvider.id.toString()])
              .orderBy('timestamp', descending: true)
              .limit(_currentLimit)
              .snapshots();
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.header,
            border: Border(bottom: BorderSide(color: c.border, width: 1)),
          ),
          child: Row(
            children: [
              // Avatar + paid badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: chatProvider.profilePicture != null &&
                            chatProvider.profilePicture!.isNotEmpty
                        ? NetworkImage(chatProvider.profilePicture!)
                        : null,
                    child: chatProvider.profilePicture == null ||
                            chatProvider.profilePicture!.isEmpty
                        ? Icon(Icons.person, size: 18, color: Colors.grey[400])
                        : null,
                  ),
                  if (chatProvider.ispaid)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.star, size: 8, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatProvider.namee.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: chatProvider.ispaid ? c.primary : c.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chatProvider.matchesCount != null && chatProvider.matchesCount! > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite, color: c.primary, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  '${chatProvider.matchesCount}',
                                  style: TextStyle(
                                    color: c.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _userIsTyping ? c.primary : (chatProvider.online ? c.online : c.muted),
                          ),
                        ),
                        Text(
                          _userIsTyping
                              ? "typing..."
                              : (chatProvider.online ? "Online" : "Offline"),
                          style: TextStyle(
                            fontSize: 11,
                            color: _userIsTyping
                                ? c.primary
                                : (chatProvider.online ? c.online : c.muted),
                          ),
                        ),
                        if (chatProvider.id != null)
                          Row(
                            children: [
                              Icon(Icons.tag, size: 10, color: c.muted),
                              const SizedBox(width: 2),
                              Text(
                                '${chatProvider.id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              _iconBtn(
                icon: _showMatchInfo ? Icons.favorite : Icons.favorite_border,
                active: _showMatchInfo,
                iconColor: _showMatchInfo ? c.primary : c.muted,
                onTap: () => setState(() => _showMatchInfo = !_showMatchInfo),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                icon: Icons.video_call_outlined,
                iconColor: c.primary,
                onTap: () => _launchVideoCall(chatProvider),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                icon: Icons.call_outlined,
                iconColor: const Color(0xFF334155),
                onTap: () => _launchAudioCall(chatProvider),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                icon: _isSearching ? Icons.close : Icons.search,
                active: _isSearching,
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _filteredMessages.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 6),
              _iconBtn(
                icon: Icons.notifications_outlined,
                iconColor: c.muted,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search messages...",
                    hintStyle: TextStyle(fontSize: 12, color: c.muted),
                    prefixIcon: Icon(Icons.search, size: 16, color: c.muted),
                    filled: true,
                    fillColor: c.searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: c.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: _searchMessages,
                ),
              ),
            ),

          // Match info panel
          if (_showMatchInfo)
            _buildMatchInfoPanel(chatProvider),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          "Firebase Error",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _handleIndexError(snapshot.error.toString()),
                          child: const Text("Create Index", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && _lastSnapshot == null) {
                  return Center(child: CircularProgressIndicator(color: c.primary));
                }

                final messages = _isSearching && _filteredMessages.isNotEmpty
                    ? _filteredMessages
                    : (snapshot.hasData ? snapshot.data!.docs : _lastSnapshot?.docs ?? []);

                if (snapshot.hasData) {
                  _lastSnapshot = snapshot.data;
                  // If we received fewer docs than requested, there are no older messages.
                  final bool noMore = snapshot.data!.docs.length < _currentLimit;
                  if (noMore != !_hasMoreMessages || _isLoadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {
                        _hasMoreMessages = !noMore;
                        _isLoadingMore = false;
                      });
                    });
                  }
                  // Mark incoming messages as seen by admin.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _markIncomingMessagesAsSeen(snapshot.data!.docs);
                  });
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          "No messages yet",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Start a conversation!",
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ],
                    ),
                  );
                }

                final itemCount = messages.length;
                // Extra slot at the end of the reversed list (= visual top) for the
                // load-more indicator.
                final listItemCount = itemCount + (_hasMoreMessages || _isLoadingMore ? 1 : 0);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  reverse: true,
                  itemCount: listItemCount,
                  itemBuilder: (context, index) {
                    // The last item in the reversed list is the oldest-message indicator.
                    if (index == itemCount) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: _isLoadingMore
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.primary,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: _loadMoreMessages,
                                  icon: Icon(Icons.history, size: 14, color: c.primary),
                                  label: Text(
                                    'Load older messages',
                                    style: TextStyle(fontSize: 12, color: c.primary),
                                  ),
                                ),
                        ),
                      );
                    }

                    var doc = messages[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isSentByMe = data['senderid'] == senderId.toString();
                    DateTime timestamp = (data['timestamp'] != null)
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    if (index == 0 && !_isSearching) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients &&
                            (_scrollController.offset <= 100 || _lastSnapshot?.docs.length != itemCount)) {
                          _scrollToBottom();
                        }
                      });
                    }

                    return GestureDetector(
                      key: ValueKey(doc.id),
                      onLongPress: () {
                        if (isSentByMe) {
                          _showMessageOptions(context, doc.id, data['message']);
                        }
                      },
                      child: _buildChatBubble(
                        data['message'],
                        isSentByMe,
                        timestamp,
                        data['type'],
                        data.containsKey('profileData') ? data['profileData'] : null,
                        data.containsKey('imageUrl') ? data['imageUrl'] : null,
                        data['seen'] == true,
                        data['callType']?.toString(),
                        data['callStatus']?.toString(),
                        (data['callDuration'] as num?)?.toInt() ?? 0,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(chatProvider),
        ],
      ),
    );
  }

  Widget _buildMatchInfoPanel(ChatProvider chatProvider) {
    final c = ChatColors.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.selectedRow,
        border: Border(bottom: BorderSide(color: c.primaryLight, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: c.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Match Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
              const Spacer(),
              if (_isLoadingMatchDetails)
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_matchDetails != null && _matchDetails!['percentage'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Match Score: ', style: TextStyle(fontSize: 12, color: c.muted)),
                  Text(
                    '${_matchDetails!['percentage']}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),

          if (_matchDetails != null && _matchDetails!['commonInterests'] != null)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (_matchDetails!['commonInterests'] as List).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(fontSize: 10, color: c.primary),
                  ),
                );
              }).toList(),
            ),

          if (_mutualMatches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Mutual Matches:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.muted),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mutualMatches.length,
                itemBuilder: (context, index) {
                  final match = _mutualMatches[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: match['profile_picture'] != null &&
                                  match['profile_picture'].toString().isNotEmpty
                              ? NetworkImage(match['profile_picture'])
                              : null,
                          child: match['profile_picture'] == null ||
                                  match['profile_picture'].toString().isEmpty
                              ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                              : null,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match['name'] ?? '',
                          style: TextStyle(fontSize: 8, color: c.muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          if (chatProvider.matchesCount != null && chatProvider.matchesCount! > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showMatchSelectionDialog(chatProvider),
                icon: const Icon(Icons.send, size: 12),
                label: const Text('Send Match Profile', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  backgroundColor: c.primaryLight,
                  foregroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMatchSelectionDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Match Profile', style: TextStyle(fontSize: 16)),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('matches')
                  .where('userId', isEqualTo: chatProvider.id.toString())
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final matches = snapshot.data!.docs;

                if (matches.isEmpty) {
                  return Center(child: Text('No matches found'));
                }

                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: match['profile_picture'] != null &&
                            match['profile_picture'].toString().isNotEmpty
                            ? NetworkImage(match['profile_picture'])
                            : null,
                        child: match['profile_picture'] == null ||
                            match['profile_picture'].toString().isEmpty
                            ? Icon(Icons.person, color: Colors.grey[700])
                            : null,
                      ),
                      title: Text(match['name'] ?? 'Unknown'),
                      subtitle: Text('Match: ${match['percentage'] ?? 'N/A'}%'),
                      onTap: () {
                        Navigator.pop(context);
                        _sendMatchProfile(match);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleIndexError(String error) {
    final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = regex.firstMatch(error);

    if (match != null) {
      String indexUrl = match.group(0)!;

      if (kIsWeb) {
        html.window.open(indexUrl, '_blank');
      } else {
        launchUrl(Uri.parse(indexUrl));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening Firebase Console to create index...'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please check Firebase Console for index creation'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void openUrl(String url) {
    html.window.open(url, '_blank');
  }

  Widget _buildChatBubble(String message, bool isSentByMe, DateTime timestamp,
      [String? type,
      Map<String, dynamic>? profileData,
      String? imageUrl,
      bool seen = false,
      String? callType,
      String? callStatus,
      int callDuration = 0]) {
    const kPrimary = Color(0xFFD81B60);
    const kText = Color(0xFF1E293B);
    const kMuted = Color(0xFF64748B);

    // ── Call history bubble ──────────────────────────────────────────────
    if (type == 'call') {
      return _buildCallBubble(
          callType ?? 'audio', callStatus ?? 'missed', callDuration, isSentByMe, timestamp);
    }

    if (type == 'image' && imageUrl != null) {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: MediaQuery.of(context).size.width * 0.24,
                  fit: BoxFit.cover,
                  cacheWidth: (MediaQuery.of(context).size.width * 0.24).toInt(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: kPrimary));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      children: [
                        const Text('Error loading image'),
                        Text('Details: $error', style: const TextStyle(fontSize: 10)),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text("Retry"),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6, left: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(timestamp),
                    style: const TextStyle(fontSize: 10, color: kMuted),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 3),
                    _buildSeenTick(seen),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'profile_card' && profileData != null) {
      const kCardPrimary = Color(0xFFD81B60);
      const kCardSurface = Color(0xFFFCFCFE);
      const kCardBorder = Color(0xFFEDE7F6);
      const kInfoLabel = Color(0xFF78909C);
      const kInfoValue = Color(0xFF1A2340);

      final bool isPaid = profileData['is_paid'] == true;
      final String bioText = profileData['bio'] ?? '';
      // Parse match percentage from bio like "72% Matched"
      final matchRegex = RegExp(r'(\d+(?:\.\d+)?)%');
      final matchMatch = matchRegex.firstMatch(bioText);
      final double matchPct = matchMatch != null ? double.tryParse(matchMatch.group(1)!) ?? 0 : 0;

      Color matchColor;
      if (matchPct >= 70) {
        matchColor = const Color(0xFF43A047);
      } else if (matchPct >= 50) {
        matchColor = const Color(0xFFFB8C00);
      } else {
        matchColor = const Color(0xFF78909C);
      }

      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.22,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: kCardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kCardBorder, width: 1),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header gradient with avatar ──────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Container(
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD81B60), Color(0xFFAD1457), Color(0xFF880E4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Subtle pattern dots
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -8,
                            left: -8,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // "Profile Shared" label
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.person_pin_rounded, size: 9, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('Profile Shared', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                                ],
                              ),
                            ),
                          ),
                          // Premium badge
                          if (isPaid)
                            Positioned(
                              top: 8,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium, size: 8, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text('Premium', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Avatar overlapping the gradient ──────────────────────
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Match ring
                              if (matchPct > 0)
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: matchColor, width: 2.5),
                                  ),
                                ),
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: ClipOval(
                                  child: profileData['profileImage'] != null &&
                                          profileData['profileImage'].toString().isNotEmpty
                                      ? Image.network(
                                          profileData['profileImage'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFF8BBD9),
                                            child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFFD81B60)),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFF8BBD9),
                                          child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFFD81B60)),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Name & match badge ─────────────────────────────
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            profileData['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInfoValue,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (matchPct > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: matchColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: matchColor.withOpacity(0.35), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, size: 9, color: matchColor),
                                const SizedBox(width: 3),
                                Text(
                                  '${matchPct.toStringAsFixed(0)}% Match',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: matchColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Info grid ──────────────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          // ── User ID (mandatory) ──────────────────────────
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kCardPrimary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: kCardPrimary.withOpacity(0.25), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tag_rounded, size: 10, color: kCardPrimary),
                                const SizedBox(width: 4),
                                const Text(
                                  'User ID',
                                  style: TextStyle(fontSize: 9.5, color: kCardPrimary, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(
                                  '#${profileData['id']}',
                                  style: const TextStyle(fontSize: 9.5, color: kCardPrimary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          _buildInfoRow(Icons.badge_rounded, 'Member ID', profileData['Member ID'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.wc_rounded, 'Gender', profileData['gender'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.location_on_rounded, 'Country', profileData['country'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.work_rounded, 'Occupation', profileData['occupation'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.school_rounded, 'Education', profileData['education'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.favorite_border_rounded, 'Marital', profileData['marit'], kInfoLabel, kInfoValue),
                          _buildInfoRow(Icons.cake_rounded, 'Age', profileData['age']?.toString(), kInfoLabel, kInfoValue),
                        ],
                      ),
                    ),
                  ),

                  // ── Action buttons ─────────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => openUrl("https://digitallami.com/profile.php?id=${profileData['id']}"),
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(color: kCardPrimary, width: 1.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.open_in_new_rounded, size: 12, color: kCardPrimary),
                                    SizedBox(width: 4),
                                    Text('Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kCardPrimary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  Provider.of<ChatProvider>(context, listen: false)
                                      .updateName("${profileData['last']}  ${profileData['first']}");
                                  Provider.of<ChatProvider>(context, listen: false)
                                      .updateidd(profileData['id']);
                                });
                              },
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD81B60), Color(0xFFAD1457)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_rounded, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 8, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(timestamp),
                    style: const TextStyle(fontSize: 10, color: kMuted),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 3),
                    _buildSeenTick(seen),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Text message bubble
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.24),
        child: Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: isSentByMe ? kPrimary : Colors.white,
                borderRadius: isSentByMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                boxShadow: isSentByMe
                    ? null
                    : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isSentByMe ? Colors.white : kText,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 8, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(timestamp),
                    style: const TextStyle(fontSize: 10, color: kMuted),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 3),
                    _buildSeenTick(seen),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single tick (sent) or double tick (seen) indicator for admin-sent messages.
  Widget _buildSeenTick(bool seen) {
    const kPrimary = Color(0xFFD81B60);
    const kMuted = Color(0xFF94A3B8);
    if (seen) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.done_all, size: 13, color: kPrimary),
        ],
      );
    }
    return const Icon(Icons.done, size: 13, color: kMuted);
  }

  /// Call history message bubble.
  Widget _buildCallBubble(
      String callType, String status, int durationSeconds, bool isSentByMe, DateTime timestamp) {
    const kPrimary = Color(0xFFD81B60);
    const kMuted = Color(0xFF64748B);
    final bool isMissed = status == 'missed';
    final bool isVideo = callType == 'video';
    final Color color = isMissed ? Colors.red : kPrimary;
    final String label = isMissed
        ? (isVideo ? 'Missed Video Call' : 'Missed Call')
        : (isVideo ? 'Video Call' : 'Audio Call');
    final IconData icon = isMissed
        ? (isVideo ? Icons.videocam_off_outlined : Icons.phone_missed)
        : (isVideo ? Icons.videocam_outlined : Icons.phone_outlined);
    final String dur = durationSeconds > 0 ? ' • ${_formatCallDuration(durationSeconds)}' : '';

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMissed ? Colors.red.shade50 : const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMissed ? Colors.red.shade200 : const Color(0xFFFFCDD2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label$dur',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('hh:mm a').format(timestamp),
                  style: const TextStyle(fontSize: 10, color: kMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, Color labelColor, Color valueColor) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: labelColor),
          const SizedBox(width: 5),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TextStyle(fontSize: 9.5, color: labelColor, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 9.5, color: valueColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _playAudio(String url) async {
    final AudioPlayer _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
    }
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    const kPrimary = Color(0xFFD81B60);
    // Dark-mode tints for the language-selector chip
    const kLangNepaliDarkBg     = Color(0xFF4A1A1A);
    const kLangEnglishDarkBg    = Color(0xFF1A2A40);
    const kLangNepaliDarkBorder = Color(0xFFCC4444);
    const kLangEnglishDarkBorder= Color(0xFF4488CC);
    const kLangNepaliDarkText   = Color(0xFFFF6B6B);
    const kLangEnglishDarkText  = Color(0xFF64B5F6);
    final colors = ChatColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.inputBg,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: Column(
        children: [
          if (_selectedImage != null || _selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: kIsWeb
                            ? MemoryImage(_selectedImageBytes!) as ImageProvider
                            : FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSendingImage ? null : () async => await _sendImageMessage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: _isSendingImage
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Send", style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.muted, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                      });
                    },
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.emoji_emotions, color: colors.muted, size: 20),
                onPressed: _showEmojiPicker,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(Icons.attach_file, color: colors.muted, size: 20),
                onPressed: _pickImage,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              // Language selector button
              Tooltip(
                message: _selectedLanguage == 'en-US' ? 'Switch to Nepali' : 'Switch to English',
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = _selectedLanguage == 'en-US' ? 'ne-NP' : 'en-US';
                      if (_webSpeechRecognition != null) {
                        _webSpeechRecognition!['lang'] = _selectedLanguage;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? (_selectedLanguage == 'ne-NP'
                              ? (colors.isDark ? kLangNepaliDarkBg : Colors.red.shade50)
                              : (colors.isDark ? kLangEnglishDarkBg : Colors.blue.shade50))
                          : colors.cardBg,
                      border: Border.all(
                        color: _selectedLanguage == 'ne-NP'
                            ? (colors.isDark ? kLangNepaliDarkBorder : Colors.red.shade300)
                            : (colors.isDark ? kLangEnglishDarkBorder : Colors.blue.shade300),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedLanguage == 'en-US' ? 'EN' : 'ने',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedLanguage == 'ne-NP'
                            ? (colors.isDark ? kLangNepaliDarkText : Colors.red.shade700)
                            : (colors.isDark ? kLangEnglishDarkText : Colors.blue.shade700),
                      ),
                    ),
                  ),
                ),
              ),
              // Mic button
              IconButton(
                tooltip: _isListening ? 'Stop voice typing' : 'Start voice typing',
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? kPrimary : colors.muted,
                  size: 20,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 6,
                  onChanged: (text) {
                    if (chatProvider.id != null) {
                      _updateAdminTypingStatus(text, chatProvider.id.toString());
                    }
                  },
                  style: TextStyle(color: colors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _selectedLanguage == 'ne-NP'
                        ? "सन्देश टाइप गर्नुहोस्"
                        : "Type a message",
                    hintStyle: TextStyle(color: colors.muted, fontSize: 14),
                    filled: true,
                    fillColor: colors.searchFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: kPrimary, width: 1.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: hasText ? kPrimary : colors.border,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: hasText ? Colors.white : colors.muted,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _selectedImageBytes = result.files.single.bytes;
            _selectedImage = null;
          });
        } else {
          if (result.files.single.path != null) {
            setState(() {
              _selectedImage = File(result.files.single.path!);
              _selectedImageBytes = null;
            });
          }
        }
      } else {
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _sendImageMessage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (_selectedImage == null && _selectedImageBytes == null) return;

    setState(() => _isSendingImage = true);

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('chat_images/$fileName');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = storageRef.putData(_selectedImageBytes!);
      } else {
        uploadTask = storageRef.putFile(_selectedImage!);
      }

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('adminchat').add({
        'message': 'Image',
        'liked': false,
        'replyto': '',
        'senderid': senderId.toString(),
        'receiverid': chatProvider.id.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'imageUrl': imageUrl,
        'seen': false,
      });

      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _isSendingImage = false;
      });
    } catch (e) {
      setState(() => _isSendingImage = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send image: $e")));
    }
  }

  Future<void> _sendMessage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();

    // Clear immediately so the UI feels instant
    _messageController.clear();
    _textBeforeVoice = '';
    FocusScope.of(context).requestFocus(_messageFocusNode);

    // Clear typing indicator immediately on send.
    _clearAdminTypingStatus();

    try {
      await _firestore.collection('adminchat').add({
        'message': messageText,
        'liked': false,
        'replyto': '',
        'senderid': senderId.toString(),
        'receiverid': chatProvider.id.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'seen': false,
      });

      await NotificationService.sendChatNotification(
        recipientUserId: chatProvider.id.toString(),
        senderName: "Admin",
        senderId: '1',
        message: messageText,
        extraData: {
          'chatId': chatProvider.id.toString(),
          'screen': 'chat',
        },
      );

      String conversationId = getConversationId(
        senderId.toString(),
        chatProvider.id.toString(),
      );

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
        'participants': [senderId.toString(), chatProvider.id.toString()],
        'lastMessage': messageText,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      // Restore message text so user doesn't lose their content
      if (_messageController.text.isEmpty) {
        _messageController.text = messageText;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageText.length),
        );
        _textBeforeVoice = messageText;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  String getConversationId(String a, String b) {
    return (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';
  }

  void _showMessageOptions(BuildContext context, String docId, String currentMessage) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, size: 20),
              title: Text("Edit", style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _editMessage(docId, currentMessage);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, size: 20),
              title: Text("Delete", style: TextStyle(fontSize: 14)),
              onTap: () {
                _firestore.collection('adminchat').doc(docId).delete();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _editMessage(String docId, String currentMessage) {
    TextEditingController editController = TextEditingController(text: currentMessage);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Message", style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: editController,
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                _firestore
                    .collection('adminchat')
                    .doc(docId)
                    .update({'message': editController.text.trim()});
                Navigator.pop(context);
              },
              child: Text("Save", style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            height: 240,
            width: 240,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                setState(() {
                  _messageController.text += emoji.emoji;
                });
              },
              config: Config(),
            ),
          ),
        );
      },
    );
  }

  void _searchMessages(String query) {
    if (_lastSnapshot == null) return;

    setState(() {
      if (query.isEmpty) {
        _filteredMessages.clear();
      } else {
        _filteredMessages = _lastSnapshot!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String message = data['message']?.toString().toLowerCase() ?? '';
          return message.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _removeCallOverlay();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _clearAdminTypingStatus();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }
}