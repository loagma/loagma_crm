import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/beat_plan_model.dart';
import 'api_config.dart';

class BeatPlanService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/beat-plans';

  // Get authentication token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'API request failed');
    }
  }

  /// ========================================
  /// ADMIN METHODS
  /// ========================================

  /// Generate weekly beat plan for a salesman
  static Future<Map<String, dynamic>> generateWeeklyBeatPlan({
    required String salesmanId,
    required DateTime weekStartDate,
    required List<String> pincodes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'salesmanId': salesmanId,
        'weekStartDate': weekStartDate.toIso8601String(),
        'pincodes': pincodes,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: headers,
        body: body,
      );

      final responseData = _handleResponse(response);
      return responseData;
    } catch (e) {
      throw Exception('Failed to generate beat plan: $e');
    }
  }

  /// Get all weekly beat plans (admin view)
  static Future<Map<String, dynamic>> getWeeklyBeatPlans({
    int page = 1,
    int limit = 10,
    String? salesmanId,
    String? status,
    DateTime? weekStartDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (salesmanId != null) 'salesmanId': salesmanId,
        if (status != null) 'status': status,
        if (weekStartDate != null)
          'weekStartDate': weekStartDate.toIso8601String(),
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      final responseData = _handleResponse(response);

      // Parse beat plans
      final beatPlans = (responseData['data'] as List)
          .map((json) => WeeklyBeatPlan.fromJson(json))
          .toList();

      return {'beatPlans': beatPlans, 'pagination': responseData['pagination']};
    } catch (e) {
      throw Exception('Failed to get beat plans: $e');
    }
  }

  /// Update weekly beat plan
  static Future<WeeklyBeatPlan> updateWeeklyBeatPlan({
    required String beatPlanId,
    String? status,
    List<String>? pincodes,
    List<Map<String, dynamic>>? dailyPlans,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        if (status != null) 'status': status,
        if (pincodes != null) 'pincodes': pincodes,
        if (dailyPlans != null) 'dailyPlans': dailyPlans,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/$beatPlanId'),
        headers: headers,
        body: body,
      );

      final responseData = _handleResponse(response);
      return WeeklyBeatPlan.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to update beat plan: $e');
    }
  }

  /// Lock/unlock beat plan
  static Future<WeeklyBeatPlan> toggleBeatPlanLock({
    required String beatPlanId,
    required bool lock,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'lock': lock});

      final response = await http.post(
        Uri.parse('$_baseUrl/$beatPlanId/toggle-lock'),
        headers: headers,
        body: body,
      );

      final responseData = _handleResponse(response);
      return WeeklyBeatPlan.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to ${lock ? 'lock' : 'unlock'} beat plan: $e');
    }
  }

  /// Handle missed beats
  static Future<Map<String, dynamic>> handleMissedBeat({
    required String dailyBeatId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/handle-missed/$dailyBeatId'),
        headers: headers,
      );

      final responseData = _handleResponse(response);
      return responseData['data'];
    } catch (e) {
      throw Exception('Failed to handle missed beat: $e');
    }
  }

  /// Get beat plan analytics
  static Future<Map<String, dynamic>> getBeatPlanAnalytics({
    String? salesmanId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (salesmanId != null) 'salesmanId': salesmanId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse(
        '$_baseUrl/analytics',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      final responseData = _handleResponse(response);
      return responseData['data'];
    } catch (e) {
      throw Exception('Failed to get beat plan analytics: $e');
    }
  }

  /// ========================================
  /// SALESMAN METHODS
  /// ========================================

  /// Get today's beat plan for salesman
  static Future<TodaysBeatPlan?> getTodaysBeatPlan() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/today'),
        headers: headers,
      );

      final responseData = _handleResponse(response);

      if (responseData['data'] == null) {
        return null;
      }

      return TodaysBeatPlan.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to get today\'s beat plan: $e');
    }
  }

  /// Get this week's beat plan for salesman (all days)
  static Future<WeeklyBeatPlan?> getThisWeeksBeatPlan() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/this-week'),
        headers: headers,
      );

      final responseData = _handleResponse(response);

      if (responseData['data'] == null) {
        return null;
      }

      return WeeklyBeatPlan.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to get this week\'s beat plan: $e');
    }
  }

  /// Delete a beat plan (admin only)
  static Future<void> deleteBeatPlan(String beatPlanId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$beatPlanId'),
        headers: headers,
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete beat plan: $e');
    }
  }

  /// Mark beat area as complete
  static Future<BeatCompletion> markBeatAreaComplete({
    required String dailyBeatId,
    required String areaName,
    int accountsVisited = 0,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'dailyBeatId': dailyBeatId,
        'areaName': areaName,
        'accountsVisited': accountsVisited,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/complete-area'),
        headers: headers,
        body: body,
      );

      final responseData = _handleResponse(response);
      return BeatCompletion.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to mark beat area as complete: $e');
    }
  }

  /// Get salesman's beat plan history
  static Future<Map<String, dynamic>> getSalesmanBeatHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/salesman/history',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      final responseData = _handleResponse(response);

      // Parse beat plans
      final beatPlans = (responseData['data'] as List)
          .map((json) => WeeklyBeatPlan.fromJson(json))
          .toList();

      return {'beatPlans': beatPlans, 'pagination': responseData['pagination']};
    } catch (e) {
      throw Exception('Failed to get beat plan history: $e');
    }
  }

  /// ========================================
  /// SHARED METHODS
  /// ========================================

  /// Get specific weekly beat plan details
  static Future<WeeklyBeatPlan> getWeeklyBeatPlanDetails(
    String beatPlanId,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/$beatPlanId'),
        headers: headers,
      );

      final responseData = _handleResponse(response);
      return WeeklyBeatPlan.fromJson(responseData['data']);
    } catch (e) {
      throw Exception('Failed to get beat plan details: $e');
    }
  }

  /// ========================================
  /// OFFLINE SUPPORT
  /// ========================================

  /// Cache today's beat plan for offline access
  static Future<void> cacheTodaysBeatPlan(TodaysBeatPlan beatPlan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode({
        'weeklyPlan': beatPlan.weeklyPlan?.toJson(),
        'dailyPlan': beatPlan.dailyPlan?.toJson(),
        'accounts': beatPlan.accounts,
        'completedAreas': beatPlan.completedAreas,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString('cached_todays_beat_plan', jsonData);
    } catch (e) {
      print('Failed to cache today\'s beat plan: $e');
    }
  }

  /// Get cached today's beat plan
  static Future<TodaysBeatPlan?> getCachedTodaysBeatPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_todays_beat_plan');

      if (cachedData == null) return null;

      final jsonData = jsonDecode(cachedData);
      final cachedAt = DateTime.parse(jsonData['cachedAt']);

      // Check if cache is from today
      final now = DateTime.now();
      if (cachedAt.day != now.day ||
          cachedAt.month != now.month ||
          cachedAt.year != now.year) {
        // Cache is old, remove it
        await prefs.remove('cached_todays_beat_plan');
        return null;
      }

      return TodaysBeatPlan.fromJson(jsonData);
    } catch (e) {
      print('Failed to get cached today\'s beat plan: $e');
      return null;
    }
  }

  /// Clear cached beat plan data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_todays_beat_plan');
    } catch (e) {
      print('Failed to clear beat plan cache: $e');
    }
  }

  /// ========================================
  /// UTILITY METHODS
  /// ========================================

  /// Get week start date (Monday) for a given date
  static DateTime getWeekStartDate(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Get week end date (Sunday) for a given date
  static DateTime getWeekEndDate(DateTime date) {
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  /// Format week range for display
  static String formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
  }

  /// Get day name from day of week number
  static String getDayName(int dayOfWeek) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek];
    }
    return 'Unknown';
  }

  /// Get status color for UI
  static String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return '#FFA500'; // Orange
      case 'ACTIVE':
        return '#4CAF50'; // Green
      case 'LOCKED':
        return '#F44336'; // Red
      case 'COMPLETED':
        return '#2196F3'; // Blue
      case 'PLANNED':
        return '#9E9E9E'; // Grey
      case 'IN_PROGRESS':
        return '#FF9800'; // Orange
      case 'MISSED':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
