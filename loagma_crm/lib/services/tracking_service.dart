import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'location_service.dart';
import 'network_service.dart';
import 'user_service.dart';

class TrackingService {
  static TrackingService? _instance;
  static TrackingService get instance => _instance ??= TrackingService._();
  TrackingService._();

  static const Duration _minSendInterval = Duration(seconds: 20);
  static const double _minDistanceMeters = 25;
  static const double _maxAccuracyMeters = 50;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  bool _isTracking = false;
  String? _attendanceId;
  String? _employeeId;
  String? _employeeName;

  bool get isTracking => _isTracking;

  Future<bool> startTracking({
    required String attendanceId,
    required String employeeId,
    required String employeeName,
  }) async {
    if (_isTracking) {
      return true;
    }

    // Ensure employeeName is never null or empty
    String finalEmployeeName = employeeName;
    if (finalEmployeeName.isEmpty) {
      // Fallback to UserService name if provided name is empty
      final userName = UserService.name;
      if (userName != null && userName.isNotEmpty) {
        finalEmployeeName = userName;
      } else {
        // Last resort: use employeeId as display name
        finalEmployeeName = employeeId;
      }
    }

    _attendanceId = attendanceId;
    _employeeId = employeeId;
    _employeeName = finalEmployeeName; // Now guaranteed to be non-empty

    final locationStarted =
        await LocationService.instance.startLocationTracking();
    if (!locationStarted) {
      return false;
    }

    _positionSubscription = LocationService.instance.locationStream.listen(
      _handlePositionUpdate,
      onError: (error) {
        print('❌ Tracking stream error: $error');
      },
      cancelOnError: false, // Keep listening even on errors
    );

    _isTracking = true;
    return true;
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _attendanceId = null;
    _employeeId = null;
    _employeeName = null;
    _lastSentAt = null;
    _lastSentPosition = null;
  }

  void _handlePositionUpdate(Position position) {
    if (!_isTracking || _attendanceId == null || _employeeId == null) {
      return;
    }

    if (position.accuracy > _maxAccuracyMeters) {
      return;
    }

    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!) < _minSendInterval) {
      final distance = _lastSentPosition == null
          ? 0.0
          : Geolocator.distanceBetween(
              _lastSentPosition!.latitude,
              _lastSentPosition!.longitude,
              position.latitude,
              position.longitude,
            );
      if (distance < _minDistanceMeters) {
        return;
      }
    }

    _lastSentAt = now;
    _lastSentPosition = position;

    _sendToFirebase(position);
    _sendToBackend(position);
  }

  Future<void> _sendToFirebase(Position position) async {
    try {
      final employeeId = _employeeId;
      final attendanceId = _attendanceId;
      if (employeeId == null || attendanceId == null) return;

      final timestamp = position.timestamp;
      
      // Ensure employeeName is never null or empty
      // _employeeName is guaranteed to be non-empty after startTracking()
      String finalEmployeeName = _employeeName ?? employeeId;
      if (finalEmployeeName.isEmpty) {
        // Fallback to UserService name if available
        final userName = UserService.name;
        if (userName != null && userName.isNotEmpty) {
          finalEmployeeName = userName;
        } else {
          // Last resort: use employeeId as display name
          finalEmployeeName = employeeId;
        }
      }
      
      final payload = {
        'employeeId': employeeId,
        'employeeName': finalEmployeeName,
        'attendanceId': attendanceId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'recordedAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Update live tracking (this keeps the employee "online")
      await _firestore
          .collection('tracking_live')
          .doc(employeeId)
          .set(payload, SetOptions(merge: true));

      // Store historical tracking points
      await _firestore
          .collection('tracking')
          .doc(employeeId)
          .collection('sessions')
          .doc(attendanceId)
          .collection('points')
          .add(payload);
          
      print('✅ Tracking point sent: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
    } catch (e) {
      print('❌ Firebase tracking write failed: $e');
      // Don't throw - continue tracking even if Firebase write fails
    }
  }

  Future<void> _sendToBackend(Position position) async {
    try {
      final employeeId = _employeeId;
      final attendanceId = _attendanceId;
      if (employeeId == null || attendanceId == null) return;

      final hasConnection = await NetworkService.checkConnectivity();
      if (!hasConnection) return;

      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tracking/point'),
        headers: headers,
        body: jsonEncode({
          'employeeId': employeeId,
          'attendanceId': attendanceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'recordedAt': position.timestamp.toIso8601String(),
        }),
      );
    } catch (e) {
      print('❌ Backend tracking write failed: $e');
    }
  }
}
