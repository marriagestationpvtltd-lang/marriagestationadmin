import 'package:adminmrz/adminchat/services/pushservice.dart';
import 'package:adminmrz/adminchat/video_call_page.dart';
import 'package:adminmrz/core/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'left.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:firebase_storage/firebase_storage.dart';

class ChatWindow extends StatefulWidget {
  final String name;
  final bool isOnline;
  var receiverIdd;

  ChatWindow({required this.name, required this.isOnline, required this.receiverIdd});

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
  bool _isSearching = false;
  bool _isSendingImage = false;
  bool _showMatchInfo = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  List<QueryDocumentSnapshot> _filteredMessages = [];
  html.SpeechRecognition? _webSpeechRecognition;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ScrollController _scrollController = ScrollController();
  QuerySnapshot? _lastSnapshot;
  String? _lastUploadedImageUrl;

  // Match-related data
  Map<String, dynamic>? _matchDetails;
  bool _isLoadingMatchDetails = false;
  List<Map<String, dynamic>> _mutualMatches = [];

  @override
  void initState() {
    super.initState();
    _initializeWebSpeech();
    _initializeRecorder();
    _printFirebaseConfig();
    _fetchMatchDetails();
  }

  void _printFirebaseConfig() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  Future<void> _fetchMatchDetails() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    setState(() {
      _isLoadingMatchDetails = true;
    });

