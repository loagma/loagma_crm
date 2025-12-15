import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/task_assignment_model.dart';
import '../services/user_service.dart';

class TaskAssignmentService {
  static final String _baseUrl = ApiConfig.baseUrl;

  /// Get task assignments for current salesman
  static Future<List<TaskAssignment>> getSalesmanTaskAssignments() async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('🔍 Loading task assignments for authenticated user');
      print('🔑 Token available: true');
      print('👤 Current user ID: ${UserService.currentUserId}');

      // Use the new endpoint that gets assignments for the authenticated user
      final url = '$_baseUrl/task-assignments/my-assignments';
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

        print('✅ Loaded ${assignmentsJson.length} task assignments');
        for (int i = 0; i < assignmentsJson.length; i++) {
          final assignment = assignmentsJson[i];
          print(
            '  Assignment ${i + 1}: ${assignment['city']} - ${assignment['pincode']}',
          );
        }

        return assignmentsJson
            .map((json) => TaskAssignment.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        final data = json.decode(response.body);
        throw Exception(
          'Authentication failed: ${data['message'] ?? 'Invalid token'}',
        );
      } else {
        final data = json.decode(response.body);
        throw Exception(
          'Failed to load task assignments: ${data['message'] ?? 'Server error (${response.statusCode})'}',
        );
      }
    } catch (e) {
      print('Error fetching task assignments: $e');

      // Re-throw authentication errors as-is
      if (e.toString().contains('Authentication failed')) {
        rethrow;
      }

      throw Exception('Failed to load task assignments: $e');
    }
  }

  /// Get all task assignments (admin only)
  static Future<List<TaskAssignment>> getAllTaskAssignments() async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/task-assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> assignmentsJson = data['assignments'] ?? [];

        return assignmentsJson
            .map((json) => TaskAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load task assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching all task assignments: $e');
      throw Exception('Failed to load task assignments: $e');
    }
  }

  /// Create new task assignment
  static Future<TaskAssignment> createTaskAssignment(
    Map<String, dynamic> assignmentData,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/task-assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(assignmentData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TaskAssignment.fromJson(data['assignment']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to create task assignment',
        );
      }
    } catch (e) {
      print('Error creating task assignment: $e');
      throw Exception('Failed to create task assignment: $e');
    }
  }

  /// Update task assignment
  static Future<TaskAssignment> updateTaskAssignment(
    String assignmentId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/task-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaskAssignment.fromJson(data['assignment']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to update task assignment',
        );
      }
    } catch (e) {
      print('Error updating task assignment: $e');
      throw Exception('Failed to update task assignment: $e');
    }
  }

  /// Delete task assignment
  static Future<void> deleteTaskAssignment(String assignmentId) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/task-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to delete task assignment',
        );
      }
    } catch (e) {
      print('Error deleting task assignment: $e');
      throw Exception('Failed to delete task assignment: $e');
    }
  }

  /// Get task assignment by ID
  static Future<TaskAssignment?> getTaskAssignmentById(
    String assignmentId,
  ) async {
    try {
      final token = UserService.token;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/task-assignments/$assignmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaskAssignment.fromJson(data['assignment']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load task assignment: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching task assignment: $e');
      throw Exception('Failed to load task assignment: $e');
    }
  }

  /// Search task assignments by location
  static Future<List<TaskAssignment>> searchTaskAssignmentsByLocation({
    String? pincode,
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
      if (pincode != null) queryParams['pincode'] = pincode;
      if (city != null) queryParams['city'] = city;
      if (district != null) queryParams['district'] = district;
      if (state != null) queryParams['state'] = state;

      final uri = Uri.parse(
        '$_baseUrl/task-assignments/search',
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
            .map((json) => TaskAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to search task assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error searching task assignments: $e');
      throw Exception('Failed to search task assignments: $e');
    }
  }
}
