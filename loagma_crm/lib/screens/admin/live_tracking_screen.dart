import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../services/tracking_api_service.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFD7BE69);

  final MapController _mapController = MapController();
  late TabController _tabController;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  DateTime? _startDate;
  DateTime? _endDate;
  List<LatLng> _routePoints = []; // Historical route from backend
  List<LatLng> _liveRoutePoints =
      []; // Combined route (historical + live points)
  bool _isLoadingRoute = false;
  bool _hasLoadedRoute =
      false; // Track if route has been loaded to prevent infinite loops
  Map<String, String> _employeeNameMap = {}; // employeeId -> employeeName
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _routeDetails =
      {}; // employeeId -> route data with stats
  int _lastDocCount = 0; // Track document count to reduce logging
  List<_LivePoint> _currentLivePoints =
      []; // Store current live points for route loading
  Map<String, AttendanceModel?> _attendanceMap =
      {}; // employeeId -> today's active attendance

  LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployeeNames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayAttendance(List<String> employeeIds) async {
    if (employeeIds.isEmpty) return;

    try {
      debugPrint(
        '📅 Fetching today attendance for ${employeeIds.length} employees: $employeeIds',
      );
      final attendanceMap =
          await AttendanceService.getTodayActiveAttendanceForEmployees(
            employeeIds,
          );

      if (mounted) {
        setState(() {
          // Merge with existing map to preserve data
          _attendanceMap = {..._attendanceMap, ...attendanceMap};
        });

        // Log what we got
        attendanceMap.forEach((employeeId, attendance) {
          if (attendance != null) {
            debugPrint(
              '✅ Found today attendance for $employeeId: ${attendance.punchInTime}',
            );
          } else {
            debugPrint('⚠️ No today attendance for $employeeId');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching today attendance: $e');
    }
  }

  Future<void> _loadEmployeeNames() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await UserService.getAllUsers();
      if (result['success'] == true) {
        final List<dynamic> users = result['data'] ?? [];
        final Map<String, String> nameMap = {};

        for (var user in users) {
          final id = user['id']?.toString() ?? user['_id']?.toString();
          final name = user['name']?.toString() ?? '';
          if (id != null && id.isNotEmpty) {
            nameMap[id] = name.isNotEmpty ? name : 'Unknown Employee';
          }
        }

        setState(() {
          _employeeNameMap = nameMap;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load employee names';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading employees: $e';
      });
    }
  }

  String _getEmployeeName(String employeeId, String? firebaseName) {
    // Use Firebase name if available, otherwise fallback to backend map
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }
    return _employeeNameMap[employeeId] ?? employeeId;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: initialDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      });
      // Only load route if dates changed (not on initial selection)
      if (_selectedEmployeeId != null) {
        _hasLoadedRoute = false; // Reset flag when dates change
        await _loadRoute();
      }
    }
  }

  Future<void> _loadRoute() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingRoute || _hasLoadedRoute) {
      return;
    }
    final employeeId = _selectedEmployeeId;
    if (employeeId == null || employeeId.isEmpty) {
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingRoute = true);

    try {
      // Get current attendance ID from live points if available
      String? attendanceId;
      if (_currentLivePoints.isNotEmpty) {
        final currentLivePoint = _currentLivePoints.firstWhere(
          (point) => point.employeeId == employeeId,
          orElse: () => _LivePoint.fallback(),
        );
        if (currentLivePoint != _LivePoint.fallback() &&
            currentLivePoint.attendanceId != null) {
          attendanceId = currentLivePoint.attendanceId;
        }
      }

      // Always use today's date range to get current session data
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

      DateTime? startDate = _startDate;
      DateTime? endDate = _endDate;

      // If no date range specified OR if dates are old, use today
      if (startDate == null || startDate.isBefore(startOfToday)) {
        startDate = startOfToday;
      }
      if (endDate == null || endDate.isBefore(startOfToday)) {
        endDate = now;
      }

      // Ensure end date is not in the future
      if (endDate.isAfter(now)) {
        endDate = now;
      }

      final result = await TrackingApiService.getRoute(
        employeeId: employeeId,
        attendanceId: attendanceId, // Filter by current attendance session
        start: startDate,
        end: endDate,
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
                  print('Error parsing route point: $e');
                }
                return null;
              })
              .whereType<LatLng>()
              .toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              _isLoadingRoute = false;
              _hasLoadedRoute = true;
            });
            // Calculate route details
            _calculateRouteDetails(employeeId, data);
            debugPrint(
              '✅ Loaded ${points.length} route points for employee $employeeId',
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _routePoints = [];
              _isLoadingRoute = false;
              _hasLoadedRoute = true;
            });
            // No route data - this is normal if employee hasn't moved yet
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _routePoints = [];
            _isLoadingRoute = false;
            _hasLoadedRoute =
                true; // Mark as loaded to prevent infinite retries
          });
          // Only log errors that aren't the Prisma model issue
          final errorMsg = result['message']?.toString() ?? '';
          if (!errorMsg.contains('count') &&
              !errorMsg.contains('undefined') &&
              !errorMsg.contains('Prisma')) {
            debugPrint('⚠️ Route load failed: $errorMsg');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routePoints = [];
          _isLoadingRoute = false;
          _hasLoadedRoute = true; // Mark as loaded to prevent infinite retries
        });
        // Only log non-repetitive errors
        final errorMsg = e.toString();
        if (!errorMsg.contains('count') && !errorMsg.contains('undefined')) {
          debugPrint('❌ Route load error: $e');
        }
      }
    }
  }

  void _focusOnPoint(LatLng point) {
    _mapController.move(point, 15);
  }

  // Update live route points by combining historical route with current live position
  // This is called from StreamBuilder context with live points
  void _updateLiveRoutePointsWithLiveData(
    List<LatLng> historicalPoints,
    List<_LivePoint> livePoints,
  ) {
    if (_selectedEmployeeId == null) {
      _liveRoutePoints = historicalPoints;
      return;
    }

    final currentLivePoint = livePoints.firstWhere(
      (point) => point.employeeId == _selectedEmployeeId,
      orElse: () => _LivePoint.fallback(),
    );

    if (currentLivePoint != _LivePoint.fallback()) {
      // Combine historical route with current live position
      final combined = List<LatLng>.from(historicalPoints);
      final liveLatLng = currentLivePoint.latLng;

      // Always add live point if we have historical points
      // If no historical points, start with live point
      if (combined.isEmpty) {
        combined.add(liveLatLng);
      } else {
        final lastPoint = combined.last;
        final distance = _calculateDistance(
          lastPoint.latitude,
          lastPoint.longitude,
          liveLatLng.latitude,
          liveLatLng.longitude,
        );
        // Add if distance is more than 10 meters (reduced threshold for better tracking)
        // This ensures we capture actual movement while filtering GPS drift
        if (distance > 0.010) {
          combined.add(liveLatLng);
        } else if (combined.length == 1) {
          // If only one point, always update it to show current position
          combined[0] = liveLatLng;
        }
      }
      _liveRoutePoints = combined;

      // Debug log only when route size changes significantly (every 10 points)
      if (combined.length % 10 == 0 || combined.length <= 5) {
        debugPrint(
          '🗺️ Live route updated: ${combined.length} points (${historicalPoints.length} historical + live)',
        );
      }
    } else {
      // No live point, just use historical route
      _liveRoutePoints = historicalPoints;
    }
  }

  // Calculate route details (distance, duration, etc.)
  void _calculateRouteDetails(String employeeId, List<dynamic> routeData) {
    if (routeData.isEmpty) {
      _routeDetails[employeeId] = [];
      return;
    }

    _routeDetails[employeeId] = routeData
        .map((point) => point as Map<String, dynamic>)
        .toList();
  }

  // Calculate distance between two points in kilometers (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('Live Tracking'),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelPadding: const EdgeInsets.symmetric(vertical: 4),
            tabs: const [
              Tab(
                icon: Icon(Icons.location_on, size: 18),
                text: 'Live Tracking',
              ),
              Tab(icon: Icon(Icons.route, size: 18), text: 'Route Details'),
            ],
          ),
        ),
        actions: [
          if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
              onPressed: _loadEmployeeNames,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLiveTrackingTab(), _buildRouteDetailsTab()],
      ),
    );
  }

  Widget _buildLiveTrackingTab() {
    // Get live tracking documents - Firebase will update in real-time.
    // We filter by `updatedAt` on the server side so only recent
    // locations (last 24 hours) are streamed to the client.
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    final liveStream = FirebaseFirestore.instance
        .collection('tracking_live')
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .orderBy('updatedAt', descending: true)
        // Safety cap to avoid flooding UI if many devices are live.
        .limit(500)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: liveStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          String errorMessage = 'Error loading tracking data: $error';
          String? helpMessage;

          // Check for Firebase permission errors
          if (error.contains('PERMISSION_DENIED') ||
              error.contains('permission-denied') ||
              error.contains('Missing or insufficient permissions')) {
            errorMessage = 'Firebase Permission Denied';
            helpMessage =
                'Firestore security rules need to be deployed.\n\n'
                'Please deploy the rules from:\n'
                'firebase/firestore.rules\n\n'
                'You can do this via:\n'
                '1. Firebase Console → Firestore → Rules → Deploy\n'
                '2. Or run: firebase deploy --only firestore:rules';
          }

          return _buildErrorState(errorMessage, helpMessage: helpMessage);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        // Reduced logging - only log when there are changes
        if (docs.length != _lastDocCount) {
          debugPrint('📊 Firebase: ${docs.length} active tracking documents');
          _lastDocCount = docs.length;
        }

        // Convert raw docs into live points. We still keep a defensive
        // time filter on the client, but the heavy lifting is done by
        // the Firestore query above.
        final livePoints = docs
            .map((doc) => _LivePoint.fromDoc(doc, _employeeNameMap))
            .where((point) {
              if (point == null) return false;
              // Filter out old data - only show recent updates (last 24 hours)
              final lastUpdate = point.updatedAt ?? point.recordedAt;
              if (lastUpdate == null) return false;
              // Only include if updated within last 24 hours (covers today's sessions)
              return lastUpdate.isAfter(yesterday);
            })
            .cast<_LivePoint>()
            .toList();

        // Store current live points for route loading
        _currentLivePoints = livePoints;

        // Fetch today's active attendance for all visible employees (only once)
        // Only fetch if we don't already have data for these employees
        if (livePoints.isNotEmpty && _attendanceMap.isEmpty) {
          final employeeIds = livePoints
              .map((p) => p.employeeId)
              .toSet()
              .toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _fetchTodayAttendance(employeeIds);
            }
          });
        }

        if (livePoints.isEmpty) {
          return _buildEmptyState();
        }

        // Update live route points in real-time (combine historical + live)
        if (_selectedEmployeeId != null) {
          // Update route without triggering setState to avoid rebuild loop
          _updateLiveRoutePointsWithLiveData(_routePoints, livePoints);

          // Always ensure we have at least the current live point for polyline
          if (_liveRoutePoints.isEmpty) {
            final currentLivePoint = livePoints.firstWhere(
              (point) => point.employeeId == _selectedEmployeeId,
              orElse: () => _LivePoint.fallback(),
            );
            if (currentLivePoint != _LivePoint.fallback()) {
              _liveRoutePoints = [currentLivePoint.latLng];
            }
          }
        } else {
          _liveRoutePoints = _routePoints;
        }

        // Auto-select first employee if none selected (using post-frame callback to avoid setState during build)
        if (_selectedEmployeeId == null && livePoints.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedEmployeeId == null) {
              final first = livePoints.first;
              setState(() {
                _selectedEmployeeId = first.employeeId;
                _selectedEmployeeName = first.employeeName;
                _defaultCenter = first.latLng;
                _hasLoadedRoute =
                    false; // Reset route loading flag for new employee
              });
              // Load route immediately when employee is auto-selected
              _loadRoute();
            }
          });
        }

        // Auto-load route when employee is selected and route hasn't been loaded yet
        // Only trigger once per employee selection to prevent infinite loops
        if (_selectedEmployeeId != null &&
            !_isLoadingRoute &&
            !_hasLoadedRoute) {
          // Use a one-time callback to prevent multiple triggers
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Small delay to ensure state is settled
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted &&
                  _selectedEmployeeId != null &&
                  !_hasLoadedRoute &&
                  !_isLoadingRoute) {
                _loadRoute();
              }
            });
          });
        }

        final markers = livePoints.map((point) {
          final displayName = _getEmployeeName(
            point.employeeId,
            point.employeeName,
          );
          final isSelected = point.employeeId == _selectedEmployeeId;
          final lastUpdate = point.updatedAt ?? point.recordedAt;
          // Consider live if updated within last 2 minutes
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
                  _selectedEmployeeName = displayName;
                  _hasLoadedRoute = false; // Reset flag when employee changes
                  _routePoints = []; // Clear old route
                  _liveRoutePoints = []; // Clear old live route
                });
                _focusOnPoint(point.latLng);
                // Fetch attendance for selected employee if not already loaded
                if (!_attendanceMap.containsKey(point.employeeId)) {
                  _fetchTodayAttendance([point.employeeId]);
                }
                // Load route after state update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadRoute();
                });
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Bike PNG marker (from assets/bycicle.png)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/bycicle.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (isSelected)
                    // Live indicator dot
                    if (isLive && !isSelected)
                      Positioned(
                        top: -2,
                        right: -2,
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

        // Get center point for map initialization
        final selectedPoint = livePoints.firstWhere(
          (point) => point.employeeId == _selectedEmployeeId,
          orElse: () =>
              livePoints.isNotEmpty ? livePoints.first : _LivePoint.fallback(),
        );

        final centerPoint = livePoints.isNotEmpty
            ? selectedPoint.latLng
            : _defaultCenter;

        // Note: The StreamBuilder automatically rebuilds when Firebase data changes,
        // so markers update in real-time. The map center is set initially but
        // users can manually pan/zoom. To auto-follow, they can tap the marker.

        return Column(
          children: [
            _buildFilterBar(livePoints),
            const Divider(height: 1),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(center: centerPoint, zoom: 12),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-a.global.ssl.fastly.net/light_nolabels/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.loagma_crm',
                    maxZoom: 19,
                  ),
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-a.global.ssl.fastly.net/light_only_labels/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.loagma_crm',
                    maxZoom: 19,
                    backgroundColor: Colors.transparent,
                  ),
                  // Route polyline - show combined route (historical + live)
                  // Show polyline if we have at least 1 point (changed from 2 to show even single point routes)
                  if (_liveRoutePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _liveRoutePoints,
                          color: primaryColor,
                          strokeWidth: 5,
                          borderStrokeWidth: 2,
                          borderColor: Colors.white,
                        ),
                      ],
                    )
                  // If we only have historical route (no live points yet), show that
                  else if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: primaryColor.withOpacity(0.7),
                          strokeWidth: 4,
                          borderStrokeWidth: 1,
                          borderColor: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteDetailsTab() {
    if (_selectedEmployeeId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select an employee to view route details',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final routeData = _routeDetails[_selectedEmployeeId] ?? [];

    if (routeData.isEmpty && !_isLoadingRoute) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Route Data Available',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No tracking points found for the selected date range.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Route details will appear here once the employee starts tracking and moves around.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  // Reload route with current date range
                  _hasLoadedRoute = false;
                  _loadRoute();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Route'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingRoute) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    // Calculate route statistics
    double totalDistance = 0;
    DateTime? startTime;
    DateTime? endTime;
    int pointCount = routeData.length;

    for (int i = 0; i < routeData.length; i++) {
      final point = routeData[i];
      final lat = point['latitude'];
      final lng = point['longitude'];
      final recordedAtRaw = point['recordedAt'];

      // Backend sends recordedAt in UTC; convert to local for display.
      DateTime? recordedAt;
      if (recordedAtRaw != null) {
        if (recordedAtRaw is DateTime) {
          recordedAt = recordedAtRaw.toLocal();
        } else {
          try {
            recordedAt = DateTime.parse(recordedAtRaw.toString()).toLocal();
          } catch (_) {
            recordedAt = null;
          }
        }
      }

      if (lat != null && lng != null) {
        if (i == 0 && recordedAt != null) {
          startTime = recordedAt;
        }
        if (i == routeData.length - 1 && recordedAt != null) {
          endTime = recordedAt;
        }

        if (i > 0) {
          final prevPoint = routeData[i - 1];
          final prevLat = prevPoint['latitude'];
          final prevLng = prevPoint['longitude'];
          if (prevLat != null && prevLng != null) {
            totalDistance += _calculateDistance(
              prevLat is num
                  ? prevLat.toDouble()
                  : double.parse(prevLat.toString()),
              prevLng is num
                  ? prevLng.toDouble()
                  : double.parse(prevLng.toString()),
              lat is num ? lat.toDouble() : double.parse(lat.toString()),
              lng is num ? lng.toDouble() : double.parse(lng.toString()),
            );
          }
        }
      }
    }

    final duration = startTime != null && endTime != null
        ? endTime.difference(startTime)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee info card
          Card(
            color: primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(
                      _selectedEmployeeName?.substring(0, 1).toUpperCase() ??
                          'E',
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
                          _selectedEmployeeName ?? 'Unknown Employee',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedEmployeeId != null)
                          Text(
                            'ID: $_selectedEmployeeId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Route statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.straighten,
                          label: 'Total Distance',
                          value: '${totalDistance.toStringAsFixed(2)} km',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.location_on,
                          label: 'Tracking Points',
                          value: pointCount.toString(),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (duration != null) ...[
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.access_time,
                      label: 'Duration',
                      value: _formatDuration(duration),
                      color: Colors.orange,
                      fullWidth: true,
                    ),
                  ],
                  if (startTime != null) ...[
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.play_arrow,
                      label: 'Start Time',
                      value: DateFormat(
                        'MMM dd, yyyy HH:mm:ss',
                      ).format(startTime),
                      color: Colors.purple,
                      fullWidth: true,
                    ),
                  ],
                  if (endTime != null) ...[
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.stop,
                      label: 'End Time',
                      value: DateFormat(
                        'MMM dd, yyyy HH:mm:ss',
                      ).format(endTime),
                      color: Colors.red,
                      fullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Route points list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Points',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routeData.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final point = routeData[index];
                      final lat = point['latitude'];
                      final lng = point['longitude'];
                      final recordedAtRaw = point['recordedAt'];
                      final speed = point['speed'];
                      final accuracy = point['accuracy'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${lat?.toStringAsFixed(6) ?? 'N/A'}, ${lng?.toStringAsFixed(6) ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (recordedAtRaw != null)
                              Text(
                                () {
                                  try {
                                    final dt = recordedAtRaw is DateTime
                                        ? recordedAtRaw.toLocal()
                                        : DateTime.parse(
                                            recordedAtRaw.toString(),
                                          ).toLocal();
                                    return DateFormat(
                                      'MMM dd, HH:mm:ss',
                                    ).format(dt);
                                  } catch (_) {
                                    return recordedAtRaw.toString();
                                  }
                                }(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (speed != null || accuracy != null)
                              Text(
                                [
                                  if (speed != null)
                                    'Speed: ${speed.toStringAsFixed(1)} m/s',
                                  if (accuracy != null)
                                    'Accuracy: ±${accuracy.toStringAsFixed(0)}m',
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.location_on,
                          color: primaryColor,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildFilterBar(List<_LivePoint> livePoints) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: InputDecoration(
                labelText: 'Employee',
                prefixIcon: const Icon(Icons.person, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: livePoints.map((point) {
                final displayName = _getEmployeeName(
                  point.employeeId,
                  point.employeeName,
                );
                return DropdownMenuItem(
                  value: point.employeeId,
                  child: Text(
                    displayName.isNotEmpty ? displayName : point.employeeId,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                final selected = livePoints.firstWhere(
                  (point) => point.employeeId == value,
                  orElse: () => _LivePoint.fallback(),
                );
                final displayName = _getEmployeeName(
                  selected.employeeId,
                  selected.employeeName,
                );
                setState(() {
                  _selectedEmployeeId = value;
                  _selectedEmployeeName = displayName;
                  _hasLoadedRoute = false; // Reset flag when employee changes
                  _routePoints = []; // Clear old route
                  _liveRoutePoints = []; // Clear old live route
                });
                if (selected != _LivePoint.fallback()) {
                  _focusOnPoint(selected.latLng);
                }
                // Fetch attendance for selected employee
                _fetchTodayAttendance([value]);
                // Load route after state update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadRoute();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          if (_isLoadingRoute)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            )
          else if (_selectedEmployeeId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload Route',
              onPressed: () {
                setState(() {
                  _hasLoadedRoute = false; // Reset to allow reload
                  _routePoints = []; // Clear old route
                  _liveRoutePoints = []; // Clear old live route
                });
                _loadRoute();
              },
              color: primaryColor,
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters & info',
            onPressed: () => _showFilterBottomSheet(livePoints),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(List<_LivePoint> livePoints) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters & employee info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _startDate == null
                            ? 'Start date'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        _endDate == null
                            ? 'End date'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedEmployeeId != null)
                  Builder(
                    builder: (context) {
                      final selectedPoint = livePoints.firstWhere(
                        (point) => point.employeeId == _selectedEmployeeId,
                        orElse: () => _LivePoint.fallback(),
                      );

                      if (selectedPoint == _LivePoint.fallback()) {
                        return const SizedBox.shrink();
                      }

                      final lastUpdate =
                          selectedPoint.updatedAt ?? selectedPoint.recordedAt;
                      // Consider live if updated within last 10 minutes (more lenient)
                      final isLive =
                          lastUpdate != null &&
                          DateTime.now().difference(lastUpdate) <
                              const Duration(minutes: 10);

                      // Get actual punch-in time from attendance record (today's data)
                      final attendance =
                          _attendanceMap[selectedPoint.employeeId];
                      final punchInTime = attendance?.punchInTime;

                      // Check if punch-in time is from today
                      final now = DateTime.now();
                      final startOfToday = DateTime(
                        now.year,
                        now.month,
                        now.day,
                      );
                      final isTodayPunchIn =
                          punchInTime != null &&
                          punchInTime.isAfter(
                            startOfToday.subtract(const Duration(days: 1)),
                          ) &&
                          punchInTime.isBefore(
                            startOfToday.add(const Duration(days: 1)),
                          );

                      // Use today's punch-in time if available, otherwise fallback to tracking start time
                      final displayTime = isTodayPunchIn
                          ? punchInTime
                          : selectedPoint.recordedAt;

                      // Check if we should show "No punch-in today" message
                      final hasNoTodayPunchIn =
                          attendance == null || !isTodayPunchIn;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLive ? Colors.green : Colors.grey.shade300,
                            width: isLive ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedEmployeeName ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLive
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLive)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 8),
                                      const SizedBox(width: 4),
                                      Text(
                                        isLive ? 'LIVE' : 'OFFLINE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (hasNoTodayPunchIn && displayTime != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 14,
                                    color: Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Last punch-in: ${DateFormat('MMM dd, HH:mm').format(displayTime)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No punch-in today',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ] else if (displayTime != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Punched in: ${DateFormat('MMM dd, HH:mm').format(displayTime)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (lastUpdate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Last update: ${_formatTime(lastUpdate)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Select an employee',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadEmployeeNames,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Active Tracking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No employees are currently being tracked.\nEmployees will appear here when they punch in.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {String? helpMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error Loading Tracking Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (helpMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to Fix:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        helpMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePoint {
  final String employeeId;
  final String employeeName;
  final LatLng latLng;
  final DateTime? recordedAt;
  final DateTime? updatedAt;
  final String? attendanceId;

  _LivePoint({
    required this.employeeId,
    required this.employeeName,
    required this.latLng,
    this.recordedAt,
    this.updatedAt,
    this.attendanceId,
  });

  static _LivePoint? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> employeeNameMap,
  ) {
    try {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat == null || lng == null) {
        return null;
      }

      final employeeId = data['employeeId']?.toString() ?? doc.id;
      final firebaseName = data['employeeName']?.toString() ?? '';

      // Use Firebase name if available, otherwise fallback to backend map
      final employeeName = firebaseName.isNotEmpty
          ? firebaseName
          : (employeeNameMap[employeeId] ??
                employeeId); // Fallback to employeeId if no name found

      // Parse timestamps
      DateTime? recordedAt;
      DateTime? updatedAt;

      if (data['recordedAt'] != null) {
        final timestamp = data['recordedAt'];
        if (timestamp is Timestamp) {
          recordedAt = timestamp.toDate();
        } else if (timestamp is DateTime) {
          recordedAt = timestamp;
        }
      }

      if (data['updatedAt'] != null) {
        final timestamp = data['updatedAt'];
        if (timestamp is Timestamp) {
          updatedAt = timestamp.toDate();
        } else if (timestamp is DateTime) {
          updatedAt = timestamp;
        }
      }

      final attendanceId = data['attendanceId']?.toString();

      return _LivePoint(
        employeeId: employeeId,
        employeeName: employeeName,
        latLng: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
        recordedAt: recordedAt,
        updatedAt: updatedAt,
        attendanceId: attendanceId,
      );
    } catch (e) {
      debugPrint('❌ Error parsing tracking doc ${doc.id}: $e');
      return null;
    }
  }

  static _LivePoint fallback() => _LivePoint(
    employeeId: '',
    employeeName: '',
    latLng: LatLng(0, 0),
    recordedAt: null,
    updatedAt: null,
    attendanceId: null,
  );
}
