import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_bell.dart';

class SalesmanNotificationsScreen extends StatefulWidget {
  final String? userId;
  final String? role;

  const SalesmanNotificationsScreen({super.key, this.userId, this.role});

  @override
  State<SalesmanNotificationsScreen> createState() =>
      _SalesmanNotificationsScreenState();
}

class _SalesmanNotificationsScreenState
    extends State<SalesmanNotificationsScreen> {
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _filteredNotifications = [];
  NotificationCounts? counts;
  bool isLoading = true;
  bool isLoadingMore = false;
  String selectedFilter = 'all';
  int currentOffset = 0;
  final int limit = 20;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  // Date filter
  DateTime? _selectedDate;

  // Pagination
  int _totalCount = 0;
  int _currentPage = 1;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications();
    _loadCounts();
  }

  @override
  void dispose() {
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
        _allNotifications.clear();
        _filteredNotifications.clear();
        currentOffset = 0;
        _currentPage = 1;
        hasMoreData = true;
        isLoading = true;
      });
    }

    try {
      final result = await NotificationService.getNotifications(
        userId: widget.userId,
        role: widget.role ?? 'salesman',
        unreadOnly: false,
        limit: limit,
        offset: currentOffset,
        startDate: _selectedDate != null
            ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
              )
            : null,
        endDate: _selectedDate != null
            ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                23,
                59,
                59,
              )
            : null,
      );

      if (result['success'] == true && mounted) {
        final newNotifications = (result['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        final pagination = result['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _totalCount = pagination['total'] ?? 0;
        }

        setState(() {
          if (refresh) {
            _allNotifications = newNotifications;
          } else {
            _allNotifications.addAll(newNotifications);
          }
          _applyFilter();
          hasMoreData = newNotifications.length == limit;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'approvals') {
      _filteredNotifications = _allNotifications
          .where(
            (n) =>
                n.type == 'late_punch_approved' ||
                n.type == 'late_punch_rejected' ||
                n.type == 'early_punch_out_approved' ||
                n.type == 'early_punch_out_rejected' ||
                n.type == 'leave_approved' ||
                n.type == 'leave_rejected',
          )
          .toList();
    } else if (selectedFilter == 'tasks') {
      _filteredNotifications = _allNotifications
          .where(
            (n) =>
                n.type == 'task_assigned' ||
                n.type == 'task_updated' ||
                n.type == 'beat_plan_assigned',
          )
          .toList();
    } else {
      _filteredNotifications = List.from(_allNotifications);
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
      currentOffset += limit;
      _currentPage++;
    });

    await _loadNotifications();
  }

  Future<void> _loadCounts() async {
    try {
      final result = await NotificationService.getNotificationCounts(
        userId: widget.userId,
        role: widget.role ?? 'salesman',
      );

      if (result['success'] == true && mounted) {
        setState(() {
          counts = NotificationCounts.fromJson(result['counts']);
        });
      }
    } catch (e) {
      debugPrint('Error loading notification counts: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    if (success && mounted) {
      setState(() {
        final index = _allNotifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (index != -1) {
          _allNotifications[index] = NotificationModel.fromJson({
            ..._allNotifications[index].toJson(),
            'isRead': true,
            'readAt': DateTime.now().toIso8601String(),
          });
          _applyFilter();
        }
      });
      _loadCounts();
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead(
      userId: widget.userId,
      role: widget.role ?? 'salesman',
    );

    if (success && mounted) {
      setState(() {
        _allNotifications = _allNotifications
            .map(
              (n) => NotificationModel.fromJson({
                ...n.toJson(),
                'isRead': true,
                'readAt': DateTime.now().toIso8601String(),
              }),
            )
            .toList();
        _applyFilter();
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
        _applyFilter();
      });
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
          _NotificationDetailsSheet(notification: notification),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadNotifications(refresh: true);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Notifications'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_filteredNotifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadNotifications(refresh: true);
        },
        child: Column(
          children: [
            // Filter Chips
            _buildFilterChips(),
            // Date Filter Bar
            _buildDateFilterBar(),
            // Content
            Expanded(child: _buildNotificationsList()),
            // Pagination Info
            if (_filteredNotifications.isNotEmpty) _buildPaginationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', counts?.unread ?? 0),
            const SizedBox(width: 8),
            _buildFilterChip('Approvals', 'approvals', 0),
            const SizedBox(width: 8),
            _buildFilterChip('Tasks', 'tasks', 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, int count) {
    final isSelected = selectedFilter == filter;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(filter),
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildDateFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDate != null
                        ? primaryColor
                        : Colors.grey[300]!,
                    width: _selectedDate != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedDate != null
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _selectedDate != null
                          ? primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                            : 'Filter by Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: _selectedDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _selectedDate != null
                          ? primaryColor
                          : Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
              ),
              tooltip: 'Clear filter',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    final int totalPages = (_totalCount / limit).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_filteredNotifications.length}${_totalCount > 0 ? ' of $_totalCount' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (totalPages > 1)
            Text(
              'Page $_currentPage of $totalPages',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subMessage;
    IconData icon;

    if (_selectedDate != null) {
      message =
          'No notifications for ${DateFormat('dd MMM yyyy').format(_selectedDate!)}';
      subMessage = 'Try selecting a different date';
      icon = Icons.search_off;
    } else {
      switch (selectedFilter) {
        case 'approvals':
          message = 'No approval notifications';
          subMessage = 'Approval status updates will appear here';
          icon = Icons.approval;
          break;
        case 'tasks':
          message = 'No task notifications';
          subMessage = 'Task assignments will appear here';
          icon = Icons.task;
          break;
        default:
          message = 'No notifications yet';
          subMessage =
              'You will receive notifications for approvals, tasks, and updates';
          icon = Icons.notifications_none;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Date Filter'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    // Group notifications by date
    final groupedNotifications = _groupNotificationsByDate();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: groupedNotifications.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedNotifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final entry = groupedNotifications.entries.elementAt(index);
        final dateKey = entry.key;
        final dateNotifications = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey),
            ...dateNotifications.map(
              (notification) => NotificationItem(
                notification: notification,
                onTap: () => _showNotificationDetails(notification),
                onMarkAsRead: notification.isRead
                    ? null
                    : () => _markAsRead(notification.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate() {
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notification in _filteredNotifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  Widget _buildDateHeader(String dateKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dateKey,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B7355),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.grey[300])),
        ],
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationDetailsSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildTypeIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            notification.message,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Details Section
          if (notification.data != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDataSection(notification.data!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timestamp
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                notification.createdAtIST ?? notification.formattedTime,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7BE69),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case 'late_punch_approved':
      case 'early_punch_out_approved':
      case 'leave_approved':
        bgColor = Colors.green[100]!;
        iconColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'late_punch_rejected':
      case 'early_punch_out_rejected':
      case 'leave_rejected':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.cancel;
        break;
      case 'task_assigned':
      case 'beat_plan_assigned':
        bgColor = Colors.blue[100]!;
        iconColor = Colors.blue[700]!;
        icon = Icons.assignment;
        break;
      case 'task_updated':
        bgColor = Colors.orange[100]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.update;
        break;
      default:
        bgColor = Colors.grey[200]!;
        iconColor = Colors.grey[700]!;
        icon = Icons.notifications;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  Widget _buildDataSection(Map<String, dynamic> data) {
    final List<Widget> rows = [];

    if (data['reason'] != null) {
      rows.add(_buildDataRow('Reason', data['reason']));
    }
    if (data['adminComment'] != null) {
      rows.add(_buildDataRow('Admin Comment', data['adminComment']));
    }
    if (data['taskName'] != null) {
      rows.add(_buildDataRow('Task', data['taskName']));
    }
    if (data['dueDate'] != null) {
      rows.add(_buildDataRow('Due Date', data['dueDate']));
    }
    if (data['status'] != null) {
      rows.add(_buildDataRow('Status', data['status']));
    }

    return Column(children: rows);
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
