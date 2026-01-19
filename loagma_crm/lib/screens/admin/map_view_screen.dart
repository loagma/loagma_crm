import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/google_places_service.dart';
import '../../services/location_service.dart';
import '../../services/mapbox_service.dart';
import '../../config/mapbox_config.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';
import '../../services/shop_service.dart';
import '../../config/google_places_config.dart';
import '../../utils/memory_optimizer.dart';

class AdminEnhancedMapScreen extends StatefulWidget {
  const AdminEnhancedMapScreen({super.key});

  @override
  State<AdminEnhancedMapScreen> createState() => _AdminEnhancedMapScreenState();
}

class _AdminEnhancedMapScreenState extends State<AdminEnhancedMapScreen>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  PointAnnotationManager? _pointAnnotationManager;
  
  // Mapbox annotations
  Map<String, PointAnnotation> _markerAnnotations = {};
  bool _isMapReady = false;
  bool isLoading = true;

  // Marker optimization
  static const int MAX_MARKERS = 200; // Limit total markers
  Map<String, PointAnnotation> _markerCache = {}; // Cache markers to avoid recreation

  List<Map<String, dynamic>> _googlePlacesShops = [];
  bool _isLoadingGooglePlaces = false;

  List<Map<String, dynamic>> salesmanAccounts = [];
  List<PlaceInfo> nearbyPlaces = [];
  List<Map<String, dynamic>> areaAssignments = [];
  Position? _currentPosition;
  bool _locationPermissionGranted = false;

  // Single place type filtering
  String? _selectedSinglePlaceType;
  List<Map<String, dynamic>> _filteredPlaces = [];
  Map<String, List<Map<String, dynamic>>> _placeCache = {};
  Timer? _filterDebounceTimer;

  // Category mapping for Google Places types[] matching
  // A place matches if ANY of its types[] is in the category's mapped types
  static const Map<String, List<String>> categoryMap = {
    // Food & Dining
    'restaurant': ['restaurant', 'food', 'meal_takeaway', 'meal_delivery'],
    'cafe': ['cafe', 'coffee_shop'],
    'bakery': ['bakery'],
    'bar': ['bar', 'night_club'],
    'meal_takeaway': ['meal_takeaway', 'meal_delivery', 'food'],

    // Retail & Shopping
    'convenience_store': [
      'convenience_store',
      'grocery_or_supermarket',
      'store',
    ],
    'grocery_or_supermarket': [
      'grocery_or_supermarket',
      'convenience_store',
      'supermarket',
      'store',
    ],
    'supermarket': ['supermarket', 'grocery_or_supermarket', 'store'],
    'shopping_mall': ['shopping_mall', 'department_store'],
    'clothing_store': ['clothing_store', 'shoe_store'],
    'electronics_store': ['electronics_store', 'store'],
    'jewelry_store': ['jewelry_store', 'store'],
    'shoe_store': ['shoe_store', 'clothing_store'],
    'furniture_store': ['furniture_store', 'home_goods_store', 'store'],
    'hardware_store': ['hardware_store', 'store'],
    'book_store': ['book_store', 'store'],
    'pet_store': ['pet_store', 'store'],
    'florist': ['florist', 'store'],

    // Health & Medical
    'pharmacy': ['pharmacy', 'drugstore', 'health'],
    'hospital': ['hospital', 'health'],
    'doctor': ['doctor', 'health'],
    'dentist': ['dentist', 'health'],
    'gym': ['gym', 'health'],
    'spa': ['spa', 'beauty_salon', 'health'],

    // Services
    'bank': ['bank', 'atm', 'finance'],
    'atm': ['atm', 'bank', 'finance'],
    'lodging': ['lodging', 'hotel', 'motel', 'guest_house'],
    'gas_station': ['gas_station'],
    'car_repair': ['car_repair', 'car_dealer'],
    'car_wash': ['car_wash'],
    'laundry': ['laundry', 'dry_cleaning'],
    'beauty_salon': ['beauty_salon', 'hair_care', 'spa'],
    'hair_care': ['hair_care', 'beauty_salon'],

    // Education & Entertainment
    'school': ['school', 'primary_school', 'secondary_school', 'university'],
    'library': ['library'],
    'movie_theater': ['movie_theater', 'cinema'],
    'liquor_store': ['liquor_store', 'store'],
  };

  List<Map<String, dynamic>> _allSalesmen = [];
  List<String> _selectedSalesmenIds = [];
  bool _isLoadingSalesmen = false;

  bool _showFilters = false;
  bool _showPlaces = true;
  bool _showAccounts = true;
  bool _showAccountsList = false;
  List<String> _selectedPlaceTypes = ['grocery_or_supermarket'];
  int _searchRadius = 1500;

  // Place types for business discovery - matching Google Maps API types exactly
  final List<Map<String, dynamic>> _placeTypes = [
    // 🍽 Food & Dining
    {'type': 'restaurant', 'name': 'Restaurant', 'icon': Icons.restaurant},
    {'type': 'cafe', 'name': 'Cafe', 'icon': Icons.local_cafe},
    {'type': 'bakery', 'name': 'Bakery', 'icon': Icons.bakery_dining},
    {'type': 'bar', 'name': 'Bar', 'icon': Icons.local_bar},
    {'type': 'meal_takeaway', 'name': 'Takeaway', 'icon': Icons.takeout_dining},

    // 🛒 Retail & Shopping
    {
      'type': 'grocery_or_supermarket',
      'name': 'Kirana / Grocery',
      'icon': Icons.store,
    },
    {
      'type': 'supermarket',
      'name': 'Supermarket',
      'icon': Icons.local_grocery_store,
    },
    {'type': 'shopping_mall', 'name': 'Mall', 'icon': Icons.shopping_bag},
    {'type': 'clothing_store', 'name': 'Clothing', 'icon': Icons.checkroom},
    {'type': 'electronics_store', 'name': 'Electronics', 'icon': Icons.devices},
    {'type': 'jewelry_store', 'name': 'Jewelry', 'icon': Icons.diamond},
    {'type': 'shoe_store', 'name': 'Shoes', 'icon': Icons.shopping_basket},
    {'type': 'furniture_store', 'name': 'Furniture', 'icon': Icons.chair},
    {'type': 'hardware_store', 'name': 'Hardware', 'icon': Icons.build},
    {'type': 'book_store', 'name': 'Books', 'icon': Icons.menu_book},
    {'type': 'pet_store', 'name': 'Pet Store', 'icon': Icons.pets},
    {'type': 'florist', 'name': 'Florist', 'icon': Icons.local_florist},

    // 🏥 Health & Medical
    {'type': 'pharmacy', 'name': 'Pharmacy', 'icon': Icons.local_pharmacy},
    {'type': 'hospital', 'name': 'Hospital', 'icon': Icons.local_hospital},
    {'type': 'doctor', 'name': 'Doctor', 'icon': Icons.medical_services},
    {'type': 'dentist', 'name': 'Dentist', 'icon': Icons.medical_services},
    {'type': 'gym', 'name': 'Gym', 'icon': Icons.fitness_center},
    {'type': 'spa', 'name': 'Spa', 'icon': Icons.spa},

    // 🏦 Services
    {'type': 'bank', 'name': 'Bank', 'icon': Icons.account_balance},
    {'type': 'atm', 'name': 'ATM', 'icon': Icons.atm},
    {'type': 'lodging', 'name': 'Hotel', 'icon': Icons.hotel},
    {
      'type': 'gas_station',
      'name': 'Petrol Pump',
      'icon': Icons.local_gas_station,
    },
    {'type': 'car_repair', 'name': 'Car Repair', 'icon': Icons.car_repair},
    {'type': 'car_wash', 'name': 'Car Wash', 'icon': Icons.local_car_wash},
    {'type': 'laundry', 'name': 'Laundry', 'icon': Icons.local_laundry_service},
    {'type': 'beauty_salon', 'name': 'Salon', 'icon': Icons.content_cut},
    {'type': 'hair_care', 'name': 'Hair Care', 'icon': Icons.face},

    // 🎓 Education & Entertainment
    {'type': 'school', 'name': 'School', 'icon': Icons.school},
    {'type': 'library', 'name': 'Library', 'icon': Icons.local_library},
    {'type': 'movie_theater', 'name': 'Cinema', 'icon': Icons.movie},
    {'type': 'liquor_store', 'name': 'Liquor Store', 'icon': Icons.local_bar},
  ];

  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;
  bool _isLegendCollapsed = false;
  bool _isPincodeCollapsed = false;
  List<String> _selectedPincodes = [];
  List<Map<String, dynamic>> _assignedPincodes = [];

  List<String> selectedCustomerStages = [];
  List<String> selectedBusinessTypes = [];
  List<String> selectedFunnelStages = [];
  List<String> selectedPincodes = [];
  List<String> selectedAssignedAreas = [];
  bool? selectedApprovalStatus;
  DateTime? selectedFromDate; // Custom from date
  DateTime? selectedToDate; // Custom to date

  List<String> tempSelectedCustomerStages = [];
  List<String> tempSelectedBusinessTypes = [];
  List<String> tempSelectedFunnelStages = [];
  List<String> tempSelectedPincodes = [];
  List<String> tempSelectedAssignedAreas = [];
  bool? tempSelectedApprovalStatus;
  DateTime? tempSelectedFromDate; // Temp from date
  DateTime? tempSelectedToDate; // Temp to date

  List<String> availableFunnelStages = [];
  List<String> availablePincodes = [];
  List<String> availableAssignedAreas = [];
  List<String> availableCustomerStages = [];
  List<String> availableBusinessTypes = [];

  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  static const Color primaryColor = Color(0xFFD7BE69);
  static const Position _defaultLocation = Position(77.2090, 28.6139); // Delhi (lng, lat)

  static const List<String> allFunnelStages = [
    "Awareness",
    "Interest",
    "Consideration",
    "Intent",
    "Evaluation",
    "Converted",
  ];
  static const List<String> allCustomerStages = [
    'Lead',
    'Prospect',
    'Customer',
    'Inactive',
  ];
  static const List<String> allBusinessTypes = [
    "Kirana Store",
    "Sweet Shop",
    "Restaurant",
    "Bakery",
    "Caterer",
    "Hostel",
    "Hotel",
    "Cafe",
    "Other",
  ];

  @override
  void initState() {
    super.initState();

    // Set conservative memory limits
    MemoryOptimizer.setConservativeImageLimits();

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _resetTempFilters();
    _initializeMap();
  }

  @override
  void dispose() {
    _isMapReady = false;
    _mapboxService.dispose();
    _mapboxMap = null;
    _isMapReady = false;
    _mapController = null;
    _filterAnimationController.dispose();
    _filterDebounceTimer?.cancel();
    _markerCache.clear(); // Clear marker cache
    LocationService.instance.stopLocationTracking();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => isLoading = true);
    await _getCurrentLocation();
    await _loadAllSalesmen();
    if (_currentPosition != null) await _loadNearbyPlaces();

    // Optimize memory after initial load
    MemoryOptimizer.optimizeMemory();

    setState(() => isLoading = false);
  }

  Future<void> _loadAllSalesmen() async {
    setState(() => _isLoadingSalesmen = true);
    try {
      final token = UserService.token;
      if (token == null) throw Exception('Token missing');

      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          final salesmen = users.where((user) {
            final roleId = user['roleId']?.toString() ?? '';
            final role = user['role']?.toString().toLowerCase() ?? '';
            return roleId == 'R002' ||
                role.contains('salesman') ||
                role.contains('sales');
          }).toList();
          setState(() => _allSalesmen = salesmen);
          print('✅ Loaded ${_allSalesmen.length} salesmen');
        }
      }
    } catch (e) {
      print('❌ Error loading salesmen: $e');
    } finally {
      setState(() => _isLoadingSalesmen = false);
    }
  }

  Future<void> _loadAccountsForSelectedSalesmen() async {
    if (_selectedSalesmenIds.isEmpty) {
      setState(() {
        salesmanAccounts = [];
        areaAssignments = [];
        _assignedPincodes = [];
      });
      _updateMapMarkers();
      return;
    }

    setState(() => isLoading = true);
    try {
      final token = UserService.token;
      if (token == null) throw Exception('Token missing');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      List<Map<String, dynamic>> allAccounts = [];
      List<Map<String, dynamic>> allAssignments = [];

      for (String salesmanId in _selectedSalesmenIds) {
        final accountsUrl = Uri.parse(
          '${ApiConfig.baseUrl}/accounts?createdById=$salesmanId',
        );
        final accountsResponse = await http.get(accountsUrl, headers: headers);
        if (accountsResponse.statusCode == 200) {
          final data = jsonDecode(accountsResponse.body);
          if (data['success'] == true) {
            final accounts = List<Map<String, dynamic>>.from(
              data['data'] ?? [],
            );
            final salesman = _allSalesmen.firstWhere(
              (s) => s['id'] == salesmanId,
              orElse: () => {'name': 'Unknown'},
            );
            for (var account in accounts) {
              account['salesmanId'] = salesmanId;
              account['salesmanName'] = salesman['name'] ?? 'Unknown';
            }
            allAccounts.addAll(accounts);
          }
        }

        final assignmentsUrl = Uri.parse(
          '${ApiConfig.baseUrl}/task-assignments/assignments/salesman/$salesmanId',
        );
        final assignmentsResponse = await http.get(
          assignmentsUrl,
          headers: headers,
        );
        if (assignmentsResponse.statusCode == 200) {
          final data = jsonDecode(assignmentsResponse.body);
          if (data['success'] == true) {
            final assignments = List<Map<String, dynamic>>.from(
              data['assignments'] ?? data['data'] ?? [],
            );
            final salesman = _allSalesmen.firstWhere(
              (s) => s['id'] == salesmanId,
              orElse: () => {'name': 'Unknown'},
            );
            for (var assignment in assignments) {
              assignment['salesmanId'] = salesmanId;
              assignment['salesmanName'] = salesman['name'] ?? 'Unknown';
            }
            allAssignments.addAll(assignments);
          }
        }
      }

      setState(() {
        salesmanAccounts = allAccounts;
        areaAssignments = allAssignments;
      });
      print(
        '✅ Loaded ${salesmanAccounts.length} accounts, ${areaAssignments.length} assignments',
      );

      _extractFilterOptions();
      await _loadAssignedPincodes();
      await _updateMapMarkers();
      if (salesmanAccounts.isNotEmpty && _mapboxMap != null)
        await _focusOnAccountsArea();
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSalesmanSelectionDialog() {
    List<String> tempSelected = List.from(_selectedSalesmenIds);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.people, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Select Salesmen'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setDialogState(
                        () => tempSelected = _allSalesmen
                            .map((s) => s['id'].toString())
                            .toList(),
                      ),
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('Select All'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setDialogState(() => tempSelected.clear()),
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  '${tempSelected.length} of ${_allSalesmen.length} selected',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: _allSalesmen.isEmpty
                      ? const Center(child: Text('No salesmen found'))
                      : ListView.builder(
                          itemCount: _allSalesmen.length,
                          itemBuilder: (context, index) {
                            final salesman = _allSalesmen[index];
                            final id = salesman['id'].toString();
                            final name = salesman['name'] ?? 'Unknown';
                            final isSelected = tempSelected.contains(id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (v) => setDialogState(
                                () => v == true
                                    ? tempSelected.add(id)
                                    : tempSelected.remove(id),
                              ),
                              title: Text(name),
                              secondary: CircleAvatar(
                                backgroundColor: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade300,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                ),
                              ),
                              activeColor: primaryColor,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedSalesmenIds = tempSelected);
                _loadAccountsForSelectedSalesmen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check),
              label: Text('Apply (${tempSelected.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied)
        return;
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
        _locationPermissionGranted = true;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadAssignedPincodes() async {
    try {
      Map<String, Map<String, dynamic>> pincodeMap = {};
      for (var assignment in areaAssignments) {
        final pincode = assignment['pincode']?.toString();
        if (pincode != null && pincode.isNotEmpty) {
          final count = salesmanAccounts
              .where((a) => a['pincode']?.toString() == pincode)
              .length;
          pincodeMap[pincode] = {
            'pincode': pincode,
            'city': assignment['city'] ?? '',
            'state': assignment['state'] ?? '',
            'totalBusinesses': count,
            'salesmanName': assignment['salesmanName'] ?? '',
          };
        }
      }
      for (var account in salesmanAccounts) {
        final pincode = account['pincode']?.toString();
        if (pincode != null &&
            pincode.isNotEmpty &&
            !pincodeMap.containsKey(pincode)) {
          final count = salesmanAccounts
              .where((a) => a['pincode']?.toString() == pincode)
              .length;
          pincodeMap[pincode] = {
            'pincode': pincode,
            'city': account['city'] ?? '',
            'state': account['state'] ?? '',
            'totalBusinesses': count,
            'salesmanName': account['salesmanName'] ?? '',
          };
        }
      }
      setState(() => _assignedPincodes = pincodeMap.values.toList());
      print('✅ Loaded ${_assignedPincodes.length} pincodes');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void _extractFilterOptions() {
    Set<String> pincodes = {};
    for (var account in salesmanAccounts)
      if (account['pincode'] != null)
        pincodes.add(account['pincode'].toString());
    setState(() {
      availableFunnelStages = List.from(allFunnelStages);
      availableCustomerStages = List.from(allCustomerStages);
      availableBusinessTypes = List.from(allBusinessTypes);
      availablePincodes = pincodes.toList()..sort();
    });
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null) return;
    try {
      List<PlaceInfo> allPlaces = [];
      for (String placeType in _selectedPlaceTypes) {
        try {
          final results = await GooglePlacesService.fetchNearbyPlaces(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            radius: _searchRadius,
            type: placeType,
          );
          allPlaces.addAll(
            results.map((r) => PlaceInfo.fromRawNearbyResult(r)),
          );
        } catch (e) {
          print('Error: $e');
        }
      }
      final unique = <String, PlaceInfo>{};
      for (final p in allPlaces) unique[p.placeId] = p;
      setState(() => nearbyPlaces = unique.values.toList());
      await _updateMapMarkers();
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Fetch places by single type using Google Places Nearby Search API
  /// Integrates with existing map without rebuilding Mapbox MapWidget
  Future<void> fetchPlacesByType(String? selectedPlaceType) async {
    // Clear existing filtered places if no type selected
    if (selectedPlaceType == null || selectedPlaceType.isEmpty) {
      setState(() {
        _selectedSinglePlaceType = null;
        _filteredPlaces.clear();
      });
      _updateMapMarkers();
      return;
    }

    // Debounce filter changes
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performPlaceSearch(selectedPlaceType);
    });
  }

  Future<void> _performPlaceSearch(String placeType) async {
    print('🔍 === _performPlaceSearch called ===');
    print('🎯 Requested place type: $placeType');

    // Get current location - use map center if available, fallback to user location
    double? searchLat;
    double? searchLng;

    if (_mapboxMap != null && _isMapReady) {
      try {
        final cameraState = await _mapboxMap!.getCameraState();
        final centerPoint = cameraState.center;
        searchLat = centerPoint.coordinates.latitude;
        searchLng = centerPoint.coordinates.longitude;
        print('📍 Using map center: $searchLat, $searchLng');
      } catch (e) {
        // Fallback to user location
        if (_currentPosition != null) {
          searchLat = _currentPosition!.latitude;
          searchLng = _currentPosition!.longitude;
          print('📍 Using user location: $searchLat, $searchLng');
        }
      }
    } else if (_currentPosition != null) {
      searchLat = _currentPosition!.latitude;
      searchLng = _currentPosition!.longitude;
      print('📍 Using user location (fallback): $searchLat, $searchLng');
    }

    if (searchLat == null || searchLng == null) {
      print('❌ No location available for place search');
      return;
    }

    // Create cache key
    final cacheKey =
        '${placeType}_${searchLat.toStringAsFixed(4)}_${searchLng.toStringAsFixed(4)}';

    // Check cache first
    if (_placeCache.containsKey(cacheKey)) {
      print('💾 Using cached results for: $cacheKey');
      setState(() {
        _selectedSinglePlaceType = placeType;
        _filteredPlaces = _placeCache[cacheKey]!;
      });
      await _updateMapMarkers();
      return;
    }

    try {
      // Call Google Places Nearby Search API - SINGLE TYPE ONLY
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$searchLat,$searchLng'
        '&radius=5000'
        '&type=$placeType'
        '&key=${GooglePlacesConfig.apiKey}',
      );

      print('🌐 API URL: $url');
      final response = await http.get(url);
      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 API Status: ${data['status']}');

        // Only process if status is OK
        if (data['status'] == 'OK') {
          final results = data['results'] as List? ?? [];
          print('📊 Raw results count: ${results.length}');

          // Log first few results to understand the data structure
          if (results.isNotEmpty) {
            print('🔍 === SAMPLE API RESULTS ===');
            for (
              int i = 0;
              i < (results.length > 3 ? 3 : results.length);
              i++
            ) {
              final place = results[i];
              print('Place ${i + 1}:');
              print('  Name: ${place['name']}');
              print('  Types: ${place['types']}');
              print('  Business Status: ${place['business_status']}');
              print('  Rating: ${place['rating']}');
              print('  Place ID: ${place['place_id']}');
              print('  ---');
            }
            print('🔍 === END SAMPLE RESULTS ===');
          }

          // Convert to our format - store types[] as List<String>
          final places = results
              .map<Map<String, dynamic>>((place) {
                final geometry = place['geometry']?['location'];

                // Store types[] as List<String> for proper category matching
                List<String> placeTypes = [];
                if (place['types'] != null && place['types'] is List) {
                  placeTypes = List<String>.from(
                    (place['types'] as List).map(
                      (t) => t.toString().toLowerCase(),
                    ),
                  );
                }

                return {
                  'place_id': place['place_id'] ?? '',
                  'name': place['name'] ?? 'Unknown Place',
                  'latitude': geometry?['lat']?.toDouble(),
                  'longitude': geometry?['lng']?.toDouble(),
                  'rating': place['rating']?.toDouble(),
                  'types': placeTypes, // Store as List<String>
                  'businessType': placeTypes.isNotEmpty
                      ? placeTypes.first
                      : 'store',
                  'vicinity': place['vicinity'] ?? '',
                  'business_status': place['business_status'],
                  'price_level': place['price_level'],
                };
              })
              .where((place) {
                // Filter out places without valid coordinates
                return place['latitude'] != null &&
                    place['longitude'] != null &&
                    place['place_id'].toString().isNotEmpty;
              })
              .toList();

          print('✅ Processed ${places.length} valid places');

          // Log unique types found across all places
          final allTypes = <String>{};
          for (final place in places) {
            final types = place['types'] as List<String>? ?? [];
            allTypes.addAll(types);
          }
          print('🏷️ All unique types found: ${allTypes.toList()..sort()}');

          // Cache the results
          _placeCache[cacheKey] = places;

          // Update state
          setState(() {
            _selectedSinglePlaceType = placeType;
            _filteredPlaces = places;
          });

          await _updateMapMarkers();

          print('✅ Loaded ${places.length} places for type: $placeType');
        } else {
          print(
            '❌ Google Places API error: ${data['status']} - ${data['error_message'] ?? ''}',
          );
          if (data['error_message'] != null) {
            print('❌ Error details: ${data['error_message']}');
          }
          // Fail silently - don't affect UI
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        // Fail silently - don't affect UI
      }
    } catch (e) {
      print('❌ Error fetching places: $e');
      // Fail silently - don't affect UI
    }
  }

  Future<void> _updateMapMarkers() async {
    // Debounce marker updates to prevent excessive calls
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_selectedPincodes.isNotEmpty) {
        // If pincodes are selected, show all shops (existing + Google Places)
        await _updateMapMarkersWithAllShops();
      } else {
        // Default behavior - show only salesman accounts and nearby places
        await _updateMapMarkersDefault();
      }
    });
  }

  Future<void> _updateMapMarkersDefault() async {
    if (_pointAnnotationManager == null) return;
    
    // Clear existing markers
    for (var marker in _markerAnnotations.values) {
      try {
        await _pointAnnotationManager!.delete(marker);
      } catch (e) {
        print('Error deleting marker: $e');
      }
    }
    _markerAnnotations.clear();
    _markerCache.clear();

    // Add current location marker
    if (_currentPosition != null) {
      final markerId = 'current_location';
      try {
        final options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          textField: '📍 My Location',
          textOffset: [0.0, -2.0],
          textSize: 12.0,
          iconSize: 1.2,
        );
        final marker = await _pointAnnotationManager!.create(options);
        _markerAnnotations[markerId] = marker;
        _markerCache[markerId] = marker;
      } catch (e) {
        print('Error creating current location marker: $e');
      }
    }

    // Add salesman accounts - only if _showAccounts is true (with limit)
    if (_showAccounts) {
      final filteredAccounts = _getFilteredAccounts();
      final accountsToShow = filteredAccounts.take(MAX_MARKERS ~/ 2).toList();

      for (var account in accountsToShow) {
        if (account['latitude'] != null && account['longitude'] != null) {
          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());
            if (!_isValidCoordinate(lat, lng)) continue;

            final markerId = 'account_${account['id']}';
            if (!_markerCache.containsKey(markerId)) {
              try {
                final options = PointAnnotationOptions(
                  geometry: Point(coordinates: Position(lng, lat)),
                  textField: '${account['personName'] ?? 'Unknown'}\n${account['businessName'] ?? ''} • SR: ${account['salesmanName'] ?? ''}',
                  textOffset: [0.0, -2.0],
                  textSize: 11.0,
                  iconSize: account['isApproved'] == true ? 1.2 : 1.0,
                );
                final marker = await _pointAnnotationManager!.create(options);
                _markerAnnotations[markerId] = marker;
                _markerCache[markerId] = marker;
              } catch (e) {
                print('Error creating account marker: $e');
              }
            }
          } catch (e) {
            print('❌ Error adding account marker: $e');
          }
        }
      }
    }

    // Add places - prioritize single-select filtered places over multi-select nearby places (with limit)
    if (_showPlaces) {
      if (_filteredPlaces.isNotEmpty) {
        // Filter single-select filtered places using categoryMap
        final placesToShow = _selectedSinglePlaceType != null
            ? _filteredPlaces
                  .where((place) {
                    final placeTypes = _getShopTypes(place);
                    return _matchesCategory(
                      placeTypes,
                      _selectedSinglePlaceType!,
                    );
                  })
                  .take(MAX_MARKERS ~/ 2)
                  .toList()
            : _filteredPlaces.take(MAX_MARKERS ~/ 2).toList();

        for (int i = 0; i < placesToShow.length; i++) {
          final place = placesToShow[i];
          if (place['latitude'] != null && place['longitude'] != null) {
            final markerId = place['place_id'] ?? 'filtered_place_$i';
            if (!_markerCache.containsKey(markerId)) {
              try {
                final options = PointAnnotationOptions(
                  geometry: Point(coordinates: Position(
                    place['longitude'].toDouble(),
                    place['latitude'].toDouble(),
                  )),
                  textField: '${place['name'] ?? 'Unknown Place'}\n${place['vicinity'] ?? ''}',
                  textOffset: [0.0, -2.0],
                  textSize: 11.0,
                  iconSize: 1.0,
                );
                final marker = await _pointAnnotationManager!.create(options);
                _markerAnnotations[markerId] = marker;
                _markerCache[markerId] = marker;
              } catch (e) {
                print('Error creating filtered place marker: $e');
              }
            }
          }
        }
      } else {
        // Add regular nearby places (multi-select) with limit
        final placesToShow = nearbyPlaces.take(MAX_MARKERS ~/ 2).toList();
        for (int i = 0; i < placesToShow.length; i++) {
          final place = placesToShow[i];
          if (place.latitude != null && place.longitude != null) {
            final markerId = 'place_$i';
            if (!_markerCache.containsKey(markerId)) {
              try {
                final options = PointAnnotationOptions(
                  geometry: Point(coordinates: Position(place.longitude!, place.latitude!)),
                  textField: place.name,
                  textOffset: [0.0, -2.0],
                  textSize: 11.0,
                  iconSize: 1.0,
                );
                final marker = await _pointAnnotationManager!.create(options);
                _markerAnnotations[markerId] = marker;
                _markerCache[markerId] = marker;
              } catch (e) {
                print('Error creating place marker: $e');
              }
            }
          }
        }
      }
    }
  }

  bool _isValidCoordinate(double lat, double lng) =>
      !(lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180 ||
          (lat == 0 && lng == 0) ||
          (lat.abs() < 0.0001 && lng.abs() < 0.0001));

  List<Map<String, dynamic>> _getFilteredAccounts() {
    return salesmanAccounts.where((account) {
      // Custom date range filter
      if (selectedFromDate != null || selectedToDate != null) {
        final createdAt = account['createdAt'];
        if (createdAt != null) {
          try {
            final accountDate = DateTime.parse(createdAt.toString());

            // Check from date
            if (selectedFromDate != null) {
              final fromDate = DateTime(
                selectedFromDate!.year,
                selectedFromDate!.month,
                selectedFromDate!.day,
              );
              if (accountDate.isBefore(fromDate)) return false;
            }

            // Check to date
            if (selectedToDate != null) {
              final toDate = DateTime(
                selectedToDate!.year,
                selectedToDate!.month,
                selectedToDate!.day,
                23,
                59,
                59, // End of day
              );
              if (accountDate.isAfter(toDate)) return false;
            }
          } catch (e) {
            // If date parsing fails, include the account
          }
        } else {
          // If no createdAt date and filter is active, exclude account
          return false;
        }
      }

      if (selectedCustomerStages.isNotEmpty &&
          !selectedCustomerStages.contains(account['customerStage']))
        return false;
      if (selectedBusinessTypes.isNotEmpty &&
          !selectedBusinessTypes.contains(account['businessType']))
        return false;
      if (selectedFunnelStages.isNotEmpty &&
          !selectedFunnelStages.contains(account['funnelStage']))
        return false;
      if (selectedPincodes.isNotEmpty &&
          !selectedPincodes.contains(account['pincode']))
        return false;
      if (selectedApprovalStatus != null &&
          account['isApproved'] != selectedApprovalStatus)
        return false;
      return true;
    }).toList();
  }

  Future<void> _showPlaceDetails(PlaceInfo place) async {
    try {
      final details = await GooglePlacesService.fetchPlaceDetails(
        place.placeId,
      );
      if (details != null)
        setState(() {
          _selectedPlace = PlaceInfo.fromRawPlaceDetails(details);
          _showPlaceDetailsOverlay = true;
        });
    } catch (e) {}
  }

  void _showFilteredPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.purple,
                  child: Icon(
                    _getCategoryIcon(_selectedSinglePlaceType),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'] ?? 'Unknown Place',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedSinglePlaceType != null)
                        Text(
                          _formatBusinessType(_selectedSinglePlaceType!),
                          style: const TextStyle(color: Colors.purple),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (place['vicinity'] != null)
              _buildDetailRow(Icons.location_on, 'Address', place['vicinity']),
            if (place['rating'] != null)
              _buildDetailRow(Icons.star, 'Rating', '${place['rating']} ⭐'),
            if (place['business_status'] != null)
              _buildDetailRow(
                Icons.business,
                'Status',
                place['business_status'],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  if (_mapboxMap != null && _isMapReady && _mapboxService.map != null) {
                    await _safeAnimateCamera(
                      Point(coordinates: Position(
                        place['longitude'].toDouble(),
                        place['latitude'].toDouble(),
                      )),
                      16.0,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.my_location),
                label: const Text('Focus on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDetails(Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: account['isApproved'] == true
                      ? Colors.green
                      : Colors.orange,
                  child: Icon(
                    account['isApproved'] == true
                        ? Icons.check_circle
                        : Icons.pending,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['personName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (account['salesmanName'] != null)
                        Text(
                          'SR: ${account['salesmanName']}',
                          style: TextStyle(color: primaryColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (account['businessName'] != null)
              _buildDetailRow(
                Icons.business,
                'Business',
                account['businessName'],
              ),
            _buildDetailRow(
              Icons.phone,
              'Contact',
              account['contactNumber'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.pin_drop,
              'Pincode',
              account['pincode'] ?? 'N/A',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canFocusOnAccount(account)
                    ? () {
                        Navigator.pop(context);
                        _focusOnAccount(account);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.my_location),
                label: Text(
                  _canFocusOnAccount(account) ? 'Focus on Map' : 'No GPS',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Text('$label: $value'),
      ],
    ),
  );

  bool _canFocusOnAccount(Map<String, dynamic> account) {
    if (account['latitude'] == null || account['longitude'] == null)
      return false;
    try {
      return _isValidCoordinate(
        double.parse(account['latitude'].toString()),
        double.parse(account['longitude'].toString()),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> _focusOnAccount(Map<String, dynamic> account) async {
    if (!mounted || account['latitude'] == null || account['longitude'] == null)
      return;
    try {
      final lat = double.parse(account['latitude'].toString());
      final lng = double.parse(account['longitude'].toString());
      if (_isValidCoordinate(lat, lng))
        await _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );
    } catch (e) {}
  }

  Future<void> _focusOnAccountsArea() async {
    if (!mounted || !_isMapReady || _mapController == null) return;
    final accountsWithLocation = salesmanAccounts
        .where((a) => a['latitude'] != null && a['longitude'] != null)
        .toList();
    if (accountsWithLocation.isEmpty) return;
    try {
      double minLat = double.infinity,
          maxLat = -double.infinity,
          minLng = double.infinity,
          maxLng = -double.infinity;
      for (var account in accountsWithLocation) {
        final lat = double.parse(account['latitude'].toString());
        final lng = double.parse(account['longitude'].toString());
        if (_isValidCoordinate(lat, lng)) {
          minLat = lat < minLat ? lat : minLat;
          maxLat = lat > maxLat ? lat : maxLat;
          minLng = lng < minLng ? lng : minLng;
          maxLng = lng > maxLng ? lng : maxLng;
        }
      }
      if (minLat != double.infinity && _mapboxService.map != null) {
        await _mapboxService.fitBounds(
          bounds: CoordinateBounds(
            southwest: Point(coordinates: Position(minLng - 0.01, minLat - 0.01)),
            northeast: Point(coordinates: Position(maxLng + 0.01, maxLat + 0.01)),
            infiniteBounds: false,
          ),
          padding: 100.0,
        );
      }
    } catch (e) {}
  }

  bool _isMapInValidState() =>
      mounted && _isMapReady && _mapboxMap != null && _mapboxService.map != null;

  Future<bool> _safeAnimateCamera(Point center, double zoom) async {
    if (!_isMapInValidState()) return false;
    try {
      await _mapboxService.animateCamera(center: center, zoom: zoom);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showError(String message) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCustomerStages.clear();
      selectedBusinessTypes.clear();
      selectedFunnelStages.clear();
      selectedPincodes.clear();
      selectedApprovalStatus = null;
      selectedFromDate = null;
      selectedToDate = null;
      tempSelectedCustomerStages.clear();
      tempSelectedBusinessTypes.clear();
      tempSelectedFunnelStages.clear();
      tempSelectedPincodes.clear();
      tempSelectedApprovalStatus = null;
      tempSelectedFromDate = null;
      tempSelectedToDate = null;
    });
    Future.microtask(() => _updateMapMarkers());
  }

  void _applyFilters() {
    setState(() {
      selectedCustomerStages = List.from(tempSelectedCustomerStages);
      selectedBusinessTypes = List.from(tempSelectedBusinessTypes);
      selectedFunnelStages = List.from(tempSelectedFunnelStages);
      selectedPincodes = List.from(tempSelectedPincodes);
      selectedApprovalStatus = tempSelectedApprovalStatus;
      selectedFromDate = tempSelectedFromDate;
      selectedToDate = tempSelectedToDate;
    });
    Future.microtask(() => _updateMapMarkers());
  }

  bool get _hasFilterChanges =>
      selectedCustomerStages.length != tempSelectedCustomerStages.length ||
      selectedBusinessTypes.length != tempSelectedBusinessTypes.length ||
      selectedFunnelStages.length != tempSelectedFunnelStages.length ||
      selectedPincodes.length != tempSelectedPincodes.length ||
      selectedApprovalStatus != tempSelectedApprovalStatus ||
      selectedFromDate != tempSelectedFromDate ||
      selectedToDate != tempSelectedToDate;
  void _resetTempFilters() {
    setState(() {
      tempSelectedCustomerStages = List.from(selectedCustomerStages);
      tempSelectedBusinessTypes = List.from(selectedBusinessTypes);
      tempSelectedFunnelStages = List.from(selectedFunnelStages);
      tempSelectedPincodes = List.from(selectedPincodes);
      tempSelectedApprovalStatus = selectedApprovalStatus;
      tempSelectedFromDate = selectedFromDate;
      tempSelectedToDate = selectedToDate;
    });
  }

  bool _hasActiveFilters() =>
      selectedCustomerStages.isNotEmpty ||
      selectedBusinessTypes.isNotEmpty ||
      selectedFunnelStages.isNotEmpty ||
      selectedPincodes.isNotEmpty ||
      selectedApprovalStatus != null ||
      selectedFromDate != null ||
      selectedToDate != null;

  void _onPincodeSelected(String pincode, Map<String, dynamic> pincodeData) {
    print('🎯 Pincode selected: $pincode');
    print('📊 Current selected pincodes: $_selectedPincodes');

    setState(() {
      if (_selectedPincodes.contains(pincode)) {
        _selectedPincodes.remove(pincode);
        print('➖ Removed pincode: $pincode');
      } else {
        _selectedPincodes.add(pincode);
        print('➕ Added pincode: $pincode');
      }
    });

      print('📊 Updated selected pincodes: $_selectedPincodes');

    if (_selectedPincodes.isNotEmpty) {
      print('🔄 Loading all shops for selected pincodes...');
      _loadAllShopsForSelectedPincodes();
    } else {
      print('🔄 No pincodes selected, updating markers normally...');
      await _updateMapMarkers();
    }
  }

  Future<void> _loadAllShopsForSelectedPincodes() async {
    print('🔍 Loading all shops for pincodes: $_selectedPincodes');
    setState(() => _isLoadingGooglePlaces = true);

    try {
      // First, focus on salesman accounts for selected pincodes
      await _focusOnSelectedPincodes();

      // Then load Google Places shops for each selected pincode
      List<Map<String, dynamic>> allGoogleShops = [];

      for (String pincode in _selectedPincodes) {
        print('🔎 Loading Google Places shops for pincode: $pincode');

        // Get pincode data for geocoding
        final pincodeData = _assignedPincodes.firstWhere(
          (p) => p['pincode'] == pincode,
          orElse: () => {'pincode': pincode, 'city': ''},
        );

        final googleShops = await _loadGooglePlacesForPincode(
          pincode,
          pincodeData['city'] ?? '',
        );
        allGoogleShops.addAll(googleShops);
      }

      setState(() {
        _googlePlacesShops = allGoogleShops;
      });

      print('✅ Loaded ${allGoogleShops.length} Google Places shops');
      print('📊 Sample Google Places data: ${allGoogleShops.take(2).toList()}');

      // Update markers to show both types
      await _updateMapMarkersWithAllShops();
    } catch (e) {
      print('❌ Error loading all shops: $e');
      _showError('Failed to load shops from Google Places');
    } finally {
      setState(() => _isLoadingGooglePlaces = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadGooglePlacesForPincode(
    String pincode,
    String city,
  ) async {
    try {
      print('🔎 Loading shops from backend API for pincode: $pincode');
      print('🔍 Selected place types: $_selectedPlaceTypes');

      // Use the selected place types from the filter instead of hardcoded list
      final result = await ShopService.getShopsByPincode(
        pincode,
        businessTypes: _selectedPlaceTypes,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final googlePlacesShops =
            data['googlePlacesShops']?['shops'] as List? ?? [];

        print(
          '✅ Loaded ${googlePlacesShops.length} Google Places shops from backend',
        );

        // Log sample backend data structure
        if (googlePlacesShops.isNotEmpty) {
          print('🔍 === SAMPLE BACKEND DATA ===');
          for (
            int i = 0;
            i < (googlePlacesShops.length > 2 ? 2 : googlePlacesShops.length);
            i++
          ) {
            final shop = googlePlacesShops[i];
            print('Backend Shop ${i + 1}:');
            print('  Name: ${shop['name']}');
            print('  Business Type: ${shop['businessType']}');
            print(
              '  Types: ${shop['types']}',
            ); // Check if backend provides types[]
            print('  Place ID: ${shop['placeId']}');
            print('  Address: ${shop['address']}');
            print('  ---');
          }
          print('🔍 === END BACKEND DATA ===');
        }

        // Convert to our expected format and validate data
        List<Map<String, dynamic>> validShops = [];

        for (var shop in googlePlacesShops) {
          try {
            // Validate required fields
            if (shop['latitude'] != null &&
                shop['longitude'] != null &&
                shop['name'] != null &&
                shop['placeId'] != null) {
              // Store types[] as List<String> for proper category matching
              List<String> placeTypes = [];
              if (shop['types'] != null && shop['types'] is List) {
                placeTypes = List<String>.from(
                  (shop['types'] as List).map(
                    (t) => t.toString().toLowerCase(),
                  ),
                );
              } else if (shop['businessType'] != null) {
                // Fallback: use businessType as single type
                placeTypes = [shop['businessType'].toString().toLowerCase()];
              }

              validShops.add({
                'id': shop['id'] ?? 'google_${shop['placeId']}',
                'placeId': shop['placeId'],
                'name': shop['name'] ?? 'Unknown Shop',
                'businessType': shop['businessType'] ?? 'store',
                'types': placeTypes, // Store as List<String>
                'address': shop['address'] ?? '',
                'pincode': pincode,
                'latitude': _parseDouble(shop['latitude']),
                'longitude': _parseDouble(shop['longitude']),
                'rating': _parseDouble(shop['rating']),
                'isGooglePlace': true,
                'isApproved': null,
                'salesmanName': null,
              });
            } else {
              print(
                '⚠️ Skipping invalid shop: ${shop['name']} - missing required fields',
              );
            }
          } catch (e) {
            print('❌ Error processing shop ${shop['name']}: $e');
          }
        }

        print('✅ Processed ${validShops.length} valid Google Places shops');

        // Debug: Log unique types to understand the data
        final allTypes = validShops
            .expand((shop) => (shop['types'] as List<String>?) ?? [])
            .toSet()
            .toList();
        print('🔍 Unique types found: $allTypes');

        return validShops;
      } else {
        print('❌ Backend API failed: ${result['message'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading shops from backend: $e');
      return [];
    }
  }

  Future<void> _updateMapMarkersWithAllShops() async {
    if (_pointAnnotationManager == null) return;
    
    print('=== _updateMapMarkersWithAllShops called ===');
    print('Google Places shops count: ${_googlePlacesShops.length}');
    print(
      'Salesman accounts count: ${_getFilteredAccountsForSelectedPincodes().length}',
    );
    print('Show Accounts: $_showAccounts, Show Places: $_showPlaces');

    // Clear existing markers
    for (var marker in _markerAnnotations.values) {
      try {
        await _pointAnnotationManager!.delete(marker);
      } catch (e) {
        print('Error deleting marker: $e');
      }
    }
    _markerAnnotations.clear();
    _markerCache.clear();

    // Add current location marker
    if (_currentPosition != null) {
      try {
        final options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          textField: '📍 My Location',
          textOffset: [0.0, -2.0],
          textSize: 12.0,
          iconSize: 1.2,
        );
        final marker = await _pointAnnotationManager!.create(options);
        _markerAnnotations['current_location'] = marker;
      } catch (e) {
        print('Error creating current location marker: $e');
      }
    }

    // Add salesman-created accounts (existing shops) - only if _showAccounts is true
    if (_showAccounts) {
      final filteredAccounts = _getFilteredAccountsForSelectedPincodes();
      print('Adding ${filteredAccounts.length} salesman account markers');

      for (var account in filteredAccounts) {
        if (account['latitude'] != null && account['longitude'] != null) {
          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());
            if (!_isValidCoordinate(lat, lng)) continue;

            try {
              final markerId = 'salesman_account_${account['id']}';
              final options = PointAnnotationOptions(
                geometry: Point(coordinates: Position(lng, lat)),
                textField: '${account['personName'] ?? 'Unknown'}\n${account['businessName'] ?? ''} - SR: ${account['salesmanName'] ?? ''} - EXISTING',
                textOffset: [0.0, -2.0],
                textSize: 11.0,
                iconSize: account['isApproved'] == true ? 1.2 : 1.0,
              );
              final marker = await _pointAnnotationManager!.create(options);
              _markerAnnotations[markerId] = marker;
            } catch (e) {
              print('Error adding salesman account marker: $e');
            }
          } catch (e) {
            print('Error processing account: $e');
          }
        }
      }
    } else {
      print('Accounts toggle is OFF - skipping salesman account markers');
    }

    // Add Google Places shops (new potential shops) - only if Places toggle is ON
    if (_showPlaces) {
      print(
        'Processing ${_googlePlacesShops.length} Google Places shops for markers',
      );
      print('Filtering by place types: $_selectedPlaceTypes');

      // Filter Google Places shops using categoryMap for proper types[] matching
      final filteredGoogleShops = _googlePlacesShops.where((shop) {
        // If no category selected, show all
        if (_selectedPlaceTypes.isEmpty) return true;

        // Get shop's types[] list
        final shopTypes = _getShopTypes(shop);
        if (shopTypes.isEmpty) return false;

        // Check if shop matches ANY selected category using categoryMap
        return _selectedPlaceTypes.any((selectedCategory) {
          return _matchesCategory(shopTypes, selectedCategory);
        });
      }).toList();

      print(
        'Filtered to ${filteredGoogleShops.length} shops using categoryMap',
      );

      int googleMarkersAdded = 0;

      for (var shop in filteredGoogleShops) {
        if (shop['latitude'] != null && shop['longitude'] != null) {
          try {
            final lat = _parseDouble(shop['latitude']);
            final lng = _parseDouble(shop['longitude']);

            if (lat == null || lng == null || !_isValidCoordinate(lat, lng))
              continue;

            try {
              final markerId = 'google_shop_${shop['id']}';
              final options = PointAnnotationOptions(
                geometry: Point(coordinates: Position(lng, lat)),
                textField: '${shop['name'] ?? 'Unknown Shop'}\n${_formatBusinessType(shop['businessType'])}',
                textOffset: [0.0, -2.0],
                textSize: 11.0,
                iconSize: 1.0,
              );
              final marker = await _pointAnnotationManager!.create(options);
              _markerAnnotations[markerId] = marker;
              googleMarkersAdded++;
            } catch (e) {
              print(
                '❌ Error adding Google Places marker for ${shop['name']}: $e',
              );
            }
          } catch (e) {
            print('Error processing shop: $e');
          }
        }
      }

      print(
        '🟣 Added $googleMarkersAdded Google Places markers out of ${filteredGoogleShops.length} filtered shops (${_googlePlacesShops.length} total)',
      );

      // Add regular nearby places
      for (int i = 0; i < nearbyPlaces.length; i++) {
        final place = nearbyPlaces[i];
        if (place.latitude != null && place.longitude != null) {
          try {
            final markerId = 'nearby_place_$i';
            final options = PointAnnotationOptions(
              geometry: Point(coordinates: Position(place.longitude!, place.latitude!)),
              textField: '${place.name}\nNEARBY PLACE',
              textOffset: [0.0, -2.0],
              textSize: 11.0,
              iconSize: 1.0,
            );
            final marker = await _pointAnnotationManager!.create(options);
            _markerAnnotations[markerId] = marker;
          } catch (e) {
            print('Error creating nearby place marker: $e');
          }
        }
      }
    } else {
      print(
        'Places toggle is OFF - skipping ALL place markers (Google Places + Nearby)',
      );
    }

    print('=== Updated map with ${_markerAnnotations.length} total markers ===');
  }

  /// Get shop types as List<String> from shop data
  List<String> _getShopTypes(Map<String, dynamic> shop) {
    // First try to get types[] list
    if (shop['types'] != null && shop['types'] is List) {
      return List<String>.from(
        (shop['types'] as List).map((t) => t.toString().toLowerCase()),
      );
    }
    // Fallback to businessType as single type
    if (shop['businessType'] != null) {
      return [shop['businessType'].toString().toLowerCase()];
    }
    return [];
  }

  /// Check if shop types match the selected category using categoryMap
  /// Returns true if ANY shop type is in the category's mapped types
  bool _matchesCategory(List<String> shopTypes, String selectedCategory) {
    final category = selectedCategory.toLowerCase();

    // Get mapped types for this category
    final mappedTypes = categoryMap[category];

    if (mappedTypes == null || mappedTypes.isEmpty) {
      // No mapping found - do direct match
      print('🔍 No mapping for category "$category", doing direct match');
      return shopTypes.contains(category);
    }

    // Check if ANY shop type matches ANY mapped type
    final matches = shopTypes.any((shopType) => mappedTypes.contains(shopType));

    print('🔍 Category match check:');
    print('  Category: $category');
    print('  Shop types: $shopTypes');
    print('  Mapped types: $mappedTypes');
    print('  Matches: $matches');

    return matches;
  }

  /// Get count of shops matching selected categories (for legend/stats)
  int _getFilteredShopCount() {
    if (_selectedPlaceTypes.isEmpty) return _googlePlacesShops.length;

    return _googlePlacesShops.where((shop) {
      final shopTypes = _getShopTypes(shop);
      if (shopTypes.isEmpty) return false;
      return _selectedPlaceTypes.any((cat) => _matchesCategory(shopTypes, cat));
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredAccountsForSelectedPincodes() {
    if (_selectedPincodes.isEmpty) return [];

    return salesmanAccounts.where((account) {
      final accountPincode = account['pincode']?.toString();
      if (accountPincode == null ||
          !_selectedPincodes.contains(accountPincode)) {
        return false;
      }

      // Apply date range filter
      if (selectedFromDate != null || selectedToDate != null) {
        final createdAt = account['createdAt'];
        if (createdAt != null) {
          try {
            final accountDate = DateTime.parse(createdAt.toString());

            // Check from date
            if (selectedFromDate != null) {
              final fromDate = DateTime(
                selectedFromDate!.year,
                selectedFromDate!.month,
                selectedFromDate!.day,
              );
              if (accountDate.isBefore(fromDate)) return false;
            }

            // Check to date
            if (selectedToDate != null) {
              final toDate = DateTime(
                selectedToDate!.year,
                selectedToDate!.month,
                selectedToDate!.day,
                23,
                59,
                59, // End of day
              );
              if (accountDate.isAfter(toDate)) return false;
            }
          } catch (e) {
            // If date parsing fails, include the account
          }
        } else {
          // If no createdAt date and filter is active, exclude account
          return false;
        }
      }

      // Apply other filters
      if (selectedCustomerStages.isNotEmpty &&
          !selectedCustomerStages.contains(account['customerStage']))
        return false;
      if (selectedBusinessTypes.isNotEmpty &&
          !selectedBusinessTypes.contains(account['businessType']))
        return false;
      if (selectedFunnelStages.isNotEmpty &&
          !selectedFunnelStages.contains(account['funnelStage']))
        return false;
      if (selectedApprovalStatus != null &&
          account['isApproved'] != selectedApprovalStatus)
        return false;

      return true;
    }).toList();
  }

  void _showGooglePlaceDetails(Map<String, dynamic> shop) async {
    // Show loading modal first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch full details if we have a placeId
    Map<String, dynamic> fullDetails = Map.from(shop);
    if (shop['placeId'] != null) {
      try {
        final details = await GooglePlacesService.fetchPlaceDetails(
          shop['placeId'],
        );
        if (details != null) {
          fullDetails = {
            ...shop,
            'reviews': details['reviews'],
            'photos': details['photos'],
            'phoneNumber': details['formatted_phone_number'],
            'website': details['website'],
            'openNow': details['opening_hours']?['open_now'],
            'userRatingsTotal': details['user_ratings_total'],
          };
        }
      } catch (e) {
        print('Error fetching place details: $e');
      }
    }

    // Close loading dialog
    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    // Show the details modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(fullDetails['businessType']),
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullDetails['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatBusinessType(fullDetails['businessType']),
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Rating row
            if (fullDetails['rating'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${(fullDetails['rating'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fullDetails['userRatingsTotal'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${fullDetails['userRatingsTotal']} reviews)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    const Spacer(),
                    if (fullDetails['openNow'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: fullDetails['openNow'] == true
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fullDetails['openNow'] == true ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address
                    if (fullDetails['address'] != null)
                      _buildInfoCard(
                        Icons.location_on,
                        'Address',
                        fullDetails['address'],
                        Colors.blue,
                      ),
                    // Phone
                    if (fullDetails['phoneNumber'] != null)
                      _buildInfoCard(
                        Icons.phone,
                        'Phone',
                        fullDetails['phoneNumber'],
                        Colors.green,
                      ),
                    // Photos Section
                    if (fullDetails['photos'] != null &&
                        (fullDetails['photos'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Photos (${(fullDetails['photos'] as List).length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (fullDetails['photos'] as List).length,
                          itemBuilder: (context, index) {
                            final photo =
                                (fullDetails['photos'] as List)[index];
                            final photoRef = photo is Map
                                ? (photo['photoReference'] ??
                                      photo['photo_reference'])
                                : photo.toString();
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: photoRef != null
                                    ? Image.network(
                                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${GooglePlacesConfig.apiKey}',
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    // Reviews Section
                    if (fullDetails['reviews'] != null &&
                        (fullDetails['reviews'] as List).isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.reviews, size: 20, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Reviews (${(fullDetails['reviews'] as List).length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(fullDetails['reviews'] as List)
                          .take(5)
                          .map((review) => _buildReviewCard(review)),
                    ],
                    // No photos/reviews message
                    if ((fullDetails['photos'] == null ||
                            (fullDetails['photos'] as List).isEmpty) &&
                        (fullDetails['reviews'] == null ||
                            (fullDetails['reviews'] as List).isEmpty))
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No photos or reviews available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final authorName =
        review['authorName'] ?? review['author_name'] ?? 'Anonymous';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final text = review['text'] ?? '';
    final time =
        review['relativeTimeDescription'] ??
        review['relative_time_description'] ??
        '';
    final photoUrl = review['profilePhotoUrl'] ?? review['profile_photo_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Text(
                        authorName[0].toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? type) {
    if (type == null) return Icons.store;
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'bank':
        return Icons.account_balance;
      case 'hospital':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'school':
        return Icons.school;
      case 'supermarket':
        return Icons.local_grocery_store;
      case 'convenience_store':
        return Icons.storefront;
      case 'grocery_or_supermarket':
        return Icons.storefront;
      case 'lodging':
      case 'hotel':
        return Icons.hotel;
      case 'gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.store;
    }
  }

  /// Format business type for display
  String _formatBusinessType(String? businessType) {
    if (businessType == null || businessType.isEmpty) return 'Business';

    // Custom mappings for better display names
    const typeDisplayNames = {
      'accounting': 'Accounting',
      'airport': 'Airport',
      'amusement_park': 'Amusement Park',
      'aquarium': 'Aquarium',
      'art_gallery': 'Art Gallery',
      'atm': 'ATM',
      'bakery': 'Bakery',
      'bank': 'Bank',
      'bar': 'Bar',
      'beauty_salon': 'Beauty Salon',
      'bicycle_store': 'Bicycle Store',
      'book_store': 'Book Store',
      'bowling_alley': 'Bowling Alley',
      'bus_station': 'Bus Station',
      'cafe': 'Cafe',
      'campground': 'Campground',
      'car_dealer': 'Car Dealer',
      'car_rental': 'Car Rental',
      'car_repair': 'Car Repair',
      'car_wash': 'Car Wash',
      'casino': 'Casino',
      'cemetery': 'Cemetery',
      'church': 'Church',
      'city_hall': 'City Hall',
      'clothing_store': 'Clothing Store',
      'convenience_store': 'Convenience Store',
      'courthouse': 'Courthouse',
      'dentist': 'Dentist',
      'department_store': 'Department Store',
      'doctor': 'Doctor',
      'drugstore': 'Drugstore',
      'electrician': 'Electrician',
      'electronics_store': 'Electronics Store',
      'embassy': 'Embassy',
      'fire_station': 'Fire Station',
      'florist': 'Florist',
      'funeral_home': 'Funeral Home',
      'furniture_store': 'Furniture Store',
      'gas_station': 'Gas Station',
      'grocery_or_supermarket': 'Grocery Store',
      'gym': 'Gym',
      'hair_care': 'Hair Care',
      'hardware_store': 'Hardware Store',
      'hindu_temple': 'Hindu Temple',
      'home_goods_store': 'Home Goods Store',
      'hospital': 'Hospital',
      'insurance_agency': 'Insurance Agency',
      'jewelry_store': 'Jewelry Store',
      'laundry': 'Laundry',
      'lawyer': 'Lawyer',
      'library': 'Library',
      'light_rail_station': 'Light Rail Station',
      'liquor_store': 'Liquor Store',
      'local_government_office': 'Government Office',
      'locksmith': 'Locksmith',
      'lodging': 'Hotel',
      'meal_delivery': 'Meal Delivery',
      'meal_takeaway': 'Takeaway',
      'mosque': 'Mosque',
      'movie_rental': 'Movie Rental',
      'movie_theater': 'Movie Theater',
      'moving_company': 'Moving Company',
      'museum': 'Museum',
      'night_club': 'Night Club',
      'painter': 'Painter',
      'park': 'Park',
      'parking': 'Parking',
      'pet_store': 'Pet Store',
      'pharmacy': 'Pharmacy',
      'physiotherapist': 'Physiotherapist',
      'plumber': 'Plumber',
      'police': 'Police',
      'post_office': 'Post Office',
      'primary_school': 'Primary School',
      'real_estate_agency': 'Real Estate Agency',
      'restaurant': 'Restaurant',
      'roofing_contractor': 'Roofing Contractor',
      'rv_park': 'RV Park',
      'school': 'School',
      'secondary_school': 'Secondary School',
      'shoe_store': 'Shoe Store',
      'shopping_mall': 'Shopping Mall',
      'spa': 'Spa',
      'stadium': 'Stadium',
      'storage': 'Storage',
      'store': 'Store',
      'subway_station': 'Subway Station',
      'supermarket': 'Supermarket',
      'synagogue': 'Synagogue',
      'taxi_stand': 'Taxi Stand',
      'tourist_attraction': 'Tourist Attraction',
      'train_station': 'Train Station',
      'transit_station': 'Transit Station',
      'travel_agency': 'Travel Agency',
      'university': 'University',
      'veterinary_care': 'Veterinary Care',
      'zoo': 'Zoo',
      // Additional common types
      'food': 'Food & Dining',
      'health': 'Health & Medical',
      'finance': 'Financial Services',
      'establishment': 'Business',
    };

    final lowerType = businessType.toLowerCase();
    return typeDisplayNames[lowerType] ??
        businessType
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
  }

  // Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to format dates
  String _formatDate(dynamic dateValue) {
    try {
      final date = DateTime.parse(dateValue.toString());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final accountDate = DateTime(date.year, date.month, date.day);

      if (accountDate == today) {
        return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (accountDate == yesterday) {
        return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Helper method to format date range for display
  String _formatDateRange() {
    if (selectedFromDate == null && selectedToDate == null) {
      return 'All Time';
    } else if (selectedFromDate != null && selectedToDate != null) {
      return '${_formatDateOnly(selectedFromDate!)} - ${_formatDateOnly(selectedToDate!)}';
    } else if (selectedFromDate != null) {
      return 'From ${_formatDateOnly(selectedFromDate!)}';
    } else {
      return 'Until ${_formatDateOnly(selectedToDate!)}';
    }
  }

  // Helper method to format date only (without time)
  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper methods to check if a date is today or yesterday
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate == today;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate == yesterday;
  }

  Future<void> _focusOnSelectedPincodes() async {
    print('🔍 Focusing on pincodes: $_selectedPincodes');

    // Get accounts for selected pincodes with valid GPS
    final pincodeAccounts = salesmanAccounts.where((account) {
      final accountPincode = account['pincode']?.toString();
      return accountPincode != null &&
          _selectedPincodes.contains(accountPincode) &&
          account['latitude'] != null &&
          account['longitude'] != null;
    }).toList();

    print('📊 Found ${pincodeAccounts.length} accounts with GPS');
    await _updateMapMarkersForSelectedPincodes();

    // Focus on accounts if they have valid coordinates
    if (pincodeAccounts.isNotEmpty) {
      double minLat = double.infinity,
          maxLat = -double.infinity,
          minLng = double.infinity,
          maxLng = -double.infinity;
      int validCount = 0;

      for (var account in pincodeAccounts) {
        try {
          final lat = double.parse(account['latitude'].toString());
          final lng = double.parse(account['longitude'].toString());
          if (_isValidCoordinate(lat, lng)) {
            minLat = lat < minLat ? lat : minLat;
            maxLat = lat > maxLat ? lat : maxLat;
            minLng = lng < minLng ? lng : minLng;
            maxLng = lng > maxLng ? lng : maxLng;
            validCount++;
          }
        } catch (e) {}
      }

      if (validCount > 0) {
        print('✅ Focusing on $validCount accounts');
        if (validCount == 1) {
          await _safeAnimateCamera(
            Point(coordinates: Position(minLng, minLat)),
            15.0,
          );
        } else {
          if (_mapboxService.map != null) {
            await _mapboxService.fitBounds(
              bounds: CoordinateBounds(
                southwest: Point(coordinates: Position(minLng - 0.01, minLat - 0.01)),
                northeast: Point(coordinates: Position(maxLng + 0.01, maxLat + 0.01)),
                infiniteBounds: false,
              ),
              padding: 100.0,
            );
          }
        }
        return;
      }
    }

    // No accounts with GPS - geocode the pincode
    if (_selectedPincodes.isNotEmpty) {
      print('📍 No GPS accounts, geocoding pincode...');
      final firstPincode = _selectedPincodes.first;
      final pincodeData = _assignedPincodes.firstWhere(
        (p) => p['pincode'] == firstPincode,
        orElse: () => {'pincode': firstPincode, 'city': ''},
      );
      await _geocodeAndFocusPincode(firstPincode, pincodeData['city'] ?? '');
    }
  }

  Future<void> _geocodeAndFocusPincode(String pincode, String city) async {
    try {
      final searchQuery = city.isNotEmpty
          ? '$pincode, $city, India'
          : '$pincode, India';
      print('🔍 Geocoding: $searchQuery');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(searchQuery)}&key=${GooglePlacesConfig.apiKey}',
      );
      final response = await http.get(url);
      print('📊 Geocoding response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Geocoding data: ${data['status']}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final lat = (location['lat'] as num).toDouble();
          final lng = (location['lng'] as num).toDouble();
          print('📍 Geocoded: ($lat, $lng)');

          final success = await _safeAnimateCamera(
            Point(coordinates: Position(lng, lat)),
            13.0,
          );
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📍 Focused on $pincode${city.isNotEmpty ? " - $city" : ""}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print(
            '❌ Geocoding failed: ${data['status']} - ${data['error_message'] ?? ''}',
          );
          _showError('Could not find location for $pincode');
        }
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      _showError('Error finding location');
    }
  }

  Future<void> _updateMapMarkersForSelectedPincodes() async {
    if (_pointAnnotationManager == null) return;
    
    // Clear existing markers
    for (var marker in _markerAnnotations.values) {
      try {
        await _pointAnnotationManager!.delete(marker);
      } catch (e) {
        print('Error deleting marker: $e');
      }
    }
    _markerAnnotations.clear();
    _markerCache.clear();
    
    // Add current location marker
    if (_currentPosition != null) {
      try {
        final options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          textField: '📍 My Location',
          textOffset: [0.0, -2.0],
          textSize: 12.0,
          iconSize: 1.2,
        );
        final marker = await _pointAnnotationManager!.create(options);
        _markerAnnotations['current_location'] = marker;
      } catch (e) {
        print('Error creating current location marker: $e');
      }
    }

    // Only add account markers if _showAccounts is true
    if (_showAccounts) {
      for (var account in salesmanAccounts) {
        final accountPincode = account['pincode']?.toString();
        if (accountPincode != null &&
            _selectedPincodes.contains(accountPincode) &&
            account['latitude'] != null &&
            account['longitude'] != null) {
          // Apply date filter
          if (selectedFromDate != null || selectedToDate != null) {
            final createdAt = account['createdAt'];
            if (createdAt != null) {
              try {
                final accountDate = DateTime.parse(createdAt.toString());
                if (selectedFromDate != null) {
                  final fromDate = DateTime(
                    selectedFromDate!.year,
                    selectedFromDate!.month,
                    selectedFromDate!.day,
                  );
                  if (accountDate.isBefore(fromDate)) continue;
                }
                if (selectedToDate != null) {
                  final toDate = DateTime(
                    selectedToDate!.year,
                    selectedToDate!.month,
                    selectedToDate!.day,
                    23,
                    59,
                    59,
                  );
                  if (accountDate.isAfter(toDate)) continue;
                }
              } catch (e) {
                // Continue if date parsing fails
              }
            } else {
              continue; // Skip if no date and filter is active
            }
          }

          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());
            if (_isValidCoordinate(lat, lng)) {
              try {
                final markerId = 'account_${account['id']}';
                final options = PointAnnotationOptions(
                  geometry: Point(coordinates: Position(lng, lat)),
                  textField: '${account['personName'] ?? 'Unknown'}\n${account['businessName'] ?? ''}',
                  textOffset: [0.0, -2.0],
                  textSize: 11.0,
                  iconSize: account['isApproved'] == true ? 1.2 : 1.0,
                );
                final marker = await _pointAnnotationManager!.create(options);
                _markerAnnotations[markerId] = marker;
              } catch (e) {
                print('Error creating account marker: $e');
              }
            }
          } catch (e) {
            print('Error processing account: $e');
          }
        }
      }
    }
  }

  void _selectAllPincodes() {
    setState(
      () => _selectedPincodes = _assignedPincodes
          .map((p) => p['pincode']?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .toList(),
    );
    _loadAllShopsForSelectedPincodes();
  }

  void _clearPincodeSelection() {
    setState(() {
      _selectedPincodes.clear();
      _googlePlacesShops.clear();
    });
    await _updateMapMarkers();
  }

  // Quick date filter methods
  void _setTodayFilter() {
    final today = DateTime.now();
    setState(() {
      tempSelectedFromDate = DateTime(today.year, today.month, today.day);
      tempSelectedToDate = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      );
    });
  }

  void _setYesterdayFilter() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      tempSelectedFromDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      tempSelectedToDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );
    });
  }

  void _clearDateFilter() {
    setState(() {
      tempSelectedFromDate = null;
      tempSelectedToDate = null;
    });
  }

  // Date picker methods
  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tempSelectedFromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        tempSelectedFromDate = picked;
        // If to date is before from date, clear it
        if (tempSelectedToDate != null &&
            tempSelectedToDate!.isBefore(picked)) {
          tempSelectedToDate = null;
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tempSelectedToDate ?? DateTime.now(),
      firstDate: tempSelectedFromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        tempSelectedToDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Map View'),
        backgroundColor: primaryColor,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people),
                onPressed: _isLoadingSalesmen
                    ? null
                    : _showSalesmanSelectionDialog,
                tooltip: 'Select Salesmen',
              ),
              if (_selectedSalesmenIds.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selectedSalesmenIds.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
              _showFilters
                  ? _filterAnimationController.forward()
                  : _filterAnimationController.reverse();
            },
          ),
          IconButton(
            icon: Icon(_showAccountsList ? Icons.map : Icons.list),
            onPressed: () =>
                setState(() => _showAccountsList = !_showAccountsList),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAllSalesmen();
              if (_selectedSalesmenIds.isNotEmpty)
                _loadAccountsForSelectedSalesmen();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : _selectedSalesmenIds.isEmpty
          ? _buildNoSalesmanSelected()
          : _showAccountsList
          ? _buildAccountsList()
          : Stack(
              children: [
                _buildMapboxMap(),
                if (_showFilters)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(_filterAnimation),
                      child: _buildFiltersPanel(),
                    ),
                  ),
                Positioned(bottom: 16, left: 16, child: _buildLegendCard()),
                Positioned(bottom: 16, left: 160, child: _buildPincodeCard()),
                if (_showPlaceDetailsOverlay && _selectedPlace != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: PlaceDetailsWidget(
                      place: _selectedPlace!,
                      onClose: () => setState(() {
                        _showPlaceDetailsOverlay = false;
                        _selectedPlace = null;
                      }),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _showAccountsList || _selectedSalesmenIds.isEmpty
          ? null
          : FloatingActionButton(
              mini: true,
              backgroundColor: primaryColor,
              onPressed: () async {
                if (_currentPosition != null && _isMapInValidState())
                  await _safeAnimateCamera(
                    Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
                    15.0,
                  );
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }

  Widget _buildNoSalesmanSelected() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No Salesman Selected',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the people icon to select salesmen',
          style: TextStyle(color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showSalesmanSelectionDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.people),
          label: Text('Select Salesmen (${_allSalesmen.length})'),
        ),
      ],
    ),
  );

  Widget _buildAccountsList() {
    final accounts = _getFilteredAccounts();
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedSalesmenIds.length} salesmen • ${accounts.length} accounts',
                    ),
                  ),
                  TextButton(
                    onPressed: _showSalesmanSelectionDialog,
                    child: const Text('Change'),
                  ),
                ],
              ),
              if (selectedFromDate != null || selectedToDate != null)
                Row(
                  children: [
                    Icon(Icons.date_range, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Date Range: ${_formatDateRange()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No accounts found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: account['isApproved'] == true
                              ? Colors.green
                              : Colors.orange,
                          child: Text(
                            (account['personName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          account['personName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (account['businessName'] != null)
                              Text(account['businessName']),
                            if (account['salesmanName'] != null)
                              Text(
                                'SR: ${account['salesmanName']}',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            if (account['pincode'] != null)
                              Text(
                                'Pincode: ${account['pincode']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            if (account['createdAt'] != null)
                              Text(
                                'Created: ${_formatDate(account['createdAt'])}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                        trailing: _canFocusOnAccount(account)
                            ? IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: primaryColor,
                                ),
                                onPressed: () async {
                                  // Switch to map view first
                                  setState(() => _showAccountsList = false);
                                  // Wait for map to be ready then focus
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  _focusOnAccount(account);
                                },
                              )
                            : const Text(
                                'No GPS',
                                style: TextStyle(fontSize: 10),
                              ),
                        onTap: () => _showAccountDetails(account),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Get popular place types for the filter
  // Get important place types for the filter (12 most important categories)
  List<Map<String, dynamic>> _getImportantPlaceTypes() {
    return _placeTypes.where((placeType) {
      final type = placeType['type'] as String;
      return [
        'grocery_or_supermarket',
        'restaurant',
        'cafe',
        'pharmacy',
        'bank',
        'gas_station',
        'clothing_store',
        'electronics_store',
        'bakery',
        'beauty_salon',
        'hospital',
        'school',
      ].contains(type);
    }).toList();
  }

  Widget _buildFiltersPanel() => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: primaryColor, size: 18),
              const SizedBox(width: 4),
              const Text(
                'Filters',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_googlePlacesShops.isNotEmpty)
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() => _showFilters = false);
                  _filterAnimationController.reverse();
                },
              ),
            ],
          ),
          const Divider(),

          // Toggle switches
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  title: const Text('Accounts', style: TextStyle(fontSize: 12)),
                  value: _showAccounts,
                  onChanged: (v) {
                    print('Accounts toggle changed to: $v');
                    setState(() {
                      _showAccounts = v;
                    });
                    // Force proper marker update after state change
                    Future.microtask(() {
                      if (_selectedPincodes.isNotEmpty) {
                        print('Calling _updateMapMarkersWithAllShops');
                        await _updateMapMarkersWithAllShops();
                      } else {
                        print('Calling _updateMapMarkersDefault');
                        await _updateMapMarkersDefault();
                      }
                    });
                  },
                  activeColor: primaryColor,
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  title: const Text('Places', style: TextStyle(fontSize: 12)),
                  value: _showPlaces,
                  onChanged: (v) {
                    print('Places toggle changed to: $v');
                    setState(() {
                      _showPlaces = v;
                    });
                    // Force proper marker update after state change
                    Future.microtask(() {
                      if (_selectedPincodes.isNotEmpty) {
                        print('Calling _updateMapMarkersWithAllShops');
                        await _updateMapMarkersWithAllShops();
                      } else {
                        print('Calling _updateMapMarkersDefault');
                        await _updateMapMarkersDefault();
                      }
                    });
                  },
                  activeColor: primaryColor,
                ),
              ),
            ],
          ),

          // Date Range Filter
          const SizedBox(height: 8),
          const Text(
            'Date Range Filter',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Quick date filter buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _setTodayFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (tempSelectedFromDate != null &&
                              tempSelectedToDate != null &&
                              _isToday(tempSelectedFromDate!) &&
                              _isToday(tempSelectedToDate!))
                          ? primaryColor.withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isToday(tempSelectedFromDate!) &&
                                _isToday(tempSelectedToDate!))
                            ? primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      'Today',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isToday(tempSelectedFromDate!) &&
                                _isToday(tempSelectedToDate!))
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isToday(tempSelectedFromDate!) &&
                                _isToday(tempSelectedToDate!))
                            ? primaryColor
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: _setYesterdayFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (tempSelectedFromDate != null &&
                              tempSelectedToDate != null &&
                              _isYesterday(tempSelectedFromDate!) &&
                              _isYesterday(tempSelectedToDate!))
                          ? primaryColor.withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isYesterday(tempSelectedFromDate!) &&
                                _isYesterday(tempSelectedToDate!))
                            ? primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      'Yesterday',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isYesterday(tempSelectedFromDate!) &&
                                _isYesterday(tempSelectedToDate!))
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            (tempSelectedFromDate != null &&
                                tempSelectedToDate != null &&
                                _isYesterday(tempSelectedFromDate!) &&
                                _isYesterday(tempSelectedToDate!))
                            ? primaryColor
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _clearDateFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Clear',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom date range selectors
          Row(
            children: [
              // From Date
              Expanded(
                child: InkWell(
                  onTap: () => _selectFromDate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tempSelectedFromDate != null
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tempSelectedFromDate != null
                            ? primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: tempSelectedFromDate != null
                              ? primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tempSelectedFromDate != null
                                ? _formatDateOnly(tempSelectedFromDate!)
                                : 'From Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: tempSelectedFromDate != null
                                  ? primaryColor
                                  : Colors.grey[600],
                              fontWeight: tempSelectedFromDate != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (tempSelectedFromDate != null)
                          InkWell(
                            onTap: () =>
                                setState(() => tempSelectedFromDate = null),
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // To Date
              Expanded(
                child: InkWell(
                  onTap: () => _selectToDate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tempSelectedToDate != null
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tempSelectedToDate != null
                            ? primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: tempSelectedToDate != null
                              ? primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tempSelectedToDate != null
                                ? _formatDateOnly(tempSelectedToDate!)
                                : 'To Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: tempSelectedToDate != null
                                  ? primaryColor
                                  : Colors.grey[600],
                              fontWeight: tempSelectedToDate != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (tempSelectedToDate != null)
                          InkWell(
                            onTap: () =>
                                setState(() => tempSelectedToDate = null),
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Shop Categories (horizontally scrollable in 2 rows)
          if (_showPlaces) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop Categories',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_selectedPlaceTypes.length} selected',
                  style: TextStyle(fontSize: 10, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 50, // Height for single row
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _getImportantPlaceTypes().map((placeType) {
                    final isSelected = _selectedPlaceTypes.contains(
                      placeType['type'],
                    );
                    return Container(
                      width: 70, // Fixed width for each item
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPlaceTypes.remove(placeType['type']);
                              // Ensure at least one place type is always selected
                              if (_selectedPlaceTypes.isEmpty) {
                                _selectedPlaceTypes.add(
                                  'grocery_or_supermarket',
                                );
                              }
                            } else {
                              _selectedPlaceTypes.add(placeType['type']);
                            }
                          });

                          // Reload nearby places for current location
                          _loadNearbyPlaces();

                          // If pincodes are selected, reload Google Places shops with new filter
                          if (_selectedPincodes.isNotEmpty) {
                            _loadAllShopsForSelectedPincodes();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                placeType['icon'],
                                size: 20,
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                placeType['name'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Quick select/deselect buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlaceTypes = _getImportantPlaceTypes()
                          .map((p) => p['type'] as String)
                          .toList();
                    });
                    _loadNearbyPlaces();
                    if (_selectedPincodes.isNotEmpty) {
                      _loadAllShopsForSelectedPincodes();
                    }
                  },
                  child: const Text(
                    'Select All',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlaceTypes = ['grocery_or_supermarket'];
                    });
                    _loadNearbyPlaces();
                    if (_selectedPincodes.isNotEmpty) {
                      _loadAllShopsForSelectedPincodes();
                    }
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],

          // Apply/Reset buttons at the bottom
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasFilterChanges ? _applyFilters : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasFilterChanges
                        ? primaryColor
                        : Colors.grey[300],
                  ),
                  child: Text(
                    _hasFilterChanges ? 'Apply' : 'No Changes',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_hasFilterChanges)
                TextButton(
                  onPressed: _resetTempFilters,
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildLegendCard() => Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLegendCollapsed) ...[
            _buildLegendItem('My Location', Colors.blue),
            _buildLegendItem('Approved Shops', Colors.green),
            _buildLegendItem('Pending Shops', Colors.orange),
            if (_filteredPlaces.isNotEmpty)
              _buildLegendItem('Filtered Places', Colors.purple)
            else
              _buildLegendItem('Nearby Places', Colors.red),
            _buildLegendItem('Google Places', Colors.purple),
            const SizedBox(height: 8),
          ],
          InkWell(
            onTap: () =>
                setState(() => _isLegendCollapsed = !_isLegendCollapsed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isLegendCollapsed ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLegendItem(String label, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );

  Widget _buildPincodeCard() => Card(
    elevation: 4,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isPincodeCollapsed) ...[
              if (_assignedPincodes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No pincodes',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                )
              else ...[
                if (_selectedPincodes.isNotEmpty &&
                    _googlePlacesShops.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_googlePlacesShops.length} total Google Places',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Filtered by: ${_selectedPlaceTypes.join(", ")}',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoadingGooglePlaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _assignedPincodes
                          .map((p) => _buildPincodeItem(p))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // All and Clear buttons at bottom right
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _selectAllPincodes,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _clearPincodeSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
            InkWell(
              onTap: () =>
                  setState(() => _isPincodeCollapsed = !_isPincodeCollapsed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pincode (${_selectedPincodes.length}/${_assignedPincodes.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isPincodeCollapsed
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPincodeItem(Map<String, dynamic> pincodeData) {
    final pincode = pincodeData['pincode'] ?? '';
    final city = pincodeData['city'] ?? '';
    final count = pincodeData['totalBusinesses'] ?? 0;
    final isSelected = _selectedPincodes.contains(pincode);
    return InkWell(
      onTap: () => _onPincodeSelected(pincode, pincodeData),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pincode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (city.isNotEmpty)
                    Text(
                      city,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '$count businesses',
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build Mapbox map widget
  Widget _buildMapboxMap() {
    final initialPoint = _currentPosition != null
        ? Position(_currentPosition!.longitude, _currentPosition!.latitude)
        : _defaultLocation;
    
    return MapWidget(
      key: const ValueKey("admin_enhanced_map"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: initialPoint),
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
      
      // Create annotation manager
      _pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      
      _isMapReady = true;
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (salesmanAccounts.isNotEmpty) {
        await _focusOnAccountsArea();
      }
      
      // Update markers after map is ready
      await _updateMapMarkers();
      
      print('✅ Mapbox map created for admin enhanced map');
    } catch (e) {
      print('❌ Error creating Mapbox map: $e');
    }
  }
}
