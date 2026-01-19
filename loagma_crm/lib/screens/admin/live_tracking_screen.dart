<<<<<<< HEAD
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
=======
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/route_service.dart';
import '../../services/admin_live_tracking_socket.dart';
import '../../models/attendance_model.dart';
import 'route_playback_screen.dart';
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

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
<<<<<<< HEAD
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  late AnimationController _pulseController;
  StreamSubscription? _locationSubscription;

  StreamSubscription? _connectionSubscription;

  // Annotation managers for markers and polylines
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  // Store annotations by ID for updates
  final Map<String, PointAnnotation> _markerAnnotations = {};
  final Map<String, PolylineAnnotation> _polylineAnnotations = {};

=======
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionSubscription;

>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  bool isLoading = true;
  String? errorMessage;

  // Data
  List<AttendanceModel> activeEmployees = [];
<<<<<<< HEAD
  List<Map<String, dynamic>> allEmployees = [];
=======
  List<Map<String, dynamic>> allEmployees =
      []; // All employees for historical dropdown
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  List<Map<String, dynamic>> historicalRoutes = [];
  String? selectedSalesmanId;
  DateTime selectedDate = DateTime.now();

  // Map data
<<<<<<< HEAD
  Map<String, List<Position>> employeeRoutes = {};
  Map<String, Position> homeLocations = {};
=======
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, List<LatLng>> employeeRoutes = {};
  Map<String, LatLng> homeLocations =
      {}; // Store home locations for each employee
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

  // State
  bool isLiveTrackingEnabled = true;
  bool showRoutes = true;
  bool showHomeLocations = true;
<<<<<<< HEAD
  String? selectedEmployeeId;
=======
  String? selectedEmployeeId; // Track selected employee for highlighting
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

  // Colors
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
<<<<<<< HEAD
    _tabController.addListener(_onTabChanged);
    _initializeAnimations();
    _loadActiveEmployees();
    _loadAllEmployees();
    _startLiveTracking();
    _initializeWebSocket();
=======
    _tabController.addListener(_onTabChanged); // Add tab change listener
    _initializeAnimations();
    _loadActiveEmployees();
    _loadAllEmployees(); // Load all employees for historical dropdown
    _startLiveTracking();
    _initializeWebSocket(); // Initialize WebSocket for real-time updates
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
    _mapboxService.dispose();
    _mapboxMap = null;
=======
    // Set to null before disposing to prevent use after dispose
    final controller = _mapController;
    _mapController = null;
    controller?.dispose();
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
      _liveTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
        await _refreshEmployeeListOnly();
        // Also refresh routes periodically if enabled
        if (showRoutes && _tabController.index == 0 && mounted) {
          await _loadEmployeeRoutes();
        }
=======
      // Reduce REST polling frequency since WebSocket handles real-time updates
      // Only refresh employee list, not positions (WebSocket handles positions)
      _liveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        _refreshEmployeeListOnly(); // Only refresh employee list, not map
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      });
    }
  }

<<<<<<< HEAD
=======
  /// Refresh only the employee list without rebuilding the map
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  Future<void> _refreshEmployeeListOnly() async {
    try {
      final result = await AttendanceService.getLiveAttendanceDashboard();
      if (result['success'] == true && mounted) {
        final allAttendance = result['data']['attendances'] ?? [];
        final newActiveEmployees = allAttendance
            .where((a) => a.status == 'active')
            .cast<AttendanceModel>()
            .toList();

<<<<<<< HEAD
=======
        // Only update the employee list, don't rebuild map markers
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        setState(() {
          activeEmployees = newActiveEmployees;
        });
      }
    } catch (e) {
      print('Failed to refresh employee list: $e');
    }
  }

