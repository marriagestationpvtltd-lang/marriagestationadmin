import 'package:adminmrz/core/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'docmodel.dart';

class DocumentsProvider with ChangeNotifier {
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;
  bool _isActionLoading = false;

  DateTime? _lastFetchTime;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < AppConstants.cacheDuration;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isActionLoading => _isActionLoading;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Document> get pendingDocuments =>
      _documents.where((doc) => doc.isPending).toList();

  List<Document> get approvedDocuments =>
      _documents.where((doc) => doc.isApproved).toList();

  List<Document> get rejectedDocuments =>
      _documents.where((doc) => doc.isRejected).toList();

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> fetchDocuments({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _documents.isNotEmpty) return true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/admin/appUsers/getAppUsers');
      final response = await http
          .post(
            url,
            headers: await _authHeaders(),
            body: json.encode({'startIndex': 0, 'fetchRecord': 100, 'searchString': ''}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final status = responseData['status'];
        if (status == 200 || status?.toString() == '200') {
          final List<dynamic> data = responseData['recordList'] ?? [];
          _documents = data
              .map((u) => Document(
                    userId: u['id'] is int ? u['id'] : int.tryParse(u['id']?.toString() ?? '') ?? 0,
                    email: u['email']?.toString() ?? '',
                    firstName: u['firstName']?.toString() ?? '',
                    lastName: u['lastName']?.toString() ?? '',
                    gender: u['gender']?.toString() ?? '',
                    status: u['isVerified'] == 1
                        ? 'approved'
                        : u['isVerified'] == null
                            ? 'pending'
                            : 'rejected',
                    isVerified: u['isVerified'] is int ? u['isVerified'] : 0,
                    documentId: u['id'] is int ? u['id'] : int.tryParse(u['id']?.toString() ?? '') ?? 0,
                    documentType: 'Identity',
                    documentIdNumber: u['contactNo']?.toString() ?? '',
                    photo: null,
                  ))
              .toList();
          _lastFetchTime = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = responseData['message'] ?? 'Failed to load documents';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDocumentStatus({
    required int userId,
    required String action,
    String? rejectReason,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/admin/appUsers/approveDocument');
      final bool isVerified = action == 'approve';

      final response = await http
          .post(
            url,
            headers: await _authHeaders(),
            body: json.encode({'id': userId, 'isVerified': isVerified}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final status = responseData['status'];
        if (status == 200 || status?.toString() == '200') {
          final index = _documents.indexWhere((doc) => doc.userId == userId);
          if (index != -1) {
            final updatedDoc = Document(
              userId: _documents[index].userId,
              email: _documents[index].email,
              firstName: _documents[index].firstName,
              lastName: _documents[index].lastName,
              gender: _documents[index].gender,
              status: action == 'approve' ? 'approved' : 'rejected',
              isVerified: action == 'approve' ? 1 : 0,
              documentId: _documents[index].documentId,
              documentType: _documents[index].documentType,
              documentIdNumber: _documents[index].documentIdNumber,
              photo: _documents[index].photo,
            );
            _documents[index] = updatedDoc;
          }
          _isActionLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = responseData['message'] ?? 'Failed to update status';
          _isActionLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
        _isActionLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }
}
