import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/usermodel.dart';

class UserService {
  static const String baseUrl = 'https://digitallami.com/api9';

  Future<UserListResponse> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_users.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

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
}