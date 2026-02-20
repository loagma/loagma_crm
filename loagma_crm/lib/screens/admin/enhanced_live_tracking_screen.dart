import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../services/tracking_api_service.dart';
import '../../services/user_service.dart';

/// Enhanced Live Tracking Screen with separate Live and Historical tabs
///
/// Live Tab: Shows only currently punched-in employees (real-time from Firebase)
/// Historical Tab: Shows all employees with date picker for viewing past routes
class EnhancedLiveTrackingScreen extends StatefulWidget {
  const EnhancedLiveTrackingScreen({super.key});

  @override
  State<EnhancedLiveTrackingScreen> createState() =>
      _EnhancedLiveTrackingScreenState();
}

class _EnhancedLiveTrackingScreenState extends State<EnhancedLiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFD7BE69);

  late TabController _tabController;
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mapController = MapController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
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

/// Live Tracking Tab - Shows only currently punched-in employees
class LiveTrackingTab extends StatefulWidget {
  const LiveTrackingTab({super.key});

  @override
  State<LiveTrackingTab> createState() => _LiveTrackingTabState();
}

class _LiveTrackingTabState extends State<LiveTrackingTab> {
  static const Color primaryColor = Color(0xFFD7BE69);
  late final MapController _mapController;
  String? _selectedEmployeeId;
  Map<String, String> _employeeNames = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadEmployeeNames();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeNames() async {
    try {
      final response = await UserService.getAllUsers();

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      final Map<String, String> names = {};

      // UserService.getAllUsers() returns Map with 'success' and 'data' keys
      if (response['success'] == true && response['data'] is List) {
        final usersList = response['data'] as List;
        for (var user in usersList) {
          if (user is Map && user['id'] != null) {
            names[user['id'] as String] = user['name'] as String? ?? 'Unknown';
          }
        }
      }

      // Check again before calling setState
      if (mounted) {
        setState(() {
          _employeeNames = names;
        });
      }
    } catch (e) {
      debugPrint('Error loading employee names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show employees updated in last 24 hours (active sessions)
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tracking_live')
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // Parse live tracking points
        final livePoints = docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _LivePoint.fromMap(data, _employeeNames);
            })
            .where((point) => point != null)
            .cast<_LivePoint>()
            .toList();

        if (livePoints.isEmpty) {
          return _buildEmptyState();
        }

        // Auto-select first employee if none selected
        if (_selectedEmployeeId == null && livePoints.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedEmployeeId = livePoints.first.employeeId;
              });
            }
          });
        }

        return _buildMap(livePoints);
      },
    );
  }

  Widget _buildMap(List<_LivePoint> livePoints) {
    final markers = livePoints.map((point) {
      final isSelected = point.employeeId == _selectedEmployeeId;
      final lastUpdate = point.updatedAt ?? point.recordedAt;
      final isLive =
          lastUpdate != null &&
          DateTime.now().difference(lastUpdate).inMinutes < 2;

      return Marker(
        point: point.latLng,
        width: 50,
        height: 50,
        builder: (_) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedEmployeeId = point.employeeId;
            });
            _mapController.move(point.latLng, 15);
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

    final center = livePoints
        .firstWhere(
          (p) => p.employeeId == _selectedEmployeeId,
          orElse: () => livePoints.first,
        )
        .latLng;

    return Column(
      children: [
        _buildEmployeeList(livePoints),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: center, zoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.loagma_crm',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeList(List<_LivePoint> points) {
    return Container(
      height: 80,
      color: Colors.grey[100],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: points.length,
        itemBuilder: (context, index) {
          final point = points[index];
          final isSelected = point.employeeId == _selectedEmployeeId;
          final lastUpdate = point.updatedAt ?? point.recordedAt;
          final timeAgo = lastUpdate != null
              ? _formatTimeAgo(DateTime.now().difference(lastUpdate))
              : 'Unknown';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedEmployeeId = point.employeeId;
              });
              _mapController.move(point.latLng, 15);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    point.employeeName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
            'No employees are currently punched in',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
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
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
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

/// Historical Routes Tab - Shows all employees with date picker
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

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      final filteredUsers = <Map<String, dynamic>>[];

      // UserService.getAllUsers() returns Map with 'success' and 'data' keys
      if (response['success'] == true && response['data'] is List) {
        final usersList = response['data'] as List;
        for (var u in usersList) {
          if (u is Map && u['id'] != null) {
            filteredUsers.add(u as Map<String, dynamic>);
          }
        }
      }

      // Check again before calling setState
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
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
        _errorMessage = 'Error: $e';
      });
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
              child: CircularProgressIndicator(color: primaryColor),
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
          DropdownButtonFormField<String>(
            initialValue: _selectedEmployeeId,
            decoration: const InputDecoration(
              labelText: 'Select Employee',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      color: primaryColor.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Points', _routePoints.length.toString()),
          _buildStatItem('Distance', '${distance.toStringAsFixed(2)} km'),
          _buildStatItem('Start', DateFormat('HH:mm').format(_selectedDate)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  double _calculateTotalDistance() {
    double total = 0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      total += _haversineDistance(_routePoints[i], _routePoints[i + 1]);
    }
    return total;
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 64, color: Colors.grey[400]),
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
            'Error',
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
          ElevatedButton(onPressed: _loadRoute, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Helper class for live tracking points
class _LivePoint {
  final String employeeId;
  final String employeeName;
  final LatLng latLng;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  _LivePoint({
    required this.employeeId,
    required this.employeeName,
    required this.latLng,
    this.recordedAt,
    this.updatedAt,
  });

  static _LivePoint? fromMap(
    Map<String, dynamic> data,
    Map<String, String> employeeNames,
  ) {
    try {
      final employeeId = data['employeeId']?.toString();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (employeeId == null || lat == null || lng == null) return null;

      final employeeName =
          data['employeeName'] ??
          employeeNames[employeeId] ??
          'Employee $employeeId';

      DateTime? recordedAt;
      if (data['recordedAt'] is Timestamp) {
        recordedAt = (data['recordedAt'] as Timestamp).toDate();
      }

      DateTime? updatedAt;
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }

      return _LivePoint(
        employeeId: employeeId,
        employeeName: employeeName,
        latLng: LatLng(
          (lat is num ? lat : num.parse(lat.toString())).toDouble(),
          (lng is num ? lng : num.parse(lng.toString())).toDouble(),
        ),
        recordedAt: recordedAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('Error parsing live point: $e');
      return null;
    }
  }
}
