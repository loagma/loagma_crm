import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account_model.dart';
import 'api_config.dart';

class AccountService {
  // Create Account
  static Future<Account> createAccount({
    required String personName,
    required String contactNumber,
    String? dateOfBirth,
    String? businessType,
    String? customerStage,
    String? funnelStage,
    String? assignedToId,
    int? areaId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.accountsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'personName': personName,
          'contactNumber': contactNumber,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (businessType != null) 'businessType': businessType,
          if (customerStage != null) 'customerStage': customerStage,
          if (funnelStage != null) 'funnelStage': funnelStage,
          if (assignedToId != null) 'assignedToId': assignedToId,
          if (areaId != null) 'areaId': areaId,
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

  // Fetch All Accounts
  static Future<List<Account>> fetchAccounts({
    int page = 1,
    int limit = 50,
    String? areaId,
    String? assignedToId,
    String? customerStage,
    String? funnelStage,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (areaId != null) 'areaId': areaId,
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (customerStage != null) 'customerStage': customerStage,
        if (funnelStage != null) 'funnelStage': funnelStage,
        if (search != null) 'search': search,
      };

      final uri = Uri.parse(ApiConfig.accountsUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Account.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load accounts');
    } catch (e) {
      print('Error fetching accounts: $e');
      rethrow;
    }
  }

  // Fetch Account by ID
  static Future<Account> fetchAccountById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
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

  // Update Account
  static Future<Account> updateAccount(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: {'Content-Type': 'application/json'},
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

  // Delete Account
  static Future<void> deleteAccount(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
