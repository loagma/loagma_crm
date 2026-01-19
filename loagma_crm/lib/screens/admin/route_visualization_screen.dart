import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/route_service.dart';
import '../../services/mapbox_service.dart';
import '../../config/mapbox_config.dart';
=======
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/route_service.dart';
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

/// Enhanced route visualization with home location marking and date picker
class RouteVisualizationScreen extends StatefulWidget {
  final String? attendanceId;
  final String? employeeId;
  final String employeeName;
  final bool showDatePicker;

  const RouteVisualizationScreen({
    super.key,
    this.attendanceId,
    this.employeeId,
    required this.employeeName,
    this.showDatePicker = false,
  });

  @override
  State<RouteVisualizationScreen> createState() =>
      _RouteVisualizationScreenState();
}

class _RouteVisualizationScreenState extends State<RouteVisualizationScreen> {
<<<<<<< HEAD
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  
  // Mapbox annotations
  final Map<String, PointAnnotation> _markerAnnotations = {};
  final Map<String, PolylineAnnotation> _polylineAnnotations = {};
  
=======
  GoogleMapController? _mapController;
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  bool _isLoading = true;
  String? _error;

  // Route data
<<<<<<< HEAD
  List<Position> _routePoints = [];
  List<Map<String, double>> _routeCoordinates = []; // Store lat/lng for calculations
=======
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  double _totalDistance = 0.0;
  int _totalPoints = 0;

  // Date picker for historical routes
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _availableDates = [];
  String? _selectedAttendanceId;

  @override
  void initState() {
    super.initState();
    if (widget.showDatePicker && widget.employeeId != null) {
      _loadAvailableDates();
    } else if (widget.attendanceId != null) {
      _loadRoute();
    }
  }
<<<<<<< HEAD
  
  @override
  void dispose() {
    _mapboxService.dispose();
    _mapboxMap = null;
    super.dispose();
  }
=======
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

