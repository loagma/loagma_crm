import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/route_service.dart';

/// Admin screen for visualizing salesman travel routes
/// Shows complete route with start/end markers and animated playback
/// Includes distance/speed graph for route analysis
class RouteVisualizationScreen extends StatefulWidget {
  final String attendanceId;
  final String employeeName;

  const RouteVisualizationScreen({
    super.key,
    required this.attendanceId,
    required this.employeeName,
  });

  @override
  State<RouteVisualizationScreen> createState() =>
      _RouteVisualizationScreenState();
}

class _RouteVisualizationScreenState extends State<RouteVisualizationScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _routeData;
  bool _isLoading = true;
  String? _error;

  // Route visualization
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];

  // Route playback animation
  Timer? _playbackTimer;
  int _currentPlaybackIndex = 0;
  bool _isPlaying = false;
  bool _playbackCompleted = false;
  bool _chartsExpanded = false;
  late AnimationController _markerAnimationController;

  // Chart data
  List<FlSpot> _distanceChartData = [];
  List<FlSpot> _speedChartData = [];
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadRouteData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _markerAnimationController.dispose();
    super.dispose();
  }

  /// Load route data from API
  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await RouteService.getAttendanceRoute(widget.attendanceId);

      if (result['success']) {
        _routeData = result['data'];
        _processRouteData();
        _setupMap();
        _generateChartData();

        // Auto-start playback after loading
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _startPlayback();
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load route data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading route: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Process route data and create map elements
  void _processRouteData() {
    if (_routeData == null) return;

    final routePoints = _routeData!['routePoints'] as List<dynamic>;
    final startLocation = _routeData!['startLocation'];
    final endLocation = _routeData!['endLocation'];

    // Create route points for polyline
    _routePoints = routePoints
        .map(
          (point) => LatLng(
            point['latitude'].toDouble(),
            point['longitude'].toDouble(),
          ),
        )
        .toList();

    // Add start and end points to route if not already included
    final startLatLng = LatLng(
      startLocation['latitude'].toDouble(),
      startLocation['longitude'].toDouble(),
    );

    if (_routePoints.isEmpty || _routePoints.first != startLatLng) {
      _routePoints.insert(0, startLatLng);
    }

    if (endLocation != null) {
      final endLatLng = LatLng(
        endLocation['latitude'].toDouble(),
        endLocation['longitude'].toDouble(),
      );

      if (_routePoints.isEmpty || _routePoints.last != endLatLng) {
        _routePoints.add(endLatLng);
      }
    }
  }

  /// Setup map markers and polylines
  void _setupMap() {
    if (_routeData == null) return;

    final startLocation = _routeData!['startLocation'];
    final endLocation = _routeData!['endLocation'];

    _markers.clear();
    _polylines.clear();

    // Start marker (green)
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(
          startLocation['latitude'].toDouble(),
          startLocation['longitude'].toDouble(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Punch In',
          snippet:
              'Time: ${_formatTime(startLocation['time'])}\n${startLocation['address'] ?? 'No address'}',
        ),
      ),
    );

    // End marker (red) - only if punch-out completed
    if (endLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
            endLocation['latitude'].toDouble(),
            endLocation['longitude'].toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Punch Out',
            snippet:
                'Time: ${_formatTime(endLocation['time'])}\n${endLocation['address'] ?? 'No address'}',
          ),
        ),
      );
    }

    // Route polyline
    if (_routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 4,
          patterns: [], // Solid line
        ),
      );
    }

    // Moving marker (initially at start)
    if (_routePoints.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('moving'),
          position: _routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(
            title: 'Current Position',
            snippet: 'Route playback in progress',
          ),
        ),
      );
    }

    setState(() {});
  }

  /// Generate chart data for distance and speed analysis
  void _generateChartData() {
    if (_routeData == null) return;

    final routePoints = _routeData!['routePoints'] as List<dynamic>;
    if (routePoints.isEmpty) return;

    _distanceChartData.clear();
    _speedChartData.clear();

    double cumulativeDistance = 0.0;
    final startTime = DateTime.parse(routePoints.first['timestamp']);

    for (int i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];
      final timestamp = DateTime.parse(point['timestamp']);
      final minutesFromStart = timestamp
          .difference(startTime)
          .inMinutes
          .toDouble();

      // Calculate distance from previous point
      if (i > 0) {
        final prevPoint = routePoints[i - 1];
        final distance = RouteService.calculateDistance(
          prevPoint['latitude'].toDouble(),
          prevPoint['longitude'].toDouble(),
          point['latitude'].toDouble(),
          point['longitude'].toDouble(),
        );
        cumulativeDistance += distance;
      }

      // Add to distance chart
      _distanceChartData.add(FlSpot(minutesFromStart, cumulativeDistance));

      // Add to speed chart if speed data available
      final speed = point['speed']?.toDouble();
      if (speed != null && speed >= 0) {
        _speedChartData.add(FlSpot(minutesFromStart, speed));
      }
    }

    _totalDistance = cumulativeDistance;
  }

  /// Start route playback animation
  void _startPlayback() {
    if (_routePoints.isEmpty || _isPlaying) return;

    setState(() {
      _isPlaying = true;
      _playbackCompleted = false;
      _currentPlaybackIndex = 0;
    });

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentPlaybackIndex >= _routePoints.length - 1) {
        _stopPlayback();
        setState(() {
          _playbackCompleted = true;
        });
        return;
      }

      _currentPlaybackIndex++;
      _updateMovingMarker();
    });
  }

  /// Stop route playback
  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    setState(() {
      _isPlaying = false;
    });
  }

  /// Reset playback to beginning
  void _resetPlayback() {
    _stopPlayback();
    setState(() {
      _currentPlaybackIndex = 0;
      _playbackCompleted = false;
    });
    _updateMovingMarker();
  }

  /// Update moving marker position during playback
  void _updateMovingMarker() {
    if (_currentPlaybackIndex >= _routePoints.length) return;

    final newPosition = _routePoints[_currentPlaybackIndex];

    // Remove old moving marker and add new one
    _markers.removeWhere((marker) => marker.markerId.value == 'moving');
    _markers.add(
      Marker(
        markerId: const MarkerId('moving'),
        position: newPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Current Position',
          snippet:
              'Point ${_currentPlaybackIndex + 1} of ${_routePoints.length}',
        ),
      ),
    );

    // Animate camera to follow marker
    _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));

    setState(() {});
  }

  /// Format time for display
  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Route: ${widget.employeeName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 1,
        toolbarHeight: 50,
        actions: [
          if (!_isLoading && _routeData != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadRouteData,
              padding: const EdgeInsets.all(8),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  SizedBox(height: 16),
                  Text('Loading route data...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRouteData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Compact route summary
                _buildRouteSummaryCard(),

                // Map view (larger)
                Expanded(child: _buildMapView()),

                // Compact playback controls
                _buildPlaybackControls(),

                // Collapsible charts
                _buildChartsView(),
              ],
            ),
    );
  }

  /// Build route summary card - Compact version
  Widget _buildRouteSummaryCard() {
    if (_routeData == null) return const SizedBox.shrink();

    final summary = _routeData!['summary'];
    final status = _routeData!['status'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactSummaryItem(
            status == 'completed' ? 'Completed' : 'Active',
            'Status',
            status == 'completed' ? Colors.green : Colors.orange,
          ),
          _buildCompactSummaryItem(
            summary['duration'] != null
                ? '${summary['duration']} min'
                : 'Ongoing',
            'Duration',
            Colors.blue,
          ),
          _buildCompactSummaryItem(
            '${_totalDistance.toStringAsFixed(1)} km',
            'Distance',
            Colors.purple,
          ),
          _buildCompactSummaryItem(
            '${summary['totalPoints']}',
            'Points',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryItem(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

  /// Build Google Maps view
  Widget _buildMapView() {
    if (_routePoints.isEmpty) {
      return const Center(child: Text('No route data available'));
    }

    // Calculate bounds for initial camera position
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;

        // Fit bounds to show entire route
        Future.delayed(const Duration(milliseconds: 500), () {
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              100.0, // padding
            ),
          );
        });
      },
      initialCameraPosition: CameraPosition(target: center, zoom: 14),
      markers: _markers,
      polylines: _polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  /// Build compact playback controls
  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Reset button
          IconButton(
            onPressed: _resetPlayback,
            icon: const Icon(Icons.replay, size: 20),
            tooltip: 'Reset',
            padding: const EdgeInsets.all(8),
          ),

          // Play/Pause button
          Container(
            decoration: BoxDecoration(
              color: _isPlaying ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _isPlaying ? _stopPlayback : _startPlayback,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
              tooltip: _isPlaying ? 'Pause' : 'Play',
              padding: const EdgeInsets.all(8),
            ),
          ),

          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Text(
              _playbackCompleted
                  ? 'Completed'
                  : _isPlaying
                  ? 'Playing (${_currentPlaybackIndex + 1}/${_routePoints.length})'
                  : 'Ready to play',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build collapsible charts view
  Widget _buildChartsView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Charts header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _chartsExpanded = !_chartsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.analytics, size: 20, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'Route Summary',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    _chartsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expandable charts content
          if (_chartsExpanded)
            SizedBox(
              height: 200,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: const Color(0xFFD7BE69),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFFD7BE69),
                      labelStyle: const TextStyle(fontSize: 12),
                      tabs: const [
                        Tab(text: 'Distance'),
                        Tab(text: 'Speed'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [_buildRouteSummary(), _buildRouteDetails()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build distance chart
  Widget _buildDistanceChart() {
    if (_distanceChartData.isEmpty) {
      return const Center(child: Text('No distance data available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(1)}km',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}min',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _distanceChartData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build speed chart
  Widget _buildSpeedChart() {
    if (_speedChartData.isEmpty) {
      return const Center(child: Text('No speed data available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}km/h',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}min',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _speedChartData,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
