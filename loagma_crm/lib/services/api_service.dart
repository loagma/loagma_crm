import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException, HttpException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

/// Handles all API interactions for OTP-based authentication.
/// Automatically chooses correct base URL for emulator, web, or real device.
class ApiService {
  /// Default local development host.
  static String _hostIp = '192.168.1.9';

  /// Override the host IP at runtime for testing on physical devices.
  static void setHostIp(String ip) => _hostIp = ip;

  /// Returns the current active host IP.
  static String get hostIp => _hostIp;

  /// Constructs the appropriate base URL depending on platform.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
      return 'http://$_hostIp:5000';
    } catch (_) {
      return 'http://$_hostIp:5000';
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Generic HTTP Request Handler
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('📡 POST $url');
    debugPrint('📦 Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      debugPrint('✅ Response ${response.statusCode}: ${response.body}');

      // Parse response body for both success and error cases
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        // Return the error response so the UI can show the message
        return responseData;
      }
    } on TimeoutException {
      throw Exception(
        '⏱️ Request to $url timed out after ${timeout.inSeconds}s',
      );
    } on SocketException catch (e) {
      throw Exception('🌐 Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('📄 Invalid response format: ${e.message}');
    } catch (e) {
      throw Exception('❌ Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('📡 GET $url');
    try {
      final response = await http.get(url).timeout(timeout);
      debugPrint('✅ Response ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw HttpException(
          'Request failed: ${response.statusCode} ${response.reasonPhrase}',
          uri: url,
        );
      }
    } on TimeoutException {
      throw Exception('⏱️ GET request to $url timed out');
    } on SocketException catch (e) {
      throw Exception('🌐 Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('📄 Invalid JSON response: ${e.message}');
    } catch (e) {
      throw Exception('❌ Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 API Endpoints
  // ---------------------------------------------------------------------------

  /// Sends OTP to user's contact number.
  static Future<Map<String, dynamic>> sendOtp(String contactNumber) {
    return _post('/auth/send-otp', {'contactNumber': contactNumber});
  }

  /// Verifies OTP. Includes optional [name] and [email] for new users.
  static Future<Map<String, dynamic>> verifyOtp(
    String contactNumber,
    String otp, 
  ) {
    final body = {
      'contactNumber': contactNumber,
      'otp': otp,
    };
    return _post('/auth/verify-otp', body);
  }

  /// Completes signup for new users by adding name and email.
  static Future<Map<String, dynamic>> completeSignup(
    String contactNumber,
    String name,
    String email,
  ) {
    final body = {
      'contactNumber': contactNumber,
      'name': name,
      'email': email,
    };
    return _post('/auth/complete-signup', body);
  }

  /// Simple health check endpoint.
  static Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/health');
    debugPrint('🔍 Health Check: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } on TimeoutException {
      throw Exception('Health check timed out');
    } on SocketException catch (e) {
      throw Exception('Network error during health check: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during health check: $e');
    }
  }
}
