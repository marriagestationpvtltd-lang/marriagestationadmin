import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detailmodel.dart';

class UserDetailsService {
  static const String _baseUrl = 'https://digitallami.com/Api2';

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
}