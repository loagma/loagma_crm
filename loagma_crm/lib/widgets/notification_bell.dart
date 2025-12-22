import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../screens/admin/notifications_screen.dart';

class NotificationBell extends StatefulWidget {
  final String? userId;
  final String? role;
  final Color? iconColor;
  final double? iconSize;

  const NotificationBell({
    super.key,
    this.userId,
    this.role,
    this.iconColor,
    this.iconSize,
  });

  @override
  State<NotificationBell> createState() => NotificationBellState();
}

class NotificationBellState extends State<NotificationBell> {
  int unreadCount = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationCounts();
  }

  Future<void> _loadNotificationCounts() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final result = await NotificationService.getNotificationCounts(
        userId: widget.userId,
        role: widget.role,
      );

      if (result['success'] == true && mounted) {
        final counts = NotificationCounts.fromJson(result['counts']);
        setState(() {
          unreadCount = counts.unread;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification counts: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Public method to refresh notifications from parent widgets
  void refreshNotifications() {
    _loadNotificationCounts();
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationsScreen(userId: widget.userId, role: widget.role),
      ),
    ).then((_) {
      // Refresh counts when returning from notifications screen
      _loadNotificationCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color:
                widget.iconColor ??
                Theme.of(context).appBarTheme.foregroundColor ??
                const Color.fromARGB(255, 81, 81, 81),
            size: widget.iconSize ?? 24,
          ),
          onPressed: _openNotifications,
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case 'punch_in':
        return Colors.green;
      case 'punch_out':
        return Colors.red;
      case 'alert':
        return Colors.orange;
      case 'general':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'punch_in':
        return Icons.login;
      case 'punch_out':
        return Icons.logout;
      case 'alert':
        return Icons.warning;
      case 'general':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.grey[100] : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 24),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (notification.priority == 'urgent' ||
                            notification.priority == 'high') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.priority == 'urgent'
                                  ? Colors.red
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.priorityText,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Mark as read button
              if (!notification.isRead && onMarkAsRead != null)
                IconButton(
                  icon: const Icon(Icons.check, size: 20),
                  onPressed: onMarkAsRead,
                  tooltip: 'Mark as read',
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
