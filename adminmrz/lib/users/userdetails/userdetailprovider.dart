import 'package:adminmrz/users/userdetails/userdetailservice.dart';
import 'package:flutter/material.dart';

import 'detailmodel.dart';


class UserDetailsProvider with ChangeNotifier {
  final UserDetailsService _userDetailsService = UserDetailsService();

  UserDetailsData? _userDetails;
  bool _isLoading = false;
  String _error = '';
  int? _userId;
  bool _isUpdating = false;
  String _updateError = '';

  UserDetailsData? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  String get error => _error;
  int? get userId => _userId;
  bool get isUpdating => _isUpdating;
  String get updateError => _updateError;

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

  /// Update a single profile field and refresh the local model on success.
  Future<bool> updateField({
    required String section,
    required String field,
    required String value,
  }) async {
    if (_userId == null) return false;
    _isUpdating = true;
    _updateError = '';
    notifyListeners();

    try {
      final success = await _userDetailsService.updateUserDetail(
        userId: _userId!,
        section: section,
        field: field,
        value: value,
      );
      if (!success) {
        _updateError = 'Update failed. Please try again.';
      }
      _isUpdating = false;
      notifyListeners();
      return success;
    } catch (e) {
      _updateError = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _userDetails = null;
    _error = '';
    _userId = null;
    _updateError = '';
    notifyListeners();
  }
}