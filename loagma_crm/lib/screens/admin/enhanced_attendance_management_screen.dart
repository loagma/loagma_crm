import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/attendance_summary_card.dart';
import '../../widgets/live_attendance_status.dart';
import '../../widgets/attendance_analytics_chart.dart';

class EnhancedAttendanceManagementScreen extends StatefulWidget {
  const EnhancedAttendanceManagementScreen({super.key});

  @override
  State<EnhancedAttendanceManagementScreen> createState() =>
      _EnhancedAttendanceManagementScreenState();
}

class _EnhancedAttendanceManagementScreenState
    extends State<EnhancedAttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFD7BE69);

  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Timer? _refreshTimer;

  // Data
  Map<String, dynamic> dashboardData = {};
  List<AttendanceModel> attendanceRecords = [];
  List<dynamic> absentEmployees = [];
  Map<String, dynamic> analytics = {};
  Map<String, dynamic> employeeReport = {};

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
    _mapController?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    if (isLiveTrackingEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_tabController.index == 1) {
          // Live tracking tab
          _loadLiveDashboard();
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadLiveDashboard(),
      _loadAnalytics(),
      _loadEmployeeReport(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadLiveDashboard() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] == true) {
        setState(() {
          dashboardData = result['data'];
          attendanceRecords = result['data']['attendances'] ?? [];
          absentEmployees = result['data']['absentEmployees'] ?? [];
        });
        _createMarkers();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load dashboard: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final result = await AttendanceService.getAttendanceAnalytics();
      if (result['success'] == true) {
        setState(() {
          analytics = result['data'];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load analytics: $e');
    }
  }

  Future<void> _loadEmployeeReport() async {
    try {
      final result = await AttendanceService.getEmployeeAttendanceReport(
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
      if (result['success'] == true) {
        setState(() {
          employeeReport = result['data'];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load employee report: $e');
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    for (var record in attendanceRecords) {
      if (record.status == 'active') {
        // Use punch-in location for active employees
        markers.add(
          Marker(
            markerId: MarkerId(record.id),
            position: LatLng(record.punchInLatitude, record.punchInLongitude),
            infoWindow: InfoWindow(
              title: record.employeeName,
              snippet:
                  'Active since ${DateFormat('HH:mm').format(record.punchInTime)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () => _showEmployeeLocationDetails(record),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<AttendanceModel> get filteredRecords {
    return attendanceRecords.where((record) {
      final matchesSearch =
          record.employeeName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          record.employeeId.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter =
          filterStatus == 'All' ||
          (filterStatus == 'Present' && record.status == 'active') ||
          (filterStatus == 'Completed' && record.status == 'completed');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Enhanced Attendance Management'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isLiveTrackingEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                isLiveTrackingEnabled = !isLiveTrackingEnabled;
                if (isLiveTrackingEnabled) {
                  _startLiveTracking();
                } else {
                  _refreshTimer?.cancel();
                }
              });
            },
            tooltip: isLiveTrackingEnabled
                ? 'Pause Live Tracking'
                : 'Resume Live Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
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

    return RefreshIndicator(
      onRefresh: _loadLiveDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Enhanced Summary Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: AttendanceSummaryCard(
                statistics: stats,
                date: DateTime.now(),
                onTap: () {
                  // Navigate to detailed view or show more info
                },
              ),
            ),

            const SizedBox(height: 8),

            // Search and Filter
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name or employee ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Present'),
                        _buildFilterChip('Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Attendance List
            Container(
              color: Colors.white,
              child: filteredRecords.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No records found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return _buildAttendanceCard(record);
                      },
                    ),
            ),

            // Absent Employees Section
            if (absentEmployees.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absent Employees (${absentEmployees.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...absentEmployees.map(
                      (employee) => _buildAbsentEmployeeCard(employee),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingTab() {
    final activeEmployees = attendanceRecords
        .where((r) => r.status == 'active')
        .toList();

    return Column(
      children: [
        // Live Status Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLiveTrackingEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLiveTrackingEnabled
                      ? Icons.location_on
                      : Icons.location_off,
                  color: isLiveTrackingEnabled ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activeEmployees.length} Active Employees',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLiveTrackingEnabled
                          ? 'Live tracking enabled'
                          : 'Live tracking paused',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLiveTrackingEnabled
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLiveDashboard,
                tooltip: 'Refresh locations',
              ),
            ],
          ),
        ),

        // Map View
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(28.6139, 77.2090),
                  zoom: 11,
                ),
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_markers.isNotEmpty) {
                    _fitMarkersInView();
                  }
                },
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
              ),

              // Active Employees List (Bottom Sheet)
              if (activeEmployees.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Active Employees (${activeEmployees.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: activeEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = activeEmployees[index];
                              return _buildActiveEmployeeCard(employee);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final summary = analytics['summary'] ?? {};
    final dailyAnalytics = analytics['dailyAnalytics'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 30 Days Analytics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildAnalyticsCard(
                        'Total Attendances',
                        '${summary['totalAttendances'] ?? 0}',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                      _buildAnalyticsCard(
                        'Avg Work Hours',
                        '${summary['avgWorkHours'] ?? 0}h',
                        Icons.access_time,
                        Colors.green,
                      ),
                      _buildAnalyticsCard(
                        'Total Distance',
                        '${summary['totalDistance'] ?? 0}km',
                        Icons.directions_car,
                        Colors.orange,
                      ),
                      _buildAnalyticsCard(
                        'Completed',
                        '${summary['completedAttendances'] ?? 0}',
                        Icons.check_circle,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Daily Analytics Chart
            if (dailyAnalytics.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Attendance Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dailyAnalytics.length,
                        itemBuilder: (context, index) {
                          final dayData = dailyAnalytics[index];
                          return _buildDayAnalyticsCard(dayData);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final employeeReports = employeeReport['employeeReports'] ?? [];
    final month = employeeReport['month'] ?? DateTime.now().month;
    final year = employeeReport['year'] ?? DateTime.now().year;

    return RefreshIndicator(
      onRefresh: _loadEmployeeReport,
      child: Column(
        children: [
          // Month/Year Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime(year, month)),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime(year, month),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (date != null) {
                      final result =
                          await AttendanceService.getEmployeeAttendanceReport(
                            month: date.month,
                            year: date.year,
                          );
                      if (result['success'] == true) {
                        setState(() {
                          employeeReport = result['data'];
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Employee Reports List
          Expanded(
            child: employeeReports.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assessment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No employee reports available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: employeeReports.length,
                    itemBuilder: (context, index) {
                      final report = employeeReports[index];
                      return _buildEmployeeReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = filterStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => filterStatus = label);
        },
        selectedColor: primaryColor.withOpacity(0.3),
        checkmarkColor: primaryColor,
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    final isActive = record.status == 'active';
    final workDuration = record.totalWorkHours != null
        ? '${record.totalWorkHours!.toStringAsFixed(1)}h'
        : 'In Progress';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAttendanceDetails(record),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor,
                    child: Text(
                      record.employeeName.isNotEmpty
                          ? record.employeeName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record.employeeId,
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Time Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.login,
                      'Punch In',
                      DateFormat('HH:mm').format(record.punchInTime),
                      Colors.green,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.logout,
                      'Punch Out',
                      record.punchOutTime != null
                          ? DateFormat('HH:mm').format(record.punchOutTime!)
                          : '--:--',
                      Colors.red,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.timer,
                      'Duration',
                      workDuration,
                      primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Distance and KM
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Travel Distance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  record.totalDistanceKm != null
                                      ? '${record.totalDistanceKm!.toStringAsFixed(1)} km'
                                      : '--',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KM Reading',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${record.bikeKmStart ?? '--'} → ${record.bikeKmEnd ?? '--'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildInfoColumn(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAbsentEmployeeCard(dynamic employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: Text(
            employee['name'] != null && employee['name'].isNotEmpty
                ? employee['name'][0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(employee['name'] ?? 'Unknown'),
        subtitle: Text(employee['employeeCode'] ?? 'No Code'),
        trailing: const Icon(Icons.warning, color: Colors.red),
      ),
    );
  }

  Widget _buildActiveEmployeeCard(AttendanceModel employee) {
    final workDuration = DateTime.now().difference(employee.punchInTime);
    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            employee.employeeName.isNotEmpty
                ? employee.employeeName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          employee.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Working for ${hours}h ${minutes}m',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.my_location, color: primaryColor),
          onPressed: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(employee.punchInLatitude, employee.punchInLongitude),
                15,
              ),
            );
          },
          tooltip: 'Focus on map',
        ),
        onTap: () => _showEmployeeLocationDetails(employee),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String label,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayAnalyticsCard(dynamic dayData) {
    final date = DateTime.parse(dayData['date']);
    final totalEmployees = dayData['totalEmployees'] ?? 0;
    final completedEmployees = dayData['completedEmployees'] ?? 0;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM dd').format(date),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Total: $totalEmployees', style: const TextStyle(fontSize: 11)),
          Text(
            'Completed: $completedEmployees',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalEmployees > 0 ? completedEmployees / totalEmployees : 0,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeReportCard(dynamic report) {
    final employee = report['employee'];
    final statistics = report['statistics'];
    final attendancePercentage = statistics['attendancePercentage'] ?? 0.0;

    Color getPercentageColor(double percentage) {
      if (percentage >= 90) return Colors.green;
      if (percentage >= 75) return Colors.orange;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: getPercentageColor(attendancePercentage),
                  child: Text(
                    employee['name'] != null && employee['name'].isNotEmpty
                        ? employee['name'][0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${employee['employeeCode'] ?? 'No Code'} • ${employee['department'] ?? 'No Dept'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    color: getPercentageColor(attendancePercentage),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${attendancePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Statistics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: [
                _buildReportStatItem(
                  'Present',
                  '${statistics['presentDays'] ?? 0}',
                  Colors.green,
                ),
                _buildReportStatItem(
                  'Absent',
                  '${statistics['absentDays'] ?? 0}',
                  Colors.red,
                ),
                _buildReportStatItem(
                  'Avg Hours',
                  '${statistics['avgWorkHours'] ?? 0}h',
                  Colors.blue,
                ),
                _buildReportStatItem(
                  'Distance',
                  '${statistics['totalDistance'] ?? 0}km',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEmployeeLocationDetails(AttendanceModel employee) {
    final workDuration = employee.punchOutTime != null
        ? employee.punchOutTime!.difference(employee.punchInTime)
        : DateTime.now().difference(employee.punchInTime);

    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: employee.status == 'active'
                  ? Colors.green
                  : Colors.blue,
              child: Text(
                employee.employeeName.isNotEmpty
                    ? employee.employeeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.employeeName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    employee.employeeId,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Punch In',
              DateFormat('HH:mm').format(employee.punchInTime),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Work Duration', '${hours}h ${minutes}m'),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Location',
              '${employee.punchInLatitude.toStringAsFixed(4)}, ${employee.punchInLongitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Status', employee.status.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(employee.punchInLatitude, employee.punchInLongitude),
                  16,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            icon: const Icon(Icons.location_on),
            label: const Text('Show on Map'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Text(
                      record.employeeName.isNotEmpty
                          ? record.employeeName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.employeeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record.employeeId,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Punch In Section
              _buildDetailSection('Punch In Details', Icons.login, Colors.green, [
                _buildDetailRow(
                  'Time',
                  DateFormat('HH:mm:ss').format(record.punchInTime),
                ),
                _buildDetailRow(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(record.punchInTime),
                ),
                _buildDetailRow(
                  'Location',
                  '${record.punchInLatitude.toStringAsFixed(6)}, ${record.punchInLongitude.toStringAsFixed(6)}',
                ),
                if (record.punchInAddress != null)
                  _buildDetailRow('Address', record.punchInAddress!),
                if (record.bikeKmStart != null)
                  _buildDetailRow('KM Reading', record.bikeKmStart!),
              ]),
              const SizedBox(height: 24),

              // Punch Out Section
              _buildDetailSection('Punch Out Details', Icons.logout, Colors.red, [
                _buildDetailRow(
                  'Time',
                  record.punchOutTime != null
                      ? DateFormat('HH:mm:ss').format(record.punchOutTime!)
                      : 'Not punched out',
                ),
                if (record.punchOutLatitude != null &&
                    record.punchOutLongitude != null)
                  _buildDetailRow(
                    'Location',
                    '${record.punchOutLatitude!.toStringAsFixed(6)}, ${record.punchOutLongitude!.toStringAsFixed(6)}',
                  ),
                if (record.punchOutAddress != null)
                  _buildDetailRow('Address', record.punchOutAddress!),
                if (record.bikeKmEnd != null)
                  _buildDetailRow('KM Reading', record.bikeKmEnd!),
              ]),
              const SizedBox(height: 24),

              // Summary Section
              _buildDetailSection('Summary', Icons.summarize, primaryColor, [
                _buildDetailRow(
                  'Work Duration',
                  record.totalWorkHours != null
                      ? '${record.totalWorkHours!.toStringAsFixed(2)} hours'
                      : 'In progress',
                ),
                _buildDetailRow(
                  'Travel Distance',
                  record.totalDistanceKm != null
                      ? '${record.totalDistanceKm!.toStringAsFixed(2)} km'
                      : 'Not calculated',
                ),
                _buildDetailRow('Status', record.status.toUpperCase()),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;

    if (_markers.length == 1) {
      final marker = _markers.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 14),
      );
      return;
    }

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        100,
      ),
    );
  }
}
