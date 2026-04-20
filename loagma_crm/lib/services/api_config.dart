// lib/config/api_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API Configuration
/// Toggle between local and production backend.
class ApiConfig {
  /// Set to false for local development, true for production (Render).
  static const bool useProduction = true;

  /// Your computer's local WiFi IP. Update if it changes.
  /// Find it with: ipconfig (Windows) or ifconfig / ip addr (Mac/Linux).
  static const String _localIp = '192.168.1.7';
  // static const String _localIp = '172.20.10.3';

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
