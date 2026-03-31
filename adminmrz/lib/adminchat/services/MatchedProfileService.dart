import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/MatchedProfile.dart';

class MatchedProfileProvider with ChangeNotifier {
  String _name = '';
  bool _isloading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  static const int _perPage = 20;
  int? _currentUserId;
  String _memberid = '';

  String get memberid => _memberid;
  String get name => _name;
  bool get isloading => _isloading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;

  List<MatchedProfile> _matchedProfiles = [];

  // Getters for the specific fields you want to access
  List<String> get memberiddd =>
      _matchedProfiles.map((profile) => profile.memberid).toList();
  List<int> get ids =>
      _matchedProfiles.map((profile) => profile.id).toList();
  List<String> get firstNames =>
      _matchedProfiles.map((profile) => profile.firstName).toList();
  List<String> get lastNames =>
      _matchedProfiles.map((profile) => profile.lastName).toList();
  List<double> get matchingPercentages =>
      _matchedProfiles.map((profile) => profile.matchingPercentage).toList();
  List<bool> get isPaidList =>
      _matchedProfiles.map((profile) => profile.isPaid).toList();
  List<bool> get isOnlineList =>
      _matchedProfiles.map((profile) => profile.isOnline).toList();
  List<String> get occupation =>
      _matchedProfiles.map((profile) => profile.occupation).toList();
  List<String> get education =>
      _matchedProfiles.map((profile) => profile.education).toList();
  List<String> get country =>
      _matchedProfiles.map((profile) => profile.country).toList();
  List<String> get marit =>
      _matchedProfiles.map((profile) => profile.marit).toList();
  List<String> get gender =>
      _matchedProfiles.map((profile) => profile.gender).toList();
  List<int> get age =>
      _matchedProfiles.map((profile) => profile.age).toList();

  List<String> get profilePictures =>
      _matchedProfiles.map((profile) => profile.profilePicture).toList();

  // Fetch first page (resets list)
  Future<void> fetchMatchedProfiles(int userId) async {
    _currentUserId = userId;
    _currentPage = 1;
    _hasMore = false;
    _isloading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://digitallami.com/match_admin.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'page': 1,
          'per_page': _perPage,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List? ?? [];

        _matchedProfiles = list.map((p) => MatchedProfile.fromJson(p)).toList();
        _totalCount = data['total'] is int
            ? data['total'] as int
            : int.tryParse(data['total']?.toString() ?? '') ?? _matchedProfiles.length;
        _hasMore = _matchedProfiles.length >= _perPage &&
            _matchedProfiles.length < _totalCount;

        if (_matchedProfiles.isNotEmpty) {
          _name = _matchedProfiles.first.firstName;
          _memberid = _matchedProfiles.first.memberid;
        } else {
          _name = '';
          _memberid = '';
          _hasMore = false;
        }
      } else {
        throw Exception('Failed to load matched profiles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching matched profiles: $e');
    } finally {
      _isloading = false;
      notifyListeners();
    }
  }

  // Fetch next page (appends to list)
  Future<void> fetchMoreProfiles() async {
    if (_isLoadingMore || !_hasMore || _currentUserId == null) {
      debugPrint('fetchMoreProfiles skipped: '
          'isLoadingMore=$_isLoadingMore hasMore=$_hasMore userId=$_currentUserId');
      return;
    }
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await http.post(
        Uri.parse('https://digitallami.com/match_admin.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'page': nextPage,
          'per_page': _perPage,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List? ?? [];
        final newProfiles = list.map((p) => MatchedProfile.fromJson(p)).toList();

        if (newProfiles.isNotEmpty) {
          _matchedProfiles.addAll(newProfiles);
          _currentPage = nextPage;
          _totalCount = data['total'] is int
              ? data['total'] as int
              : int.tryParse(data['total']?.toString() ?? '') ?? _matchedProfiles.length;
          _hasMore = newProfiles.length >= _perPage &&
              _matchedProfiles.length < _totalCount;
        } else {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Error fetching more profiles: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Helper methods
  String getProfilePicture(int index) {
    if (index < 0 || index >= _matchedProfiles.length) return '';
    return _matchedProfiles[index].profilePicture;
  }

  bool isPaid(int index) {
    if (index < 0 || index >= _matchedProfiles.length) return false;
    return _matchedProfiles[index].isPaid;
  }

  bool isOnline(int index) {
    if (index < 0 || index >= _matchedProfiles.length) return false;
    return _matchedProfiles[index].isOnline;
  }

  String getFullName(int index) {
    if (index < 0 || index >= _matchedProfiles.length) return '';
    return '${_matchedProfiles[index].firstName} ${_matchedProfiles[index].lastName}';
  }

  // Lightweight refresh: re-fetch current profiles and update only isOnline field
  Future<void> refreshOnlineStatuses() async {
    if (_currentUserId == null || _matchedProfiles.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://digitallami.com/match_admin.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'page': 1,
          'per_page': _matchedProfiles.length.clamp(_perPage, 100),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List? ?? [];

        // Build a lookup map: id -> isOnline
        final Map<int, bool> onlineMap = {
          for (var item in list)
            (item['id'] ?? 0) as int: (item['is_online'] ?? false) as bool,
        };

        // Update only isOnline without disturbing order or other fields
        bool changed = false;
        final updated = _matchedProfiles.map((profile) {
          final newStatus = onlineMap[profile.id];
          if (newStatus != null && newStatus != profile.isOnline) {
            changed = true;
            return profile.copyWith(isOnline: newStatus);
          }
          return profile;
        }).toList();

        if (changed) {
          _matchedProfiles = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing online statuses: $e');
    }
  }

  void clearData() {
    _matchedProfiles.clear();
    _name = '';
    _memberid = '';
    _hasMore = false;
    _currentPage = 1;
    _totalCount = 0;
    _currentUserId = null;
    notifyListeners();
  }
}