import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';

class SalesmanAssignmentsMapScreen extends StatefulWidget {
  const SalesmanAssignmentsMapScreen({super.key});

  @override
  State<SalesmanAssignmentsMapScreen> createState() =>
      _SalesmanAssignmentsMapScreenState();
}

class _SalesmanAssignmentsMapScreenState
    extends State<SalesmanAssignmentsMapScreen> {
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> assignments = [];
  Set<Marker> markers = {};
  bool isLoading = true;
  String? selectedAssignmentId;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments?salesmanId=$userId',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final assignmentsList = List<Map<String, dynamic>>.from(
          data['data'] ?? [],
        );

        setState(() {
          assignments = assignmentsList;
        });

        await _createMarkers();
        _fitMapToMarkers();
      }
    } catch (e) {
      print('Error fetching assignments: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createMarkers() async {
    Set<Marker> newMarkers = {};

    for (var assignment in assignments) {
      final area = assignment['area'];
      if (area == null) continue;

      final areaName = area['name'] ?? 'Unknown Area';
      final assignmentId = assignment['id'];
      final status = assignment['status'] ?? 'Unknown';

      // Try to get coordinates from area or geocode the area name
      double? lat;
      double? lng;

      // If area has coordinates
      if (area['latitude'] != null && area['longitude'] != null) {
        lat = area['latitude'] is double
            ? area['latitude']
            : double.tryParse(area['latitude'].toString());
        lng = area['longitude'] is double
            ? area['longitude']
            : double.tryParse(area['longitude'].toString());
      } else {
        // Geocode area name with city context
        final zone = area['zone'];
        final city = zone?['city'];
        final cityName = city?['name'] ?? '';

        final searchQuery = cityName.isNotEmpty
            ? '$areaName, $cityName'
            : areaName;
        final coords = await _geocodeArea(searchQuery);

        if (coords != null) {
          lat = coords['lat'];
          lng = coords['lng'];
        }
      }

      if (lat != null && lng != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(assignmentId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: areaName, snippet: 'Status: $status'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(status),
            ),
            onTap: () {
              setState(() => selectedAssignmentId = assignmentId);
            },
          ),
        );
      }
    }

    setState(() => markers = newMarkers);
  }

  Future<Map<String, double>?> _geocodeArea(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent('$query, India');
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'LoagmaCRM/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          return {
            'lat': double.parse(results[0]['lat']),
            'lng': double.parse(results[0]['lon']),
          };
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return null;
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BitmapDescriptor.hueGreen;
      case 'completed':
        return BitmapDescriptor.hueBlue;
      case 'inactive':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _fitMapToMarkers() {
    if (markers.isEmpty || _mapController == null) return;

    LatLngBounds bounds;
    if (markers.length == 1) {
      final marker = markers.first;
      bounds = LatLngBounds(
        southwest: LatLng(
          marker.position.latitude - 0.01,
          marker.position.longitude - 0.01,
        ),
        northeast: LatLng(
          marker.position.latitude + 0.01,
          marker.position.longitude + 0.01,
        ),
      );
    } else {
      double minLat = markers.first.position.latitude;
      double maxLat = markers.first.position.latitude;
      double minLng = markers.first.position.longitude;
      double maxLng = markers.first.position.longitude;

      for (var marker in markers) {
        if (marker.position.latitude < minLat)
          minLat = marker.position.latitude;
        if (marker.position.latitude > maxLat)
          maxLat = marker.position.latitude;
        if (marker.position.longitude < minLng) {
          minLng = marker.position.longitude;
        }
        if (marker.position.longitude > maxLng) {
          maxLng = marker.position.longitude;
        }
      }

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Area Allotments - Map View'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAssignments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No area allotments found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitMapToMarkers();
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.5937, 78.9629), // India center
                    zoom: 5,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
                // Legend
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.green, 'Active'),
                        _buildLegendItem(Colors.blue, 'Completed'),
                        _buildLegendItem(Colors.red, 'Inactive'),
                      ],
                    ),
                  ),
                ),
                // Selected assignment details
                if (selectedAssignmentId != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildAssignmentDetails(),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAssignmentDetails() {
    final assignment = assignments.firstWhere(
      (a) => a['id'] == selectedAssignmentId,
      orElse: () => {},
    );

    if (assignment.isEmpty) return const SizedBox.shrink();

    final area = assignment['area'];
    final status = assignment['status'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  area?['name'] ?? 'Unknown Area',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => selectedAssignmentId = null);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (area?['zone']?['name'] != null)
            Text(
              'Zone: ${area['zone']['name']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          if (area?['zone']?['city']?['name'] != null)
            Text(
              'City: ${area['zone']['city']['name']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (assignment['startDate'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Start: ${assignment['startDate'].toString().split('T')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (assignment['endDate'] != null)
            Text(
              'End: ${assignment['endDate'].toString().split('T')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
