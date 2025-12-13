import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

import '../models/salesman_model.dart';
import '../models/location_info_model.dart';
import '../models/area_assignment_model.dart';

class EnhancedTaskAssignmentService {
  /// Fetch all salesmen from the backend
  static Future<List<Salesman>> fetchAllSalesmen() async {
    try {
      print('🔍 Fetching salesmen from API...');
      print('🔑 Token: ${UserService.token != null ? "Available" : "NULL"}');
      print('🌐 URL: ${ApiConfig.baseUrl}/users/get-all');

      // Use users endpoint and filter salesmen on client side
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/get-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserService.token}',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usersJson = data['data'] ?? [];
          print('👥 Total users found: ${usersJson.length}');

          // Filter salesmen on client side
          final salesmenJson = usersJson.where((user) {
            // Check roleId = 'R002' (salesman role ID)
            if (user['roleId'] == 'R002') return true;

            // Check role.name = 'salesman'
            if (user['role'] != null && user['role']['name'] == 'salesman')
              return true;

            // Check roles array contains 'salesman' or 'R002'
            if (user['roles'] != null && user['roles'] is List) {
              final roles = (user['roles'] as List)
                  .map((r) => r.toString().toLowerCase())
                  .toList();
              if (roles.contains('salesman') || roles.contains('r002'))
                return true;
            }

            return false;
          }).toList();

          print('👨‍💼 Salesmen found: ${salesmenJson.length}');

          // Debug: Print all salesmen
          for (var salesman in salesmenJson) {
            print(
              '   Salesman: ${salesman['id']} | ${salesman['name']} | ${salesman['contactNumber']}',
            );
          }

          // Convert to Salesman objects
          final salesmen = salesmenJson
              .map(
                (salesman) => Salesman(
                  id: salesman['id'] ?? '',
                  name: salesman['name'] ?? 'Unknown',
                  contactNumber: salesman['contactNumber'] ?? '',
                  employeeCode: salesman['employeeCode'] ?? '',
                  email: salesman['email'] ?? '',
                ),
              )
              .toList();

          return salesmen;
        } else {
          print('❌ API returned success: false');
          throw Exception('API returned success: false');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Error Body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching salesmen: $e');
      throw Exception('Failed to fetch salesmen: $e');
    }
  }

  /// Fetch location details by pin code
  static Future<LocationInfo> fetchLocationByPinCode(String pinCode) async {
    try {
      print('🔍 Fetching location for pincode: $pinCode');

      // Make actual API call to pincode endpoint
      final url = '${ApiConfig.baseUrl}/pincode/$pinCode';
      print('📡 API URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final locationData = data['data'];

          // Get areas from the main response (now includes all areas)
          List<String> areas = [];
          if (locationData['areas'] != null) {
            areas = (locationData['areas'] as List).cast<String>();
          }

          // If no areas found, add a default area
          if (areas.isEmpty) {
            areas = [locationData['area'] ?? 'Main Area'];
          }

          print(
            '✅ Location data: ${locationData['city']}, ${locationData['state']}',
          );
          print('✅ Areas found: ${areas.length}');

          return LocationInfo(
            pinCode: pinCode,
            country: locationData['country'] ?? 'India',
            state: locationData['state'] ?? '',
            district: locationData['district'] ?? '',
            city: locationData['city'] ?? '',
            areas: areas,
          );
        }
      }

      // If API fails, throw an exception
      throw Exception('Failed to fetch location data for pincode $pinCode');
    } catch (e) {
      print('❌ Error fetching location: $e');

      // Fallback to mock data for common pincodes
      if (pinCode.startsWith('4')) {
        print('🔄 Using fallback data for Maharashtra pincode');
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
        print('🔄 Using fallback data for Delhi pincode');
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
        print('🔄 Using fallback data for other pincode');
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
      final requestBody = {
        'salesmanId': salesmanId,
        'salesmanName': salesmanName,
        'pincode': pinCode, // Note: TaskAssignment uses 'pincode' (lowercase)
        'country': country,
        'state': state,
        'district': district,
        'city': city,
        'areas': selectedAreas,
        'businessTypes': businessTypes,
        'totalBusinesses': selectedAreas.length * businessTypes.length * 5,
      };

      print('� Assignin g areas to salesman...');
      print('📡 API URL: ${ApiConfig.baseUrl}/task-assignments');
      print('🔑 Token: ${UserService.token != null ? "Available" : "Missing"}');
      print('📦 Request body: ${jsonEncode(requestBody)}');

      // Use real API call to create task assignment
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/task-assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserService.token}',
        },
        body: jsonEncode(requestBody),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Area assignment successful!');
        return {
          'success': true,
          'message':
              'Successfully assigned ${selectedAreas.length} areas to $salesmanName',
          'assignment': data['assignment'],
        };
      } else {
        print('❌ Area assignment failed: ${data['message']}');
        throw Exception(data['message'] ?? 'Failed to assign areas');
      }
    } catch (e) {
      print('❌ Error assigning areas: $e');
      throw Exception('Failed to assign areas: $e');
    }

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
