import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'api_config.dart';
import 'location_service.dart';
import 'network_service.dart';
import 'user_service.dart';

class _PendingTrackingPoint {
  _PendingTrackingPoint({
    required this.clientPointId,
    required this.employeeId,
    required this.employeeName,
    required this.attendanceId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.recordedAt,
  });

  final String clientPointId;
  final String employeeId;
  final String employeeName;
  final String attendanceId;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final DateTime recordedAt;

  Map<String, dynamic> toPayload() {
    final recordedAtUtc = recordedAt.toUtc().toIso8601String();
    return {
      'clientPointId': clientPointId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'attendanceId': attendanceId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'recordedAt': recordedAtUtc,
      'timestamp': recordedAtUtc,
    };
  }
}

/// Socket.IO based tracking service with REST fallback queue.
class SocketTrackingService {
  static final SocketTrackingService instance =
      SocketTrackingService._internal();
  factory SocketTrackingService() => instance;
  SocketTrackingService._internal();

  IO.Socket? _socket;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _heartbeatTimer;
  Timer? _flushTimer;
  Timer? _emitTimer;

  String? _employeeId;
  String? _employeeName;
  String? _attendanceId;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastSentTime;
  DateTime? _lastAckTime;
  int _pointSequence = 0;
  bool _isFlushing = false;
  int _emittedCount = 0;
  int _ackedCount = 0;
  int _flushedCount = 0;

  final LinkedHashMap<String, _PendingTrackingPoint> _pendingById =
      LinkedHashMap<String, _PendingTrackingPoint>();

  static const Duration _sendInterval = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _flushInterval = Duration(seconds: 12);

  int _reconnectAttempts = 0;
  bool _isConnecting = false;

