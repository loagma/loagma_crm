import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service for handling salesman route tracking functionality
/// Manages GPS point storage and route data retrieval for Admin visualization
class RouteService {
  /// Store GPS route point during active attendance session
  /// Called every 20-30 seconds by Salesman app while attendance is active
  ///
  /// Parameters:
  /// - employeeId: ID of the salesman
  /// - attendanceId: ID of the active attendance session
  /// - latitude: GPS latitude coordinate
  /// - longitude: GPS longitude coordinate
  /// - speed: Optional speed in km/h
  /// - accuracy: Optional GPS accuracy in meters
  static Future<Map<String, dynamic>> storeRoutePoint({
    required String employeeId,
    required String attendanceId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
  }) async {
    try {
      // Validate GPS coordinates before sending
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return {'success': false, 'message': 'Invalid GPS coordinates'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/routes/point');

      final body = {
        'employeeId': employeeId,
        'attendanceId': attendanceId,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Add optional parameters if available
      if (speed != null) body['speed'] = speed;
      if (accuracy != null) body['accuracy'] = accuracy;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to store route point',
        };
      }
    } catch (e) {
      print('❌ RouteService.storeRoutePoint error: $e');
      return {
        'success': false,
        'message': 'Network error while storing route point',
      };
    }
  }

  /// Fetch complete route data for a specific attendance session
  /// Used by Admin to display route visualization and playback
  ///
  /// Parameters:
  /// - attendanceId: ID of the attendance session
  ///
  /// Returns:
  /// - Complete route data with start/end points and GPS trail
  static Future<Map<String, dynamic>> getAttendanceRoute(
    String attendanceId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/routes/attendance/$attendanceId',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch route data',
        };
      }
    } catch (e) {
      print('❌ RouteService.getAttendanceRoute error: $e');
      return {
        'success': false,
        'message': 'Network error while fetching route data',
      };
    }
  }

  /// Get route summary for multiple attendance sessions
  /// Used by Admin dashboard for route overview and statistics
  ///
  /// Parameters:
  /// - employeeId: Optional filter by specific employee
  /// - startDate: Optional start date filter
  /// - endDate: Optional end date filter
  /// - limit: Maximum number of records to return (default: 50)
  static Future<Map<String, dynamic>> getRouteSummary({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};

      if (employeeId != null) queryParams['employeeId'] = employeeId;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/routes/summary',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch route summary',
        };
      }
    } catch (e) {
      print('❌ RouteService.getRouteSummary error: $e');
      return {
        'success': false,
        'message': 'Network error while fetching route summary',
      };
    }
  }

  /// Calculate distance between two GPS points using Haversine formula
  /// Used for distance calculations in route analysis and graphs
  ///
  /// Parameters:
  /// - lat1, lon1: First GPS coordinate
  /// - lat2, lon2: Second GPS coordinate
  ///
  /// Returns:
  /// - Distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Calculate total distance for a route
  /// Sums up distances between consecutive GPS points
  ///
  /// Parameters:
  /// - routePoints: List of GPS coordinates with latitude/longitude
  ///
  /// Returns:
  /// - Total distance in kilometers
  static double calculateTotalDistance(List<Map<String, dynamic>> routePoints) {
    if (routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;

    for (int i = 1; i < routePoints.length; i++) {
      final prev = routePoints[i - 1];
      final current = routePoints[i];

      final distance = calculateDistance(
        prev['latitude'].toDouble(),
        prev['longitude'].toDouble(),
        current['latitude'].toDouble(),
        current['longitude'].toDouble(),
      );

      totalDistance += distance;
    }

    return totalDistance;
  }

  /// Validate GPS coordinates
  /// Checks if coordinates are within valid ranges
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Check if two GPS points are significantly different
  /// Used to avoid storing duplicate or very close points
  ///
  /// Parameters:
  /// - lat1, lon1: First GPS coordinate
  /// - lat2, lon2: Second GPS coordinate
  /// - threshold: Minimum distance in meters (default: 10m)
  static bool isSignificantMovement(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double threshold = 10.0,
  }) {
    final distance =
        calculateDistance(lat1, lon1, lat2, lon2) * 1000; // Convert to meters
    return distance >= threshold;
  }
}
