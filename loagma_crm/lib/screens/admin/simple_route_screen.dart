import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/route_service.dart';

/// Simple route visualization - just map and basic info
class SimpleRouteScreen extends StatefulWidget {
  final String attendanceId;
  final String employeeName;

  const SimpleRouteScreen({
    super.key,
    required this.attendanceId,
    required this.employeeName,
  });

  @override
  State<SimpleRouteScreen> createState() => _SimpleRouteScreenState();
}

class _SimpleRouteScreenState extends State<SimpleRouteScreen> {
  GoogleMapController? _mapController;
  bool _isLoading = true;
  String? _error;

  // Route data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double _totalDistance = 0.0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await RouteService.getAttendanceRoute(widget.attendanceId);

      if (result['success']) {
        final routeData = result['data'];
        _buildRoute(routeData);
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load route';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildRoute(Map<String, dynamic> routeData) {
    final routePoints = routeData['routePoints'] as List<dynamic>;
    final startLocation = routeData['startLocation'];
    final endLocation = routeData['endLocation'];

    if (routePoints.isEmpty) return;

    // Create route polyline
    List<LatLng> points = routePoints
        .map(
          (point) => LatLng(
            point['latitude'].toDouble(),
            point['longitude'].toDouble(),
          ),
        )
        .toList();

    // Add start and end points if not already included
    final startLatLng = LatLng(
      startLocation['latitude'].toDouble(),
      startLocation['longitude'].toDouble(),
    );
    final endLatLng = LatLng(
      endLocation['latitude'].toDouble(),
      endLocation['longitude'].toDouble(),
    );

    if (points.isEmpty || points.first != startLatLng) {
      points.insert(0, startLatLng);
    }
    if (points.isEmpty || points.last != endLatLng) {
      points.add(endLatLng);
    }

    // Calculate distance
    double distance = 0.0;
    for (int i = 1; i < points.length; i++) {
      distance += RouteService.calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    setState(() {
      _totalDistance = distance;
      _totalPoints = points.length;

      // Create polyline
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 4,
        ),
      };

      // Create markers
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: startLatLng,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: endLatLng,
          infoWindow: const InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    // Fit map to show route
    _fitMapToRoute(points);
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRoute,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Simple info bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_totalDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Distance'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_totalPoints',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Points'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(28.6139, 77.2090),
                      zoom: 10,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }
}
