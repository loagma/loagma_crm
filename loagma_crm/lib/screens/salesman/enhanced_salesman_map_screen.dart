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
  String _selectedPlaceType = 'store';
  int _searchRadius = 1500;
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;

  // Filter states for accounts
  String? selectedCustomerStage;
  String? selectedBusinessType;
  String? selectedFunnelStage;
  String? selectedPincode;
  String? selectedAssignedArea;
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
      final nearbyResults = await GooglePlacesService.instance
          .fetchNearbyPlaces(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            radius: _searchRadius,
            type: _selectedPlaceType,
          );

      final places = nearbyResults
          .map((result) => PlaceInfo.fromNearbyResult(result))
          .toList();

      setState(() {
        nearbyPlaces = places;
      });

      print('✅ Loaded ${nearbyPlaces.length} nearby places');
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

            if (lat == 0 && lng == 0) continue;

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
            print('Error parsing coordinates for account ${account['id']}: $e');
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

  List<Map<String, dynamic>> _getFilteredAccounts() {
    return salesmanAccounts.where((account) {
      if (selectedCustomerStage != null &&
          account['customerStage'] != selectedCustomerStage)
        return false;
      if (selectedBusinessType != null &&
          account['businessType'] != selectedBusinessType)
        return false;
      if (selectedFunnelStage != null &&
          account['funnelStage'] != selectedFunnelStage)
        return false;
      if (selectedPincode != null && account['pincode'] != selectedPincode)
        return false;
      if (selectedAssignedArea != null) {
        // Check if account is in the selected assigned area
        bool isInAssignedArea = areaAssignments.any(
          (assignment) =>
              assignment['city'] == selectedAssignedArea &&
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _focusOnAccount(account);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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

  void _focusOnAccount(Map<String, dynamic> account) {
    if (account['latitude'] != null && account['longitude'] != null) {
      try {
        final lat = double.parse(account['latitude'].toString());
        final lng = double.parse(account['longitude'].toString());

        if (lat != 0 && lng != 0) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
          );
        }
      } catch (e) {
        print('Error focusing on account: $e');
        _showError('Invalid location coordinates for this account');
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
        return lat != 0 && lng != 0;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCustomerStage = null;
      selectedBusinessType = null;
      selectedFunnelStage = null;
      selectedPincode = null;
      selectedAssignedArea = null;
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
        title: const Text('Enhanced Map View'),
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
                  Text('Loading enhanced map data...'),
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
                if (salesmanAccounts.isNotEmpty)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.green,
                    onPressed: _focusOnAccountsArea,
                    tooltip: 'Focus on Accounts',
                    child: const Icon(Icons.account_circle),
                  ),
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
                FloatingActionButton(
                  backgroundColor: primaryColor,
                  onPressed: () {
                    if (_markers.isNotEmpty) {
                      _fitMarkersInView();
                    } else {
                      _showError('No markers to display');
                    }
                  },
                  tooltip: 'Fit All Markers',
                  child: const Icon(Icons.center_focus_strong),
                ),
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
    return selectedCustomerStage != null ||
        selectedBusinessType != null ||
        selectedFunnelStage != null ||
        selectedPincode != null ||
        selectedAssignedArea != null ||
        selectedApprovalStatus != null;
  }

  Widget _buildFiltersPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filters & Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Layer toggles
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Accounts'),
                    subtitle: Text('${_getFilteredAccounts().length} accounts'),
                    value: _showAccounts,
                    onChanged: (value) {
                      setState(() {
                        _showAccounts = value;
                      });
                      _updateMapMarkers();
                    },
                    activeColor: primaryColor,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Places'),
                    subtitle: Text('${nearbyPlaces.length} places'),
                    value: _showPlaces,
                    onChanged: (value) {
                      setState(() {
                        _showPlaces = value;
                      });
                      _updateMapMarkers();
                    },
                    activeColor: primaryColor,
                  ),
                ),
              ],
            ),

            const Divider(),

            // Account Filters
            const Text(
              'Account Filters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Funnel Stage Filter
            if (availableFunnelStages.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedFunnelStage,
                decoration: const InputDecoration(
                  labelText: 'Funnel Stage',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Funnel Stages'),
                  ),
                  ...availableFunnelStages.map(
                    (stage) => DropdownMenuItem<String>(
                      value: stage,
                      child: Text(stage),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFunnelStage = value;
                  });
                  _updateMapMarkers();
                },
              ),
              const SizedBox(height: 8),
            ],

            // Pincode Filter
            if (availablePincodes.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedPincode,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Pincodes'),
                  ),
                  ...availablePincodes.map(
                    (pincode) => DropdownMenuItem<String>(
                      value: pincode,
                      child: Text(pincode),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPincode = value;
                  });
                  _updateMapMarkers();
                },
              ),
              const SizedBox(height: 8),
            ],

            // Assigned Area Filter
            if (availableAssignedAreas.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedAssignedArea,
                decoration: const InputDecoration(
                  labelText: 'Assigned Area',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Areas'),
                  ),
                  ...availableAssignedAreas.map(
                    (area) => DropdownMenuItem<String>(
                      value: area,
                      child: Text(area),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAssignedArea = value;
                  });
                  _updateMapMarkers();
                },
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),

            // Place type filter
            const Text(
              'Place Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _placeTypes.length,
                itemBuilder: (context, index) {
                  final placeType = _placeTypes[index];
                  final isSelected = _selectedPlaceType == placeType['type'];

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            placeType['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(placeType['name']),
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPlaceType = placeType['type'];
                          });
                          _loadNearbyPlaces();
                        }
                      },
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Search radius
            Text('Search Radius: ${_searchRadius}m'),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('My Location', Colors.blue),
            _buildLegendItem('Approved Accounts', Colors.green),
            _buildLegendItem('Pending Accounts', Colors.orange),
            _buildLegendItem('Nearby Places', Colors.purple),
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
}
