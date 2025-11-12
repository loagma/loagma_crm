import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';
import 'api_config.dart';

class LocationService {
  // Countries
  static Future<List<Country>> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/countries'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Country.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load countries');
    } catch (e) {
      print('Error fetching countries: $e');
      rethrow;
    }
  }

  // States
  static Future<List<State>> fetchStates(int countryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/states?countryId=$countryId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => State.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load states');
    } catch (e) {
      print('Error fetching states: $e');
      rethrow;
    }
  }

  // Districts
  static Future<List<District>> fetchDistricts(int stateId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/districts?stateId=$stateId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => District.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load districts');
    } catch (e) {
      print('Error fetching districts: $e');
      rethrow;
    }
  }

  // Cities
  static Future<List<City>> fetchCities(int districtId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/cities?districtId=$districtId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => City.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load cities');
    } catch (e) {
      print('Error fetching cities: $e');
      rethrow;
    }
  }

  // Zones
  static Future<List<Zone>> fetchZones(int cityId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/zones?cityId=$cityId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Zone.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load zones');
    } catch (e) {
      print('Error fetching zones: $e');
      rethrow;
    }
  }

  // Areas
  static Future<List<Area>> fetchAreas(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.locationsUrl}/areas?zoneId=$zoneId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Area.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load areas');
    } catch (e) {
      print('Error fetching areas: $e');
      rethrow;
    }
  }
}
