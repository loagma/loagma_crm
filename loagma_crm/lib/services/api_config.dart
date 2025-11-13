// lib/config/api_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API Configuration
/// ✅ Works locally for emulator, web, and physical devices.
/// 💡 Easy to update when moving to production.
class ApiConfig {
  /// Your local system IP (used for testing on physical devices)
  static String _localHostIp = '192.168.1.9';

  /// Update manually if your local IP changes
  static void setLocalHostIp(String ip) => _localHostIp = ip;

  /// Base URL detection based on platform
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000'; // Android Emulator
      } else {
        return 'http://$_localHostIp:5000'; // Physical Device or iOS
      }
    } catch (_) {
      return 'http://$_localHostIp:5000';
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------
  static String get authUrl => '$baseUrl/auth';
  static String get usersUrl => '$baseUrl/users';
  static String get accountsUrl => '$baseUrl/accounts';
  static String get locationsUrl => '$baseUrl/locations';
}
