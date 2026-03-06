import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../services/user_service.dart';
import '../../services/api_config.dart';
import '../../services/tracking_api_service.dart';
import '../../services/admin_socket_service.dart';

/// Socket.IO-based Live Tracking Screen with Live and Historical tabs
class SocketLiveTrackingScreen extends StatefulWidget {
  const SocketLiveTrackingScreen({super.key});

  @override
  State<SocketLiveTrackingScreen> createState() =>
      _SocketLiveTrackingScreenState();
}

class _SocketLiveTrackingScreenState extends State<SocketLiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFD7BE69);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Tracking'),
        backgroundColor: primaryColor,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Live Tracking'),
            Tab(icon: Icon(Icons.history), text: 'Historical Routes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [LiveTrackingTab(), HistoricalRoutesTab()],
      ),
    );
  }
}

/// Live Tracking Tab - Socket.IO real-time tracking
class LiveTrackingTab extends StatefulWidget {
  const LiveTrackingTab({super.key});

  @override
  State<LiveTrackingTab> createState() => _LiveTrackingTabState();
}

class _LiveTrackingTabState extends State<LiveTrackingTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep socket alive when switching tabs

  static const Color primaryColor = Color(0xFFD7BE69);

  final MapController _mapController = MapController();

  // Stream subscriptions from global AdminSocketService
  StreamSubscription<Map<String, dynamic>>? _locationUpdateSub;
  StreamSubscription<Map<String, dynamic>>? _employeeConnectedSub;
  StreamSubscription<Map<String, dynamic>>? _employeeDisconnectedSub;
  StreamSubscription<bool>? _connectionStatusSub;

  // In-memory state of active employees
  final Map<String, _EmployeeLocation> _activeEmployees = {};
  final Map<String, List<LatLng>> _employeeRoutes =
      {}; // Store routes for each employee
  final Map<String, LatLng> _employeePunchInLocations =
      {}; // Store punch-in locations
  final Map<String, DateTime> _employeeLastUpdateTime =
      {}; // Track last update time
  final Map<String, double> _employeeTotalDistance =
      {}; // Track total distance traveled in km
  final Map<String, Map<String, dynamic>> _routeStatsByEmployee = {};
  String? _selectedEmployeeId;
  bool _isConnected = false;
  bool _isConnecting = true;
  String? _errorMessage;
  bool _isDisposed = false;
  Timer? _uiFlushTimer;
  final Map<String, dynamic> _pendingLocationByEmployee = {};
  DateTime _lastUiMutationAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _uiMutationThrottle = Duration(milliseconds: 700);

  // Route optimization settings
  static const int _maxRoutePoints = 500; // Increased for better detail
  static const double _routeSimplificationTolerance =
      0.00001; // Douglas-Peucker tolerance

  AdminSocketService get _socketService => AdminSocketService.instance;

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _uiFlushTimer = Timer.periodic(_uiMutationThrottle, (_) {
      _flushPendingLocationUpdates();
    });
    _subscribeToSocketService();
    // Load fallback data from API
    _loadPunchedInEmployees();
  }

  /// Subscribe to global AdminSocketService streams
  void _subscribeToSocketService() {
    // Register as active listener (triggers lazy connection if needed)
    _socketService.addListener();

    // Initial connection state
    _isConnected = _socketService.isConnected;
    _isConnecting = !_isConnected;

    // Listen to connection status changes
    _connectionStatusSub = _socketService.connectionStatus.listen((connected) {
      _safeSetState(() {
        _isConnected = connected;
        _isConnecting = false;
        if (connected) {
          _errorMessage = null;
        }
      });
    });

    // Listen to location updates
    _locationUpdateSub = _socketService.locationUpdates.listen((data) {
      _handleLocationUpdate(data);
    });

    // Listen to employee session started
    _employeeConnectedSub = _socketService.employeeConnected.listen((data) {
      final employeeId = data['employeeId']?.toString();
      debugPrint('🟢 Employee session started: $employeeId');
      _loadPunchedInEmployees();
    });

    // Listen to employee disconnected/session ended
    _employeeDisconnectedSub = _socketService.employeeDisconnected.listen((data) {
      final employeeId = data['employeeId']?.toString();
      if (employeeId == null || employeeId.isEmpty) return;
      debugPrint('🔴 Employee session ended: $employeeId');
      _handleEmployeeDisconnected(employeeId);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _uiFlushTimer?.cancel();
    _uiFlushTimer = null;
    // Cancel stream subscriptions and unregister as listener
    _locationUpdateSub?.cancel();
    _employeeConnectedSub?.cancel();
    _employeeDisconnectedSub?.cancel();
    _connectionStatusSub?.cancel();
    // Notify service that we're no longer listening (may trigger auto-disconnect)
    _socketService.removeListener();
    _mapController.dispose();
    super.dispose();
  }

  /// Reconnect to socket using global AdminSocketService
  void _reconnectSocket() {
    _safeSetState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    _socketService.connect();
  }

  /// Load punched-in employees from API as fallback
  Future<void> _loadPunchedInEmployees() async {
    if (!mounted) return;

    try {
      // Get today's punched-in employees from attendance API
      final response = await TrackingApiService.getTodayPunchedInEmployees();

      if (!mounted) return;

      if (response['success'] == true && response['data'] is List) {
        final punchedInList = response['data'] as List;

        debugPrint('📋 Found ${punchedInList.length} punched-in employees');

        for (var attendance in punchedInList) {
          if (attendance is Map) {
            final employeeId = attendance['employeeId']?.toString();
            final employeeName = attendance['employeeName']?.toString();
            final punchInLat = attendance['punchInLatitude'];
            final punchInLng = attendance['punchInLongitude'];

            if (employeeId != null && employeeName != null && mounted) {
              // Store punch-in location if available
              if (punchInLat != null && punchInLng != null) {
                final punchInLocation = LatLng(
                  (punchInLat is num
                          ? punchInLat
                          : num.parse(punchInLat.toString()))
                      .toDouble(),
                  (punchInLng is num
                          ? punchInLng
                          : num.parse(punchInLng.toString()))
                      .toDouble(),
                );

                _safeSetState(() {
                  _employeePunchInLocations[employeeId] = punchInLocation;
                  // Initialize route with punch-in location as first point
                  _employeeRoutes[employeeId] = [punchInLocation];
                });

                debugPrint(
                  '📍 Punch-in location for $employeeName: ${punchInLocation.latitude.toStringAsFixed(6)}, ${punchInLocation.longitude.toStringAsFixed(6)}',
                );
              }

              // Try to get latest location for this employee
              final locationResult = await TrackingApiService.getLiveTracking(
                employeeId: employeeId,
              );

              // Check if location data exists
              if (locationResult['success'] == true &&
                  locationResult['data'] != null &&
                  locationResult['data'] is Map) {
                final locationData = locationResult['data'];
                final lat = locationData['latitude'];
                final lng = locationData['longitude'];

                if (lat != null && lng != null) {
                  final latLng = LatLng(
                    (lat is num ? lat : num.parse(lat.toString())).toDouble(),
                    (lng is num ? lng : num.parse(lng.toString())).toDouble(),
                  );

                  _safeSetState(() {
                    final lastSeenRaw = locationData['lastSeenAt'] ??
                        locationData['recordedAt'];
                    _activeEmployees[employeeId] = _EmployeeLocation(
                      employeeId: employeeId,
                      employeeName: employeeName,
                      latitude: latLng.latitude,
                      longitude: latLng.longitude,
                      speed: locationData['speed'] != null
                          ? (locationData['speed'] is num
                                    ? locationData['speed']
                                    : num.parse(
                                        locationData['speed'].toString(),
                                      ))
                                .toDouble()
                          : 0,
                      accuracy: locationData['accuracy'] != null
                          ? (locationData['accuracy'] is num
                                    ? locationData['accuracy']
                                    : num.parse(
                                        locationData['accuracy'].toString(),
                                      ))
                                .toDouble()
                          : 0,
                      attendanceId: locationData['attendanceId']?.toString(),
                      status: locationData['status']?.toString(),
                      lastUpdate: DateTime.parse(
                        lastSeenRaw ?? DateTime.now().toIso8601String(),
                      ),
                    );

                  });
                  debugPrint('✅ Loaded location for $employeeName');
                }
              } else {
                _safeSetState(() {
                  _activeEmployees[employeeId] = _EmployeeLocation(
                    employeeId: employeeId,
                    employeeName: employeeName,
                    latitude: 0,
                    longitude: 0,
                    speed: 0,
                    accuracy: 0,
                    attendanceId: null,
                    lastUpdate: DateTime.now(),
                  );
                });
                debugPrint('⚠️ No location data yet for $employeeName');
              }

              // Load today's full route so polylines render immediately
              await _loadTodayRouteForEmployee(employeeId);
            }
          }
        }
      }

      debugPrint(
        '✅ Loaded ${_activeEmployees.length} punched-in employees (${_activeEmployees.values.where((e) => e.latitude != 0 || e.longitude != 0).length} with locations)',
      );
    } catch (e) {
      debugPrint('❌ Error loading punched-in employees: $e');
    }
  }

  /// Load today's full tracking route for an employee so polylines render on load.
  Future<void> _loadTodayRouteForEmployee(String employeeId) async {
    if (!mounted) return;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await TrackingApiService.getRoute(
        employeeId: employeeId,
        start: startOfDay,
        end: endOfDay,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] is List) {
        final data = result['data'] as List;
        final points = <LatLng>[];
        for (final item in data) {
          if (item is Map) {
            final lat = item['latitude'];
            final lng = item['longitude'];
            if (lat != null && lng != null) {
              points.add(LatLng(
                (lat is num ? lat : num.parse(lat.toString())).toDouble(),
                (lng is num ? lng : num.parse(lng.toString())).toDouble(),
              ));
            }
          }
        }

        if (points.isNotEmpty) {
          _safeSetState(() {
            _employeeRoutes[employeeId] = points;
            _recalculateDistance(employeeId);
          });
          debugPrint(
            '📍 Loaded ${points.length} route points for $employeeId',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading route for $employeeId: $e');
    }
  }

  /// Handle incoming location updates
  void _handleLocationUpdate(dynamic data) {
    if (!mounted || _isDisposed) return;
    if (data is! Map) return;

    final employeeId = data['employeeId']?.toString();
    if (employeeId == null || employeeId.isEmpty) return;

    final now = DateTime.now();
    if (now.difference(_lastUiMutationAt) < _uiMutationThrottle) {
      _pendingLocationByEmployee[employeeId] = data;
      return;
    }

    _applyLocationUpdate(data);
  }

  void _flushPendingLocationUpdates() {
    if (!mounted || _isDisposed || _pendingLocationByEmployee.isEmpty) {
      return;
    }

    final pending = List<dynamic>.from(_pendingLocationByEmployee.values);
    _pendingLocationByEmployee.clear();

    for (final event in pending) {
      _applyLocationUpdate(event);
    }
  }

  void _applyLocationUpdate(dynamic data) {
    try {
      final employeeId = data['employeeId']?.toString();
      final employeeName = data['employeeName']?.toString() ?? employeeId;
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      final speed = data['speed'] ?? 0.0;
      final accuracy = data['accuracy'] ?? 0.0;
      final recordedAt = data['recordedAt'] != null
          ? DateTime.parse(data['recordedAt'])
          : DateTime.now();
      final lastSeenAt = data['lastSeenAt'] != null
          ? DateTime.parse(data['lastSeenAt'])
          : recordedAt;
      final totalDistanceKmRaw = data['totalDistanceKm'];
      final attendanceId = data['attendanceId']?.toString();
      final serverStatus = data['status']?.toString();

      if (employeeId == null || latitude == null || longitude == null) {
        return;
      }

      final latLng = LatLng(
        (latitude is num ? latitude : num.parse(latitude.toString()))
            .toDouble(),
        (longitude is num ? longitude : num.parse(longitude.toString()))
            .toDouble(),
      );

      _safeSetState(() {
        _lastUiMutationAt = DateTime.now();
        _activeEmployees[employeeId] = _EmployeeLocation(
          employeeId: employeeId,
          employeeName: employeeName ?? employeeId,
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          speed: (speed is num ? speed : num.parse(speed.toString()))
              .toDouble(),
          accuracy:
              (accuracy is num ? accuracy : num.parse(accuracy.toString()))
                  .toDouble(),
          attendanceId: attendanceId,
          status: serverStatus,
          lastUpdate: lastSeenAt,
        );

        _employeeLastUpdateTime[employeeId] = lastSeenAt;

        if (!_employeeRoutes.containsKey(employeeId)) {
          if (_employeePunchInLocations.containsKey(employeeId)) {
            _employeeRoutes[employeeId] = [
              _employeePunchInLocations[employeeId]!,
            ];
          } else {
            _employeeRoutes[employeeId] = [];
          }
          _employeeTotalDistance[employeeId] = 0.0;
        }

        const shouldAddPoint = true;

        if (shouldAddPoint) {
          if (_employeeRoutes[employeeId]!.isNotEmpty &&
              totalDistanceKmRaw == null) {
            final distanceFromLast = _calculateDistance(
              _employeeRoutes[employeeId]!.last,
              latLng,
            );
            _employeeTotalDistance[employeeId] =
                (_employeeTotalDistance[employeeId] ?? 0.0) + distanceFromLast;
          }

          _employeeRoutes[employeeId]!.add(latLng);

          if (_employeeRoutes[employeeId]!.length > _maxRoutePoints) {
            _optimizeRoute(employeeId);
          }
        }

        if (totalDistanceKmRaw is num) {
          _employeeTotalDistance[employeeId] = totalDistanceKmRaw.toDouble();
        }
      });

      debugPrint(
        'Location updated:  ( active,  points,  km)',
      );
    } catch (e) {
      debugPrint('Error handling location update: ');
    }
  }
  /// Optimize route by removing redundant points while keeping punch-in location
  void _optimizeRoute(String employeeId) {
    if (!_employeeRoutes.containsKey(employeeId)) return;

    final route = _employeeRoutes[employeeId]!;
    if (route.length <= _maxRoutePoints) return;

    // Keep punch-in location (first point) if it exists
    final hasPunchIn = _employeePunchInLocations.containsKey(employeeId);
    final punchInPoint = hasPunchIn ? route.first : null;

    // Keep recent points (last 200) and simplify older points
    final recentPoints = route.sublist(math.max(0, route.length - 200));
    final olderPoints = route.sublist(0, math.max(0, route.length - 200));

    // Simplify older points using Douglas-Peucker algorithm
    final simplifiedOlder = _simplifyRoute(
      olderPoints,
      _routeSimplificationTolerance,
    );

    // Combine: punch-in (if exists) + simplified older + recent
    final optimizedRoute = <LatLng>[];
    if (punchInPoint != null && !simplifiedOlder.contains(punchInPoint)) {
      optimizedRoute.add(punchInPoint);
    }
    optimizedRoute.addAll(simplifiedOlder);
    optimizedRoute.addAll(recentPoints);

    _employeeRoutes[employeeId] = optimizedRoute;

    // Recalculate total distance from optimized route
    _recalculateDistance(employeeId);

    debugPrint(
      '🔧 Optimized route for $employeeId: ${route.length} → ${optimizedRoute.length} points, Distance: ${(_employeeTotalDistance[employeeId] ?? 0).toStringAsFixed(2)} km',
    );
  }

  /// Recalculate total distance from the entire route
  void _recalculateDistance(String employeeId) {
    if (!_employeeRoutes.containsKey(employeeId)) return;

    final route = _employeeRoutes[employeeId]!;
    if (route.length < 2) {
      _employeeTotalDistance[employeeId] = 0.0;
      return;
    }

    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }

    _employeeTotalDistance[employeeId] = totalDistance;

    debugPrint(
      '📏 Recalculated distance for $employeeId: ${totalDistance.toStringAsFixed(2)} km from ${route.length} points',
    );
  }

  /// Simplified Douglas-Peucker algorithm for route simplification
  List<LatLng> _simplifyRoute(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    // Find point with maximum distance from line between first and last
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = _simplifyRoute(points.sublist(0, maxIndex + 1), tolerance);
      final right = _simplifyRoute(points.sublist(maxIndex), tolerance);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// Calculate perpendicular distance from point to line
  double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;

    final mag = math.sqrt(dx * dx + dy * dy);
    if (mag > 0.0) {
      final u =
          ((point.longitude - lineStart.longitude) * dx +
              (point.latitude - lineStart.latitude) * dy) /
          (mag * mag);

      final intersectionLng = lineStart.longitude + u * dx;
      final intersectionLat = lineStart.latitude + u * dy;

      final dx2 = point.longitude - intersectionLng;
      final dy2 = point.latitude - intersectionLat;

      return math.sqrt(dx2 * dx2 + dy2 * dy2);
    } else {
      final dx2 = point.longitude - lineStart.longitude;
      final dy2 = point.latitude - lineStart.latitude;
      return math.sqrt(dx2 * dx2 + dy2 * dy2);
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(point1.latitude)) *
            math.cos(_toRadians(point2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  /// Handle employee disconnection
  void _handleEmployeeDisconnected(String employeeId) {
    if (!mounted || _isDisposed) return;

    debugPrint(
      '?? Employee disconnected: $employeeId (${_activeEmployees.length} active)',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    // Show connection status at top
    return Column(
      children: [
        // Connection status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
          child: Row(
            children: [
              Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                size: 20,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isConnected
                      ? 'Real-time tracking active'
                      : _isConnecting
                      ? 'Connecting to server...'
                      : 'Disconnected - Showing last known positions',
                  style: TextStyle(
                    color: _isConnected
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!_isConnected && !_isConnecting)
                TextButton.icon(
                  onPressed: _reconnectSocket,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Main content
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null && _activeEmployees.isEmpty) {
      return _buildError();
    }

    if (_isConnecting && _activeEmployees.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Connecting to server...'),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_activeEmployees.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildEmployeeDropdown(),
        Expanded(child: _buildMap()),
        if (_selectedEmployeeId != null) _buildDistanceStats(),
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    final employees = _activeEmployees.values.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Employee to Track',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedEmployeeId,
            hint: const Text('Choose an employee'),
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _selectedEmployeeId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _safeSetState(() {
                          _selectedEmployeeId = null;
                        });
                      },
                    )
                  : null,
            ),
            items: employees.map((emp) {
              final distance = _employeeTotalDistance[emp.employeeId] ?? 0.0;
              final hasLocation = emp.latitude != 0 || emp.longitude != 0;
              final freshnessStatus = _getFreshnessStatus(
                emp.lastUpdate,
                serverStatus: emp.status,
              );
              final timeAgo = hasLocation
                  ? _formatTimeAgo(DateTime.now().difference(emp.lastUpdate))
                  : 'No location';

              return DropdownMenuItem<String>(
                value: emp.employeeId,
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasLocation
                              ? _getFreshnessColor(freshnessStatus)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasLocation
                              ? '${emp.employeeName} (${distance.toStringAsFixed(1)}km, $freshnessStatus)'
                              : '${emp.employeeName} (waiting...)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              _safeSetState(() {
                _selectedEmployeeId = value;
              });
              if (value != null && _activeEmployees.containsKey(value)) {
                final emp = _activeEmployees[value]!;
                if (emp.latitude != 0 || emp.longitude != 0) {
                  _mapController.move(LatLng(emp.latitude, emp.longitude), 15);
                }
                _refreshRouteStatsForSelected();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Filter employees with valid locations
    final employeesWithLocation = _activeEmployees.values
        .where((e) => e.latitude != 0 || e.longitude != 0)
        .toList();

    // Show default map with message if no locations yet
    final showDefaultMap = employeesWithLocation.isEmpty;

    // Calculate center point
    LatLng center;
    if (_selectedEmployeeId != null &&
        _activeEmployees.containsKey(_selectedEmployeeId)) {
      final emp = _activeEmployees[_selectedEmployeeId]!;
      if (emp.latitude != 0 || emp.longitude != 0) {
        center = LatLng(emp.latitude, emp.longitude);
      } else {
        // Default center if selected employee has no location
        center = LatLng(24.8607, 67.0011); // Karachi default
      }
    } else if (employeesWithLocation.isNotEmpty) {
      final centerLat =
          employeesWithLocation.map((e) => e.latitude).reduce((a, b) => a + b) /
          employeesWithLocation.length;
      final centerLng =
          employeesWithLocation
              .map((e) => e.longitude)
              .reduce((a, b) => a + b) /
          employeesWithLocation.length;
      center = LatLng(centerLat, centerLng);
    } else {
      // Default center when no locations available
      center = LatLng(24.8607, 67.0011); // Karachi default
    }

    // Create markers only for employees with valid locations
    final markers = employeesWithLocation.map((employee) {
      final isSelected = employee.employeeId == _selectedEmployeeId;
      final timeSinceUpdate = DateTime.now().difference(employee.lastUpdate);
      final isLive = timeSinceUpdate.inMinutes < 2;

      return Marker(
        point: LatLng(employee.latitude, employee.longitude),
        width: 50,
        height: 50,
        builder: (_) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedEmployeeId = employee.employeeId;
            });
            _mapController.move(
              LatLng(employee.latitude, employee.longitude),
              15,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.white : primaryColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: isSelected ? Colors.white : primaryColor,
                  size: 24,
                ),
              ),
              if (isLive && !isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();

    // Get polyline for selected employee with enhanced styling
    final polylines = <Polyline>[];
    if (_selectedEmployeeId != null &&
        _employeeRoutes.containsKey(_selectedEmployeeId) &&
        _employeeRoutes[_selectedEmployeeId]!.length > 1) {
      // Main route polyline with smooth styling
      polylines.add(
        Polyline(
          points: _employeeRoutes[_selectedEmployeeId]!,
          color: primaryColor.withValues(alpha: 0.9),
          strokeWidth: 5,
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      );

      // Add punch-in marker (start point) if available
      if (_employeePunchInLocations.containsKey(_selectedEmployeeId)) {
        final punchInPoint = _employeePunchInLocations[_selectedEmployeeId]!;
        markers.add(
          Marker(
            point: punchInPoint,
            width: 50,
            height: 50,
            builder: (_) => Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      }

      // Add current location marker (end point) if different from punch-in
      if (_employeeRoutes[_selectedEmployeeId]!.length > 1) {
        final currentPoint = _employeeRoutes[_selectedEmployeeId]!.last;
        final emp = _activeEmployees[_selectedEmployeeId]!;

        // Only add if it's different from punch-in location
        if (!_employeePunchInLocations.containsKey(_selectedEmployeeId) ||
            _calculateDistance(
                  _employeePunchInLocations[_selectedEmployeeId]!,
                  currentPoint,
                ) >
                0.01) {
          // 10 meters minimum distance

          // Determine if employee is moving
          final isMoving = emp.speed > 0.5; // Moving if speed > 0.5 m/s

          markers.add(
            Marker(
              point: currentPoint,
              width: 50,
              height: 50,
              builder: (_) => Container(
                decoration: BoxDecoration(
                  color: isMoving ? primaryColor : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isMoving ? Icons.navigation : Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        }
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(center: center, zoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.loagma_crm',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
        // Show overlay message when waiting for locations
        if (showDefaultMap)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_searching,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for Location Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_activeEmployees.length} employee(s) punched in',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Waiting for them to send location...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Active Employees',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for employees to connect...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _reconnectSocket,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.isNegative) return 'just now';
    if (duration.inSeconds < 60) return '${duration.inSeconds}s ago';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  String _getFreshnessStatus(DateTime lastUpdate, {String? serverStatus}) {
    if (serverStatus == 'LIVE' ||
        serverStatus == 'DEGRADED' ||
        serverStatus == 'OFFLINE') {
      return serverStatus!;
    }
    final age = DateTime.now().difference(lastUpdate);
    if (age.isNegative) return 'LIVE';
    if (age.inSeconds <= 45) return 'LIVE';
    if (age.inSeconds <= 180) return 'DEGRADED';
    return 'OFFLINE';
  }

  Color _getFreshnessColor(String status) {
    switch (status) {
      case 'LIVE':
        return Colors.green;
      case 'DEGRADED':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Future<void> _refreshRouteStatsForSelected() async {
    final selectedId = _selectedEmployeeId;
    if (selectedId == null || selectedId.isEmpty) return;
    final attendanceId = _activeEmployees[selectedId]?.attendanceId;

    final result = await TrackingApiService.getRouteStats(
      employeeId: selectedId,
      attendanceId: attendanceId,
    );
    if (result['success'] == true && result['data'] is Map) {
      final stats = Map<String, dynamic>.from(result['data']);
      _safeSetState(() {
        _routeStatsByEmployee[selectedId] = stats;
        final totalDistanceKm = stats['totalDistanceKm'];
        if (totalDistanceKm is num) {
          _employeeTotalDistance[selectedId] = totalDistanceKm.toDouble();
        }
      });
    }
  }

  /// Build distance and stats widget
  Widget _buildDistanceStats() {
    if (_selectedEmployeeId == null) return const SizedBox.shrink();

    final selectedId = _selectedEmployeeId!;
    final distance = _employeeTotalDistance[selectedId] ?? 0.0;
    final routePoints = _employeeRoutes[selectedId]?.length ?? 0;
    final stats = _routeStatsByEmployee[selectedId];
    final durationSec = stats != null && stats['durationSec'] is num
        ? (stats['durationSec'] as num).toInt()
        : routePoints * 5;

    final hours = durationSec ~/ 3600;
    final minutes = (durationSec % 3600) ~/ 60;
    final duration = '$hours' 'h ' '$minutes' 'm';

    String avgSpeed = 'N/A';
    if (durationSec > 0 && distance > 0) {
      final speedKmh = distance / (durationSec / 3600);
      avgSpeed = '${speedKmh.toStringAsFixed(1)} km/h';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.route,
            'Distance',
            '${distance.toStringAsFixed(2)} km',
            primaryColor,
          ),
          _buildStatItem(Icons.access_time, 'Duration', duration, Colors.blue),
          _buildStatItem(Icons.speed, 'Avg Speed', avgSpeed, Colors.green),
          _buildStatItem(
            Icons.location_on,
            'Points',
            '$routePoints',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

/// Employee location data model
class _EmployeeLocation {
  final String employeeId;
  final String employeeName;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final String? attendanceId;
  final String? status;
  final DateTime lastUpdate;

  _EmployeeLocation({
    required this.employeeId,
    required this.employeeName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    this.attendanceId,
    this.status,
    required this.lastUpdate,
  });
}

/// Historical Routes Tab - Shows past routes with date picker
class HistoricalRoutesTab extends StatefulWidget {
  const HistoricalRoutesTab({super.key});

  @override
  State<HistoricalRoutesTab> createState() => _HistoricalRoutesTabState();
}

class _HistoricalRoutesTabState extends State<HistoricalRoutesTab> {
  static const Color primaryColor = Color(0xFFD7BE69);
  late final MapController _mapController;
  bool _isMapReady = false;
  LatLng? _pendingMapCenter;

  List<Map<String, dynamic>> _allEmployees = [];
  String? _selectedEmployeeId;
  DateTime _selectedDate = DateTime.now();

  List<LatLng> _routePoints = [];
  List<DateTime> _routeTimestamps = [];
  bool _isLoadingRoute = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadEmployees();
  }

  @override
  void dispose() {
    _isMapReady = false;
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await UserService.getAllUsers();

      if (!mounted) return;

      final filteredUsers = <Map<String, dynamic>>[];

      if (response['success'] == true && response['data'] is List) {
        final usersList = response['data'] as List;
        for (var u in usersList) {
          if (u is Map && u['id'] != null) {
            filteredUsers.add(u as Map<String, dynamic>);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allEmployees = filteredUsers;
          if (_allEmployees.isNotEmpty && _selectedEmployeeId == null) {
            _selectedEmployeeId = _allEmployees.first['id'];
            _loadRoute();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load employees: $e';
        });
      }
    }
  }

  Future<void> _loadRoute() async {
    if (_selectedEmployeeId == null || !mounted) return;

    setState(() {
      _isLoadingRoute = true;
      _errorMessage = null;
    });

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        0,
        0,
        0,
      );
      final endOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );

      final result = await TrackingApiService.getRoute(
        employeeId: _selectedEmployeeId!,
        start: startOfDay,
        end: endOfDay,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && data is List && data.isNotEmpty) {
          final points = <LatLng>[];
          final timestamps = <DateTime>[];
          for (final item in data) {
            try {
              final lat = item['latitude'];
              final lng = item['longitude'];
              if (lat != null && lng != null) {
                points.add(LatLng(
                  (lat is num ? lat : num.parse(lat.toString())).toDouble(),
                  (lng is num ? lng : num.parse(lng.toString())).toDouble(),
                ));
                final recordedAt = item['recordedAt'];
                if (recordedAt != null) {
                  timestamps.add(DateTime.parse(recordedAt.toString()));
                } else {
                  timestamps.add(DateTime.now());
                }
              }
            } catch (e) {
              debugPrint('Error parsing point: $e');
            }
          }

          setState(() {
            _routePoints = points;
            _routeTimestamps = timestamps;
            _isLoadingRoute = false;
          });

          // Center map on route only after map is ready.
          if (points.isNotEmpty) {
            final centerLat =
                points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length;
            final centerLng =
                points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length;
            _moveOrQueueMapCenter(LatLng(centerLat, centerLng));
          }

          debugPrint('✅ Loaded ${points.length} historical points');
        } else {
          setState(() {
            _routePoints = [];
            _routeTimestamps = [];
            _isLoadingRoute = false;
            _errorMessage = 'No route data for selected date';
          });
        }
      } else {
        setState(() {
          _routePoints = [];
          _routeTimestamps = [];
          _isLoadingRoute = false;
          _errorMessage = result['message'] ?? 'Failed to load route';
        });
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
      if (mounted) {
        setState(() {
          _routePoints = [];
          _routeTimestamps = [];
          _isLoadingRoute = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        if (_isLoadingRoute)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading route...'),
                ],
              ),
            ),
          )
        else if (_errorMessage != null)
          Expanded(child: _buildErrorState())
        else if (_routePoints.isEmpty)
          Expanded(child: _buildEmptyState())
        else
          Expanded(child: _buildMap()),
        if (_routePoints.isNotEmpty) _buildStats(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Employee Dropdown
          if (_allEmployees.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: const InputDecoration(
                labelText: 'Select Employee',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _allEmployees.map((emp) {
                return DropdownMenuItem<String>(
                  value: emp['id'] as String,
                  child: Text(emp['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEmployeeId = value;
                });
                _loadRoute();
              },
            ),
          const SizedBox(height: 12),
          // Date Picker
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadRoute,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final center = _routePoints.isNotEmpty
        ? _routePoints[_routePoints.length ~/ 2]
        : LatLng(0, 0);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: center,
        zoom: 13,
        onMapReady: () {
          _isMapReady = true;
          if (!mounted) return;
          if (_pendingMapCenter != null) {
            final queued = _pendingMapCenter!;
            _pendingMapCenter = null;
            _mapController.move(queued, 13);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.loagma_crm',
        ),
        // Polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: primaryColor,
              strokeWidth: 4,
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ],
        ),
        // Start and End markers
        MarkerLayer(
          markers: [
            // Start marker (Punch-in location)
            Marker(
              point: _routePoints.first,
              width: 50,
              height: 50,
              builder: (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            // End marker (Last location)
            Marker(
              point: _routePoints.last,
              width: 50,
              height: 50,
              builder: (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _moveOrQueueMapCenter(LatLng center) {
    if (_isMapReady && mounted) {
      _mapController.move(center, 13);
      return;
    }
    _pendingMapCenter = center;
  }

  Widget _buildStats() {
    final distance = _calculateTotalDistance();
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.route, 'Total Points', '${_routePoints.length}'),
          _buildStatItem(
            Icons.straighten,
            'Distance',
            '${distance.toStringAsFixed(2)} km',
          ),
          _buildStatItem(Icons.access_time, 'Duration', _calculateDuration()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  double _calculateTotalDistance() {
    if (_routePoints.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final p1 = _routePoints[i];
      final p2 = _routePoints[i + 1];
      total += _calculateDistance(p1, p2);
    }
    return total;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  String _calculateDuration() {
    if (_routeTimestamps.length >= 2) {
      final totalSeconds = _routeTimestamps.last
          .difference(_routeTimestamps.first)
          .inSeconds
          .abs();
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
    if (_routePoints.length < 2) return '0h 0m';
    final totalSeconds = _routePoints.length * 5;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Route Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tracking data found for selected date',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Select Different Date'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Route',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRoute,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );
  }
}



