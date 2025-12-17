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

    GooglePlacesService.instance.initialize();
    _initializeMap();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    LocationService.instance.stopLocationTracking();
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
    Set<String> funnelStages = {};
    Set<String> pincodes = {};
    Set<String> customerStages = {};
    Set<String> businessTypes = {};

    for (var account in salesmanAccounts) {
      if (account['funnelStage'] != null) {
        funnelStages.add(account['funnelStage'].toString());
      }
      if (account['pincode'] != null) {
        pincodes.add(account['pincode'].toString());
      }
      if (account['customerStage'] != null) {
        customerStages.add(account['customerStage'].toString());
      }
      if (account['businessType'] != null) {
        businessTypes.add(account['businessType'].toString());
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
      availableFunnelStages = funnelStages.toList()..sort();
      availablePincodes = pincodes.toList()..sort();
      availableAssignedAreas = assignedAreas.toList()..sort();
      availableCustomerStages = customerStages.toList()..sort();
      availableBusinessTypes = businessTypes.toList()..sort();
    });
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null) return;

    try {
      List<PlaceInfo> allPlaces = [];

      // Load places for each selected place type
      for (String placeType in _selectedPlaceTypes) {
        final nearbyResults = await GooglePlacesService.instance
            .fetchNearbyPlaces(
              lat: _currentPosition!.latitude,
              lng: _currentPosition!.longitude,
              radius: _searchRadius,
              type: placeType,
            );

        final places = nearbyResults
            .map((result) => PlaceInfo.fromNearbyResult(result))
            .toList();

        allPlaces.addAll(places);
      }

      setState(() {
        nearbyPlaces = allPlaces;
      });

      print(
        '✅ Loaded ${nearbyPlaces.length} nearby places for ${_selectedPlaceTypes.length} place types',
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
      final details = await GooglePlacesService.instance.fetchPlaceDetails(
        place.placeId,
      );

      if (details != null) {
        final detailedPlace = PlaceInfo.fromPlaceDetails(details);
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
                    ? () {
                        Navigator.pop(context);
                        _focusOnAccount(account);
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

  void _focusOnAccount(Map<String, dynamic> account) {
    if (account['latitude'] != null && account['longitude'] != null) {
      try {
        final lat = double.parse(account['latitude'].toString());
        final lng = double.parse(account['longitude'].toString());

        if (_isValidCoordinate(lat, lng)) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
          );
        } else {
          _showError(
            'Invalid location coordinates for this account (lat: $lat, lng: $lng)',
          );
        }
      } catch (e) {
        print('❌ Error focusing on account: $e');
        _showError('Error parsing location coordinates for this account');
      }
    } else {
      _showError('No location data available for this account');
    }
  }

  void _focusOnAccountsArea() {
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

    if (accountsWithLocation.isEmpty) {
      // Focus on current location if no accounts have location
      if (_currentPosition != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            12,
          ),
        );
      }
      return;
    }

    if (accountsWithLocation.length == 1) {
      // Focus on single account
      final account = accountsWithLocation.first;
      final lat = double.parse(account['latitude'].toString());
      final lng = double.parse(account['longitude'].toString());
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
      );
    } else {
      // Calculate bounds for multiple accounts
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

      // Add padding to bounds
      final latPadding = (maxLat - minLat) * 0.1;
      final lngPadding = (maxLng - minLng) * 0.1;

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15,
          ),
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
    });
    _updateMapMarkers();
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
                  onMapCreated: (controller) {
                    _mapController = controller;

                    // Delay to ensure map is fully loaded
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted && _mapController != null) {
                        if (salesmanAccounts.isNotEmpty) {
                          // Focus on accounts area first
                          _focusOnAccountsArea();
                        } else if (_markers.isNotEmpty) {
                          // Fallback to fitting all markers
                          _fitMarkersInView();
                        }
                      }
                    });
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

                // Legend and Controls
                Positioned(bottom: 100, left: 16, child: _buildLegendCard()),

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
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          15,
                        ),
                      );
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
                                onPressed: () {
                                  setState(() {
                                    _showAccountsList = false;
                                  });
                                  _focusOnAccount(account);
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
            // Header
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

            // Search radius - compact
            Text(
              'Search Radius: ${_searchRadius}m',
              style: const TextStyle(fontSize: 12),
            ),
            Slider(
              value: _searchRadius.toDouble(),
              min: 500,
              max: 5000,
              divisions: 9,
              label: '${_searchRadius}m',
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isLegendCollapsed = !_isLegendCollapsed;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isLegendCollapsed ? Icons.expand_more : Icons.expand_less,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
            if (!_isLegendCollapsed) ...[
              const SizedBox(height: 8),
              _buildLegendItem('My Location', Colors.blue),
              _buildLegendItem('Approved Accounts', Colors.green),
              _buildLegendItem('Pending Accounts', Colors.orange),
              _buildLegendItem('Nearby Places', Colors.purple),
            ],
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

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;

    final bounds = _calculateBounds(_markers);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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
          selectedFunnelStages,
          (selected) {
            setState(() {
              selectedFunnelStages = selected;
            });
            _updateMapMarkers();
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
          selectedPincodes,
          (selected) {
            setState(() {
              selectedPincodes = selected;
            });
            _updateMapMarkers();
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
          selectedAssignedAreas,
          (selected) {
            setState(() {
              selectedAssignedAreas = selected;
            });
            _updateMapMarkers();
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
          selectedCustomerStages,
          (selected) {
            setState(() {
              selectedCustomerStages = selected;
            });
            _updateMapMarkers();
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
          selectedBusinessTypes,
          (selected) {
            setState(() {
              selectedBusinessTypes = selected;
            });
            _updateMapMarkers();
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
          value: selectedApprovalStatus,
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
              selectedApprovalStatus = value;
            });
            _updateMapMarkers();
          },
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilter(
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      fontSize: 14,
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
                    // Select All / Clear All buttons
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
