import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  String? selectedPincode;
  String screenTitle = 'Area Allotments Map';

  // Filters
  String? selectedCity;
  String? selectedState;
  bool showMetrics = true;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    // Don't fetch assignments here, wait for didChangeDependencies to get arguments
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['isMultiple'] == true && args['assignments'] != null) {
        // Multiple assignments passed from "View All on Map"
        setState(() {
          assignments = List<Map<String, dynamic>>.from(args['assignments']);
          screenTitle = 'All Area Allotments Map';
          isLoading = false;
        });
        createMarkers();
      } else if (args['assignment'] != null) {
        // Single assignment passed from "View on Map"
        final assignment = args['assignment'];
        setState(() {
          assignments = [assignment];
          screenTitle = '${assignment['city']} - ${assignment['pincode']} Map';
          isLoading = false;
        });
        createMarkers();
      } else {
        // No arguments, fetch assignments normally
        fetchAssignments();
      }
    } else {
      // No arguments, fetch assignments normally
      fetchAssignments();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> fetchAssignments() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments/assignments/salesman/$userId',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final assignmentsList = List<Map<String, dynamic>>.from(
          data['assignments'] ?? [],
        );

        setState(() {
          assignments = assignmentsList;
        });

        await createMarkers();
        if (mounted) {
          _fitMapToMarkers();
        }
      }
    } catch (e) {
      print('Error fetching assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> createMarkers() async {
    Set<Marker> newMarkers = {};

    for (var assignment in filteredAssignments) {
      final pincode = assignment['pincode'];
      final city = assignment['city'] ?? '';
      final state = assignment['state'] ?? '';
      final areas = assignment['areas'] as List<dynamic>? ?? [];
      final totalBusinesses = assignment['totalBusinesses'] ?? 0;

      if (pincode == null) continue;

      // Geocode pincode
      final coords = await _geocodePincode(pincode, city, state);

      if (coords != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(pincode),
            position: LatLng(coords['lat']!, coords['lng']!),
            infoWindow: InfoWindow(
              title: 'Pincode: $pincode',
              snippet: '$city - ${areas.length} areas, $totalBusinesses shops',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () {
              setState(() => selectedPincode = pincode);
            },
          ),
        );
      }
    }

    if (mounted) {
      setState(() => markers = newMarkers);
    }
  }

  Future<Map<String, double>?> _geocodePincode(
    String pincode,
    String city,
    String state,
  ) async {
    try {
      final query = [
        pincode,
        city,
        state,
        'India',
      ].where((s) => s.isNotEmpty).join(', ');
      final encodedQuery = Uri.encodeComponent(query);
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
      print('Geocoding error for $pincode: $e');
    }
    return null;
  }

  void _fitMapToMarkers() {
    if (markers.isEmpty || _mapController == null) return;

    LatLngBounds bounds;
    if (markers.length == 1) {
      final marker = markers.first;
      bounds = LatLngBounds(
        southwest: LatLng(
          marker.position.latitude - 0.1,
          marker.position.longitude - 0.1,
        ),
        northeast: LatLng(
          marker.position.latitude + 0.1,
          marker.position.longitude + 0.1,
        ),
      );
    } else {
      double minLat = markers.first.position.latitude;
      double maxLat = markers.first.position.latitude;
      double minLng = markers.first.position.longitude;
      double maxLng = markers.first.position.longitude;

      for (var marker in markers) {
        if (marker.position.latitude < minLat) {
          minLat = marker.position.latitude;
        }
        if (marker.position.latitude > maxLat) {
          maxLat = marker.position.latitude;
        }
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

    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    });
  }

  List<Map<String, dynamic>> get filteredAssignments {
    return assignments.where((assignment) {
      if (selectedCity != null && assignment['city'] != selectedCity) {
        return false;
      }
      if (selectedState != null && assignment['state'] != selectedState) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get cities {
    return assignments
        .map((a) => a['city'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get states {
    return assignments
        .map((a) => a['state'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  void _clearFilters() {
    setState(() {
      selectedCity = null;
      selectedState = null;
      selectedPincode = null;
    });
    createMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(showMetrics ? Icons.visibility_off : Icons.visibility),
            tooltip: showMetrics ? 'Hide Metrics' : 'Show Metrics',
            onPressed: () {
              setState(() => showMetrics = !showMetrics);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          ),
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
                // Map
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
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),

                // Metrics Bar (Top)
                if (showMetrics) _buildMetricsBar(),

                // Filters (Below Metrics)
                if (showMetrics) _buildFiltersBar(),

                // Selected Assignment Details (Bottom)
                if (selectedPincode != null) _buildAssignmentDetails(),
              ],
            ),
    );
  }

  Widget _buildMetricsBar() {
    final totalAreas = filteredAssignments.length;
    final totalShops = filteredAssignments.fold<int>(
      0,
      (sum, a) => sum + (a['totalBusinesses'] as int? ?? 0),
    );
    final totalPincodes = filteredAssignments
        .map((a) => a['pincode'])
        .toSet()
        .length;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD7BE69), Color(0xFFE8D699)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(Icons.location_city, totalPincodes.toString()),
            Container(width: 1, height: 30, color: Colors.white30),
            _buildMetricItem(Icons.place, totalAreas.toString()),
            Container(width: 1, height: 30, color: Colors.white30),
            _buildMetricItem(Icons.store, totalShops.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Positioned(
      top: 60,
      left: 8,
      right: 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // City Filter
            if (cities.isNotEmpty)
              _buildFilterChip(
                label: selectedCity ?? 'All Cities',
                icon: Icons.location_city,
                onTap: () => _showCityFilter(),
                isSelected: selectedCity != null,
              ),
            const SizedBox(width: 8),

            // State Filter
            if (states.isNotEmpty)
              _buildFilterChip(
                label: selectedState ?? 'All States',
                icon: Icons.map,
                onTap: () => _showStateFilter(),
                isSelected: selectedState != null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showCityFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select City',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Cities'),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedCity,
                onChanged: (value) {
                  setState(() => selectedCity = value);
                  Navigator.pop(context);
                  createMarkers();
                },
              ),
            ),
            ...cities.map(
              (city) => ListTile(
                title: Text(city),
                leading: Radio<String?>(
                  value: city,
                  groupValue: selectedCity,
                  onChanged: (value) {
                    setState(() => selectedCity = value);
                    Navigator.pop(context);
                    createMarkers();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStateFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All States'),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedState,
                onChanged: (value) {
                  setState(() => selectedState = value);
                  Navigator.pop(context);
                  createMarkers();
                },
              ),
            ),
            ...states.map(
              (state) => ListTile(
                title: Text(state),
                leading: Radio<String?>(
                  value: state,
                  groupValue: selectedState,
                  onChanged: (value) {
                    setState(() => selectedState = value);
                    Navigator.pop(context);
                    createMarkers();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentDetails() {
    final assignment = assignments.firstWhere(
      (a) => a['pincode'] == selectedPincode,
      orElse: () => {},
    );

    if (assignment.isEmpty) return const SizedBox.shrink();

    final pincode = assignment['pincode'] ?? 'N/A';
    final city = assignment['city'] ?? '';
    final state = assignment['state'] ?? '';
    final areas = assignment['areas'] as List<dynamic>? ?? [];
    final businessTypes = assignment['businessTypes'] as List<dynamic>? ?? [];
    final totalBusinesses = assignment['totalBusinesses'] ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pincode: $pincode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (city.isNotEmpty || state.isNotEmpty)
                        Text(
                          [city, state].where((s) => s.isNotEmpty).join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => selectedPincode = null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailChip(
                  Icons.place,
                  '${areas.length} Areas',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  Icons.business,
                  '${businessTypes.length} Types',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  Icons.store,
                  '$totalBusinesses Shops',
                  Colors.green,
                ),
              ],
            ),
            if (areas.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Areas:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: areas.take(5).map((area) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      area.toString(),
                      style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                    ),
                  );
                }).toList(),
              ),
              if (areas.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${areas.length - 5} more',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
