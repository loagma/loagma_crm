import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class LatePunchApprovalService {
  static String get baseUrl => '${ApiConfig.baseUrl}/late-punch-approval';

  // Request Late Punch-In Approval
  static Future<Map<String, dynamic>> requestLatePunchApproval({
    required String employeeId,
    required String employeeName,
    required String reason,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Requesting late punch approval for: $employeeId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/request'),
            headers: headers,
            body: jsonEncode({
              'employeeId': employeeId,
              'employeeName': employeeName,
              'reason': reason,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      final data = jsonDecode(response.body);

      print('📊 Late punch approval request response: ${response.statusCode}');

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Approval request submitted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit approval request',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      String errorMessage = 'Network error. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Get Employee's Approval Request Status
  static Future<Map<String, dynamic>> getEmployeeApprovalStatus(
    String employeeId,
  ) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Fetching approval status for: $employeeId');

      final response = await http.get(
        Uri.parse('$baseUrl/employee/$employeeId/status'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      print('📊 Approval status response: ${response.statusCode}');

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch approval status',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Validate Approval Code
  static Future<Map<String, dynamic>> validateApprovalCode({
    required String employeeId,
    required String approvalCode,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Validating approval code for: $employeeId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/validate-code'),
            headers: headers,
            body: jsonEncode({
              'employeeId': employeeId,
              'approvalCode': approvalCode,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      final data = jsonDecode(response.body);

      print('📊 Code validation response: ${response.statusCode}');

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Approval code is valid',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid approval code',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      String errorMessage = 'Network error. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Admin: Get Pending Approval Requests
  static Future<Map<String, dynamic>> getPendingApprovalRequests({
    int page = 1,
    int limit = 20,
    String? date,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (date != null) 'date': date,
      };

      final uri = Uri.parse(
        '$baseUrl/pending',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch pending requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Approve Late Punch Request
  static Future<Map<String, dynamic>> approveLatePunchRequest({
    required String requestId,
    required String adminId,
    String? adminRemarks,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/approve/$requestId'),
            headers: headers,
            body: jsonEncode({
              'adminId': adminId,
              'adminRemarks': adminRemarks,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Request approved successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to approve request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Reject Late Punch Request
  static Future<Map<String, dynamic>> rejectLatePunchRequest({
    required String requestId,
    required String adminId,
    required String adminRemarks,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/reject/$requestId'),
            headers: headers,
            body: jsonEncode({
              'adminId': adminId,
              'adminRemarks': adminRemarks,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Request rejected successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reject request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Get All Approval Requests (with filters)
  static Future<Map<String, dynamic>> getAllApprovalRequests({
    int page = 1,
    int limit = 20,
    String? status,
    String? employeeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (employeeId != null) 'employeeId': employeeId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse(
        '$baseUrl/all',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
          'filters': data['filters'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch approval requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Helper method to check if current time is after 9:45 AM
  static bool isAfterCutoffTime() {
    final now = DateTime.now();
    final cutoffTime = DateTime(now.year, now.month, now.day, 9, 45);
    return now.isAfter(cutoffTime);
  }

  // Helper method to format time remaining until cutoff
  static String getTimeUntilCutoff() {
    final now = DateTime.now();
    final cutoffTime = DateTime(now.year, now.month, now.day, 9, 45);

    if (now.isAfter(cutoffTime)) {
      return 'Cutoff time passed';
    }

    final difference = cutoffTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }
}
