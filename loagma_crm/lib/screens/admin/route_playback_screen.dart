import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/route_service.dart';
import '../../services/mapbox_service.dart';
import '../../config/mapbox_config.dart';

/// Full-featured route playback screen with animation controls
/// Allows admin to replay salesman's route with play/pause/speed controls
class RoutePlaybackScreen extends StatefulWidget {
  final String attendanceId;
  final String employeeName;
  final DateTime date;

  const RoutePlaybackScreen({
    super.key,
    required this.attendanceId,
    required this.employeeName,
    required this.date,
  });

  @override
  State<RoutePlaybackScreen> createState() => _RoutePlaybackScreenState();
}

class _RoutePlaybackScreenState extends State<RoutePlaybackScreen>
    with TickerProviderStateMixin {
  // Mapbox map controller
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  
  // Mapbox annotations
  Map<String, PointAnnotation> _markerAnnotations = {};
  Map<String, PolylineAnnotation> _polylineAnnotations = {};

  // Animation state
  bool isPlaying = false;
  bool isLoading = true;
  int currentPointIndex = 0;
  double playbackSpeed = 1.0;
  Timer? _playbackTimer;

  // Route data
  Map<String, dynamic>? analyticsData;
  List<Map<String, dynamic>> playbackPoints = [];
  List<Map<String, dynamic>> distanceVsTime = [];
  List<Map<String, dynamic>> idlePeriods = [];
  List<Map<String, dynamic>> movementTimeline = [];

  // Map polylines (traveled path)
  List<Position> traveledPath = [];

  // Colors
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadRouteAnalytics();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _mapboxService.dispose();
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _loadRouteAnalytics() async {
    try {
      setState(() => isLoading = true);

      final result = await RouteService.getRouteAnalytics(widget.attendanceId);

      if (result['success'] == true && mounted) {
        final data = result['data'];
        setState(() {
          analyticsData = data;
          playbackPoints = List<Map<String, dynamic>>.from(
            data['playbackPoints'] ?? [],
          );
          distanceVsTime = List<Map<String, dynamic>>.from(
            data['distanceVsTime'] ?? [],
          );
          idlePeriods = List<Map<String, dynamic>>.from(
            data['idlePeriods'] ?? [],
          );
          movementTimeline = List<Map<String, dynamic>>.from(
            data['movementTimeline'] ?? [],
          );
          isLoading = false;
        });

        _initializeMap();
      } else {
        setState(() => isLoading = false);
        _showError(result['message'] ?? 'Failed to load route data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error loading route: $e');
    }
  }

  Future<void> _initializeMap() async {
    // Wait for map to be ready
    if (playbackPoints.isEmpty) return;
    if (_pointAnnotationManager == null || _polylineAnnotationManager == null) {
      // Annotation managers not ready yet, will be called from _onMapCreated
      return;
    }

    try {
      // Add start marker
      final startPoint = playbackPoints.first;
      final startPos = Position(
        startPoint['longitude'] as double,
        startPoint['latitude'] as double,
      );
      final startOptions = PointAnnotationOptions(
        geometry: Point(coordinates: startPos),
        textField: '🟢 Start\n${DateFormat('hh:mm a').format(DateTime.parse(startPoint['timestamp']))}',
        textOffset: [0.0, -2.0],
        textSize: 12.0,
        iconSize: 1.2,
      );
      final startMarker = await _pointAnnotationManager!.create(startOptions);
      _markerAnnotations['start'] = startMarker;

      // Add end marker
      final endPoint = playbackPoints.last;
      final endPos = Position(
        endPoint['longitude'] as double,
        endPoint['latitude'] as double,
      );
      final endOptions = PointAnnotationOptions(
        geometry: Point(coordinates: endPos),
        textField: '🔴 End\n${DateFormat('hh:mm a').format(DateTime.parse(endPoint['timestamp']))}',
        textOffset: [0.0, -2.0],
        textSize: 12.0,
        iconSize: 1.2,
      );
      final endMarker = await _pointAnnotationManager!.create(endOptions);
      _markerAnnotations['end'] = endMarker;

      // Add idle period markers
      for (int i = 0; i < idlePeriods.length; i++) {
        final idle = idlePeriods[i];
        final idlePos = Position(
          idle['longitude'] as double,
          idle['latitude'] as double,
        );
        final idleOptions = PointAnnotationOptions(
          geometry: Point(coordinates: idlePos),
          textField: '⏸ Idle Period',
          textOffset: [0.0, -2.0],
          textSize: 11.0,
          iconSize: 1.0,
        );
        final idleMarker = await _pointAnnotationManager!.create(idleOptions);
        _markerAnnotations['idle_$i'] = idleMarker;
      }

      // Add full route polyline (faded) - shows the complete route
      final fullRoute = playbackPoints
          .map((p) => Position(p['longitude'] as double, p['latitude'] as double))
          .toList();
      
      if (fullRoute.length > 1) {
        final fullRouteOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: fullRoute),
          lineColor: Colors.grey.value,
          lineWidth: 3.0,
          lineOpacity: 0.3,
        );
        final fullRoutePolyline = await _polylineAnnotationManager!.create(fullRouteOptions);
        _polylineAnnotations['full_route'] = fullRoutePolyline;
      }

      // Set initial position marker (will be updated when map is ready)
      if (currentPointIndex < playbackPoints.length) {
        await _updateCurrentPositionMarker();
      }
      
      // Focus camera on route
      _focusCameraOnRoute();
    } catch (e) {
      print('Error initializing map markers: $e');
    }
  }
  
  Future<void> _updateCurrentPositionMarker() async {
    if (playbackPoints.isEmpty || currentPointIndex >= playbackPoints.length) return;
    if (_pointAnnotationManager == null || _polylineAnnotationManager == null) return;

    try {
      final currentPoint = playbackPoints[currentPointIndex];
      final currentLat = currentPoint['latitude'] as double;
      final currentLng = currentPoint['longitude'] as double;
      final currentPos = Position(currentLng, currentLat);

      // Remove old current marker
      final oldCurrentMarker = _markerAnnotations['current'];
      if (oldCurrentMarker != null) {
        await _pointAnnotationManager!.delete(oldCurrentMarker);
        _markerAnnotations.remove('current');
      }

      // Add new current marker
      final currentOptions = PointAnnotationOptions(
        geometry: Point(coordinates: currentPos),
        textField: '📍 ${widget.employeeName}\n${(currentPoint['cumulativeDistanceKm'] ?? 0.0).toStringAsFixed(2)} km',
        textOffset: [0.0, -2.0],
        textSize: 12.0,
        iconSize: 1.5,
      );
      final currentMarker = await _pointAnnotationManager!.create(currentOptions);
      _markerAnnotations['current'] = currentMarker;

      // Update traveled path polyline
      traveledPath = playbackPoints
          .take(currentPointIndex + 1)
          .map((p) => Position(p['longitude'] as double, p['latitude'] as double))
          .toList();

      // Remove old traveled polyline
      final oldTraveledPolyline = _polylineAnnotations['traveled'];
      if (oldTraveledPolyline != null) {
        await _polylineAnnotationManager!.delete(oldTraveledPolyline);
        _polylineAnnotations.remove('traveled');
      }

      // Add new traveled polyline
      if (traveledPath.length > 1) {
        final traveledOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: traveledPath),
          lineColor: successColor.value,
          lineWidth: 5.0,
          lineOpacity: 0.8,
        );
        final traveledPolyline = await _polylineAnnotationManager!.create(traveledOptions);
        _polylineAnnotations['traveled'] = traveledPolyline;
      }
    } catch (e) {
      print('Error updating current position marker: $e');
    }
  }

  Future<void> _focusCameraOnRoute() async {
    if (_mapboxMap == null || playbackPoints.isEmpty) return;

    try {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (var point in playbackPoints) {
        final lat = point['latitude'] as double;
        final lng = point['longitude'] as double;
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      }

      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;

      await _mapboxService.fitBounds(
        bounds: CoordinateBounds(
          southwest: Point(
            coordinates: Position(minLng - lngPadding, minLat - latPadding),
          ),
          northeast: Point(
            coordinates: Position(maxLng + lngPadding, maxLat + latPadding),
          ),
          infiniteBounds: false,
        ),
        padding: 50.0,
      );
    } catch (e) {
      print('Error focusing camera on route: $e');
    }
  }

  void _play() {
    if (playbackPoints.isEmpty) return;

    setState(() => isPlaying = true);

    // Calculate interval based on speed
    final intervalMs = (500 / playbackSpeed).round();

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (
      timer,
    ) {
      if (currentPointIndex < playbackPoints.length - 1) {
        setState(() {
          currentPointIndex++;
        });
        
        // Update marker and polyline asynchronously
        _updateCurrentPositionMarker().then((_) {
          // Animate camera to follow
          final currentPoint = playbackPoints[currentPointIndex];
          if (_mapboxMap != null && _mapboxService.map != null) {
            _mapboxService.animateCamera(
              center: Point(
                coordinates: Position(
                  currentPoint['longitude'] as double,
                  currentPoint['latitude'] as double,
                ),
              ),
              zoom: 15.0,
            );
          }
        });
      } else {
        _pause();
      }
    });
  }

  void _pause() {
    _playbackTimer?.cancel();
    setState(() => isPlaying = false);
  }

  void _stop() {
    _playbackTimer?.cancel();
    setState(() {
      isPlaying = false;
      currentPointIndex = 0;
      _updateCurrentPositionMarker();
    });
    _focusCameraOnRoute();
  }

  void _forward() {
    if (currentPointIndex < playbackPoints.length - 1) {
      setState(() {
        currentPointIndex = math.min(
          currentPointIndex + 10,
          playbackPoints.length - 1,
        );
      });
      _updateCurrentPositionMarker();
    }
  }

  void _rewind() {
    if (currentPointIndex > 0) {
      setState(() {
        currentPointIndex = math.max(currentPointIndex - 10, 0);
      });
      _updateCurrentPositionMarker();
    }
  }

  void _setSpeed(double speed) {
    setState(() => playbackSpeed = speed);
    if (isPlaying) {
      _pause();
      _play();
    }
  }

  void _seekTo(double value) {
    final index = (value * (playbackPoints.length - 1)).round();
    setState(() {
      currentPointIndex = index;
    });
    _updateCurrentPositionMarker();
  }

  void _showAnalyticsDialog() {
    if (analyticsData == null) return;

    final summary = analyticsData!['summary'] as Map<String, dynamic>?;
    if (summary == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Analytics'),
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
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.employeeName, style: const TextStyle(fontSize: 16)),
            Text(
              DateFormat('MMM dd, yyyy').format(widget.date),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsDialog,
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : playbackPoints.isEmpty
          ? const Center(child: Text('No route data available'))
          : Column(
              children: [
                // Map
                Expanded(child: _buildMap()),
                // Progress info
                _buildProgressInfo(),
                // Progress slider
                _buildProgressSlider(),
                // Playback controls
                _buildPlaybackControls(),
                // Speed controls
                _buildSpeedControls(),
              ],
            ),
    );
  }

  Widget _buildMap() {
    final initialPoint = playbackPoints.isNotEmpty
        ? Position(
            playbackPoints.first['longitude'] as double,
            playbackPoints.first['latitude'] as double,
          )
        : Position(77.2090, 28.6139); // Default to Delhi
    
    return MapWidget(
      key: const ValueKey("route_playback_map"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: initialPoint),
        zoom: 14.0,
      ),
      styleUri: MapboxConfig.defaultMapStyle,
      onMapCreated: _onMapCreated,
    );
  }
  
  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      _mapboxMap = map;
      _mapboxService.initialize(map);
      
      // Create annotation managers
      _pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      _polylineAnnotationManager = await map.annotations.createPolylineAnnotationManager();
      
      // Initialize map with markers and routes
      await _initializeMap();
      
      print('✅ Mapbox map created for route playback');
    } catch (e) {
      print('❌ Error creating Mapbox map: $e');
    }
  }

  Widget _buildProgressInfo() {
    if (playbackPoints.isEmpty) return const SizedBox.shrink();

    final currentPoint = playbackPoints[currentPointIndex];
    final timestamp = DateTime.parse(currentPoint['timestamp']);
    final distance = currentPoint['cumulativeDistanceKm'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('hh:mm:ss a').format(timestamp),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Point ${currentPointIndex + 1} of ${playbackPoints.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: successColor,
                ),
              ),
              Text(
                'Distance traveled',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Slider(
        value: playbackPoints.isEmpty
            ? 0
            : currentPointIndex / (playbackPoints.length - 1),
        onChanged: _seekTo,
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10),
            onPressed: _rewind,
            tooltip: 'Rewind 10 points',
            iconSize: 32,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stop,
            tooltip: 'Stop',
            iconSize: 32,
          ),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: isPlaying ? _pause : _play,
              tooltip: isPlaying ? 'Pause' : 'Play',
              iconSize: 40,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.forward_10),
            onPressed: _forward,
            tooltip: 'Forward 10 points',
            iconSize: 32,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _focusCameraOnRoute,
            tooltip: 'Fit route',
            iconSize: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Speed: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildSpeedButton(0.5),
          _buildSpeedButton(1.0),
          _buildSpeedButton(2.0),
          _buildSpeedButton(4.0),
          _buildSpeedButton(8.0),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    final isSelected = playbackSpeed == speed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text('${speed}x'),
        selected: isSelected,
        onSelected: (_) => _setSpeed(speed),
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }
}
