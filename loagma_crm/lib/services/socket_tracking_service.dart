import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'user_service.dart';
import 'api_config.dart';
import 'location_service.dart';

/// Socket.IO-based tracking service for real-time GPS updates
/// Replaces Firestore for live tracking
class SocketTrackingService {
  static final SocketTrackingService instance =
      SocketTrackingService._internal();
  factory SocketTrackingService() => instance;
  SocketTrackingService._internal();

  IO.Socket? _socket;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _heartbeatTimer;

  String? _employeeId;
  String? _employeeName;
  String? _attendanceId;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastSentTime;

  // Configuration
  static const Duration _sendInterval = Duration(
    seconds: 3,
  ); // Reduced for responsiveness
  static const double _minDistanceMeters = 5; // 5 meters for smoother routes
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  int _reconnectAttempts = 0;
  bool _isConnecting = false;

  bool get isTracking => _isTracking;
  bool get isConnected => _socket?.connected ?? false;

  /// Initialize and connect to Socket.IO server
  Future<void> connect() async {
    if (_socket?.connected == true) {
      debugPrint('✅ Socket already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('⏳ Connection already in progress');
      return;
    }

    _isConnecting = true;

    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      // Use http:// URL directly - Socket.IO client handles WebSocket upgrade
      final socketUrl = ApiConfig.baseUrl;

      debugPrint('🔌 Connecting to Socket.IO: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Force WebSocket only
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(_reconnectDelay.inMilliseconds)
            .setTimeout(10000)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      _isConnecting = false;
      rethrow;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected: ${_socket!.id}');
      _isConnecting = false;
      _reconnectAttempts = 0;
      _startHeartbeat();
    });

    _socket!.onDisconnect((reason) {
      debugPrint('🔌 Socket disconnected: $reason');
      _stopHeartbeat();
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connection error: $error');
      _isConnecting = false;
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
    });

    _socket!.onReconnect((attempt) {
      debugPrint('🔄 Socket reconnecting (attempt $attempt)');
      _reconnectAttempts = attempt as int;
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ Socket reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint(
        '❌ Socket reconnection failed after $_maxReconnectAttempts attempts',
      );
    });

    // Listen for acknowledgments
    _socket!.on('location-ack', (data) {
      debugPrint('✅ Location acknowledged: $data');
    });

    // Listen for errors
    _socket!.on('error', (data) {
      debugPrint('❌ Server error: $data');
    });
  }

  /// Start tracking with Socket.IO
  Future<void> startTracking({
    required String employeeId,
    required String attendanceId,
    String? employeeName,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Tracking already active');
      return;
    }

    _employeeId = employeeId;
    _attendanceId = attendanceId;
    _employeeName = employeeName ?? employeeId;

    // Connect to socket if not connected
    if (!isConnected) {
      await connect();
    }

    // Start location service first
    final locationStarted = await LocationService.instance
        .startLocationTracking();
    if (!locationStarted) {
      debugPrint('❌ Failed to start location service');
      throw Exception('Failed to start location service');
    }

    // Notify server about session start
    _socket?.emit('session-start', {
      'employeeId': employeeId,
      'attendanceId': attendanceId,
      'employeeName': _employeeName,
      'startedAt': DateTime.now().toIso8601String(),
    });

    // Start listening to location updates
    _locationSubscription = LocationService.instance.locationStream.listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
    );

    _isTracking = true;
    debugPrint('🟢 Socket tracking started for $employeeId');
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    // Cancel location subscription
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Stop location service
    LocationService.instance.stopLocationTracking();

    // Notify server about session end
    _socket?.emit('session-end', {
      'employeeId': _employeeId,
      'attendanceId': _attendanceId,
      'endedAt': DateTime.now().toIso8601String(),
    });

    _isTracking = false;
    _lastPosition = null;
    _lastSentTime = null;

    debugPrint('🔴 Socket tracking stopped');
  }

  /// Handle location updates from GPS
  void _handleLocationUpdate(Position position) {
    if (!_isTracking || !isConnected) {
      debugPrint(
        '⏭️ Skipping location update: tracking=$_isTracking, connected=$isConnected',
      );
      return;
    }

    final now = DateTime.now();

    // PRIMARY FILTER: Movement-based (5 meters)
    // This is the main filter for smooth routes
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < _minDistanceMeters) {
        // Not enough movement, skip this update
        return;
      }

      debugPrint('✅ Movement threshold met: ${distance.toStringAsFixed(1)}m');
    }

    // SECONDARY FILTER: Time-based rate limiting (3 seconds minimum)
    // Prevents too frequent updates even when moving fast
    if (_lastSentTime != null &&
        now.difference(_lastSentTime!) < _sendInterval) {
      final timeSinceLastSend = now.difference(_lastSentTime!).inSeconds;
      debugPrint(
        '⏭️ Rate limit: too soon (${timeSinceLastSend}s < ${_sendInterval.inSeconds}s)',
      );
      return;
    }

    // Send location update via Socket.IO
    _sendLocationUpdate(position);
  }

  /// Send location update to server
  void _sendLocationUpdate(Position position) {
    if (!isConnected || _employeeId == null || _attendanceId == null) {
      debugPrint('⚠️ Cannot send location: Not connected or missing IDs');
      debugPrint(
        '   Connected: $isConnected, EmployeeId: $_employeeId, AttendanceId: $_attendanceId',
      );
      return;
    }

    final payload = {
      'employeeId': _employeeId,
      'employeeName': _employeeName,
      'attendanceId': _attendanceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('📤 Sending location update to server:');
    debugPrint('   Employee: $_employeeName ($_employeeId)');
    debugPrint('   Attendance: $_attendanceId');
    debugPrint(
      '   Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
    );
    debugPrint(
      '   Accuracy: ${position.accuracy.toStringAsFixed(1)}m, Speed: ${position.speed.toStringAsFixed(1)}m/s',
    );

    _socket!.emit('location-update', payload);

    _lastPosition = position;
    _lastSentTime = DateTime.now();

    debugPrint('✅ Location update sent successfully');
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        _socket!.emit('heartbeat', {
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect from socket
  Future<void> disconnect() async {
    await stopTracking();
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('🔌 Socket disconnected and disposed');
  }

  /// Reconnect manually
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }

  /// Get connection status
  Map<String, dynamic> getStatus() {
    return {
      'connected': isConnected,
      'tracking': _isTracking,
      'employeeId': _employeeId,
      'attendanceId': _attendanceId,
      'lastUpdate': _lastSentTime?.toIso8601String(),
      'reconnectAttempts': _reconnectAttempts,
    };
  }
}
