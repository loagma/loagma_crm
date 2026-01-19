import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import 'firebase_options.dart';

/// Application initialization service
/// Handles all app startup initialization including Firebase
class AppInitialization {
  static bool _initialized = false;

  /// Initialize all app services
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('App already initialized');
      }
      return;
    }

    try {
      // Initialize existing user service
      await UserService.init();

      // Initialize Firebase for live tracking
      await FirebaseService.instance.initialize(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Validate Firebase connection
      final isConnected = await FirebaseService.instance.validateConnection();
      if (!isConnected) {
        if (kDebugMode) {
          print('Warning: Firebase connection validation failed');
        }
      }

      _initialized = true;
      if (kDebugMode) {
        print('App initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('App initialization failed: $e');
      }
      // Don't throw - allow app to continue without Firebase if needed
      // You can modify this behavior based on your requirements
    }
  }

  /// Check if app is initialized
  static bool get isInitialized => _initialized;

  /// Check if Firebase is available
  static bool get isFirebaseAvailable => FirebaseService.instance.isInitialized;
}