<<<<<<< HEAD
  Future<void> _initializeWebSocket() async {
    try {
=======
  /// Initialize WebSocket connection for real-time location updates
  Future<void> _initializeWebSocket() async {
    try {
      // Connect to WebSocket
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      final connected = await AdminLiveTrackingSocket.instance.connect();
      if (!connected) {
        print('⚠️ WebSocket connection failed, falling back to REST polling');
        return;
      }

<<<<<<< HEAD
=======
      // Listen to real-time location updates
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      _locationSubscription = AdminLiveTrackingSocket.instance.locationStream
          .listen(
            _handleRealTimeLocationUpdate,
            onError: (error) {
              print('❌ WebSocket location stream error: $error');
            },
          );

<<<<<<< HEAD
=======
      // Listen to connection status
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      _connectionSubscription = AdminLiveTrackingSocket
          .instance
          .connectionStream
          .listen(_handleConnectionStatusChange);

      print('✅ WebSocket initialized for real-time tracking');
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
    }
  }

<<<<<<< HEAD
  void _handleRealTimeLocationUpdate(LocationUpdate update) {
    if (!mounted) return;
    if (_tabController.index != 0) return;
=======
  /// Handle real-time location updates from WebSocket
  void _handleRealTimeLocationUpdate(LocationUpdate update) {
    if (!mounted) return; // Widget disposed
    if (_tabController.index != 0) return; // Only update on Live Tracking tab
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

    try {
      final salesmanId = update.salesmanId;
      final location = update.location;

<<<<<<< HEAD
=======
      // Find employee in active list
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      final employeeIndex = activeEmployees.indexWhere(
        (emp) => emp.employeeId == salesmanId,
      );

      if (employeeIndex != -1) {
<<<<<<< HEAD
=======
        // Update employee's current position and distance
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        final employee = activeEmployees[employeeIndex];
        employee.currentLatitude = location.latitude;
        employee.currentLongitude = location.longitude;
        employee.lastPositionUpdate = location.timestamp;
<<<<<<< HEAD
        employee.isMoving = location.speed != null && location.speed! > 0;
        employee.currentDistanceKm = location.totalDistanceKm;
        employee.speed = location.speed ?? 0.0;

        if (mounted) {
          setState(() {
            // Trigger UI rebuild with updated data
          });
          
          // Update marker and route asynchronously
          _updateSalesmanMarker(employee, location).then((_) {
            if (mounted && showRoutes) {
              _updateSalesmanRoute(salesmanId);
            }
          }).catchError((e) {
            print('Error updating marker/route: $e');
          });
        }
      } else {
        // Employee not in active list, but we still want to show their route if tracking
        if (mounted && showRoutes) {
          _updateSalesmanRoute(salesmanId);
        }
      }
    } catch (e) {
      print('Error handling real-time location update: $e');
=======
        employee.isMoving = true; // Assume moving if sending updates
        employee.currentDistanceKm =
            location.totalDistanceKm; // Update distance from WebSocket

        // Update marker smoothly without rebuilding map
        if (mounted) {
          _updateSalesmanMarker(employee, location);

          // Update route polyline
          _updateSalesmanRoute(salesmanId, location.latLng);
        }
      }
    } catch (e) {
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      // Ignore errors after dispose
    }
  }

<<<<<<< HEAD
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
    if (!showRoutes || _polylineAnnotationManager == null || !mounted) return;

    try {
      final polylineId = 'realtime_$salesmanId';
      
      // Get real-time route from WebSocket
      final realtimeRoute = AdminLiveTrackingSocket.instance.getSalesmanRoute(salesmanId);
      
      // Find employee to get attendance ID for historical route
      final employee = activeEmployees.firstWhere(
        (e) => e.employeeId == salesmanId,
        orElse: () => activeEmployees.firstWhere(
          (e) => e.employeeId == salesmanId,
          orElse: () => activeEmployees.first,
        ),
      );
      
      // Get historical route from database
      List<Position> historicalPositions = [];
      if (employee.id.isNotEmpty) {
        final result = await RouteService.getAttendanceRoute(employee.id);
        if (result['success'] == true) {
          final routePoints = result['data']['routePoints'] as List?;
          if (routePoints != null && routePoints.isNotEmpty) {
            historicalPositions = routePoints
                .map((point) => Position(
                      point['longitude'] as double,
                      point['latitude'] as double,
                    ))
                .toList();
          }
        }
      }
      
      // Combine historical and real-time routes
      List<Position> allPositions = [];
      
      // Get last historical coordinates for duplicate checking
      double? lastHistoricalLat;
      double? lastHistoricalLng;
      if (employee.id.isNotEmpty) {
        final routeResult = await RouteService.getAttendanceRoute(employee.id);
        if (routeResult['success'] == true) {
          final routePoints = routeResult['data']['routePoints'] as List?;
          if (routePoints != null && routePoints.isNotEmpty) {
            final lastPoint = routePoints.last;
            lastHistoricalLat = (lastPoint['latitude'] as num).toDouble();
            lastHistoricalLng = (lastPoint['longitude'] as num).toDouble();
          }
        }
      }
      
      // Add historical positions first
      allPositions.addAll(historicalPositions);
      
      // Add real-time positions (avoid duplicates near last historical point)
      for (var latLng in realtimeRoute) {
        bool shouldAdd = true;
        
        // Check if this point is too close to the last historical point
        if (lastHistoricalLat != null && lastHistoricalLng != null) {
          final distance = _calculateDistance(
            lastHistoricalLat,
            lastHistoricalLng,
            latLng.latitude,
            latLng.longitude,
          );
          // If very close to last historical point (< 50 meters), skip to avoid overlap
          if (distance < 0.05) {
            shouldAdd = false;
          }
        }
        
        if (shouldAdd) {
          final pos = Position(latLng.longitude, latLng.latitude);
          allPositions.add(pos);
        }
      }
      
      // Remove old polyline
      final oldPolyline = _polylineAnnotations[polylineId];
      if (oldPolyline != null) {
        await _polylineAnnotationManager!.delete(oldPolyline);
        _polylineAnnotations.remove(polylineId);
      }
      
      // Create new polyline if we have enough points
      if (allPositions.length > 1) {
        final isSelected = selectedEmployeeId == salesmanId;
        final employeeForColor = activeEmployees.firstWhere(
          (e) => e.employeeId == salesmanId,
          orElse: () => employee,
        );
        
        final options = PolylineAnnotationOptions(
          geometry: LineString(coordinates: allPositions),
          lineColor: isSelected
              ? Colors.blue.value
              : employeeForColor.isMoving == true
                  ? successColor.value
                  : warningColor.value,
          lineWidth: isSelected ? 5.0 : 3.0,
          lineOpacity: 0.8,
        );

        final polyline = await _polylineAnnotationManager!.create(options);
        if (mounted) {
          _polylineAnnotations[polylineId] = polyline;
        }
      }
    } catch (e) {
      print('Error updating salesman route: $e');
    }
  }
  
  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _handleConnectionStatusChange(bool isConnected) {
    if (mounted) {
      setState(() {});
=======
  /// Update specific salesman marker smoothly
  void _updateSalesmanMarker(
    AttendanceModel employee,
    SalesmanLocation location,
  ) {
    final markerId = MarkerId('current_${employee.employeeId}');

    // Find existing marker
    final existingMarker = _markers.firstWhere(
      (marker) => marker.markerId == markerId,
      orElse: () => Marker(markerId: markerId),
    );

    // Create updated marker with distance info
    final distanceText = location.totalDistanceKm > 0
        ? ' | ${location.totalDistanceKm.toStringAsFixed(2)} km'
        : '';
    final updatedMarker = existingMarker.copyWith(
      positionParam: location.latLng,
      infoWindowParam: InfoWindow(
        title: employee.employeeName,
        snippet:
            'Live Location - Moving$distanceText (${DateFormat('HH:mm:ss').format(location.timestamp)})',
      ),
    );

    // Update marker set
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == markerId);
      _markers.add(updatedMarker);
    });
  }

  /// Update salesman route polyline
  void _updateSalesmanRoute(String salesmanId, LatLng newPoint) {
    if (!showRoutes) return;

    final polylineId = PolylineId('realtime_$salesmanId');
    final route = AdminLiveTrackingSocket.instance.getSalesmanRoute(salesmanId);

    if (route.length > 1) {
      final polyline = Polyline(
        polylineId: polylineId,
        points: route,
        color: successColor,
        width: 3,
      );

      setState(() {
        _polylines.removeWhere((p) => p.polylineId == polylineId);
        _polylines.add(polyline);
      });
    }
  }

  /// Handle WebSocket connection status changes
  void _handleConnectionStatusChange(bool isConnected) {
    if (mounted) {
      setState(() {
        // Update UI to show connection status
      });
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

      if (isConnected) {
        _showInfoSnackBar('Real-time tracking connected');
      } else {
        _showErrorSnackBar('Real-time tracking disconnected');
      }
    }
  }

  void _onTabChanged() {
<<<<<<< HEAD
    if (_mapboxMap != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});

