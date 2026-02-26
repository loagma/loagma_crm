import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class TrackingApiService {
  static String get baseUrl => '${ApiConfig.baseUrl}/tracking';

  static Future<Map<String, dynamic>> getRoute({
    required String employeeId,
    DateTime? start,
    DateTime? end,
    String? attendanceId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'employeeId': employeeId,
        if (attendanceId != null) 'attendanceId': attendanceId,
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
        if (limit != null) 'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/route',
      ).replace(queryParameters: queryParams);

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'] ?? []};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load route',
        'data': [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  static Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/today');

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load attendance',
        'data': [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  /// Fetches the latest known position for a single employee.
  /// Uses GET /tracking/live?employeeId=... (correct backend endpoint).
  static Future<Map<String, dynamic>> getLatestLocation({
    required String employeeId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/live').replace(
        queryParameters: {'employeeId': employeeId},
      );

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // /live returns a list keyed by employee; grab the first entry for this employee
        final list = data['data'] as List?;
        final point = (list != null && list.isNotEmpty) ? list.first : null;
        return {'success': point != null, 'data': point};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load location',
        'data': null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  static Future<Map<String, dynamic>> getLiveTracking({
    String? employeeId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (employeeId != null) {
        queryParams['employeeId'] = employeeId;
      }

      final uri = Uri.parse(
        '$baseUrl/live',
      ).replace(queryParameters: queryParams);

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load live tracking',
        'data': [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }

  static Future<Map<String, dynamic>> getRouteStats({
    required String employeeId,
    String? attendanceId,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final queryParams = <String, String>{
        'employeeId': employeeId,
        if (attendanceId != null) 'attendanceId': attendanceId,
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
      };

      final uri = Uri.parse(
        '$baseUrl/route-stats',
      ).replace(queryParameters: queryParams);

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'] ?? {}};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load route stats',
        'data': {},
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> getTodayPunchedInEmployees() async {
    try {
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/all').replace(
        queryParameters: {
          'date': dateStr,
          'limit': '1000', // Get all for today
        },
      );

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Filter only punched-in employees (no punch out time)
        final allAttendance = data['data'] as List;
        final punchedIn = allAttendance.where((att) {
          return att['punchOutTime'] == null;
        }).toList();

        return {'success': true, 'data': punchedIn};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load attendance',
        'data': [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': []};
    }
  }
}
