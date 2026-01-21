import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_task_assignment_service.dart';
import '../../services/google_places_service.dart';
import '../../models/shop_model.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';

// Marker data model for flutter_map
class _ShopMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String name;
  final String? businessType;
  final String? stage;
  final double? rating;
  final bool isSalesmanCreated;
  final Color color;
  final VoidCallback? onTap;

  _ShopMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    this.businessType,
    this.stage,
    this.rating,
    this.isSalesmanCreated = false,
    required this.color,
    this.onTap,
  });
}

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
  late final MapController _mapController;
  List<_ShopMarker> _markers = [];
  List<Shop> _shops = [];
  List<Shop> _salesmanCreatedShops = []; // Shops created by salesman
  bool _isLoading = true;
  bool _isMapReady = false;
  LatLng _centerPosition = LatLng(20.5937, 78.9629);
  bool _isLegendExpanded = false; // Legend collapsed by default
  bool _isInfoExpanded = false; // Info card collapsed by default
  bool _isFilterExpanded = false; // Filter section collapsed by default

  // Filter states
  Set<String> _stageFilter = {}; // Business status filter
  Set<String> _businessTypeFilter = {}; // Combined business/place type filter
  Set<String> _ratingFilter = {}; // Rating filter
  Set<String> _priceFilter = {}; // Price level filter
  bool _showGooglePlaces = true; // Show Google Places businesses
  bool _showSalesmanCreated = true; // Show salesman-created accounts

  // Combined business types - includes both dynamic types and Google Places API types
  static const List<Map<String, dynamic>> _predefinedBusinessTypes = [
    {
      'type': 'grocery_or_supermarket',
      'name': 'Grocery Store',
      'icon': Icons.local_grocery_store,
      'color': Colors.green,
    },
    {
      'type': 'restaurant',
      'name': 'Restaurant',
      'icon': Icons.restaurant,
      'color': Colors.orange,
    },
    {
      'type': 'cafe',
      'name': 'Cafe',
      'icon': Icons.local_cafe,
      'color': Colors.brown,
    },
    {
      'type': 'pharmacy',
      'name': 'Pharmacy',
      'icon': Icons.local_pharmacy,
      'color': Colors.red,
    },
    {
      'type': 'clothing_store',
      'name': 'Clothing Store',
      'icon': Icons.checkroom,
      'color': Colors.purple,
    },
    {
      'type': 'electronics_store',
      'name': 'Electronics',
      'icon': Icons.devices,
      'color': Colors.blue,
    },
    {
      'type': 'bank',
      'name': 'Bank',
      'icon': Icons.account_balance,
      'color': Colors.indigo,
    },
    {
      'type': 'gas_station',
      'name': 'Gas Station',
      'icon': Icons.local_gas_station,
      'color': Colors.teal,
    },
    {
      'type': 'bakery',
      'name': 'Bakery',
      'icon': Icons.bakery_dining,
      'color': Colors.amber,
    },
    {
      'type': 'beauty_salon',
      'name': 'Beauty Salon',
      'icon': Icons.content_cut,
      'color': Colors.pink,
    },
    {
      'type': 'hospital',
      'name': 'Hospital',
      'icon': Icons.local_hospital,
      'color': Colors.redAccent,
    },
  ];

  // Place details overlay state
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadAssignmentBusinesses();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignmentBusinesses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Check if this is multiple assignments
      final isMultiple = widget.assignment['isMultiple'] == true;
      List<Shop> allShops = [];
      List<Shop> salesmanShops = [];

      // Get salesman ID to fetch their created accounts
      String? salesmanId;
      if (isMultiple) {
        // For multiple assignments, get salesmanId from the assignment data
        salesmanId = widget.assignment['salesmanId'];
        print('🔍 Multiple assignments - salesmanId from widget: $salesmanId');

        // Fallback: try to get from first assignment if not in widget
        if (salesmanId == null) {
          final assignments =
              (widget.assignment['assignments'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          if (assignments.isNotEmpty) {
            salesmanId = assignments.first['salesmanId'];
            print('🔍 Got salesmanId from first assignment: $salesmanId');
          }
        }
      } else {
        salesmanId = widget.assignment['salesmanId'];
        print('🔍 Single assignment - salesmanId: $salesmanId');
      }

      // Fetch salesman-created accounts
      if (salesmanId != null && salesmanId.isNotEmpty) {
        print('📞 Fetching salesman-created accounts for: $salesmanId');
        try {
          final salesmanAccountsResult = await _service
              .getSalesmanCreatedAccounts(salesmanId);
          print('📥 Salesman accounts result: $salesmanAccountsResult');

          if (salesmanAccountsResult['success'] == true) {
            final accounts =
                (salesmanAccountsResult['accounts'] as List?) ?? [];
            print('✅ Found ${accounts.length} salesman-created accounts');

            for (var account in accounts) {
              try {
                print(
                  '📍 Processing account: ${account['shopName']} at ${account['latitude']}, ${account['longitude']}',
                );

                // Convert account to Shop model
                salesmanShops.add(
                  Shop(
                    id: account['id']?.toString() ?? '',
                    placeId: account['id']?.toString() ?? '',
                    name:
                        account['shopName'] ??
                        account['personName'] ??
                        'Unknown Shop',
                    address: account['address'] ?? '',
                    latitude: double.tryParse(
                      account['latitude']?.toString() ?? '',
                    ),
                    longitude: double.tryParse(
                      account['longitude']?.toString() ?? '',
                    ),
                    businessType: account['businessType'] ?? 'other',
                    stage:
                        account['customerStage'] ?? account['stage'] ?? 'new',
                    pincode: account['pincode'] ?? '',
                    rating: null,
                    createdAt: account['createdAt'] != null
                        ? DateTime.parse(account['createdAt'])
                        : DateTime.now(),
                    updatedAt: account['updatedAt'] != null
                        ? DateTime.parse(account['updatedAt'])
                        : DateTime.now(),
                  ),
                );
              } catch (e) {
                print('❌ Error parsing salesman account: $e');
                print('   Account data: $account');
              }
            }
            print(
              '✅ Successfully parsed ${salesmanShops.length} salesman accounts',
            );
          } else {
            print('⚠️ Salesman accounts fetch returned success: false');
            print('   Message: ${salesmanAccountsResult['message']}');
          }
        } catch (e) {
          print('❌ Error fetching salesman accounts: $e');
        }
      } else {
        print(
          '⚠️ No salesmanId available - cannot fetch salesman-created accounts',
        );
        print('   Assignment data: ${widget.assignment}');
      }

      if (isMultiple) {
        // Handle multiple assignments
        final assignments =
            (widget.assignment['assignments'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        for (var assignment in assignments) {
          final pincode = assignment['pincode'];
          final areas = (assignment['areas'] as List?)?.cast<String>() ?? [];
          final businessTypes =
              (assignment['businessTypes'] as List?)?.cast<String>() ?? [];

          // Fetch businesses for this assignment
          final result = await _service.searchBusinesses(
            pincode,
            areas,
            businessTypes.isEmpty
                ? ['grocery', 'cafe', 'restaurant']
                : businessTypes,
          );

          if (result['success'] == true) {
            final businesses = (result['businesses'] as List?) ?? [];
            for (var business in businesses) {
              try {
                allShops.add(Shop.fromGooglePlaces(business, pincode));
              } catch (e) {
                // Skip invalid shops
              }
            }
          }
        }
      } else {
        // Handle single assignment
        final pincode = widget.assignment['pincode'];
        final areas =
            (widget.assignment['areas'] as List?)?.cast<String>() ?? [];
        final businessTypes =
            (widget.assignment['businessTypes'] as List?)?.cast<String>() ?? [];

        // Fetch businesses for this assignment
        final result = await _service.searchBusinesses(
          pincode,
          areas,
          businessTypes.isEmpty
              ? ['grocery', 'cafe', 'restaurant']
              : businessTypes,
        );

        if (result['success'] == true) {
          final businesses = (result['businesses'] as List?) ?? [];
          for (var business in businesses) {
            try {
              allShops.add(Shop.fromGooglePlaces(business, pincode));
            } catch (e) {
              // Skip invalid shops
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _shops = allShops;
        _salesmanCreatedShops = salesmanShops;
        _createMarkers();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading businesses: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _createMarkers() {
    final markers = <_ShopMarker>[];
    double totalLat = 0;
    double totalLng = 0;
    int validLocations = 0;

    // Add markers for Google Places businesses (with filters)
    if (_showGooglePlaces) {
      for (var shop in _shops) {
        // Apply business status filter
        if (_stageFilter.isNotEmpty &&
            !_stageFilter.contains(_getBusinessStatus(shop).toLowerCase())) {
          continue;
        }

        // Apply business type filter (includes both dynamic and predefined types)
        if (_businessTypeFilter.isNotEmpty) {
          bool matchesBusinessType = false;
          for (String selectedType in _businessTypeFilter) {
            if (shop.businessType.toLowerCase().contains(
                  selectedType.toLowerCase(),
                ) ||
                selectedType.toLowerCase().contains(
                  shop.businessType.toLowerCase(),
                ) ||
                _isBusinessTypeMatch(shop.businessType, selectedType)) {
              matchesBusinessType = true;
              break;
            }
          }
          if (!matchesBusinessType) continue;
        }

        // Apply rating filter
        if (_ratingFilter.isNotEmpty && shop.rating != null) {
          final ratingRange = _getRatingRange(shop.rating!);
          if (!_ratingFilter.contains(ratingRange)) {
            continue;
          }
        }

        // Apply price filter (if available)
        if (_priceFilter.isNotEmpty) {
          // This would need price_level from Google Places API
          // For now, skip this filter for shops without price data
        }

        if (shop.latitude != null && shop.longitude != null) {
          totalLat += shop.latitude!;
          totalLng += shop.longitude!;
          validLocations++;

          markers.add(
            _ShopMarker(
              id: 'google_${shop.placeId ?? shop.name}',
              latitude: shop.latitude!,
              longitude: shop.longitude!,
              name: shop.name,
              businessType: shop.businessType,
              stage: _getBusinessStatus(shop),
              rating: shop.rating,
              isSalesmanCreated: false,
              color: _getMarkerColorByStatusColor(_getBusinessStatus(shop)),
              onTap: () => _showShopDetails(shop, false),
            ),
          );
        }
      }
    }

    // Add markers for salesman-created accounts (with filters)
    if (_showSalesmanCreated) {
      for (var shop in _salesmanCreatedShops) {
        // Apply business status filter
        if (_stageFilter.isNotEmpty &&
            !_stageFilter.contains(shop.stage.toLowerCase())) {
          continue;
        }

        // Apply business type filter (includes both dynamic and predefined types)
        if (_businessTypeFilter.isNotEmpty) {
          bool matchesBusinessType = false;
          for (String selectedType in _businessTypeFilter) {
            if (shop.businessType.toLowerCase().contains(
                  selectedType.toLowerCase(),
                ) ||
                selectedType.toLowerCase().contains(
                  shop.businessType.toLowerCase(),
                ) ||
                _isBusinessTypeMatch(shop.businessType, selectedType)) {
              matchesBusinessType = true;
              break;
            }
          }
          if (!matchesBusinessType) continue;
        }

        // Apply rating filter
        if (_ratingFilter.isNotEmpty && shop.rating != null) {
          final ratingRange = _getRatingRange(shop.rating!);
          if (!_ratingFilter.contains(ratingRange)) {
            continue;
          }
        }

        if (shop.latitude != null && shop.longitude != null) {
          totalLat += shop.latitude!;
          totalLng += shop.longitude!;
          validLocations++;

          markers.add(
            _ShopMarker(
              id: 'salesman_${shop.placeId ?? shop.name}',
              latitude: shop.latitude!,
              longitude: shop.longitude!,
              name: shop.name,
              businessType: shop.businessType,
              stage: shop.stage,
              rating: shop.rating,
              isSalesmanCreated: true,
              color: Colors.purple, // Purple for salesman-created
              onTap: () => _showShopDetails(shop, true),
            ),
          );
        }
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
    if (_isMapReady && validLocations > 0) {
      _mapController.move(_centerPosition, 12);
    }
  }
  
  // Get marker color as Color instead of hue
  Color _getMarkerColorByStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'popular':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'needs attention':
        return Colors.orange;
      case 'new listing':
        return Colors.yellow.shade700;
      default:
        return Colors.red;
    }
  }

  // Build flutter_map markers from _ShopMarker data
  List<Marker> _buildFlutterMapMarkers() {
    return _markers.map((shopMarker) {
      return Marker(
        point: LatLng(shopMarker.latitude, shopMarker.longitude),
        width: 40,
        height: 40,
        builder: (context) => GestureDetector(
          onTap: shopMarker.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: shopMarker.isSalesmanCreated 
                  ? Colors.purple 
                  : shopMarker.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              shopMarker.isSalesmanCreated 
                  ? Icons.star 
                  : Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getBusinessStatus(Shop shop) {
    // For Google Places, determine status based on available data
    if (shop.rating != null && shop.rating! >= 4.0) {
      return 'Popular';
    } else if (shop.rating != null && shop.rating! >= 3.0) {
      return 'Active';
    } else if (shop.rating != null) {
      return 'Needs Attention';
    } else {
      return 'New Listing';
    }
  }

  String _getRatingRange(double rating) {
    if (rating >= 4.5) return '4.5+ Stars';
    if (rating >= 4.0) return '4.0+ Stars';
    if (rating >= 3.5) return '3.5+ Stars';
    if (rating >= 3.0) return '3.0+ Stars';
    if (rating >= 2.0) return '2.0+ Stars';
    return 'Below 2 Stars';
  }

  bool _isBusinessTypeMatch(String businessType, String selectedType) {
    // Map business types to Google Places types and common variations
    final typeMapping = {
      'grocery_or_supermarket': ['grocery', 'supermarket', 'kirana', 'store'],
      'restaurant': ['restaurant', 'food', 'dining', 'eatery'],
      'cafe': ['cafe', 'coffee', 'tea'],
      'pharmacy': ['pharmacy', 'medical', 'drugstore', 'medicine'],
      'clothing_store': ['clothing', 'fashion', 'apparel', 'garment'],
      'electronics_store': ['electronics', 'mobile', 'computer', 'gadget'],
      'bank': ['bank', 'finance', 'atm'],
      'gas_station': ['gas', 'petrol', 'fuel', 'station'],
      'bakery': ['bakery', 'bread', 'cake', 'pastry', 'sweet'],
      'beauty_salon': ['beauty', 'salon', 'hair', 'spa', 'parlour'],
      'hospital': ['hospital', 'clinic', 'medical', 'health', 'doctor'],
    };

    final mappedTypes = typeMapping[selectedType] ?? [];
    return mappedTypes.any(
      (type) => businessType.toLowerCase().contains(type.toLowerCase()),
    );
  }

  void _showShopDetails(Shop shop, bool isSalesmanCreated) {
    if (isSalesmanCreated) {
      // Show simple dialog for salesman-created shops
      _showSalesmanShopDetails(shop);
    } else {
      // Show enhanced Google Places details for Google Places shops
      _showGooglePlacesDetails(shop);
    }
  }

  void _showSalesmanShopDetails(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_pin, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: const TextStyle(fontSize: 16)),
                  const Text(
                    'Created by Salesman',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This account was created by the salesman',
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow(Icons.category, 'Type', shop.businessType),
            _buildDetailRow(Icons.flag, 'Stage', shop.stage),
            if (shop.address != null && shop.address!.isNotEmpty)
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

  void _showGooglePlacesDetails(Shop shop) async {
    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      PlaceInfo? placeInfo;

      // Try to get Google Places details if we have a placeId
      if (shop.placeId != null && shop.placeId!.isNotEmpty) {
        try {
          final details = await GooglePlacesService.fetchPlaceDetails(
            shop.placeId!,
          );
          if (details != null) {
            placeInfo = PlaceInfo.fromRawPlaceDetails(details);
          }
        } catch (e) {
          print('Error fetching place details: $e');
        }
      }

      setState(() => _isLoading = false);

      if (placeInfo != null && mounted) {
        // Show place details as bottom sheet overlay (like salesman map)
        setState(() {
          _selectedPlace = placeInfo;
          _showPlaceDetailsOverlay = true;
        });
      } else if (mounted) {
        // Fallback to basic shop details dialog
        _showBasicShopDetails(shop);
      }
    } catch (e) {
      print('Error loading place details: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showBasicShopDetails(shop);
      }
    }
  }

  void _showBasicShopDetails(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFFD7BE69)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(shop.name, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Basic information only - Google Places details not available',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow(Icons.category, 'Type', shop.businessType),
            _buildDetailRow(Icons.flag, 'Stage', shop.stage),
            if (shop.address != null && shop.address!.isNotEmpty)
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
    final isMultiple = widget.assignment['isMultiple'] == true;

    String title;
    String subtitle;

    if (isMultiple) {
      final assignments =
          (widget.assignment['assignments'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      title = '${widget.salesmanName} - All Assignments';
      subtitle = '${assignments.length} Pincodes • ${_shops.length} Businesses';
    } else {
      final areas = (widget.assignment['areas'] as List?)?.cast<String>() ?? [];
      title =
          '${widget.assignment['city'] ?? 'Assignment'} - ${widget.assignment['pincode'] ?? ''}';
      subtitle = '${areas.length} Areas • ${_shops.length} Businesses';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              subtitle,
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
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _centerPosition,
                    zoom: 12,
                    onMapReady: () {
                      _isMapReady = true;
                      if (_shops.isNotEmpty || _salesmanCreatedShops.isNotEmpty) {
                        _mapController.move(_centerPosition, 12);
                      }
                    },
                    onTap: (_, __) {
                      // Close place details overlay when tapping on map
                      if (_showPlaceDetailsOverlay) {
                        setState(() {
                          _showPlaceDetailsOverlay = false;
                          _selectedPlace = null;
                        });
                      }
                    },
                  ),
                  children: [
                    // Base map tiles
                    TileLayer(
                      urlTemplate:
                          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_nolabels/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.loagma_crm',
                      maxZoom: 19,
                    ),
                    // Labels layer
                    TileLayer(
                      urlTemplate:
                          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_only_labels/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.loagma_crm',
                      maxZoom: 19,
                      backgroundColor: Colors.transparent,
                    ),
                    // Marker cluster layer
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        markers: _buildFlutterMapMarkers(),
                        maxClusterRadius: 40,
                        disableClusteringAtZoom: 15,
                        showPolygon: false,
                        size: const Size(40, 40),
                        anchor: AnchorPos.align(AnchorAlign.center),
                        builder: (context, cluster) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7BE69),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cluster.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

          // Filters & Legend at top
          if (!_isLoading)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.filter_list,
                              size: 16,
                              color: Color(0xFFD7BE69),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_markers.length} shown',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (_stageFilter.isNotEmpty ||
                                _businessTypeFilter.isNotEmpty ||
                                _ratingFilter.isNotEmpty ||
                                !_showGooglePlaces ||
                                !_showSalesmanCreated)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Icon(
                              _isFilterExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: const Color(0xFFD7BE69),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isFilterExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Source Filter
                            Row(
                              children: [
                                const Icon(
                                  Icons.source,
                                  size: 14,
                                  color: Color(0xFFD7BE69),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Source:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        FilterChip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.map,
                                                size: 12,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Google (${_shops.length})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          selected: _showGooglePlaces,
                                          onSelected: (selected) {
                                            setState(() {
                                              _showGooglePlaces = selected;
                                              _createMarkers();
                                            });
                                          },
                                          selectedColor: Colors.green
                                              .withValues(alpha: 0.2),
                                          checkmarkColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(width: 6),
                                        FilterChip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_pin,
                                                size: 12,
                                                color: Colors.purple,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Salesman (${_salesmanCreatedShops.length})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          selected: _showSalesmanCreated,
                                          onSelected: (selected) {
                                            setState(() {
                                              _showSalesmanCreated = selected;
                                              _createMarkers();
                                            });
                                          },
                                          selectedColor: Colors.purple
                                              .withValues(alpha: 0.2),
                                          checkmarkColor: Colors.purple,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!_showGooglePlaces || !_showSalesmanCreated)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showGooglePlaces = true;
                                        _showSalesmanCreated = true;
                                        _createMarkers();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'All',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Stage Filter (Funnel)
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: Color(0xFFD7BE69),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Stage:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildStageFilterChip(
                                          'New',
                                          'new',
                                          Colors.yellow,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildStageFilterChip(
                                          'Lead',
                                          'lead',
                                          Colors.orange,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildStageFilterChip(
                                          'Prospect',
                                          'prospect',
                                          Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildStageFilterChip(
                                          'Follow-up',
                                          'follow-up',
                                          Colors.cyan,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildStageFilterChip(
                                          'Converted',
                                          'converted',
                                          Colors.green,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildStageFilterChip(
                                          'Lost',
                                          'lost',
                                          Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_stageFilter.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _stageFilter.clear();
                                        _createMarkers();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Business Type Filter (Combined - Dynamic + Predefined Google Places Types)
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 14,
                                  color: Color(0xFFD7BE69),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Business Type:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // Predefined Google Places types
                                        ..._predefinedBusinessTypes
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              final index = entry.key;
                                              final businessType = entry.value;
                                              return Row(
                                                children: [
                                                  if (index > 0)
                                                    const SizedBox(width: 6),
                                                  _buildPredefinedBusinessTypeChip(
                                                    businessType,
                                                  ),
                                                ],
                                              );
                                            }),
                                        // Dynamic business types from data
                                        ..._getAvailableBusinessTypes()
                                            .where(
                                              (type) =>
                                                  !_predefinedBusinessTypes.any(
                                                    (predefined) =>
                                                        predefined['type'] ==
                                                            type ||
                                                        _isBusinessTypeMatch(
                                                          type,
                                                          predefined['type'],
                                                        ),
                                                  ),
                                            )
                                            .map(
                                              (type) => Row(
                                                children: [
                                                  const SizedBox(width: 6),
                                                  _buildDynamicBusinessTypeChip(
                                                    type,
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_businessTypeFilter.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _businessTypeFilter.clear();
                                        _createMarkers();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Legend
                            Row(
                              children: [
                                const Icon(
                                  Icons.legend_toggle,
                                  size: 14,
                                  color: Color(0xFFD7BE69),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Legend:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildLegendChip(
                                          'New',
                                          Colors.yellow,
                                          _getFilteredCount('new'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Lead',
                                          Colors.orange,
                                          _getFilteredCount('lead'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Prospect',
                                          Colors.blue,
                                          _getFilteredCount('prospect'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Follow-up',
                                          Colors.cyan,
                                          _getFilteredCount('follow-up'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Converted',
                                          Colors.green,
                                          _getFilteredCount('converted'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Lost',
                                          Colors.red,
                                          _getFilteredCount('lost'),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildLegendChip(
                                          'Salesman',
                                          Colors.purple,
                                          _getFilteredSalesmanCount(),
                                          isSpecial: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isLegendExpanded = !_isLegendExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isLegendExpanded
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Compact Info Card at bottom
          if (!_isLoading)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isInfoExpanded = !_isInfoExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(215, 190, 105, 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isMultiple ? Icons.person : Icons.location_city,
                                color: const Color(0xFFD7BE69),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isInfoExpanded
                                  ? Icons.expand_more
                                  : Icons.expand_less,
                              size: 18,
                              color: Color(0xFFD7BE69),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isInfoExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCompactStatItem(
                                  Icons.store,
                                  '${_shops.length}',
                                  'Google',
                                  Colors.green,
                                ),
                                _buildCompactStatItem(
                                  Icons.person_pin,
                                  '${_salesmanCreatedShops.length}',
                                  'Created',
                                  Colors.purple,
                                ),
                                if (isMultiple)
                                  _buildCompactStatItem(
                                    Icons.pin_drop,
                                    '${(widget.assignment['assignments'] as List?)?.length ?? 0}',
                                    'Pincodes',
                                    Colors.blue,
                                  )
                                else
                                  _buildCompactStatItem(
                                    Icons.location_on,
                                    '${(widget.assignment['areas'] as List?)?.length ?? 0}',
                                    'Areas',
                                    Colors.blue,
                                  ),
                              ],
                            ),
                            if (!isMultiple) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              // Areas list for single assignment
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Assigned Areas:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children:
                                    ((widget.assignment['areas'] as List?)
                                                ?.cast<String>() ??
                                            [])
                                        .map(
                                          (area) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                215,
                                                190,
                                                105,
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              area,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Place Details Overlay (like salesman map view)
          if (_showPlaceDetailsOverlay && _selectedPlace != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: PlaceDetailsWidget(
                  place: _selectedPlace!,
                  onClose: () {
                    setState(() {
                      _showPlaceDetailsOverlay = false;
                      _selectedPlace = null;
                    });
                  },
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

  Widget _buildCompactStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLegendChip(
    String label,
    Color color,
    int count, {
    bool isSpecial = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSpecial)
            const Icon(Icons.star, size: 10, color: Colors.purple)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for filters
  Widget _buildStageFilterChip(String label, String value, Color color) {
    final isSelected = _stageFilter.contains(value);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _stageFilter.add(value);
          } else {
            _stageFilter.remove(value);
          }
          _createMarkers();
        });
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPredefinedBusinessTypeChip(Map<String, dynamic> businessType) {
    final type = businessType['type'] as String;
    final name = businessType['name'] as String;
    final icon = businessType['icon'] as IconData;
    final color = businessType['color'] as Color;
    final isSelected = _businessTypeFilter.contains(type);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(name, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _businessTypeFilter.add(type);
          } else {
            _businessTypeFilter.remove(type);
          }
          _createMarkers();
        });
      },
      selectedColor: color.withValues(alpha: 0.8),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDynamicBusinessTypeChip(String type) {
    final isSelected = _businessTypeFilter.contains(type.toLowerCase());
    return FilterChip(
      label: Text(
        type[0].toUpperCase() + type.substring(1),
        style: const TextStyle(fontSize: 10),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _businessTypeFilter.add(type.toLowerCase());
          } else {
            _businessTypeFilter.remove(type.toLowerCase());
          }
          _createMarkers();
        });
      },
      selectedColor: const Color(0xFFD7BE69).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFFD7BE69),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  List<String> _getAvailableBusinessTypes() {
    final types = <String>{};
    for (var shop in _shops) {
      types.add(shop.businessType.toLowerCase());
    }
    for (var shop in _salesmanCreatedShops) {
      types.add(shop.businessType.toLowerCase());
    }
    return types.toList()..sort();
  }

  int _getFilteredCount(String stage) {
    int count = 0;
    if (_showGooglePlaces) {
      count += _shops.where((s) {
        if (_businessTypeFilter.isNotEmpty &&
            !_businessTypeFilter.contains(s.businessType.toLowerCase())) {
          return false;
        }
        return s.stage.toLowerCase() == stage;
      }).length;
    }
    if (_showSalesmanCreated) {
      count += _salesmanCreatedShops.where((s) {
        if (_businessTypeFilter.isNotEmpty &&
            !_businessTypeFilter.contains(s.businessType.toLowerCase())) {
          return false;
        }
        return s.stage.toLowerCase() == stage;
      }).length;
    }
    return count;
  }

  int _getFilteredSalesmanCount() {
    if (!_showSalesmanCreated) return 0;
    return _salesmanCreatedShops.where((s) {
      if (_stageFilter.isNotEmpty &&
          !_stageFilter.contains(s.stage.toLowerCase())) {
        return false;
      }
      if (_businessTypeFilter.isNotEmpty &&
          !_businessTypeFilter.contains(s.businessType.toLowerCase())) {
        return false;
      }
      return true;
    }).length;
  }
}