=======
    // Prevent map control conflicts during tab changes
    if (_mapController != null) {
      // Small delay to allow tab animation to complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            // Force map to refresh its state
          });

          // Load routes when switching to live tracking tab
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
=======
      // Load all employees who have attendance records for dropdown
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      final result = await AttendanceService.getAllAttendance(limit: 1000);
      if (result['success'] == true && mounted) {
        final attendances = result['data'] as List<AttendanceModel>;

<<<<<<< HEAD
=======
        // Extract unique employees
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD

        await _updateMapMarkers();

=======
        _updateMapMarkers();

        // Auto-focus camera on first active employee
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        if (newActiveEmployees.isNotEmpty) {
          _focusCameraOnActiveEmployees();
        }

<<<<<<< HEAD
=======
        // Load routes if enabled and on live tracking tab
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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

<<<<<<< HEAD
  void _focusCameraOnActiveEmployees() {
    if (!mounted || _mapboxMap == null || activeEmployees.isEmpty) return;

    try {
=======
  /// Focus camera on all active employees or first one
  void _focusCameraOnActiveEmployees() {
    if (!mounted || _mapController == null || activeEmployees.isEmpty) return;

    try {
      // If only one employee, focus on them
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      if (activeEmployees.length == 1) {
        final employee = activeEmployees.first;
        final lat = employee.currentLatitude ?? employee.punchInLatitude;
        final lng = employee.currentLongitude ?? employee.punchInLongitude;

<<<<<<< HEAD
        _mapboxService.animateCamera(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
=======
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 15.0),
          ),
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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

<<<<<<< HEAD
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
=======
      // Add some padding
      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          50.0,
        ),
      );
    } catch (e) {
      // Ignore map controller errors after dispose
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
=======
            // Safe type conversion for numeric values
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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

<<<<<<< HEAD
=======
  // Helper method for safe type conversion
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
        homeLocations[employee.employeeId] = Position(
          employee.punchInLongitude,
          employee.punchInLatitude,
=======
        homeLocations[employee.employeeId] = LatLng(
          employee.punchInLatitude,
          employee.punchInLongitude,
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
        if (employee.id.isEmpty) continue;
        
=======
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        final result = await RouteService.getAttendanceRoute(employee.id);
        if (result['success'] == true && mounted) {
          final routePoints = result['data']['routePoints'] as List?;
          if (routePoints != null && routePoints.isNotEmpty) {
            employeeRoutes[employee.id] = routePoints
                .map(
<<<<<<< HEAD
                  (point) => Position(
                    point['longitude'] as double,
                    point['latitude'] as double,
=======
                  (point) => LatLng(
                    point['latitude'] as double,
                    point['longitude'] as double,
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
                  ),
                )
                .toList();
          }
        }
      }
<<<<<<< HEAD
      
      // Update polylines after loading historical routes
      if (mounted && _polylineAnnotationManager != null) {
        await _updateRoutePolylines();
      }
=======
      _updateRoutePolylines();
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
    } catch (e) {
      print('Failed to load employee routes: $e');
    }
  }

<<<<<<< HEAD
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
=======
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
      // Use current position if available, otherwise fall back to punch-in location
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      final lat = employee.currentLatitude ?? employee.punchInLatitude;
      final lng = employee.currentLongitude ?? employee.punchInLongitude;

      final isSelected = selectedEmployeeId == employee.employeeId;
<<<<<<< HEAD

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
=======
      final hasCurrentPosition =
          employee.currentLatitude != null && employee.currentLongitude != null;

      markers.add(
        Marker(
          markerId: MarkerId('current_${employee.employeeId}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor
                      .hueBlue // Highlight selected employee
                : employee.isMoving == true
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${isSelected ? '⭐ ' : ''}${employee.employeeName}',
            snippet: hasCurrentPosition
                ? 'Live Location - ${employee.isMoving == true ? "Moving" : "Stationary"}'
                : 'Punch-in Location',
          ),
        ),
      );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
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

=======
        markers.add(
          Marker(
            markerId: MarkerId('home_$employeeId'),
            position: homeLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor
                        .hueBlue // Highlight selected employee's home
                  : BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title:
                  '🏠 ${isSelected ? '⭐ ' : ''}${employee.employeeName} - Home',
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

    // If an employee is selected, focus the camera on them
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
    if (selectedEmployeeId != null) {
      _focusOnSelectedEmployee();
    }
  }

<<<<<<< HEAD
  Future<void> _updateRoutePolylines() async {
    if (_polylineAnnotationManager == null || !showRoutes) return;

    // Don't clear all polylines - we want to keep real-time routes
    // Only clear historical routes that are no longer active
    final activeEmployeeIds = activeEmployees.map((e) => e.id).toSet();
    final routesToRemove = <String>[];
    
    for (var entry in _polylineAnnotations.entries) {
      // Check if this is a historical route (not realtime_ prefix)
      if (!entry.key.startsWith('realtime_')) {
        // Check if employee is still active
        if (!activeEmployeeIds.contains(entry.key)) {
          routesToRemove.add(entry.key);
        }
      }
    }
    
    // Remove inactive historical routes
    for (var key in routesToRemove) {
      final polyline = _polylineAnnotations[key];
      if (polyline != null) {
        await _polylineAnnotationManager!.delete(polyline);
        _polylineAnnotations.remove(key);
      }
    }

    // Add/update historical routes from database
=======
  void _updateRoutePolylines() {
    Set<Polyline> polylines = {};

>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
    for (var entry in employeeRoutes.entries) {
      final employeeId = entry.key;
      final routePoints = entry.value;

      if (routePoints.length > 1) {
        final employee = activeEmployees.firstWhere(
          (e) => e.id == employeeId,
          orElse: () => activeEmployees.first,
        );

        final isSelected = selectedEmployeeId == employee.employeeId;
<<<<<<< HEAD
        final polylineId = 'historical_$employeeId';

        // Remove old historical route if exists
        final oldPolyline = _polylineAnnotations[polylineId];
        if (oldPolyline != null) {
          await _polylineAnnotationManager!.delete(oldPolyline);
        }

        final options = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: isSelected
              ? Colors.blue.value
              : employee.isMoving == true
                  ? successColor.value
                  : warningColor.value,
          lineWidth: isSelected ? 5.0 : 3.0,
          lineOpacity: 0.6, // Slightly transparent for historical routes
        );

        final polyline = await _polylineAnnotationManager!.create(options);
        _polylineAnnotations[polylineId] = polyline;
      }
    }
    
    // Also update real-time routes for all active employees
    for (var employee in activeEmployees) {
      final realtimeRoute = AdminLiveTrackingSocket.instance.getSalesmanRoute(employee.employeeId);
      if (realtimeRoute.isNotEmpty) {
        _updateSalesmanRoute(employee.employeeId);
      }
    }
  }

  void _focusOnSelectedEmployee() {
    if (!mounted || selectedEmployeeId == null || _mapboxMap == null) return;
=======
        polylines.add(
          Polyline(
            polylineId: PolylineId(employeeId),
            points: routePoints,
            color: isSelected
                ? Colors
                      .blue // Highlight selected employee's route
                : employee.isMoving == true
                ? successColor
                : warningColor,
            width: isSelected ? 5 : 3, // Make selected route thicker
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  /// Focus camera on selected employee
  void _focusOnSelectedEmployee() {
    if (!mounted || selectedEmployeeId == null || _mapController == null)
      return;
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

    try {
      final selectedEmployee = activeEmployees.firstWhere(
        (e) => e.employeeId == selectedEmployeeId,
        orElse: () => activeEmployees.first,
      );

<<<<<<< HEAD
=======
      // Use current position if available, otherwise fall back to punch-in location
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      final lat =
          selectedEmployee.currentLatitude ?? selectedEmployee.punchInLatitude;
      final lng =
          selectedEmployee.currentLongitude ??
          selectedEmployee.punchInLongitude;

<<<<<<< HEAD
      _mapboxService.animateCamera(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.0,
=======
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15.0),
        ),
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      );
    } catch (e) {
      // Ignore map controller errors after dispose
    }
  }

<<<<<<< HEAD
=======
  void _updateHistoricalMapData() {
    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    for (var route in historicalRoutes) {
      final employeeId = route['employeeId'] as String;
      final employeeName = route['employeeName'] as String;
      final homeLocation = route['homeLocation'] as Map<String, dynamic>?;
      final startLocation = route['startLocation'] as Map<String, dynamic>?;
      final endLocation = route['endLocation'] as Map<String, dynamic>?;

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

      // Add route polyline from full route points
      final routePoints = route['routePoints'] as List?;
      if (routePoints != null && routePoints.length > 1) {
        final points = routePoints
            .map(
              (point) => LatLng(
                (point['latitude'] as num).toDouble(),
                (point['longitude'] as num).toDouble(),
              ),
            )
            .toList();

        polylines.add(
          Polyline(
            polylineId: PolylineId('historical_route_$employeeId'),
            points: points,
            color: Colors.blue,
            width: 4,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
            onPressed: () async {
=======
            onPressed: () {
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
              setState(() {
                showRoutes = !showRoutes;
              });
              if (showRoutes) {
<<<<<<< HEAD
                // Load and display routes
                await _loadEmployeeRoutes();
                // Also update real-time routes
                for (var employee in activeEmployees) {
                  final realtimeRoute = AdminLiveTrackingSocket.instance
                      .getSalesmanRoute(employee.employeeId);
                  if (realtimeRoute.isNotEmpty) {
                    await _updateSalesmanRoute(employee.employeeId);
                  }
                }
              } else {
                // Clear all route polylines
                if (_polylineAnnotationManager != null) {
                  for (var polyline in _polylineAnnotations.values) {
                    await _polylineAnnotationManager!.delete(polyline);
                  }
                  _polylineAnnotations.clear();
                }
=======
                _loadEmployeeRoutes();
              } else {
                setState(() {
                  _polylines.clear();
                });
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
              }
            },
            tooltip: 'Toggle Routes',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
<<<<<<< HEAD
        physics: const NeverScrollableScrollPhysics(),
=======
        physics:
            const NeverScrollableScrollPhysics(), // Disable physical tab switching for better map controls
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
              // WebSocket connection status
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AdminLiveTrackingSocket.instance.isConnected
                      ? successColor
                      : errorColor,
                ),
              ),
              const SizedBox(width: 8),
=======
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
              Icon(
                isLiveTrackingEnabled ? Icons.play_circle : Icons.pause_circle,
                color: isLiveTrackingEnabled ? successColor : warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
<<<<<<< HEAD
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLiveTrackingEnabled
                          ? 'Live Tracking Active'
                          : 'Live Tracking Paused',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLiveTrackingEnabled ? successColor : warningColor,
                      ),
                    ),
                    if (AdminLiveTrackingSocket.instance.isConnected)
                      Text(
                        'Real-time: ${activeEmployees.length} employees',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
=======
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
              // Refresh button
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
=======
              // Focus all button
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
              : _buildMapboxMap(),
=======
              : _buildMap(),
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        ),
        _buildActiveEmployeesList(),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildMapboxMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(77.2090, 28.6139)), // Delhi
        zoom: 10.0,
      ),
      styleUri: MapboxConfig.defaultMapStyle, // Using street map style
      textureView: true,
      onMapCreated: _onMapCreated,
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      _mapboxMap = map;
      _mapboxService.initialize(map);

      // Create annotation managers
      _pointAnnotationManager = await map.annotations
          .createPointAnnotationManager();
      _polylineAnnotationManager = await map.annotations
          .createPolylineAnnotationManager();

      print('✅ Mapbox map and annotation managers created successfully!');

      // Load initial data
      if (activeEmployees.isNotEmpty) {
        await _updateMapMarkers();
        if (showRoutes) {
          // Load historical routes first
          await _loadEmployeeRoutes();
          // Then update with real-time routes
          await _updateRoutePolylines();
        }
      } else if (showRoutes) {
        // Even if no active employees, try to load routes for any tracked salesmen
        await _updateRoutePolylines();
      }

      print('✅ Mapbox map initialized with markers and routes!');
    } catch (e) {
      print('❌ Error initializing map: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to initialize map: $e';
        });
      }
    }
  }

  Widget _buildRoutePlaybackTab() {
    return const Center(
      child: Text(
        'Route Playback - Use original screen for full functionality',
        style: TextStyle(fontSize: 16, color: Colors.grey),
=======
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
                      value: selectedSalesmanId,
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
                        ...allEmployees.map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee['employeeId'],
                            child: Text(employee['employeeName']),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSalesmanId = value;
                        });
                        if (value != null) {
                          _loadRoutePlaybackData();
                        }
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
              const SizedBox(height: 8),
              Text(
                'Selected Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (selectedSalesmanId != null && historicalRoutes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text('Full Playback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (historicalRoutes.isNotEmpty) {
                          final route = historicalRoutes.first;
                          final employeeName =
                              route['employeeName'] as String? ?? 'Unknown';
                          final attendanceId = route['attendanceId'] as String;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoutePlaybackScreen(
                                attendanceId: attendanceId,
                                employeeName: employeeName,
                                date: selectedDate,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.analytics),
                      onPressed: () {
                        _showRouteAnalyticsDialog();
                      },
                      tooltip: 'View Analytics',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (historicalRoutes.isNotEmpty)
                  _buildRouteQuickStats(historicalRoutes.first),
              ],
            ),
          ),
          Expanded(child: _buildMap()),
        ] else if (selectedSalesmanId != null && isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (selectedSalesmanId != null)
          const Expanded(
            child: Center(
              child: Text(
                'No route data found for selected date',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Select an employee to view route playback',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  /// Build quick stats widget for route
  Widget _buildRouteQuickStats(Map<String, dynamic> route) {
    final routeSummary = route['routeSummary'] as Map<String, dynamic>?;
    final totalDistanceKm = routeSummary?['totalDistanceKm'] ?? 0.0;
    final duration = routeSummary?['duration'] ?? 0;
    final totalPoints = routeSummary?['totalPoints'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatChip(Icons.route, '${totalDistanceKm.toStringAsFixed(2)} km'),
        _buildStatChip(Icons.timer, '$duration min'),
        _buildStatChip(Icons.location_on, '$totalPoints pts'),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Show route analytics dialog
  Future<void> _showRouteAnalyticsDialog() async {
    if (historicalRoutes.isEmpty) return;

    final route = historicalRoutes.first;
    final attendanceId = route['attendanceId'] as String;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await RouteService.getRouteAnalytics(attendanceId);
      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true && mounted) {
        final data = result['data'];
        final summary = data['summary'] as Map<String, dynamic>?;

        if (summary != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Route Analytics - ${route['employeeName']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalyticsRow(
                      Icons.route,
                      'Total Distance',
                      '${summary['totalDistanceKm']?.toStringAsFixed(2) ?? '0'} km',
                    ),
                    _buildAnalyticsRow(
                      Icons.timer,
                      'Total Duration',
                      '${summary['totalDurationMinutes'] ?? 0} min',
                    ),
                    _buildAnalyticsRow(
                      Icons.directions_walk,
                      'Active Time',
                      '${summary['activeTimeMinutes'] ?? 0} min',
                    ),
                    _buildAnalyticsRow(
                      Icons.pause_circle,
                      'Idle Time',
                      '${summary['idleTimeMinutes'] ?? 0} min',
                    ),
                    _buildAnalyticsRow(
                      Icons.speed,
                      'Avg Speed',
                      '${summary['averageSpeedKmh']?.toStringAsFixed(1) ?? '0'} km/h',
                    ),
                    _buildAnalyticsRow(
                      Icons.location_on,
                      'Route Points',
                      '${summary['totalPoints'] ?? 0}',
                    ),
                    _buildAnalyticsRow(
                      Icons.hourglass_empty,
                      'Idle Periods',
                      '${summary['idlePeriodsCount'] ?? 0}',
                    ),
                  ],
                ),
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
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Error loading analytics: $e');
    }
  }

  Widget _buildAnalyticsRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildHistoricalRoutesTab() {
    return const Center(
      child: Text(
        'Historical Routes - Use original screen for full functionality',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
=======
  /// Load route data for playback
  Future<void> _loadRoutePlaybackData() async {
    if (selectedSalesmanId == null) return;

    try {
      setState(() => isLoading = true);

      final result = await _getHistoricalRoutes(
        selectedDate,
        selectedSalesmanId,
      );
      if (result['success'] == true && mounted) {
        final routes = List<Map<String, dynamic>>.from(result['data'] ?? []);

        if (routes.isNotEmpty) {
          setState(() {
            historicalRoutes = routes;
            isLoading = false;
          });
          _updateHistoricalMapData();
          _focusMapOnRoute();
        } else {
          setState(() {
            historicalRoutes = [];
            isLoading = false;
          });
          _showInfoSnackBar('No route data found for selected date');
        }
      } else {
        setState(() {
          historicalRoutes = [];
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load route data');
      }
    } catch (e) {
      setState(() {
        historicalRoutes = [];
        isLoading = false;
      });
      _showErrorSnackBar('Error loading route: $e');
    }
  }

  /// Focus map camera on the loaded route
  void _focusMapOnRoute() {
    if (!mounted || historicalRoutes.isEmpty || _mapController == null) return;

    try {
      final route = historicalRoutes.first;
      final routePreview = route['routePreview'] as List?;

      if (routePreview != null && routePreview.isNotEmpty) {
        final bounds = _calculateRouteBounds(routePreview);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );
      } else {
        // Focus on start location if no route preview
        final startLocation = route['startLocation'] as Map<String, dynamic>?;
        if (startLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  startLocation['latitude'] as double,
                  startLocation['longitude'] as double,
                ),
                zoom: 14.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Ignore map controller errors after dispose
    }
  }

  /// Calculate bounds for a route
  LatLngBounds _calculateRouteBounds(List routePoints) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in routePoints) {
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
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
                        ...allEmployees.map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee['employeeId'],
                            child: Text(employee['employeeName']),
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
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
=======
                      minimumSize: Size.zero,
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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
<<<<<<< HEAD
=======
                        // Show last update time with color indicator
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
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

<<<<<<< HEAD
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
=======
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
            height: 100,
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
                final totalDistanceKm = routeSummary?['totalDistanceKm'] ?? 0.0;

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
                      // Distance traveled
                      Row(
                        children: [
                          const Icon(Icons.route, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${totalDistanceKm.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
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

  /// Get icon for last update status
  IconData _getLastUpdateIcon(DateTime? lastUpdate) {
    if (lastUpdate == null) return Icons.signal_wifi_off;

    final minutesAgo = DateTime.now().difference(lastUpdate).inMinutes;
    if (minutesAgo < 2) return Icons.signal_wifi_4_bar;
    if (minutesAgo < 5)
      return Icons.signal_wifi_statusbar_connected_no_internet_4;
    if (minutesAgo < 15) return Icons.signal_wifi_bad;
    return Icons.signal_wifi_off;
  }

  /// Get color for last update status
  Color _getLastUpdateColor(DateTime? lastUpdate) {
    if (lastUpdate == null) return Colors.red;

    final minutesAgo = DateTime.now().difference(lastUpdate).inMinutes;
    if (minutesAgo < 2) return successColor;
    if (minutesAgo < 5) return Colors.orange;
    if (minutesAgo < 15) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get text for last update status
  String _getLastUpdateText(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'No updates';

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return 'Updated ${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      if (mins < 2) return 'Updated just now';
      if (mins < 5) return 'Updated ${mins}m ago';
      return 'Last update ${mins}m ago ⚠️';
    } else {
      final hours = difference.inHours;
      final mins = difference.inMinutes.remainder(60);
      return 'OFFLINE ${hours}h ${mins}m ❌';
    }
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
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
