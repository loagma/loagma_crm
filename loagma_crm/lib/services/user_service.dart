import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class UserService {
  static Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 1000,
    String? departmentId,
    bool? isActive,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (departmentId != null) 'departmentId': departmentId,
        if (isActive != null) 'isActive': isActive.toString(),
        if (search != null) 'search': search,
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/users',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to load users');
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to load user');
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }
}
