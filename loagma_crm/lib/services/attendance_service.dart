import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import 'api_config.dart';
import 'user_service.dart';
import 'route_tracking_service.dart';

class AttendanceService {
  static String get baseUrl => '${ApiConfig.baseUrl}/attendance';

  // Helper method to check network connectivity
  static Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Punch In
  static Future<Map<String, dynamic>> punchIn({
    required String employeeId,
    required String employeeName,
    required double latitude,
    required double longitude,
    String? photo,
    String? address,
    String? bikeKmStart,
  }) async {
    try {
      // Validate photo size before sending
      if (photo != null && photo.length > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Photo is too large. Please use a smaller image.',
        };
      }

      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Punching in for employee: $employeeId');
      print('🔑 Token available: ${token != null && token.isNotEmpty}');

      // Check connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        return {
          'success': false,
          'message':
              'No internet connection. Please check your network and try again.',
        };
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/punch-in'),
            headers: headers,
            body: jsonEncode({
              'employeeId': employeeId,
              'employeeName': employeeName,
              'punchInLatitude': latitude,
              'punchInLongitude': longitude,
              'punchInPhoto': photo,
              'punchInAddress': address,
              'bikeKmStart': bikeKmStart,
            }),
          )
          .timeout(
            const Duration(
              seconds: 45,
            ), // Increased timeout for Render cold starts
            onTimeout: () {
              throw Exception(
                'Request timeout. The server might be starting up. Please try again.',
              );
            },
          );

      final data = jsonDecode(response.body);

      print('📊 Punch in response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 201 || response.statusCode == 200) {
        final result = {
          'success': true,
          'message': data['message'] ?? 'Punched in successfully',
          'data': data['data'] != null
              ? AttendanceModel.fromJson(data['data'])
              : null,
        };

        // Start route tracking for the new attendance session
        // This extends existing functionality without modifying punch-in logic
        if (result['data'] != null) {
          final attendanceModel = result['data'] as AttendanceModel;
          try {
            await RouteTrackingService.instance.startRouteTracking(
              attendanceModel.id,
            );
            print(
              '✅ Route tracking started for attendance: ${attendanceModel.id}',
            );
          } catch (e) {
            print('⚠️ Route tracking failed to start: $e');
            // Don't fail punch-in if route tracking fails
          }
        }

        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to punch in',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      String errorMessage = 'Network error. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      } else if (e.toString().contains('memory') ||
          e.toString().contains('OutOfMemory')) {
        errorMessage = 'Photo too large. Please use a smaller image.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Punch Out
  static Future<Map<String, dynamic>> punchOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? photo,
    String? address,
    String? bikeKmEnd,
  }) async {
    try {
      // Validate photo size before sending
      if (photo != null && photo.length > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Photo is too large. Please use a smaller image.',
        };
      }

      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Punching out for attendance: $attendanceId');
      print('🔑 Token available: ${token != null && token.isNotEmpty}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/punch-out'),
            headers: headers,
            body: jsonEncode({
              'attendanceId': attendanceId,
              'punchOutLatitude': latitude,
              'punchOutLongitude': longitude,
              'punchOutPhoto': photo,
              'punchOutAddress': address,
              'bikeKmEnd': bikeKmEnd,
            }),
          )
          .timeout(
            const Duration(seconds: 30), // Add timeout
            onTimeout: () {
              throw Exception('Request timeout. Please check your connection.');
            },
          );

      final data = jsonDecode(response.body);

      print('📊 Punch out response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 200) {
        final result = {
          'success': true,
          'message': data['message'] ?? 'Punched out successfully',
          'data': data['data'] != null
              ? AttendanceModel.fromJson(data['data'])
              : null,
        };

        // Stop route tracking when punch-out completes
        // This extends existing functionality without modifying punch-out logic
        try {
          RouteTrackingService.instance.stopRouteTracking();
          print('✅ Route tracking stopped for attendance: $attendanceId');
        } catch (e) {
          print('⚠️ Route tracking failed to stop: $e');
          // Don't fail punch-out if route tracking fails
        }

        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to punch out',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      String errorMessage = 'Network error. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      } else if (e.toString().contains('memory') ||
          e.toString().contains('OutOfMemory')) {
        errorMessage = 'Photo too large. Please use a smaller image.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Get Today's Attendance
  static Future<AttendanceModel?> getTodayAttendance(String employeeId) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('🔍 Fetching today attendance for: $employeeId');
      print('🔑 Token available: ${token != null && token.isNotEmpty}');

      final response = await http.get(
        Uri.parse('$baseUrl/today/$employeeId'),
        headers: headers,
      );

      print('📊 Attendance response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 401) {
        print('❌ Authentication failed for attendance');
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null) {
          return AttendanceModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching today attendance: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication')) {
        rethrow; // Re-throw authentication errors
      }
      return null;
    }
  }

  // Get Attendance History
  static Future<Map<String, dynamic>> getAttendanceHistory({
    required String employeeId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse(
        '$baseUrl/history/$employeeId',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final attendances = (data['data'] as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'data': attendances,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch history',
          'data': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  // Get Attendance Statistics
  static Future<Map<String, dynamic>> getAttendanceStats({
    required String employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = {
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/stats/$employeeId',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Get All Attendance Records
  static Future<Map<String, dynamic>> getAllAttendance({
    String? date,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (date != null) 'date': date,
        if (status != null) 'status': status,
      };

      final uri = Uri.parse(
        '$baseUrl/all',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final attendances = (data['data'] as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'data': attendances,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch attendance records',
          'data': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  // Admin: Get Live Attendance Dashboard
  static Future<Map<String, dynamic>> getLiveAttendanceDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final attendances = (data['data']['attendances'] as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'data': {
            'statistics': data['data']['statistics'],
            'attendances': attendances,
            'absentEmployees': data['data']['absentEmployees'],
            'date': data['data']['date'],
          },
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch dashboard data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Get Attendance Analytics
  static Future<Map<String, dynamic>> getAttendanceAnalytics({
    String? startDate,
    String? endDate,
    String? employeeId,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (employeeId != null) 'employeeId': employeeId,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/analytics',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch analytics',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Admin: Get Detailed Attendance with Full Information
  static Future<Map<String, dynamic>> getDetailedAttendance({
    String? date,
    String? employeeId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (date != null) 'date': date,
        if (employeeId != null) 'employeeId': employeeId,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/detailed',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final attendances = (data['data'] as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'data': attendances,
          'pagination': data['pagination'],
          'filters': data['filters'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch detailed attendance',
          'data': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  // Admin: Get Employee Attendance Report
  static Future<Map<String, dynamic>> getEmployeeAttendanceReport({
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = {
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/admin/report',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch employee report',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
