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

  Future<UserListResponse> getUsers({int startIndex = 0, int fetchRecord = 50, String searchString = ''}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/appUsers/getAppUsers'),
          headers: await _authHeaders(),
          body: json.encode({
            'startIndex': startIndex,
            'fetchRecord': fetchRecord,
            'searchString': searchString,
          }),
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
    final headers = await _authHeaders();
    final results = await Future.wait(userIds.map((userId) async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/users/activeInactiveUsers'),
            headers: headers,
            body: json.encode({'id': userId}),
          )
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 200;
      }
      return false;
    }));
    return results.every((r) => r);
  }

  Future<bool> deleteUsers(List<int> userIds) async {
    final headers = await _authHeaders();
    final results = await Future.wait(userIds.map((userId) async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/users/deleteUser'),
            headers: headers,
            body: json.encode({'id': userId}),
          )
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 200;
      }
      return false;
    }));
    return results.every((r) => r);
  }
}
