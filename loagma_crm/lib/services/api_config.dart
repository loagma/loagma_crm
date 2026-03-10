// // lib/config/api_config.dart
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

// /// Centralized API Configuration
// /// ✅ Works locally for emulator, web, and physical devices.
// /// 💡 Easy to update when moving to production.
// class ApiConfig {
//   /// Your local system IP (used for testing on physical devices)
//   static String _localHostIp = '192.168.1.9';

//   /// Update manually if your local IP changes
//   static void setLocalHostIp(String ip) => _localHostIp = ip;

//   /// Base URL detection based on platform
//   static String get baseUrl {
//     if (kIsWeb) return 'http://localhost:5000';
//     try {
//       if (Platform.isAndroid) {
//         return 'http://10.0.2.2:5000'; // Android Emulator
//       } else {
//         return 'http://$_localHostIp:5000'; // Physical Device or iOS
//       }
//     } catch (_) {
//       return 'http://$_localHostIp:5000';
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // Endpoints
//   // ---------------------------------------------------------------------------
//   static String get authUrl => '$baseUrl/auth';
//   static String get usersUrl => '$baseUrl/users';
//   static String get accountsUrl => '$baseUrl/accounts';
//   static String get locationsUrl => '$baseUrl/locations';
// }

// lib/config/api_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API Configuration
/// Toggle between local and production backend.
class ApiConfig {
  /// Set to false for local development, true for production (Render).
  static const bool useProduction = false;

  /// Your computer's local WiFi IP. Update if it changes.
  /// Find it with: ipconfig (Windows) or ifconfig / ip addr (Mac/Linux).
  static const String _localIp = '192.168.1.6';

  static String get baseUrl {
    if (useProduction) {
      return 'https://loagma-crm.onrender.com';
    }

    if (kIsWeb) return 'http://localhost:5000';

    try {
      if (Platform.isAndroid) {
        // Physical devices AND emulators both use the LAN IP.
        // 10.0.2.2 only works in the emulator; the LAN IP works everywhere
        // as long as the phone/emulator is on the same WiFi network.
        return 'http://$_localIp:5000';
      }
      return 'http://$_localIp:5000';
    } catch (_) {
      return 'http://$_localIp:5000';
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------
  static String get authUrl => '$baseUrl/auth';
  static String get usersUrl => '$baseUrl/users';
  static String get accountsUrl => '$baseUrl/accounts';
  static String get locationsUrl => '$baseUrl/locations';
  static String get teleadminUrl => '$baseUrl/teleadmin';
}
