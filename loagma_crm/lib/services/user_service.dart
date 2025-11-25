import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static SharedPreferences? _prefs;

  static const String _keyUserId = "userId";
  static const String _keyRole = "role";
  static const String _keyContact = "contactNumber";
  static const String _keyName = "name";
  static const String _keyToken = "token";

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

    await _prefs?.setString(_keyUserId, user['_id'] ?? "");
    await _prefs?.setString(_keyRole, user['role'] ?? "");
    await _prefs?.setString(_keyContact, user['contactNumber'] ?? "");
    await _prefs?.setString(_keyName, user['name'] ?? "");

    if (data['token'] != null) {
      await _prefs?.setString(_keyToken, data['token']);
    }
  }

  /// -------------------------------------------------------------
  /// DEV MODE LOGIN
  /// -------------------------------------------------------------
  static Future<void> login({
    required String role,
    String? contactNumber,
  }) async {
    await _prefs?.setString(_keyRole, role);
    if (contactNumber != null) {
      await _prefs?.setString(_keyContact, contactNumber);
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
}
