import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_config.dart';
import '../../services/google_places_service.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';

class AdminAssignmentsMapScreen extends StatefulWidget {
  const AdminAssignmentsMapScreen({super.key});

  @override
  State<AdminAssignmentsMapScreen> createState() =>
      _AdminAssignmentsMapScreenState();
}

class _AdminAssignmentsMapScreenState extends State<AdminAssignmentsMapScreen> {
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> allAssignments = [];
  Set<Marker> markers = {};
  bool isLoading = true;
  String? selectedAssignmentId;
  String? filterStatus;

  // Google Places integration
  List<PlaceInfo> nearbyPlaces = [];
  bool isLoadingPlaces = false;
  PlaceInfo? selectedPlace;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    GooglePlacesService.instance.initialize();
    fetchAllAssignments();
  }

  Future<void> fetchAllAssignments() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/task-assignments');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          allAssignments = List<Map<String, dynamic>>.from(data['data'] ?? []);
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
    final filteredAssignments = filterStatus == null
        ? allAssignments
        : allAssignments.where((a) => a['status'] == filterStatus).toList();

    for (var assignment in filteredAssignments) {
      final area = assignment['area'];
      if (area == null) continue;

      final areaName = area['name'] ?? 'Unknown';
      final salesmanName = assignment['salesman']?['name'] ?? 'Unassigned';
      final status = assignment['status'] ?? 'Unknown';

      double? lat, lng;

      if (area['latitude'] != null && area['longitude'] != null) {
        lat = area['latitude'] is double
            ? area['latitude']
            : double.tryParse(area['latitude'].toString());
        lng = area['longitude'] is double
            ? area['longitude']
            : double.tryParse(area['longitude'].toString());
      } else {
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
            markerId: MarkerId(assignment['id']),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: areaName,
              snippet: '$salesmanName - $status',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(status),
            ),
            onTap: () {
              setState(() => selectedAssignmentId = assignment['id']);
              if (lat != null && lng != null) {
                _fetchNearbyPlaces(lat, lng);
              }
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

  Future<void> _fetchNearbyPlaces(double lat, double lng) async {
    setState(() => isLoadingPlaces = true);

    try {
      final places = await GooglePlacesService.instance.fetchNearbyPlaces(
        lat: lat,
        lng: lng,
        radius: 1500,
        type: "store",
      );

      List<PlaceInfo> placeInfoList = [];

      for (var place in places.take(10)) {
        // Limit to 10 places
        if (place.placeId != null) {
          try {
            final details = await GooglePlacesService.instance
                .fetchPlaceDetails(place.placeId!);
            if (details != null) {
              final placeInfo = PlaceInfo.fromPlaceDetails(details);
              placeInfoList.add(placeInfo);
            }
          } catch (e) {
            print('Error fetching place details: $e');
          }
        }
      }

      setState(() {
        nearbyPlaces = placeInfoList;
        isLoadingPlaces = false;
      });

      // Add place markers to map
      _addPlaceMarkers();
    } catch (e) {
      print('Error fetching nearby places: $e');
      setState(() => isLoadingPlaces = false);
    }
  }

  void _addPlaceMarkers() {
    Set<Marker> newMarkers = Set.from(markers);

    // Remove existing place markers
    newMarkers.removeWhere(
      (marker) => marker.markerId.value.startsWith('place_'),
    );

    // Add new place markers
    for (int i = 0; i < nearbyPlaces.length; i++) {
      final place = nearbyPlaces[i];
      if (place.latitude != null && place.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('place_${place.placeId}'),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(
              title: place.name,
              snippet:
                  '${place.formattedRating} • ${place.isOpenNow ? "Open" : "Closed"}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            onTap: () {
              setState(() => selectedPlace = place);
            },
          ),
        );
      }
    }

    setState(() => markers = newMarkers);
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

    if (markers.length == 1) {
      final marker = markers.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 12),
      );
      return;
    }

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (var marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Area Allotments - Map View'),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                filterStatus = value == 'All' ? null : value;
              });
              _createMarkers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Active', child: Text('Active')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
              const PopupMenuItem(value: 'Inactive', child: Text('Inactive')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllAssignments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : allAssignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No assignments found',
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
                    target: LatLng(20.5937, 78.9629),
                    zoom: 5,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                        const Divider(height: 8),
                        _buildLegendItem(Colors.purple, 'Places'),
                      ],
                    ),
                  ),
                ),
                if (selectedAssignmentId != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildAssignmentDetails(),
                  ),
                if (selectedPlace != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: PlaceDetailsWidget(
                      place: selectedPlace!,
                      onClose: () => setState(() => selectedPlace = null),
                    ),
                  ),
                if (nearbyPlaces.isNotEmpty &&
                    selectedPlace == null &&
                    selectedAssignmentId == null)
                  Positioned(bottom: 16, right: 16, child: _buildPlacesList()),
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
    final assignment = allAssignments.firstWhere(
      (a) => a['id'] == selectedAssignmentId,
      orElse: () => {},
    );
    if (assignment.isEmpty) return const SizedBox.shrink();

    final area = assignment['area'];
    final salesman = assignment['salesman'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                  area?['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => selectedAssignmentId = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Salesman: ${salesman?['name'] ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Contact: ${salesman?['contactNumber'] ?? 'N/A'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(assignment['status'] ?? ''),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              assignment['status'] ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildPlacesList() {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.place, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nearby Places (${nearbyPlaces.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (isLoadingPlaces)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: nearbyPlaces.length,
              itemBuilder: (context, index) {
                final place = nearbyPlaces[index];
                return InkWell(
                  onTap: () => setState(() => selectedPlace = place),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              place.formattedRating,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: place.isOpenNow
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                place.isOpenNow ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
