// TODO: Uncomment when backend integration is ready
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_config.dart';

import '../models/salesman_model.dart';
import '../models/pincode_assignment_model.dart';

class TaskAssignmentService {
  /// Fetch all salesmen from the backend
  /// TODO: Replace with actual API endpoint when backend is ready
  static Future<List<Salesman>> fetchSalesmen() async {
    try {
      // Placeholder: Mock data for now
      await Future.delayed(const Duration(seconds: 1));

      // Mock salesmen data
      return [
        Salesman(
          id: '1',
          name: 'Rajesh Kumar',
          contactNumber: '9876543210',
          employeeCode: 'EMP001',
          email: 'rajesh@example.com',
          assignedPinCodes: ['400001', '400002'],
        ),
        Salesman(
          id: '2',
          name: 'Priya Sharma',
          contactNumber: '9876543211',
          employeeCode: 'EMP002',
          email: 'priya@example.com',
          assignedPinCodes: ['400003'],
        ),
        Salesman(
          id: '3',
          name: 'Amit Patel',
          contactNumber: '9876543212',
          employeeCode: 'EMP003',
          email: 'amit@example.com',
          assignedPinCodes: [],
        ),
      ];

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/salesmen'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['salesmen'] as List)
              .map((json) => Salesman.fromJson(json))
              .toList();
        }
      }
      throw Exception('Failed to fetch salesmen');
      */
    } catch (e) {
      print('Error fetching salesmen: $e');
      rethrow;
    }
  }

  /// Assign a pin code to a salesman
  /// TODO: Replace with actual API endpoint when backend is ready
  static Future<Map<String, dynamic>> assignPinCodeToSalesman({
    required String salesmanId,
    required String salesmanName,
    required String pinCode,
  }) async {
    try {
      // Placeholder: Mock assignment for now
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'message': 'Pin code $pinCode assigned to $salesmanName successfully',
        'assignment': PinCodeAssignment(
          salesmanId: salesmanId,
          salesmanName: salesmanName,
          pinCode: pinCode,
          assignedDate: DateTime.now(),
        ).toJson(),
      };

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'salesmanId': salesmanId,
          'salesmanName': salesmanName,
          'pinCode': pinCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to assign pin code');
      }
      */
    } catch (e) {
      print('Error assigning pin code: $e');
      rethrow;
    }
  }

  /// Get all assignments for a specific salesman
  static Future<List<PinCodeAssignment>> getAssignmentsBySalesman(
    String salesmanId,
  ) async {
    try {
      // Placeholder: Mock data for now
      await Future.delayed(const Duration(milliseconds: 300));

      return [];

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments/salesman/$salesmanId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['assignments'] as List)
              .map((json) => PinCodeAssignment.fromJson(json))
              .toList();
        }
      }
      throw Exception('Failed to fetch assignments');
      */
    } catch (e) {
      print('Error fetching assignments: $e');
      rethrow;
    }
  }

  /// Remove a pin code assignment
  static Future<Map<String, dynamic>> removePinCodeAssignment({
    required String salesmanId,
    required String pinCode,
  }) async {
    try {
      // Placeholder: Mock removal for now
      await Future.delayed(const Duration(milliseconds: 300));

      return {
        'success': true,
        'message': 'Pin code $pinCode removed successfully',
      };

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/task-assignments/$salesmanId/$pinCode',
        ),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to remove pin code');
      }
      */
    } catch (e) {
      print('Error removing pin code: $e');
      rethrow;
    }
  }
}
