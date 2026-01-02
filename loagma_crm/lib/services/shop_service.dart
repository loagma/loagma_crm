import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class ShopService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Get all shops for a pincode (both existing accounts and Google Places)
  static Future<Map<String, dynamic>> getShopsByPincode(
    String pincode, {
    List<String>? businessTypes,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$_baseUrl/shops/pincode/$pincode');
      final queryParams = <String, String>{};

      if (businessTypes != null && businessTypes.isNotEmpty) {
        queryParams['businessTypes'] = businessTypes.join(',');
      }

      final finalUri = uri.replace(queryParameters: queryParams);

      print('🔍 Fetching shops for pincode: $pincode');
      print('📡 URL: $finalUri');

      final response = await http.get(
        finalUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully fetched shops data');
        print('📊 Total shops: ${data['totalShops']}');
        print('📊 Existing accounts: ${data['existingAccounts']['count']}');
        print('📊 Google Places: ${data['googlePlacesShops']['count']}');

        return {'success': true, 'data': data};
      } else {
        print('❌ Failed to fetch shops: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch shops',
        };
      }
    } catch (e) {
      print('❌ Error fetching shops by pincode: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get Google Place details
  static Future<Map<String, dynamic>> getGooglePlaceDetails(
    String placeId,
  ) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$_baseUrl/shops/google-place/$placeId');

      print('🔍 Fetching Google Place details: $placeId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully fetched place details');

        return {'success': true, 'data': data};
      } else {
        print('❌ Failed to fetch place details: ${response.statusCode}');

        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch place details',
        };
      }
    } catch (e) {
      print('❌ Error fetching Google Place details: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Create account from Google Place
  static Future<Map<String, dynamic>> createAccountFromGooglePlace(
    String placeId, {
    String? assignedToId,
    String customerStage = 'Lead',
    String funnelStage = 'Awareness',
    String? notes,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
        '$_baseUrl/shops/google-place/$placeId/create-account',
      );

      final body = {
        'assignedToId': assignedToId,
        'customerStage': customerStage,
        'funnelStage': funnelStage,
        'notes': notes,
      };

      print('🔍 Creating account from Google Place: $placeId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Successfully created account from Google Place');

        return {'success': true, 'data': data};
      } else {
        print('❌ Failed to create account: ${response.statusCode}');

        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create account',
        };
      }
    } catch (e) {
      print('❌ Error creating account from Google Place: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
