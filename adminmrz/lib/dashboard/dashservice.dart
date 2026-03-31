import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashmodel.dart';

class DashboardService {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  Future<DashboardResponse> getDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/admin/dashboard/getDashboardData'),
          headers: headers,
          body: json.encode({}),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DashboardResponse.fromJson(data);
    } else {
      throw Exception('Failed to load dashboard data: ${response.statusCode}');
    }
  }
}
