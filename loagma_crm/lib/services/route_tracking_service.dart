import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'route_service.dart';
import 'user_service.dart';

/// Service for tracking salesman routes during active attendance sessions
/// Extends existing location logic to store GPS points for route visualization
/// Designed to be battery-friendly and performance-conscious
class RouteTrackingService {
  static RouteTrackingService? _instance;
  static RouteTrackingService get instance =>
      _instance ??= RouteTrackingService._();
  RouteTrackingService._();

  Timer? _routeTimer;
  String? _activeAttendanceId;
  Position? _lastStoredPosition;
  bool _isRouteTracking = false;

  // Configuration constants
  static const int _trackingIntervalSeconds = 25; // Send GPS every 25 seconds
  static const double _minimumDistanceMeters =
      10.0; // Minimum movement to store point
  static const double _maxSpeedKmh =
      200.0; // Flag abnormal speeds above 200 km/h

  bool get isRouteTracking => _isRouteTracking;
  String? get activeAttendanceId => _activeAttendanceId;

  /// Start route tracking for an active attendance session
  /// Integrates with existing location service without modifying punch-in logic
  ///
  /// Parameters:
  /// - attendanceId: ID of the active attendance session
  Future<bool> startRouteTracking(String attendanceId) async {
    try {
      // Ensure location service is running
      if (!LocationService.instance.isTracking) {
        final started = await LocationService.instance.startLocationTracking();
        if (!started) {
          print('❌ Could not start location service for route tracking');
          return false;
        }
      }

      // Stop any existing route tracking
      stopRouteTracking();

      _activeAttendanceId = attendanceId;
      _isRouteTracking = true;
      _lastStoredPosition = null;

      // Store initial position if available
      final currentPosition = LocationService.instance.currentPosition;
      if (currentPosition != null) {
        await _storeRoutePoint(currentPosition);
      }

      // Start periodic route point storage
      _routeTimer = Timer.periodic(
        Duration(seconds: _trackingIntervalSeconds),
        (timer) => _onRouteTimerTick(),
      );

      print('✅ Route tracking started for attendance: $attendanceId');
      return true;
    } catch (e) {
      print('❌ Error starting route tracking: $e');
      return false;
    }
  }

  /// Stop route tracking
  /// Called when punch-out occurs or attendance session ends
  void stopRouteTracking() {
    _routeTimer?.cancel();
    _routeTimer = null;
    _activeAttendanceId = null;
    _isRouteTracking = false;
    _lastStoredPosition = null;

    print('🛑 Route tracking stopped');
  }

  /// Handle periodic route tracking timer
  /// Stores GPS points if significant movement detected
  Future<void> _onRouteTimerTick() async {
    try {
      if (!_isRouteTracking || _activeAttendanceId == null) {
        return;
      }

      final currentPosition = LocationService.instance.currentPosition;
      if (currentPosition == null) {
        print('⚠️ No current position available for route tracking');
        return;
      }

      // Check if this is a significant movement
      if (_shouldStorePosition(currentPosition)) {
        await _storeRoutePoint(currentPosition);
      }
    } catch (e) {
      print('❌ Error in route timer tick: $e');
    }
  }

  /// Determine if current position should be stored
  /// Filters out duplicate points and minimal movements
  bool _shouldStorePosition(Position currentPosition) {
    // Always store first position
    if (_lastStoredPosition == null) {
      return true;
    }

    // Calculate distance from last stored position
    final distance = Geolocator.distanceBetween(
      _lastStoredPosition!.latitude,
      _lastStoredPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Only store if moved significantly
    if (distance < _minimumDistanceMeters) {
      print(
        '📍 Skipping route point - insufficient movement: ${distance.toStringAsFixed(1)}m',
      );
      return false;
    }

    // Check for abnormal GPS jumps (potential GPS errors)
    if (distance > 1000) {
      // More than 1km in 25 seconds
      final timeDiff = currentPosition.timestamp.difference(
        _lastStoredPosition!.timestamp,
      );
      final speedKmh = (distance / 1000) / (timeDiff.inSeconds / 3600);

      if (speedKmh > _maxSpeedKmh) {
        print(
          '⚠️ Flagging abnormal GPS jump: ${speedKmh.toStringAsFixed(1)} km/h',
        );
        // Store anyway but flag it silently - don't block route tracking
      }
    }

    return true;
  }

  /// Store GPS route point via API
  /// Lightweight operation optimized for frequent calls
  Future<void> _storeRoutePoint(Position position) async {
    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null || _activeAttendanceId == null) {
        print('❌ Missing employee ID or attendance ID for route point');
        return;
      }

      // Calculate speed if available
      double? speed;
      if (position.speed >= 0) {
        speed = position.speed * 3.6; // Convert m/s to km/h
      }

      final result = await RouteService.storeRoutePoint(
        employeeId: employeeId,
        attendanceId: _activeAttendanceId!,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speed,
        accuracy: position.accuracy,
      );

      if (result['success']) {
        _lastStoredPosition = position;
        print(
          '📍 Route point stored: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
      } else {
        print('❌ Failed to store route point: ${result['message']}');

        // If attendance is completed, stop tracking
        if (result['message']?.contains('completed') == true) {
          print('🛑 Attendance completed - stopping route tracking');
          stopRouteTracking();
        }
      }
    } catch (e) {
      print('❌ Error storing route point: $e');
    }
  }

  /// Force store current position
  /// Used for important waypoints (e.g., when visiting accounts)
  Future<bool> forceStoreCurrentPosition() async {
    try {
      final currentPosition = LocationService.instance.currentPosition;
      if (currentPosition == null) {
        print('❌ No current position available for force store');
        return false;
      }

      await _storeRoutePoint(currentPosition);
      return true;
    } catch (e) {
      print('❌ Error force storing position: $e');
      return false;
    }
  }

  /// Get route tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isTracking': _isRouteTracking,
      'attendanceId': _activeAttendanceId,
      'lastPosition': _lastStoredPosition != null
          ? {
              'latitude': _lastStoredPosition!.latitude,
              'longitude': _lastStoredPosition!.longitude,
              'timestamp': _lastStoredPosition!.timestamp.toIso8601String(),
            }
          : null,
      'trackingInterval': _trackingIntervalSeconds,
    };
  }

  /// Dispose resources
  void dispose() {
    stopRouteTracking();
  }
}
