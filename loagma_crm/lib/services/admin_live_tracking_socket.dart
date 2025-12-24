import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'user_service.dart';
import 'api_config.dart';

/// Admin WebSocket service for receiving real-time salesman locations
/// Handles live location updates and route tracking for admin dashboard
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

  // Configuration
  static const int _reconnectDelaySeconds = 5;
  static const int _maxReconnectAttempts = 10;

  // Data streams
  final _locationController = StreamController<LocationUpdate>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Current data
  final Map<String, SalesmanLocation> _salesmanLocations = {};
  final Map<String, List<LatLng>> _salesmanRoutes = {};

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
        print('📡 Admin live tracking already connected');
        return true;
      }

      final token = UserService.token;
      if (token == null || token.isEmpty) {
        print('❌ No authentication token available');
        return false;
      }

      // Build WebSocket URL
      final wsUrl = _buildWebSocketUrl(token);
      print('🔗 Admin connecting to WebSocket: $wsUrl');

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
      _connectionController.add(true);

      print('✅ Admin WebSocket connected successfully');
      return true;
    } catch (e) {
      print('❌ Admin WebSocket connection failed: $e');
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

    // WebSocket runs on the same server as HTTP, no port change needed
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

    print('🔌 Admin WebSocket disconnected');
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
          // Heartbeat response
          break;

        case 'ERROR':
          print('❌ Server error: ${message['message']}');
          break;

        default:
          print('📨 Unknown message type: ${message['type']}');
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  /// Handle real-time location update
  void _handleLocationUpdate(Map<String, dynamic> message) {
    try {
      final salesmanId = message['salesmanId'] as String;
      final lat = (message['lat'] as num).toDouble();
      final lng = (message['lng'] as num).toDouble();
      final timestamp = message['timestamp'] as int;

      // Update salesman location
      final location = SalesmanLocation(
        salesmanId: salesmanId,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      _salesmanLocations[salesmanId] = location;

      // Add to route
      final routePoint = LatLng(lat, lng);
      if (_salesmanRoutes.containsKey(salesmanId)) {
        _salesmanRoutes[salesmanId]!.add(routePoint);
      } else {
        _salesmanRoutes[salesmanId] = [routePoint];
      }

      // Emit location update
      _locationController.add(
        LocationUpdate(
          salesmanId: salesmanId,
          location: location,
          isInitial: false,
        ),
      );

      print(
        '📍 Location update for $salesmanId: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      );
    } catch (e) {
      print('❌ Error processing location update: $e');
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

        final location = SalesmanLocation(
          salesmanId: salesmanId,
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        );

        _salesmanLocations[salesmanId] = location;

        // Initialize route
        _salesmanRoutes[salesmanId] = [LatLng(lat, lng)];

        // Emit initial location
        _locationController.add(
          LocationUpdate(
            salesmanId: salesmanId,
            location: location,
            isInitial: true,
          ),
        );
      }

      print('📍 Received initial locations for ${locations.length} salesmen');
    } catch (e) {
      print('❌ Error processing initial locations: $e');
    }
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

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('❌ Admin WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('🔌 Admin WebSocket disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelaySeconds * _reconnectAttempts;

    print(
      '🔄 Scheduling admin reconnect attempt ${_reconnectAttempts}/${_maxReconnectAttempts} in ${delay}s',
    );

    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      print('🔄 Admin attempting to reconnect...');
      await connect();
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

  /// Get specific salesman location
  SalesmanLocation? getSalesmanLocation(String salesmanId) {
    return _salesmanLocations[salesmanId];
  }

  /// Get specific salesman route
  List<LatLng> getSalesmanRoute(String salesmanId) {
    return _salesmanRoutes[salesmanId] ?? [];
  }

  /// Clear route for salesman (when they disconnect/reconnect)
  void clearSalesmanRoute(String salesmanId) {
    _salesmanRoutes[salesmanId]?.clear();
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

/// Data classes for location updates
class SalesmanLocation {
  final String salesmanId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  SalesmanLocation({
    required this.salesmanId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

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