  Future<void> _loadAvailableDates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load route summary for the past 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final result = await RouteService.getRouteSummary(
        employeeId: widget.employeeId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success'] && result['data'] != null) {
        final List<dynamic> summaryData = result['data'];
        setState(() {
          _availableDates = summaryData
              .where((item) => item['hasRoute'] == true)
              .map(
                (item) => {
                  'date': DateTime.parse(item['date']),
                  'attendanceId': item['attendanceId'],
                  'routePointsCount': item['routePointsCount'],
                },
              )
              .toList();
        });

        // Load the most recent date by default
        if (_availableDates.isNotEmpty) {
          final mostRecent = _availableDates.first;
          _selectedDate = mostRecent['date'];
          _selectedAttendanceId = mostRecent['attendanceId'];
          _loadRoute();
        }
      } else {
        setState(() {
          _error = 'No route data available for this employee';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load available dates. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoute() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attendanceId = widget.attendanceId ?? _selectedAttendanceId;
      if (attendanceId == null) {
        setState(() {
          _error = 'No attendance session selected';
        });
        return;
      }

      final result = await RouteService.getAttendanceRoute(attendanceId);

      if (result['success'] && result['data'] != null) {
        final routeData = result['data'];
        _buildEnhancedRoute(routeData);
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
      print('Route loading error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildEnhancedRoute(Map<String, dynamic> routeData) {
    final List<dynamic> routePoints = routeData['routePoints'] ?? [];
    final Map<String, dynamic>? homeLocation = routeData['homeLocation'];
    final Map<String, dynamic>? startLocation = routeData['startLocation'];
    final Map<String, dynamic>? endLocation = routeData['endLocation'];
    final Map<String, dynamic>? summary = routeData['summary'];

    if (routePoints.isEmpty && homeLocation == null && startLocation == null) {
      setState(() {
        _error = 'No route data available';
      });
      return;
    }

<<<<<<< HEAD
    // Create route polyline from GPS points (Mapbox uses Position with lng, lat order)
    List<Position> points = [];
    List<Map<String, double>> coordinates = [];
    if (routePoints.isNotEmpty) {
      for (var point in routePoints) {
        try {
          final lat = point['latitude'].toDouble();
          final lng = point['longitude'].toDouble();
          points.add(Position(lng, lat));
          coordinates.add({'latitude': lat, 'longitude': lng});
        } catch (e) {
          print('Error parsing route point: $point, error: $e');
        }
      }
=======
    // Create route polyline from GPS points
    List<LatLng> points = [];
    if (routePoints.isNotEmpty) {
      points = routePoints
          .map((point) {
            try {
              return LatLng(
                point['latitude'].toDouble(),
                point['longitude'].toDouble(),
              );
            } catch (e) {
              print('Error parsing route point: $point, error: $e');
              return null;
            }
          })
          .where((point) => point != null)
          .cast<LatLng>()
          .toList();
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
    }

    // Use distance from API response if available, otherwise calculate locally
    double distance = 0.0;
    if (summary != null && summary['totalDistanceKm'] != null) {
      distance = (summary['totalDistanceKm'] as num).toDouble();
    } else {
<<<<<<< HEAD
      // Fallback to local calculation using original routePoints
      if (routePoints.length > 1) {
        for (int i = 1; i < routePoints.length; i++) {
          try {
            final prevPoint = routePoints[i - 1];
            final currPoint = routePoints[i];
            distance += RouteService.calculateDistance(
              prevPoint['latitude'].toDouble(),
              prevPoint['longitude'].toDouble(),
              currPoint['latitude'].toDouble(),
              currPoint['longitude'].toDouble(),
            );
          } catch (e) {
            print('Error calculating distance: $e');
          }
        }
=======
      // Fallback to local calculation
      for (int i = 1; i < points.length; i++) {
        distance += RouteService.calculateDistance(
          points[i - 1].latitude,
          points[i - 1].longitude,
          points[i].latitude,
          points[i].longitude,
        );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      }
    }

    setState(() {
      _totalDistance = distance;
      _totalPoints = points.length;
<<<<<<< HEAD
      _routePoints = points;
      _routeCoordinates = coordinates;

    });
    
    // Update Mapbox annotations after state is set
    _updateMapboxAnnotations(points, homeLocation, startLocation, endLocation);
  }
  
  // Update Mapbox annotations for route, home, start, and end markers
  Future<void> _updateMapboxAnnotations(
    List<Position> points,
    Map<String, dynamic>? homeLocation,
    Map<String, dynamic>? startLocation,
    Map<String, dynamic>? endLocation,
  ) async {
    if (_pointAnnotationManager == null || _polylineAnnotationManager == null) {
      return;
    }
    
    try {
      // Clear existing annotations
      for (var marker in _markerAnnotations.values) {
        await _pointAnnotationManager!.delete(marker);
      }
      _markerAnnotations.clear();
      
      for (var polyline in _polylineAnnotations.values) {
        await _polylineAnnotationManager!.delete(polyline);
      }
      _polylineAnnotations.clear();
      
      // Create route polyline
      if (points.length > 1) {
        final polylineOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: points),
          lineColor: const Color(0xFFD7BE69).value, // Golden theme color
          lineWidth: 4.0,
          lineOpacity: 0.8,
        );
        final polyline = await _polylineAnnotationManager!.create(polylineOptions);
        _polylineAnnotations['route'] = polyline;
      }
      
      // Home location marker (most important - where salesman started working)
      if (homeLocation != null) {
        try {
          final homePos = Position(
            homeLocation['longitude'].toDouble(),
            homeLocation['latitude'].toDouble(),
          );
          final options = PointAnnotationOptions(
            geometry: Point(coordinates: homePos),
            textField: '🏠 Home Location\nStarted at ${_formatTime(homeLocation['time'])}',
            textOffset: [0.0, -2.0],
            textSize: 12.0,
            iconSize: 1.2,
          );
          final marker = await _pointAnnotationManager!.create(options);
          _markerAnnotations['home'] = marker;
=======

      // Create polyline with golden theme color
      _polylines = {};
      if (points.length > 1) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFFD7BE69), // Golden theme color
            width: 4,
          ),
        );
      }

      // Create markers
      _markers = {};

      // Home location marker (most important - where salesman started working)
      if (homeLocation != null) {
        try {
          final homeLatLng = LatLng(
            homeLocation['latitude'].toDouble(),
            homeLocation['longitude'].toDouble(),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('home'),
              position: homeLatLng,
              infoWindow: InfoWindow(
                title: '🏠 Home Location',
                snippet:
                    'Started working here at ${_formatTime(homeLocation['time'])}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue, // Blue for home
              ),
            ),
          );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        } catch (e) {
          print('Error creating home marker: $e');
        }
      }
<<<<<<< HEAD
      
      // Start location marker (punch-in location)
      if (startLocation != null) {
        try {
          final startPos = Position(
            startLocation['longitude'].toDouble(),
            startLocation['latitude'].toDouble(),
          );
          final options = PointAnnotationOptions(
            geometry: Point(coordinates: startPos),
            textField: '🟢 Punch In\nStarted at ${_formatTime(startLocation['time'])}',
            textOffset: [0.0, -2.0],
            textSize: 12.0,
            iconSize: 1.2,
          );
          final marker = await _pointAnnotationManager!.create(options);
          _markerAnnotations['start'] = marker;
=======

      // Start location marker (punch-in location)
      if (startLocation != null) {
        try {
          final startLatLng = LatLng(
            startLocation['latitude'].toDouble(),
            startLocation['longitude'].toDouble(),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: startLatLng,
              infoWindow: InfoWindow(
                title: '🟢 Punch In',
                snippet: 'Started at ${_formatTime(startLocation['time'])}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen, // Green for start
              ),
            ),
          );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        } catch (e) {
          print('Error creating start marker: $e');
        }
      }
<<<<<<< HEAD
      
      // End location marker (punch-out location)
      if (endLocation != null) {
        try {
          final endPos = Position(
            endLocation['longitude'].toDouble(),
            endLocation['latitude'].toDouble(),
          );
          final options = PointAnnotationOptions(
            geometry: Point(coordinates: endPos),
            textField: '🔴 Punch Out\nEnded at ${_formatTime(endLocation['time'])}',
            textOffset: [0.0, -2.0],
            textSize: 12.0,
            iconSize: 1.2,
          );
          final marker = await _pointAnnotationManager!.create(options);
          _markerAnnotations['end'] = marker;
=======

      // End location marker (punch-out location)
      if (endLocation != null) {
        try {
          final endLatLng = LatLng(
            endLocation['latitude'].toDouble(),
            endLocation['longitude'].toDouble(),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('end'),
              position: endLatLng,
              infoWindow: InfoWindow(
                title: '🔴 Punch Out',
                snippet: 'Ended at ${_formatTime(endLocation['time'])}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed, // Red for end
              ),
            ),
          );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
        } catch (e) {
          print('Error creating end marker: $e');
        }
      }
<<<<<<< HEAD
      
      // Fit map to show all markers
      if (_markerAnnotations.isNotEmpty && _mapboxMap != null) {
        _fitMapToMarkers();
      }
    } catch (e) {
      print('Error updating Mapbox annotations: $e');
    }
=======

      // Fit map to show all markers
      if (_markers.isNotEmpty && _mapController != null) {
        _fitMapToMarkers();
      }
    });
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  }

  String _formatTime(dynamic timeData) {
    try {
      final DateTime time = DateTime.parse(timeData.toString());
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return 'Unknown time';
    }
  }

<<<<<<< HEAD
  Future<void> _fitMapToMarkers() async {
    if (_markerAnnotations.isEmpty && _routeCoordinates.isEmpty) return;
=======
  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

<<<<<<< HEAD
    // Calculate bounds from route coordinates
    for (final coord in _routeCoordinates) {
      final lat = coord['latitude']!;
      final lng = coord['longitude']!;
=======
    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

<<<<<<< HEAD
    if (minLat != double.infinity && _mapboxMap != null && _mapboxService.map != null) {
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
        padding: 100.0,
      );
    }
=======
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
        backgroundColor: const Color(0xFFD7BE69),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.showDatePicker && _availableDates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _showDatePicker,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.showDatePicker ? _loadAvailableDates : _loadRoute,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : _error != null
          ? _buildErrorState()
          : Column(
              children: [
                // Date selector for historical routes
                if (widget.showDatePicker && _availableDates.isNotEmpty)
                  _buildDateSelector(),

                // Route info bar
                _buildInfoBar(),

                // Map
                Expanded(child: _buildMap()),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: widget.showDatePicker ? _loadAvailableDates : _loadRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFFD7BE69)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Date',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showDatePicker,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
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
          _buildInfoItem('${_totalDistance.toStringAsFixed(1)} km', 'Distance'),
          _buildDivider(),
          _buildInfoItem('$_totalPoints', 'GPS Points'),
          _buildDivider(),
          _buildInfoItem('${_markers.length}', 'Locations'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD7BE69),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFD7BE69).withOpacity(0.3),
    );
  }

