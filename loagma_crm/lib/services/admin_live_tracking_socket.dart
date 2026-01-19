import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'api_config.dart';

/// Admin WebSocket service for receiving real-time salesman locations
/// Handles live location updates, route tracking, and distance display
class AdminLiveTrackingSocket {
  static AdminLiveTrackingSocket? _instance;
  static AdminLiveTrackingSocket get instance =>
      _instance ??= AdminLiveTrackingSocket._();
  AdminLiveTrackingSocket._();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;

  // State
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatResponse;
  bool _isPendingReconnect = false;

  // Configuration
  static const int _reconnectDelaySeconds = 3;
  static const int _maxReconnectAttempts = 50;
  static const int _heartbeatIntervalSeconds = 25;

  // Data streams
  final _locationController = StreamController<LocationUpdate>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Current data - stores all salesman locations and routes
  final Map<String, SalesmanLocation> _salesmanLocations = {};
  final Map<String, List<LatLng>> _salesmanRoutes = {};
  final Map<String, double> _salesmanDistances = {};

  // Getters
  bool get isConnected => _isConnected;
  Stream<LocationUpdate> get locationStream => _locationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Map<String, SalesmanLocation> get salesmanLocations =>
      Map.unmodifiable(_salesmanLocations);
  Map<String, List<LatLng>> get salesmanRoutes =>
      Map.unmodifiable(_salesmanRoutes);

