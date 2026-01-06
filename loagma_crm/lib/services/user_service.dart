import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'network_service.dart';

class UserService {
  static SharedPreferences? _prefs;

  static const String _keyUserId = "userId";
  static const String _keyRole = "role";
  static const String _keyContact = "contactNumber";
  static const String _keyName = "name";
  static const String _keyToken = "token";
  static const String _keyAttendanceId = "currentAttendanceId";

  /// -------------------------------------------------------------
  /// MUST CALL IN main() → before runApp()
  /// -------------------------------------------------------------
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// -------------------------------------------------------------
  /// REAL LOGIN — Save full session from API response
  /// -------------------------------------------------------------
  static Future<void> loginFromApi(Map<String, dynamic> data) async {
    final user = data['data'];

    if (user == null) return;

    // Handle both 'id' and '_id' formats from backend
    final userId = user['id'] ?? user['_id'] ?? "";
    await _prefs?.setString(_keyUserId, userId);
    await _prefs?.setString(_keyRole, user['role'] ?? "");
    await _prefs?.setString(_keyContact, user['contactNumber'] ?? "");
    await _prefs?.setString(_keyName, user['name'] ?? "");

    if (data['token'] != null) {
      await _prefs?.setString(_keyToken, data['token']);
    }
  }

  /// -------------------------------------------------------------
  /// DEV MODE LOGIN (with optional user ID)
  /// -------------------------------------------------------------
  static Future<void> login({
    required String role,
    String? contactNumber,
    String? userId,
    String? name,
  }) async {
    await _prefs?.setString(_keyRole, role);
    if (contactNumber != null) {
      await _prefs?.setString(_keyContact, contactNumber);
    }
    if (userId != null) {
      await _prefs?.setString(_keyUserId, userId);
    }
    if (name != null) {
      await _prefs?.setString(_keyName, name);
    }
  }

  /// -------------------------------------------------------------
  /// LOGOUT
  /// -------------------------------------------------------------
  static Future<void> logout() async {
    await _prefs?.clear();
  }

  /// -------------------------------------------------------------
  /// GETTERS
  /// -------------------------------------------------------------
  static bool get isLoggedIn {
    final role = _prefs?.getString(_keyRole);
    return role != null && role.isNotEmpty;
  }

  static String? get currentUserId => _prefs?.getString(_keyUserId);
  static String? get currentRole => _prefs?.getString(_keyRole);
  static String? get contactNumber => _prefs?.getString(_keyContact);
  static String? get name => _prefs?.getString(_keyName);
  static String? get token => _prefs?.getString(_keyToken);
  static String? get currentAttendanceId => _prefs?.getString(_keyAttendanceId);

  /// Set current attendance ID (called when punch-in)
  static Future<void> setCurrentAttendanceId(String? attendanceId) async {
    if (attendanceId != null) {
      await _prefs?.setString(_keyAttendanceId, attendanceId);
    } else {
      await _prefs?.remove(_keyAttendanceId);
    }
  }

  /// Check if user has valid authentication (logged in with token)
  static bool get hasValidAuth {
    return isLoggedIn &&
        token != null &&
        token!.isNotEmpty &&
        currentUserId != null &&
        currentUserId!.isNotEmpty;
  }

  /// -------------------------------------------------------------
  /// API METHODS
  /// -------------------------------------------------------------

  // Get All Users (Admin) - Optimized with better error handling
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      // Check connectivity first
      final isConnected = await NetworkService.checkConnectivity();
      if (!isConnected) {
        return {
          'success': false,
          'message':
              'No internet connection. Please check your network and try again.',
          'data': [],
        };
      }

      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Use retry mechanism for better reliability
      final response = await NetworkService.retryApiCall(
        () => http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/users/get-all'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        maxRetries: 2,
        delay: const Duration(seconds: 3),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': [],
        };
      } else if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch users',
          'data': [],
        };
      }
    } catch (e) {
      final errorMessage = NetworkService.getErrorMessage(e);
      return {'success': false, 'message': errorMessage, 'data': []};
    }
  }
}
