import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import 'api_config.dart';

class AttendanceService {
  static String get baseUrl => '${ApiConfig.baseUrl}/attendance';

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
      final response = await http.post(
        Uri.parse('$baseUrl/punch-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'employeeName': employeeName,
          'punchInLatitude': latitude,
          'punchInLongitude': longitude,
          'punchInPhoto': photo,
          'punchInAddress': address,
          'bikeKmStart': bikeKmStart,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Punched in successfully',
          'data': data['data'] != null
              ? AttendanceModel.fromJson(data['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to punch in',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
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
      final response = await http.post(
        Uri.parse('$baseUrl/punch-out'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'attendanceId': attendanceId,
          'punchOutLatitude': latitude,
          'punchOutLongitude': longitude,
          'punchOutPhoto': photo,
          'punchOutAddress': address,
          'bikeKmEnd': bikeKmEnd,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Punched out successfully',
          'data': data['data'] != null
              ? AttendanceModel.fromJson(data['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to punch out',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Today's Attendance
  static Future<AttendanceModel?> getTodayAttendance(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/today/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null) {
          return AttendanceModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching today attendance: $e');
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
