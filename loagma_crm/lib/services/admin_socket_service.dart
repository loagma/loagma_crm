import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_config.dart';
import 'user_service.dart';

/// Global admin socket service that stays connected as long as admin is logged in.
/// This allows live tracking updates to be received even when not on the live tracking screen.
class AdminSocketService {
  static final AdminSocketService _instance = AdminSocketService._internal();
  static AdminSocketService get instance => _instance;
  factory AdminSocketService() => _instance;
  AdminSocketService._internal();

  IO.Socket? _socket;
  bool _isConnecting = false;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Track active listeners to enable auto-disconnect when not in use
  int _activeListeners = 0;
  Timer? _inactivityTimer;
  static const Duration _inactivityTimeout = Duration(minutes: 5);

  // Stream controllers for broadcasting updates to UI
  final StreamController<Map<String, dynamic>> _locationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _employeeConnectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _employeeDisconnectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<String>> _activeEmployeesController =
      StreamController<List<String>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Public streams for UI to listen to
  Stream<Map<String, dynamic>> get locationUpdates =>
      _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get employeeConnected =>
      _employeeConnectedController.stream;
  Stream<Map<String, dynamic>> get employeeDisconnected =>
      _employeeDisconnectedController.stream;
  Stream<List<String>> get activeEmployees => _activeEmployeesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  int get activeListeners => _activeListeners;

  /// Increment listener count and connect if needed (lazy connection)
  void addListener() {
    _activeListeners++;
    debugPrint('🎧 AdminSocketService: Listener added ($_activeListeners active)');
    _inactivityTimer?.cancel();
    ensureConnected();
  }

  /// Decrement listener count and disconnect after timeout if no listeners
  void removeListener() {
    if (_activeListeners > 0) _activeListeners--;
    debugPrint('🎧 AdminSocketService: Listener removed ($_activeListeners active)');
    
    if (_activeListeners == 0) {
      // Start inactivity timer - disconnect if no listeners for 5 minutes
      _inactivityTimer?.cancel();
      _inactivityTimer = Timer(_inactivityTimeout, () {
        if (_activeListeners == 0) {
          debugPrint('⏱️ AdminSocketService: Auto-disconnect due to inactivity');
          disconnect();
        }
      });
    }
  }

  /// Connect to socket server (lazy connection - called when needed)
  Future<void> connect() async {
    final role = UserService.currentRole?.toLowerCase();
    if (role != 'admin' && role != 'manager') {
      debugPrint('🔌 AdminSocketService: Not admin/manager, skipping connect');
      return;
    }

    if (_socket?.connected == true) {
      debugPrint('🔌 AdminSocketService: Already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('🔌 AdminSocketService: Connection in progress');
      return;
    }

    _isConnecting = true;

    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) {
        debugPrint('❌ AdminSocketService: No token available');
        _isConnecting = false;
        return;
      }

      final socketUrl = ApiConfig.baseUrl;
      debugPrint('🔌 AdminSocketService connecting to: $socketUrl');

      _socket?.dispose();
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(3000)
            .setTimeout(15000)
            .build(),
      );

      _setupListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ AdminSocketService connection error: $e');
      _isConnecting = false;
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }

  void _setupListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ AdminSocketService connected');
      _isConnecting = false;
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 AdminSocketService disconnected');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ AdminSocketService connect error: $error');
      _isConnecting = false;
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.on('location-update', (data) {
      if (data is Map<String, dynamic>) {
        _locationUpdateController.add(data);
      } else if (data is Map) {
        _locationUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('employee-connected', (data) {
      if (data is Map<String, dynamic>) {
        _employeeConnectedController.add(data);
      } else if (data is Map) {
        _employeeConnectedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('employee-disconnected', (data) {
      if (data is Map<String, dynamic>) {
        _employeeDisconnectedController.add(data);
      } else if (data is Map) {
        _employeeDisconnectedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('employee-session-started', (data) {
      if (data is Map<String, dynamic>) {
        _employeeConnectedController.add(data);
      } else if (data is Map) {
        _employeeConnectedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('employee-session-ended', (data) {
      if (data is Map<String, dynamic>) {
        _employeeDisconnectedController.add(data);
      } else if (data is Map) {
        _employeeDisconnectedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('active-employees', (data) {
      if (data is List) {
        _activeEmployeesController.add(List<String>.from(data));
      }
    });
  }

  /// Disconnect from socket. Called on logout or inactivity.
  void disconnect() {
    debugPrint('🔌 AdminSocketService disconnecting');
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
    _isConnected = false;
    _activeListeners = 0;
    _connectionStatusController.add(false);
  }

  /// Check if we should reconnect
  void ensureConnected() {
    final role = UserService.currentRole?.toLowerCase();
    if ((role == 'admin' || role == 'manager') && !_isConnected && !_isConnecting) {
      connect();
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    disconnect();
    _locationUpdateController.close();
    _employeeConnectedController.close();
    _employeeDisconnectedController.close();
    _activeEmployeesController.close();
    _connectionStatusController.close();
  }
}
