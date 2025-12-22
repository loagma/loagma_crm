import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/admin_approval_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_bell.dart';
import 'approval_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String? userId;
  final String? role;

  const NotificationsScreen({super.key, this.userId, this.role});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  List<NotificationModel> notifications = [];
  NotificationCounts? counts;
  Map<String, dynamic>? approvalCounts;
  bool isLoading = true;
  bool isLoadingMore = false;
  String selectedFilter = 'all';
  int currentOffset = 0;
  final int limit = 20;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadNotifications();
    _loadCounts();
    _loadApprovalCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreData) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        notifications.clear();
        currentOffset = 0;
        hasMoreData = true;
        isLoading = true;
      });
    }

    try {
      String? typeFilter;
      bool unreadOnly = false;

      switch (selectedFilter) {
        case 'punch_in':
          typeFilter = 'punch_in';
          break;
        case 'punch_out':
          typeFilter = 'punch_out';
          break;
        case 'unread':
          unreadOnly = true;
          break;
      }

      final result = await NotificationService.getNotifications(
        userId: widget.userId,
        role: widget.role ?? 'admin',
        type: typeFilter,
        unreadOnly: unreadOnly,
        limit: limit,
        offset: currentOffset,
      );

      if (result['success'] == true && mounted) {
        final newNotifications = (result['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            notifications = newNotifications;
          } else {
            notifications.addAll(newNotifications);
          }
          hasMoreData = newNotifications.length == limit;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
      currentOffset += limit;
    });

    await _loadNotifications();
  }

  Future<void> _loadCounts() async {
    try {
      final result = await NotificationService.getAdminDashboardNotifications(
        limit: 1, // Just to get counts
      );

      if (result['success'] == true && mounted) {
        setState(() {
          counts = NotificationCounts.fromJson(result['counts']);
        });
      }
    } catch (e) {
      print('Error loading notification counts: $e');
    }
  }

  Future<void> _loadApprovalCounts() async {
    try {
      final result = await AdminApprovalService.getApprovalCounts();
      if (result['success'] == true && mounted) {
        setState(() {
          approvalCounts = result['data'];
        });
      }
    } catch (e) {
      print('Error loading approval counts: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    if (success && mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = NotificationModel.fromJson({
            ...notifications[index].toJson(),
            'isRead': true,
            'readAt': DateTime.now().toIso8601String(),
          });
        }
      });
      _loadCounts();
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead(
      userId: widget.userId,
      role: widget.role ?? 'admin',
    );

    if (success && mounted) {
      setState(() {
        notifications = notifications
            .map(
              (n) => NotificationModel.fromJson({
                ...n.toJson(),
                'isRead': true,
                'readAt': DateTime.now().toIso8601String(),
              }),
            )
            .toList();
      });
      _loadCounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onFilterChanged(String filter) {
    if (selectedFilter != filter) {
      setState(() {
        selectedFilter = filter;
      });
      _loadNotifications(refresh: true);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          NotificationDetailsSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 4) {
              // Navigate to approval requests screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApprovalRequestsScreen(),
                ),
              ).then((_) {
                // Refresh counts when returning
                _loadApprovalCounts();
              });
            } else {
              final filters = ['all', 'punch_in', 'punch_out', 'unread'];
              _onFilterChanged(filters[index]);
            }
          },
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'All',
              icon: counts != null
                  ? _buildTabBadge(counts!.total.toString())
                  : null,
            ),
            Tab(
              text: 'Punch In',
              icon: counts?.punchIn != null
                  ? _buildTabBadge(counts!.punchIn.toString())
                  : null,
            ),
            Tab(
              text: 'Punch Out',
              icon: counts?.punchOut != null
                  ? _buildTabBadge(counts!.punchOut.toString())
                  : null,
            ),
            Tab(
              text: 'Unread',
              icon: counts != null
                  ? _buildTabBadge(counts!.unread.toString())
                  : null,
            ),
            Tab(
              text: 'Approvals',
              icon: approvalCounts != null && approvalCounts!['total'] > 0
                  ? _buildTabBadge(approvalCounts!['total'].toString())
                  : null,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadNotifications(refresh: true);
          await _loadApprovalCounts();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationsList(), // All
            _buildNotificationsList(), // Punch In
            _buildNotificationsList(), // Punch Out
            _buildNotificationsList(), // Unread
            _buildApprovalsPlaceholder(), // Approvals (placeholder)
          ],
        ),
      ),
    );
  }

  Widget _buildTabBadge(String count) {
    if (count == '0') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (selectedFilter) {
      case 'punch_in':
        message = 'No punch-in notifications';
        icon = Icons.login;
        break;
      case 'punch_out':
        message = 'No punch-out notifications';
        icon = Icons.logout;
        break;
      case 'unread':
        message = 'No unread notifications';
        icon = Icons.mark_email_read;
        break;
      default:
        message = 'No notifications yet';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here when salesmen punch in or out',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final notification = notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () => _showNotificationDetails(notification),
          onMarkAsRead: notification.isRead
              ? null
              : () => _markAsRead(notification.id),
        );
      },
    );
  }

  Widget _buildApprovalsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.approval, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Approval Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This tab will automatically navigate to the approval requests screen',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApprovalRequestsScreen(),
                ),
              ).then((_) {
                _loadApprovalCounts();
              });
            },
            icon: const Icon(Icons.approval),
            label: const Text('View Approval Requests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(notification.typeIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(notification.message, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          if (notification.data != null) ...[
            const Text(
              'Details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDataSection(notification.data!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                notification.createdAtIST ?? notification.formattedTime,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7BE69),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['employeeName'] != null)
            _buildDataRow('Employee', data['employeeName']),
          if (data['punchInTimeFormatted'] != null)
            _buildDataRow('Punch In Time', data['punchInTimeFormatted'])
          else if (data['punchInTimeIST'] != null)
            _buildDataRow('Punch In Time', data['punchInTimeIST']),
          if (data['punchOutTimeFormatted'] != null)
            _buildDataRow('Punch Out Time', data['punchOutTimeFormatted'])
          else if (data['punchOutTimeIST'] != null)
            _buildDataRow('Punch Out Time', data['punchOutTimeIST']),
          if (data['workDurationFormatted'] != null)
            _buildDataRow('Work Duration', data['workDurationFormatted']),
          if (data['totalDistanceKm'] != null)
            _buildDataRow('Distance', '${data['totalDistanceKm']} km'),
          if (data['location'] != null && data['location']['address'] != null)
            _buildDataRow('Location', data['location']['address']),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
