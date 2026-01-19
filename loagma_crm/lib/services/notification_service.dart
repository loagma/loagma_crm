import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_service.dart';

class NotificationService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/notifications';

  // Get notifications for current user
  static Future<Map<String, dynamic>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
    String? type,
    String? userId,
    String? role,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{
        'unreadOnly': unreadOnly.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (userId != null) queryParams['userId'] = userId;
      if (role != null) queryParams['role'] = role;
<<<<<<< HEAD
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
=======
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'notifications': data['data'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch notifications',
        );
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return {'success': false, 'error': e.toString(), 'notifications': []};
    }
  }

  // Get notification counts
  static Future<Map<String, dynamic>> getNotificationCounts({
    String? userId,
    String? role,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse(
        '$_baseUrl/counts',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'counts': data['data'] ?? {'total': 0, 'unread': 0, 'read': 0},
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch notification counts',
        );
      }
    } catch (e) {
      print('❌ Error fetching notification counts: $e');
      return {
        'success': false,
        'error': e.toString(),
        'counts': {'total': 0, 'unread': 0, 'read': 0},
      };
    }
  }

  // Get admin dashboard notifications
  static Future<Map<String, dynamic>> getAdminDashboardNotifications({
    int limit = 20,
    String? type,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{'limit': limit.toString()};

      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(
        '$_baseUrl/admin/dashboard',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'notifications': data['data']['notifications'] ?? [],
          'counts': data['data']['counts'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch admin notifications',
        );
      }
    } catch (e) {
      print('❌ Error fetching admin notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
        'notifications': [],
        'counts': {},
      };
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to mark notification as read',
        );
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead({String? userId, String? role}) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse(
        '$_baseUrl/mark-all-read',
      ).replace(queryParameters: queryParams);

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to mark all notifications as read',
        );
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  // Create notification (Admin only)
  static Future<bool> createNotification({
    required String title,
    required String message,
    String type = 'general',
    String priority = 'normal',
    String? targetRole,
    String? targetUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final body = {
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
      };

      if (targetRole != null) body['targetRole'] = targetRole;
      if (targetUserId != null) body['targetUserId'] = targetUserId;
      if (data != null) body['data'] = jsonEncode(data);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to create notification',
        );
      }
    } catch (e) {
      print('❌ Error creating notification: $e');
      return false;
    }
  }

  // Helper method to format notification time
  static String formatNotificationTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  // Helper method to get notification icon
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'punch_in':
        return '🟢';
      case 'punch_out':
        return '🔴';
      case 'alert':
        return '⚠️';
      case 'general':
        return '📢';
      default:
        return '📝';
    }
  }

  // Helper method to get notification color
  static String getNotificationColor(String type) {
    switch (type) {
      case 'punch_in':
        return 'green';
      case 'punch_out':
        return 'red';
      case 'alert':
        return 'orange';
      case 'general':
        return 'blue';
      default:
        return 'grey';
    }
  }
}
