import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/shop_model.dart';
import '../services/user_service.dart';

class MapTaskAssignmentService {
  final String baseUrl = ApiConfig.baseUrl;

  // Constructor to initialize Google Places service
  MapTaskAssignmentService() {
    try {
      // GooglePlacesService is now static, no initialization needed
    } catch (e) {
      print('⚠️ Google Places service initialization failed: $e');
    }
  }

  // Get headers with auth token from UserService
  static Map<String, String> _getHeaders() {
    final token = UserService.token;
    print(
      '🔑 UserService.token: ${token != null ? "Available (${token.substring(0, 20)}...)" : "NULL"}',
    );
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> fetchSalesmen() async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/users/salesmen'; // Use the correct salesmen endpoint
      print('🔍 Fetching salesmen from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Salesmen data: $data');
        return data;
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to fetch salesmen (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error fetching salesmen: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchLocationByPincode(String pincode) async {
    try {
      final headers = _getHeaders();
      final url = '$baseUrl/pincode/$pincode';

      print('🔍 Fetching location for pincode: $pincode');
      print('📡 URL: $url');
      print('🔑 Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Location data received: $data');

        // Ensure the response has the expected structure
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          return {
            'success': false,
            'message': 'Invalid response format from server',
          };
        }
      } else if (response.statusCode == 401) {
        // Try without authentication for pincode lookup
        print('🔄 Retrying without authentication...');
        final responseNoAuth = await http.get(Uri.parse(url));

        print('📊 No-auth response status: ${responseNoAuth.statusCode}');
        print('📊 No-auth response body: ${responseNoAuth.body}');

        if (responseNoAuth.statusCode == 200) {
          final data = json.decode(responseNoAuth.body);
          print('✅ Location data received (no auth): $data');

          // Ensure the response has the expected structure
          if (data['success'] == true && data['data'] != null) {
            return data;
          } else {
            return {
              'success': false,
              'message': 'Invalid response format from server',
            };
          }
        }
      }

      print('❌ Failed to fetch location: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Failed to fetch location (Status: ${response.statusCode})',
      };
    } catch (e) {
      print('❌ Error fetching location: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> assignAreasToSalesman(
    String salesmanId,
    String salesmanName,
    String pincode,
    String country,
    String state,
    String district,
    String city,
    List<String> areas,
    List<String> businessTypes, {
    int totalBusinesses = 0,
  }) async {
    try {
      final headers = _getHeaders();
      final url = '$baseUrl/task-assignments'; // Use the correct endpoint
      final payload = {
        'salesmanId': salesmanId,
        'salesmanName': salesmanName,
        'pincode': pincode,
        'country': country,
        'state': state,
        'district': district,
        'city': city,
        'areas': areas,
        'businessTypes': businessTypes,
        'totalBusinesses': totalBusinesses,
      };

      print('🌐 API Call: POST $url');
      print('📦 Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(payload),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Assignment API Success: $data');
        return data;
      } else {
        print(
          '❌ Assignment API Failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'message': 'Failed to assign areas (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Assignment API Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAssignmentsBySalesman(
    String salesmanId,
  ) async {
    try {
      final headers = _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/task-assignments/salesman/$salesmanId',
        ), // Use correct endpoint
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch assignments'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> searchBusinesses(
    String pincode,
    List<String> areas,
    List<String> businessTypes,
  ) async {
    print(
      '🔍 Searching businesses for pincode: $pincode, areas: $areas, types: $businessTypes',
    );

    // For now, let's use mock data to ensure the app works
    // TODO: Re-enable Google Places API after debugging
    print('🔄 Using mock data for testing...');
    return _generateMockBusinesses(pincode, areas, businessTypes);

    /* 
    // Google Places API implementation (temporarily disabled for debugging)
    try {
      // First, get location coordinates for the pincode
      final locationResult = await fetchLocationByPincode(pincode);
      if (locationResult['success'] != true) {
        print('❌ Failed to get location for pincode');
        return _generateMockBusinesses(pincode, areas, businessTypes);
      }

      final locationData = locationResult['data'];
      final city = locationData['city'];
      final state = locationData['state'];
      print('📍 Location: $city, $state');

      // Use Google Places to search for businesses
      final GooglePlacesService placesService = GooglePlacesService.instance;
      List<Map<String, dynamic>> allBusinesses = [];
      Map<String, int> breakdown = {};

      // Search for each business type in each area
      for (String businessType in businessTypes) {
        int typeCount = 0;

        // Map business types to Google Places types
        String googlePlaceType = _mapBusinessTypeToGoogleType(businessType);
        print('🔄 Mapped $businessType -> $googlePlaceType');

        for (String area in areas.isEmpty ? [city] : areas) {
          try {
            // Search by text query combining area, city and business type
            String searchQuery = '$googlePlaceType in $area, $city, $state';
            print('🔍 Searching: $searchQuery');

            final places = await placesService.searchPlacesByText(
              query: searchQuery,
            );

            print('📊 Found ${places.length} places for $searchQuery');

            // Convert places to business format
            for (var place in places.take(10)) {
              // Limit to 10 per area/type
              if (place.name != null && place.geometry?.location != null) {
                print('✅ Adding business: ${place.name}');
                final business = {
                  'placeId': place.placeId ?? '',
                  'name': place.name!,
                  'businessType': businessType,
                  'rating': place.rating?.toDouble() ?? 0.0,
                  'address': place.formattedAddress ?? '$area, $city',
                  'latitude': place.geometry!.location!.lat,
                  'longitude': place.geometry!.location!.lng,
                  'area': area,
                  'pincode': pincode,
                  'stage': 'new', // Default stage
                  'photos': place.photos?.isNotEmpty == true
                      ? [
                          place.mainPhotoUrl,
                        ].where((url) => url != null).toList()
                      : [],
                  'types': place.types ?? [],
                  'priceLevel': place.priceLevel ?? 0,
                  'openNow': place.isOpenNow,
                };

                allBusinesses.add(business);
                typeCount++;
              }
            }
          } catch (e) {
            print('❌ Error searching for $businessType in $area: $e');
          }
        }

        breakdown[businessType] = typeCount;
        print('✅ Found $typeCount businesses for $businessType');
      }

      print('✅ Total businesses found: ${allBusinesses.length}');

      if (allBusinesses.isEmpty) {
        print('🔄 No businesses found via API, using mock data...');
        return _generateMockBusinesses(pincode, areas, businessTypes);
      }

      return {
        'success': true,
        'businesses': allBusinesses,
        'totalBusinesses': allBusinesses.length,
        'breakdown': breakdown,
        'message': 'Found ${allBusinesses.length} businesses',
      };
    } catch (e) {
      print('❌ Error searching businesses: $e');

      // Fallback to mock data if Google Places fails
      print('🔄 Using fallback mock data...');
      return _generateMockBusinesses(pincode, areas, businessTypes);
    }
    */
  }

  // Generate mock businesses as fallback
  Map<String, dynamic> _generateMockBusinesses(
    String pincode,
    List<String> areas,
    List<String> businessTypes,
  ) {
    print('🎭 Generating mock businesses for:');
    print('   Pincode: $pincode');
    print('   Areas: $areas');
    print('   Business Types: $businessTypes');

    List<Map<String, dynamic>> mockBusinesses = [];
    Map<String, int> breakdown = {};

    // Mock coordinates for Jabalpur area (482004)
    double baseLat = 23.1815; // Jabalpur latitude
    double baseLng = 79.9864; // Jabalpur longitude

    for (String businessType in businessTypes) {
      int typeCount = 0;

      for (String area in areas.isEmpty ? ['Main Area'] : areas) {
        // Generate 3-5 mock businesses per type per area
        int businessCount = 3 + (businessType.hashCode % 3);

        for (int i = 0; i < businessCount; i++) {
          final businessName = _generateMockBusinessName(businessType, i);
          print('   📍 Creating: $businessName ($businessType in $area)');

          final business = {
            'placeId': 'mock_${businessType}_${area}_$i',
            'name': businessName,
            'businessType': businessType,
            'rating': 3.5 + (i * 0.3),
            'address': '$area, $pincode',
            'latitude':
                baseLat + (i * 0.001) + (businessType.hashCode % 100) * 0.0001,
            'longitude': baseLng + (i * 0.001) + (area.hashCode % 100) * 0.0001,
            'area': area,
            'pincode': pincode,
            'stage': 'new',
            'photos': [],
            'types': [businessType],
            'priceLevel': 1 + (i % 3),
            'openNow': i % 2 == 0,
          };

          mockBusinesses.add(business);
          typeCount++;
        }
      }

      breakdown[businessType] = typeCount;
      print('   ✅ Generated $typeCount businesses for $businessType');
    }

    print(
      '🎭 Mock generation complete: ${mockBusinesses.length} total businesses',
    );
    print('   Breakdown: $breakdown');

    return {
      'success': true,
      'businesses': mockBusinesses,
      'totalBusinesses': mockBusinesses.length,
      'breakdown': breakdown,
      'message': 'Found ${mockBusinesses.length} businesses (mock data)',
    };
  }

  String _generateMockBusinessName(String businessType, int index) {
    Map<String, List<String>> nameTemplates = {
      'kirana': [
        'Sharma General Store',
        'Patel Kirana',
        'Gupta Store',
        'Local Mart',
        'Family Store',
      ],
      'pharmacy': [
        'Apollo Pharmacy',
        'MedPlus',
        'City Medical',
        'Health Care',
        'Wellness Pharmacy',
      ],
      'schools': [
        'St. Mary School',
        'Government School',
        'Little Angels',
        'Bright Future School',
        'Knowledge Hub',
      ],
      'cafe': [
        'Coffee Corner',
        'Tea Time',
        'Brew House',
        'Cafe Delight',
        'Morning Fresh',
      ],
      'restaurant': [
        'Tasty Bites',
        'Food Palace',
        'Spice Garden',
        'Royal Dining',
        'Home Kitchen',
      ],
      'bakery': [
        'Fresh Bread',
        'Sweet Corner',
        'Cake Shop',
        'Bakery House',
        'Daily Bread',
      ],
      'hotel': [
        'Hotel Comfort',
        'Stay Inn',
        'Royal Lodge',
        'City Hotel',
        'Traveler Rest',
      ],
      'supermarket': [
        'Big Bazaar',
        'Super Market',
        'Mega Store',
        'Shopping Center',
        'Retail Hub',
      ],
      'hospitals': [
        'City Hospital',
        'Apollo Hospital',
        'Max Healthcare',
        'Fortis Hospital',
        'AIIMS',
        'Government Hospital',
        'Care Hospital',
      ],
      'colleges': [
        'Government College',
        'Engineering College',
        'Medical College',
        'Arts College',
        'Commerce College',
      ],
      'hostel': [
        'Student Hostel',
        'PG Accommodation',
        'Boys Hostel',
        'Girls Hostel',
        'Working Hostel',
      ],
      'others': [
        'General Store',
        'Local Shop',
        'Service Center',
        'Business Center',
        'Commercial Hub',
      ],
    };

    List<String> names =
        nameTemplates[businessType.toLowerCase()] ??
        nameTemplates['others'] ??
        ['${businessType.toUpperCase()} ${index + 1}'];
    return names[index % names.length];
  }

  // Map business types to Google Places types
  String _mapBusinessTypeToGoogleType(String businessType) {
    switch (businessType.toLowerCase()) {
      case 'kirana':
      case 'grocery':
        return 'grocery store';
      case 'cafe':
        return 'cafe';
      case 'hotel':
        return 'lodging';
      case 'dairy':
        return 'store dairy';
      case 'restaurant':
        return 'restaurant';
      case 'bakery':
        return 'bakery';
      case 'pharmacy':
        return 'pharmacy';
      case 'supermarket':
        return 'supermarket';
      case 'hostel':
        return 'lodging hostel';
      case 'schools':
        return 'school';
      case 'colleges':
        return 'university';
      case 'hospitals':
        return 'hospital';
      case 'others':
        return 'store';
      default:
        return businessType;
    }
  }

  Future<Map<String, dynamic>> saveShops(
    List<Shop> shops,
    String salesmanId,
  ) async {
    try {
      // For now, return success since we don't have a shops endpoint in task-assignments
      print('💾 Would save ${shops.length} shops for salesman: $salesmanId');

      return {
        'success': true,
        'message': 'Shops saved successfully (mock)',
        'savedCount': shops.length,
      };
    } catch (e) {
      print('❌ Save shops error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getShopsBySalesman(String salesmanId) async {
    try {
      // Return empty shops list for now
      print('🏪 Getting shops for salesman: $salesmanId');

      return {'success': true, 'shops': [], 'message': 'No shops found'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateShopStage(
    String shopId,
    String stage,
  ) async {
    try {
      print('🏪 Updating shop $shopId stage to: $stage');

      return {
        'success': true,
        'message': 'Shop stage updated successfully (mock)',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/task-assignments/$assignmentId'; // Use correct endpoint
      print('🗑️ Deleting assignment: $url');

      final response = await http.delete(Uri.parse(url), headers: headers);

      print('📡 Delete Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Assignment deleted successfully');
        return data;
      } else {
        print('❌ Failed to delete: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to delete assignment (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Delete error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAssignment(
    String assignmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = _getHeaders();
      final url =
          '$baseUrl/task-assignments/$assignmentId'; // Use correct endpoint
      print('✏️ Updating assignment: $url');
      print('📦 Updates: $updates');

      final response = await http.put(
        // Use PUT instead of PATCH
        Uri.parse(url),
        headers: headers,
        body: json.encode(updates),
      );

      print('📡 Update Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Assignment updated successfully');
        return data;
      } else {
        print('❌ Failed to update: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Failed to update assignment (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Update error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fetch accounts created by salesman
  Future<Map<String, dynamic>> getSalesmanCreatedAccounts(
    String salesmanId,
  ) async {
    try {
      final headers = _getHeaders();

      // Try the accounts endpoint with createdById filter
      final url = '$baseUrl/accounts?createdById=$salesmanId';
      print('👤 Fetching salesman-created accounts: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> accounts = [];
        if (data['success'] == true && data['data'] != null) {
          accounts = data['data'] as List;
        } else if (data['accounts'] != null) {
          accounts = data['accounts'] as List;
        } else if (data is List) {
          accounts = data;
        }

        print('✅ Fetched ${accounts.length} salesman-created accounts');

        return {'success': true, 'accounts': accounts};
      } else {
        print('❌ Failed to fetch salesman accounts: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to fetch salesman accounts',
          'accounts': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching salesman accounts: $e');
      return {'success': false, 'message': 'Error: $e', 'accounts': []};
    }
  }
}
