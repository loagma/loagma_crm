import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFD7BE69);

  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  String filterStatus = 'All'; // All, Present, Absent, Late

  // Mock data - Replace with API call
  List<Map<String, dynamic>> attendanceRecords = [
    {
      'id': '1',
      'employeeName': 'John Doe',
      'employeeCode': 'EMP001',
      'role': 'Salesman',
      'punchInTime': '09:00 AM',
      'punchOutTime': '06:30 PM',
      'punchInLocation': '28.6139, 77.2090',
      'punchOutLocation': '28.6250, 77.2200',
      'currentLat': null,
      'currentLng': null,
      'lastLocationUpdate': null,
      'punchInPhoto': null,
      'punchOutPhoto': null,
      'startKm': '1000',
      'endKm': '1150',
      'travelDistance': '12.5',
      'workDuration': '09:30:00',
      'status': 'Present',
      'date': DateTime.now(),
    },
    {
      'id': '2',
      'employeeName': 'Jane Smith',
      'employeeCode': 'EMP002',
      'role': 'Salesman',
      'punchInTime': '09:15 AM',
      'punchOutTime': '--:--',
      'punchInLocation': '28.5355, 77.3910',
      'punchOutLocation': null,
      'currentLat': 28.5400,
      'currentLng': 77.3950,
      'lastLocationUpdate': DateTime.now().subtract(const Duration(minutes: 5)),
      'punchInPhoto': null,
      'punchOutPhoto': null,
      'startKm': '2000',
      'endKm': null,
      'travelDistance': null,
      'workDuration': 'In Progress',
      'status': 'Present',
      'date': DateTime.now(),
    },
    {
      'id': '3',
      'employeeName': 'Mike Johnson',
      'employeeCode': 'EMP003',
      'role': 'Salesman',
      'punchInTime': '09:30 AM',
      'punchOutTime': '--:--',
      'punchInLocation': '28.7041, 77.1025',
      'punchOutLocation': null,
      'currentLat': 28.7100,
      'currentLng': 77.1100,
      'lastLocationUpdate': DateTime.now().subtract(const Duration(minutes: 2)),
      'punchInPhoto': null,
      'punchOutPhoto': null,
      'startKm': '3000',
      'endKm': null,
      'travelDistance': null,
      'workDuration': 'In Progress',
      'status': 'Present',
      'date': DateTime.now(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _createMarkers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    for (var record in attendanceRecords) {
      // Only show active employees with current location
      if (record['currentLat'] != null && record['currentLng'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId(record['id']),
            position: LatLng(record['currentLat'], record['currentLng']),
            infoWindow: InfoWindow(
              title: record['employeeName'],
              snippet:
                  '${record['employeeCode']} • Last update: ${_getTimeAgo(record['lastLocationUpdate'])}',
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

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  List<Map<String, dynamic>> get filteredRecords {
    return attendanceRecords.where((record) {
      final matchesSearch =
          record['employeeName'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          record['employeeCode'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      final matchesFilter =
          filterStatus == 'All' || record['status'] == filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Live Tracking'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildLiveTrackingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final presentCount = attendanceRecords
        .where((r) => r['status'] == 'Present')
        .length;
    final absentCount = attendanceRecords
        .where((r) => r['status'] == 'Absent')
        .length;
    final totalEmployees = attendanceRecords.length;

    return Column(
      children: [
        // Stats Cards
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalEmployees.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Present',
                  presentCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  absentCount.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),

        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or employee code',
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
                    _buildFilterChip('Absent'),
                    _buildFilterChip('Late'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Attendance List
        Expanded(
          child: filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return _buildAttendanceCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLiveTrackingTab() {
    final activeEmployees = attendanceRecords
        .where(
          (r) =>
              r['punchOutTime'] == '--:--' &&
              r['currentLat'] != null &&
              r['currentLng'] != null,
        )
        .toList();

    return Column(
      children: [
        // Active Employees Count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: Colors.green),
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
                      'Real-time location tracking',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _createMarkers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Locations refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
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
                    constraints: const BoxConstraints(maxHeight: 200),
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

  Widget _buildActiveEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            employee['employeeName'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          employee['employeeName'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Last update: ${_getTimeAgo(employee['lastLocationUpdate'])}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.my_location, color: primaryColor),
          onPressed: () {
            if (employee['currentLat'] != null &&
                employee['currentLng'] != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(employee['currentLat'], employee['currentLng']),
                  15,
                ),
              );
            }
          },
          tooltip: 'Focus on map',
        ),
        onTap: () => _showEmployeeLocationDetails(employee),
      ),
    );
  }

  void _showEmployeeLocationDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                employee['employeeName'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['employeeName'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    employee['employeeCode'],
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
            _buildDetailRow('Punch In', employee['punchInTime']),
            const SizedBox(height: 8),
            _buildDetailRow('Work Duration', employee['workDuration']),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Current Location',
              '${employee['currentLat']}, ${employee['currentLng']}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Last Update',
              _getTimeAgo(employee['lastLocationUpdate']),
            ),
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
              if (employee['currentLat'] != null &&
                  employee['currentLng'] != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(employee['currentLat'], employee['currentLng']),
                    16,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            icon: const Icon(Icons.location_on),
            label: const Text('Show on Map'),
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

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Date Selector
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
                        DateFormat('MMM dd, yyyy').format(selectedDate),
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
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
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

        // History List
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Select a date to view history',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final isActive = record['punchOutTime'] == '--:--';

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
                      record['employeeName'][0].toUpperCase(),
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
                          record['employeeName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${record['employeeCode']} • ${record['role']}',
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
                      record['punchInTime'],
                      Colors.green,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.logout,
                      'Punch Out',
                      record['punchOutTime'],
                      Colors.red,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.timer,
                      'Duration',
                      record['workDuration'],
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
                                  record['travelDistance'] != null
                                      ? '${record['travelDistance']} km'
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
                                  '${record['startKm']} → ${record['endKm'] ?? '--'}',
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

  void _showAttendanceDetails(Map<String, dynamic> record) {
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
                      record['employeeName'][0].toUpperCase(),
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
                          record['employeeName'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${record['employeeCode']} • ${record['role']}',
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
              _buildDetailSection(
                'Punch In Details',
                Icons.login,
                Colors.green,
                [
                  _buildDetailRow('Time', record['punchInTime']),
                  _buildDetailRow('Location', record['punchInLocation']),
                  _buildDetailRow('KM Reading', record['startKm']),
                ],
              ),
              const SizedBox(height: 24),

              // Punch Out Section
              _buildDetailSection(
                'Punch Out Details',
                Icons.logout,
                Colors.red,
                [
                  _buildDetailRow('Time', record['punchOutTime']),
                  _buildDetailRow(
                    'Location',
                    record['punchOutLocation'] ?? '--',
                  ),
                  _buildDetailRow('KM Reading', record['endKm'] ?? '--'),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Section
              _buildDetailSection('Summary', Icons.summarize, primaryColor, [
                _buildDetailRow('Work Duration', record['workDuration']),
                _buildDetailRow(
                  'Travel Distance',
                  record['travelDistance'] != null
                      ? '${record['travelDistance']} km'
                      : '--',
                ),
                _buildDetailRow('Status', record['status']),
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
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
