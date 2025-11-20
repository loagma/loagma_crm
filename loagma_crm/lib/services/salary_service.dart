import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SalaryService {
  static Future<Map<String, dynamic>> createOrUpdateSalary(
      Map<String, dynamic> salaryData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/salaries'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(salaryData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save salary information'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSalaryByEmployeeId(
      String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/salaries/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Salary information not found'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllSalaries({
    String? departmentId,
    bool? isActive,
    double? minSalary,
    double? maxSalary,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (departmentId != null) queryParams['departmentId'] = departmentId;
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (minSalary != null) queryParams['minSalary'] = minSalary.toString();
      if (maxSalary != null) queryParams['maxSalary'] = maxSalary.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${ApiConfig.baseUrl}/salaries')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch salaries'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSalaryStatistics(
      {String? departmentId}) async {
    try {
      final queryParams = <String, String>{};
      if (departmentId != null) queryParams['departmentId'] = departmentId;

      final uri = Uri.parse('${ApiConfig.baseUrl}/salaries/statistics')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteSalary(String employeeId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/salaries/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete salary information'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
