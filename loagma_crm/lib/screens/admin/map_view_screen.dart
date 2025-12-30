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
  List<String> _selectedPlaceTypes = ['store'];
  int _searchRadius = 1500;
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

  List<String> tempSelectedCustomerStages = [];
  List<String> tempSelectedBusinessTypes = [];
  List<String> tempSelectedFunnelStages = [];
  List<String> tempSelectedPincodes = [];
  List<String> tempSelectedAssignedAreas = [];
  bool? tempSelectedApprovalStatus;

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
          } catch (e) {}
        }
      }
    }
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
                BitmapDescriptor.hueViolet,
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
      tempSelectedCustomerStages.clear();
      tempSelectedBusinessTypes.clear();
      tempSelectedFunnelStages.clear();
      tempSelectedPincodes.clear();
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
      selectedApprovalStatus = tempSelectedApprovalStatus;
    });
    _updateMapMarkers();
  }

  bool get _hasFilterChanges =>
      selectedCustomerStages.length != tempSelectedCustomerStages.length ||
      selectedBusinessTypes.length != tempSelectedBusinessTypes.length ||
      selectedFunnelStages.length != tempSelectedFunnelStages.length ||
      selectedPincodes.length != tempSelectedPincodes.length ||
      selectedApprovalStatus != tempSelectedApprovalStatus;
  void _resetTempFilters() {
    setState(() {
      tempSelectedCustomerStages = List.from(selectedCustomerStages);
      tempSelectedBusinessTypes = List.from(selectedBusinessTypes);
      tempSelectedFunnelStages = List.from(selectedFunnelStages);
      tempSelectedPincodes = List.from(selectedPincodes);
      tempSelectedApprovalStatus = selectedApprovalStatus;
    });
  }

  bool _hasActiveFilters() =>
      selectedCustomerStages.isNotEmpty ||
      selectedBusinessTypes.isNotEmpty ||
      selectedFunnelStages.isNotEmpty ||
      selectedPincodes.isNotEmpty ||
      selectedApprovalStatus != null;

  void _onPincodeSelected(String pincode, Map<String, dynamic> pincodeData) {
    print('🎯 Pincode selected: $pincode');
    setState(() {
      if (_selectedPincodes.contains(pincode)) {
        _selectedPincodes.remove(pincode);
      } else {
        _selectedPincodes.add(pincode);
      }
    });
    if (_selectedPincodes.isNotEmpty) {
      _focusOnSelectedPincodes();
    } else {
      _updateMapMarkers();
    }
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
    _focusOnSelectedPincodes();
  }

  void _clearPincodeSelection() {
    setState(() => _selectedPincodes.clear());
    _updateMapMarkers();
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
          child: Row(
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
            _buildLegendItem('Approved', Colors.green),
            _buildLegendItem('Pending', Colors.orange),
            _buildLegendItem('Places', Colors.purple),
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
                  ],
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