  bool get isTracking => _isTracking;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) {
      return;
    }

    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      _socket = IO.io(
        ApiConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
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
      _isConnecting = false;
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _isConnecting = false;
      _reconnectAttempts = 0;
      _startHeartbeat();
      _startFlushTimer();
      _emitSessionStartIfReady();
      unawaited(_flushPendingPointsToBatch());
    });

    _socket!.onDisconnect((reason) {
      debugPrint('🔌 Socket disconnected: $reason');
      _stopHeartbeat();
      _startFlushTimer();
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('❌ Socket connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
    });

    _socket!.onReconnect((attempt) {
      _reconnectAttempts = attempt as int;
      _emitSessionStartIfReady();
      unawaited(_flushPendingPointsToBatch());
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ Socket reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint(
        '❌ Socket reconnection failed after $_maxReconnectAttempts attempts',
      );
    });

    _socket!.on('location-ack', (data) {
      if (data is! Map) return;
      final clientPointId = data['clientPointId']?.toString();
      if (clientPointId != null && clientPointId.isNotEmpty) {
        _pendingById.remove(clientPointId);
        _ackedCount += 1;
        _lastAckTime = DateTime.now();
      }
    });

    _socket!.on('error', (data) {
      debugPrint('❌ Server error: $data');
    });
  }

  Future<void> startTracking({
    required String employeeId,
    required String attendanceId,
    String? employeeName,
  }) async {
    if (_isTracking) {
      return;
    }

    _employeeId = employeeId;
    _attendanceId = attendanceId;
    _employeeName = (employeeName == null || employeeName.isEmpty)
        ? employeeId
        : employeeName;

    if (!isConnected) {
      await connect();
    }

    final locationStarted = await LocationService.instance.startLocationTracking();
    if (!locationStarted) {
      throw Exception('Failed to start location service');
    }

    _locationSubscription = LocationService.instance.locationStream.listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
    );

    _isTracking = true;
    _emitSessionStartIfReady();
    _startEmitTimer();
    _startFlushTimer();
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _locationSubscription?.cancel();
    _locationSubscription = null;
    LocationService.instance.stopLocationTracking();

    _emitSessionEndIfReady();
    _isTracking = false;
    _lastPosition = null;
    _lastSentTime = null;

    _stopEmitTimer();
    _stopHeartbeat();
    _stopFlushTimer();
  }

  void _handleLocationUpdate(Position position) {
    if (!_isTracking || _employeeId == null || _attendanceId == null) {
      return;
    }

    _lastPosition = position;
    if (_lastSentTime == null) {
      _emitCurrentPoint();
    }
  }

  void _emitCurrentPoint() {
    if (!_isTracking || _employeeId == null || _attendanceId == null) {
      return;
    }
    final position = _lastPosition;
    if (position == null) {
      return;
    }
    final now = DateTime.now();
    final point = _buildPendingPoint(position, now);
    _pendingById[point.clientPointId] = point;
    _emittedCount += 1;
    _lastPosition = position;
    _lastSentTime = now;
    _sendPointOverSocket(point);
  }

  _PendingTrackingPoint _buildPendingPoint(Position position, DateTime now) {
    _pointSequence += 1;
    final employeeId = _employeeId!;
    final attendanceId = _attendanceId!;
    final employeeName = _employeeName ?? employeeId;

    return _PendingTrackingPoint(
      clientPointId:
          '$employeeId-$attendanceId-${now.microsecondsSinceEpoch}-$_pointSequence',
      employeeId: employeeId,
      employeeName: employeeName,
      attendanceId: attendanceId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      recordedAt: now,
    );
  }

  void _sendPointOverSocket(_PendingTrackingPoint point) {
    if (!isConnected || _socket == null) {
      return;
    }
    _socket!.emit('location-update', point.toPayload());
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!_isTracking) return;

      if (isConnected) {
        _socket!.emit('heartbeat', {
          'employeeId': _employeeId,
          'attendanceId': _attendanceId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      }

      unawaited(_flushPendingPointsToBatch());
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      unawaited(_flushPendingPointsToBatch());
    });
  }

  void _stopFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _startEmitTimer() {
    _emitTimer?.cancel();
    _emitTimer = Timer.periodic(_sendInterval, (_) {
      _emitCurrentPoint();
    });
  }

  void _stopEmitTimer() {
    _emitTimer?.cancel();
    _emitTimer = null;
  }

  Future<void> _flushPendingPointsToBatch() async {
    if (_isFlushing || _pendingById.isEmpty) {
      return;
    }
    if (_employeeId == null || _attendanceId == null) {
      return;
    }

    final hasNetwork = await NetworkService.checkConnectivity();
    if (!hasNetwork) {
      return;
    }

    _isFlushing = true;
    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) return;

      final snapshot = List<_PendingTrackingPoint>.from(_pendingById.values);
      final payload = {
        'points': snapshot.map((p) => p.toPayload()).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tracking/points/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final body = jsonDecode(response.body);
      final accepted = body['acceptedClientPointIds'];
      if (accepted is List) {
        for (final id in accepted) {
          final removed = _pendingById.remove(id.toString());
          if (removed != null) {
            _flushedCount += 1;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to flush pending tracking points: $e');
    } finally {
      _isFlushing = false;
    }
  }

  void _emitSessionStartIfReady() {
    if (!isConnected || _employeeId == null || _attendanceId == null) {
      return;
    }
    _socket!.emit('session-start', {
      'employeeId': _employeeId,
      'attendanceId': _attendanceId,
      'employeeName': _employeeName ?? _employeeId,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _emitSessionEndIfReady() {
    if (_socket == null || _employeeId == null || _attendanceId == null) {
      return;
    }
    _socket!.emit('session-end', {
      'employeeId': _employeeId,
      'attendanceId': _attendanceId,
      'endedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> disconnect() async {
    await stopTracking();
    await _flushPendingPointsToBatch();
    _pendingById.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _employeeId = null;
    _employeeName = null;
    _attendanceId = null;
  }

  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }

  Map<String, dynamic> getStatus() {
    return {
      'connected': isConnected,
      'tracking': _isTracking,
      'employeeId': _employeeId,
      'attendanceId': _attendanceId,
      'lastEmitAt': _lastSentTime?.toIso8601String(),
      'lastAckAt': _lastAckTime?.toIso8601String(),
      'reconnectAttempts': _reconnectAttempts,
      'queued': _pendingById.length,
      'emitted': _emittedCount,
      'acked': _ackedCount,
      'flushed': _flushedCount,
    };
  }
}
