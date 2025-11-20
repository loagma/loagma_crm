import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ExpenseService {
  // Create expense
  static Future<Map<String, dynamic>> createExpense({
    required String token,
    required String expenseType,
    required double amount,
    required DateTime expenseDate,
    String? description,
    String? billNumber,
    String? attachmentUrl,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/expenses');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'expenseType': expenseType,
          'amount': amount,
          'expenseDate': expenseDate.toIso8601String(),
          if (description != null) 'description': description,
          if (billNumber != null) 'billNumber': billNumber,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating expense: $e'};
    }
  }

  // Get my expenses
  static Future<Map<String, dynamic>> getMyExpenses({
    required String token,
    String? status,
    String? expenseType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (expenseType != null) queryParams['expenseType'] = expenseType;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/expenses/my',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching expenses: $e'};
    }
  }

  // Get expense statistics
  static Future<Map<String, dynamic>> getExpenseStatistics({
    required String token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/expenses/statistics');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching statistics: $e'};
    }
  }

  // Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required String token,
    required String expenseId,
    String? expenseType,
    double? amount,
    DateTime? expenseDate,
    String? description,
    String? billNumber,
    String? attachmentUrl,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/expenses/$expenseId');

      final body = <String, dynamic>{};
      if (expenseType != null) body['expenseType'] = expenseType;
      if (amount != null) body['amount'] = amount;
      if (expenseDate != null) {
        body['expenseDate'] = expenseDate.toIso8601String();
      }
      if (description != null) body['description'] = description;
      if (billNumber != null) body['billNumber'] = billNumber;
      if (attachmentUrl != null) body['attachmentUrl'] = attachmentUrl;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating expense: $e'};
    }
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense({
    required String token,
    required String expenseId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/expenses/$expenseId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting expense: $e'};
    }
  }
}
