import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import 'api_config.dart';
import 'network_service.dart';
import 'user_service.dart';

class AccountService {
  // Get auth token from shared preferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      'token',
    ); // Fixed: was 'auth_token', should be 'token'
  }

  // Get user ID from shared preferences
  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      'userId',
    ); // Fixed: was 'user_id', should be 'userId'
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== CREATE ====================

  static Future<Account> createAccount({
    String? businessName,
    required String personName,
    required String contactNumber,
    String? businessType,
    String? businessSize,
    String? dateOfBirth,
    String? customerStage,
    String? funnelStage,
    String? gstNumber,
    String? panCard,
    String? ownerImage,
    String? shopImage,
    bool? isActive,
    String? pincode,
    String? country,
    String? state,
    String? district,
    String? city,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    String? assignedToId,
    int? areaId,
  }) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      print('🔍 Creating account with:');
      print('   User ID (createdById): $userId');
      print('   Person Name: $personName');
      print('   Contact: $contactNumber');

      final response = await http.post(
        Uri.parse(ApiConfig.accountsUrl),
        headers: headers,
        body: json.encode({
          if (businessName != null) 'businessName': businessName,
          'personName': personName,
          'contactNumber': contactNumber,
          if (businessType != null) 'businessType': businessType,
          if (businessSize != null) 'businessSize': businessSize,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (customerStage != null) 'customerStage': customerStage,
          if (funnelStage != null) 'funnelStage': funnelStage,
          if (gstNumber != null) 'gstNumber': gstNumber,
          if (panCard != null) 'panCard': panCard,
          if (ownerImage != null) 'ownerImage': ownerImage,
          if (shopImage != null) 'shopImage': shopImage,
          if (isActive != null) 'isActive': isActive,
          if (pincode != null) 'pincode': pincode,
          if (country != null) 'country': country,
          if (state != null) 'state': state,
          if (district != null) 'district': district,
          if (city != null) 'city': city,
          if (area != null) 'area': area,
          if (address != null) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (assignedToId != null) 'assignedToId': assignedToId,
          if (areaId != null) 'areaId': areaId,
          if (userId != null) 'createdById': userId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  static Future<Map<String, dynamic>> fetchAccounts({
    int page = 1,
    int limit = 50,
    String? areaId,
    String? assignedToId,
    /// Day filter for salesman allotment: 1=Mon .. 7=Sun. Backend filters by assignedDays.
    int? assignedDay,
    String? customerStage,
    String? funnelStage,
    bool? isApproved,
    String? createdById,
    String? approvedById,
    String? search,
    String? pincode,
    DateTime? startDate,
    DateTime? endDate,
    String? salesmanId, // Helper: filters by createdById (for salesman accounts)
  }) async {
    try {
      // Check connectivity first
      final isConnected = await NetworkService.checkConnectivity();
      if (!isConnected) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final headers = await _getHeaders();
      // If salesmanId is provided, use it as createdById (accounts are linked to salesmen via createdById)
      final effectiveCreatedById = salesmanId ?? createdById;
      
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (areaId != null) 'areaId': areaId,
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (assignedDay != null && assignedDay >= 1 && assignedDay <= 7) 'assignedDay': assignedDay.toString(),
        if (customerStage != null) 'customerStage': customerStage,
        if (funnelStage != null) 'funnelStage': funnelStage,
        if (isApproved != null) 'isApproved': isApproved.toString(),
        if (effectiveCreatedById != null) 'createdById': effectiveCreatedById,
        if (approvedById != null) 'approvedById': approvedById,
        if (search != null) 'search': search,
        if (pincode != null && pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
        if (startDate != null)
          'startDate': startDate
              .toIso8601String(), // Send full ISO string with time
        if (endDate != null)
          'endDate': endDate
              .toIso8601String(), // Send full ISO string with time
      };

      final uri = Uri.parse(
        ApiConfig.accountsUrl,
      ).replace(queryParameters: queryParams);

      // Use retry mechanism for better reliability
      final response = await NetworkService.retryApiCall(
        () => http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15)),
        maxRetries: 2,
        delay: const Duration(seconds: 2),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'accounts': (data['data'] as List)
              .map((json) => Account.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      }
      throw Exception('Failed to load accounts: ${response.statusCode}');
    } catch (e) {
      final errorMessage = NetworkService.getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  static Future<Account> fetchAccountById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      }
      throw Exception('Failed to load account');
    } catch (e) {
      print('Error fetching account: $e');
      rethrow;
    }
  }

  // ==================== UPDATE ====================

  static Future<Account> updateAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update account');
      }
    } catch (e) {
      print('Error updating account: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteAccount(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.accountsUrl}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // ==================== VERIFY / REJECT ====================
  // Terminology: use "verify" / "verified" in UI; backend uses approve.

  static Future<Account> verifyAccount(String id, {String? notes}) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/$id/approve'),
        headers: headers,
        body: json.encode({
          if (userId != null) 'approvedById': userId,
          if (notes != null && notes.trim().isNotEmpty) 'verificationNotes': notes.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify account');
      }
    } catch (e) {
      print('Error verifying account: $e');
      rethrow;
    }
  }

  static Future<Account> rejectAccount(String id, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/$id/reject'),
        headers: headers,
        body: json.encode({
          if (notes != null && notes.trim().isNotEmpty) 'rejectionNotes': notes.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Account.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject account');
      }
    } catch (e) {
      print('Error rejecting account: $e');
      rethrow;
    }
  }

  /// Legacy alias for verifyAccount (approve).
  static Future<Account> approveAccount(String id) => verifyAccount(id);

  // ==================== STATISTICS ====================

  static Future<Map<String, dynamic>> getAccountStats({
    String? assignedToId,
    String? areaId,
    String? createdById,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (areaId != null) 'areaId': areaId,
        if (createdById != null) 'createdById': createdById,
      };

      final uri = Uri.parse(
        '${ApiConfig.accountsUrl}/stats',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load account stats');
    } catch (e) {
      print('Error fetching account stats: $e');
      rethrow;
    }
  }

  // ==================== BULK OPERATIONS ====================

  static Future<int> bulkAssignAccounts({
    required List<String> accountIds,
    required String assignedToId,
    /// Beat days: 1=Mon .. 7=Sun. Sent to backend for day-wise salesman list.
    List<int>? assignedDays,
    DateTime? weekStartDate,
    String? visitFrequency,
    bool createWeeklyAssignments = true,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'accountIds': accountIds,
        'assignedToId': assignedToId,
      };
      if (assignedDays != null && assignedDays.isNotEmpty) {
        body['assignedDays'] = assignedDays;
      }
      if (weekStartDate != null) {
        body['weekStartDate'] = toWeekStart(weekStartDate).toIso8601String();
      }
      if (visitFrequency != null && visitFrequency.trim().isNotEmpty) {
        body['visitFrequency'] = visitFrequency.trim().toUpperCase();
      }
      body['createWeeklyAssignments'] = createWeeklyAssignments;
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/bulk/assign'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to assign accounts');
      }
    } catch (e) {
      print('Error bulk assigning accounts: $e');
      rethrow;
    }
  }

  static DateTime toWeekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final delta = normalized.weekday - 1;
    return normalized.subtract(Duration(days: delta));
  }

  static Future<Map<String, dynamic>> fetchWeeklyAssignmentsView({
    required String salesmanId,
    required DateTime weekStartDate,
    String? pincode,
  }) async {
    try {
      final effectiveSalesmanId = salesmanId.trim().isNotEmpty
          ? salesmanId.trim()
          : (UserService.currentUserId?.trim() ?? '');
      if (effectiveSalesmanId.isEmpty) {
        throw Exception('Session is missing user id. Please login again.');
      }

      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);
      final uri = Uri.parse('${ApiConfig.accountsUrl}/weekly/view').replace(
        queryParameters: {
          'salesmanId': effectiveSalesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          if (pincode != null && pincode.trim().isNotEmpty)
            'pincode': pincode.trim(),
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to load weekly assignments');
    } catch (e) {
      print('Error fetching weekly assignments view: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> autoAssignNextUnassignedAccounts({
    required String salesmanId,
    required String pincode,
    required DateTime weekStartDate,
    required int day,
    required int countN,
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/weekly/auto-assign-next'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'pincode': pincode.trim(),
          'weekStartDate': weekStart.toIso8601String(),
          'day': day,
          'countN': countN,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to auto-assign next accounts');
    } catch (e) {
      print('Error auto assigning next unassigned accounts: $e');
      rethrow;
    }
  }

  static Future<int> manualAssignWeeklyAccounts({
    required String salesmanId,
    required DateTime weekStartDate,
    required List<String> accountIds,
    required List<int> assignedDays,
    String? visitFrequency,
    int? afterDays,
    List<String> manualOverrideAccountIds = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/weekly/manual-assign'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          'accountIds': accountIds,
          'assignedDays': assignedDays,
          if (visitFrequency != null && visitFrequency.trim().isNotEmpty)
            'visitFrequency': visitFrequency.trim().toUpperCase(),
          if (afterDays != null && afterDays > 0)
            'afterDays': afterDays,
          'manualOverrideAccountIds': manualOverrideAccountIds,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return (data['count'] as num?)?.toInt() ?? 0;
      }
      throw Exception(data['message'] ?? 'Failed to assign weekly accounts');
    } catch (e) {
      print('Error manual assigning weekly accounts: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> unassignWeeklyAccountsGlobal({
    required String salesmanId,
    required List<String> accountIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/weekly/unassign-global'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'accountIds': accountIds,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return (data['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      }
      throw Exception(data['message'] ?? 'Failed to unassign weekly accounts');
    } catch (e) {
      print('Error global unassign weekly accounts: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchPlanningWeekView({
    required String salesmanId,
    required DateTime weekStartDate,
    String? pincode,
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);
      final uri = Uri.parse('${ApiConfig.accountsUrl}/planning/week').replace(
        queryParameters: {
          'salesmanId': salesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          if (pincode != null && pincode.trim().isNotEmpty)
            'pincode': pincode.trim(),
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to load planning week view');
    } catch (e) {
      print('Error fetching planning week view: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> assignPlanningWeekAccounts({
    required String salesmanId,
    required DateTime weekStartDate,
    required List<Map<String, dynamic>> assignments,
    List<String> manualOverrideAccountIds = const [],
    String? overrideReason,
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);

      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/planning/week/assign'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          'assignments': assignments,
          'manualOverrideAccountIds': manualOverrideAccountIds,
          if (overrideReason != null && overrideReason.trim().isNotEmpty)
            'overrideReason': overrideReason.trim(),
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to assign planning week accounts');
    } catch (e) {
      print('Error assigning planning week accounts: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updatePlanningWeekAccount({
    required String accountId,
    required String salesmanId,
    required DateTime weekStartDate,
    required List<int> plannedDays,
    required String visitFrequency,
    bool isOverride = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);

      final response = await http.patch(
        Uri.parse('${ApiConfig.accountsUrl}/planning/week/account/$accountId'),
        headers: headers,
        body: json.encode({
          'salesmanId': salesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          'plannedDays': plannedDays,
          'visitFrequency': visitFrequency.toUpperCase(),
          'isOverride': isOverride,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to update planning week account');
    } catch (e) {
      print('Error updating planning week account: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchMultiVisitWeekAccounts({
    required String salesmanId,
    required DateTime weekStartDate,
    String? frequency,
    int? day,
  }) async {
    try {
      final headers = await _getHeaders();
      final weekStart = toWeekStart(weekStartDate);
      final uri = Uri.parse('${ApiConfig.accountsUrl}/planning/week/multi-visit').replace(
        queryParameters: {
          'salesmanId': salesmanId,
          'weekStartDate': weekStart.toIso8601String(),
          if (frequency != null && frequency.trim().isNotEmpty)
            'frequency': frequency.trim().toUpperCase(),
          if (day != null) 'day': day.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to load multi-visit week accounts');
    } catch (e) {
      print('Error fetching multi-visit week accounts: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchTodayPlannedAccounts({
    required String salesmanId,
    DateTime? date,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.accountsUrl}/planning/today').replace(
        queryParameters: {
          'salesmanId': salesmanId,
          if (date != null) 'date': date.toIso8601String(),
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to load today planned accounts');
    } catch (e) {
      print('Error fetching today planned accounts: $e');
      rethrow;
    }
  }

  static Future<int> bulkApproveAccounts({
    required List<String> accountIds,
  }) async {
    try {
      final userId = await _getUserId();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/bulk/approve'),
        headers: headers,
        body: json.encode({
          'accountIds': accountIds,
          if (userId != null) 'approvedById': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve accounts');
      }
    } catch (e) {
      print('Error bulk approving accounts: $e');
      rethrow;
    }
  }

  // ==================== CHECK CONTACT NUMBER ====================

  static Future<Map<String, dynamic>> checkContactNumber(
    String contactNumber,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.accountsUrl}/check-contact'),
        headers: headers,
        body: json.encode({'contactNumber': contactNumber}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to check contact number');
      }
    } catch (e) {
      print('Error checking contact number: $e');
      rethrow;
    }
  }
}
