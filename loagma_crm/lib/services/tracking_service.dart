import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  static const Duration _minSendInterval = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const Duration _statusCheckInterval = Duration(seconds: 10);
  static const double _minDistanceMeters = 25;
  // Removed accuracy filter to allow tracking even with lower accuracy

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  Timer? _statusMonitorTimer;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  bool _isTracking = false;
  String? _attendanceId;
  String? _employeeId;
  String? _employeeName;
  BuildContext? _context; // For showing alerts
  bool _locationServiceEnabled = true;
  bool _networkConnected = true;
  bool _hasShownLocationAlert = false;
  bool _hasShownNetworkAlert = false;

  bool get isTracking => _isTracking;
  
  // Set context for showing alerts (should be called from UI)
  void setContext(BuildContext? context) {
    _context = context;
  }

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

    // Start heartbeat to force updates every 5 seconds
    _startHeartbeat();
    
    // Start status monitoring
    _startStatusMonitoring();

    _isTracking = true;
    print('✅ Tracking started for employee: $employeeId');
    return true;
  }

  Future<void> stopTracking() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _attendanceId = null;
    _employeeId = null;
    _employeeName = null;
    _lastSentAt = null;
    _lastSentPosition = null;
    _hasShownLocationAlert = false;
    _hasShownNetworkAlert = false;
    print('🛑 Tracking stopped');
  }

  void _handlePositionUpdate(Position position) {
    if (!_isTracking || _attendanceId == null || _employeeId == null) {
      return;
    }

    // Removed accuracy filter - accept all positions to keep tracking active
    // Only filter by time/distance to avoid excessive updates
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
      // If less than 5 seconds passed, only send if moved 25+ meters
      if (distance < _minDistanceMeters) {
        return;
      }
    }

    _lastSentAt = now;
    _lastSentPosition = position;

    _sendToFirebase(position);
    _sendToBackend(position);
  }

  // Heartbeat mechanism to force updates every 5 seconds
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      // Force send update even if location hasn't changed
      if (_lastSentPosition != null) {
        print('💓 Heartbeat: Forcing location update');
        // Update timestamp to keep status LIVE
        _sendToFirebase(_lastSentPosition!);
        _sendToBackend(_lastSentPosition!);
      } else {
        // If no position yet, try to get current location
        LocationService.instance.getCurrentLocation(forceRefresh: true).then((position) {
          if (position != null && _isTracking) {
            _lastSentPosition = position;
            _lastSentAt = DateTime.now();
            _sendToFirebase(position);
            _sendToBackend(position);
          }
        });
      }
    });
  }

  // Monitor location service and network status
  void _startStatusMonitoring() {
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = Timer.periodic(_statusCheckInterval, (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      // Check location service status
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled && !_hasShownLocationAlert) {
        _locationServiceEnabled = false;
        _hasShownLocationAlert = true;
        _showLocationDisabledAlert();
      } else if (locationEnabled && !_locationServiceEnabled) {
        _locationServiceEnabled = true;
        _hasShownLocationAlert = false;
        print('✅ Location service re-enabled');
      }

      // Check network connectivity
      final networkConnected = await NetworkService.checkConnectivity();
      if (!networkConnected && !_hasShownNetworkAlert) {
        _networkConnected = false;
        _hasShownNetworkAlert = true;
        _showNetworkDisabledAlert();
      } else if (networkConnected && !_networkConnected) {
        _networkConnected = true;
        _hasShownNetworkAlert = false;
        print('✅ Network reconnected');
        // Retry sending any pending updates
        if (_lastSentPosition != null) {
          _sendToFirebase(_lastSentPosition!);
          _sendToBackend(_lastSentPosition!);
        }
      }
    });
  }

  void _showLocationDisabledAlert() {
    print('⚠️ Location service disabled - showing alert');
    if (_context != null && _context!.mounted) {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Location Service Disabled')),
            ],
          ),
          content: const Text(
            'Location tracking requires GPS to be enabled.\n\n'
            'Please enable Location Services in your device settings to continue tracking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  void _showNetworkDisabledAlert() {
    print('⚠️ Network disconnected - showing alert');
    if (_context != null && _context!.mounted) {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('No Internet Connection')),
            ],
          ),
          content: const Text(
            'Location tracking requires internet connection.\n\n'
            'Please check your network connection and ensure Wi-Fi or mobile data is enabled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry connectivity check
                NetworkService.checkConnectivity();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
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
      // Use employeeId as document ID to ensure each salesman has unique document
      await _firestore
          .collection('tracking_live')
          .doc(employeeId.toString()) // Ensure string conversion
          .set(payload, SetOptions(merge: true));
      
      print('📡 Firebase update sent for employeeId: $employeeId');

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
