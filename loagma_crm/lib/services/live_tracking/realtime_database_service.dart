import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../models/live_tracking/location_models.dart';

/// Service class for managing Firebase Realtime Database operations
/// Specifically handles live location tracking and real-time updates
class RealtimeDatabaseService {
  static RealtimeDatabaseService? _instance;
  static RealtimeDatabaseService get instance =>
      _instance ??= RealtimeDatabaseService._();
  RealtimeDatabaseService._();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database paths
  static const String liveLocationsPath = 'live_locations';
  static const String connectionStatusPath = 'connection_status';
  static const String userPresencePath = 'user_presence';

  // Stream subscriptions for cleanup
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Initialize Realtime Database with proper settings
  Future<void> initialize() async {
    try {
      // Enable offline persistence
      _database.setPersistenceEnabled(true);

      // Set cache size (10MB)
      _database.setPersistenceCacheSizeBytes(10000000);

      // Configure database URL if needed
      // Note: Database URL is typically configured in Firebase options

      // Set up connection monitoring
      await _setupConnectionMonitoring();
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to initialize Realtime Database: ${e.toString()}',
      );
    }
  }

  /// Set up connection monitoring for offline/online status
  Future<void> _setupConnectionMonitoring() async {
    try {
      final connectedRef = _database.ref('.info/connected');

      connectedRef.onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;

        if (connected) {
          _handleConnectionRestored();
        } else {
          _handleConnectionLost();
        }
      });
    } catch (e) {
      // Connection monitoring is not critical, so we don't throw
      developer.log(
        'Warning: Failed to set up connection monitoring: $e',
        name: 'RealtimeDatabaseService',
      );
    }
  }

  /// Handle connection restored event
  void _handleConnectionRestored() {
    // Optionally notify listeners about connection restoration
    developer.log(
      'Realtime Database connection restored',
      name: 'RealtimeDatabaseService',
    );
  }

  /// Handle connection lost event
  void _handleConnectionLost() {
    // Optionally notify listeners about connection loss
    developer.log(
      'Realtime Database connection lost',
      name: 'RealtimeDatabaseService',
    );
  }

  /// Update live location for current user
  Future<void> updateLiveLocation(LiveLocation location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw RealtimeDatabaseException('User not authenticated');
      }

      final ref = _database.ref().child(liveLocationsPath).child(user.uid);
      await ref.set(location.toJson());

      // Also update user presence
      await _updateUserPresence(user.uid, true);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to update live location: ${e.toString()}',
      );
    }
  }

  /// Get live location for a specific user
  Future<LiveLocation?> getLiveLocation(String userId) async {
    try {
      final ref = _database.ref().child(liveLocationsPath).child(userId);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['user_id'] = userId;
        return LiveLocation.fromJson(data);
      }
      return null;
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to get live location: ${e.toString()}',
      );
    }
  }

  /// Get all active live locations
  Future<List<LiveLocation>> getAllActiveLiveLocations() async {
    try {
      final ref = _database.ref().child(liveLocationsPath);
      final snapshot = await ref.orderByChild('is_active').equalTo(true).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        return data.entries.map((entry) {
          final locationData = Map<String, dynamic>.from(entry.value as Map);
          locationData['user_id'] = entry.key;
          return LiveLocation.fromJson(locationData);
        }).toList();
      }
      return [];
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to get all active live locations: ${e.toString()}',
      );
    }
  }

  /// Listen to live location changes for a specific user
  Stream<LiveLocation?> listenToUserLocation(String userId) {
    try {
      final ref = _database.ref().child(liveLocationsPath).child(userId);

      return ref.onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          data['user_id'] = userId;
          return LiveLocation.fromJson(data);
        }
        return null;
      });
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to listen to user location: ${e.toString()}',
      );
    }
  }

  /// Listen to all live location changes
  Stream<List<LiveLocation>> listenToAllLiveLocations() {
    try {
      final ref = _database.ref().child(liveLocationsPath);

      return ref.onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          return data.entries.map((entry) {
            final locationData = Map<String, dynamic>.from(entry.value as Map);
            locationData['user_id'] = entry.key;
            return LiveLocation.fromJson(locationData);
          }).toList();
        }
        return <LiveLocation>[];
      });
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to listen to all live locations: ${e.toString()}',
      );
    }
  }

  /// Listen to active salesmen locations only
  Stream<List<LiveLocation>> listenToActiveSalesmenLocations() {
    try {
      final ref = _database.ref().child(liveLocationsPath);

      return ref.orderByChild('is_active').equalTo(true).onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          return data.entries.map((entry) {
            final locationData = Map<String, dynamic>.from(entry.value as Map);
            locationData['user_id'] = entry.key;
            return LiveLocation.fromJson(locationData);
          }).toList();
        }
        return <LiveLocation>[];
      });
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to listen to active salesmen locations: ${e.toString()}',
      );
    }
  }

  /// Set user as active (start tracking)
  Future<void> setUserActive(String userId) async {
    try {
      final ref = _database.ref().child(liveLocationsPath).child(userId);
      await ref.update({
        'is_active': true,
        'last_update': ServerValue.timestamp,
      });

      await _updateUserPresence(userId, true);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to set user active: ${e.toString()}',
      );
    }
  }

  /// Set user as inactive (stop tracking)
  Future<void> setUserInactive(String userId) async {
    try {
      final ref = _database.ref().child(liveLocationsPath).child(userId);
      await ref.update({
        'is_active': false,
        'last_update': ServerValue.timestamp,
      });

      await _updateUserPresence(userId, false);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to set user inactive: ${e.toString()}',
      );
    }
  }

  /// Remove user's live location data
  Future<void> removeUserLocation(String userId) async {
    try {
      final ref = _database.ref().child(liveLocationsPath).child(userId);
      await ref.remove();

      await _removeUserPresence(userId);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to remove user location: ${e.toString()}',
      );
    }
  }

  /// Update user presence information
  Future<void> _updateUserPresence(String userId, bool isOnline) async {
    try {
      final ref = _database.ref().child(userPresencePath).child(userId);

      if (isOnline) {
        // Set up presence with automatic cleanup on disconnect
        await ref.set({'is_online': true, 'last_seen': ServerValue.timestamp});

        // Set up automatic cleanup on disconnect
        await ref.onDisconnect().update({
          'is_online': false,
          'last_seen': ServerValue.timestamp,
        });
      } else {
        await ref.update({
          'is_online': false,
          'last_seen': ServerValue.timestamp,
        });
      }
    } catch (e) {
      // Presence is not critical, so we don't throw
      developer.log(
        'Warning: Failed to update user presence: $e',
        name: 'RealtimeDatabaseService',
      );
    }
  }

  /// Remove user presence information
  Future<void> _removeUserPresence(String userId) async {
    try {
      final ref = _database.ref().child(userPresencePath).child(userId);
      await ref.remove();
    } catch (e) {
      // Presence is not critical, so we don't throw
      developer.log(
        'Warning: Failed to remove user presence: $e',
        name: 'RealtimeDatabaseService',
      );
    }
  }

  /// Get user presence information
  Future<Map<String, dynamic>?> getUserPresence(String userId) async {
    try {
      final ref = _database.ref().child(userPresencePath).child(userId);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to get user presence: ${e.toString()}',
      );
    }
  }

  /// Listen to user presence changes
  Stream<Map<String, dynamic>?> listenToUserPresence(String userId) {
    try {
      final ref = _database.ref().child(userPresencePath).child(userId);

      return ref.onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        }
        return null;
      });
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to listen to user presence: ${e.toString()}',
      );
    }
  }

  /// Get connection status
  Stream<bool> getConnectionStatus() {
    try {
      final ref = _database.ref('.info/connected');
      return ref.onValue.map((event) => event.snapshot.value as bool? ?? false);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to get connection status: ${e.toString()}',
      );
    }
  }

  /// Clean up old location data (call periodically)
  Future<void> cleanupOldLocations({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

      final ref = _database.ref().child(liveLocationsPath);
      final snapshot = await ref
          .orderByChild('last_update')
          .endAt(cutoffTime)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final updates = <String, dynamic>{};
        for (final userId in data.keys) {
          updates['$liveLocationsPath/$userId'] = null;
          updates['$userPresencePath/$userId'] = null;
        }

        if (updates.isNotEmpty) {
          await _database.ref().update(updates);
        }
      }
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to cleanup old locations: ${e.toString()}',
      );
    }
  }

  /// Subscribe to a stream with automatic cleanup
  void subscribeToStream(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
  }

  /// Cancel a specific subscription
  void cancelSubscription(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }

  /// Cancel all subscriptions and cleanup
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Validate location data before storing
  bool validateLocationData(Map<String, dynamic> data) {
    try {
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;
      final timestamp = data['timestamp'] as int?;
      final accuracy = data['accuracy'] as double?;
      final isActive = data['is_active'] as bool?;

      return latitude != null &&
          longitude != null &&
          timestamp != null &&
          accuracy != null &&
          isActive != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180 &&
          accuracy >= 0;
    } catch (e) {
      return false;
    }
  }

  /// Get database reference for custom operations
  DatabaseReference getReference(String path) {
    return _database.ref(path);
  }

  /// Perform atomic update operation
  Future<void> atomicUpdate(Map<String, dynamic> updates) async {
    try {
      await _database.ref().update(updates);
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to perform atomic update: ${e.toString()}',
      );
    }
  }

  /// Perform transaction operation
  Future<T?> runTransaction<T>(
    String path,
    T? Function(T? currentValue) updateFunction,
  ) async {
    try {
      final ref = _database.ref(path);
      final result = await ref.runTransaction((currentValue) {
        final typedValue = currentValue as T?;
        return Transaction.success(updateFunction(typedValue));
      });

      return result.snapshot.value as T?;
    } catch (e) {
      throw RealtimeDatabaseException(
        'Failed to run transaction: ${e.toString()}',
      );
    }
  }
}

/// Custom exception class for Realtime Database operations
class RealtimeDatabaseException implements Exception {
  final String message;

  RealtimeDatabaseException(this.message);

  @override
  String toString() => 'RealtimeDatabaseException: $message';
}
