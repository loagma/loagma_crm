import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/route_service.dart';

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
  // Map controller
  GoogleMapController? _mapController;

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

  // Map markers and polylines
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> traveledPath = [];

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
    _mapController?.dispose();
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

  void _initializeMap() {
    if (playbackPoints.isEmpty) return;

    // Add start marker
    final startPoint = playbackPoints.first;
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startPoint['latitude'], startPoint['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Start',
          snippet: DateFormat(
            'hh:mm a',
          ).format(DateTime.parse(startPoint['timestamp'])),
        ),
      ),
    );

    // Add end marker
    final endPoint = playbackPoints.last;
    _markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endPoint['latitude'], endPoint['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'End',
          snippet: DateFormat(
            'hh:mm a',
          ).format(DateTime.parse(endPoint['timestamp'])),
        ),
      ),
    );

    // Add idle period markers
    for (int i = 0; i < idlePeriods.length; i++) {
      final idle = idlePeriods[i];
      _markers.add(
        Marker(
          markerId: MarkerId('idle_$i'),
          position: LatLng(idle['latitude'], idle['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: 'Idle Period',
            snippet: '${idle['durationMinutes']} minutes',
          ),
        ),
      );
    }

    // Add full route polyline (faded)
    final fullRoute = playbackPoints
        .map((p) => LatLng(p['latitude'], p['longitude']))
        .toList();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('full_route'),
        points: fullRoute,
        color: Colors.grey.withOpacity(0.3),
        width: 3,
      ),
    );

    // Add current position marker
    _updateCurrentPositionMarker();

    setState(() {});

    // Focus camera on route
    _focusCameraOnRoute();
  }

  void _updateCurrentPositionMarker() {
    if (playbackPoints.isEmpty || currentPointIndex >= playbackPoints.length) {
      return;
    }

    final currentPoint = playbackPoints[currentPointIndex];
    final currentLatLng = LatLng(
      currentPoint['latitude'],
      currentPoint['longitude'],
    );

    // Remove old current marker
    _markers.removeWhere((m) => m.markerId.value == 'current');

    // Add new current marker
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: currentLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: widget.employeeName,
          snippet:
              '${currentPoint['cumulativeDistanceKm']?.toStringAsFixed(2) ?? '0'} km',
        ),
      ),
    );

    // Update traveled path polyline
    traveledPath = playbackPoints
        .take(currentPointIndex + 1)
        .map((p) => LatLng(p['latitude'], p['longitude']))
        .toList();

    _polylines.removeWhere((p) => p.polylineId.value == 'traveled');
    if (traveledPath.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('traveled'),
          points: traveledPath,
          color: successColor,
          width: 5,
        ),
      );
    }
  }

  void _focusCameraOnRoute() {
    if (_mapController == null || playbackPoints.isEmpty) return;

    final bounds = _calculateBounds();
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _calculateBounds() {
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

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
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
          _updateCurrentPositionMarker();
        });

        // Animate camera to follow
        final currentPoint = playbackPoints[currentPointIndex];
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentPoint['latitude'], currentPoint['longitude']),
          ),
        );
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
        _updateCurrentPositionMarker();
      });
    }
  }

  void _rewind() {
    if (currentPointIndex > 0) {
      setState(() {
        currentPointIndex = math.max(currentPointIndex - 10, 0);
        _updateCurrentPositionMarker();
      });
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
      _updateCurrentPositionMarker();
    });
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
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _focusCameraOnRoute();
      },
      initialCameraPosition: CameraPosition(
        target: playbackPoints.isNotEmpty
            ? LatLng(
                playbackPoints.first['latitude'],
                playbackPoints.first['longitude'],
              )
            : const LatLng(28.6139, 77.2090),
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
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
