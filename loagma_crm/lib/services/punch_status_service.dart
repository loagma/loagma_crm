import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

/// Punch UI State - matches backend uiState values
enum PunchUIState {
  idle,
  canPunchIn,
  waitingApproval,
  sessionActive,
  canPunchOut,
}

/// Approval Type
enum ApprovalType { latePunchIn, earlyPunchOut }

/// Approval Status
enum ApprovalStatus { pending, approved, rejected, expired, used }

/// Punch Status Response Model
class PunchStatusResponse {
  final bool success;
  final String employeeId;
  final String employeeName;
  final String serverTime;
  final String serverTimeIST;

  // Working hours config (for display only)
  final String workStartTime;
  final String workEndTime;
  final int startGraceMinutes;
  final int endGraceMinutes;

  // Session state
  final ActiveSession? activeSession;
  final int todaySessionsCount;

  // Core UI state flags
  final bool canPunchIn;
  final bool canPunchOut;
  final bool requiresApproval;
  final ApprovalType? approvalType;
  final ApprovalStatus? approvalStatus;
  final String? approvalId;

  // UI message and state
  final String message;
  final PunchUIState uiState;

  PunchStatusResponse({
    required this.success,
    required this.employeeId,
    required this.employeeName,
    required this.serverTime,
    required this.serverTimeIST,
    required this.workStartTime,
    required this.workEndTime,
    required this.startGraceMinutes,
    required this.endGraceMinutes,
    this.activeSession,
    required this.todaySessionsCount,
    required this.canPunchIn,
    required this.canPunchOut,
    required this.requiresApproval,
    this.approvalType,
    this.approvalStatus,
    this.approvalId,
    required this.message,
    required this.uiState,
  });

  factory PunchStatusResponse.fromJson(Map<String, dynamic> json) {
    final workingHours = json['workingHours'] ?? {};

    return PunchStatusResponse(
      success: json['success'] ?? false,
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      serverTime: json['serverTime'] ?? '',
      serverTimeIST: json['serverTimeIST'] ?? '',
      workStartTime: workingHours['startTime'] ?? '09:00:00',
      workEndTime: workingHours['endTime'] ?? '18:00:00',
      startGraceMinutes: workingHours['startGraceMinutes'] ?? 45,
      endGraceMinutes: workingHours['endGraceMinutes'] ?? 30,
      activeSession: json['activeSession'] != null
          ? ActiveSession.fromJson(json['activeSession'])
          : null,
      todaySessionsCount: json['todaySessionsCount'] ?? 0,
      canPunchIn: json['canPunchIn'] ?? false,
      canPunchOut: json['canPunchOut'] ?? false,
      requiresApproval: json['requiresApproval'] ?? false,
      approvalType: _parseApprovalType(json['approvalType']),
      approvalStatus: _parseApprovalStatus(json['approvalStatus']),
      approvalId: json['approvalId'],
      message: json['message'] ?? '',
      uiState: _parseUIState(json['uiState']),
    );
  }

  static ApprovalType? _parseApprovalType(String? type) {
    if (type == null) return null;
    switch (type) {
      case 'LATE_PUNCH_IN':
        return ApprovalType.latePunchIn;
      case 'EARLY_PUNCH_OUT':
        return ApprovalType.earlyPunchOut;
      default:
        return null;
    }
  }

  static ApprovalStatus? _parseApprovalStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'PENDING':
        return ApprovalStatus.pending;
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      case 'EXPIRED':
        return ApprovalStatus.expired;
      case 'USED':
        return ApprovalStatus.used;
      default:
        return null;
    }
  }

  static PunchUIState _parseUIState(String? state) {
    switch (state) {
      case 'CAN_PUNCH_IN':
        return PunchUIState.canPunchIn;
      case 'WAITING_APPROVAL':
        return PunchUIState.waitingApproval;
      case 'SESSION_ACTIVE':
        return PunchUIState.sessionActive;
      case 'CAN_PUNCH_OUT':
        return PunchUIState.canPunchOut;
      default:
        return PunchUIState.idle;
    }
  }
}

class ActiveSession {
  final String id;
  final String punchInTime;
  final String punchInTimeIST;
  final String status;

  ActiveSession({
    required this.id,
    required this.punchInTime,
    required this.punchInTimeIST,
    required this.status,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] ?? '',
      punchInTime: json['punchInTime'] ?? '',
      punchInTimeIST: json['punchInTimeIST'] ?? '',
      status: json['status'] ?? 'OPEN',
    );
  }
}

/// Punch Status Service - Single source of truth for UI state
class PunchStatusService {
  static String get baseUrl => '${ApiConfig.baseUrl}/punch';

  static Map<String, String> get _headers {
    final token = UserService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /punch/status/:employeeId
  /// Single source of truth for UI - call this on app open/refresh
  static Future<PunchStatusResponse?> getPunchStatus(String employeeId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status/$employeeId'), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PunchStatusResponse.fromJson(data);
      }

      print('❌ Get punch status failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Get punch status error: $e');
      return null;
    }
  }

  /// POST /punch/approval/request
  /// Request approval for late punch-in or early punch-out
  static Future<Map<String, dynamic>> requestApproval({
    required String employeeId,
    required String employeeName,
    required String type, // 'LATE_PUNCH_IN' or 'EARLY_PUNCH_OUT'
    required String reason,
    String? attendanceId, // Required for EARLY_PUNCH_OUT
  }) async {
    try {
      final body = {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'type': type,
        'reason': reason,
        if (attendanceId != null) 'attendanceId': attendanceId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/approval/request'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Request submitted',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to submit request',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// POST /punch/approval/approve (Admin only)
  static Future<Map<String, dynamic>> approveRequest({
    required String requestId,
    required String type,
    required String adminId,
    String? adminRemarks,
  }) async {
    try {
      final body = {
        'requestId': requestId,
        'type': type,
        'adminId': adminId,
        if (adminRemarks != null) 'adminRemarks': adminRemarks,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/approval/approve'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Operation completed',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// POST /punch/approval/reject (Admin only)
  static Future<Map<String, dynamic>> rejectRequest({
    required String requestId,
    required String type,
    required String adminId,
    String? adminRemarks,
  }) async {
    try {
      final body = {
        'requestId': requestId,
        'type': type,
        'adminId': adminId,
        if (adminRemarks != null) 'adminRemarks': adminRemarks,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/approval/reject'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Operation completed',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// GET /punch/approval/pending (Admin only)
  static Future<Map<String, dynamic>> getPendingApprovals({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      final uri = Uri.parse(
        '$baseUrl/approval/pending',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {'success': response.statusCode == 200, 'data': data['data']};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
