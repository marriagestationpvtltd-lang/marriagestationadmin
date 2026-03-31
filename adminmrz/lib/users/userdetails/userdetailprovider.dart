import 'package:adminmrz/users/userdetails/userdetailservice.dart';
import 'package:flutter/material.dart';

import 'detailmodel.dart';


class UserDetailsProvider with ChangeNotifier {
  final UserDetailsService _userDetailsService = UserDetailsService();

  UserDetailsData? _userDetails;
  bool _isLoading = false;
  String _error = '';
  int? _userId;

  UserDetailsData? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  String get error => _error;
  int? get userId => _userId;

  Future<void> fetchUserDetails(int userId, int myId) async {
    _isLoading = true;
    _error = '';
    _userId = userId;
    notifyListeners();

    try {
      final response = await _userDetailsService.getUserDetails(userId, myId);
      if (response.status == 'success') {
        _userDetails = response.data;
      } else {
        _error = 'Failed to load user details';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _userDetails = null;
    _error = '';
    _userId = null;
    notifyListeners();
  }
}