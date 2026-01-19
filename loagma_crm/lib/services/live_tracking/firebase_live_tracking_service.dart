import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:collection';
import '../../models/live_tracking/location_models.dart';
import 'database_service.dart';
import 'realtime_database_service.dart';
import 'location_service.dart';

/// Service class for handling Firebase real-time location tracking
/// Integrates with both Firestore and Realtime Database services
/// Includes offline data queuing and enhanced error handling
class FirebaseLiveTrackingService {
  static FirebaseLiveTrackingService? _instance;
  static FirebaseLiveTrackingService get instance =>
      _instance ??= FirebaseLiveTrackingService._();
  FirebaseLiveTrackingService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService.instance;
  final RealtimeDatabaseService _realtimeService =
      RealtimeDatabaseService.instance;
  final LocationService _locationService = LocationService.instance;

  // Tracking state
  bool _isTracking = false;
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // Offline data queue
  final Queue<LocationData> _offlineQueue = Queue<LocationData>();
  final Queue<LocationHistory> _historyQueue = Queue<LocationHistory>();
  bool _isOnline = true;
  Timer? _syncTimer;

  // Configuration
  Duration _updateInterval = const Duration(seconds: 30);
  int _maxOfflineQueueSize = 1000;
  Duration _syncRetryInterval = const Duration(minutes: 1);
  bool _storeHistoryEnabled = true;
  int _historyStorageInterval = 5; // Store every 5th location update

  // Counters for history storage
  int _locationUpdateCount = 0;

  /// Initialize the live tracking service
  Future<void> initialize() async {
    try {
      await _databaseService.initialize();
      await _realtimeService.initialize();

      // Set up connection monitoring
      _setupConnectionMonitoring();

      // Start periodic sync timer
      _startSyncTimer();

      developer.log(
        'Firebase Live Tracking Service initialized',
        name: 'FirebaseLiveTrackingService',
      );
    } catch (e) {
      throw LiveTrackingException(
        'Failed to initialize live tracking service: ${e.toString()}',
      );
    }
  }

  /// Set up connection monitoring
  void _setupConnectionMonitoring() {
    _connectionSubscription = _realtimeService.getConnectionStatus().listen(
      (isConnected) {
        _isOnline = isConnected;
        developer.log(
          'Connection status changed: ${isConnected ? "online" : "offline"}',
          name: 'FirebaseLiveTrackingService',
        );

        if (isConnected && _offlineQueue.isNotEmpty) {
          _syncOfflineData();
        }
      },
      onError: (error) {
        developer.log(
          'Connection monitoring error: $error',
          name: 'FirebaseLiveTrackingService',
        );
      },
    );
  }

