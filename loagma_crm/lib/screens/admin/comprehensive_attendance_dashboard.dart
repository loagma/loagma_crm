import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class ComprehensiveAttendanceDashboard extends StatefulWidget {
  const ComprehensiveAttendanceDashboard({Key? key}) : super(key: key);

  @override
  State<ComprehensiveAttendanceDashboard> createState() =>
      _ComprehensiveAttendanceDashboardState();
}

class _ComprehensiveAttendanceDashboardState
    extends State<ComprehensiveAttendanceDashboard>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late Timer _refreshTimer;

  // Data
  Map<String, dynamic> dashboardData = {};
  List<AttendanceModel> todayAttendances = [];
  List<AttendanceModel> filteredAttendances = [];
  bool isLoading = true;
  bool isRefreshing = false;

  // UI State
  int currentPage = 0;
  String selectedFilter = 'all';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isBottomSheetExpanded = false;

  // Google Maps
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _refreshTimer.cancel();
    searchController.dispose();
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
        _applyFilters();
        _updateMapMarkers();
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
    setState(() => isRefreshing = true);
    await _loadData();
    if (mounted) setState(() => isRefreshing = false);
  }

  void _applyFilters() {
    List<AttendanceModel> filtered = todayAttendances;

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
    if (selectedFilter != 'all') {
      if (selectedFilter == 'present') {
        filtered = filtered
            .where(
              (attendance) =>
                  attendance.status == 'active' ||
                  attendance.status == 'completed',
            )
            .toList();
      } else {
        filtered = filtered
            .where((attendance) => attendance.status == selectedFilter)
            .toList();
      }
    }

    setState(() {
      filteredAttendances = filtered;
    });
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    for (var attendance in todayAttendances) {
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

    setState(() => markers = newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isRefreshing ? Icons.hourglass_empty : Icons.refresh),
            onPressed: isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => currentPage = index),
                  children: [
                    _buildDashboardPage(),
                    _buildEmployeesPage(),
                    _buildMapPage(),
                  ],
                ),
                _buildBottomNavigation(),
              ],
            ),
    );
  }

  Widget _buildDashboardPage() {
    final stats = dashboardData['statistics'] ?? {};
    final presentCount = stats['presentCount'] ?? 0;
    final totalEmployees = stats['totalEmployees'] ?? 0;
    final absentCount = totalEmployees > presentCount
        ? totalEmployees - presentCount
        : 0; // Fix negative absent
    final activeCount = todayAttendances
        .where((a) => a.status == 'active')
        .length;
    final completedCount = todayAttendances
        .where((a) => a.status == 'completed')
        .length;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Summary Card
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

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Mark Attendance',
                    Icons.fingerprint,
                    Colors.blue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mark attendance feature'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Send Alert',
                    Icons.notifications,
                    Colors.orange,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sending alerts to absent employees'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...todayAttendances
                .take(3)
                .map((attendance) => _buildActivityItem(attendance)),
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesPage() {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Present', 'present'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
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
              itemCount: filteredAttendances.length,
              itemBuilder: (context, index) {
                final attendance = filteredAttendances[index];
                return _buildEmployeeCard(attendance);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Live Locations (${todayAttendances.length} employees)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: _centerMapOnEmployees,
              ),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 5,
            ),
            markers: markers,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isBottomSheetExpanded ? 200 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle and main navigation
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                  _buildNavItem(Icons.people, 'Employees', 1),
                  _buildNavItem(Icons.map, 'Map', 2),
                  GestureDetector(
                    onTap: () => setState(
                      () => isBottomSheetExpanded = !isBottomSheetExpanded,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isBottomSheetExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.more_horiz,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded content
            if (isBottomSheetExpanded)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Stats',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStat(
                              'Present',
                              '${dashboardData['statistics']?['presentCount'] ?? 0}',
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickStat(
                              'Active',
                              '${todayAttendances.where((a) => a.status == 'active').length}',
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickStat(
                              'Completed',
                              '${todayAttendances.where((a) => a.status == 'completed').length}',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Exporting attendance data...',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sending alerts to absent employees...',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications, size: 16),
                              label: const Text('Alert'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(AttendanceModel attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
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
            radius: 20,
            backgroundColor: attendance.isPunchedOut
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            child: Text(
              attendance.employeeName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 14,
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
                  'In: ${DateFormat('HH:mm').format(attendance.punchInTime)} | ${attendance.punchOutTime != null ? 'Out: ${DateFormat('HH:mm').format(attendance.punchOutTime!)}' : 'Active'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: attendance.isPunchedOut
                  ? Colors.green.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              attendance.isPunchedOut ? 'DONE' : 'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: attendance.isPunchedOut ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Color _getAttendanceColor(int present, int total) {
    if (total == 0) return Colors.grey;
    final percentage = (present / total) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  void _centerMapOnEmployees() {
    if (markers.isEmpty || mapController == null) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in markers) {
      minLat = minLat < marker.position.latitude
          ? minLat
          : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude
          ? maxLat
          : marker.position.latitude;
      minLng = minLng < marker.position.longitude
          ? minLng
          : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude
          ? maxLng
          : marker.position.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }
}