  Widget _buildMap() {
<<<<<<< HEAD
    return MapWidget(
      key: const ValueKey("route_visualization_map"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(77.2090, 28.6139)), // Default to Delhi
        zoom: 12.0,
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
      
      // If route data is already loaded, update annotations
      if (_routePoints.isNotEmpty) {
        // Rebuild annotations with current data
        await _updateMapboxAnnotations(_routePoints, null, null, null);
      }
      
      print('✅ Mapbox map created for route visualization');
    } catch (e) {
      print('❌ Error creating Mapbox map: $e');
    }
  }
=======
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_markers.isNotEmpty) {
          _fitMapToMarkers();
        }
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(28.6139, 77.2090), // Default to Delhi
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
    );
  }
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517

  Future<void> _showDatePicker() async {
    if (_availableDates.isEmpty) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _availableDates.last['date'],
      lastDate: _availableDates.first['date'],
      selectableDayPredicate: (DateTime date) {
        return _availableDates.any(
          (item) =>
              item['date'].year == date.year &&
              item['date'].month == date.month &&
              item['date'].day == date.day,
        );
      },
    );

    if (selectedDate != null) {
      final selectedItem = _availableDates.firstWhere(
        (item) =>
            item['date'].year == selectedDate.year &&
            item['date'].month == selectedDate.month &&
            item['date'].day == selectedDate.day,
        orElse: () => _availableDates.first,
      );

      setState(() {
        _selectedDate = selectedItem['date'];
        _selectedAttendanceId = selectedItem['attendanceId'];
      });

      _loadRoute();
    }
  }
}
