import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/usermodel.dart';

class UserService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserListResponse> getUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_users.php'),
            headers: await _authHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Suspend the users identified by [userIds].
  Future<bool> suspendUsers(List<int> userIds) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/suspend_users.php'),
            headers: await _authHeaders(),
            body: json.encode({'user_ids': userIds}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to suspend users: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently delete the users identified by [userIds].
  Future<bool> deleteUsers(List<int> userIds) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_users.php'),
            headers: await _authHeaders(),
            body: json.encode({'user_ids': userIds}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to delete users: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}