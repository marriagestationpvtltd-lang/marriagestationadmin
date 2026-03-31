import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:adminmrz/payment/paymentmodel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<PaymentHistoryResponse> getPaymentHistory({int startIndex = 0, int fetchRecord = 50}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/admin/payment/getPayment'),
          headers: await _authHeaders(),
          body: json.encode({'startIndex': startIndex, 'fetchRecord': fetchRecord}),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PaymentHistoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load payment history: ${response.statusCode}');
    }
  }

  Future<PaymentHistoryResponse> getFilteredPayments({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? status,
    int startIndex = 0,
    int fetchRecord = 50,
  }) async {
    final Map<String, dynamic> body = {
      'startIndex': startIndex,
      'fetchRecord': fetchRecord,
    };
    if (startDate != null) body['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['endDate'] = endDate.toIso8601String().split('T')[0];
    if (paymentMethod != null && paymentMethod.isNotEmpty) body['paymentMethod'] = paymentMethod;
    if (status != null && status.isNotEmpty) body['status'] = status;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/admin/payment/getPayment'),
          headers: await _authHeaders(),
          body: json.encode(body),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PaymentHistoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load filtered payments: ${response.statusCode}');
    }
  }

  Future<bool> insertPayment(Map<String, dynamic> paymentData) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/admin/payment/insertPayment'),
          headers: await _authHeaders(),
          body: json.encode(paymentData),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 200;
    } else {
      throw Exception('Failed to insert payment: ${response.statusCode}');
    }
  }
}
