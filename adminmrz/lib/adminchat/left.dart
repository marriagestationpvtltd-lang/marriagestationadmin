import 'dart:async';
import 'dart:convert';

import 'package:adminmrz/adminchat/services/MatchedProfileService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'chat_theme.dart';
import 'chatprovider.dart';
import 'chatscreen.dart';
import 'constant.dart';

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

  // Pagination
  int _page = 1;
  static const int _pageSize = 20;
  int _totalUsers = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  Timer? _onlineStatusTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchUsers(reset: true);
    // Poll online status every 30 seconds so the list updates live
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshOnlineStatus(),
    );
  }

  @override
  void dispose() {
    _conversationSub?.cancel();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _onlineStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchUsers({bool reset = false}) async {
    if (_isLoadingMore && !reset) return;

    if (reset) {
      _page = 1;
      _hasMore = true;
      _users = [];
      _filteredUsers = [];
      _isInitialLoading = true;
      _conversationSub?.cancel();
      _conversationSub = null;
    }

    if (!_hasMore && !reset) return;

    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final Map<String, String> queryParams = {
        'page': _page.toString(),
        'limit': _pageSize.toString(),
      };
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final uri = Uri.parse('https://digitallami.com/get.php')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> newUsers = (jsonResponse["data"] as List?) ?? [];

        // Support totalRecords / total fields from the server
        int? serverTotal = jsonResponse["totalRecords"] is int
            ? jsonResponse["totalRecords"] as int
            : jsonResponse["total"] is int
                ? jsonResponse["total"] as int
                : null;
        serverTotal ??= int.tryParse(
                jsonResponse["totalRecords"]?.toString() ?? '') ??
            int.tryParse(jsonResponse["total"]?.toString() ?? '');

        if (reset) {
          _users = newUsers;
          _totalUsers = serverTotal ?? newUsers.length;
        } else {
          _users = [..._users, ...newUsers];
          if (serverTotal != null) _totalUsers = serverTotal;
        }

        // Determine if more pages exist
        if (serverTotal != null) {
          _hasMore = _users.length < serverTotal;
        } else {
          _hasMore = newUsers.length >= _pageSize;
        }
        _page++;

        if (reset) {
          final chatProvider =
              Provider.of<ChatProvider>(context, listen: false);
          if (chatProvider.id != null && _users.isNotEmpty) {
            _selectedChat = _users.firstWhere(
              (user) => user['id'] == chatProvider.id.toString(),
              orElse: () => _users[0],
            );
          } else if (_users.isNotEmpty) {
            _selectedChat = _users[0];
          }
          listenToConversationChanges();
        }

        _applyFilters();
      }
    } catch (error) {
      debugPrint('Error fetching users: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      fetchUsers();
    }
  }

  // Lightweight poll: fetch a large page and update only is_online / last_seen_text
  Future<void> _refreshOnlineStatus() async {
    if (_users.isEmpty || !mounted) return;
    try {
      final uri = Uri.parse('https://digitallami.com/get.php').replace(
        queryParameters: {
          'page': '1',
          'limit': _users.length.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> freshList =
            (jsonResponse["data"] as List?) ?? [];

        // Build lookup: id -> {is_online, last_seen_text}
        final Map<String, Map<String, dynamic>> freshMap = {
          for (var u in freshList)
            u['id'].toString(): {
              'is_online': u['is_online'] ?? false,
              'last_seen_text': u['last_seen_text']?.toString() ?? '',
            },
        };

        bool changed = false;
        for (int i = 0; i < _users.length; i++) {
          final userId = _users[i]['id']?.toString();
          if (userId == null) continue;
          final fresh = freshMap[userId];
          if (fresh == null) continue;
          if (_users[i]['is_online'] != fresh['is_online'] ||
              _users[i]['last_seen_text'] != fresh['last_seen_text']) {
            _users[i] = {
              ..._users[i] as Map<String, dynamic>,
              'is_online': fresh['is_online'],
              'last_seen_text': fresh['last_seen_text'],
            };
            changed = true;
          }
        }

        if (changed && mounted) {
          _applyFilters();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing online status: $e');
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
    _searchDebounce?.cancel();
    setState(() {
      _showOnlyPaid = false;
      _showOnlyOnline = false;
      _showWithMatches = false;
      _sortBy = 'recent';
      _searchQuery = "";
    });
    fetchUsers(reset: true);
  }

  void _updateSelectedChat() {
    if (_selectedChat != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.updateName(_selectedChat!["name"]);
      chatProvider.updateonline(_selectedChat!["is_online"] == true);
      chatProvider.updateidd(int.tryParse(_selectedChat!["id"]) ?? 0);
      chatProvider.updatePaidStatus(_selectedChat!["is_paid"] == true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final c = ChatColors.of(context);

    return Container(
      width: 280,
      color: c.sidebar,
      child: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────
          Container(
            height: 56,
            color: c.sidebar,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filteredUsers.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── SEARCH BAR ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search conversations...",
                  hintStyle: TextStyle(fontSize: 12, color: c.muted),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.muted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: c.muted),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            setState(() => _searchQuery = "");
                            fetchUsers(reset: true);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: c.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: c.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: c.primary, width: 1),
                  ),
                  filled: true,
                  fillColor: c.searchFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () => fetchUsers(reset: true),
                  );
                },
              ),
            ),
          ),

          // ── FILTER CHIPS ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Paid', style: TextStyle(fontSize: 10)),
                        selected: _showOnlyPaid,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        onSelected: (bool selected) {
                          setState(() {
                            _showOnlyPaid = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: c.primaryLight,
                        checkmarkColor: c.primary,
                        side: BorderSide(color: c.border),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Online', style: TextStyle(fontSize: 10)),
                        selected: _showOnlyOnline,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        onSelected: (bool selected) {
                          setState(() {
                            _showOnlyOnline = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: c.primaryLight,
                        checkmarkColor: c.primary,
                        side: BorderSide(color: c.border),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Matches', style: TextStyle(fontSize: 10)),
                        selected: _showWithMatches,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        onSelected: (bool selected) {
                          setState(() {
                            _showWithMatches = selected;
                            _applyFilters();
                          });
                        },
                        selectedColor: c.primaryLight,
                        checkmarkColor: c.primary,
                        side: BorderSide(color: c.border),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: c.searchFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.border),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          icon: Icon(Icons.sort, size: 14, color: c.muted),
                          style: TextStyle(fontSize: 10, color: c.text),
                          dropdownColor: c.sidebar,
                          items: const [
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

                if (_showOnlyPaid || _showOnlyOnline || _showWithMatches || _searchQuery.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.clear_all, size: 14),
                      label: const Text('Clear', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: c.primary,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── COUNT ROW ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _totalUsers > 0
                    ? '${_filteredUsers.length} / $_totalUsers users'
                    : '${_filteredUsers.length} users',
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
            ),
          ),

          Container(height: 1, color: c.border),

          // ── LIST ────────────────────────────────────────────────────
          Expanded(
            child: _isInitialLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Loading users...',
                          style: TextStyle(color: c.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              'No users found',
                              style: TextStyle(color: c.muted, fontSize: 13),
                            ),
                            if (_showOnlyPaid ||
                                _showOnlyOnline ||
                                _showWithMatches ||
                                _searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: _resetFilters,
                                style: TextButton.styleFrom(
                                    foregroundColor: c.primary),
                                child: const Text('Clear filters',
                                    style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            _filteredUsers.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading footer
                          if (index == _filteredUsers.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.primary,
                                  ),
                                ),
                              ),
                            );
                          }

                          var user = _filteredUsers[index];
                          bool isSelected = _selectedChat == user;

                          return _buildUserRow(
                            user["name"] ?? "",
                            user["id"].toString(),
                            conversationMap[user["id"].toString()]
                                    ?['lastMessage'] ??
                                user["chat_message"] ??
                                "",
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
                              });
                              // Fetch matched profiles for the newly selected user
                              final newId =
                                  int.tryParse(user["id"].toString()) ?? 0;
                              if (newId > 0) {
                                Provider.of<MatchedProfileProvider>(context,
                                        listen: false)
                                    .fetchMatchedProfiles(newId);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── USER ROW ────────────────────────────────────────────────────────
  Widget _buildUserRow(
    String name,
    String userId,
    String chatMessage,
    int matches,
    String lastSeen,
    bool isPaid,
    bool isOnline,
    String profileImage,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final c = ChatColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? c.selectedRow : c.sidebar,
          border: isSelected
              ? Border(left: BorderSide(color: c.primary, width: 3))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.cardBg,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[400], size: 20)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? c.online : c.border,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.sidebar, width: 2),
                    ),
                  ),
                ),
                if (isPaid)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.sidebar, width: 1.5),
                      ),
                      child: const Icon(Icons.star, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isPaid ? c.primary : c.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userId.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.tag, size: 10, color: c.muted),
                        const SizedBox(width: 2),
                        Text(
                          userId,
                          style: TextStyle(
                            fontSize: 10,
                            color: c.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline ? "Online" : lastSeen,
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline ? c.online : c.muted,
                    ),
                  ),
                  if (chatMessage.isNotEmpty)
                    Text(
                      chatMessage,
                      style: TextStyle(fontSize: 11, color: c.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            if (matches > 0)
              Container(
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
                      '$matches',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}