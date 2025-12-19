import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';
import '../services/api_config.dart';
import '../services/user_service.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  bool isLoading = false;
  String result = '';

  Future<void> _testNotificationService() async {
    setState(() {
      isLoading = true;
      result = 'Testing notification service...';
    });

    try {
      // Test getting notification counts
      final countsResult = await NotificationService.getNotificationCounts(
        role: 'admin',
      );

      if (countsResult['success'] == true) {
        final counts = countsResult['counts'];
        setState(() {
          result =
              'Success! Notification counts:\n'
              'Total: ${counts['total']}\n'
              'Unread: ${counts['unread']}\n'
              'Read: ${counts['read']}';
        });
      } else {
        setState(() {
          result = 'Error: ${countsResult['error']}';
        });
      }
    } catch (e) {
      setState(() {
        result = 'Exception: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testCreateNotification() async {
    setState(() {
      isLoading = true;
      result = 'Creating test notification...';
    });

    try {
      final success = await NotificationService.createNotification(
        title: 'Test Notification',
        message: 'This is a test notification created from the app',
        type: 'general',
        priority: 'normal',
        targetRole: 'admin',
      );

      setState(() {
        result = success
            ? 'Test notification created successfully!'
            : 'Failed to create test notification';
      });
    } catch (e) {
      setState(() {
        result = 'Exception: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testTimeFormatting() async {
    setState(() {
      isLoading = true;
      result = 'Testing time formatting with backend...';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserService.token}',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          result =
              'Time formatting test successful!\n'
              'Current time: ${data['data']['currentTime']}\n'
              'Time string: ${data['data']['timeString']}\n'
              'Test notifications created successfully!';
        });
      } else {
        setState(() {
          result = 'Error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        result = 'Exception: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification System Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _testNotificationService,
                    child: const Text('Test Get Counts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _testCreateNotification,
                    child: const Text('Create Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _testTimeFormatting,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Test Time Formatting'),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(result, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
