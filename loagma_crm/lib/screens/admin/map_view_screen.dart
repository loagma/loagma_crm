import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/google_places_service.dart';
import '../../services/location_service.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';
import '../../services/shop_service.dart';
import '../../config/google_places_config.dart';

class AdminEnhancedMapScreen extends StatefulWidget {
  const AdminEnhancedMapScreen({super.key});

  @override
  State<AdminEnhancedMapScreen> createState() => _AdminEnhancedMapScreenState();
}

class _AdminEnhancedMapScreenState extends State<AdminEnhancedMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isControllerDisposed = false;
  Set<Marker> _markers = {};
  bool isLoading = true;

  List<Map<String, dynamic>> _googlePlacesShops = [];
  bool _isLoadingGooglePlaces = false;

  List<Map<String, dynamic>> salesmanAccounts = [];
  List<PlaceInfo> nearbyPlaces = [];
  List<Map<String, dynamic>> areaAssignments = [];
  Position? _currentPosition;
  bool _locationPermissionGranted = false;

  List<Map<String, dynamic>> _allSalesmen = [];
  List<String> _selectedSalesmenIds = [];
  bool _isLoadingSalesmen = false;

  bool _showFilters = false;
  bool _showPlaces = true;
  bool _showAccounts = true;
  bool _showAccountsList = false;
  List<String> _selectedPlaceTypes = ['convenience_store'];
  int _searchRadius = 1500;

  // Place types for business discovery - simplified and accurate
  final List<Map<String, dynamic>> _placeTypes = [
    {'type': 'restaurant', 'name': 'Restaurant', 'icon': Icons.restaurant},
    {
      'type': 'supermarket',
      'name': 'Supermarket',
      'icon': Icons.local_grocery_store,
    },
    {'type': 'convenience_store', 'name': 'Kirana', 'icon': Icons.storefront},
    {'type': 'lodging', 'name': 'Hotel', 'icon': Icons.hotel},
    {'type': 'bank', 'name': 'Bank', 'icon': Icons.account_balance},
    {'type': 'pharmacy', 'name': 'Pharmacy', 'icon': Icons.local_pharmacy},
    {'type': 'hospital', 'name': 'Hospital', 'icon': Icons.local_hospital},
    {'type': 'cafe', 'name': 'Cafe', 'icon': Icons.local_cafe},
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
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

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
    _isControllerDisposed = true;
    _isMapReady = false;
    _mapController = null;
    _filterAnimationController.dispose();
    LocationService.instance.stopLocationTracking();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => isLoading = true);
    await _getCurrentLocation();
    await _loadAllSalesmen();
    if (_currentPosition != null) await _loadNearbyPlaces();
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
      _updateMapMarkers();
      if (salesmanAccounts.isNotEmpty && _mapController != null)
        _focusOnAccountsArea();
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
      _updateMapMarkers();
    } catch (e) {
      print('Error: $e');
    }
  }

  void _updateMapMarkers() {
    if (_selectedPincodes.isNotEmpty) {
      // If pincodes are selected, show all shops (existing + Google Places)
      _updateMapMarkersWithAllShops();
    } else {
      // Default behavior - show only salesman accounts and nearby places
      _updateMapMarkersDefault();
    }
  }

  void _updateMapMarkersDefault() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add salesman accounts
    if (_showAccounts) {
      for (var account in _getFilteredAccounts()) {
        if (account['latitude'] != null && account['longitude'] != null) {
          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());
            if (!_isValidCoordinate(lat, lng)) continue;

            markers.add(
              Marker(
                markerId: MarkerId('account_${account['id']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: account['personName'] ?? 'Unknown',
                  snippet:
                      '${account['businessName'] ?? ''} • SR: ${account['salesmanName'] ?? ''}',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  account['isApproved'] == true
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueOrange,
                ),
                onTap: () => _showAccountDetails(account),
              ),
            );
          } catch (e) {
            print('❌ Error adding account marker: $e');
          }
        }
      }
    }

    // Add nearby places
    if (_showPlaces) {
      for (int i = 0; i < nearbyPlaces.length; i++) {
        final place = nearbyPlaces[i];
        if (place.latitude != null && place.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('place_$i'),
              position: LatLng(place.latitude!, place.longitude!),
              infoWindow: InfoWindow(title: place.name),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              onTap: () => _showPlaceDetails(place),
            ),
          );
        }
      }
    }

    setState(() => _markers = markers);
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
      if (minLat != double.infinity) {
        final bounds = LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        );
        await _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    } catch (e) {}
  }

  bool _isMapInValidState() =>
      mounted &&
      !_isControllerDisposed &&
      _isMapReady &&
      _mapController != null;

  Future<bool> _safeAnimateCamera(CameraUpdate update) async {
    if (!_isMapInValidState()) return false;
    try {
      await _mapController!.animateCamera(update);
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
    _updateMapMarkers();
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
    _updateMapMarkers();
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
      _updateMapMarkers();
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
      _updateMapMarkersWithAllShops();
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

        // Convert to our expected format and validate data
        List<Map<String, dynamic>> validShops = [];

        for (var shop in googlePlacesShops) {
          try {
            // Validate required fields
            if (shop['latitude'] != null &&
                shop['longitude'] != null &&
                shop['name'] != null &&
                shop['placeId'] != null) {
              validShops.add({
                'id': shop['id'] ?? 'google_${shop['placeId']}',
                'placeId': shop['placeId'],
                'name': shop['name'] ?? 'Unknown Shop',
                'businessType': shop['businessType'] ?? 'store',
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

        // Debug: Log unique business types to understand the data
        final uniqueBusinessTypes = validShops
            .map((shop) => shop['businessType']?.toString())
            .where((type) => type != null)
            .toSet()
            .toList();
        print('🔍 Unique business types found: $uniqueBusinessTypes');

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

  void _updateMapMarkersWithAllShops() {
    print('🗺️ Updating map markers with all shops');
    print('📊 Google Places shops count: ${_googlePlacesShops.length}');
    print(
      '📊 Salesman accounts count: ${_getFilteredAccountsForSelectedPincodes().length}',
    );

    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add salesman-created accounts (existing shops)
    if (_showAccounts) {
      for (var account in _getFilteredAccountsForSelectedPincodes()) {
        if (account['latitude'] != null && account['longitude'] != null) {
          try {
            final lat = double.parse(account['latitude'].toString());
            final lng = double.parse(account['longitude'].toString());
            if (!_isValidCoordinate(lat, lng)) continue;

            markers.add(
              Marker(
                markerId: MarkerId('salesman_account_${account['id']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: account['personName'] ?? 'Unknown',
                  snippet:
                      '${account['businessName'] ?? ''} • SR: ${account['salesmanName'] ?? ''} • EXISTING',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  account['isApproved'] == true
                      ? BitmapDescriptor
                            .hueGreen // Green for approved salesman shops
                      : BitmapDescriptor
                            .hueOrange, // Orange for pending salesman shops
                ),
                onTap: () => _showAccountDetails(account),
              ),
            );
          } catch (e) {
            print('❌ Error adding salesman account marker: $e');
          }
        }
      }
    }

    // Add Google Places shops (new potential shops) - only if Places toggle is ON
    if (_showPlaces) {
      print(
        '🟣 Processing ${_googlePlacesShops.length} Google Places shops for markers',
      );
      print('🔍 Filtering by place types: $_selectedPlaceTypes');

      // Filter Google Places shops by selected place types - simplified logic
      final filteredGoogleShops = _googlePlacesShops.where((shop) {
        final shopType = shop['businessType']?.toString().toLowerCase() ?? '';
        if (shopType.isEmpty) return false;

        // Simple direct type matching
        return _selectedPlaceTypes.any((selectedType) {
          final selected = selectedType.toLowerCase();

          // Direct type match
          if (shopType == selected || shopType.contains(selected)) return true;

          // Handle lodging -> hotel mapping
          if (selected == 'lodging' &&
              (shopType.contains('hotel') || shopType.contains('lodging')))
            return true;

          // Handle convenience_store -> grocery/kirana
          if (selected == 'convenience_store' &&
              (shopType.contains('convenience') ||
                  shopType.contains('grocery')))
            return true;

          return false;
        });
      }).toList();

      print('🟣 Filtered to ${filteredGoogleShops.length} shops');

      int googleMarkersAdded = 0;

      for (var shop in filteredGoogleShops) {
        if (shop['latitude'] != null && shop['longitude'] != null) {
          try {
            final lat = _parseDouble(shop['latitude']);
            final lng = _parseDouble(shop['longitude']);

            if (lat == null || lng == null || !_isValidCoordinate(lat, lng))
              continue;

            markers.add(
              Marker(
                markerId: MarkerId('google_shop_${shop['id']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: shop['name'] ?? 'Unknown Shop',
                  snippet: _formatBusinessType(shop['businessType']),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet, // Purple for Google Places shops
                ),
                onTap: () => _showGooglePlaceDetails(shop),
              ),
            );
            googleMarkersAdded++;
            print('✅ Added Google Places marker for ${shop['name']}');
          } catch (e) {
            print(
              '❌ Error adding Google Places marker for ${shop['name']}: $e',
            );
          }
        } else {
          print(
            '⚠️ Skipping Google Place ${shop['name']} - missing coordinates',
          );
        }
      }

      print(
        '🟣 Added $googleMarkersAdded Google Places markers out of ${filteredGoogleShops.length} filtered shops (${_googlePlacesShops.length} total)',
      );

      // Add regular nearby places
      for (int i = 0; i < nearbyPlaces.length; i++) {
        final place = nearbyPlaces[i];
        if (place.latitude != null && place.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('nearby_place_$i'),
              position: LatLng(place.latitude!, place.longitude!),
              infoWindow: InfoWindow(
                title: place.name,
                snippet: 'NEARBY PLACE',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed, // Red for general nearby places
              ),
              onTap: () => _showPlaceDetails(place),
            ),
          );
        }
      }
    } else {
      print('🟣 Places toggle is OFF - skipping Google Places markers');
    }

    setState(() => _markers = markers);
    print('🗺️ Updated map with ${markers.length} markers');
    print('   - Current location: ${_currentPosition != null ? 1 : 0}');
    print(
      '   - Salesman accounts: ${_getFilteredAccountsForSelectedPincodes().length}',
    );
    print('   - Nearby places: ${_showPlaces ? nearbyPlaces.length : 0}');
  }

  List<Map<String, dynamic>> _getFilteredAccountsForSelectedPincodes() {
    if (_selectedPincodes.isEmpty) return [];

    return salesmanAccounts.where((account) {
      final accountPincode = account['pincode']?.toString();
      return accountPincode != null &&
          _selectedPincodes.contains(accountPincode);
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
    _updateMapMarkersForSelectedPincodes();

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
            CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 15),
          );
        } else {
          final bounds = LatLngBounds(
            southwest: LatLng(minLat - 0.01, minLng - 0.01),
            northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
          );
          await _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 13),
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

  void _updateMapMarkersForSelectedPincodes() {
    Set<Marker> markers = {};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    for (var account in salesmanAccounts) {
      final accountPincode = account['pincode']?.toString();
      if (accountPincode != null &&
          _selectedPincodes.contains(accountPincode) &&
          account['latitude'] != null &&
          account['longitude'] != null) {
        try {
          final lat = double.parse(account['latitude'].toString());
          final lng = double.parse(account['longitude'].toString());
          if (_isValidCoordinate(lat, lng)) {
            markers.add(
              Marker(
                markerId: MarkerId('account_${account['id']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: account['personName'] ?? 'Unknown',
                  snippet: account['businessName'] ?? '',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  account['isApproved'] == true
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueOrange,
                ),
                onTap: () => _showAccountDetails(account),
              ),
            );
          }
        } catch (e) {}
      }
    }
    setState(() => _markers = markers);
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
    _updateMapMarkers();
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
                  onMapCreated: (controller) async {
                    if (!mounted || _isControllerDisposed) return;
                    _mapController = controller;
                    _isMapReady = true;
                    _isControllerDisposed = false;
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (salesmanAccounts.isNotEmpty)
                      await _focusOnAccountsArea();
                  },
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
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
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      15,
                    ),
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
                                onPressed: () {
                                  setState(() => _showAccountsList = false);
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
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: primaryColor, size: 18),
              const SizedBox(width: 6),
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
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  title: const Text('Accounts', style: TextStyle(fontSize: 12)),
                  value: _showAccounts,
                  onChanged: (v) {
                    setState(() => _showAccounts = v);
                    _updateMapMarkers();
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
                    setState(() => _showPlaces = v);
                    _updateMapMarkers();
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
          if (_showPlaces) ...[
            const SizedBox(height: 8),
            const Text(
              'Shop Categories',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              height: 100,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _placeTypes.length,
                itemBuilder: (context, index) {
                  final placeType = _placeTypes[index];
                  final isSelected = _selectedPlaceTypes.contains(
                    placeType['type'],
                  );
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPlaceTypes.remove(placeType['type']);
                          // Ensure at least one place type is always selected
                          if (_selectedPlaceTypes.isEmpty) {
                            _selectedPlaceTypes.add('convenience_store');
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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            placeType['icon'],
                            size: 16,
                            color: isSelected ? primaryColor : Colors.grey[600],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            placeType['name'],
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
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
            _buildLegendItem('Google Places', Colors.purple),
            _buildLegendItem('Nearby Places', Colors.red),
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
      constraints: const BoxConstraints(maxHeight: 300, maxWidth: 180),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _selectAllPincodes,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'All',
                          style: TextStyle(fontSize: 9, color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _clearPincodeSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 9, color: Colors.red),
                        ),
                      ),
                    ),
                    if (_isLoadingGooglePlaces) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (_selectedPincodes.isNotEmpty &&
                    _googlePlacesShops.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(4),
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
                const SizedBox(height: 4),
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
              ],
              const SizedBox(height: 8),
            ],
            InkWell(
              onTap: () =>
                  setState(() => _isPincodeCollapsed = !_isPincodeCollapsed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                    if (_selectedPincodes.isNotEmpty)
                      InkWell(
                        onTap: _clearPincodeSelection,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}
