import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'dart:async';
import '../../models/live_tracking/location_models.dart';

/// Service class for managing Firebase database operations
/// Handles Firestore collections and Realtime Database setup
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final rtdb.FirebaseDatabase _realtimeDb = rtdb.FirebaseDatabase.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String locationHistoryCollection = 'location_history';
  static const String dailyDistanceCollection = 'daily_distance';

  // Realtime Database paths
  static const String liveLocationsPath = 'live_locations';

  /// Initialize database with proper settings
  Future<void> initialize() async {
    try {
      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Realtime Database settings
      _realtimeDb.setPersistenceEnabled(true);
      _realtimeDb.setPersistenceCacheSizeBytes(10000000); // 10MB cache
    } catch (e) {
      throw DatabaseException('Failed to initialize database: ${e.toString()}');
    }
  }

  /// Create or update user document in Firestore
  Future<void> createUserDocument(TrackingUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.id)
          .set(user.toJson());
    } catch (e) {
      throw DatabaseException(
        'Failed to create user document: ${e.toString()}',
      );
    }
  }

  /// Get user document from Firestore
  Future<TrackingUser?> getUserDocument(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = userId;

        // Handle Firestore timestamp conversion
        if (data['created_at'] is Timestamp) {
          data['created_at'] =
              (data['created_at'] as Timestamp).millisecondsSinceEpoch;
        }

        return TrackingUser.fromJson(data);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get user document: ${e.toString()}');
    }
  }

  /// Update user document in Firestore
  Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update(updates);
    } catch (e) {
      throw DatabaseException(
        'Failed to update user document: ${e.toString()}',
      );
    }
  }

  /// Get all users with optional role filter
  Future<List<TrackingUser>> getUsers({UserRole? roleFilter}) async {
    try {
      Query query = _firestore.collection(usersCollection);

      if (roleFilter != null) {
        query = query.where(
          'role',
          isEqualTo: roleFilter.toString().split('.').last,
        );
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Handle Firestore timestamp conversion
        if (data['created_at'] is Timestamp) {
          data['created_at'] =
              (data['created_at'] as Timestamp).millisecondsSinceEpoch;
        }

        return TrackingUser.fromJson(data);
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to get users: ${e.toString()}');
    }
  }

  /// Store location history in Firestore
  Future<void> storeLocationHistory(LocationHistory location) async {
    try {
      await _firestore
          .collection(locationHistoryCollection)
          .add(location.toJson());
    } catch (e) {
      throw DatabaseException(
        'Failed to store location history: ${e.toString()}',
      );
    }
  }

  /// Get location history for a user
  Future<List<LocationHistory>> getLocationHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(locationHistoryCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
        );
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return LocationHistory.fromJson(data);
      }).toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get location history: ${e.toString()}',
      );
    }
  }

  /// Store daily distance record
  Future<void> storeDailyDistance({
    required String userId,
    required String date,
    required double totalDistance,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final docId = '${date}_$userId';
      final data = {
        'user_id': userId,
        'date': date,
        'total_distance': totalDistance,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': endTime.millisecondsSinceEpoch,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(dailyDistanceCollection).doc(docId).set(data);
    } catch (e) {
      throw DatabaseException(
        'Failed to store daily distance: ${e.toString()}',
      );
    }
  }

  /// Get daily distance records for a user
  Future<List<Map<String, dynamic>>> getDailyDistance({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(dailyDistanceCollection)
          .where('user_id', isEqualTo: userId);

      if (startDate != null) {
        final startDateStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.where('date', isGreaterThanOrEqualTo: startDateStr);
      }

      if (endDate != null) {
        final endDateStr =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.where('date', isLessThanOrEqualTo: endDateStr);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Handle Firestore timestamp conversion
        if (data['updated_at'] is Timestamp) {
          data['updated_at'] =
              (data['updated_at'] as Timestamp).millisecondsSinceEpoch;
        }

        return data;
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to get daily distance: ${e.toString()}');
    }
  }

  /// Update live location in Realtime Database
  Future<void> updateLiveLocation(LiveLocation location) async {
    try {
      final ref = _realtimeDb
          .ref()
          .child(liveLocationsPath)
          .child(location.userId);
      await ref.set(location.toJson());
    } catch (e) {
      throw DatabaseException(
        'Failed to update live location: ${e.toString()}',
      );
    }
  }

  /// Get live location for a user
  Future<LiveLocation?> getLiveLocation(String userId) async {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath).child(userId);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return LiveLocation.fromJson(data);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get live location: ${e.toString()}');
    }
  }

  /// Get all live locations
  Future<List<LiveLocation>> getAllLiveLocations() async {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath);
      final snapshot = await ref.get();

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
      throw DatabaseException(
        'Failed to get all live locations: ${e.toString()}',
      );
    }
  }

  /// Listen to live location changes for a user
  Stream<LiveLocation?> listenToLiveLocation(String userId) {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath).child(userId);

      return ref.onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return LiveLocation.fromJson(data);
        }
        return null;
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to listen to live location: ${e.toString()}',
      );
    }
  }

  /// Listen to all live location changes
  Stream<List<LiveLocation>> listenToAllLiveLocations() {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath);

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
      throw DatabaseException(
        'Failed to listen to all live locations: ${e.toString()}',
      );
    }
  }

  /// Remove live location for a user
  Future<void> removeLiveLocation(String userId) async {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath).child(userId);
      await ref.remove();
    } catch (e) {
      throw DatabaseException(
        'Failed to remove live location: ${e.toString()}',
      );
    }
  }

  /// Set user as inactive in live locations
  Future<void> setUserInactive(String userId) async {
    try {
      final ref = _realtimeDb.ref().child(liveLocationsPath).child(userId);
      await ref.update({
        'is_active': false,
        'last_update': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw DatabaseException('Failed to set user inactive: ${e.toString()}');
    }
  }

  /// Create database indexes (call this during app initialization)
  Future<void> createIndexes() async {
    try {
      // Note: Firestore indexes are typically created through Firebase Console
      // or using Firebase CLI. This method serves as documentation for required indexes.

      // Required indexes for location_history collection:
      // - user_id (ascending), timestamp (descending)
      // - timestamp (ascending) for date range queries

      // Required indexes for daily_distance collection:
      // - user_id (ascending), date (ascending)
      // - date (ascending) for date range queries

      // Required indexes for users collection:
      // - role (ascending) for role-based queries
      // - active (ascending) for active user queries

      // These indexes should be created in Firebase Console or via firebase deploy
    } catch (e) {
      throw DatabaseException('Failed to create indexes: ${e.toString()}');
    }
  }

  /// Clean up old location history data (call periodically)
  Future<void> cleanupOldLocationHistory({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final query = _firestore
          .collection(locationHistoryCollection)
          .where('timestamp', isLessThan: cutoffDate.millisecondsSinceEpoch)
          .limit(500); // Process in batches

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      throw DatabaseException(
        'Failed to cleanup old location history: ${e.toString()}',
      );
    }
  }
}

/// Custom exception class for database operations
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
