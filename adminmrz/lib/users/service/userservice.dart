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
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _jsonAuthHeaders() async {
    return {
      ...await _authHeaders(),
      'Content-Type': 'application/json',
    };
  }

  Future<UserListResponse> getUsers({int startIndex = 0, int fetchRecord = 50, String searchString = ''}) async {
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
  }

  Future<bool> suspendUsers(List<int> userIds) async {
    final headers = await _jsonAuthHeaders();
    final results = await Future.wait(userIds.map((userId) async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update_user_status.php'),
            headers: headers,
            body: json.encode({'id': userId, 'action': 'suspend'}),
          )
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    }));
    return results.every((r) => r);
  }

  Future<bool> deleteUsers(List<int> userIds) async {
    final headers = await _jsonAuthHeaders();
    final results = await Future.wait(userIds.map((userId) async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_user.php'),
            headers: headers,
            body: json.encode({'id': userId}),
          )
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    }));
    return results.every((r) => r);
  }
}
