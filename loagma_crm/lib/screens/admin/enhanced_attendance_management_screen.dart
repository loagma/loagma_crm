import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class EnhancedAttendanceManagementScreen extends StatefulWidget {
  const EnhancedAttendanceManagementScreen({super.key});

  @override
  State<EnhancedAttendanceManagementScreen> createState() =>
      _EnhancedAttendanceManagementScreenState();
}

class _EnhancedAttendanceManagementScreenState
    extends State<EnhancedAttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Timer? _refreshTimer;

  // Data
  Map<String, dynamic> dashboardData = {};
  List<AttendanceModel> attendanceRecords = [];
  List<AttendanceModel> filteredRecords = [];
  List<dynamic> absentEmployees = [];

  // Filters
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  String filterStatus = 'All';
  bool isLoading = false;
  bool isLiveTrackingEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && isLiveTrackingEnabled) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] && mounted) {
        setState(() {
          dashboardData = result['data'];
          attendanceRecords = result['data']['attendances'] ?? [];
          absentEmployees = result['data']['absentEmployees'] ?? [];
          isLoading = false;
        });
        _applyFilters();
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<AttendanceModel> filtered = attendanceRecords;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (attendance) =>
                attendance.employeeName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                attendance.employeeId.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply status filter
    if (filterStatus != 'All') {
      if (filterStatus == 'Present') {
        filtered = filtered
            .where(
              (attendance) =>
                  attendance.status == 'active' ||
                  attendance.status == 'completed',
            )
            .toList();
      } else if (filterStatus == 'Completed') {
        filtered = filtered
            .where((attendance) => attendance.status == 'completed')
            .toList();
      }
    }

    setState(() => filteredRecords = filtered);
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    for (var attendance in attendanceRecords) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('${attendance.id}_in'),
          position: LatLng(
            attendance.punchInLatitude,
            attendance.punchInLongitude,
          ),
          infoWindow: InfoWindow(
            title: attendance.employeeName,
            snippet:
                'In: ${DateFormat('HH:mm').format(attendance.punchInTime)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            attendance.isPunchedOut
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );

      if (attendance.punchOutLatitude != null &&
          attendance.punchOutLongitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('${attendance.id}_out'),
            position: LatLng(
              attendance.punchOutLatitude!,
              attendance.punchOutLongitude!,
            ),
            infoWindow: InfoWindow(
              title: '${attendance.employeeName} - Out',
              snippet: attendance.punchOutTime != null
                  ? 'Out: ${DateFormat('HH:mm').format(attendance.punchOutTime!)}'
                  : 'Active',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    setState(() => _markers = newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Enhanced Attendance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isLiveTrackingEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() => isLiveTrackingEnabled = !isLiveTrackingEnabled);
              if (isLiveTrackingEnabled) {
                _startLiveTracking();
              } else {
                _refreshTimer?.cancel();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Live Tracking'),
            Tab(text: 'Analytics'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildLiveTrackingTab(),
                _buildAnalyticsTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    final stats = dashboardData['statistics'] ?? {};
    final presentCount = stats['presentCount'] ?? 0;
    final totalEmployees = stats['totalEmployees'] ?? 0;
    final absentCount = totalEmployees > presentCount
        ? totalEmployees - presentCount
        : 0;
    final activeCount = attendanceRecords
        .where((a) => a.status == 'active')
        .length;
    final completedCount = attendanceRecords
        .where((a) => a.status == 'completed')
        .length;

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLiveTrackingEnabled
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLiveTrackingEnabled ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLiveTrackingEnabled
                        ? Icons.location_on
                        : Icons.location_off,
                    color: isLiveTrackingEnabled ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${attendanceRecords.length} Active Employees',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isLiveTrackingEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isLiveTrackingEnabled
                        ? 'Live tracking enabled'
                        : 'Live tracking paused',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLiveTrackingEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.today,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Attendance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM dd').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getAttendanceColor(
                            presentCount,
                            totalEmployees,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          totalEmployees > 0
                              ? '${((presentCount / totalEmployees) * 100).toInt()}%'
                              : '0%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Present',
                          presentCount,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Absent',
                          absentCount,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Active',
                          activeCount,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Done',
                          completedCount,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...attendanceRecords
                .take(5)
                .map((attendance) => _buildActivityItem(attendance)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingTab() {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 2,
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 5,
            ),
            markers: _markers,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),

        // Employee List
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Active Employees (${attendanceRecords.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final attendance = attendanceRecords[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: attendance.isPunchedOut
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              child: Text(
                                attendance.employeeName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: attendance.isPunchedOut
                                      ? Colors.green
                                      : Colors.blue,
                                ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Working for ${_calculateWorkDuration(attendance)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              attendance.isPunchedOut
                                  ? Icons.check_circle
                                  : Icons.location_on,
                              color: attendance.isPunchedOut
                                  ? Colors.green
                                  : Colors.orange,
                              size: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Performance Metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Attendance Rate',
                        '85%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Avg Work Hours',
                        '8.2h',
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'On-Time Rate',
                        '78%',
                        Icons.schedule_outlined,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Overtime Hours',
                        '12h',
                        Icons.access_time,
                        Colors.red,
                      ),
                    ),
                  ],
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
            'Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Daily Report',
            'Today\'s attendance summary',
            Icons.today,
            Colors.blue,
            () {},
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            'Weekly Report',
            'This week\'s attendance analysis',
            Icons.date_range,
            Colors.green,
            () {},
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            'Monthly Report',
            'Monthly attendance statistics',
            Icons.calendar_month,
            Colors.orange,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActivityItem(AttendanceModel attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
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
            child: Text(
              attendance.employeeName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: attendance.isPunchedOut ? Colors.green : Colors.blue,
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  attendance.isPunchedOut
                      ? 'Completed work'
                      : 'Currently working',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'HH:mm',
            ).format(attendance.punchOutTime ?? attendance.punchInTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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

  Color _getAttendanceColor(int present, int total) {
    if (total == 0) return Colors.grey;
    final percentage = (present / total) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _calculateWorkDuration(AttendanceModel attendance) {
    final now = DateTime.now();
    final workDuration = now.difference(attendance.punchInTime);
    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
