import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/attendance_model.dart';
import 'attendance_service.dart';
import 'tracking_service.dart';
import 'user_service.dart';

/// Central place to coordinate attendance sessions and live tracking.
///
/// Responsibilities:
/// - Persist the current `attendanceId` in `UserService`.
/// - Start `TrackingService` when there is an active attendance.
/// - Stop tracking and clear state when attendance is completed.
/// - Re-check on app/screens startup so tracking can resume automatically.
class AttendanceSessionManager {
  const AttendanceSessionManager._();

  /// Call this whenever a punch-in completes successfully.
  static Future<void> handlePunchInSuccess(
    BuildContext context,
    AttendanceModel attendance,
  ) async {
    try {
      // Persist active attendance ID for recovery after restarts.
      await UserService.setCurrentAttendanceId(attendance.id);

      final employeeId = UserService.currentUserId;
      final employeeName = UserService.name ?? attendance.employeeName;

      if (employeeId == null || employeeId.isEmpty) {
        debugPrint('⚠️ handlePunchInSuccess: employeeId is null/empty');
        return;
      }

      // If tracking is already running, don't restart it.
      if (TrackingService.instance.isTracking) {
        debugPrint('ℹ️ handlePunchInSuccess: tracking already active');
        return;
      }

      TrackingService.instance.setContext(context);
      await TrackingService.instance.startTracking(
        attendanceId: attendance.id,
        employeeId: employeeId,
        employeeName: employeeName,
      );

      debugPrint(
        '✅ handlePunchInSuccess: tracking started for attendance ${attendance.id}',
      );
    } catch (e) {
      debugPrint('❌ handlePunchInSuccess error: $e');
    }
  }

  /// Call this whenever a punch-out completes successfully.
  static Future<void> handlePunchOutSuccess() async {
    try {
      await UserService.setCurrentAttendanceId(null);

      if (TrackingService.instance.isTracking) {
        await TrackingService.instance.stopTracking();
        debugPrint('✅ handlePunchOutSuccess: tracking stopped');
      } else {
        debugPrint('ℹ️ handlePunchOutSuccess: tracking already stopped');
      }
    } catch (e) {
      debugPrint('❌ handlePunchOutSuccess error: $e');
    }
  }

  /// Ensure tracking is running for the current user if they have
  /// an active attendance today. Safe to call on app start or when
  /// important salesman screens are opened.
  static Future<void> ensureTrackingForActiveSession(
    BuildContext context,
  ) async {
    try {
      if (!UserService.hasValidAuth) {
        debugPrint(
          'ℹ️ ensureTrackingForActiveSession: user not authenticated, skipping',
        );
        return;
      }

      final employeeId = UserService.currentUserId;
      if (employeeId == null || employeeId.isEmpty) {
        debugPrint(
          '⚠️ ensureTrackingForActiveSession: employeeId is null/empty, skipping',
        );
        return;
      }

      // If tracking is already active, nothing to do.
      if (TrackingService.instance.isTracking) {
        debugPrint(
          'ℹ️ ensureTrackingForActiveSession: tracking already active',
        );
        return;
      }

      // Prefer today's attendance from backend to know current status.
      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (attendance == null || !attendance.isPunchedIn) {
        // No active attendance; clear any stale cached ID.
        await UserService.setCurrentAttendanceId(null);
        debugPrint(
          'ℹ️ ensureTrackingForActiveSession: no active attendance, nothing to track',
        );
        return;
      }

      await handlePunchInSuccess(context, attendance);
    } catch (e) {
      debugPrint('❌ ensureTrackingForActiveSession error: $e');
    }
  }
}
