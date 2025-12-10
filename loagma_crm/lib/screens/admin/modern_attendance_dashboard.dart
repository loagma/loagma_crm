import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class ModernAttendanceDashboard extends StatefulWidget {
  const ModernAttendanceDashboard({super.key});

  @override
  State<ModernAttendanceDashboard> createState() =>
      _ModernAttendanceDashboardState();
}

class _ModernAttendanceDashboardState extends State<ModernAttendanceDashboard>
    with TickerProviderStateMixin {
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  GoogleMapController? _mapController;
  Timer? _liveTimer;

  // Data
  Map<String, dynamic> dashboardStats = {};
  List<AttendanceModel> activeEmployees = [];
  List<AttendanceModel> allAttendance = [];
  List<dynamic> absentEmployees = [];
  Set<Marker> _markers = {};

  // State
  bool isLiveTrackingEnabled = true;
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _liveTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startLiveTracking() {
    if (isLiveTrackingEnabled) {
      _liveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _loadDashboardData();
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] == true && mounted) {
        setState(() {
          dashboardStats = result['data']['statistics'] ?? {};
          allAttendance = result['data']['attendances'] ?? [];
          activeEmployees = allAttendance
              .where((a) => a.status == 'active')
              .toList();
          absentEmployees = result['data']['absentEmployees'] ?? [];
          isLoading = false;
        });
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load data: $e');
      }
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};

    for (var employee in activeEmployees) {
      markers.add(
        Marker(
          markerId: MarkerId(employee.id),
          position: LatLng(employee.punchInLatitude, employee.punchInLongitude),
          infoWindow: InfoWindow(
            title: employee.employeeName,
            snippet:
                'Active since ${DateFormat('HH:mm').format(employee.punchInTime)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () => _showEmployeeDetails(employee),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _toggleLiveTracking() {
    setState(() {
      isLiveTrackingEnabled = !isLiveTrackingEnabled;
      if (isLiveTrackingEnabled) {
        _startLiveTracking();
      } else {
        _liveTimer?.cancel();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildLiveStatusHeader(),
            _buildQuickStats(),
            _buildActiveEmployeesSection(),
            _buildMapSection(),
            _buildRecentActivity(),
          ],
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Attendance Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.dashboard, size: 60, color: Colors.white24),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isLiveTrackingEnabled ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: _toggleLiveTracking,
          tooltip: isLiveTrackingEnabled
              ? 'Pause Live Tracking'
              : 'Resume Live Tracking',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  Widget _buildLiveStatusHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLiveTrackingEnabled
                ? [successColor, successColor.withValues(alpha: 0.8)]
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isLiveTrackingEnabled ? successColor : Colors.grey)
                  .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: isLiveTrackingEnabled
                      ? 1.0 + (_pulseController.value * 0.1)
                      : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isLiveTrackingEnabled
                          ? Icons.location_on
                          : Icons.location_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking ${isLiveTrackingEnabled ? 'Active' : 'Paused'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${activeEmployees.length} employees currently active',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isLiveTrackingEnabled,
              onChanged: (_) => _toggleLiveTracking(),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.7),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = dashboardStats;
    final totalEmployees = stats['totalEmployees'] ?? 0;
    final presentEmployees = stats['presentEmployees'] ?? 0;
    final absentCount = stats['absentEmployees'] ?? 0;
    final activeCount = stats['activeEmployees'] ?? 0;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Employees',
              totalEmployees.toString(),
              Icons.people,
              primaryColor,
              'All registered employees',
            ),
            _buildStatCard(
              'Present Today',
              presentEmployees.toString(),
              Icons.check_circle,
              successColor,
              'Employees who punched in',
            ),
            _buildStatCard(
              'Currently Active',
              activeCount.toString(),
              Icons.location_on,
              warningColor,
              'Working right now',
            ),
            _buildStatCard(
              'Absent Today',
              absentCount.toString(),
              Icons.cancel,
              errorColor,
              'Not punched in yet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEmployeesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Active Employees (${activeEmployees.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAllEmployees(),
                  icon: const Icon(Icons.list),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeEmployees.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No active employees right now',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
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
    );
  }

  Widget _buildActiveEmployeeCard(AttendanceModel employee) {
    final workDuration = DateTime.now().difference(employee.punchInTime);
    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: successColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: successColor.withValues(alpha: 0.1),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: successColor,
                child: Text(
                  employee.employeeName.isNotEmpty
                      ? employee.employeeName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            employee.employeeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Working for ${hours}h ${minutes}m',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showEmployeeDetails(employee),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _focusOnEmployee(employee),
                icon: const Icon(Icons.my_location, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: warningColor.withValues(alpha: 0.1),
                  foregroundColor: warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_markers.length} Active',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _fitMarkersInView,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentAttendance = allAttendance.take(5).toList();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...recentAttendance.map(
              (attendance) => _buildActivityItem(attendance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(AttendanceModel attendance) {
    final isActive = attendance.status == 'active';
    final timeAgo = _getTimeAgo(attendance.punchInTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isActive ? successColor : primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isActive ? successColor : primaryColor,
            child: Text(
              attendance.employeeName.isNotEmpty
                  ? attendance.employeeName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
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
                  attendance.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isActive ? 'Punched in $timeAgo' : 'Completed work $timeAgo',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? successColor : primaryColor).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Active' : 'Completed',
              style: TextStyle(
                color: isActive ? successColor : primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "refresh",
          onPressed: _loadDashboardData,
          backgroundColor: primaryColor,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "analytics",
          onPressed: () => _showAnalytics(),
          backgroundColor: warningColor,
          child: const Icon(Icons.analytics, color: Colors.white),
        ),
      ],
    );
  }

  void _showEmployeeDetails(AttendanceModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildEmployeeHeader(employee),
                    const SizedBox(height: 24),
                    _buildEmployeeStats(employee),
                    const SizedBox(height: 24),
                    _buildEmployeeLocation(employee),
                    const SizedBox(height: 24),
                    _buildEmployeeActions(employee),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader(AttendanceModel employee) {
    final workDuration = DateTime.now().difference(employee.punchInTime);
    final hours = workDuration.inHours;
    final minutes = workDuration.inMinutes % 60;

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: successColor,
          child: Text(
            employee.employeeName.isNotEmpty
                ? employee.employeeName[0].toUpperCase()
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
                employee.employeeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                employee.employeeId,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Working for ${hours}h ${minutes}m',
                  style: const TextStyle(
                    color: successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeStats(AttendanceModel employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Punch In',
                  DateFormat('HH:mm').format(employee.punchInTime),
                  Icons.login,
                  successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Status',
                  employee.status.toUpperCase(),
                  Icons.circle,
                  employee.status == 'active' ? successColor : primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEmployeeLocation(AttendanceModel employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${employee.punchInLatitude.toStringAsFixed(6)}, ${employee.punchInLongitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (employee.punchInAddress != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    employee.punchInAddress!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeActions(AttendanceModel employee) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _focusOnEmployee(employee);
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Show on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEmployeeHistory(employee),
            icon: const Icon(Icons.history),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _focusOnEmployee(AttendanceModel employee) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(employee.punchInLatitude, employee.punchInLongitude),
        16,
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

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showAllEmployees() {
    // Navigate to all employees screen
    Navigator.pushNamed(context, '/admin/all-employees');
  }

  void _showAnalytics() {
    // Navigate to analytics screen
    Navigator.pushNamed(context, '/admin/analytics');
  }

  void _showEmployeeHistory(AttendanceModel employee) {
    // Navigate to employee history screen
    Navigator.pushNamed(
      context,
      '/admin/employee-history',
      arguments: employee,
    );
  }
}
