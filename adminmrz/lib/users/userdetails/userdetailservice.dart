import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detailmodel.dart';

class UserDetailsService {
  static const String _baseUrl = 'https://digitallami.com/Api2';
  static const String _adminBaseUrl = 'https://digitallami.com/api9';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<UserDetailsResponse> getUserDetails(int userId, int myId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/other_profile.php?userid=$userId&myid=$myId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserDetailsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update a single field for a user profile from the admin panel.
  /// [userId] – target user's ID
  /// [section] – one of: 'personal', 'family', 'lifestyle', 'partner'
  /// [field]   – API field key (snake_case, matches backend column)
  /// [value]   – new value as string
  Future<bool> updateUserDetail({
    required int userId,
    required String section,
    required String field,
    required String value,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_adminBaseUrl/update_user_profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': token,
        },
        body: json.encode({
          'userid': userId,
          'section': section,
          'field': field,
          'value': value,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true || data['status'] == 'success';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}