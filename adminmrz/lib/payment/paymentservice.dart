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
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<PaymentHistoryResponse> getPaymentHistory({int startIndex = 0, int fetchRecord = 50}) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/get_payments.php'),
          headers: await _authHeaders(),
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
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) params['end_date'] = endDate.toIso8601String().split('T')[0];
    if (paymentMethod != null && paymentMethod.isNotEmpty) params['payment_method'] = paymentMethod;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse('$_baseUrl/get_payments.php').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http
        .get(uri, headers: await _authHeaders())
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
          Uri.parse('$_baseUrl/insert_payment.php'),
          headers: {
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          body: json.encode(paymentData),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to insert payment: ${response.statusCode}');
    }
  }
}