  /// Start periodic sync timer for offline data
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncRetryInterval, (_) {
      if (_isOnline && (_offlineQueue.isNotEmpty || _historyQueue.isNotEmpty)) {
        _syncOfflineData();
      }
    });
  }

  /// Start live location tracking with enhanced integration
  Future<void> startTracking({
    Duration updateInterval = const Duration(seconds: 30),
    bool enableHistoryStorage = true,
    int historyStorageInterval = 5,
  }) async {
    if (_isTracking) return;

    final user = _auth.currentUser;
    if (user == null) {
      throw LiveTrackingException('User not authenticated');
    }

    try {
      // Update configuration
      _updateInterval = updateInterval;
      _storeHistoryEnabled = enableHistoryStorage;
      _historyStorageInterval = historyStorageInterval;

      // Start location tracking using the enhanced location service
      final trackingStarted = await _locationService.startLocationTracking(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeInterval: updateInterval,
      );

      if (!trackingStarted) {
        throw LiveTrackingException('Failed to start location tracking');
      }

      // Set user as active in Firebase
      await _realtimeService.setUserActive(user.uid);

      // Subscribe to location updates
      _positionSubscription = _locationService.locationStream.listen(
        (Position position) => _handlePositionUpdate(position),
        onError: (error) => _handleTrackingError(error),
      );

      // Set up periodic updates as backup
      _trackingTimer = Timer.periodic(updateInterval, (_) async {
        try {
          final position = await _locationService.getCurrentLocation();
          if (position != null) {
            await _handlePositionUpdate(position);
          }
        } catch (e) {
          _handleTrackingError(e);
        }
      });

      _isTracking = true;
      developer.log(
        'Live tracking started successfully',
        name: 'FirebaseLiveTrackingService',
      );
    } catch (e) {
      throw LiveTrackingException('Failed to start tracking: ${e.toString()}');
    }
  }

  /// Stop live location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Stop location service tracking
      await _locationService.stopLocationTracking();

      // Cancel subscriptions and timers
      await _positionSubscription?.cancel();
      _trackingTimer?.cancel();

      _positionSubscription = null;
      _trackingTimer = null;
      _isTracking = false;

      // Set user as inactive
      await _realtimeService.setUserInactive(user.uid);

      // Sync any remaining offline data
      if (_offlineQueue.isNotEmpty || _historyQueue.isNotEmpty) {
        await _syncOfflineData();
      }

      developer.log(
        'Live tracking stopped successfully',
        name: 'FirebaseLiveTrackingService',
      );
    } catch (e) {
      throw LiveTrackingException('Failed to stop tracking: ${e.toString()}');
    }
  }

  /// Handle position update with offline queuing
  Future<void> _handlePositionUpdate(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      _locationUpdateCount++;

      // Create live location object
      final liveLocation = LiveLocation(
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: now,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        isActive: true,
        lastUpdate: now,
      );

      // Try to update live location in Realtime Database
      if (_isOnline) {
        try {
          await _realtimeService.updateLiveLocation(liveLocation);
          developer.log(
            'Live location updated successfully',
            name: 'FirebaseLiveTrackingService',
          );
        } catch (e) {
          developer.log(
            'Failed to update live location, queuing for offline sync: $e',
            name: 'FirebaseLiveTrackingService',
          );
          _queueLocationData(liveLocation);
        }
      } else {
        _queueLocationData(liveLocation);
      }

      // Store in location history if enabled and interval reached
      if (_storeHistoryEnabled && _shouldStoreInHistory()) {
        final locationHistory = LocationHistory(
          id: '', // Will be auto-generated by Firestore
          userId: user.uid,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: now,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
        );

        if (_isOnline) {
          try {
            await _databaseService.storeLocationHistory(locationHistory);
            developer.log(
              'Location history stored successfully',
              name: 'FirebaseLiveTrackingService',
            );
          } catch (e) {
            developer.log(
              'Failed to store location history, queuing for offline sync: $e',
              name: 'FirebaseLiveTrackingService',
            );
            _queueHistoryData(locationHistory);
          }
        } else {
          _queueHistoryData(locationHistory);
        }
      }
    } catch (e) {
      _handleTrackingError(e);
    }
  }

  /// Determine if position should be stored in history
  bool _shouldStoreInHistory() {
    return _locationUpdateCount % _historyStorageInterval == 0;
  }

  /// Queue location data for offline sync
  void _queueLocationData(LocationData locationData) {
    if (_offlineQueue.length >= _maxOfflineQueueSize) {
      // Remove oldest item to make space
      _offlineQueue.removeFirst();
      developer.log(
        'Offline queue full, removed oldest location data',
        name: 'FirebaseLiveTrackingService',
      );
    }

    _offlineQueue.add(locationData);
    developer.log(
      'Location data queued for offline sync. Queue size: ${_offlineQueue.length}',
      name: 'FirebaseLiveTrackingService',
    );
  }

  /// Queue history data for offline sync
  void _queueHistoryData(LocationHistory historyData) {
    if (_historyQueue.length >= _maxOfflineQueueSize) {
      // Remove oldest item to make space
      _historyQueue.removeFirst();
      developer.log(
        'History queue full, removed oldest history data',
        name: 'FirebaseLiveTrackingService',
      );
    }

    _historyQueue.add(historyData);
    developer.log(
      'History data queued for offline sync. Queue size: ${_historyQueue.length}',
      name: 'FirebaseLiveTrackingService',
    );
  }

  /// Sync offline data when connection is restored
  Future<void> _syncOfflineData() async {
    if (!_isOnline) return;

    developer.log(
      'Starting offline data sync. Location queue: ${_offlineQueue.length}, History queue: ${_historyQueue.length}',
      name: 'FirebaseLiveTrackingService',
    );

    // Sync live location data
    final locationErrors = <String>[];
    while (_offlineQueue.isNotEmpty) {
      final locationData = _offlineQueue.removeFirst();

      try {
        if (locationData is LiveLocation) {
          await _realtimeService.updateLiveLocation(locationData);
        }
      } catch (e) {
        locationErrors.add(e.toString());
        // Re-queue if it's a temporary error
        if (locationErrors.length < 3) {
          _offlineQueue.addFirst(locationData);
        }
        break; // Stop syncing on error to avoid overwhelming the service
      }
    }

    // Sync history data
    final historyErrors = <String>[];
    while (_historyQueue.isNotEmpty) {
      final historyData = _historyQueue.removeFirst();

      try {
        await _databaseService.storeLocationHistory(historyData);
      } catch (e) {
        historyErrors.add(e.toString());
        // Re-queue if it's a temporary error
        if (historyErrors.length < 3) {
          _historyQueue.addFirst(historyData);
        }
        break; // Stop syncing on error
      }
    }

    if (locationErrors.isEmpty && historyErrors.isEmpty) {
      developer.log(
        'Offline data sync completed successfully',
        name: 'FirebaseLiveTrackingService',
      );
    } else {
      developer.log(
        'Offline data sync completed with errors. Location errors: ${locationErrors.length}, History errors: ${historyErrors.length}',
        name: 'FirebaseLiveTrackingService',
      );
    }
  }

  /// Handle tracking errors
  void _handleTrackingError(dynamic error) {
    developer.log(
      'Tracking error: $error',
      name: 'FirebaseLiveTrackingService',
    );

    // Optionally implement error recovery strategies
    // For example, restart tracking after a delay
  }

  /// Send manual location update
  Future<void> updateLiveLocation(Position position) async {
    await _handlePositionUpdate(position);
  }

  /// Store location in history manually
  Future<void> storeLocationHistory(Position position) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw LiveTrackingException('User not authenticated');
    }

    try {
      final locationHistory = LocationHistory(
        id: '', // Will be auto-generated by Firestore
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
      );

      if (_isOnline) {
        await _databaseService.storeLocationHistory(locationHistory);
      } else {
        _queueHistoryData(locationHistory);
      }
    } catch (e) {
      throw LiveTrackingException(
        'Failed to store location history: ${e.toString()}',
      );
    }
  }

  /// Listen to live location updates for a specific user
  Stream<LiveLocation?> listenToUserLocation(String userId) {
    return _realtimeService.listenToUserLocation(userId);
  }

  /// Listen to all active live locations (admin feature)
  Stream<List<LiveLocation>> listenToAllLiveLocations() {
    return _realtimeService.listenToAllLiveLocations();
  }

  /// Listen to active salesmen locations only
  Stream<List<LiveLocation>> listenToActiveSalesmenLocations() {
    return _realtimeService.listenToActiveSalesmenLocations();
  }

  /// Get current live location for a user
  Future<LiveLocation?> getCurrentLiveLocation(String userId) async {
    return await _realtimeService.getLiveLocation(userId);
  }

  /// Get all active live locations
  Future<List<LiveLocation>> getAllActiveLiveLocations() async {
    return await _realtimeService.getAllActiveLiveLocations();
  }

  /// Set user as inactive (stop tracking)
  Future<void> setUserInactive() async {
    await stopTracking();
  }

  /// Set user as active (start tracking)
  Future<void> setUserActive() async {
    await startTracking();
  }

  /// Get location history for a user
  Future<List<LocationHistory>> getLocationHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return await _databaseService.getLocationHistory(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get daily distance records
  Future<List<Map<String, dynamic>>> getDailyDistance({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _databaseService.getDailyDistance(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculate and store daily distance
  Future<void> calculateDailyDistance(String userId, String date) async {
    try {
      final startOfDay = DateTime.parse('${date}T00:00:00');
      final endOfDay = DateTime.parse('${date}T23:59:59');

      final locations = await _databaseService.getLocationHistory(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (locations.isEmpty) return;

      double totalDistance = 0.0;
      for (int i = 1; i < locations.length; i++) {
        final distance = _locationService.getDistanceBetween(
          locations[i - 1].latitude,
          locations[i - 1].longitude,
          locations[i].latitude,
          locations[i].longitude,
        );
        totalDistance += distance;
      }

      await _databaseService.storeDailyDistance(
        userId: userId,
        date: date,
        totalDistance: totalDistance,
        startTime:
            locations.last.timestamp, // Oldest first due to descending order
        endTime: locations.first.timestamp,
      );
    } catch (e) {
      throw LiveTrackingException(
        'Failed to calculate daily distance: ${e.toString()}',
      );
    }
  }

  /// Get connection status
  Stream<bool> getConnectionStatus() {
    return _realtimeService.getConnectionStatus();
  }

  /// Get offline queue status
  OfflineQueueStatus getOfflineQueueStatus() {
    return OfflineQueueStatus(
      locationQueueSize: _offlineQueue.length,
      historyQueueSize: _historyQueue.length,
      isOnline: _isOnline,
      maxQueueSize: _maxOfflineQueueSize,
    );
  }

  /// Configure offline settings
  void configureOfflineSettings({
    int? maxQueueSize,
    Duration? syncRetryInterval,
    bool? enableHistoryStorage,
    int? historyStorageInterval,
  }) {
    if (maxQueueSize != null) _maxOfflineQueueSize = maxQueueSize;
    if (syncRetryInterval != null) {
      _syncRetryInterval = syncRetryInterval;
      _syncTimer?.cancel();
      _startSyncTimer();
    }
    if (enableHistoryStorage != null) {
      _storeHistoryEnabled = enableHistoryStorage;
    }
    if (historyStorageInterval != null) {
      _historyStorageInterval = historyStorageInterval;
    }

    developer.log(
      'Offline settings updated',
      name: 'FirebaseLiveTrackingService',
    );
  }

  /// Force sync offline data
  Future<void> forceSyncOfflineData() async {
    await _syncOfflineData();
  }

  /// Clear offline queues
  void clearOfflineQueues() {
    _offlineQueue.clear();
    _historyQueue.clear();
    developer.log(
      'Offline queues cleared',
      name: 'FirebaseLiveTrackingService',
    );
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Get current tracking settings
  TrackingConfiguration get currentConfiguration => TrackingConfiguration(
    updateInterval: _updateInterval,
    maxOfflineQueueSize: _maxOfflineQueueSize,
    syncRetryInterval: _syncRetryInterval,
    storeHistoryEnabled: _storeHistoryEnabled,
    historyStorageInterval: _historyStorageInterval,
  );

  /// Dispose resources
  void dispose() {
    stopTracking();
    _connectionSubscription?.cancel();
    _syncTimer?.cancel();
    _realtimeService.dispose();
    _locationService.dispose();
    developer.log(
      'Firebase Live Tracking Service disposed',
      name: 'FirebaseLiveTrackingService',
    );
  }
}

/// Custom exception class for live tracking operations
class LiveTrackingException implements Exception {
  final String message;

  LiveTrackingException(this.message);

  @override
  String toString() => 'LiveTrackingException: $message';
}

/// Offline queue status information
class OfflineQueueStatus {
  final int locationQueueSize;
  final int historyQueueSize;
  final bool isOnline;
  final int maxQueueSize;

  OfflineQueueStatus({
    required this.locationQueueSize,
    required this.historyQueueSize,
    required this.isOnline,
    required this.maxQueueSize,
  });

  bool get hasQueuedData => locationQueueSize > 0 || historyQueueSize > 0;
  double get queueUtilization =>
      (locationQueueSize + historyQueueSize) / (maxQueueSize * 2);
}

/// Tracking configuration
class TrackingConfiguration {
  final Duration updateInterval;
  final int maxOfflineQueueSize;
  final Duration syncRetryInterval;
  final bool storeHistoryEnabled;
  final int historyStorageInterval;

  TrackingConfiguration({
    required this.updateInterval,
    required this.maxOfflineQueueSize,
    required this.syncRetryInterval,
    required this.storeHistoryEnabled,
    required this.historyStorageInterval,
  });
}
