// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // ---------------------------------------------------------------------------
  // 🔹 Generic HTTP Request Handler
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
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
      final responseData = jsonDecode(response.body);

      return responseData;
    } on TimeoutException {
      throw Exception('⏱️ Request timed out after ${timeout.inSeconds}s');
    } on SocketException catch (e) {
      throw Exception('🌐 Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('📄 Invalid response format: ${e.message}');
    } catch (e) {
      throw Exception('❌ Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
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

  static Future<Map<String, dynamic>> sendOtp(String contactNumber) =>
      _post('/auth/send-otp', {'contactNumber': contactNumber});

  static Future<Map<String, dynamic>> verifyOtp(
    String contactNumber,
    String otp,
  ) => _post('/auth/verify-otp', {'contactNumber': contactNumber, 'otp': otp});

  static Future<Map<String, dynamic>> completeSignup(
    String contactNumber,
    String name,
    String email,
  ) => _post('/auth/complete-signup', {
    'contactNumber': contactNumber,
    'name': name,
    'email': email,
  });

  static Future<bool> healthCheck() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/health');
    debugPrint('🔍 Health Check: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return false;
    }
  }
}
