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

  // Check approval status for employee
  static Future<Map<String, dynamic>> getApprovalStatus(
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
        Uri.parse('$baseUrl/status/$employeeId'),
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

  // Admin: Get Pending Approval Requests
  static Future<Map<String, dynamic>> getPendingApprovalRequests() async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/pending'),
        headers: headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
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

  // Admin: Approve/Reject Late Punch Request
  static Future<Map<String, dynamic>> adminAction({
    required int requestId,
    required String action, // 'APPROVED' or 'REJECTED'
    required String adminId,
    required String adminName,
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
            Uri.parse('$baseUrl/admin/action'),
            headers: headers,
            body: jsonEncode({
              'requestId': requestId,
              'action': action,
              'adminId': adminId,
              'adminName': adminName,
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
          'message': data['message'] ?? 'Action completed successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to complete action',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Helper method to check if current time is after 9:45 AM IST
  static bool isAfterCutoffTime() {
    // Get current time in IST (UTC+5:30)
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    // For testing: set cutoff to 8:00 AM so approval widget shows more often
    final cutoffTime = DateTime(now.year, now.month, now.day, 8, 0);
    final isAfter = now.isAfter(cutoffTime);

    print(
      '🕘 Current IST time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
    print('🕘 Cutoff time: 8:00 (testing)');
    print('🕘 Is after cutoff: $isAfter');

    return isAfter;
  }

  // Helper method to format time remaining until cutoff
  static String getTimeUntilCutoff() {
    // Get current time in IST (UTC+5:30)
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    // For testing: set cutoff to 8:00 AM
    final cutoffTime = DateTime(now.year, now.month, now.day, 8, 0);

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
