import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import 'api_config.dart';

class AccountService {
  // Get auth token from shared preferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get user ID from shared preferences
  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== CREATE ====================

  static Future<Account> createAccount({
    String? businessName,
    required String personName,
    required String contactNumber,
    String? businessType,
    String? businessSize,
    String? dateOfBirth,
    String? customerStage,
    String? funnelStage,
    String? gstNumber,
    String? panCard,
    String? ownerImage,
    String? shopImage,
    bool? isActive,
    String? pincode,
    String? country,
    String? state,
    String? district,
    String? city,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    String? assignedToId,
    int? areaId,
  }) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(ApiConfig.accountsUrl),
        headers: headers,
        body: json.encode({
          if (businessName != null) 'businessName': businessName,
          'personName': personName,
          'contactNumber': contactNumber,
          if (businessType != null) 'businessType': businessType,
          if (businessSize != null) 'businessSize': businessSize,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (customerStage != null) 'customerStage': customerStage,
          if (funnelStage != null) 'funnelStage': funnelStage,
          if (gstNumber != null) 'gstNumber': gstNumber,
          if (panCard != null) 'panCard': panCard,
          if (ownerImage != null) 'ownerImage': ownerImage,
          if (shopImage != null) 'shopImage': shopImage,
          if (isActive != null) 'isActive': isActive,
          if (pincode != null) 'pincode': pincode,
          if (country != null) 'country': country,
          if (state != null) 'state': state,
          if (district != null) 'district': district,
          if (city != null) 'city': city,
          if (area != null) 'area': area,
          if (address != null) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (assignedToId != null) 'assignedToId': assignedToId,
          if (areaId != null) 'areaId': areaId,
          if (userId != null) 'createdById': userId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  static Future<Map<String, dynamic>> fetchAccounts({
    int page = 1,
    int limit = 50,
    String? areaId,
    String? assignedToId,
    String? customerStage,
    String? funnelStage,
    bool? isApproved,
    String? createdById,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (areaId != null) 'areaId': areaId,
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (customerStage != null) 'customerStage': customerStage,
        if (funnelStage != null) 'funnelStage': funnelStage,
        if (isApproved != null) 'isApproved': isApproved.toString(),
        if (createdById != null) 'createdById': createdById,
        if (search != null) 'search': search,
      };

      final uri = Uri.parse(
        ApiConfig.accountsUrl,
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'accounts': (data['data'] as List)
              .map((json) => Account.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      }
      throw Exception('Failed to load accounts');
    } catch (e) {
      print('Error fetching accounts: $e');
      rethrow;
    }
  }

  static Future<Account> fetchAccountById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      }
      throw Exception('Failed to load account');
    } catch (e) {
      print('Error fetching account: $e');
      rethrow;
    }
  }

  // ==================== UPDATE ====================

  static Future<Account> updateAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update account');
      }
    } catch (e) {
      print('Error updating account: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteAccount(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // ==================== APPROVAL ====================

  static Future<Account> approveAccount(String id) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/$id/approve'),
        headers: headers,
        body: json.encode({if (userId != null) 'approvedById': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve account');
      }
    } catch (e) {
      print('Error approving account: $e');
      rethrow;
    }
  }

  static Future<Account> rejectAccount(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/$id/reject'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject account');
      }
    } catch (e) {
      print('Error rejecting account: $e');
      rethrow;
    }
  }

  // ==================== STATISTICS ====================

  static Future<Map<String, dynamic>> getAccountStats({
    String? assignedToId,
    String? areaId,
    String? createdById,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (areaId != null) 'areaId': areaId,
        if (createdById != null) 'createdById': createdById,
      };

      final uri = Uri.parse(
        '${ApiConfig.accountsUrl}/stats',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load account stats');
    } catch (e) {
      print('Error fetching account stats: $e');
      rethrow;
    }
  }

  // ==================== BULK OPERATIONS ====================

  static Future<int> bulkAssignAccounts({
    required List<String> accountIds,
    required String assignedToId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/bulk/assign'),
        headers: headers,
        body: json.encode({
          'accountIds': accountIds,
          'assignedToId': assignedToId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to assign accounts');
      }
    } catch (e) {
      print('Error bulk assigning accounts: $e');
      rethrow;
    }
  }

  static Future<int> bulkApproveAccounts({
    required List<String> accountIds,
  }) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/bulk/approve'),
        headers: headers,
        body: json.encode({
          'accountIds': accountIds,
          if (userId != null) 'approvedById': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve accounts');
      }
    } catch (e) {
      print('Error bulk approving accounts: $e');
      rethrow;
    }
  }

  // ==================== CHECK CONTACT NUMBER ====================

  static Future<Map<String, dynamic>> checkContactNumber(
    String contactNumber,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/check-contact'),
        headers: headers,
        body: json.encode({'contactNumber': contactNumber}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to check contact number');
      }
    } catch (e) {
      print('Error checking contact number: $e');
      rethrow;
    }
  }
}
