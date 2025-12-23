import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/route_service.dart';

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
  GoogleMapController? _mapController;
  bool _isLoading = true;
  String? _error;

  // Route data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
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

    if (routePoints.isEmpty && homeLocation == null && startLocation == null) {
      setState(() {
        _error = 'No route data available';
      });
      return;
    }

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
    }

    // Calculate total distance
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
        } catch (e) {
          print('Error creating home marker: $e');
        }
      }

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
        } catch (e) {
          print('Error creating start marker: $e');
        }
      }

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
        } catch (e) {
          print('Error creating end marker: $e');
        }
      }

      // Fit map to show all markers
      if (_markers.isNotEmpty && _mapController != null) {
        _fitMapToMarkers();
      }
    });
  }

  String _formatTime(dynamic timeData) {
    try {
      final DateTime time = DateTime.parse(timeData.toString());
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return 'Unknown time';
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
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
