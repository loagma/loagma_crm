import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class NetworkService {
  static bool _isOnline = true;
  static DateTime? _lastConnectivityCheck;

  static bool get isOnline => _isOnline;

  /// Check if the device has internet connectivity
  static Future<bool> checkConnectivity() async {
    // Cache connectivity check for 30 seconds to avoid excessive calls
    if (_lastConnectivityCheck != null &&
        DateTime.now().difference(_lastConnectivityCheck!).inSeconds < 30) {
      return _isOnline;
    }

    try {
      // Try to reach a reliable endpoint first
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // If internet is available, test our API server
        _isOnline = await _testApiServer();
      } else {
        _isOnline = false;
      }
    } catch (e) {
      _isOnline = false;
    }

    _lastConnectivityCheck = DateTime.now();
    return _isOnline;
  }

  /// Test if our API server is reachable
  static Future<bool> _testApiServer() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      // If health endpoint doesn't exist, try a basic endpoint
      try {
        final response = await http
            .get(Uri.parse(ApiConfig.baseUrl))
            .timeout(const Duration(seconds: 10));

        // Any response (even 404) means server is reachable
        return response.statusCode < 500;
      } catch (e) {
        return false;
      }
    }
  }

  /// Get user-friendly error message based on error type
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('failed host lookup') ||
        errorString.contains('socketexception')) {
      if (ApiConfig.useProduction) {
        return 'Server is temporarily unavailable. This might be because the free hosting service is sleeping. Please wait 30-60 seconds and try again.';
      } else {
        return 'Cannot connect to local server. Make sure your backend is running on port 5000.';
      }
    } else if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (errorString.contains('connection refused')) {
      return 'Server connection refused. The server might be down for maintenance.';
    } else if (errorString.contains('no route to host')) {
      return 'Network unreachable. Please check your internet connection.';
    } else {
      return 'Network error occurred. Please try again later.';
    }
  }

  /// Retry mechanism for API calls
  static Future<T> retryApiCall<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await apiCall();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Wait before retrying, with exponential backoff
        await Future.delayed(delay * attempts);
      }
    }

    throw Exception('Max retries exceeded');
  }
}
