import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:adminmrz/package/packagemodel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PackageService {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _jsonAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<PackageListResponse> getPackages({int startIndex = 0, int fetchRecord = 50}) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/get_packages.php'),
          headers: await _authHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PackageListResponse.fromJson(data);
    } else {
      throw Exception('Failed to load packages: ${response.statusCode}');
    }
  }

  Future<CreatePackageResponse> createPackage(Package package) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/create_package.php'),
          headers: await _jsonAuthHeaders(),
          body: json.encode({
            'name': package.name,
            'baseAmount': package.baseAmount,
            'facility': package.facility,
            'duration': package.duration,
          }),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CreatePackageResponse.fromJson(data);
    } else {
      throw Exception('Failed to create package: ${response.statusCode}');
    }
  }

  Future<bool> updatePackage(Package package) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/update_package.php'),
          headers: await _jsonAuthHeaders(),
          body: json.encode(package.toJson()),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to update package: ${response.statusCode}');
    }
  }

  Future<bool> deletePackage(int packageId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/delete_package.php'),
          headers: await _jsonAuthHeaders(),
          body: json.encode({'id': packageId}),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to delete package: ${response.statusCode}');
    }
  }

  Future<bool> toggleActivePackage(int packageId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/toggle_package.php'),
          headers: await _jsonAuthHeaders(),
          body: json.encode({'id': packageId}),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to toggle package status: ${response.statusCode}');
    }
  }
}
