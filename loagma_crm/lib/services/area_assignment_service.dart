import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/area_assignment_model.dart';
import '../services/user_service.dart';

class AreaAssignmentService {
  static final String _baseUrl = ApiConfig.baseUrl;

  /// Get area assignments for current salesman
  static Future<List<AreaAssignment>> getSalesmanAreaAssignments() async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('🔍 Loading area assignments for authenticated user');
      print('🔑 Token available: true');
      print('👤 Current user ID: ${UserService.currentUserId}');

      // Use the new endpoint that gets assignments for the authenticated user
      final url = '$_baseUrl/area-assignments/my-assignments';
      print('📡 Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> assignmentsJson = data['assignments'] ?? [];

        print('✅ Loaded ${assignmentsJson.length} area assignments');
        for (int i = 0; i < assignmentsJson.length; i++) {
          final assignment = assignmentsJson[i];
          print(
            '  Assignment ${i + 1}: ${assignment['city']} - ${assignment['pinCode']}',
          );
        }

        return assignmentsJson
            .map((json) => AreaAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load area assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching area assignments: $e');
      throw Exception('Failed to load area assignments: $e');
    }
  }

  /// Get all area assignments (admin only)
  static Future<List<AreaAssignment>> getAllAreaAssignments() async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/area-assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> assignmentsJson = data['assignments'] ?? [];

        return assignmentsJson
            .map((json) => AreaAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load area assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching all area assignments: $e');
      throw Exception('Failed to load area assignments: $e');
    }
  }

  /// Create new area assignment
  static Future<AreaAssignment> createAreaAssignment(
    Map<String, dynamic> assignmentData,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/area-assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(assignmentData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AreaAssignment.fromJson(data['assignment']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to create area assignment',
        );
      }
    } catch (e) {
      print('Error creating area assignment: $e');
      throw Exception('Failed to create area assignment: $e');
    }
  }

  /// Update area assignment
  static Future<AreaAssignment> updateAreaAssignment(
    String assignmentId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/area-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AreaAssignment.fromJson(data['assignment']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to update area assignment',
        );
      }
    } catch (e) {
      print('Error updating area assignment: $e');
      throw Exception('Failed to update area assignment: $e');
    }
  }

  /// Delete area assignment
  static Future<void> deleteAreaAssignment(String assignmentId) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/area-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to delete area assignment',
        );
      }
    } catch (e) {
      print('Error deleting area assignment: $e');
      throw Exception('Failed to delete area assignment: $e');
    }
  }

  /// Get area assignment by ID
  static Future<AreaAssignment?> getAreaAssignmentById(
    String assignmentId,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/area-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AreaAssignment.fromJson(data['assignment']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load area assignment: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching area assignment: $e');
      throw Exception('Failed to load area assignment: $e');
    }
  }

  /// Search area assignments by location
  static Future<List<AreaAssignment>> searchAreaAssignmentsByLocation({
    String? pinCode,
    String? city,
    String? district,
    String? state,
  }) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final queryParams = <String, String>{};
      if (pinCode != null) queryParams['pinCode'] = pinCode;
      if (city != null) queryParams['city'] = city;
      if (district != null) queryParams['district'] = district;
      if (state != null) queryParams['state'] = state;

      final uri = Uri.parse(
        '$_baseUrl/area-assignments/search',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> assignmentsJson = data['assignments'] ?? [];

        return assignmentsJson
            .map((json) => AreaAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to search area assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error searching area assignments: $e');
      throw Exception('Failed to search area assignments: $e');
    }
  }
}
