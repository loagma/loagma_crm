import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Firebase service for initializing and managing Firebase connections
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseDatabase? _database;

  // Getters for Firebase instances
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseDatabase get database => _database ??= FirebaseDatabase.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Firebase with configuration
  Future<void> initialize({FirebaseOptions? options}) async {
    try {
      if (_initialized) {
        print('Firebase already initialized');
        return;
      }

      await Firebase.initializeApp(options: options);

      // Configure Firestore settings
      _configureFirestore();

      // Configure Realtime Database settings
      _configureRealtimeDatabase();

      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      throw FirebaseInitializationException(
        'Failed to initialize Firebase: $e',
      );
    }
  }

  /// Configure Firestore settings
  void _configureFirestore() {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Configure Realtime Database settings
  void _configureRealtimeDatabase() {
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
  }

  /// Validate Firebase connection
  Future<bool> validateConnection() async {
    try {
      if (!_initialized) {
        throw Exception('Firebase not initialized');
      }

      // Test Firestore connection
      await firestore.enableNetwork();

      // Test Realtime Database connection
      final ref = database.ref('connection_test');
      await ref.set({'timestamp': ServerValue.timestamp});
      await ref.remove();

      return true;
    } catch (e) {
      print('Firebase connection validation failed: $e');
      return false;
    }
  }

  /// Get current user authentication status
  User? getCurrentUser() {
    return auth.currentUser;
  }

  /// Check if user has specific role
  Future<String?> getUserRole() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Failed to sign out: $e',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _auth = null;
    _firestore = null;
    _database = null;
    _initialized = false;
  }
}

/// Custom exception for Firebase initialization errors
class FirebaseInitializationException implements Exception {
  final String message;

  const FirebaseInitializationException(this.message);

  @override
  String toString() => 'FirebaseInitializationException: $message';
}

/// Firebase connection validator
class FirebaseConnectionValidator {
  static Future<ValidationResult> validate() async {
    final service = FirebaseService.instance;

    if (!service.isInitialized) {
      return ValidationResult(
        isValid: false,
        error: 'Firebase not initialized',
      );
    }

    try {
      final isConnected = await service.validateConnection();

      if (!isConnected) {
        return ValidationResult(
          isValid: false,
          error: 'Firebase connection failed',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Connection validation error: $e',
      );
    }
  }
}

/// Result of Firebase connection validation
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({required this.isValid, this.error});

  @override
  String toString() {
    return isValid
        ? 'ValidationResult: Valid'
        : 'ValidationResult: Invalid - $error';
  }
}
