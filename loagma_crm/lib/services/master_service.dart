import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MasterService {
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/masters/departments'),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load departments');
    } catch (e) {
      print('Error fetching departments: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getFunctionalRoles({
    String? departmentId,
  }) async {
    try {
      final uri = departmentId != null
          ? Uri.parse(
              '${ApiConfig.baseUrl}/masters/functional-roles',
            ).replace(queryParameters: {'departmentId': departmentId})
          : Uri.parse('${ApiConfig.baseUrl}/masters/functional-roles');

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load functional roles');
    } catch (e) {
      print('Error fetching functional roles: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/masters/roles'),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load roles');
    } catch (e) {
      print('Error fetching roles: $e');
      rethrow;
    }
  }
}
