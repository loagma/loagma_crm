import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import 'user_service.dart';
import 'location_service.dart';
import 'api_config.dart';

/// Production WebSocket service for real-time location tracking
/// Handles salesman GPS updates with auto-reconnect and distance filtering
class LiveLocationSocket {
  static LiveLocationSocket? _instance;
  static LiveLocationSocket get instance =>
      _instance ??= LiveLocationSocket._();
  LiveLocationSocket._();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;

  // Location tracking
  Timer? _locationTimer;
  Position? _lastSentPosition;
  bool _isConnected = false;
  bool _isTracking = false;

  // Configuration
  static const int _sendIntervalSeconds = 3; // Send every 3 seconds
  static const double _minimumDistanceMeters = 10.0; // Minimum movement
  static const int _reconnectDelaySeconds = 5;
  static const int _maxReconnectAttempts = 10;

  // State
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Getters
  bool get isConnected => _isConnected;
  bool get isTracking => _isTracking;

  /// Start live location tracking with WebSocket
  Future<bool> startTracking() async {
    try {
      if (_isTracking) {
        print('📍 Live location tracking already active');
        return true;
      }

      // Ensure location service is running
      if (!LocationService.instance.isTracking) {
        final started = await LocationService.instance.startLocationTracking();
        if (!started) {
          print('❌ Could not start location service');
          return false;
        }
      }

      // Connect to WebSocket
      final connected = await _connect();
      if (!connected) {
        print('❌ Could not connect to WebSocket');
        return false;
      }

      // Start location updates
      _startLocationUpdates();
      _isTracking = true;

      print('✅ Live location tracking started');
      return true;
    } catch (e) {
      print('❌ Error starting live location tracking: $e');
      return false;
    }
  }

  /// Stop live location tracking
  void stopTracking() {
    _isTracking = false;
    _stopLocationUpdates();
    _disconnect();
    print('🛑 Live location tracking stopped');
  }

  /// Connect to WebSocket server
  Future<bool> _connect() async {
    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) {
        print('❌ No authentication token available');
        return false;
      }

      // Build WebSocket URL
      final wsUrl = _buildWebSocketUrl(token);
      print('🔗 Connecting to WebSocket: $wsUrl');

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Set up message listener
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();

      print('✅ WebSocket connected successfully');
      return true;
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Build WebSocket URL with authentication
  String _buildWebSocketUrl(String token) {
    final baseUrl = ApiConfig.baseUrl;

    // Convert HTTP/HTTPS to WS/WSS
    String wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    // Get current user ID for salesman authentication
    final salesmanId = UserService.currentUserId ?? 'unknown';

    // Always use the same server and port for WebSocket
    final finalUrl =
        '$wsUrl/ws?token=$token&userType=salesman&employeeId=$salesmanId';
    print('🔗 Using WebSocket URL: $finalUrl');

    return finalUrl;
  }

  /// Disconnect from WebSocket
  void _disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageSubscription?.cancel();
    _channel?.sink.close();

    _channel = null;
    _messageSubscription = null;
    _isConnected = false;
  }

  /// Start sending location updates
  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(
      Duration(seconds: _sendIntervalSeconds),
      (timer) => _sendLocationUpdate(),
    );
  }

  /// Stop sending location updates
  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Send location update to server
  Future<void> _sendLocationUpdate() async {
    try {
      if (!_isConnected || !_isTracking) return;

      final currentPosition = LocationService.instance.currentPosition;
      if (currentPosition == null) {
        print('⚠️ No current position available');
        return;
      }

      // Check if movement is significant
      if (!_shouldSendLocation(currentPosition)) {
        return;
      }

      final salesmanId = UserService.currentUserId;
      if (salesmanId == null) {
        print('❌ No salesman ID available');
        return;
      }

      // Prepare location message
      final locationMessage = {
        'type': 'LOCATION',
        'salesmanId': salesmanId,
        'lat': currentPosition.latitude,
        'lng': currentPosition.longitude,
        'timestamp': currentPosition.timestamp.millisecondsSinceEpoch,
      };

      // Send to WebSocket
      _sendMessage(locationMessage);
      _lastSentPosition = currentPosition;

      print(
        '📍 Location sent: ${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      print('❌ Error sending location update: $e');
    }
  }

  /// Check if location should be sent (distance filtering)
  bool _shouldSendLocation(Position currentPosition) {
    // Always send first location
    if (_lastSentPosition == null) return true;

    // Calculate distance from last sent position
    final distance = Geolocator.distanceBetween(
      _lastSentPosition!.latitude,
      _lastSentPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Only send if moved significantly
    if (distance < _minimumDistanceMeters) {
      print(
        '📍 Skipping location - insufficient movement: ${distance.toStringAsFixed(1)}m',
      );
      return false;
    }

    return true;
  }

  /// Send message to WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('❌ Error sending WebSocket message: $e');
        _handleError(e);
      }
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());

      switch (message['type']) {
        case 'PONG':
          // Heartbeat response
          break;

        case 'ERROR':
          print('❌ Server error: ${message['message']}');
          break;

        default:
          print('📨 Received message: ${message['type']}');
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;

    if (_isTracking) {
      _scheduleReconnect();
    }
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('🔌 WebSocket disconnected');
    _isConnected = false;

    if (_isTracking) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached, stopping tracking');
      stopTracking();
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelaySeconds * _reconnectAttempts;

    print(
      '🔄 Scheduling reconnect attempt ${_reconnectAttempts}/${_maxReconnectAttempts} in ${delay}s',
    );

    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      if (_isTracking) {
        print('🔄 Attempting to reconnect...');
        await _connect();
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'PING'});
      }
    });
  }

  /// Get tracking status
  Map<String, dynamic> getStatus() {
    return {
      'isConnected': _isConnected,
      'isTracking': _isTracking,
      'reconnectAttempts': _reconnectAttempts,
      'lastSentPosition': _lastSentPosition != null
          ? {
              'latitude': _lastSentPosition!.latitude,
              'longitude': _lastSentPosition!.longitude,
              'timestamp': _lastSentPosition!.timestamp.toIso8601String(),
            }
          : null,
    };
  }

  /// Force send current location
  Future<void> forceSendLocation() async {
    final currentPosition = LocationService.instance.currentPosition;
    if (currentPosition != null) {
      _lastSentPosition = null; // Force send regardless of distance
      await _sendLocationUpdate();
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
