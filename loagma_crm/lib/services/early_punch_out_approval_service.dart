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

  // Check approval status for attendance
  static Future<Map<String, dynamic>> getApprovalStatus(
    int attendanceId,
  ) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print(
        '🔍 Fetching early punch-out approval status for attendance: $attendanceId',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/status/$attendanceId'),
        headers: headers,
      );

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

  // Admin: Get Pending Early Punch-Out Approval Requests
  static Future<Map<String, dynamic>> getPendingEarlyPunchOutRequests() async {
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

  // Admin: Approve/Reject Early Punch-Out Request
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

  // Helper method to check if current time is before 6:30 PM IST
  static bool isBeforeEarlyPunchOutCutoff() {
    // Get current local time
    final now = DateTime.now();

    // Check if we're already in IST timezone (UTC+5:30)
    final timeZoneOffset = now.timeZoneOffset;
    final isAlreadyIST =
        timeZoneOffset.inHours == 5 && timeZoneOffset.inMinutes == 330;

    DateTime istTime;
    if (isAlreadyIST) {
      // Already in IST, use local time directly
      istTime = now;
    } else {
      // Convert from UTC to IST
      final utcNow = now.toUtc();
      istTime = utcNow.add(const Duration(hours: 5, minutes: 30));
    }

    // Create cutoff time for the same day in IST
    final cutoffTime = DateTime(
      istTime.year,
      istTime.month,
      istTime.day,
      18,
      30,
    );
    final isBefore = istTime.isBefore(cutoffTime);

    print('🕘 System local time: ${now.toString()}');
    print(
      '🕘 System timezone offset: ${timeZoneOffset.inHours}:${(timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0')}',
    );
    print('🕘 Is already IST: $isAlreadyIST');
    print(
      '🕘 IST time used: ${istTime.toString()} (${istTime.hour}:${istTime.minute.toString().padLeft(2, '0')})',
    );
    print('🕘 Early punch-out cutoff: ${cutoffTime.toString()} (18:30 IST)');
    print('🕘 Is before cutoff: $isBefore');
    print(
      '🕘 Time difference: ${cutoffTime.difference(istTime).inMinutes} minutes',
    );

    return isBefore;
  }

  // Helper method to format time remaining until early punch-out cutoff
  static String getTimeUntilEarlyPunchOutCutoff() {
    // Get current local time
    final now = DateTime.now();

    // Check if we're already in IST timezone (UTC+5:30)
    final timeZoneOffset = now.timeZoneOffset;
    final isAlreadyIST =
        timeZoneOffset.inHours == 5 && timeZoneOffset.inMinutes == 330;

    DateTime istTime;
    if (isAlreadyIST) {
      // Already in IST, use local time directly
      istTime = now;
    } else {
      // Convert from UTC to IST
      final utcNow = now.toUtc();
      istTime = utcNow.add(const Duration(hours: 5, minutes: 30));
    }

    final cutoffTime = DateTime(
      istTime.year,
      istTime.month,
      istTime.day,
      18,
      30,
    );

    if (istTime.isAfter(cutoffTime)) {
      return 'Can punch out normally';
    }

    final difference = cutoffTime.difference(istTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m until normal punch-out time';
    } else {
      return '${minutes}m until normal punch-out time';
    }
  }
}