    try {
      final response = await http.get(
          Uri.parse('${AppConstants.chatApiUrl}/get_match_details.php?user_id=${chatProvider.id}')
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

  void _initializeWebSpeech() {
    if (js.context.hasProperty('webkitSpeechRecognition')) {
      _webSpeechRecognition = html.SpeechRecognition();
      _webSpeechRecognition!.continuous = true;
      _webSpeechRecognition!.interimResults = true;
      _webSpeechRecognition!.lang = 'en-US';

      _webSpeechRecognition!.onResult.listen((event) {
        if (event.results!.isNotEmpty) {
          var result = event.results!.last;
          String transcript = js.JsObject.fromBrowserObject(result)[0]['transcript'] as String;
          setState(() {
            _messageController.text = transcript;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        }
      });

      _webSpeechRecognition!.onEnd.listen((event) {
        setState(() => _isListening = false);
      });

      _webSpeechRecognition!.onError.listen((event) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Speech error: ${event.error}")),
        );
      });
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
    }
  }

  void _startListening() async {
    if (_webSpeechRecognition != null && !_isListening) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
        _webSpeechRecognition!.start();
        setState(() => _isListening = true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Microphone access denied")),
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening && _webSpeechRecognition != null) {
      _webSpeechRecognition!.stop();
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

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Profile image with paid badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: chatProvider.profilePicture != null &&
                      chatProvider.profilePicture!.isNotEmpty
                      ? NetworkImage(chatProvider.profilePicture!)
                      : null,
                  child: chatProvider.profilePicture == null ||
                      chatProvider.profilePicture!.isEmpty
                      ? Icon(Icons.person, size: 20, color: Colors.grey[700])
                      : null,
                ),
                if (chatProvider.ispaid)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatProvider.namee.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: chatProvider.ispaid ? Colors.amber[800] : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chatProvider.matchesCount != null && chatProvider.matchesCount! > 0)
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, color: Colors.white, size: 10),
                              SizedBox(width: 2),
                              Text(
                                '${chatProvider.matchesCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    chatProvider.online ? "Online" : "Offline",
                    style: TextStyle(
                      fontSize: 10,
                      color: chatProvider.online ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Match info toggle button
            IconButton(
              icon: Icon(
                _showMatchInfo ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showMatchInfo = !_showMatchInfo;
                });
              },
            ),

            // Video call button (only for paid members)

              GestureDetector(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallScreen(
                        currentUserId: '1',
                        currentUserName: 'Admin',
                        otherUserId: chatProvider.id.toString(),
                        otherUserName: chatProvider.namee.toString(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(Icons.video_call_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),

            SizedBox(width: 8),

            // Audio call button (only for paid members)

              GestureDetector(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        currentUserId: '1',
                        currentUserName: 'Admin',
                        otherUserId: chatProvider.id.toString(),
                        otherUserName: chatProvider.namee.toString(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(Icons.call_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),

            SizedBox(width: 8),

            // Search button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredMessages.clear();
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search messages...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                onChanged: _searchMessages,
              ),
            ),

          // Match info panel
          if (_showMatchInfo)
            _buildMatchInfoPanel(chatProvider),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('adminchat')
                  .where('senderid', whereIn: [senderId.toString(), chatProvider.id.toString()])
                  .where('receiverid', whereIn: [senderId.toString(), chatProvider.id.toString()])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          "Firebase Error",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _handleIndexError(snapshot.error.toString());
                          },
                          child: Text("Create Index"),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && _lastSnapshot == null) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = _isSearching && _filteredMessages.isNotEmpty
                    ? _filteredMessages
                    : (snapshot.hasData ? snapshot.data!.docs : _lastSnapshot?.docs ?? []);

                if (snapshot.hasData) {
                  _lastSnapshot = snapshot.data;
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No messages found"),
                        SizedBox(height: 8),
                        Text(
                          "Start a conversation!",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final itemCount = messages.length;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  reverse: true,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
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
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Match Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              Spacer(),
              if (_isLoadingMatchDetails)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: 8),

          if (_matchDetails != null && _matchDetails!['percentage'] != null)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Match Score: ',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${_matchDetails!['percentage']}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                  ),
                );
              }).toList(),
            ),

          if (_mutualMatches.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Mutual Matches:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mutualMatches.length,
                itemBuilder: (context, index) {
                  final match = _mutualMatches[index];
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: match['profile_picture'] != null &&
                              match['profile_picture'].toString().isNotEmpty
                              ? NetworkImage(match['profile_picture'])
                              : null,
                          child: match['profile_picture'] == null ||
                              match['profile_picture'].toString().isEmpty
                              ? Icon(Icons.person, size: 16, color: Colors.grey[700])
                              : null,
                        ),
                        SizedBox(height: 2),
                        Text(
                          match['name'] ?? '',
                          style: TextStyle(fontSize: 8),
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
                onPressed: () {
                  _showMatchSelectionDialog(chatProvider);
                },
                icon: Icon(Icons.send, size: 14),
                label: Text(
                  'Send Match Profile',
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 30),
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
      [String? type, Map<String, dynamic>? profileData, String? imageUrl]) {
    if (type == 'image' && imageUrl != null) {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: MediaQuery.of(context).size.width * 0.24,
                  fit: BoxFit.cover,
                  cacheWidth: (MediaQuery.of(context).size.width * 0.24).toInt(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      children: [
                        Text('Error loading image'),
                        Text('Details: $error', style: TextStyle(fontSize: 10)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: Text("Retry"),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6, left: 6),
              child: Text(
                DateFormat('hh:mm a').format(timestamp),
                style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'profile_card' && profileData != null) {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.224,
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profileData['profileImage'] != null &&
                        profileData['profileImage'].toString().isNotEmpty
                        ? NetworkImage(profileData['profileImage'])
                        : null,
                    child: profileData['profileImage'] == null ||
                        profileData['profileImage'].toString().isEmpty
                        ? Icon(Icons.person, size: 30, color: Colors.grey[700])
                        : null,
                  ),
                  if (profileData['is_paid'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.star, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                profileData['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: profileData['is_paid'] == true ? Colors.amber[800] : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1),
              Text(
                profileData['bio'] ?? 'No bio available',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              _buildProfileDetails(profileData),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton("Profile", Colors.blue, () {
                    openUrl("https://digitallami.com/profile.php?id=${profileData['id']}");
                  }),
                  _buildActionButton("Chat", Colors.green, () {
                    setState(() {
                      Provider.of<ChatProvider>(context, listen: false)
                          .updateName("${profileData['last']}  ${profileData['first']}");
                      Provider.of<ChatProvider>(context, listen: false)
                          .updateidd(profileData['id']);
                    });
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.24,
        ),
        child: Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.pinkAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                    color: isSentByMe ? Colors.white : Colors.black, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6, left: 6),
              child: Text(
                DateFormat('hh:mm a').format(timestamp),
                style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> profileData) {
    return Column(
      children: [
        _buildProfileDetail('MemberID', profileData['Member ID']),
        _buildProfileDetail('Gender', profileData['gender']),
        _buildProfileDetail('Occupation', profileData['occupation']),
        _buildProfileDetail('Education', profileData['education']),
        _buildProfileDetail('Marit', profileData['marit']),
        _buildProfileDetail('Age', profileData['age']?.toString()),
        _buildProfileDetail('id', profileData['id']?.toString()),
      ],
    );
  }

  Widget _buildProfileDetail(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(left: 40),
            width: 80,
            alignment: Alignment.centerLeft,
            child: Text(
              "$label:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 100,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? 'Unknown',
              style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_selectedImage != null || _selectedImageBytes != null)
            Row(
              children: [
                Container(
                  height: 100,
                  width: 100,
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
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSendingImage
                      ? null
                      : () async {
                    await _sendImageMessage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSendingImage
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text("Send"),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.emoji_emotions, color: Colors.orange, size: 20),
                onPressed: _showEmojiPicker,
              ),
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.blue, size: 20),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? Colors.red : Colors.blue,
                  size: 20,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Type a message",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.red, size: 20),
                onPressed: () {
                  _sendMessage();
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

    try {
      await _firestore.collection('adminchat').add({
        'message': messageText,
        'liked': false,
        'replyto': '',
        'senderid': senderId.toString(),
        'receiverid': chatProvider.id.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
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

      _messageController.clear();
      FocusScope.of(context).requestFocus(_messageFocusNode);

    } catch (e) {
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
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }
}