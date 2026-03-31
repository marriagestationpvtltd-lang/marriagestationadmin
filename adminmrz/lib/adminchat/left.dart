import 'dart:async';
import 'dart:convert';

import 'package:adminmrz/adminchat/services/MatchedProfileService.dart';
import 'package:adminmrz/core/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'chatprovider.dart';
import 'chatscreen.dart';
import 'constant.dart';
import 'loading.dart';

class ChatSidebar extends StatefulWidget {
  @override
  _ChatSidebarState createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  Map<String, Map<String, dynamic>> conversationMap = {};

  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  String _searchQuery = "";

  // Filter options
  bool _showOnlyPaid = false;
  bool _showOnlyOnline = false;
  bool _showWithMatches = false;
  String _sortBy = 'recent'; // 'recent', 'name', 'matches', 'online'

  Map<String, dynamic>? _selectedChat;
  final int senderId = 1;
  StreamSubscription? _conversationSub;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    _conversationSub?.cancel();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    final response =
    await http.get(Uri.parse('${AppConstants.chatApiUrl}/get.php'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      _users = jsonResponse["data"];

      // Initialize with current chat provider selected user if exists
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.id != null && _users.isNotEmpty) {
        _selectedChat = _users.firstWhere(
              (user) => user['id'] == chatProvider.id.toString(),
          orElse: () => _users[0],
        );
      } else if (_users.isNotEmpty) {
        _selectedChat = _users[0];
      }

      _applyFilters();

      listenToConversationChanges();
      setState(() {});
    }
  }

  void listenToConversationChanges() {
    _conversationSub = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: senderId.toString())
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .listen((snapshot) {

      Map<String, Map<String, dynamic>> tempMap = {};
      List<dynamic> sortedUsers = [];

      for (var doc in snapshot.docs) {
        List participants = doc['participants'];
        String otherUserId =
        participants.firstWhere((id) => id != senderId.toString());

        tempMap[otherUserId] = {
          'lastMessage': doc['lastMessage'] ?? '',
          'lastTimestamp': doc['lastTimestamp'],
        };

        var user = _users.firstWhere(
              (u) => u['id'].toString() == otherUserId,
          orElse: () => null,
        );

        if (user != null) {
          sortedUsers.add(user); // 🔥 already in correct order
        }
      }

      // Add remaining users (no chats yet)
      for (var user in _users) {
        if (!sortedUsers.contains(user)) {
          sortedUsers.add(user);
        }
      }

      setState(() {
        conversationMap = tempMap;

        // 🔥 IMPORTANT: assign directly (no further sort override)
        _users = List.from(sortedUsers);

        // 🔥 Apply filters WITHOUT breaking order
        _filteredUsers = _users.where((user) {
          bool matchesSearch = user["name"]
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

          bool matchesPaid = !_showOnlyPaid || (user["is_paid"] == true);
          bool matchesOnline = !_showOnlyOnline || (user["is_online"] == true);

          int matchesCount = int.tryParse(user["matches"].toString()) ?? 0;
          bool matchesWithMatches = !_showWithMatches || (matchesCount > 0);

          return matchesSearch && matchesPaid && matchesOnline && matchesWithMatches;
        }).toList();
      });
    });
  }
  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Search filter
        bool matchesSearch = user["name"]
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());

        // Paid filter
        bool matchesPaid = !_showOnlyPaid || (user["is_paid"] == true);

        // Online filter
        bool matchesOnline = !_showOnlyOnline || (user["is_online"] == true);

        // Matches filter
        int matchesCount = int.tryParse(user["matches"].toString()) ?? 0;
        bool matchesWithMatches = !_showWithMatches || (matchesCount > 0);

        return matchesSearch && matchesPaid && matchesOnline && matchesWithMatches;
      }).toList();

      // Apply sorting
      if (_sortBy != 'recent') {
        _sortUsers();
      }

      // Ensure selected chat is still in filtered list, if not, select first
      if (_selectedChat != null && !_filteredUsers.contains(_selectedChat)) {
        if (_filteredUsers.isNotEmpty) {
          _selectedChat = _filteredUsers[0];
          _updateSelectedChat();
        } else {
          _selectedChat = null;
        }
      }
    });
  }

  void _sortUsers() {
    switch (_sortBy) {
      case 'recent':
        _filteredUsers.sort((a, b) {
          String aId = a['id'].toString();
          String bId = b['id'].toString();

          Timestamp? aTs = conversationMap[aId]?['lastTimestamp'];
          Timestamp? bTs = conversationMap[bId]?['lastTimestamp'];

          DateTime aTime = aTs?.toDate() ?? DateTime(1970);
          DateTime bTime = bTs?.toDate() ?? DateTime(1970);

          return bTime.compareTo(aTime);
        });
        break;
      case 'name':
        _filteredUsers.sort((a, b) => a["name"].compareTo(b["name"]));
        break;
      case 'matches':
        _filteredUsers.sort((a, b) {
          int aMatches = int.tryParse(a["matches"].toString()) ?? 0;
          int bMatches = int.tryParse(b["matches"].toString()) ?? 0;
          return bMatches.compareTo(aMatches);
        });
        break;
      case 'online':
        _filteredUsers.sort((a, b) {
          bool aOnline = a["is_online"] ?? false;
          bool bOnline = b["is_online"] ?? false;
          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;
          return 0;
        });
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _showOnlyPaid = false;
      _showOnlyOnline = false;
      _showWithMatches = false;
      _sortBy = 'recent';
      _searchQuery = "";
      _applyFilters();
    });
  }

  void _updateSelectedChat() {
    if (_selectedChat != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.updateName(_selectedChat!["name"]);
      chatProvider.updateonline(_selectedChat!["is_online"]);
      chatProvider.updateidd(int.tryParse(_selectedChat!["id"]) ?? 0);
      chatProvider.updatePaidStatus(_selectedChat!["is_paid"] ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Container(
      width: 280,
      color: Colors.grey[200],
      child: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = "";
                      _applyFilters();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),

          // 🎛️ FILTER OPTIONS
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('Paid Members'),
                        selected: _showOnlyPaid,
                        onSelected: (bool selected) {
                          setState(() {
                            _showOnlyPaid = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: Colors.blue,
                        checkmarkColor: Colors.white,
                      ),
                      SizedBox(width: 8),
                      FilterChip(
                        label: Text('Online Only'),
                        selected: _showOnlyOnline,
                        onSelected: (bool selected) {
                          setState(() {
                            _showOnlyOnline = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: Colors.green,
                        checkmarkColor: Colors.white,
                      ),
                      SizedBox(width: 8),
                      FilterChip(
                        label: Text('Has Matches'),
                        selected: _showWithMatches,
                        onSelected: (bool selected) {
                          setState(() {
                            _showWithMatches = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: Colors.red,
                        checkmarkColor: Colors.white,
                      ),
                      SizedBox(width: 8),
                      // Sort dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          underline: SizedBox(),
                          icon: Icon(Icons.sort, size: 18),
                          items: [
                            DropdownMenuItem(value: 'recent', child: Text('Recent')),
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                            DropdownMenuItem(value: 'matches', child: Text('Matches')),
                            DropdownMenuItem(value: 'online', child: Text('Online First')),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _sortBy = newValue;
                                _sortUsers();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Reset filters button
                if (_showOnlyPaid || _showOnlyOnline || _showWithMatches || _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: Icon(Icons.clear_all, size: 16),
                          label: Text('Clear Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} users',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (_showOnlyPaid)
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Paid', style: TextStyle(fontSize: 10)),
                  ),
                if (_showOnlyOnline)
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Online', style: TextStyle(fontSize: 10)),
                  ),
                if (_showWithMatches)
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Matches', style: TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ),

          Divider(height: 1),

          // 📋 LIST
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No users found',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (_showOnlyPaid || _showOnlyOnline || _showWithMatches || _searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text('Clear filters'),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                var user = _filteredUsers[index];
                bool isSelected = _selectedChat == user;

                return _buildUserRow(
                  user["name"] ?? "",
                  conversationMap[user["id"].toString()]?['lastMessage'] ?? user["chat_message"] ?? "",
                  int.tryParse(user["matches"].toString()) ?? 0,
                  user["last_seen_text"] ?? "",
                  user["is_paid"] ?? false,
                  user["is_online"] ?? false,
                  user["profile_picture"] ?? "",
                  isSelected,
                      () {
                    setState(() {
                      _selectedChat = user;
                      _updateSelectedChat();

                      Future.microtask(() =>
                          Provider.of<MatchedProfileProvider>(context,
                              listen: false)
                              .fetchMatchedProfiles(chatProvider.id!));
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Loading(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 USER ROW UI
  Widget _buildUserRow(
      String name,
      String chatMessage,
      int matches,
      String lastSeen,
      bool isPaid,
      bool isOnline,
      String profileImage,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          children: [
            Stack(
              children: [
                // 🖼️ PROFILE IMAGE
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? Icon(Icons.person, color: Colors.grey)
                      : null,
                ),

                // 🟢 ONLINE DOT
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

                // 💰 PAID BADGE
                if (isPaid)
                  Positioned(
                    left: 0,
                    top: 0,
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

            SizedBox(width: 10),

            // 📄 TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPaid ? Colors.amber[800] : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    isOnline ? "Online" : lastSeen,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (chatMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        chatMessage,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            if (matches > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 12),
                    SizedBox(width: 2),
                    Text("$matches",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}