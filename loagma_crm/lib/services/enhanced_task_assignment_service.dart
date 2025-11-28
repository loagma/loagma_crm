// TODO: Uncomment when backend integration is ready
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_config.dart';

import '../models/salesman_model.dart';
import '../models/location_info_model.dart';
import '../models/area_assignment_model.dart';

class EnhancedTaskAssignmentService {
  /// Fetch all salesmen from the backend
  static Future<List<Salesman>> fetchAllSalesmen() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      return [
        Salesman(
          id: '1',
          name: 'Rajesh Kumar',
          contactNumber: '9876543210',
          employeeCode: 'EMP001',
          email: 'rajesh@example.com',
        ),
        Salesman(
          id: '2',
          name: 'Priya Sharma',
          contactNumber: '9876543211',
          employeeCode: 'EMP002',
          email: 'priya@example.com',
        ),
        Salesman(
          id: '3',
          name: 'Amit Patel',
          contactNumber: '9876543212',
          employeeCode: 'EMP003',
          email: 'amit@example.com',
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

  /// Fetch location details by pin code
  static Future<LocationInfo> fetchLocationByPinCode(String pinCode) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data based on pin code
      if (pinCode.startsWith('4')) {
        return LocationInfo(
          pinCode: pinCode,
          country: 'India',
          state: 'Maharashtra',
          district: 'Mumbai',
          city: 'Mumbai',
          areas: [
            'Andheri East',
            'Andheri West',
            'Bandra',
            'Juhu',
            'Versova',
            'Lokhandwala',
          ],
        );
      } else if (pinCode.startsWith('1')) {
        return LocationInfo(
          pinCode: pinCode,
          country: 'India',
          state: 'Delhi',
          district: 'New Delhi',
          city: 'Delhi',
          areas: [
            'Connaught Place',
            'Karol Bagh',
            'Rajouri Garden',
            'Dwarka',
            'Rohini',
          ],
        );
      } else {
        return LocationInfo(
          pinCode: pinCode,
          country: 'India',
          state: 'Karnataka',
          district: 'Bangalore',
          city: 'Bangalore',
          areas: [
            'Koramangala',
            'Indiranagar',
            'Whitefield',
            'Electronic City',
            'HSR Layout',
          ],
        );
      }

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/location/pincode/$pinCode'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LocationInfo.fromJson(data['location']);
        }
      }
      throw Exception('Failed to fetch location details');
      */
    } catch (e) {
      print('Error fetching location: $e');
      rethrow;
    }
  }

  /// Assign areas to salesman with business types
  static Future<Map<String, dynamic>> assignAreasToSalesman({
    required String salesmanId,
    required String salesmanName,
    required String pinCode,
    required String country,
    required String state,
    required String district,
    required String city,
    required List<String> selectedAreas,
    required List<String> businessTypes,
  }) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'message':
            'Successfully assigned ${selectedAreas.length} areas to $salesmanName',
        'assignment': AreaAssignment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          salesmanId: salesmanId,
          salesmanName: salesmanName,
          pinCode: pinCode,
          country: country,
          state: state,
          district: district,
          city: city,
          areas: selectedAreas,
          businessTypes: businessTypes,
          assignedDate: DateTime.now(),
          totalBusinesses: selectedAreas.length * businessTypes.length * 5,
        ).toJson(),
      };

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments/areas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'salesmanId': salesmanId,
          'salesmanName': salesmanName,
          'pinCode': pinCode,
          'country': country,
          'state': state,
          'district': district,
          'city': city,
          'areas': selectedAreas,
          'businessTypes': businessTypes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to assign areas');
      }
      */
    } catch (e) {
      print('Error assigning areas: $e');
      rethrow;
    }
  }

  /// Fetch all assignments for a salesman
  static Future<List<AreaAssignment>> getAssignmentsBySalesman(
    String salesmanId,
  ) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data
      return [
        AreaAssignment(
          id: '1',
          salesmanId: salesmanId,
          salesmanName: 'Rajesh Kumar',
          pinCode: '400001',
          country: 'India',
          state: 'Maharashtra',
          district: 'Mumbai',
          city: 'Mumbai',
          areas: ['Andheri East', 'Andheri West'],
          businessTypes: ['grocery', 'cafe', 'restaurant'],
          assignedDate: DateTime.now().subtract(const Duration(days: 2)),
          totalBusinesses: 45,
        ),
      ];

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments/salesman/$salesmanId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['assignments'] as List)
              .map((json) => AreaAssignment.fromJson(json))
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

  /// Fetch all businesses in selected areas by business types
  static Future<Map<String, dynamic>> fetchBusinessesByAreaAndType({
    required String pinCode,
    required List<String> areas,
    required List<String> businessTypes,
  }) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data
      final totalBusinesses = areas.length * businessTypes.length * 5;
      return {
        'success': true,
        'totalBusinesses': totalBusinesses,
        'breakdown': {
          for (var type in businessTypes) type: (areas.length * 5).toString(),
        },
        'message': 'Found $totalBusinesses businesses in ${areas.length} areas',
      };

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/businesses/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pinCode': pinCode,
          'areas': areas,
          'businessTypes': businessTypes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch businesses');
      }
      */
    } catch (e) {
      print('Error fetching businesses: $e');
      rethrow;
    }
  }

  /// Remove an assignment
  static Future<Map<String, dynamic>> removeAssignment(
    String assignmentId,
  ) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      return {'success': true, 'message': 'Assignment removed successfully'};

      // TODO: Uncomment when backend is ready
      /*
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments/$assignmentId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to remove assignment');
      }
      */
    } catch (e) {
      print('Error removing assignment: $e');
      rethrow;
    }
  }
}