  /// Connect to WebSocket server for live tracking
  Future<bool> connect() async {
    try {
      if (_isConnected) {
        debugPrint('📡 Admin live tracking already connected');
        return true;
      }

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
      debugPrint('🔗 Admin connecting to WebSocket: $wsUrl');

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
      _connectionController.add(true);

      debugPrint('✅ Admin WebSocket connected successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Admin WebSocket connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Build WebSocket URL with authentication
  String _buildWebSocketUrl(String token) {
    final baseUrl = ApiConfig.baseUrl;
    final wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$wsUrl/ws?token=$token';
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageSubscription?.cancel();
    _channel?.sink.close();

    _channel = null;
    _messageSubscription = null;
    _isConnected = false;
    _connectionController.add(false);

    debugPrint('🔌 Admin WebSocket disconnected');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());

      switch (message['type']) {
        case 'LOCATION':
          _handleLocationUpdate(message);
          break;

        case 'INITIAL_LOCATIONS':
          _handleInitialLocations(message);
          break;

        case 'PONG':
          _lastHeartbeatResponse = DateTime.now();
          break;

        case 'ERROR':
          debugPrint('❌ Server error: ${message['message']}');
          break;

        default:
          debugPrint('📨 Unknown message type: ${message['type']}');
      }
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
    }
  }

  /// Handle real-time location update from salesman
  void _handleLocationUpdate(Map<String, dynamic> message) {
    try {
      final salesmanId = message['salesmanId'] as String;
      final lat = (message['lat'] as num).toDouble();
      final lng = (message['lng'] as num).toDouble();
      final timestamp = message['timestamp'] as int;
      final totalDistanceKm =
          (message['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
      final distanceFromLastKm =
          (message['distanceFromLastKm'] as num?)?.toDouble() ?? 0.0;
      final totalPoints = (message['totalPoints'] as int?) ?? 0;
      final isHomeLocation = message['isHomeLocation'] as bool? ?? false;
      final accuracy = (message['accuracy'] as num?)?.toDouble();
      final speed = (message['speed'] as num?)?.toDouble();

      // Create location object with all data
      final location = SalesmanLocation(
        salesmanId: salesmanId,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        totalDistanceKm: totalDistanceKm,
        distanceFromLastKm: distanceFromLastKm,
        totalPoints: totalPoints,
        isHomeLocation: isHomeLocation,
        accuracy: accuracy,
        speed: speed,
      );

      // Update stored location
      _salesmanLocations[salesmanId] = location;
      _salesmanDistances[salesmanId] = totalDistanceKm;

      // Add to route polyline
      final routePoint = LatLng(lat, lng);
      if (_salesmanRoutes.containsKey(salesmanId)) {
        // Only add if different from last point (avoid duplicates)
        final lastPoint = _salesmanRoutes[salesmanId]!.isNotEmpty
            ? _salesmanRoutes[salesmanId]!.last
            : null;
        if (lastPoint == null ||
            lastPoint.latitude != lat ||
            lastPoint.longitude != lng) {
          _salesmanRoutes[salesmanId]!.add(routePoint);
        }
      } else {
        _salesmanRoutes[salesmanId] = [routePoint];
      }

      // Emit location update to listeners
      _locationController.add(
        LocationUpdate(
          salesmanId: salesmanId,
          location: location,
          isInitial: false,
        ),
      );

      debugPrint(
<<<<<<< HEAD
        '📍 ${isHomeLocation ? "HOME " : ""}Location: $salesmanId | ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} | ${totalDistanceKm.toStringAsFixed(2)} km | $totalPoints pts',
=======
        '📍 ${isHomeLocation ? "HOME " : ""}Location: $salesmanId | ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} | ${totalDistanceKm.toStringAsFixed(2)} km | ${totalPoints} pts',
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      );
    } catch (e) {
      debugPrint('❌ Error processing location update: $e');
    }
  }

  /// Handle initial locations when connecting
  void _handleInitialLocations(Map<String, dynamic> message) {
    try {
      final locations = message['locations'] as Map<String, dynamic>;

      for (final entry in locations.entries) {
        final salesmanId = entry.key;
        final locationData = entry.value as Map<String, dynamic>;

        final lat = (locationData['lat'] as num).toDouble();
        final lng = (locationData['lng'] as num).toDouble();
        final timestamp = locationData['timestamp'] as int;
        final totalDistanceKm =
            (locationData['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
        final totalPoints = (locationData['totalPoints'] as int?) ?? 0;

        final location = SalesmanLocation(
          salesmanId: salesmanId,
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          totalDistanceKm: totalDistanceKm,
          totalPoints: totalPoints,
        );

        _salesmanLocations[salesmanId] = location;
        _salesmanDistances[salesmanId] = totalDistanceKm;
        _salesmanRoutes[salesmanId] = [LatLng(lat, lng)];

        _locationController.add(
          LocationUpdate(
            salesmanId: salesmanId,
            location: location,
            isInitial: true,
          ),
        );
      }

      debugPrint(
        '📍 Received initial locations for ${locations.length} salesmen',
      );
    } catch (e) {
      debugPrint('❌ Error processing initial locations: $e');
    }
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

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    debugPrint('❌ Admin WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    debugPrint('🔌 Admin WebSocket disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
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
    final delay = (_reconnectDelaySeconds * _reconnectAttempts).clamp(3, 30);

    debugPrint(
      '🔄 Admin reconnecting in ${delay}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      _isPendingReconnect = false;
      await connect();
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

          // Check heartbeat response
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

  /// Get specific salesman location
  SalesmanLocation? getSalesmanLocation(String salesmanId) {
    return _salesmanLocations[salesmanId];
  }

  /// Get specific salesman route
  List<LatLng> getSalesmanRoute(String salesmanId) {
    return _salesmanRoutes[salesmanId] ?? [];
  }

  /// Get salesman total distance
  double getSalesmanDistance(String salesmanId) {
    return _salesmanDistances[salesmanId] ?? 0.0;
  }

  /// Clear route for salesman
  void clearSalesmanRoute(String salesmanId) {
    _salesmanRoutes[salesmanId]?.clear();
  }

  /// Clear all data (when refreshing)
  void clearAllData() {
    _salesmanLocations.clear();
    _salesmanRoutes.clear();
    _salesmanDistances.clear();
  }

  /// Get connection status
  Map<String, dynamic> getStatus() {
    return {
      'isConnected': _isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'trackedSalesmen': _salesmanLocations.length,
      'totalRoutePoints': _salesmanRoutes.values.fold<int>(
        0,
        (sum, route) => sum + route.length,
      ),
    };
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _locationController.close();
    _connectionController.close();
  }
}

/// Salesman location data with distance tracking
class SalesmanLocation {
  final String salesmanId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double totalDistanceKm;
  final double distanceFromLastKm;
  final int totalPoints;
  final bool isHomeLocation;
  final double? accuracy;
  final double? speed;

  SalesmanLocation({
    required this.salesmanId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.totalDistanceKm = 0.0,
    this.distanceFromLastKm = 0.0,
    this.totalPoints = 0,
    this.isHomeLocation = false,
    this.accuracy,
    this.speed,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Location update event
class LocationUpdate {
  final String salesmanId;
  final SalesmanLocation location;
  final bool isInitial;

  LocationUpdate({
    required this.salesmanId,
    required this.location,
    required this.isInitial,
  });
}
