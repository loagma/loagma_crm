import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class EarlyPunchOutApprovalService {
  static String get baseUrl => '${ApiConfig.baseUrl}/early-punch-out-approval';

  // Request Early Punch-Out Approval
  static Future<Map<String, dynamic>> requestEarlyPunchOutApproval({
    required String employeeId,
    required String employeeName,
    required String attendanceId,
    required String reason,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Requesting early punch-out approval for: $employeeId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/request'),
            headers: headers,
            body: jsonEncode({
              'employeeId': employeeId,
              'employeeName': employeeName,
              'attendanceId': attendanceId,
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

      print(
        '📊 Early punch-out approval request response: ${response.statusCode}',
      );

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

  // Get Employee's Early Punch-Out Approval Status
  static Future<Map<String, dynamic>> getEmployeeEarlyPunchOutStatus(
    String employeeId, {
    String? attendanceId,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Fetching early punch-out approval status for: $employeeId');

      final queryParams = <String, String>{};
      if (attendanceId != null) {
        queryParams['attendanceId'] = attendanceId;
      }

      final uri = Uri.parse(
        '$baseUrl/employee/$employeeId/status',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      final data = jsonDecode(response.body);

      print(
        '📊 Early punch-out approval status response: ${response.statusCode}',
      );

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

  // Validate Early Punch-Out Approval Code
  static Future<Map<String, dynamic>> validateEarlyPunchOutCode({
    required String employeeId,
    required String attendanceId,
    required String approvalCode,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Validating early punch-out approval code for: $employeeId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/validate-code'),
            headers: headers,
            body: jsonEncode({
              'employeeId': employeeId,
              'attendanceId': attendanceId,
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

      print(
        '📊 Early punch-out code validation response: ${response.statusCode}',
      );

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

  // Admin: Get Pending Early Punch-Out Approval Requests
  static Future<Map<String, dynamic>> getPendingEarlyPunchOutRequests({
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

  // Admin: Approve Early Punch-Out Request
  static Future<Map<String, dynamic>> approveEarlyPunchOutRequest({
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

  // Admin: Reject Early Punch-Out Request
  static Future<Map<String, dynamic>> rejectEarlyPunchOutRequest({
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

  // Admin: Get All Early Punch-Out Approval Requests (with filters)
  static Future<Map<String, dynamic>> getAllEarlyPunchOutRequests({
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

  // Helper method to check if current time is before 6:30 PM IST
  static bool isBeforeEarlyPunchOutCutoff() {
    // Get current time in IST (UTC+5:30)
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final cutoffTime = DateTime(now.year, now.month, now.day, 18, 30);
    final isBefore = now.isBefore(cutoffTime);

    print(
      '🕘 Current IST time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
    print('🕘 Early punch-out cutoff time: 18:30');
    print('🕘 Is before cutoff: $isBefore');

    return isBefore;
  }

  // Helper method to format time remaining until early punch-out cutoff
  static String getTimeUntilEarlyPunchOutCutoff() {
    // Get current time in IST (UTC+5:30)
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final cutoffTime = DateTime(now.year, now.month, now.day, 18, 30);

    if (now.isAfter(cutoffTime)) {
      return 'Can punch out normally';
    }

    final difference = cutoffTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m until normal punch-out time';
    } else {
      return '${minutes}m until normal punch-out time';
    }
  }
}
