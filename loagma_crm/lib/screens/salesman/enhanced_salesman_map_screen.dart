import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/google_places_service.dart';
import '../../services/location_service.dart';
import '../../services/network_service.dart';
import '../../services/task_assignment_service.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';
import '../../config/google_places_config.dart';

class EnhancedSalesmanMapScreen extends StatefulWidget {
  const EnhancedSalesmanMapScreen({super.key});

  @override
  State<EnhancedSalesmanMapScreen> createState() =>
      _EnhancedSalesmanMapScreenState();
}

class _EnhancedSalesmanMapScreenState extends State<EnhancedSalesmanMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isControllerDisposed = false;
  Set<Marker> _markers = {};
  bool isLoading = true;

  // Data
  List<Map<String, dynamic>> salesmanAccounts = [];
  List<PlaceInfo> nearbyPlaces = [];
  List<Map<String, dynamic>> areaAssignments = [];
  Position? _currentPosition;
  bool _locationPermissionGranted = false;

  // UI State
  bool _showFilters = false;
  bool _showPlaces = true;
  bool _showAccounts = true;
  bool _showAccountsList = false;
  List<String> _selectedPlaceTypes = ['store'];
  int _searchRadius = 1500;
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;
  bool _isLegendCollapsed = false;

  // Current Area State
  String? _currentAreaName;
  bool _isLoadingCurrentArea = false;

  // Filter states for accounts - changed to support multiple selections
  List<String> selectedCustomerStages = [];
  List<String> selectedBusinessTypes = [];
  List<String> selectedFunnelStages = [];
  List<String> selectedPincodes = [];
  List<String> selectedAssignedAreas = [];
  bool? selectedApprovalStatus;

  // Temporary filter states (before applying)
  List<String> tempSelectedCustomerStages = [];
  List<String> tempSelectedBusinessTypes = [];
  List<String> tempSelectedFunnelStages = [];
  List<String> tempSelectedPincodes = [];
  List<String> tempSelectedAssignedAreas = [];
  bool? tempSelectedApprovalStatus;

  // Available filter options
  List<String> availableFunnelStages = [];
  List<String> availablePincodes = [];
  List<String> availableAssignedAreas = [];
  List<String> availableCustomerStages = [];
  List<String> availableBusinessTypes = [];

  // Animation controllers
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  static const Color primaryColor = Color(0xFFD7BE69);
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090); // Delhi

  // Comprehensive predefined filter options
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

  // Place types for business discovery
  final List<Map<String, dynamic>> _placeTypes = [
    {'type': 'store', 'name': 'Stores', 'icon': Icons.store},
    {'type': 'restaurant', 'name': 'Restaurants', 'icon': Icons.restaurant},
    {'type': 'shopping_mall', 'name': 'Malls', 'icon': Icons.shopping_bag},
    {
      'type': 'supermarket',
      'name': 'Supermarkets',
      'icon': Icons.local_grocery_store,
    },
    {
      'type': 'convenience_store',
      'name': 'Kirana Store',
      'icon': Icons.storefront,
    },
    {'type': 'lodging', 'name': 'Hostel', 'icon': Icons.hotel},
    {'type': 'meal_takeaway', 'name': 'Caterers', 'icon': Icons.takeout_dining},
    {'type': 'food', 'name': 'Sweets', 'icon': Icons.cake},
    {'type': 'bank', 'name': 'Banks', 'icon': Icons.account_balance},
    {
      'type': 'gas_station',
      'name': 'Gas Stations',
      'icon': Icons.local_gas_station,
    },
    {'type': 'pharmacy', 'name': 'Pharmacies', 'icon': Icons.local_pharmacy},
    {'type': 'hospital', 'name': 'Hospitals', 'icon': Icons.local_hospital},
    {'type': 'school', 'name': 'Schools', 'icon': Icons.school},
    {'type': 'cafe', 'name': 'Cafes', 'icon': Icons.local_cafe},
  ];

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize temporary filters
    _resetTempFilters();

    _initializeMap();
  }

  @override
  void dispose() {
    print('🧹 Disposing EnhancedSalesmanMapScreen...');

    // Mark controller as disposed first to prevent any new operations
    _isControllerDisposed = true;
    _isMapReady = false;

    // Clear the controller reference
    _mapController = null;

    // Dispose animation controller
    _filterAnimationController.dispose();

    // Stop location tracking
    LocationService.instance.stopLocationTracking();

    print('✅ EnhancedSalesmanMapScreen disposed successfully');
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => isLoading = true);

    await _getCurrentLocation();
    await _loadSalesmanAccounts();
    await _loadAreaAssignments();

    if (_currentPosition != null) {
      await _loadNearbyPlaces();
    }

    setState(() => isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _currentPosition = position;
        _locationPermissionGranted = true;
      });

      print('📍 Current Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error getting location: $e');
      _showError('Error getting location: $e');
    }
  }

  Future<void> _loadSalesmanAccounts() async {
    try {
      // Check connectivity first
      final hasConnection = await NetworkService.hasInternetConnection();
      if (!hasConnection) {
        _showError(
          'No internet connection. Please check your network and try again.',
        );
        return;
      }

      final userId = UserService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final token = UserService.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId',
      );

      print('📡 Loading accounts from: $accountsUrl');

      final response = await http.get(accountsUrl, headers: headers);

      print('📊 Accounts response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            salesmanAccounts = List<Map<String, dynamic>>.from(
              data['data'] ?? [],
            );
          });
          _extractFilterOptions();
          print('✅ Loaded ${salesmanAccounts.length} salesman accounts');

          // Update map markers after loading accounts
          _updateMapMarkers();

          // Focus on accounts if available
          if (salesmanAccounts.isNotEmpty && _mapController != null) {
            _focusOnAccountsArea();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load accounts');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error loading accounts: $e');
      _showError(NetworkService.getNetworkErrorMessage(e));
    }
  }

  Future<void> _loadAreaAssignments() async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null || userId.isEmpty) return;

      final token = UserService.token;
      if (token == null || token.isEmpty) {
        print('⚠️ No token available for area assignments');
        return;
      }

      print('📡 Loading area assignments using service...');

      try {
        final assignments =
            await TaskAssignmentService.getSalesmanTaskAssignments();
        print('📊 Task assignments loaded: ${assignments.length}');

        setState(() {
          areaAssignments = assignments.map((a) => a.toJson()).toList();
        });
        _extractFilterOptions();
        print('✅ Loaded ${areaAssignments.length} task assignments');
      } catch (e) {
        print('❌ Error loading task assignments: $e');
      }
    } catch (e) {
      print('❌ Error loading area assignments: $e');
    }
  }

  void _extractFilterOptions() {
    // Extract pincodes from actual data
    Set<String> pincodes = {};
    for (var account in salesmanAccounts) {
      if (account['pincode'] != null) {
        pincodes.add(account['pincode'].toString());
      }
    }

    // Extract assigned areas from area assignments
    Set<String> assignedAreas = {};
    for (var assignment in areaAssignments) {
      if (assignment['city'] != null) {
        assignedAreas.add(assignment['city'].toString());
      }
    }

    setState(() {
      // Use comprehensive predefined lists for stages and business types
      availableFunnelStages = List.from(allFunnelStages);
      availableCustomerStages = List.from(allCustomerStages);
      availableBusinessTypes = List.from(allBusinessTypes);

      // Use extracted data for location-specific filters
      availablePincodes = pincodes.toList()..sort();
      availableAssignedAreas = assignedAreas.toList()..sort();
    });
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null) return;

    try {
      List<PlaceInfo> allPlaces = [];

      // Load places for each selected place type with delay to avoid rate limiting
      for (int i = 0; i < _selectedPlaceTypes.length; i++) {
        String placeType = _selectedPlaceTypes[i];

        try {
          final nearbyResults = await GooglePlacesService.fetchNearbyPlaces(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            radius: _searchRadius,
            type: placeType,
          );

          final places = nearbyResults
              .map((result) => PlaceInfo.fromRawNearbyResult(result))
              .toList();

          allPlaces.addAll(places);

          // Add small delay between requests to avoid rate limiting
          if (i < _selectedPlaceTypes.length - 1) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          print('❌ Error loading places for type $placeType: $e');
          // Continue with other place types even if one fails
        }
      }

      // Remove duplicates based on place ID
      final uniquePlaces = <String, PlaceInfo>{};
      for (final place in allPlaces) {
        uniquePlaces[place.placeId] = place;
      }

      setState(() {
        nearbyPlaces = uniquePlaces.values.toList();
      });

      print(
        '✅ Loaded ${nearbyPlaces.length} unique nearby places for ${_selectedPlaceTypes.length} place types',
      );
      _updateMapMarkers();
    } catch (e) {
      print('Error loading places: $e');
      _showError('Error loading nearby places: $e');
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};

    // Current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'My Location',
            snippet: UserService.name ?? 'Current Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Salesman accounts markers
    if (_showAccounts) {
      for (var account in _getFilteredAccounts()) {
        if (account['latitude'] != null && account['longitude'] != null) {
          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());

            // Enhanced coordinate validation
            if (!_isValidCoordinate(lat, lng)) {
              print(
                '⚠️ Invalid coordinates for account ${account['id']}: lat=$lat, lng=$lng',
              );
              continue;
            }

            final isApproved = account['isApproved'] == true;
            final personName = account['personName'] ?? 'Unknown';
            final businessName = account['businessName'];

            markers.add(
              Marker(
                markerId: MarkerId('account_${account['id']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: personName,
                  snippet: businessName ?? 'Account',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isApproved
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueOrange,
                ),
                onTap: () => _showAccountDetails(account),
              ),
            );
          } catch (e) {
            print(
              '❌ Error parsing coordinates for account ${account['id']}: $e',
            );
          }
        }
      }
    }

    // Nearby places markers
    if (_showPlaces) {
      for (int i = 0; i < nearbyPlaces.length; i++) {
        final place = nearbyPlaces[i];
        if (place.latitude != null && place.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('place_$i'),
              position: LatLng(place.latitude!, place.longitude!),
              infoWindow: InfoWindow(
                title: place.name,
                snippet:
                    '${place.formattedRating} • ${place.statusDescription}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              onTap: () => _showPlaceDetails(place),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  // Enhanced coordinate validation
  bool _isValidCoordinate(double lat, double lng) {
    // Check if coordinates are within valid ranges
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return false;
    }

    // Check if coordinates are not exactly 0,0 (often indicates missing data)
    if (lat == 0 && lng == 0) {
      return false;
    }

    // Check if coordinates are not obviously invalid (like very small decimals that might be parsing errors)
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) {
      return false;
    }

    return true;
  }

  bool _canFocusOnAccount(Map<String, dynamic> account) {
    if (account['latitude'] == null || account['longitude'] == null) {
      return false;
    }

    try {
      final lat = double.parse(account['latitude'].toString());
      final lng = double.parse(account['longitude'].toString());
      return _isValidCoordinate(lat, lng);
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> _getFilteredAccounts() {
    return salesmanAccounts.where((account) {
      // Multi-select filter logic
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
      if (selectedAssignedAreas.isNotEmpty) {
        // Check if account is in any of the selected assigned areas
        bool isInAssignedArea = areaAssignments.any(
          (assignment) =>
              selectedAssignedAreas.contains(assignment['city']) &&
              assignment['pinCode'] == account['pincode'],
        );
        if (!isInAssignedArea) return false;
      }
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

      if (details != null) {
        final detailedPlace = PlaceInfo.fromRawPlaceDetails(details);
        setState(() {
          _selectedPlace = detailedPlace;
          _showPlaceDetailsOverlay = true;
        });
      }
    } catch (e) {
      _showError('Failed to load place details');
    }
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
                      Text(
                        account['isApproved'] == true
                            ? 'Approved Account'
                            : 'Pending Approval',
                        style: TextStyle(
                          color: account['isApproved'] == true
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (account['businessName'] != null) ...[
              _buildDetailRow(
                Icons.business,
                'Business',
                account['businessName'],
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              Icons.phone,
              'Contact',
              account['contactNumber'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.flag,
              'Customer Stage',
              account['customerStage'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.timeline,
              'Funnel Stage',
              account['funnelStage'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            if (account['address'] != null) ...[
              _buildDetailRow(Icons.location_on, 'Address', account['address']),
              const SizedBox(height: 12),
            ],
            if (account['pincode'] != null)
              _buildDetailRow(Icons.pin_drop, 'Pincode', account['pincode']),
            const SizedBox(height: 12),
            // Location status
            _buildLocationStatus(account),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canFocusOnAccount(account)
                    ? () async {
                        Navigator.pop(context);
                        await _focusOnAccount(account);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canFocusOnAccount(account)
                      ? primaryColor
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.my_location),
                label: Text(
                  _canFocusOnAccount(account)
                      ? 'Focus on Map'
                      : 'Invalid GPS Location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _focusOnAccount(Map<String, dynamic> account) async {
    if (!mounted) {
      print('🚫 Widget not mounted, cannot focus on account');
      return;
    }

    if (account['latitude'] == null || account['longitude'] == null) {
      _showError('No location data available for this account');
      return;
    }

    try {
      final lat = double.parse(account['latitude'].toString());
      final lng = double.parse(account['longitude'].toString());

      if (!_isValidCoordinate(lat, lng)) {
        _showError(
          'Invalid location coordinates for this account (lat: $lat, lng: $lng)',
        );
        return;
      }

      final target = LatLng(lat, lng);
      final accountName = account['personName'] ?? 'Unknown Account';

      print('🎯 Attempting to focus on account: $accountName at ($lat, $lng)');

      // Check if map is ready before attempting to focus
      if (!_isMapReady || _mapController == null || _isControllerDisposed) {
        print('🚫 Map not ready for focusing on account');
        _showError('Map is not ready. Please wait and try again.');
        return;
      }

      final success = await _safeAnimateCamera(
        CameraUpdate.newLatLngZoom(target, 18),
        description: 'Focus on account: $accountName',
      );

      if (success) {
        print('✅ Successfully focused on account: $accountName');
      } else {
        print('❌ Failed to focus on account: $accountName');
        _showError('Unable to focus on map. Please try again.');
      }
    } catch (e) {
      print('❌ Error focusing on account: $e');
      _showError('Error parsing location coordinates for this account');
    }
  }

  Future<void> _focusOnAccountsArea() async {
    if (!mounted) {
      print('🚫 Widget not mounted, cannot focus on accounts area');
      return;
    }

    // Check if map is ready
    if (!_isMapReady || _mapController == null || _isControllerDisposed) {
      print('🚫 Map not ready for focusing on accounts area');
      return;
    }

    try {
      final accountsWithLocation = salesmanAccounts.where((account) {
        if (account['latitude'] == null || account['longitude'] == null)
          return false;
        try {
          final lat = double.parse(account['latitude'].toString());
          final lng = double.parse(account['longitude'].toString());
          return _isValidCoordinate(lat, lng);
        } catch (e) {
          return false;
        }
      }).toList();

      print(
        '📊 Found ${accountsWithLocation.length} accounts with valid GPS coordinates',
      );

      if (accountsWithLocation.isEmpty) {
        // Focus on current location if no accounts have location
        if (_currentPosition != null) {
          print('📍 No accounts with GPS, focusing on current location');
          await _safeAnimateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              12,
            ),
            description: 'Focus on current location (no accounts with GPS)',
          );
        } else {
          print('📍 No current location available, using default location');
          await _safeAnimateCamera(
            CameraUpdate.newLatLngZoom(_defaultLocation, 10),
            description: 'Focus on default location',
          );
        }
        return;
      }

      if (accountsWithLocation.length == 1) {
        // Focus on single account
        final account = accountsWithLocation.first;
        final lat = double.parse(account['latitude'].toString());
        final lng = double.parse(account['longitude'].toString());
        print('🎯 Focusing on single account at ($lat, $lng)');

        await _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
          description: 'Focus on single account area',
        );
      } else {
        // Calculate bounds for multiple accounts
        print(
          '🎯 Calculating bounds for ${accountsWithLocation.length} accounts',
        );

        double minLat = double.parse(
          accountsWithLocation.first['latitude'].toString(),
        );
        double maxLat = minLat;
        double minLng = double.parse(
          accountsWithLocation.first['longitude'].toString(),
        );
        double maxLng = minLng;

        for (final account in accountsWithLocation) {
          final lat = double.parse(account['latitude'].toString());
          final lng = double.parse(account['longitude'].toString());

          minLat = minLat < lat ? minLat : lat;
          maxLat = maxLat > lat ? maxLat : lat;
          minLng = minLng < lng ? minLng : lng;
          maxLng = maxLng > lng ? maxLng : lng;
        }

        // Add padding to bounds (minimum 0.01 degrees)
        final latPadding = ((maxLat - minLat) * 0.1).clamp(0.01, 0.1);
        final lngPadding = ((maxLng - minLng) * 0.1).clamp(0.01, 0.1);

        final bounds = LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        );

        print(
          '🗺️ Bounds: SW(${minLat - latPadding}, ${minLng - lngPadding}) NE(${maxLat + latPadding}, ${maxLng + lngPadding})',
        );

        await _safeAnimateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
          description: 'Focus on multiple accounts area',
        );
      }
    } catch (e) {
      print('❌ Error focusing on accounts area: $e');
      // Fallback to default location
      await _safeAnimateCamera(
        CameraUpdate.newLatLngZoom(_defaultLocation, 10),
        description: 'Fallback to default location after error',
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus(Map<String, dynamic> account) {
    final hasCoordinates =
        account['latitude'] != null && account['longitude'] != null;

    if (!hasCoordinates) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'No GPS coordinates available',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    try {
      final lat = double.parse(account['latitude'].toString());
      final lng = double.parse(account['longitude'].toString());

      if (_isValidCoordinate(lat, lng)) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invalid GPS coordinates: $lat, $lng',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              size: 16,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error parsing GPS coordinates',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// Check if the map is in a valid state for operations
  bool _isMapInValidState() {
    return mounted &&
        !_isControllerDisposed &&
        _isMapReady &&
        _mapController != null;
  }

  /// Safe camera animation with comprehensive lifecycle checks
  Future<bool> _safeAnimateCamera(
    CameraUpdate update, {
    String? description,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      // Check if map is in valid state
      if (!_isMapInValidState()) {
        print(
          '🚫 Map not in valid state, skipping camera animation: $description',
        );
        return false;
      }

      try {
        // Additional safety check right before animation
        if (_mapController == null) {
          print(
            '🚫 Controller became null just before animation: $description',
          );
          return false;
        }

        await _mapController!.animateCamera(update);
        print('✅ Camera animation successful: $description');
        return true;
      } catch (e) {
        print('❌ Camera animation failed (attempt ${attempt + 1}): $e');

        // Handle disposal errors
        if (e.toString().contains('disposed') ||
            e.toString().contains('GoogleMapController was used after')) {
          print('🔄 Controller was disposed, marking as disposed');
          _isControllerDisposed = true;
          _isMapReady = false;
          _mapController = null;
          return false;
        }

        // For other errors, retry if we have attempts left
        if (attempt < maxRetries) {
          print('🔄 Retrying camera animation in 200ms...');
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        return false;
      }
    }

    return false;
  }

  /// Get current area name and load nearby shops
  Future<void> _loadCurrentAreaShops() async {
    if (_isLoadingCurrentArea) return;

    setState(() {
      _isLoadingCurrentArea = true;
    });

    try {
      // Get current location if not available
      if (_currentPosition == null) {
        await _getCurrentLocation();
      }

      if (_currentPosition == null) {
        _showError('Unable to get current location');
        return;
      }

      print(
        '🌍 Getting area name for current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      // Get area name using reverse geocoding
      final areaName = await _getCurrentAreaName(_currentPosition!);

      if (areaName != null) {
        setState(() {
          _currentAreaName = areaName;
        });

        print('📍 Current area: $areaName');

        // Load nearby places for current location
        await _loadNearbyPlaces();

        // Focus map on current location
        await _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15,
          ),
          description: 'Focus on current area: $areaName',
        );

        _showError('Loaded shops near $areaName');
      } else {
        _showError('Unable to determine current area name');
      }
    } catch (e) {
      print('❌ Error loading current area shops: $e');
      _showError('Error loading current area: $e');
    } finally {
      setState(() {
        _isLoadingCurrentArea = false;
      });
    }
  }

  /// Get current area name using reverse geocoding
  Future<String?> _getCurrentAreaName(Position position) async {
    try {
      // Use Google Places Geocoding API to get area name
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&key=${GooglePlacesConfig.apiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];

          // Try to get area/locality from address components
          for (final component in result['address_components']) {
            final types = List<String>.from(component['types']);

            // Look for sublocality, locality, or administrative_area_level_3
            if (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('locality') ||
                types.contains('administrative_area_level_3')) {
              return component['long_name'];
            }
          }

          // Fallback to formatted address
          return result['formatted_address']?.split(',')[0];
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting area name: $e');
      return null;
    }
  }

  void _clearAllFilters() {
    setState(() {
      selectedCustomerStages.clear();
      selectedBusinessTypes.clear();
      selectedFunnelStages.clear();
      selectedPincodes.clear();
      selectedAssignedAreas.clear();
      selectedApprovalStatus = null;
      // Also clear temporary filters
      tempSelectedCustomerStages.clear();
      tempSelectedBusinessTypes.clear();
      tempSelectedFunnelStages.clear();
      tempSelectedPincodes.clear();
      tempSelectedAssignedAreas.clear();
      tempSelectedApprovalStatus = null;
    });
    _updateMapMarkers();
  }

  void _applyFilters() {
    setState(() {
      selectedCustomerStages = List.from(tempSelectedCustomerStages);
      selectedBusinessTypes = List.from(tempSelectedBusinessTypes);
      selectedFunnelStages = List.from(tempSelectedFunnelStages);
      selectedPincodes = List.from(tempSelectedPincodes);
      selectedAssignedAreas = List.from(tempSelectedAssignedAreas);
      selectedApprovalStatus = tempSelectedApprovalStatus;
    });
    _updateMapMarkers();
  }

  bool get _hasFilterChanges {
    return !_listsEqual(selectedCustomerStages, tempSelectedCustomerStages) ||
        !_listsEqual(selectedBusinessTypes, tempSelectedBusinessTypes) ||
        !_listsEqual(selectedFunnelStages, tempSelectedFunnelStages) ||
        !_listsEqual(selectedPincodes, tempSelectedPincodes) ||
        !_listsEqual(selectedAssignedAreas, tempSelectedAssignedAreas) ||
        selectedApprovalStatus != tempSelectedApprovalStatus;
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    for (int i = 0; i < list2.length; i++) {
      if (!list1.contains(list2[i])) return false;
    }
    return true;
  }

  void _resetTempFilters() {
    setState(() {
      tempSelectedCustomerStages = List.from(selectedCustomerStages);
      tempSelectedBusinessTypes = List.from(selectedBusinessTypes);
      tempSelectedFunnelStages = List.from(selectedFunnelStages);
      tempSelectedPincodes = List.from(selectedPincodes);
      tempSelectedAssignedAreas = List.from(selectedAssignedAreas);
      tempSelectedApprovalStatus = selectedApprovalStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _getFilteredAccounts();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
              if (_showFilters) {
                _filterAnimationController.forward();
              } else {
                _filterAnimationController.reverse();
              }
            },
            tooltip: 'Toggle Filters',
          ),
          IconButton(
            icon: Icon(_showAccountsList ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _showAccountsList = !_showAccountsList;
              });
            },
            tooltip: _showAccountsList ? 'Show Map' : 'Show Accounts List',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
            tooltip: 'Refresh Data',
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
                  Text('Loading map data...'),
                ],
              ),
            )
          : _showAccountsList
          ? _buildAccountsList(filteredAccounts)
          : Stack(
              children: [
                // Map
                GoogleMap(
                  key: const ValueKey('enhanced_salesman_map'),
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 12,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) async {
                    if (!mounted || _isControllerDisposed) {
                      print(
                        '🚫 Widget not mounted or controller disposed during map creation',
                      );
                      return;
                    }

                    try {
                      _mapController = controller;
                      _isMapReady = true;
                      _isControllerDisposed = false;

                      print('🗺️ GoogleMap controller created and ready');

                      // Wait for map to be fully initialized
                      await Future.delayed(const Duration(milliseconds: 500));

                      // Double-check state before proceeding
                      if (!mounted || _isControllerDisposed || !_isMapReady) {
                        print(
                          '🚫 State changed during map initialization, aborting focus',
                        );
                        return;
                      }

                      // Focus on accounts area if available
                      if (salesmanAccounts.isNotEmpty) {
                        print(
                          '🎯 Focusing on accounts area after map creation',
                        );
                        await _focusOnAccountsArea();
                      } else if (_markers.isNotEmpty) {
                        print(
                          '🎯 Fitting all markers in view after map creation',
                        );
                        await _fitMarkersInView();
                      } else {
                        print('📍 No accounts or markers to focus on');
                      }
                    } catch (e) {
                      print('❌ Error in onMapCreated: $e');
                      _isControllerDisposed = true;
                      _isMapReady = false;
                      _mapController = null;

                      // Show error to user
                      if (mounted) {
                        _showError(
                          'Map initialization failed. Please refresh the screen.',
                        );
                      }
                    }
                  },
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Filters Panel
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

                // Legend and Controls - positioned at bottom left
                Positioned(bottom: 16, left: 16, child: _buildLegendCard()),

                // Place Details Overlay
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
              ],
            ),
      floatingActionButton: _showAccountsList
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Focus on accounts
                if (salesmanAccounts.isNotEmpty) const SizedBox(height: 8),

                // My location
                FloatingActionButton(
                  mini: true,
                  backgroundColor: primaryColor,
                  onPressed: () async {
                    if (!_isMapInValidState()) {
                      _showError(
                        'Map is not ready. Please wait and try again.',
                      );
                      return;
                    }

                    if (_currentPosition != null) {
                      print('📍 Focusing on my location from FAB');
                      final success = await _safeAnimateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          15,
                        ),
                        description: 'Focus on my location',
                      );

                      if (!success) {
                        _showError(
                          'Unable to focus on your location. Please try again.',
                        );
                      }
                    } else {
                      _showError('Current location not available');
                    }
                  },
                  tooltip: 'My Location',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),

                // Fit all markers
              ],
            ),
    );
  }

  Widget _buildAccountsList(List<Map<String, dynamic>> accounts) {
    return Column(
      children: [
        // Filters summary
        if (_hasActiveFilters())
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing ${accounts.length} of ${salesmanAccounts.length} accounts',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),

        // Accounts list
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
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final hasLocation =
                        account['latitude'] != null &&
                        account['longitude'] != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: account['isApproved'] == true
                              ? Colors.green
                              : Colors.orange,
                          child: Text(
                            (account['personName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                            Row(
                              children: [
                                if (account['funnelStage'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      account['funnelStage'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                if (account['pincode'] != null)
                                  Text(
                                    account['pincode'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: hasLocation
                            ? IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: primaryColor,
                                ),
                                onPressed: () async {
                                  if (!_isMapInValidState()) {
                                    _showError(
                                      'Map is not ready. Please wait and try again.',
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _showAccountsList = false;
                                  });
                                  await _focusOnAccount(account);
                                },
                                tooltip: 'Show on map',
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'No GPS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  bool _hasActiveFilters() {
    return selectedCustomerStages.isNotEmpty ||
        selectedBusinessTypes.isNotEmpty ||
        selectedFunnelStages.isNotEmpty ||
        selectedPincodes.isNotEmpty ||
        selectedAssignedAreas.isNotEmpty ||
        selectedApprovalStatus != null;
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with collapse arrow
            Row(
              children: [
                Icon(Icons.tune, color: primaryColor, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Filters & Controls',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: InkWell(
                      onTap: _clearAllFilters,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_all,
                            size: 12,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Collapse arrow
                InkWell(
                  onTap: () {
                    setState(() {
                      _showFilters = false;
                    });
                    _filterAnimationController.reverse();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Layer toggles in compact row
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Show Accounts',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${_getFilteredAccounts().length} accounts',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showAccounts,
                    onChanged: (value) {
                      setState(() {
                        _showAccounts = value;
                      });
                      _updateMapMarkers();
                    },
                    activeThumbColor: primaryColor,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Show Places',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      _currentAreaName != null
                          ? '${nearbyPlaces.length} places near $_currentAreaName'
                          : '${nearbyPlaces.length} places',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showPlaces,
                    onChanged: (value) {
                      setState(() {
                        _showPlaces = value;
                      });
                      _updateMapMarkers();
                    },
                    activeThumbColor: primaryColor,
                  ),
                ),
              ],
            ),

            const Divider(),

            // Account Filters Header
            Row(
              children: [
                Icon(Icons.filter_alt, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Account Filters:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Account Filters in 2-column grid
            _buildAccountFiltersGrid(),

            const SizedBox(height: 8),

            // Apply Filters Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasFilterChanges ? _applyFilters : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasFilterChanges
                          ? primaryColor
                          : Colors.grey[300],
                      foregroundColor: _hasFilterChanges
                          ? Colors.white
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: _hasFilterChanges ? 2 : 0,
                    ),
                    icon: Icon(
                      _hasFilterChanges ? Icons.check : Icons.filter_alt,
                      size: 16,
                    ),
                    label: Text(
                      _hasFilterChanges ? 'Apply Filters' : 'No Changes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasFilterChanges)
                  TextButton.icon(
                    onPressed: _resetTempFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),

            const Divider(),

            // Current Area Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingCurrentArea
                        ? null
                        : _loadCurrentAreaShops,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: _isLoadingCurrentArea
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(
                      _currentAreaName != null
                          ? 'Current: $_currentAreaName'
                          : 'Load Current Area Shops',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            //  filter - compact horizontal chips with multi-select
            const Text(
              'Place Types:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _placeTypes.length,
                itemBuilder: (context, index) {
                  final placeType = _placeTypes[index];
                  final isSelected = _selectedPlaceTypes.contains(
                    placeType['type'],
                  );

                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      selected: isSelected,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            placeType['icon'],
                            size: 12,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            placeType['name'],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPlaceTypes.add(placeType['type']);
                          } else {
                            _selectedPlaceTypes.remove(placeType['type']);
                            // Ensure at least one place type is always selected
                            if (_selectedPlaceTypes.isEmpty) {
                              _selectedPlaceTypes.add('store');
                            }
                          }
                        });
                        _loadNearbyPlaces();
                      },
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Search radius - compact (in kilometers)
            Text(
              'Search Radius: ${(_searchRadius / 1000).toStringAsFixed(1)}km',
              style: const TextStyle(fontSize: 12),
            ),
            Slider(
              value: _searchRadius.toDouble(),
              min: 500,
              max: 50000, // 50km max
              divisions: 99,
              label: '${(_searchRadius / 1000).toStringAsFixed(1)}km',
              onChanged: (value) {
                setState(() {
                  _searchRadius = value.round();
                });
              },
              onChangeEnd: (value) {
                _loadNearbyPlaces();
              },
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend items (show first when collapsed)
            if (!_isLegendCollapsed) ...[
              _buildLegendItem('My Location', Colors.blue),
              _buildLegendItem('Approved Accounts', Colors.green),
              _buildLegendItem('Pending Accounts', Colors.orange),
              _buildLegendItem('Nearby Places', Colors.purple),
              const SizedBox(height: 8),
            ],
            // Header with highlighted collapse arrow
            InkWell(
              onTap: () {
                setState(() {
                  _isLegendCollapsed = !_isLegendCollapsed;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        _isLegendCollapsed
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _fitMarkersInView() async {
    if (!mounted || _markers.isEmpty) {
      print('🚫 Cannot fit markers: widget not mounted or no markers');
      return;
    }

    if (!_isMapReady || _mapController == null || _isControllerDisposed) {
      print('🚫 Map not ready for fitting markers');
      return;
    }

    try {
      print('🎯 Fitting ${_markers.length} markers in view');
      final bounds = _calculateBounds(_markers);

      await _safeAnimateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
        description: 'Fit all markers in view',
      );
    } catch (e) {
      print('❌ Error fitting markers in view: $e');
    }
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = minLat < marker.position.latitude
          ? minLat
          : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude
          ? maxLat
          : marker.position.latitude;
      minLng = minLng < marker.position.longitude
          ? minLng
          : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude
          ? maxLng
          : marker.position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildAccountFiltersGrid() {
    List<Widget> filterWidgets = [];

    // Funnel Stages
    if (availableFunnelStages.isNotEmpty) {
      filterWidgets.add(
        _buildCompactMultiSelectFilter(
          'Funnel Stages',
          availableFunnelStages,
          tempSelectedFunnelStages,
          (selected) {
            setState(() {
              tempSelectedFunnelStages = selected;
            });
          },
        ),
      );
    }

    // Pincodes
    if (availablePincodes.isNotEmpty) {
      filterWidgets.add(
        _buildCompactMultiSelectFilter(
          'Pincodes',
          availablePincodes,
          tempSelectedPincodes,
          (selected) {
            setState(() {
              tempSelectedPincodes = selected;
            });
          },
        ),
      );
    }

    // Assigned Areas
    if (availableAssignedAreas.isNotEmpty) {
      filterWidgets.add(
        _buildCompactMultiSelectFilter(
          'Assigned Areas',
          availableAssignedAreas,
          tempSelectedAssignedAreas,
          (selected) {
            setState(() {
              tempSelectedAssignedAreas = selected;
            });
          },
        ),
      );
    }

    // Customer Stages
    if (availableCustomerStages.isNotEmpty) {
      filterWidgets.add(
        _buildCompactMultiSelectFilter(
          'Customer Stages',
          availableCustomerStages,
          tempSelectedCustomerStages,
          (selected) {
            setState(() {
              tempSelectedCustomerStages = selected;
            });
          },
        ),
      );
    }

    // Business Types
    if (availableBusinessTypes.isNotEmpty) {
      filterWidgets.add(
        _buildCompactMultiSelectFilter(
          'Business Types',
          availableBusinessTypes,
          tempSelectedBusinessTypes,
          (selected) {
            setState(() {
              tempSelectedBusinessTypes = selected;
            });
          },
        ),
      );
    }

    // Approval Status
    filterWidgets.add(_buildCompactDropdownFilter());

    // Create 2-column grid
    List<Widget> rows = [];
    for (int i = 0; i < filterWidgets.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: filterWidgets[i]),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < filterWidgets.length
                  ? filterWidgets[i + 1]
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < filterWidgets.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }

  Widget _buildCompactMultiSelectFilter(
    String label,
    List<String> options,
    List<String> selectedValues,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () => _showMultiSelectDialog(
              label,
              options,
              selectedValues,
              onChanged,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedValues.isEmpty
                        ? 'All $label'
                        : selectedValues.length == 1
                        ? selectedValues.first
                        : '${selectedValues.length} selected',
                    style: TextStyle(
                      fontSize: 11,
                      color: selectedValues.isEmpty
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdownFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Status',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        DropdownButtonFormField<bool?>(
          value: tempSelectedApprovalStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(fontSize: 11, color: Colors.black),
          dropdownColor: Colors.white,
          items: const [
            DropdownMenuItem<bool?>(
              value: null,
              child: Text(
                'All Statuses',
                style: TextStyle(color: Colors.black),
              ),
            ),
            DropdownMenuItem<bool?>(
              value: true,
              child: Text('Approved', style: TextStyle(color: Colors.black)),
            ),
            DropdownMenuItem<bool?>(
              value: false,
              child: Text('Pending', style: TextStyle(color: Colors.black)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              tempSelectedApprovalStatus = value;
            });
          },
        ),
      ],
    );
  }

  void _showMultiSelectDialog(
    String title,
    List<String> options,
    List<String> selectedValues,
    Function(List<String>) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedValues);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select $title'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    // Quick action buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected = List.from(options);
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Options list
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = tempSelected.contains(option);

                          return CheckboxListTile(
                            title: Text(option),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelected.add(option);
                                } else {
                                  tempSelected.remove(option);
                                }
                              });
                            },
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
                ElevatedButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
