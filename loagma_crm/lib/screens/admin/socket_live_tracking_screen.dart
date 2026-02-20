import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../services/user_service.dart';
import '../../services/api_config.dart';
import '../../services/tracking_api_service.dart';

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

class _LiveTrackingTabState extends State<LiveTrackingTab> {
  static const Color primaryColor = Color(0xFFD7BE69);

  IO.Socket? _socket;
  final MapController _mapController = MapController();

  // In-memory state of active employees
  final Map<String, _EmployeeLocation> _activeEmployees = {};
  final Map<String, List<LatLng>> _employeeRoutes =
      {}; // Store routes for each employee
  String? _selectedEmployeeId;
  bool _isConnected = false;
  bool _isConnecting = true;
  bool _isLoadingFallback = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    // Load fallback data from API
    _loadPunchedInEmployees();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Connect to Socket.IO server
  Future<void> _connectToSocket() async {
    if (!mounted) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final token = UserService.token;
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Authentication required';
            _isConnecting = false;
          });
        }
        return;
      }

      // Use http:// URL directly - Socket.IO client handles WebSocket upgrade
      final socketUrl = ApiConfig.baseUrl;
      debugPrint('🔌 Admin connecting to Socket.IO: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .setTimeout(10000)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      // Set timeout for connection
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_isConnected && _isConnecting) {
          setState(() {
            _errorMessage = 'Connection timeout. Showing last known positions.';
            _isConnecting = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection failed. Showing last known positions.';
          _isConnecting = false;
        });
      }
    }
  }

  /// Load punched-in employees from API as fallback
  Future<void> _loadPunchedInEmployees() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFallback = true;
    });

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

            if (employeeId != null && employeeName != null && mounted) {
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

                  setState(() {
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
                      lastUpdate: DateTime.parse(
                        locationData['recordedAt'] ??
                            DateTime.now().toIso8601String(),
                      ),
                    );

                    // Initialize route with current location
                    if (!_employeeRoutes.containsKey(employeeId)) {
                      _employeeRoutes[employeeId] = [latLng];
                    }
                  });
                  debugPrint('✅ Loaded location for $employeeName');
                }
              } else {
                // No location data yet, but still add employee to list with default location
                setState(() {
                  _activeEmployees[employeeId] = _EmployeeLocation(
                    employeeId: employeeId,
                    employeeName: employeeName,
                    latitude: 0,
                    longitude: 0,
                    speed: 0,
                    accuracy: 0,
                    lastUpdate: DateTime.now(),
                  );
                });
                debugPrint('⚠️ No location data yet for $employeeName');
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingFallback = false;
        });
      }

      debugPrint(
        '✅ Loaded ${_activeEmployees.length} punched-in employees (${_activeEmployees.values.where((e) => e.latitude != 0 || e.longitude != 0).length} with locations)',
      );
    } catch (e) {
      debugPrint('❌ Error loading punched-in employees: $e');
      if (mounted) {
        setState(() {
          _isLoadingFallback = false;
        });
      }
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ Admin socket connected');
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _errorMessage = null;
        });
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('🔌 Admin socket disconnected: $reason');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
      }
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Admin socket connection error: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $error';
          _isConnecting = false;
        });
      }
    });

    // Listen for location updates from all employees
    _socket!.on('location-update', (data) {
      _handleLocationUpdate(data);
    });

    // Listen for employee connection events
    _socket!.on('employee-connected', (data) {
      debugPrint('🟢 Employee connected: ${data['employeeId']}');
    });

    // Listen for employee disconnection events
    _socket!.on('employee-disconnected', (data) {
      _handleEmployeeDisconnected(data['employeeId']);
    });

    // Listen for active employees list
    _socket!.on('active-employees', (data) {
      debugPrint('📋 Active employees: $data');
    });
  }

  /// Handle incoming location updates
  void _handleLocationUpdate(dynamic data) {
    if (!mounted) return;

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

      if (employeeId == null || latitude == null || longitude == null) {
        return;
      }

      final latLng = LatLng(
        (latitude is num ? latitude : num.parse(latitude.toString()))
            .toDouble(),
        (longitude is num ? longitude : num.parse(longitude.toString()))
            .toDouble(),
      );

      setState(() {
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
          lastUpdate: recordedAt,
        );

        // Add point to employee's route
        if (!_employeeRoutes.containsKey(employeeId)) {
          _employeeRoutes[employeeId] = [];
        }
        _employeeRoutes[employeeId]!.add(latLng);

        // Keep only last 100 points to avoid memory issues
        if (_employeeRoutes[employeeId]!.length > 100) {
          _employeeRoutes[employeeId]!.removeAt(0);
        }
      });

      debugPrint(
        '📍 Location updated: $employeeId (${_activeEmployees.length} active, ${_employeeRoutes[employeeId]?.length ?? 0} points)',
      );
    } catch (e) {
      debugPrint('❌ Error handling location update: $e');
    }
  }

  /// Handle employee disconnection
  void _handleEmployeeDisconnected(String employeeId) {
    if (!mounted) return;

    setState(() {
      _activeEmployees.remove(employeeId);
      // Keep the route for historical view, or remove it
      // _employeeRoutes.remove(employeeId); // Uncomment to clear route on disconnect
    });

    debugPrint(
      '🔴 Employee disconnected: $employeeId (${_activeEmployees.length} active)',
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _connectToSocket,
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
                        setState(() {
                          _selectedEmployeeId = null;
                        });
                      },
                    )
                  : null,
            ),
            items: employees.map((emp) {
              final routePoints = _employeeRoutes[emp.employeeId]?.length ?? 0;
              final hasLocation = emp.latitude != 0 || emp.longitude != 0;
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
                          color: hasLocation ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasLocation
                              ? '${emp.employeeName} ($routePoints pts)'
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
              setState(() {
                _selectedEmployeeId = value;
              });
              if (value != null && _activeEmployees.containsKey(value)) {
                final emp = _activeEmployees[value]!;
                if (emp.latitude != 0 || emp.longitude != 0) {
                  _mapController.move(LatLng(emp.latitude, emp.longitude), 15);
                }
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

    // Get polyline for selected employee
    final polylines = <Polyline>[];
    if (_selectedEmployeeId != null &&
        _employeeRoutes.containsKey(_selectedEmployeeId) &&
        _employeeRoutes[_selectedEmployeeId]!.length > 1) {
      polylines.add(
        Polyline(
          points: _employeeRoutes[_selectedEmployeeId]!,
          color: primaryColor,
          strokeWidth: 4,
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      );

      // Add start marker for the route
      final startPoint = _employeeRoutes[_selectedEmployeeId]!.first;
      markers.add(
        Marker(
          point: startPoint,
          width: 30,
          height: 30,
          builder: (_) =>
              const Icon(Icons.play_circle, color: Colors.green, size: 30),
        ),
      );
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
            onPressed: _connectToSocket,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s ago';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
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
  final DateTime lastUpdate;

  _EmployeeLocation({
    required this.employeeId,
    required this.employeeName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
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

  List<Map<String, dynamic>> _allEmployees = [];
  String? _selectedEmployeeId;
  DateTime _selectedDate = DateTime.now();

  List<LatLng> _routePoints = [];
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
          final points = data
              .map((item) {
                try {
                  final lat = item['latitude'];
                  final lng = item['longitude'];
                  if (lat != null && lng != null) {
                    return LatLng(
                      (lat is num ? lat : num.parse(lat.toString())).toDouble(),
                      (lng is num ? lng : num.parse(lng.toString())).toDouble(),
                    );
                  }
                } catch (e) {
                  debugPrint('Error parsing point: $e');
                }
                return null;
              })
              .whereType<LatLng>()
              .toList();

          setState(() {
            _routePoints = points;
            _isLoadingRoute = false;
          });

          // Center map on route
          if (points.isNotEmpty) {
            final centerLat =
                points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length;
            final centerLng =
                points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length;
            _mapController.move(LatLng(centerLat, centerLng), 13);
          }

          debugPrint('✅ Loaded ${points.length} historical points');
        } else {
          setState(() {
            _routePoints = [];
            _isLoadingRoute = false;
            _errorMessage = 'No route data for selected date';
          });
        }
      } else {
        setState(() {
          _routePoints = [];
          _isLoadingRoute = false;
          _errorMessage = result['message'] ?? 'Failed to load route';
        });
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
      if (mounted) {
        setState(() {
          _routePoints = [];
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
      options: MapOptions(center: center, zoom: 13),
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
            // Start marker
            Marker(
              point: _routePoints.first,
              width: 40,
              height: 40,
              builder: (_) =>
                  const Icon(Icons.play_circle, color: Colors.green, size: 40),
            ),
            // End marker
            Marker(
              point: _routePoints.last,
              width: 40,
              height: 40,
              builder: (_) =>
                  const Icon(Icons.stop_circle, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
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
    if (_routePoints.length < 2) return '0h 0m';

    // Assuming 5-second intervals between points
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
