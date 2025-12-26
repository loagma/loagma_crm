import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_model.dart';
import '../services/api_config.dart';
import '../services/user_service.dart';

class LeaveService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/leaves';

  static Map<String, String> get _headers {
    final token = UserService.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Apply for leave
  static Future<LeaveModel> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'leaveType': leaveType,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return LeaveModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to apply for leave');
      }
    } catch (e) {
      print('Error applying for leave: $e');
      rethrow;
    }
  }

  /// Get my leaves with pagination and filtering
  static Future<Map<String, dynamic>> getMyLeaves({
    String status = 'ALL',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/my',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final leaves = (data['data']['leaves'] as List)
            .map((leave) => LeaveModel.fromJson(leave))
            .toList();

        return {
          'leaves': leaves,
          'pagination': data['data']['pagination'],
          'statistics': data['data']['statistics'] != null
              ? LeaveStatistics.fromJson(data['data']['statistics'])
              : null,
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch leaves');
      }
    } catch (e) {
      print('Error fetching my leaves: $e');
      rethrow;
    }
  }

  /// Get leave balance
  static Future<LeaveStatistics> getLeaveBalance({int? year}) async {
    try {
      final queryParams = year != null
          ? {'year': year.toString()}
          : <String, String>{};
      final uri = Uri.parse(
        '$_baseUrl/balance',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return LeaveStatistics.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch leave balance');
      }
    } catch (e) {
      print('Error fetching leave balance: $e');
      rethrow;
    }
  }

  /// Cancel leave (only pending leaves)
  static Future<LeaveModel> cancelLeave(String leaveId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$leaveId/cancel'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return LeaveModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel leave');
      }
    } catch (e) {
      print('Error cancelling leave: $e');
      rethrow;
    }
  }

  /// Get all leaves (Admin only)
  static Future<Map<String, dynamic>> getAllLeaves({
    String status = 'ALL',
    String? employeeId,
    String leaveType = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'status': status,
        'leaveType': leaveType,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (employeeId != null) {
        queryParams['employeeId'] = employeeId;
      }

      final uri = Uri.parse(
        '$_baseUrl/all',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final leaves = (data['data']['leaves'] as List)
            .map((leave) => LeaveModel.fromJson(leave))
            .toList();

        return {'leaves': leaves, 'pagination': data['data']['pagination']};
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch all leaves');
      }
    } catch (e) {
      print('Error fetching all leaves: $e');
      rethrow;
    }
  }

  /// Get pending leaves (Admin only)
  static Future<Map<String, dynamic>> getPendingLeaves({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$_baseUrl/pending',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final leaves = (data['data']['leaves'] as List)
            .map((leave) => LeaveModel.fromJson(leave))
            .toList();

        return {'leaves': leaves, 'pagination': data['data']['pagination']};
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch pending leaves');
      }
    } catch (e) {
      print('Error fetching pending leaves: $e');
      rethrow;
    }
  }

  /// Approve leave (Admin only)
  static Future<LeaveModel> approveLeave(
    String leaveId, {
    String? adminRemarks,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$leaveId/approve'),
        headers: _headers,
        body: jsonEncode({
          if (adminRemarks != null) 'adminRemarks': adminRemarks,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return LeaveModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to approve leave');
      }
    } catch (e) {
      print('Error approving leave: $e');
      rethrow;
    }
  }

  /// Reject leave (Admin only)
  static Future<LeaveModel> rejectLeave(
    String leaveId, {
    required String rejectionReason,
    String? adminRemarks,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$leaveId/reject'),
        headers: _headers,
        body: jsonEncode({
          'rejectionReason': rejectionReason,
          if (adminRemarks != null) 'adminRemarks': adminRemarks,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return LeaveModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to reject leave');
      }
    } catch (e) {
      print('Error rejecting leave: $e');
      rethrow;
    }
  }

  /// Get leave types
  static List<String> getLeaveTypes() {
    return ['Sick', 'Casual', 'Earned', 'Emergency', 'Unpaid'];
  }

  /// Get leave status options for filtering
  static List<String> getStatusOptions() {
    return ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'];
  }
}
