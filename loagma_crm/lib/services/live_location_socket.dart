import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'location_service.dart';
import 'api_config.dart';

/// Production WebSocket service for real-time location tracking
/// Sends location updates every 10 seconds with background support
/// Maintains persistent connection until punch-out
class LiveLocationSocket {
  static LiveLocationSocket? _instance;
  static LiveLocationSocket get instance =>
      _instance ??= LiveLocationSocket._();
  LiveLocationSocket._();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  StreamSubscription<Position>? _locationStreamSubscription;

  // Location tracking
  Timer? _locationTimer;
  Position? _lastSentPosition;
  bool _isConnected = false;
  bool _isTracking = false;
  bool _isFirstLocation = true;

  // Distance tracking
  double _totalDistanceKm = 0.0;
  List<Position> _routePoints = [];

  // Configuration - optimized for accuracy and battery
  static const int _sendIntervalSeconds = 10; // Send every 10 seconds
  static const double _minimumDistanceMeters = 5.0; // 5 meters minimum movement
  static const int _reconnectDelaySeconds = 3;
  static const int _maxReconnectAttempts = 50; // More attempts for reliability
  static const int _heartbeatIntervalSeconds = 25;

  // State
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatResponse;
  bool _isPendingReconnect = false;

  // Callbacks for UI updates
  Function(double totalDistanceKm, int totalPoints)? onDistanceUpdate;
  Function(bool isConnected)? onConnectionStatusChange;

  // Getters
  bool get isConnected => _isConnected;
  bool get isTracking => _isTracking;
  double get totalDistanceKm => _totalDistanceKm;
  int get totalPoints => _routePoints.length;

  /// Start live location tracking with WebSocket
  Future<bool> startTracking() async {
    try {
      if (_isTracking) {
        debugPrint('📍 Live location tracking already active');
        return true;
      }

      // Reset state for new tracking session
      _isFirstLocation = true;
      _totalDistanceKm = 0.0;
      _routePoints.clear();
      _reconnectAttempts = 0;
      _isPendingReconnect = false;

      // Request background location permission
      final hasPermission = await LocationService.instance
          .requestLocationPermissions(requestAlways: true);
      if (!hasPermission) {
        debugPrint('❌ Location permission not granted');
        return false;
      }

      // Start location service with high accuracy
      if (!LocationService.instance.isTracking) {
        final started = await LocationService.instance.startLocationTracking();
        if (!started) {
          debugPrint('❌ Could not start location service');
          return false;
        }
      }

      // Connect to WebSocket
      final connected = await _connect();
      if (!connected) {
        debugPrint('❌ Could not connect to WebSocket');
        // Continue anyway - will retry connection
      }

      // Subscribe to location stream for real-time updates
      _subscribeToLocationStream();

      // Start periodic location sending (backup for stream)
      _startLocationTimer();

      _isTracking = true;
      debugPrint('✅ Live location tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting live location tracking: $e');
      return false;
    }
  }

