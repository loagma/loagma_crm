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

      final uri =
          Uri.parse('$baseUrl/route').replace(queryParameters: queryParams);

      final token = UserService.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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
}
