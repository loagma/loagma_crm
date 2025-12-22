import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class AdminApprovalService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Get pending late punch-in approval requests
  static Future<Map<String, dynamic>> getPendingLatePunchRequests({
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
        '$baseUrl/late-punch-approval/pending',
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

  // Get pending early punch-out approval requests
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
        '$baseUrl/early-punch-out-approval/pending',
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

  // Approve late punch-in request
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
            Uri.parse('$baseUrl/late-punch-approval/approve/$requestId'),
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

  // Reject late punch-in request
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
            Uri.parse('$baseUrl/late-punch-approval/reject/$requestId'),
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

  // Approve early punch-out request
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
            Uri.parse('$baseUrl/early-punch-out-approval/approve/$requestId'),
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

  // Reject early punch-out request
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
            Uri.parse('$baseUrl/early-punch-out-approval/reject/$requestId'),
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

  // Get all approval requests with filters
  static Future<Map<String, dynamic>> getAllApprovalRequests({
    int page = 1,
    int limit = 20,
    String? status,
    String? employeeId,
    String? startDate,
    String? endDate,
    String? type, // 'late_punch_in' or 'early_punch_out'
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

      String endpoint;
      if (type == 'early_punch_out') {
        endpoint = '$baseUrl/early-punch-out-approval/all';
      } else {
        endpoint = '$baseUrl/late-punch-approval/all';
      }

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

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

  // Get approval counts for dashboard
  static Future<Map<String, dynamic>> getApprovalCounts() async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Get counts from both endpoints
      final latePunchResponse = await http.get(
        Uri.parse(
          '$baseUrl/late-punch-approval/pending',
        ).replace(queryParameters: {'limit': '1'}),
        headers: headers,
      );

      final earlyPunchOutResponse = await http.get(
        Uri.parse(
          '$baseUrl/early-punch-out-approval/pending',
        ).replace(queryParameters: {'limit': '1'}),
        headers: headers,
      );

      int latePunchCount = 0;
      int earlyPunchOutCount = 0;

      if (latePunchResponse.statusCode == 200) {
        final data = jsonDecode(latePunchResponse.body);
        latePunchCount = data['pagination']?['total'] ?? 0;
      }

      if (earlyPunchOutResponse.statusCode == 200) {
        final data = jsonDecode(earlyPunchOutResponse.body);
        earlyPunchOutCount = data['pagination']?['total'] ?? 0;
      }

      return {
        'success': true,
        'data': {
          'latePunchIn': latePunchCount,
          'earlyPunchOut': earlyPunchOutCount,
          'total': latePunchCount + earlyPunchOutCount,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
