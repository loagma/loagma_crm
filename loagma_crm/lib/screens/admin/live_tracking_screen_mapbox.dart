import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/mapbox_config.dart';
import '../../services/attendance_service.dart';
import '../../services/route_service.dart';
import '../../services/admin_live_tracking_socket.dart';
import '../../services/mapbox_service.dart';
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
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  late AnimationController _pulseController;
  StreamSubscription? _locationSubscription;

  StreamSubscription? _connectionSubscription;

  // Annotation managers for markers and polylines
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  // Store annotations by ID for updates
  Map<String, PointAnnotation> _markerAnnotations = {};
  Map<String, PolylineAnnotation> _polylineAnnotations = {};

  bool isLoading = true;
  String? errorMessage;

  // Data
  List<AttendanceModel> activeEmployees = [];
  List<Map<String, dynamic>> allEmployees = [];
  List<Map<String, dynamic>> historicalRoutes = [];
  String? selectedSalesmanId;
  DateTime selectedDate = DateTime.now();

  // Map data
  Map<String, List<Position>> employeeRoutes = {};
  Map<String, Position> homeLocations = {};

  // State
  bool isLiveTrackingEnabled = true;
  bool showRoutes = true;
  bool showHomeLocations = true;
  String? selectedEmployeeId;

  // Colors
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeAnimations();
    _loadActiveEmployees();
    _loadAllEmployees();
    _startLiveTracking();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    AdminLiveTrackingSocket.instance.disconnect();
    _pulseController.dispose();
    _liveTimer?.cancel();
    _refreshTimer?.cancel();
    _mapboxService.dispose();
    _mapboxMap = null;
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
      _liveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        _refreshEmployeeListOnly();
      });
    }
  }

  Future<void> _refreshEmployeeListOnly() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] == true && mounted) {
        final allAttendance = result['data']['attendances'] ?? [];
        final newActiveEmployees = allAttendance
            .where((a) => a.status == 'active')
            .cast<AttendanceModel>()
            .toList();

        setState(() {
          activeEmployees = newActiveEmployees;
        });
      }
    } catch (e) {
      print('Failed to refresh employee list: $e');
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      final connected = await AdminLiveTrackingSocket.instance.connect();
      if (!connected) {
        print('⚠️ WebSocket connection failed, falling back to REST polling');
        return;
      }

      _locationSubscription = AdminLiveTrackingSocket.instance.locationStream
          .listen(
            _handleRealTimeLocationUpdate,
            onError: (error) {
              print('❌ WebSocket location stream error: $error');
            },
          );

      _connectionSubscription = AdminLiveTrackingSocket
          .instance
          .connectionStream
          .listen(_handleConnectionStatusChange);

      print('✅ WebSocket initialized for real-time tracking');
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
    }
  }

  void _handleRealTimeLocationUpdate(LocationUpdate update) {
    if (!mounted) return;
    if (_tabController.index != 0) return;

    try {
      final salesmanId = update.salesmanId;
      final location = update.location;

      final employeeIndex = activeEmployees.indexWhere(
        (emp) => emp.employeeId == salesmanId,
      );

      if (employeeIndex != -1) {
        final employee = activeEmployees[employeeIndex];
        employee.currentLatitude = location.latitude;
        employee.currentLongitude = location.longitude;
        employee.lastPositionUpdate = location.timestamp;
        employee.isMoving = true;
        employee.currentDistanceKm = location.totalDistanceKm;

        if (mounted) {
          _updateSalesmanMarker(employee, location);
          _updateSalesmanRoute(salesmanId);
        }
      }
    } catch (e) {
      // Ignore errors after dispose
    }
  }

  Future<void> _updateSalesmanMarker(
    AttendanceModel employee,
    SalesmanLocation location,
  ) async {
    if (_pointAnnotationManager == null) return;

    final markerId = 'current_${employee.employeeId}';

    // Remove old marker if exists
    final oldMarker = _markerAnnotations[markerId];
    if (oldMarker != null) {
      await _pointAnnotationManager!.delete(oldMarker);
    }

    // Create new marker
    final options = PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(location.longitude, location.latitude),
      ),
      iconSize: 1.0,
      textField: employee.employeeName,
      textOffset: [0.0, -2.0],
      textSize: 12.0,
    );

    final marker = await _pointAnnotationManager!.create(options);
    _markerAnnotations[markerId] = marker;
  }

  Future<void> _updateSalesmanRoute(String salesmanId) async {
    if (!showRoutes || _polylineAnnotationManager == null) return;

    final polylineId = 'realtime_$salesmanId';
    final route = AdminLiveTrackingSocket.instance.getSalesmanRoute(salesmanId);

    if (route.length > 1) {
      // Remove old polyline
      final oldPolyline = _polylineAnnotations[polylineId];
      if (oldPolyline != null) {
        await _polylineAnnotationManager!.delete(oldPolyline);
      }

      // Convert LatLng to Position (Google Maps to Mapbox)
      final positions = route
          .map((latLng) => Position(latLng.longitude, latLng.latitude))
          .toList();

      // Create new polyline
      final options = PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: successColor.value,
        lineWidth: 3.0,
      );

      final polyline = await _polylineAnnotationManager!.create(options);
      _polylineAnnotations[polylineId] = polyline;
    }
  }

  void _handleConnectionStatusChange(bool isConnected) {
    if (mounted) {
      setState(() {});

      if (isConnected) {
        _showInfoSnackBar('Real-time tracking connected');
      } else {
        _showErrorSnackBar('Real-time tracking disconnected');
      }
    }
  }

  void _onTabChanged() {
    if (_mapboxMap != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});

          if (_tabController.index == 0 &&
              showRoutes &&
              activeEmployees.isNotEmpty) {
            _loadEmployeeRoutes();
          }
        }
      });
    }
  }

  Future<void> _loadAllEmployees() async {
    try {
      final result = await AttendanceService.getAllAttendance(limit: 1000);
      if (result['success'] == true && mounted) {
        final attendances = result['data'] as List<AttendanceModel>;

        final uniqueEmployees = <String, Map<String, dynamic>>{};
        for (var attendance in attendances) {
          uniqueEmployees[attendance.employeeId] = {
            'employeeId': attendance.employeeId,
            'employeeName': attendance.employeeName,
          };
        }

        setState(() {
          allEmployees = uniqueEmployees.values.toList();
        });
      }
    } catch (e) {
      print('Failed to load all employees: $e');
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

        await _updateMapMarkers();

        if (newActiveEmployees.isNotEmpty) {
          _focusCameraOnActiveEmployees();
        }

        if (showRoutes && _tabController.index == 0) {
          _loadEmployeeRoutes();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load active employees: $e');
      }
    }
  }

  void _focusCameraOnActiveEmployees() {
    if (!mounted || _mapboxMap == null || activeEmployees.isEmpty) return;

    try {
      if (activeEmployees.length == 1) {
        final employee = activeEmployees.first;
        final lat = employee.currentLatitude ?? employee.punchInLatitude;
        final lng = employee.currentLongitude ?? employee.punchInLongitude;

        _mapboxService.animateCamera(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
        );
        return;
      }

      // Multiple employees - fit all in view
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (var employee in activeEmployees) {
        final lat = employee.currentLatitude ?? employee.punchInLatitude;
        final lng = employee.currentLongitude ?? employee.punchInLongitude;

        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      }

      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;

      _mapboxService.fitBounds(
        bounds: CoordinateBounds(
          southwest: Point(
            coordinates: Position(minLng - lngPadding, minLat - latPadding),
          ),
          northeast: Point(
            coordinates: Position(maxLng + lngPadding, maxLat + latPadding),
          ),
          infiniteBounds: false,
        ),
      );
    } catch (e) {
      print('Map camera error (ignored): $e');
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
            employee.currentLatitude = _safeToDouble(
              positionData['currentLatitude'],
            );
            employee.currentLongitude = _safeToDouble(
              positionData['currentLongitude'],
            );
            employee.currentDistanceKm = _safeToDouble(
              positionData['currentDistanceKm'],
            );
            employee.isMoving = positionData['isMoving'] ?? false;
            employee.speed = _safeToDouble(positionData['speed']) ?? 0.0;
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

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _loadHomeLocations(List<AttendanceModel> employees) async {
    try {
      for (var employee in employees) {
        homeLocations[employee.employeeId] = Position(
          employee.punchInLongitude,
          employee.punchInLatitude,
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
                  (point) => Position(
                    point['longitude'] as double,
                    point['latitude'] as double,
                  ),
                )
                .toList();
          }
        }
      }
      await _updateRoutePolylines();
    } catch (e) {
      print('Failed to load employee routes: $e');
    }
  }

  // Historical routes functionality simplified - can be added later if needed

  Future<void> _updateMapMarkers() async {
    if (_pointAnnotationManager == null) return;

    // Clear existing markers
    for (var marker in _markerAnnotations.values) {
      await _pointAnnotationManager!.delete(marker);
    }
    _markerAnnotations.clear();

    // Add current position markers for active employees
    for (var employee in activeEmployees) {
      final lat = employee.currentLatitude ?? employee.punchInLatitude;
      final lng = employee.currentLongitude ?? employee.punchInLongitude;

      final isSelected = selectedEmployeeId == employee.employeeId;

      final markerId = 'current_${employee.employeeId}';

      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconSize: isSelected ? 1.2 : 1.0,
        textField: '${isSelected ? '⭐ ' : ''}${employee.employeeName}',
        textOffset: [0.0, -2.0],
        textSize: 12.0,
      );

      final marker = await _pointAnnotationManager!.create(options);
      _markerAnnotations[markerId] = marker;
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

        final isSelected = selectedEmployeeId == employeeId;
        final markerId = 'home_$employeeId';

        final options = PointAnnotationOptions(
          geometry: Point(coordinates: homeLocation),
          iconSize: isSelected ? 1.2 : 1.0,
          textField: '🏠 ${isSelected ? '⭐ ' : ''}${employee.employeeName}',
          textOffset: [0.0, -2.0],
          textSize: 12.0,
        );

        final marker = await _pointAnnotationManager!.create(options);
        _markerAnnotations[markerId] = marker;
      }
    }

    if (selectedEmployeeId != null) {
      _focusOnSelectedEmployee();
    }
  }

  Future<void> _updateRoutePolylines() async {
    if (_polylineAnnotationManager == null) return;

    // Clear existing polylines
    for (var polyline in _polylineAnnotations.values) {
      await _polylineAnnotationManager!.delete(polyline);
    }
    _polylineAnnotations.clear();

    for (var entry in employeeRoutes.entries) {
      final employeeId = entry.key;
      final routePoints = entry.value;

      if (routePoints.length > 1) {
        final employee = activeEmployees.firstWhere(
          (e) => e.id == employeeId,
          orElse: () => activeEmployees.first,
        );

        final isSelected = selectedEmployeeId == employee.employeeId;

        final options = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: isSelected
              ? Colors.blue.value
              : employee.isMoving == true
              ? successColor.value
              : warningColor.value,
          lineWidth: isSelected ? 5.0 : 3.0,
        );

        final polyline = await _polylineAnnotationManager!.create(options);
        _polylineAnnotations[employeeId] = polyline;
      }
    }
  }

  void _focusOnSelectedEmployee() {
    if (!mounted || selectedEmployeeId == null || _mapboxMap == null) return;

    try {
      final selectedEmployee = activeEmployees.firstWhere(
        (e) => e.employeeId == selectedEmployeeId,
        orElse: () => activeEmployees.first,
      );

      final lat =
          selectedEmployee.currentLatitude ?? selectedEmployee.punchInLatitude;
      final lng =
          selectedEmployee.currentLongitude ??
          selectedEmployee.punchInLongitude;

      _mapboxService.animateCamera(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.0,
      );
    } catch (e) {
      // Ignore map controller errors after dispose
    }
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
                _updateRoutePolylines();
              }
            },
            tooltip: 'Toggle Routes',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                isLiveTrackingEnabled ? Icons.play_circle : Icons.pause_circle,
                color: isLiveTrackingEnabled ? successColor : warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLiveTrackingEnabled
                      ? 'Live Tracking Active'
                      : 'Live Tracking Paused',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isLiveTrackingEnabled ? successColor : warningColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  setState(() => isLoading = true);
                  await _loadActiveEmployees();
                  _showInfoSnackBar('Data refreshed');
                },
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.center_focus_strong, size: 20),
                onPressed: _focusCameraOnActiveEmployees,
                tooltip: 'Focus on employees',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
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
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMapboxMap(),
        ),
        _buildActiveEmployeesList(),
      ],
    );
  }

  Widget _buildMapboxMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(77.2090, 28.6139)), // Delhi
        zoom: 10.0,
      ),
      styleUri: MapboxConfig.defaultMapStyle,
      onMapCreated: _onMapCreated,
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _mapboxService.initialize(map);

    // Create annotation managers
    _pointAnnotationManager = await map.annotations
        .createPointAnnotationManager();
    _polylineAnnotationManager = await map.annotations
        .createPolylineAnnotationManager();

    // Load initial data
    if (activeEmployees.isNotEmpty) {
      await _updateMapMarkers();
      if (showRoutes) {
        await _updateRoutePolylines();
      }
    }

    print('✅ Mapbox map created successfully!');
  }

  Widget _buildRoutePlaybackTab() {
    return const Center(
      child: Text(
        'Route Playback - Use original screen for full functionality',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildHistoricalRoutesTab() {
    return const Center(
      child: Text(
        'Historical Routes - Use original screen for full functionality',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
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
      height: 140,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Active Employees (${activeEmployees.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (selectedEmployeeId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedEmployeeId = null;
                      });
                      _updateMapMarkers();
                      _updateRoutePolylines();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              itemCount: activeEmployees.length,
              itemBuilder: (context, index) {
                final employee = activeEmployees[index];
                final isSelected = selectedEmployeeId == employee.employeeId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEmployeeId = isSelected
                          ? null
                          : employee.employeeId;
                    });
                    _updateMapMarkers();
                    _updateRoutePolylines();
                    if (!isSelected) {
                      _focusOnSelectedEmployee();
                    }
                  },
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              employee.isMoving == true
                                  ? Icons.directions_run
                                  : Icons.location_on,
                              color: isSelected
                                  ? Colors.blue
                                  : employee.isMoving == true
                                  ? successColor
                                  : warningColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employee.employeeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isSelected ? Colors.blue[800] : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.star,
                                color: Colors.blue,
                                size: 14,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _getWorkingDuration(employee.punchInTime),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (employee.currentDistanceKm != null) ...[
                              Icon(
                                Icons.route,
                                size: 10,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${employee.currentDistanceKm!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              _getLastUpdateIcon(employee.lastPositionUpdate),
                              size: 10,
                              color: _getLastUpdateColor(
                                employee.lastPositionUpdate,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _getLastUpdateText(employee.lastPositionUpdate),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _getLastUpdateColor(
                                    employee.lastPositionUpdate,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isSelected ? 'Tap to deselect' : 'Tap to focus',
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
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
    );
  }

  // Helper methods
  String _getWorkingDuration(DateTime punchInTime) {
    final duration = DateTime.now().difference(punchInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  IconData _getLastUpdateIcon(DateTime? lastUpdate) {
    if (lastUpdate == null) return Icons.help_outline;
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 5) return Icons.check_circle;
    if (diff.inMinutes < 15) return Icons.warning;
    return Icons.error;
  }

  Color _getLastUpdateColor(DateTime? lastUpdate) {
    if (lastUpdate == null) return Colors.grey;
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 5) return successColor;
    if (diff.inMinutes < 15) return warningColor;
    return errorColor;
  }

  String _getLastUpdateText(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'No update';
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Extension to convert SalesmanLocation to Position
extension SalesmanLocationExtension on SalesmanLocation {
  Position get position => Position(longitude, latitude);
  Point get point => Point(coordinates: position);
}
