import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/map_task_assignment_service.dart';
import '../../models/shop_model.dart';

class AssignmentMapViewScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final String salesmanName;

  const AssignmentMapViewScreen({
    super.key,
    required this.assignment,
    required this.salesmanName,
  });

  @override
  State<AssignmentMapViewScreen> createState() =>
      _AssignmentMapViewScreenState();
}

class _AssignmentMapViewScreenState extends State<AssignmentMapViewScreen> {
  final _service = MapTaskAssignmentService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Shop> _shops = [];
  bool _isLoading = true;
  LatLng _centerPosition = const LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _loadAssignmentBusinesses();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadAssignmentBusinesses() async {
    setState(() => _isLoading = true);

    try {
      final pincode = widget.assignment['pincode'];
      final areas = (widget.assignment['areas'] as List).cast<String>();
      final businessTypes = (widget.assignment['businessTypes'] as List)
          .cast<String>();

      // Fetch businesses for this assignment
      final result = await _service.searchBusinesses(
        pincode,
        areas,
        businessTypes.isEmpty
            ? ['grocery', 'cafe', 'restaurant']
            : businessTypes,
      );

      if (result['success'] == true) {
        final businesses = result['businesses'] as List?;
        if (businesses != null) {
          List<Shop> shops = [];
          for (var business in businesses) {
            try {
              shops.add(Shop.fromGooglePlaces(business, pincode));
            } catch (e) {
              // Skip invalid shops
            }
          }

          setState(() {
            _shops = shops;
            _createMarkers();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load businesses'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};
    double totalLat = 0;
    double totalLng = 0;
    int validLocations = 0;

    for (var shop in _shops) {
      if (shop.latitude != null && shop.longitude != null) {
        totalLat += shop.latitude!;
        totalLng += shop.longitude!;
        validLocations++;

        markers.add(
          Marker(
            markerId: MarkerId(shop.placeId ?? shop.name),
            position: LatLng(shop.latitude!, shop.longitude!),
            infoWindow: InfoWindow(
              title: shop.name,
              snippet: '${shop.businessType} - ${shop.stage}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(shop.stage),
            ),
            onTap: () => _showShopDetails(shop),
          ),
        );
      }
    }

    if (validLocations > 0) {
      _centerPosition = LatLng(
        totalLat / validLocations,
        totalLng / validLocations,
      );
    }

    setState(() => _markers = markers);

    // Move camera to center
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_centerPosition, 12),
      );
    }
  }

  double _getMarkerColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'new':
        return BitmapDescriptor.hueYellow;
      case 'lead':
        return BitmapDescriptor.hueOrange;
      case 'prospect':
        return BitmapDescriptor.hueBlue;
      case 'follow-up':
        return BitmapDescriptor.hueCyan;
      case 'converted':
        return BitmapDescriptor.hueGreen;
      case 'lost':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _showShopDetails(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFFD7BE69)),
            const SizedBox(width: 8),
            Expanded(child: Text(shop.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.category, 'Type', shop.businessType),
            _buildDetailRow(Icons.flag, 'Stage', shop.stage),
            if (shop.address != null)
              _buildDetailRow(Icons.location_on, 'Address', shop.address!),
            if (shop.rating != null)
              _buildDetailRow(Icons.star, 'Rating', '${shop.rating} ⭐'),
          ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = (widget.assignment['areas'] as List).cast<String>();
    final businessTypes = (widget.assignment['businessTypes'] as List)
        .cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignment Map', style: TextStyle(fontSize: 18)),
            Text(
              widget.salesmanName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAssignmentBusinesses,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centerPosition,
                    zoom: 12,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_shops.isNotEmpty) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_centerPosition, 12),
                      );
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

          // Info Card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(215, 190, 105, 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_city,
                            color: Color(0xFFD7BE69),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.assignment['city']}, ${widget.assignment['state']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Pincode: ${widget.assignment['pincode']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.location_on,
                          '${areas.length}',
                          'Areas',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          Icons.business,
                          '${_shops.length}',
                          'Businesses',
                          Colors.green,
                        ),
                        _buildStatItem(
                          Icons.category,
                          '${businessTypes.length}',
                          'Types',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Areas list
                    ExpansionTile(
                      title: const Text(
                        'Assigned Areas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: areas
                              .map(
                                (area) => Chip(
                                  label: Text(
                                    area,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: const Color.fromRGBO(
                                    215,
                                    190,
                                    105,
                                    0.2,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD7BE69)),
                        SizedBox(height: 16),
                        Text('Loading businesses...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
