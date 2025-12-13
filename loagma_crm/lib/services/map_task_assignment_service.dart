import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/shop_model.dart';
import '../services/user_service.dart';

class MapTaskAssignmentService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get headers with auth token from UserService
  static Map<String, String> _getHeaders() {
    final token = UserService.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> fetchSalesmen() async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/users/salesmen'; // Use the correct salesmen endpoint
      print('🔍 Fetching salesmen from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Salesmen data: $data');
        return data;
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to fetch salesmen (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error fetching salesmen: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchLocationByPincode(String pincode) async {
    try {
      final headers = _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pincode/$pincode'), // Use the pincode endpoint
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch location'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> assignAreasToSalesman(
    String salesmanId,
    String salesmanName,
    String pincode,
    String country,
    String state,
    String district,
    String city,
    List<String> areas,
    List<String> businessTypes, {
    int totalBusinesses = 0,
  }) async {
    try {
      final headers = _getHeaders();
      final url = '$baseUrl/task-assignments'; // Use the correct endpoint
      final payload = {
        'salesmanId': salesmanId,
        'salesmanName': salesmanName,
        'pincode': pincode,
        'country': country,
        'state': state,
        'district': district,
        'city': city,
        'areas': areas,
        'businessTypes': businessTypes,
        'totalBusinesses': totalBusinesses,
      };

      print('🌐 API Call: POST $url');
      print('📦 Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(payload),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Assignment API Success: $data');
        return data;
      } else {
        print(
          '❌ Assignment API Failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'message': 'Failed to assign areas (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Assignment API Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAssignmentsBySalesman(
    String salesmanId,
  ) async {
    try {
      final headers = _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/task-assignments/salesman/$salesmanId',
        ), // Use correct endpoint
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch assignments'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> searchBusinesses(
    String pincode,
    List<String> areas,
    List<String> businessTypes,
  ) async {
    try {
      // This endpoint might not exist, so let's return mock data for now
      print(
        '🔍 Searching businesses for pincode: $pincode, areas: $areas, types: $businessTypes',
      );

      // Return mock data since we don't have a businesses search endpoint
      return {
        'success': true,
        'businesses': [],
        'message': 'Business search not implemented yet',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveShops(
    List<Shop> shops,
    String salesmanId,
  ) async {
    try {
      // For now, return success since we don't have a shops endpoint in task-assignments
      print('💾 Would save ${shops.length} shops for salesman: $salesmanId');

      return {
        'success': true,
        'message': 'Shops saved successfully (mock)',
        'savedCount': shops.length,
      };
    } catch (e) {
      print('❌ Save shops error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getShopsBySalesman(String salesmanId) async {
    try {
      // Return empty shops list for now
      print('🏪 Getting shops for salesman: $salesmanId');

      return {'success': true, 'shops': [], 'message': 'No shops found'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateShopStage(
    String shopId,
    String stage,
  ) async {
    try {
      print('🏪 Updating shop $shopId stage to: $stage');

      return {
        'success': true,
        'message': 'Shop stage updated successfully (mock)',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/task-assignments/$assignmentId'; // Use correct endpoint
      print('🗑️ Deleting assignment: $url');

      final response = await http.delete(Uri.parse(url), headers: headers);

      print('📡 Delete Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Assignment deleted successfully');
        return data;
      } else {
        print('❌ Failed to delete: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to delete assignment (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Delete error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAssignment(
    String assignmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/task-assignments/$assignmentId'; // Use correct endpoint
      print('✏️ Updating assignment: $url');
      print('📦 Updates: $updates');

      final response = await http.put(
        // Use PUT instead of PATCH
        Uri.parse(url),
        headers: headers,
        body: json.encode(updates),
      );

      print('📡 Update Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Assignment updated successfully');
        return data;
      } else {
        print('❌ Failed to update: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to update assignment (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Update error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fetch accounts created by salesman
  Future<Map<String, dynamic>> getSalesmanCreatedAccounts(
    String salesmanId,
  ) async {
    try {
      final headers = _getHeaders();

      // Try the accounts endpoint with createdById filter
      final url = '$baseUrl/accounts?createdById=$salesmanId';
      print('👤 Fetching salesman-created accounts: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> accounts = [];
        if (data['success'] == true && data['data'] != null) {
          accounts = data['data'] as List;
        } else if (data['accounts'] != null) {
          accounts = data['accounts'] as List;
        } else if (data is List) {
          accounts = data;
        }

        print('✅ Fetched ${accounts.length} salesman-created accounts');

        return {'success': true, 'accounts': accounts};
      } else {
        print('❌ Failed to fetch salesman accounts: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to fetch salesman accounts',
          'accounts': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching salesman accounts: $e');
      return {'success': false, 'message': 'Error: $e', 'accounts': []};
    }
  }
}
