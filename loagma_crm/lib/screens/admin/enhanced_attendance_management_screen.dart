import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../services/user_service.dart';
import 'route_list_screen.dart';

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
  List<AttendanceModel> detailedAttendanceRecords = [];
  List<dynamic> absentEmployees = [];
  List<dynamic> allEmployees = [];

  // Filters
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  String filterStatus = 'All';
  String? selectedEmployeeId;
  bool isLoading = false;
  bool isLiveTrackingEnabled = true;
  bool isMapExpanded = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    _loadInitialData();
    _loadEmployees();
    _loadDetailedAttendance();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _searchController.dispose();
    _dateController.dispose();
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

  Future<void> _loadEmployees() async {
    try {
      final result = await UserService.getAllUsers();
      if (result['success'] && mounted) {
        setState(() {
          allEmployees = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  Future<void> _loadDetailedAttendance() async {
    try {
      final result = await AttendanceService.getDetailedAttendance(
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        employeeId: selectedEmployeeId,
      );
      if (result['success'] && mounted) {
        setState(() {
          detailedAttendanceRecords = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading detailed attendance: $e');
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
      // Punch In Marker
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
          onTap: () => _showEmployeeDetails(attendance),
        ),
      );

      // Punch Out Marker
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
            onTap: () => _showEmployeeDetails(attendance),
          ),
        );
      }
    }

    setState(() => _markers = newMarkers);
  }

  void _showEmployeeDetails(AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEmployeeDetailsSheet(attendance),
    );
  }

  Widget _buildEmployeeDetailsSheet(AttendanceModel attendance) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: Text(
                    attendance.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.employeeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${attendance.employeeId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: attendance.isPunchedOut
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.isPunchedOut ? 'Completed' : 'Active',
                    style: TextStyle(
                      color: attendance.isPunchedOut
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Punch In Time',
                    DateFormat(
                      'MMM dd, yyyy - HH:mm:ss',
                    ).format(attendance.punchInTime),
                    Icons.login,
                  ),
                  if (attendance.punchOutTime != null)
                    _buildDetailRow(
                      'Punch Out Time',
                      DateFormat(
                        'MMM dd, yyyy - HH:mm:ss',
                      ).format(attendance.punchOutTime!),
                      Icons.logout,
                    ),
                  _buildDetailRow(
                    'Work Duration',
                    _formatDuration(
                      attendance.totalWorkHours ??
                          _calculateCurrentWorkHours(attendance),
                    ),
                    Icons.schedule,
                  ),
                  if (attendance.totalDistanceKm != null)
                    _buildDetailRow(
                      'Distance Traveled',
                      '${attendance.totalDistanceKm!.toStringAsFixed(2)} km',
                      Icons.directions,
                    ),
                  if (attendance.punchInAddress != null)
                    _buildDetailRow(
                      'Punch In Location',
                      attendance.punchInAddress!,
                      Icons.location_on,
                    ),
                  if (attendance.punchOutAddress != null)
                    _buildDetailRow(
                      'Punch Out Location',
                      attendance.punchOutAddress!,
                      Icons.location_off,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCurrentWorkHours(AttendanceModel attendance) {
    if (attendance.isPunchedOut) return attendance.totalWorkHours ?? 0;

    final now = DateTime.now();
    final duration = now.difference(attendance.punchInTime);
    return duration.inMinutes / 60.0;
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD7BE69),
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
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Detailed View'),
            Tab(text: 'Live Tracking'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe gestures
              children: [
                _buildDashboardTab(),
                _buildDetailedViewTab(),
                _buildLiveTrackingTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    final stats = dashboardData['statistics'] ?? {};
    final totalEmployees = stats['totalEmployees'] ?? 0;
    final presentEmployees = stats['presentEmployees'] ?? 0;
    final absentEmployees = stats['absentEmployees'] ?? 0;
    final activeEmployees = stats['activeEmployees'] ?? 0;
    final completedEmployees = stats['completedEmployees'] ?? 0;
    final totalSessions = stats['totalSessions'] ?? 0;
    final avgWorkHours = stats['avgWorkHours'] ?? 0.0;
    final totalWorkHours = stats['totalWorkHours'] ?? 0.0;
    final attendancePercentage = stats['attendancePercentage'] ?? 0.0;

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
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
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
                    '${presentEmployees} Present • ${totalSessions} Sessions',
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                          color: Colors.blue.withValues(alpha: 0.1),
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
                            presentEmployees,
                            totalEmployees,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${attendancePercentage.toInt()}%',
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
                          presentEmployees,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Absent',
                          absentEmployees,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Active',
                          activeEmployees,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Done',
                          completedEmployees,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Additional Statistics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Sessions',
                          totalSessions,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItemDouble(
                          'Avg Hours',
                          avgWorkHours.toDouble(),
                          Colors.indigo,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItemDouble(
                          'Total Hours',
                          totalWorkHours.toDouble(),
                          Colors.teal,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Total Staff',
                          totalEmployees,
                          Colors.grey,
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

  Widget _buildDetailedViewTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  // Date Filter
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                            _dateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(date);
                          });
                          _loadDetailedAttendance();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Employee Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Employees'),
                        ),
                        ...allEmployees.map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee['id'],
                            child: Text(employee['name'] ?? 'Unknown'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedEmployeeId = value);
                        _loadDetailedAttendance();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Refresh Button
                  IconButton(
                    onPressed: _loadDetailedAttendance,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Summary Stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(
                'Total Records',
                detailedAttendanceRecords.length.toString(),
                Icons.list_alt,
                Colors.blue,
              ),
              _buildQuickStat(
                'Active Sessions',
                detailedAttendanceRecords
                    .where((a) => a.status == 'active')
                    .length
                    .toString(),
                Icons.play_circle,
                Colors.orange,
              ),
              _buildQuickStat(
                'Completed',
                detailedAttendanceRecords
                    .where((a) => a.status == 'completed')
                    .length
                    .toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ),

        // Attendance List
        Expanded(
          child: detailedAttendanceRecords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try selecting a different date or employee',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: detailedAttendanceRecords.length,
                  itemBuilder: (context, index) {
                    final attendance = detailedAttendanceRecords[index];
                    return _buildComprehensiveAttendanceCard(attendance);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailedAttendanceCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: attendance.isPunchedOut
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  child: Text(
                    attendance.employeeName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${attendance.employeeId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    color: attendance.isPunchedOut
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.isPunchedOut ? 'Completed' : 'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: attendance.isPunchedOut
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time Details
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Punch In',
                    DateFormat('HH:mm:ss').format(attendance.punchInTime),
                    Icons.login,
                    Colors.green,
                  ),
                ),
                if (attendance.punchOutTime != null)
                  Expanded(
                    child: _buildTimeInfo(
                      'Punch Out',
                      DateFormat('HH:mm:ss').format(attendance.punchOutTime!),
                      Icons.logout,
                      Colors.red,
                    ),
                  ),
                Expanded(
                  child: _buildTimeInfo(
                    'Duration',
                    _formatDuration(
                      attendance.totalWorkHours ??
                          _calculateCurrentWorkHours(attendance),
                    ),
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            if (attendance.totalDistanceKm != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Distance: ${attendance.totalDistanceKm!.toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            // Action Buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEmployeeDetails(attendance),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showOnMap(attendance),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showOnMap(AttendanceModel attendance) {
    _tabController.animateTo(2); // Switch to Live Tracking tab

    // Focus on the employee's location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(attendance.punchInLatitude, attendance.punchInLongitude),
          15,
        ),
      );
    }
  }

  Widget _buildLiveTrackingTab() {
    return Column(
      children: [
        // Map Controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.map, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Live Employee Tracking',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() => isMapExpanded = !isMapExpanded);
                    },
                    icon: Icon(
                      isMapExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                    tooltip: isMapExpanded ? 'Collapse Map' : 'Expand Map',
                  ),
                ],
              ),

              // Route Tracking Button
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToRouteTracking(),
                  icon: const Icon(Icons.route, size: 20),
                  label: const Text('View Route Tracking & Playback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map
        Expanded(
          flex: isMapExpanded ? 4 : 2,
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
            myLocationButtonEnabled: true,
          ),
        ),

        // Employee List (Collapsible)
        if (!isMapExpanded)
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
                          child: InkWell(
                            onTap: () => _showOnMap(attendance),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: attendance.isPunchedOut
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatItemDouble(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.2),
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
            color: color.withValues(alpha: 0.2),
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

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildComprehensiveAttendanceCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: attendance.isPunchedOut
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        attendance.employeeName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: attendance.isPunchedOut
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Employee ID: ${attendance.employeeId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Session: ${DateFormat('MMM dd, yyyy').format(attendance.punchInTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: attendance.isPunchedOut
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          attendance.isPunchedOut
                              ? Icons.check_circle
                              : Icons.access_time,
                          size: 16,
                          color: attendance.isPunchedOut
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendance.isPunchedOut ? 'Completed' : 'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: attendance.isPunchedOut
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Punch In/Out Times Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punch In/Out Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Punch In Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.login,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Punch In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'hh:mm:ss a',
                                ).format(attendance.punchInTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (attendance.punchInAddress != null)
                                Text(
                                  attendance.punchInAddress!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (attendance.punchOutTime != null) ...[
                      const SizedBox(height: 16),

                      // Punch Out Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Punch Out',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'hh:mm:ss a',
                                  ).format(attendance.punchOutTime!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                if (attendance.punchOutAddress != null)
                                  Text(
                                    attendance.punchOutAddress!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Still Active - Not Punched Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Work Duration and Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStat(
                      'Work Duration',
                      _formatDuration(
                        attendance.totalWorkHours ??
                            _calculateCurrentWorkHours(attendance),
                      ),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  if (attendance.totalDistanceKm != null)
                    Expanded(
                      child: _buildDetailStat(
                        'Distance',
                        '${attendance.totalDistanceKm!.toStringAsFixed(2)} km',
                        Icons.directions,
                        Colors.purple,
                      ),
                    ),
                  if (attendance.bikeKmStart != null ||
                      attendance.bikeKmEnd != null)
                    Expanded(
                      child: _buildDetailStat(
                        'Vehicle KM',
                        '${attendance.bikeKmStart ?? 'N/A'} - ${attendance.bikeKmEnd ?? 'Active'}',
                        Icons.motorcycle,
                        Colors.indigo,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEmployeeDetails(attendance),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Full Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOnMap(attendance),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View on Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToRouteTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteListScreen()),
    );
  }
}
