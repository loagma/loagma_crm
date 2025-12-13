import 'dart:io';
import 'package:flutter/material.dart';

class NetworkService {
  // Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if the backend server is reachable
  static Future<bool> isServerReachable(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);
      final result = await InternetAddress.lookup(uri.host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user-friendly error message for network errors
  static String getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('failed host lookup') ||
        errorString.contains('socketexception')) {
      return 'Cannot connect to server. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. The server might be starting up (this can take 30-60 seconds for free servers). Please wait and try again.';
    } else if (errorString.contains('connection refused')) {
      return 'Server is not responding. Please try again later.';
    } else if (errorString.contains('handshake')) {
      return 'SSL connection failed. Please check your network settings.';
    } else if (errorString.contains('no route to host')) {
      return 'Network unreachable. Please check your internet connection.';
    } else {
      return 'Network error occurred. Please check your connection and try again.';
    }
  }

  // Show network error dialog with helpful information
  static void showNetworkErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Connection Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getNetworkErrorMessage(error)),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Check your internet connection'),
            const Text('• Try switching between WiFi and mobile data'),
            const Text(
              '• Wait 30-60 seconds and try again (server may be starting)',
            ),
            const Text('• Restart the app if the problem persists'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show a simple network status snackbar
  static void showNetworkStatus(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Connected to internet' : 'No internet connection',
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
