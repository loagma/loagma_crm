import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/route_service.dart';

/// Simple route visualization - just map and basic info
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

class _RouteVisualizationScreenState extends State<RouteVisualizationScreen> {
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

      if (result['success'] && result['data'] != null) {
        final routeData = result['data'];
        _buildRoute(routeData);
      } else {
        setState(() {
          _error =
              result['message'] ??
              'No route data available for this attendance';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load route data. Please try again.';
      });
      print('Route loading error: $e'); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildRoute(Map<String, dynamic> routeData) {
    // Handle different possible data structures
    List<dynamic> routePoints = [];
    Map<String, dynamic>? startLocation;
    Map<String, dynamic>? endLocation;

    // Try to extract route points from different possible structures
    if (routeData['routePoints'] != null) {
      routePoints = routeData['routePoints'] as List<dynamic>;
    } else if (routeData['route'] != null &&
        routeData['route']['points'] != null) {
      routePoints = routeData['route']['points'] as List<dynamic>;
    }

    // Try to extract start/end locations
    startLocation = routeData['startLocation'] ?? routeData['start'];
    endLocation = routeData['endLocation'] ?? routeData['end'];

    if (routePoints.isEmpty && startLocation == null && endLocation == null) {
      setState(() {
        _error = 'No route data available';
      });
      return;
    }

    // Create route polyline
    List<LatLng> points = [];

    // Add route points if available
    if (routePoints.isNotEmpty) {
      points = routePoints
          .map((point) {
            try {
              return LatLng(
                (point['latitude'] ?? point['lat']).toDouble(),
                (point['longitude'] ?? point['lng']).toDouble(),
              );
            } catch (e) {
              print('Error parsing point: $point, error: $e');
              return null;
            }
          })
          .where((point) => point != null)
          .cast<LatLng>()
          .toList();
    }

    // Add start and end points if available
    LatLng? startLatLng;
    LatLng? endLatLng;

    if (startLocation != null) {
      try {
        startLatLng = LatLng(
          (startLocation['latitude'] ?? startLocation['lat']).toDouble(),
          (startLocation['longitude'] ?? startLocation['lng']).toDouble(),
        );
        if (points.isEmpty || points.first != startLatLng) {
          points.insert(0, startLatLng);
        }
      } catch (e) {
        print('Error parsing start location: $e');
      }
    }

    if (endLocation != null) {
      try {
        endLatLng = LatLng(
          (endLocation['latitude'] ?? endLocation['lat']).toDouble(),
          (endLocation['longitude'] ?? endLocation['lng']).toDouble(),
        );
        if (points.isEmpty || points.last != endLatLng) {
          points.add(endLatLng);
        }
      } catch (e) {
        print('Error parsing end location: $e');
      }
    }

    if (points.isEmpty) {
      setState(() {
        _error = 'No valid route points found';
      });
      return;
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

      // Create polyline with golden theme color
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFFD7BE69), // Golden theme color
          width: 4,
        ),
      };

      // Create markers
      _markers = {};

      if (startLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: startLatLng,
            infoWindow: const InfoWindow(title: 'Start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (endLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: endLatLng,
            infoWindow: const InfoWindow(title: 'End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
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

    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
        backgroundColor: const Color(0xFFD7BE69), // Golden theme
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRoute),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD7BE69), // Golden theme
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Simple info bar with golden theme
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7BE69).withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFD7BE69).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_totalDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD7BE69),
                            ),
                          ),
                          Text(
                            'Distance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFD7BE69).withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          Text(
                            '$_totalPoints',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD7BE69),
                            ),
                          ),
                          Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: _markers.isEmpty && _polylines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.route,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No route data available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This attendance session may not have route tracking enabled',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GoogleMap(
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
