import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/route_service.dart';
import '../../models/attendance_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _liveTimer;
  GoogleMapController? _mapController;
  late AnimationController _pulseController;

  bool isLoading = true;
  String? errorMessage;

  // Data
  List<AttendanceModel> activeEmployees = [];
  List<Map<String, dynamic>> historicalRoutes = [];
  String? selectedSalesmanId;
  DateTime selectedDate = DateTime.now();

  // Map data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, List<LatLng>> employeeRoutes = {};
  Map<String, LatLng> homeLocations =
      {}; // Store home locations for each employee

  // State
  bool isLiveTrackingEnabled = true;
  bool showRoutes = true;
  bool showHomeLocations = true;

  // Colors
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
    _loadActiveEmployees();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveTimer?.cancel();
    _refreshTimer?.cancel();
    _mapController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startLiveTracking() {
    if (isLiveTrackingEnabled) {
      _liveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _loadActiveEmployees();
        _loadEmployeeRoutes();
      });
    }
  }

  Future<void> _loadActiveEmployees() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] == true && mounted) {
        final allAttendance = result['data']['attendances'] ?? [];
        final newActiveEmployees = allAttendance
            .where((a) => a.status == 'active')
            .cast<AttendanceModel>()
            .toList();

        await _loadCurrentPositions(newActiveEmployees);
        await _loadHomeLocations(newActiveEmployees);

        setState(() {
          activeEmployees = newActiveEmployees;
          isLoading = false;
        });
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load active employees: $e');
      }
    }
  }

  Future<void> _loadCurrentPositions(List<AttendanceModel> employees) async {
    try {
      final result = await AttendanceService.getCurrentPositions();
      if (result['success'] == true && mounted) {
        final positions = result['data']['positions'] as List;

        for (var employee in employees) {
          final positionData = positions.firstWhere(
            (pos) => pos['employeeId'] == employee.employeeId,
            orElse: () => null,
          );

          if (positionData != null) {
            employee.currentLatitude = positionData['currentLatitude'];
            employee.currentLongitude = positionData['currentLongitude'];
            employee.currentDistanceKm = positionData['currentDistanceKm'];
            employee.isMoving = positionData['isMoving'] ?? false;
            employee.speed = positionData['speed'] ?? 0.0;
            employee.lastPositionUpdate =
                positionData['lastPositionUpdate'] != null
                ? DateTime.parse(positionData['lastPositionUpdate'])
                : employee.punchInTime;
          }
        }
      }
    } catch (e) {
      print('Failed to load current positions: $e');
    }
  }

  Future<void> _loadHomeLocations(List<AttendanceModel> employees) async {
    try {
      for (var employee in employees) {
        homeLocations[employee.employeeId] = LatLng(
          employee.punchInLatitude,
          employee.punchInLongitude,
        );
      }
    } catch (e) {
      print('Failed to load home locations: $e');
    }
  }

  Future<void> _loadEmployeeRoutes() async {
    if (!showRoutes) return;

    try {
      for (var employee in activeEmployees) {
        final result = await RouteService.getAttendanceRoute(employee.id);
        if (result['success'] == true && mounted) {
          final routePoints = result['data']['routePoints'] as List?;
          if (routePoints != null && routePoints.isNotEmpty) {
            employeeRoutes[employee.id] = routePoints
                .map(
                  (point) => LatLng(
                    point['latitude'] as double,
                    point['longitude'] as double,
                  ),
                )
                .toList();
          }
        }
      }
      _updateRoutePolylines();
    } catch (e) {
      print('Failed to load employee routes: $e');
    }
  }

  Future<void> _loadHistoricalRoutes() async {
    try {
      setState(() => isLoading = true);

      final result = await _getHistoricalRoutes(
        selectedDate,
        selectedSalesmanId,
      );
      if (result['success'] == true && mounted) {
        setState(() {
          historicalRoutes = List<Map<String, dynamic>>.from(
            result['data'] ?? [],
          );
          isLoading = false;
        });
        _updateHistoricalMapData();
      } else {
        setState(() {
          historicalRoutes = [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          historicalRoutes = [];
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load historical routes: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _getHistoricalRoutes(
    DateTime date,
    String? employeeId,
  ) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'date': DateFormat('yyyy-MM-dd').format(date),
      };

      // If specific employee selected, add employeeId
      if (employeeId != null) {
        queryParams['employeeId'] = employeeId;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/routes/historical',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data':
              data['data']['routes'] ??
              [], // Extract routes array from nested data
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch historical routes',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};

    // Add current position markers for active employees
    for (var employee in activeEmployees) {
      if (employee.currentLatitude != null &&
          employee.currentLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('current_${employee.employeeId}'),
            position: LatLng(
              employee.currentLatitude!,
              employee.currentLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              employee.isMoving == true
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: employee.employeeName,
              snippet:
                  'Current Location - ${employee.isMoving == true ? "Moving" : "Stationary"}',
            ),
          ),
        );
      }
    }

    // Add home location markers if enabled
    if (showHomeLocations) {
      for (var entry in homeLocations.entries) {
        final employeeId = entry.key;
        final homeLocation = entry.value;
        final employee = activeEmployees.firstWhere(
          (e) => e.employeeId == employeeId,
          orElse: () => activeEmployees.first,
        );

        markers.add(
          Marker(
            markerId: MarkerId('home_$employeeId'),
            position: homeLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: '🏠 ${employee.employeeName} - Home',
              snippet:
                  'Started work at ${DateFormat('hh:mm a').format(employee.punchInTime)}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updateRoutePolylines() {
    Set<Polyline> polylines = {};

    for (var entry in employeeRoutes.entries) {
      final employeeId = entry.key;
      final routePoints = entry.value;

      if (routePoints.length > 1) {
        final employee = activeEmployees.firstWhere(
          (e) => e.id == employeeId,
          orElse: () => activeEmployees.first,
        );

        polylines.add(
          Polyline(
            polylineId: PolylineId(employeeId),
            points: routePoints,
            color: employee.isMoving == true ? successColor : warningColor,
            width: 3,
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _updateHistoricalMapData() {
    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    for (var route in historicalRoutes) {
      final employeeId = route['employeeId'] as String;
      final employeeName = route['employeeName'] as String;
      final homeLocation = route['homeLocation'] as Map<String, dynamic>?;
      final startLocation = route['startLocation'] as Map<String, dynamic>?;
      final endLocation = route['endLocation'] as Map<String, dynamic>?;
      final routePreview = route['routePreview'] as List?;

      // Add home location marker (purple marker for where salesman started working)
      if (homeLocation != null) {
        final homeLatLng = LatLng(
          homeLocation['latitude'] as double,
          homeLocation['longitude'] as double,
        );

        markers.add(
          Marker(
            markerId: MarkerId('historical_home_$employeeId'),
            position: homeLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: '🏠 $employeeName - Home',
              snippet:
                  'Started: ${DateFormat('hh:mm a').format(DateTime.parse(homeLocation['time']))}',
            ),
          ),
        );
      }

      // Add punch-in location marker (start location - green)
      if (startLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('historical_start_$employeeId'),
            position: LatLng(
              startLocation['latitude'] as double,
              startLocation['longitude'] as double,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: '▶️ $employeeName - Punch In',
              snippet:
                  'Started: ${DateFormat('hh:mm a').format(DateTime.parse(startLocation['time']))}',
            ),
          ),
        );
      }

      // Add punch-out location marker if available (end location - red)
      if (endLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('historical_end_$employeeId'),
            position: LatLng(
              endLocation['latitude'] as double,
              endLocation['longitude'] as double,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: '⏹️ $employeeName - Punch Out',
              snippet:
                  'Ended: ${DateFormat('hh:mm a').format(DateTime.parse(endLocation['time']))}',
            ),
          ),
        );
      }

      // Add route polyline from preview points
      if (routePreview != null && routePreview.length > 1) {
        final points = routePreview
            .map(
              (point) => LatLng(
                point['latitude'] as double,
                point['longitude'] as double,
              ),
            )
            .toList();

        polylines.add(
          Polyline(
            polylineId: PolylineId('historical_route_$employeeId'),
            points: points,
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Live Employee Tracking'),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Live Tracking'),
            Tab(icon: Icon(Icons.route), text: 'Route Playback'),
            Tab(icon: Icon(Icons.history), text: 'Historical Routes'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(showHomeLocations ? Icons.home : Icons.home_outlined),
            onPressed: () {
              setState(() {
                showHomeLocations = !showHomeLocations;
              });
              _updateMapMarkers();
            },
            tooltip: 'Toggle Home Locations',
          ),
          IconButton(
            icon: Icon(showRoutes ? Icons.route : Icons.route_outlined),
            onPressed: () {
              setState(() {
                showRoutes = !showRoutes;
              });
              if (showRoutes) {
                _loadEmployeeRoutes();
              } else {
                setState(() {
                  _polylines.clear();
                });
              }
            },
            tooltip: 'Toggle Routes',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTrackingTab(),
          _buildRoutePlaybackTab(),
          _buildHistoricalRoutesTab(),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                isLiveTrackingEnabled ? Icons.play_circle : Icons.pause_circle,
                color: isLiveTrackingEnabled ? successColor : warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                isLiveTrackingEnabled
                    ? 'Live Tracking Active'
                    : 'Live Tracking Paused',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLiveTrackingEnabled ? successColor : warningColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: isLiveTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    isLiveTrackingEnabled = value;
                  });
                  if (value) {
                    _startLiveTracking();
                  } else {
                    _liveTimer?.cancel();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildMap()),
        _buildActiveEmployeesList(),
      ],
    );
  }

  Widget _buildRoutePlaybackTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              const Text(
                'Route Playback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSalesmanId,
                      decoration: const InputDecoration(
                        labelText: 'Select Employee',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Select Employee'),
                        ),
                        ...activeEmployees.map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee.employeeId,
                            child: Text(employee.employeeName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSalesmanId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedSalesmanId == null
              ? const Center(
                  child: Text(
                    'Select an employee to view route playback',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blue[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              // TODO: Implement route playback animation
                              _showInfoSnackBar(
                                'Route playback animation will be implemented',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause),
                            onPressed: () {
                              // TODO: Pause playback
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop),
                            onPressed: () {
                              // TODO: Stop playback
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.speed),
                            onPressed: () {
                              // TODO: Change playback speed
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildMap()),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHistoricalRoutesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historical Routes - ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSalesmanId,
                      decoration: const InputDecoration(
                        labelText: 'Select Salesman',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Salesmen'),
                        ),
                        ...activeEmployees.map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee.employeeId,
                            child: Text(employee.employeeName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSalesmanId = value;
                        });
                        _loadHistoricalRoutes();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loadHistoricalRoutes,
                    child: const Text('Load Routes'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMap(),
        ),
        if (historicalRoutes.isNotEmpty) _buildHistoricalRoutesSummary(),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadHistoricalRoutes();
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(28.6139, 77.2090),
        zoom: 10,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildActiveEmployeesList() {
    if (activeEmployees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No active employees found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 120,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Active Employees (${activeEmployees.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeEmployees.length,
              itemBuilder: (context, index) {
                final employee = activeEmployees[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(left: 16, bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            employee.isMoving == true
                                ? Icons.directions_run
                                : Icons.location_on,
                            color: employee.isMoving == true
                                ? successColor
                                : warningColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              employee.employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Working: ${_getWorkingDuration(employee.punchInTime)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (employee.currentDistanceKm != null)
                        Text(
                          'Distance: ${employee.currentDistanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalRoutesSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Routes Summary (${historicalRoutes.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: historicalRoutes.length,
              itemBuilder: (context, index) {
                final route = historicalRoutes[index];
                final routeSummary =
                    route['routeSummary'] as Map<String, dynamic>?;
                final startLocation =
                    route['startLocation'] as Map<String, dynamic>?;
                final endLocation =
                    route['endLocation'] as Map<String, dynamic>?;

                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['employeeName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (startLocation != null)
                        Text(
                          'Start: ${DateFormat('hh:mm a').format(DateTime.parse(startLocation['time']))}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      if (endLocation != null)
                        Text(
                          'End: ${DateFormat('hh:mm a').format(DateTime.parse(endLocation['time']))}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      if (routeSummary != null &&
                          routeSummary['totalWorkHours'] != null)
                        Text(
                          'Hours: ${routeSummary['totalWorkHours'].toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkingDuration(DateTime punchInTime) {
    final duration = DateTime.now().difference(punchInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: errorColor),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }
}
