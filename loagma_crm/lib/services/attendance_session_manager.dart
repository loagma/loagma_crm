import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../models/attendance_model.dart';
import 'attendance_service.dart';
import 'location_service.dart';
import 'socket_tracking_service.dart';
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
      if (SocketTrackingService.instance.isTracking) {
        debugPrint('ℹ️ handlePunchInSuccess: tracking already active');
        return;
      }

      // On Android, require "Allow all the time" so tracking works with screen off.
      if (defaultTargetPlatform == TargetPlatform.android) {
        final hasBackgroundBefore = await LocationService.instance
            .hasBackgroundLocationPermission();
        if (!hasBackgroundBefore) {
          debugPrint(
            '⚠️ handlePunchInSuccess: Android background location not granted, showing dialog',
          );

          // This dialog clearly explains why "Allow all the time" is needed
          // and takes the user to App Settings.
          await LocationService.showRequireBackgroundLocationDialog(context);

          // Re-check after the user returns from Settings. Only allow the
          // shift to start if background permission is now granted.
          final hasBackgroundAfter = await LocationService.instance
              .hasBackgroundLocationPermission();

          if (!hasBackgroundAfter) {
            debugPrint(
              '❌ handlePunchInSuccess: background location still not granted after dialog, aborting tracking start',
            );
            return;
          }

          debugPrint(
            '✅ handlePunchInSuccess: background location granted after dialog',
          );
        }

        final hasNotification =
            await LocationService.instance.hasNotificationPermission();
        if (!hasNotification) {
          final granted =
              await LocationService.instance.requestNotificationPermission();
          if (!granted) {
            debugPrint(
              '❌ handlePunchInSuccess: notification permission not granted, aborting tracking start',
            );
            return;
          }
        }
      }

      // Connect to Socket.IO and start tracking
      await SocketTrackingService.instance.connect();
      await SocketTrackingService.instance.startTracking(
        employeeId: employeeId,
        attendanceId: attendance.id,
        employeeName: employeeName,
      );

      debugPrint(
        '✅ handlePunchInSuccess: Socket.IO tracking started for attendance ${attendance.id}',
      );
    } catch (e) {
      debugPrint('❌ handlePunchInSuccess error: $e');
    }
  }

  /// Call this whenever a punch-out completes successfully.
  static Future<void> handlePunchOutSuccess() async {
    try {
      await UserService.setCurrentAttendanceId(null);

      if (SocketTrackingService.instance.isTracking) {
        await SocketTrackingService.instance.stopTracking();
        await SocketTrackingService.instance.disconnect();
        debugPrint('✅ handlePunchOutSuccess: Socket.IO tracking stopped');
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
      if (SocketTrackingService.instance.isTracking) {
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
