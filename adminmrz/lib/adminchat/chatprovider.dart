import 'dart:async';
import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constant.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, String>> _chatList = [];
  List<Map<String, String>> _userList = [];

  int? id;
  String? namee;
  bool online = true;
  int? userid;
  String? memberid;
  String? first_name;
  String? last_name;
  String? matching_percentage;
  bool ispaid = true;
  bool isonline = true;

  String? profilePicture;

  int? _matchesCount;
  List<Map<String, dynamic>> _matchedProfiles = [];
  bool _isLoadingMatches = false;
  String? _matchError;

  // Cache & auto-refresh
  DateTime? _lastFetchTime;
  Timer? _refreshTimer;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < AppConstants.liveCacheDuration;

  int? get matchesCount => _matchesCount;
  List<Map<String, dynamic>> get matchedProfiles => _matchedProfiles;
  bool get isLoadingMatches => _isLoadingMatches;
  String? get matchError => _matchError;
  List<Map<String, String>> get chatList => _chatList;

  /// Start auto-refreshing the chat list every [AppConstants.autoRefreshInterval].
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppConstants.autoRefreshInterval, (_) {
      fetchChatList(forceRefresh: true);
    });
  }

  /// Stop the auto-refresh timer.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchChatList({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _chatList.isNotEmpty) return;

    final url = Uri.parse('${AppConstants.chatApiUrl}/get.php');

    try {
      final response = await http
          .get(url)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true && responseData['data'] is List) {
          List<Map<String, String>> tempList = (responseData['data'] as List)
              .map((item) =>
          {
            'id': item['id'].toString(),
            'namee': item['name'].toString(),
            'online': item['is_online'].toString(),
            'matches': item['matches']?.toString() ?? '0',
            'is_paid': item['is_paid']?.toString() ?? 'false',
            'profile_picture': item['profile_picture']?.toString() ?? '',
            'last_seen_text': item['last_seen_text']?.toString() ?? '',
            'chat_message': item['chat_message']?.toString() ?? '',
          })
              .toList();

          if (tempList.isNotEmpty) {
            id = int.parse(tempList[0]['id'].toString());
            namee = tempList[0]['namee'];
            online = tempList[0]['online'] == 'true';
            profilePicture = tempList[0]['profile_picture'];
            _matchesCount = int.tryParse(tempList[0]['matches'] ?? '0');
            myid ??= id;
          }

          _chatList = tempList;
          _lastFetchTime = DateTime.now();
          notifyListeners();
        }
      }
    } catch (error) {
      debugPrint('Error fetching chat list: $error');
    }
  }

  Future<void> fetchUserMatches(int userId) async {
    _isLoadingMatches = true;
    _matchError = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.chatApiUrl}/get_matches.php?user_id=$userId');

      final response = await http
          .get(url)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success' && responseData['data'] is List) {
          _matchedProfiles = List<Map<String, dynamic>>.from(responseData['data']);
          if (_matchedProfiles.isNotEmpty) {
            _matchesCount = _matchedProfiles.length;
          }
        } else {
          _matchError = responseData['message'] ?? 'Failed to load matches';
          _matchedProfiles = [];
        }
      } else {
        _matchError = 'Server error: ${response.statusCode}';
        _matchedProfiles = [];
      }
    } catch (error) {
      _matchError = 'Network error: $error';
      _matchedProfiles = [];
      debugPrint('Error fetching matches: $error');
    } finally {
      _isLoadingMatches = false;
      notifyListeners();
    }
  }

  Map<String, String>? getUserById(int userId) {
    try {
      return _chatList.firstWhere(
            (user) => user['id'] == userId.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  int getMatchesCountForUser(int userId) {
    final user = getUserById(userId);
    if (user != null && user.containsKey('matches')) {
      return int.tryParse(user['matches'] ?? '0') ?? 0;
    }
    return 0;
  }

  bool isUserPaid(int userId) {
    final user = getUserById(userId);
    if (user != null && user.containsKey('is_paid')) {
      return user['is_paid'] == 'true';
    }
    return false;
  }

  List<Map<String, String>> getUsersWithMatches() {
    return _chatList.where((user) {
      int matches = int.tryParse(user['matches'] ?? '0') ?? 0;
      return matches > 0;
    }).toList();
  }

  List<Map<String, String>> getPaidUsers() {
    return _chatList.where((user) => user['is_paid'] == 'true').toList();
  }

  List<Map<String, String>> getOnlineUsers() {
    return _chatList.where((user) => user['online'] == 'true').toList();
  }

  List<Map<String, String>> searchUsers(String query) {
    if (query.isEmpty) return _chatList;
    return _chatList.where((user) {
      return user['namee']?.toLowerCase().contains(query.toLowerCase()) ?? false;
    }).toList();
  }

  List<Map<String, String>> filterUsers({
    String? searchQuery,
    bool? paidOnly,
    bool? onlineOnly,
    bool? withMatchesOnly,
    String? sortBy,
  }) {
    List<Map<String, String>> filtered = List.from(_chatList);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user['namee']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
      }).toList();
    }

    if (paidOnly == true) {
      filtered = filtered.where((user) => user['is_paid'] == 'true').toList();
    }

    if (onlineOnly == true) {
      filtered = filtered.where((user) => user['online'] == 'true').toList();
    }

    if (withMatchesOnly == true) {
      filtered = filtered.where((user) {
        int matches = int.tryParse(user['matches'] ?? '0') ?? 0;
        return matches > 0;
      }).toList();
    }

    if (sortBy != null) {
      switch (sortBy) {
        case 'name':
          filtered.sort((a, b) => (a['namee'] ?? '').compareTo(b['namee'] ?? ''));
          break;
        case 'matches':
          filtered.sort((a, b) {
            int aMatches = int.tryParse(a['matches'] ?? '0') ?? 0;
            int bMatches = int.tryParse(b['matches'] ?? '0') ?? 0;
            return bMatches.compareTo(aMatches);
          });
          break;
        case 'last_seen':
          filtered.sort((a, b) {
            bool aOnline = a['online'] == 'true';
            bool bOnline = b['online'] == 'true';
            if (aOnline && !bOnline) return -1;
            if (!aOnline && bOnline) return 1;
            return (a['last_seen_text'] ?? '').compareTo(b['last_seen_text'] ?? '');
          });
          break;
      }
    }

    return filtered;
  }

  void clearMatches() {
    _matchedProfiles = [];
    _matchesCount = null;
    _matchError = null;
    notifyListeners();
  }

  void setId(int newId) {
    myid = newId;
    notifyListeners();
  }

  void updateName(String newName) {
    namee = newName;
    notifyListeners();
  }

  void updateuserid(int newName) {
    userid = newName;
    notifyListeners();
  }

  void updateidd(int newId) {
    id = newId;
    final user = getUserById(newId);
    if (user != null) {
      profilePicture = user['profile_picture'];
      _matchesCount = int.tryParse(user['matches'] ?? '0');
      ispaid = user['is_paid'] == 'true';
      online = user['online'] == 'true';
    }
    notifyListeners();
  }

  void updateonline(bool newName) {
    online = newName;
    notifyListeners();
  }

  void updatePaidStatus(bool newStatus) {
    ispaid = newStatus;
    notifyListeners();
  }

  void updateMatchesCount(int count) {
    _matchesCount = count;
    notifyListeners();
  }

  void updateProfilePicture(String picture) {
    profilePicture = picture;
    notifyListeners();
  }
}