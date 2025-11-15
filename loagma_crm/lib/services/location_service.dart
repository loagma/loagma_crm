import 'api_service.dart';
import '../models/location_models.dart' as models;

class LocationService {
  // Country - Map version for forms
  static Future<List<Map<String, dynamic>>> getCountries() async {
    final response = await ApiService.get('/locations/countries');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load countries');
  }

  // Country - Typed version for dashboard
  static Future<List<models.Country>> fetchCountries() async {
    final response = await ApiService.get('/locations/countries');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.Country.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load countries');
  }

  // State - Map version
  static Future<List<Map<String, dynamic>>> getStates({int? countryId}) async {
    String url = '/locations/states';
    if (countryId != null) {
      url += '?country_id=$countryId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load states');
  }

  // State - Typed version
  static Future<List<models.State>> fetchStates(int countryId) async {
    final response = await ApiService.get(
      '/locations/states?country_id=$countryId',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.State.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load states');
  }

  // Region - Map version
  static Future<List<Map<String, dynamic>>> getRegions({int? stateId}) async {
    String url = '/locations/regions';
    if (stateId != null) {
      url += '?state_id=$stateId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load regions');
  }

  // Region - Typed version
  static Future<List<models.Region>> fetchRegions(int stateId) async {
    final response = await ApiService.get(
      '/locations/regions?state_id=$stateId',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.Region.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load regions');
  }

  // District - Map version
  static Future<List<Map<String, dynamic>>> getDistricts({
    int? regionId,
  }) async {
    String url = '/locations/districts';
    if (regionId != null) {
      url += '?region_id=$regionId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load districts');
  }

  // District - Typed version
  static Future<List<models.District>> fetchDistricts(int regionId) async {
    final response = await ApiService.get(
      '/locations/districts?region_id=$regionId',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.District.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load districts');
  }

  // City - Map version
  static Future<List<Map<String, dynamic>>> getCities({int? districtId}) async {
    String url = '/locations/cities';
    if (districtId != null) {
      url += '?district_id=$districtId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load cities');
  }

  // City - Typed version
  static Future<List<models.City>> fetchCities(int districtId) async {
    final response = await ApiService.get(
      '/locations/cities?district_id=$districtId',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.City.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load cities');
  }

  // Zone - Map version
  static Future<List<Map<String, dynamic>>> getZones({int? cityId}) async {
    String url = '/locations/zones';
    if (cityId != null) {
      url += '?city_id=$cityId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load zones');
  }

  // Zone - Typed version
  static Future<List<models.Zone>> fetchZones(int cityId) async {
    final response = await ApiService.get('/locations/zones?city_id=$cityId');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.Zone.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load zones');
  }

  // Area - Map version
  static Future<List<Map<String, dynamic>>> getAreas({int? zoneId}) async {
    String url = '/locations/areas';
    if (zoneId != null) {
      url += '?zone_id=$zoneId';
    }
    final response = await ApiService.get(url);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load areas');
  }

  // Area - Typed version
  static Future<List<models.Area>> fetchAreas(int zoneId) async {
    final response = await ApiService.get('/locations/areas?zone_id=$zoneId');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => models.Area.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load areas');
  }
}
