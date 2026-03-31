import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/MatchedProfile.dart';

class MatchedProfileProvider with ChangeNotifier {
  String _name = '';
  bool _isloading = false;
  String _memberid = '';

  String get memberid => _memberid;
  String get name => _name;
  bool get isloading => _isloading;
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

  // ADD THIS GETTER for profile pictures
  List<String> get profilePictures =>
      _matchedProfiles.map((profile) => profile.profilePicture).toList();

  // Fetch data and update the list
  Future<void> fetchMatchedProfiles(int userId) async {
    _isloading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://digitallami.com/match_admin.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null) {
          // Convert response to List<MatchedProfile>
          _matchedProfiles = (data['data'] as List)
              .map((profile) => MatchedProfile.fromJson(profile))
              .toList();

          if (_matchedProfiles.isNotEmpty) {
            _name = _matchedProfiles.first.firstName;
            _memberid = _matchedProfiles.first.memberid;
          }
        } else {
          _matchedProfiles = [];
          _name = 'no';
          _memberid = 'no';
        }
        _isloading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to load matched profiles');
      }
    } catch (e) {
      debugPrint('Error fetching matched profiles: $e');
      _isloading = false;
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

  void clearData() {
    _matchedProfiles.clear();
    _name = '';
    _memberid = '';
    notifyListeners();
  }
}