import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'network_service.dart';
import 'user_service.dart';

class TelecallerApiService {
  static Future<Map<String, String>> _headers() async {
    final token = UserService.token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query);
  }

  /// GET /telecaller/dashboard/summary
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final hasNet = await NetworkService.checkConnectivity();
      if (!hasNet) {
        return {
          'success': false,
          'message': NetworkService.getNetworkErrorMessage(
            'No internet connection',
          ),
          'data': const {},
        };
      }

      final response = await NetworkService.retryApiCall(
        () async {
          final headers = await _headers();
          return http
              .get(
                _buildUri('/telecaller/dashboard/summary'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 15));
        },
        maxRetries: 2,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'],
        'data': data['data'] ?? const {},
      };
    } catch (e) {
      debugPrint('❌ getDashboardSummary error: $e');
      return {
        'success': false,
        'message': NetworkService.getNetworkErrorMessage(e),
        'data': const {},
      };
    }
  }

  /// POST /telecaller/leads/:id/calls
  static Future<Map<String, dynamic>> createCallLog({
    required String accountId,
    required String status,
    int? durationSec,
    String? notes,
    String? recordingUrl,
    DateTime? calledAt,
    DateTime? nextFollowupAt,
    String? followupNotes,
  }) async {
    try {
      final hasNet = await NetworkService.checkConnectivity();
      if (!hasNet) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final body = <String, dynamic>{
        'status': status,
        if (durationSec != null) 'durationSec': durationSec,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (recordingUrl != null && recordingUrl.isNotEmpty)
          'recordingUrl': recordingUrl,
        if (calledAt != null) 'calledAt': calledAt.toIso8601String(),
        if (nextFollowupAt != null)
          'nextFollowupAt': nextFollowupAt.toIso8601String(),
        if (followupNotes != null && followupNotes.isNotEmpty)
          'followupNotes': followupNotes,
      };

      final response = await NetworkService.retryApiCall(
        () async {
          final headers = await _headers();
          return http
              .post(
                _buildUri('/telecaller/leads/$accountId/calls'),
                headers: headers,
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 15));
        },
        maxRetries: 1,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 &&
            (data['success'] == null || data['success'] == true),
        'message': data['message'] ?? 'Call log saved',
        'data': data['data'],
      };
    } catch (e) {
      debugPrint('❌ createCallLog error: $e');
      return {
        'success': false,
        'message': NetworkService.getNetworkErrorMessage(e),
        'data': null,
      };
    }
  }

  /// GET /telecaller/followups
  static Future<Map<String, dynamic>> getFollowups() async {
    try {
      final hasNet = await NetworkService.checkConnectivity();
      if (!hasNet) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final response = await NetworkService.retryApiCall(
        () async {
          final headers = await _headers();
          return http
              .get(
                _buildUri('/telecaller/followups'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 15));
        },
        maxRetries: 2,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] ?? const {},
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load follow-ups',
        'data': const {},
      };
    } catch (e) {
      debugPrint('❌ getFollowups error: $e');
      return {
        'success': false,
        'message': NetworkService.getNetworkErrorMessage(e),
        'data': const {},
      };
    }
  }

  /// GET /telecaller/call-history
  static Future<Map<String, dynamic>> getCallHistory() async {
    try {
      final hasNet = await NetworkService.checkConnectivity();
      if (!hasNet) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final response = await NetworkService.retryApiCall(
        () async {
          final headers = await _headers();
          return http
              .get(
                _buildUri('/telecaller/call-history'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 15));
        },
        maxRetries: 2,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] ?? const [],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load call history',
        'data': const [],
      };
    } catch (e) {
      debugPrint('❌ getCallHistory error: $e');
      return {
        'success': false,
        'message': NetworkService.getNetworkErrorMessage(e),
        'data': const [],
      };
    }
  }
}

