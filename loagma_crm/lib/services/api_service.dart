import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class ApiService {
  // If you're running on a real Android device, set this to your PC's LAN IP (e.g. 192.168.x.x).
  // For Android emulator use 10.0.2.2, for Genymotion use 10.0.3.2. For iOS simulator and web use localhost.
  // Default LAN IP for dev machine. You can override this at runtime using
  // `ApiService.setHostIp('192.168.x.y')` (useful when testing on a real device).
  static String _hostIp = '192.168.1.9';

  /// Override the host IP used for non-Android/iOS simulator targets.
  static void setHostIp(String ip) => _hostIp = ip;

  /// Read the current host IP (useful for debugging/testing).
  static String get hostIp => _hostIp;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) {
        // Android emulator maps host localhost to 10.0.2.2
        return 'http://10.0.2.2:5000';
      }
      // iOS simulator / desktop will be able to access host via localhost or LAN IP
      return 'http://$_hostIp:5000';
    } catch (_) {
      // Fallback when Platform is not available (tests, other targets)
      return 'http://$_hostIp:5000';
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String contactNumber) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');
    // Helpful debug log so you can see which baseUrl is used on the device/emulator
    // Check logs for: "ApiService: sending OTP to <baseUrl>"
    // This is useful when running on emulator (10.0.2.2) vs real device (LAN IP)
    debugPrint('ApiService: sending OTP to $baseUrl');

    try {
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"contactNumber": contactNumber}),
      )
          // increase timeout slightly to help with slow dev backends
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to send OTP (status ${response.statusCode}): ${response.body}");
      }
    } on SocketException catch (e) {
      throw Exception('No network / connection refused when sending OTP: ${e.message}');
    } on TimeoutException catch (_) {
      throw Exception('API Timeout: request to $baseUrl/auth/send-otp timed out after 20s');
    } on http.ClientException catch (e) {
      // low-level HTTP client issue
      throw Exception('Network error when sending OTP: ${e.message}');
    } catch (e) {
      // rethrow with helpful message
      throw Exception('Unexpected error when sending OTP: $e');
    }
  }

  /// Simple health check hitting [baseUrl]/health (timeout 5s).
  /// Returns true when statusCode == 200, otherwise throws with message.
  static Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/health');
    debugPrint('ApiService: healthCheck -> $url');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return true;
      throw Exception('Health check failed: ${res.statusCode} ${res.body}');
    } on TimeoutException catch (_) {
      throw Exception('Health check timed out contacting $baseUrl');
    } on SocketException catch (e) {
      throw Exception('Network error on health check: ${e.message}');
    }
  }

  /// Wrapper around [sendOtp] that retries up to [retries] times on transient
  /// network errors (SocketException, TimeoutException).
  static Future<Map<String, dynamic>> sendOtpWithRetry(String contactNumber,
      {int retries = 1}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await sendOtp(contactNumber);
      } catch (e) {
        final isLast = attempt > retries;
        final msg = e.toString();
        // Retry only on socket/timeout-like errors
        if (!isLast && (msg.contains('Timeout') || msg.contains('No network') || msg.contains('connection refused'))) {
          debugPrint('ApiService: sendOtp attempt $attempt failed with transient error, retrying... ($msg)');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

}
