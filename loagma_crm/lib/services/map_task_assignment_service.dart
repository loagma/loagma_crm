import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../models/shop_model.dart';

class MapTaskAssignmentService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get auth token from shared preferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> fetchSalesmen() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/task-assignments/salesmen';
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-assignments/location/pincode/$pincode'),
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
    List<String> businessTypes,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/task-assignments/assignments/areas'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'salesmanName': salesmanName,
          'pincode': pincode,
          'country': country,
          'state': state,
          'district': district,
          'city': city,
          'areas': areas,
          'businessTypes': businessTypes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to assign areas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAssignmentsBySalesman(
    String salesmanId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-assignments/assignments/salesman/$salesmanId'),
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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/task-assignments/businesses/search'),
        headers: headers,
        body: json.encode({
          'pincode': pincode,
          'areas': areas,
          'businessTypes': businessTypes,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to search businesses'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveShops(
    List<Shop> shops,
    String salesmanId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/task-assignments/shops'),
        headers: headers,
        body: json.encode({
          'shops': shops.map((s) => s.toJson()).toList(),
          'salesmanId': salesmanId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to save shops'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getShopsBySalesman(String salesmanId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-assignments/shops/salesman/$salesmanId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch shops'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateShopStage(
    String shopId,
    String stage,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/task-assignments/shops/$shopId/stage'),
        headers: headers,
        body: json.encode({'stage': stage}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update shop stage'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
