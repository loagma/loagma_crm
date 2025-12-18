import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import 'minimal_attendance_dashboard.dart';
import 'live_tracking_screen.dart';
import 'route_list_screen.dart';

class AdminAttendanceManagement extends StatefulWidget {
  const AdminAttendanceManagement({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceManagement> createState() =>
      _AdminAttendanceManagementState();
}

class _AdminAttendanceManagementState extends State<AdminAttendanceManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Timer _refreshTimer;

  // Data
  Map<String, dynamic> dashboardData = {};
  List<AttendanceModel> todayAttendances = [];
  bool isLoading = true;
  bool isRefreshing = false;

  // Filters
  String selectedFilter = 'all';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !isRefreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] && mounted) {
        setState(() {
          dashboardData = result['data'];
          todayAttendances = result['data']['attendances'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    await _loadData();

    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isRefreshing ? Icons.hourglass_empty : Icons.refresh),
            onPressed: isRefreshing ? null : _refreshData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Live Status'),
            Tab(icon: Icon(Icons.map), text: 'Tracking'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildLiveStatusTab(),
                _buildTrackingTab(),
                _buildReportsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToComprehensiveDashboard(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.analytics),
        label: const Text('Full Dashboard'),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final stats = dashboardData['statistics'] ?? {};

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(stats),
            const SizedBox(height: 24),

            // Today's Summary
            _buildTodaySummary(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(child: _buildFilterChips()),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),

        // Employee List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredAttendances().length,
              itemBuilder: (context, index) {
                final attendance = _getFilteredAttendances()[index];
                return _buildEmployeeCard(attendance);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Tracking',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor employee locations and travel routes',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Live Tracking Card
          _buildTrackingCard(
            'Live Employee Tracking',
            'Track employee locations in real-time',
            Icons.location_on,
            Colors.indigo,
            () => _navigateToLiveTracking(),
          ),

          const SizedBox(height: 16),

          // Route Tracking Card
          _buildTrackingCard(
            'Route Tracking & Playback',
            'View complete travel routes with animated playback and analytics',
            Icons.route,
            Colors.purple,
            () => _navigateToRouteTracking(),
          ),

          const SizedBox(height: 24),

          // Features List
          const Text(
            'Tracking Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildFeatureItem(
            'Real-time GPS Tracking',
            'Live location updates every 30 seconds',
            Icons.gps_fixed,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'Route Visualization',
            'Complete travel routes on Google Maps',
            Icons.map,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'Animated Playback',
            'Watch salesman journey with moving markers',
            Icons.play_circle,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'Distance Analytics',
            'Distance and speed charts over time',
            Icons.analytics,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Report Cards
          _buildReportCard(
            'Daily Report',
            'Today\'s attendance summary',
            Icons.today,
            Colors.blue,
            () => _generateDailyReport(),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            'Weekly Report',
            'This week\'s attendance analysis',
            Icons.date_range,
            Colors.green,
            () => _generateWeeklyReport(),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            'Monthly Report',
            'Monthly attendance statistics',
            Icons.calendar_month,
            Colors.orange,
            () => _generateMonthlyReport(),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            'Custom Report',
            'Generate custom date range report',
            Icons.analytics,
            Colors.purple,
            () => _generateCustomReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Present',
          '${stats['presentCount'] ?? 0}',
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Absent',
          '${stats['absentCount'] ?? 0}',
          Icons.person_off,
          Colors.red,
        ),
        _buildStatCard(
          'Active',
          '${stats['activeCount'] ?? 0}',
          Icons.location_on,
          Colors.blue,
        ),
        _buildStatCard(
          'Completed',
          '${stats['completedCount'] ?? 0}',
          Icons.check_circle,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Summary',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Employees',
                    '${todayAttendances.length}',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Work Hours',
                    _calculateAverageWorkHours(),
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'On Time',
                    _calculateOnTimeCount(),
                    Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Mark Attendance',
              Icons.fingerprint,
              Colors.green,
              () => _showMarkAttendanceDialog(),
            ),
            _buildActionCard(
              'Send Alert',
              Icons.notifications,
              Colors.orange,
              () => _sendAlertToAbsentees(),
            ),
            _buildActionCard(
              'Export Data',
              Icons.download,
              Colors.blue,
              () => _exportTodayData(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentAttendances = todayAttendances.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentAttendances.map(
          (attendance) => _buildActivityItem(attendance),
        ),
      ],
    );
  }

  Widget _buildActivityItem(AttendanceModel attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: attendance.isPunchedOut
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            child: Icon(
              attendance.isPunchedOut ? Icons.check : Icons.schedule,
              size: 16,
              color: attendance.isPunchedOut ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.employeeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  attendance.isPunchedOut
                      ? 'Completed work day'
                      : 'Currently working',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'HH:mm',
            ).format(attendance.punchOutTime ?? attendance.punchInTime),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'completed', 'label': 'Completed'},
    ];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter['key'];
        return FilterChip(
          selected: isSelected,
          label: Text(filter['label'] as String),
          onSelected: (selected) {
            setState(() {
              selectedFilter = filter['key'] as String;
            });
          },
          selectedColor: Colors.indigo,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmployeeCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attendance.isPunchedOut
              ? Colors.green.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          child: Text(
            attendance.employeeName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: attendance.isPunchedOut ? Colors.green : Colors.blue,
            ),
          ),
        ),
        title: Text(
          attendance.employeeName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'In: ${DateFormat('HH:mm').format(attendance.punchInTime)} | '
          '${attendance.punchOutTime != null ? 'Out: ${DateFormat('HH:mm').format(attendance.punchOutTime!)}' : 'Active'}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: attendance.isPunchedOut
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            attendance.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: attendance.isPunchedOut ? Colors.green : Colors.blue,
            ),
          ),
        ),
        onTap: () => _showEmployeeDetails(attendance),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  List<AttendanceModel> _getFilteredAttendances() {
    if (selectedFilter == 'all') {
      return todayAttendances;
    }
    return todayAttendances
        .where((attendance) => attendance.status == selectedFilter)
        .toList();
  }

  String _calculateAverageWorkHours() {
    if (todayAttendances.isEmpty) return '0.0h';

    double totalHours = 0;
    int completedCount = 0;

    for (var attendance in todayAttendances) {
      if (attendance.totalWorkHours != null) {
        totalHours += attendance.totalWorkHours!;
        completedCount++;
      }
    }

    if (completedCount == 0) return '0.0h';
    return '${(totalHours / completedCount).toStringAsFixed(1)}h';
  }

  String _calculateOnTimeCount() {
    // Assuming 9:00 AM is the standard start time
    final standardStartTime = TimeOfDay(hour: 9, minute: 0);
    int onTimeCount = 0;

    for (var attendance in todayAttendances) {
      final punchInTime = TimeOfDay.fromDateTime(attendance.punchInTime);
      if (punchInTime.hour < standardStartTime.hour ||
          (punchInTime.hour == standardStartTime.hour &&
              punchInTime.minute <= standardStartTime.minute)) {
        onTimeCount++;
      }
    }

    return onTimeCount.toString();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportTodayData();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _navigateToComprehensiveDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MinimalAttendanceDashboard(),
      ),
    );
  }

  void _navigateToLiveTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveTrackingScreen()),
    );
  }

  void _navigateToRouteTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteListScreen()),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Employees'),
              leading: Radio<String>(
                value: 'all',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Active Only'),
              leading: Radio<String>(
                value: 'active',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Completed Only'),
              leading: Radio<String>(
                value: 'completed',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attendance.employeeName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Employee ID', attendance.employeeId),
            _buildDetailRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(attendance.date),
            ),
            _buildDetailRow(
              'Punch In',
              DateFormat('HH:mm').format(attendance.punchInTime),
            ),
            _buildDetailRow(
              'Punch Out',
              attendance.punchOutTime != null
                  ? DateFormat('HH:mm').format(attendance.punchOutTime!)
                  : 'Not yet',
            ),
            _buildDetailRow(
              'Work Hours',
              attendance.totalWorkHours != null
                  ? '${attendance.totalWorkHours!.toStringAsFixed(1)}h'
                  : 'In progress',
            ),
            _buildDetailRow('Status', attendance.status.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(': $value'),
        ],
      ),
    );
  }

  void _showMarkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: const Text(
          'Manual attendance marking feature will be implemented here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendAlertToAbsentees() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending alerts to absent employees...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportTodayData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting today\'s attendance data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Attendance settings will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateDailyReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generating daily report...')));
  }

  void _generateWeeklyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating weekly report...')),
    );
  }

  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating monthly report...')),
    );
  }

  void _generateCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening custom report generator...')),
    );
  }
}
