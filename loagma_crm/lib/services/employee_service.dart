import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class EmployeeService {
  static Future<Map<String, dynamic>> createEmployee({
    String? employeeCode,
    required String name,
    required String email,
    required String contactNumber,
    String? designation,
    String? dateOfBirth,
    String? gender,
    String? nationality,
    String? image,
    String? departmentId,
    String? postUnder,
    String? jobPost,
    String? joiningDate,
    List<String>? preferredLanguages,
    String? jobPostCode,
    String? jobPostName,
    String? inchargeCode,
    String? inchargeName,
    bool? isActive,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/employees'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (employeeCode != null) 'employeeCode': employeeCode,
          'name': name,
          'email': email,
          'contactNumber': contactNumber,
          if (designation != null) 'designation': designation,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (gender != null) 'gender': gender,
          if (nationality != null) 'nationality': nationality,
          if (image != null) 'image': image,
          if (departmentId != null) 'departmentId': departmentId,
          if (postUnder != null) 'postUnder': postUnder,
          if (jobPost != null) 'jobPost': jobPost,
          if (joiningDate != null) 'joiningDate': joiningDate,
          if (preferredLanguages != null)
            'preferredLanguages': preferredLanguages,
          if (jobPostCode != null) 'jobPostCode': jobPostCode,
          if (jobPostName != null) 'jobPostName': jobPostName,
          if (inchargeCode != null) 'inchargeCode': inchargeCode,
          if (inchargeName != null) 'inchargeName': inchargeName,
          if (isActive != null) 'isActive': isActive,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create employee');
      }
    } catch (e) {
      print('Error creating employee: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAllEmployees({
    int page = 1,
    int limit = 50,
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
        '${ApiConfig.baseUrl}/employees',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to load employees');
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to load employee');
    } catch (e) {
      print('Error fetching employee: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update employee');
      }
    } catch (e) {
      print('Error updating employee: $e');
      rethrow;
    }
  }

  static Future<void> deleteEmployee(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete employee');
      }
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }
}
