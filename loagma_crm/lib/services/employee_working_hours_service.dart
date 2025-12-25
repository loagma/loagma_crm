import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class EmployeeWorkingHoursService {
  static String get baseUrl => '${ApiConfig.baseUrl}/employee-working-hours';

  // Get employee working hours configuration
  static Future<Map<String, dynamic>> getWorkingHours(String employeeId) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$employeeId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch working hours',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update employee working hours (admin only)
  static Future<Map<String, dynamic>> updateWorkingHours({
    required String employeeId,
    required String workStartTime,
    required String workEndTime,
    required int latePunchInGraceMinutes,
    required int earlyPunchOutGraceMinutes,
  }) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/$employeeId'),
        headers: headers,
        body: jsonEncode({
          'workStartTime': workStartTime,
          'workEndTime': workEndTime,
          'latePunchInGraceMinutes': latePunchInGraceMinutes,
          'earlyPunchOutGraceMinutes': earlyPunchOutGraceMinutes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update working hours',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Helper method to check if current time is after late punch-in cutoff
  static bool isAfterLatePunchInCutoff(Map<String, dynamic> workingHours) {
    try {
      final cutoffTimeStr = workingHours['latePunchInCutoffTime'] as String?;
      if (cutoffTimeStr == null) return false;

      // Parse cutoff time (HH:MM:SS)
      final cutoffParts = cutoffTimeStr.split(':');
      final cutoffHour = int.parse(cutoffParts[0]);
      final cutoffMinute = int.parse(cutoffParts[1]);

      // Get current local time (assuming device is in IST)
      final now = DateTime.now();

      // Check if device is already in IST timezone
      final timeZoneOffset = now.timeZoneOffset;
      final isAlreadyIST =
          timeZoneOffset.inMinutes == 330; // 5:30 = 330 minutes

      DateTime istTime;
      if (isAlreadyIST) {
        istTime = now;
      } else {
        istTime = now.toUtc().add(const Duration(hours: 5, minutes: 30));
      }

      // Create cutoff time for today
      final cutoffTime = DateTime(
        istTime.year,
        istTime.month,
        istTime.day,
        cutoffHour,
        cutoffMinute,
      );

      return istTime.isAfter(cutoffTime);
    } catch (e) {
      print('Error checking late punch-in cutoff: $e');
      return false;
    }
  }

  // Helper method to check if current time is before early punch-out cutoff
  static bool isBeforeEarlyPunchOutCutoff(Map<String, dynamic> workingHours) {
    try {
      final cutoffTimeStr = workingHours['earlyPunchOutCutoffTime'] as String?;
      if (cutoffTimeStr == null) return false;

      // Parse cutoff time (HH:MM:SS)
      final cutoffParts = cutoffTimeStr.split(':');
      final cutoffHour = int.parse(cutoffParts[0]);
      final cutoffMinute = int.parse(cutoffParts[1]);

      // Get current local time (assuming device is in IST)
      final now = DateTime.now();

      // Check if device is already in IST timezone
      final timeZoneOffset = now.timeZoneOffset;
      final isAlreadyIST =
          timeZoneOffset.inMinutes == 330; // 5:30 = 330 minutes

      DateTime istTime;
      if (isAlreadyIST) {
        istTime = now;
      } else {
        istTime = now.toUtc().add(const Duration(hours: 5, minutes: 30));
      }

      // Create cutoff time for today
      final cutoffTime = DateTime(
        istTime.year,
        istTime.month,
        istTime.day,
        cutoffHour,
        cutoffMinute,
      );

      final isBefore = istTime.isBefore(cutoffTime);

      print('🕘 Early punch-out cutoff check:');
      print('  - Device timezone offset: ${timeZoneOffset.inMinutes} minutes');
      print('  - Is already IST: $isAlreadyIST');
      print(
        '  - Current IST time: ${istTime.hour}:${istTime.minute.toString().padLeft(2, '0')}',
      );
      print(
        '  - Cutoff time: $cutoffHour:${cutoffMinute.toString().padLeft(2, '0')}',
      );
      print('  - Is before cutoff: $isBefore');

      return isBefore;
    } catch (e) {
      print('Error checking early punch-out cutoff: $e');
      return false;
    }
  }

  // Helper method to format time remaining until late punch-in cutoff
  static String getTimeUntilLatePunchInCutoff(
    Map<String, dynamic> workingHours,
  ) {
    try {
      final cutoffTimeStr = workingHours['latePunchInCutoffTime'] as String?;
      if (cutoffTimeStr == null) return 'Cutoff time not available';

      // Parse cutoff time (HH:MM:SS)
      final cutoffParts = cutoffTimeStr.split(':');
      final cutoffHour = int.parse(cutoffParts[0]);
      final cutoffMinute = int.parse(cutoffParts[1]);

      // Get current IST time
      final now = DateTime.now();
      final istTime = now.toUtc().add(const Duration(hours: 5, minutes: 30));

      // Create cutoff time for today
      final cutoffTime = DateTime(
        istTime.year,
        istTime.month,
        istTime.day,
        cutoffHour,
        cutoffMinute,
      );

      if (istTime.isAfter(cutoffTime)) {
        return 'Cutoff time passed';
      }

      final difference = cutoffTime.difference(istTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m until late punch-in cutoff';
      } else {
        return '${minutes}m until late punch-in cutoff';
      }
    } catch (e) {
      return 'Error calculating time';
    }
  }

  // Helper method to format time remaining until early punch-out cutoff
  static String getTimeUntilEarlyPunchOutCutoff(
    Map<String, dynamic> workingHours,
  ) {
    try {
      final cutoffTimeStr = workingHours['earlyPunchOutCutoffTime'] as String?;
      if (cutoffTimeStr == null) return 'Cutoff time not available';

      // Parse cutoff time (HH:MM:SS)
      final cutoffParts = cutoffTimeStr.split(':');
      final cutoffHour = int.parse(cutoffParts[0]);
      final cutoffMinute = int.parse(cutoffParts[1]);

      // Get current IST time
      final now = DateTime.now();
      final istTime = now.toUtc().add(const Duration(hours: 5, minutes: 30));

      // Create cutoff time for today
      final cutoffTime = DateTime(
        istTime.year,
        istTime.month,
        istTime.day,
        cutoffHour,
        cutoffMinute,
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
    } catch (e) {
      return 'Error calculating time';
    }
  }
}