  /// Subscribe to location stream for immediate updates
  void _subscribeToLocationStream() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = LocationService.instance.locationStream
        .listen(
          (Position position) {
            _handleNewPosition(position);
          },
          onError: (error) {
            debugPrint('❌ Location stream error: $error');
          },
        );
  }

  /// Handle new position from location stream
  void _handleNewPosition(Position position) {
    if (!_isTracking) return;

    // Calculate distance from last position
    double distanceFromLast = 0;
    if (_lastSentPosition != null) {
      distanceFromLast = Geolocator.distanceBetween(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Always send first location (home) or if moved significantly
    final shouldSend =
        _isFirstLocation ||
        _lastSentPosition == null ||
        distanceFromLast >= _minimumDistanceMeters;

    if (shouldSend) {
      _sendLocationToServer(position, distanceFromLast);
    }
  }

  /// Send location to server via WebSocket
  void _sendLocationToServer(Position position, double distanceFromLast) {
    if (!_isTracking) return;

    final salesmanId = UserService.currentUserId;
    if (salesmanId == null) {
      debugPrint('❌ No salesman ID available');
      return;
    }

    // Update distance tracking
    if (_lastSentPosition != null && distanceFromLast > 0) {
      _totalDistanceKm += distanceFromLast / 1000;
    }

    // Add to route points
    _routePoints.add(position);

    // Prepare location message
    final locationMessage = {
      'type': 'LOCATION',
      'salesmanId': salesmanId,
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': position.timestamp.millisecondsSinceEpoch,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'isHomeLocation': _isFirstLocation,
      'totalDistanceKm': _totalDistanceKm,
      'totalPoints': _routePoints.length,
    };

    // Send via WebSocket if connected
    if (_isConnected) {
      _sendMessage(locationMessage);
    }

    // Update state
    _lastSentPosition = position;

    final homeTag = _isFirstLocation ? ' (HOME)' : '';
    debugPrint(
      '📍 Location sent$homeTag: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} | Total: ${_totalDistanceKm.toStringAsFixed(2)} km | Points: ${_routePoints.length}',
    );

    // Notify UI
    onDistanceUpdate?.call(_totalDistanceKm, _routePoints.length);

    // Mark first location as sent
    if (_isFirstLocation) {
      _isFirstLocation = false;
    }
  }

  /// Start periodic location timer (backup mechanism)
  void _startLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: _sendIntervalSeconds),
      (timer) => _sendPeriodicLocation(),
    );
  }

  /// Send periodic location update
  Future<void> _sendPeriodicLocation() async {
    if (!_isTracking) return;

    // Ensure WebSocket is connected
    if (!_isConnected && !_isPendingReconnect) {
      _scheduleReconnect();
    }

    // Get current position and send
    final position = LocationService.instance.currentPosition;
    if (position != null) {
      double distanceFromLast = 0;
      if (_lastSentPosition != null) {
        distanceFromLast = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }

      // Send if moved or if it's been a while since last send
      if (_lastSentPosition == null ||
          distanceFromLast >= _minimumDistanceMeters) {
        _sendLocationToServer(position, distanceFromLast);
      }
    }
  }

  /// Stop live location tracking
  void stopTracking() {
    _isTracking = false;
    _isFirstLocation = true;
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    _disconnect();

    debugPrint(
      '🛑 Live location tracking stopped | Total distance: ${_totalDistanceKm.toStringAsFixed(2)} km | Points: ${_routePoints.length}',
    );
  }

  /// Connect to WebSocket server
  Future<bool> _connect() async {
    try {
      if (_isConnected) return true;

      final token = UserService.token;
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token available');
        return false;
      }

      if (!UserService.hasValidAuth) {
        debugPrint('❌ Invalid authentication');
        return false;
      }

      final wsUrl = _buildWebSocketUrl(token);
      debugPrint('🔗 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel == null) {
        debugPrint('❌ Connection closed during handshake');
        return false;
      }

      _isConnected = true;
      _reconnectAttempts = 0;
      _isPendingReconnect = false;
      _startHeartbeat();
      onConnectionStatusChange?.call(true);

      debugPrint('✅ WebSocket connected successfully');
      return true;
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Build WebSocket URL with authentication
  String _buildWebSocketUrl(String token) {
    final baseUrl = ApiConfig.baseUrl;
    String wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$wsUrl/ws?token=$token';
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
    onConnectionStatusChange?.call(false);
  }

  /// Send message to WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        debugPrint('❌ Error sending WebSocket message: $e');
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
          _lastHeartbeatResponse = DateTime.now();
          break;

        case 'ACK':
          // Location acknowledged by server
          break;

        case 'ERROR':
          debugPrint('❌ Server error: ${message['message']}');
          break;

        default:
          debugPrint('📨 Received: ${message['type']}');
      }
    } catch (e) {
      debugPrint('❌ Error handling message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    onConnectionStatusChange?.call(false);

    if (_isTracking) {
      _scheduleReconnect();
    }
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    debugPrint('🔌 WebSocket disconnected');
    _isConnected = false;
    onConnectionStatusChange?.call(false);

    if (_isTracking) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_isPendingReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      return;
    }

    _isPendingReconnect = true;
    _reconnectAttempts++;

    // Exponential backoff with max 30 seconds
    final delay = (_reconnectDelaySeconds * _reconnectAttempts).clamp(3, 30);

    debugPrint(
      '🔄 Reconnecting in ${delay}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      _isPendingReconnect = false;
      if (_isTracking) {
        await _connect();
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatIntervalSeconds),
      (timer) {
        if (_isConnected) {
          _sendMessage({'type': 'PING'});

          // Check if server responded to last heartbeat
          if (_lastHeartbeatResponse != null) {
            final timeSinceResponse = DateTime.now().difference(
              _lastHeartbeatResponse!,
            );
            if (timeSinceResponse.inSeconds > _heartbeatIntervalSeconds * 2) {
              debugPrint('⚠️ No heartbeat response, reconnecting...');
              _handleDisconnection();
            }
          }
        }
      },
    );
  }

  /// Get tracking status
  Map<String, dynamic> getStatus() {
    return {
      'isConnected': _isConnected,
      'isTracking': _isTracking,
      'reconnectAttempts': _reconnectAttempts,
      'totalDistanceKm': _totalDistanceKm,
      'totalPoints': _routePoints.length,
      'lastPosition': _lastSentPosition != null
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
    final position = LocationService.instance.currentPosition;
    if (position != null) {
      _sendLocationToServer(position, 0);
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
