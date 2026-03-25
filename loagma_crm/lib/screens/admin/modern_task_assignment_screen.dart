import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/map_task_assignment_service.dart';
import '../../services/google_places_service.dart';
import '../../models/shop_model.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';
import '../../services/user_service.dart';
import '../../services/api_config.dart';
import '../../services/network_service.dart';
import 'assignment_map_detail_screen.dart';

class ModernTaskAssignmentScreen extends StatefulWidget {
  final int? initialStep;

  const ModernTaskAssignmentScreen({super.key, this.initialStep});

  @override
  State<ModernTaskAssignmentScreen> createState() =>
      _ModernTaskAssignmentScreenState();
}

class _ModernTaskAssignmentScreenState extends State<ModernTaskAssignmentScreen>
    with SingleTickerProviderStateMixin {
  final _service = MapTaskAssignmentService();
  late TabController _tabController;

  // Role selection: default to salesman (existing behavior)
  String _assignmentRole = 'salesman';
  List<String> _assignmentRoles = ['salesman', 'telecaller'];
  final Map<String, String> _assignmentRoleLabels = {
    'salesman': 'Salesman',
    'telecaller': 'Telecaller',
  };

  // Step tracking
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form data
  final _pincodeController = TextEditingController();
  final _salesmanSearchController = TextEditingController();
  String? _selectedSalesmanId;
  String? _selectedSalesmanName;
  List<dynamic> _salesmen = [];
  List<dynamic> _filteredSalesmen = [];
  List<Map<String, dynamic>> _pincodeLocations = [];
  Map<String, List<String>> _selectedAreasByPincode = {};
  Set<String> _selectedBusinessTypes = {};
  Set<String> _mapBusinessTypeFilter = {};
  Set<String> _mapStageFilter = {};
  bool _isLoading = false;
  bool _isFetchingBusinesses = false;

  // Map data
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Shop> _shops = [];
  LatLng _initialPosition = const LatLng(20.5937, 78.9629);

  bool _mapHelpShown = false;
  bool _isFilterExpanded = true; // Add filter collapse state
  Set<String> _expandedPincodes = {}; // Track which pincodes are expanded

  // Telecaller pincode assignment state (all days)
  bool _isLoadingTelecaller = false;
  String? _telecallerError;
  List<Map<String, dynamic>> _telecallers = [];
  String? _selectedTelecallerId;
  // All-day pincodes: pincode -> { count, city?, state?, district?, region? }
  final Map<String, Map<String, dynamic>> _telecallerPincodesAll = {};
  int _telecallerStep = 0; // 0: select telecaller, 1: pincodes
  String? _pincodeFieldError; // validation message for pincode input

  // Place details overlay state (for Google Maps-like interface)
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;

  // Colors
  static const primaryColor = Color(0xFFD7BE69);
  static const secondaryColor = Color(0xFF2C3E50);
  static const accentColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial step if provided
    if (widget.initialStep != null) {
      _currentStep = widget.initialStep!;
      // Navigate to the correct page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(_currentStep);
      });
    }

    _loadSalesmen();
    _loadAssignmentRoles();
  }

  String _normalizeRoleKey(String value) {
    return value.toLowerCase().trim().replaceAll(' ', '');
  }

  String _toRoleLabel(String roleValue) {
    final normalized = roleValue.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (normalized.isEmpty) return 'Role';
    return normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _getRoleFromUser(Map<String, dynamic> user) {
    final roleValue = user['role'];
    if (roleValue is Map && roleValue['name'] != null) {
      final roleName = roleValue['name'].toString().trim();
      if (roleName.isNotEmpty && roleName.toLowerCase() != 'null') {
        return roleName;
      }
    }

    final directRole = (roleValue ?? '').toString().trim();
    if (directRole.isNotEmpty && directRole.toLowerCase() != 'null') {
      return directRole;
    }

    final roleList = user['roles'];
    if (roleList is List && roleList.isNotEmpty) {
      final first = roleList.first;
      if (first is Map && first['name'] != null) {
        return first['name'].toString();
      }
      return first.toString();
    }

    return '';
  }

  bool get _isTelecallerRole => _assignmentRole.contains('telecaller');

  String get _currentRoleLabel {
    return _assignmentRoleLabels[_assignmentRole] ?? _toRoleLabel(_assignmentRole);
  }

  Future<void> _loadAssignmentRoles() async {
    try {
      final usersResult = await UserService.getAllUsers();
      if (usersResult['success'] != true) return;

      final users = (usersResult['data'] as List?) ?? [];
      final roleKeys = <String>{'salesman', 'telecaller'};

      for (final user in users) {
        if (user is! Map) continue;
        final userMap = Map<String, dynamic>.from(user);
        final rawRole = _getRoleFromUser(userMap);
        if (rawRole.isEmpty) continue;

        final roleKey = _normalizeRoleKey(rawRole);
        if (roleKey.isEmpty) continue;

        roleKeys.add(roleKey);
        _assignmentRoleLabels[roleKey] = _toRoleLabel(rawRole);
      }

      final sortedRoles = roleKeys.toList()
        ..sort((a, b) => (_assignmentRoleLabels[a] ?? a)
            .compareTo(_assignmentRoleLabels[b] ?? b));
      final orderedRoles = <String>[];
      if (sortedRoles.remove('salesman')) orderedRoles.add('salesman');
      if (sortedRoles.remove('telecaller')) orderedRoles.add('telecaller');
      orderedRoles.addAll(sortedRoles);

      if (!mounted) return;
      setState(() {
        _assignmentRoles = orderedRoles;
        if (!_assignmentRoles.contains(_assignmentRole)) {
          _assignmentRole = _assignmentRoles.first;
        }
      });
    } catch (_) {
      // Keep fallback defaults when role loading fails.
    }
  }

  Future<void> _loadUsersForRole(String roleKey) async {
    if (!mounted) return;

    if (roleKey == 'salesman') {
      await _loadSalesmen();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final usersResult = await UserService.getAllUsers();
      if (!mounted) return;

      if (usersResult['success'] == true) {
        final users = (usersResult['data'] as List?) ?? [];
        final roleUsers = users.where((user) {
          if (user is! Map) return false;
          final userMap = Map<String, dynamic>.from(user);
          final userRole = _normalizeRoleKey(_getRoleFromUser(userMap));
          return userRole == roleKey;
        }).map((u) => Map<String, dynamic>.from(u as Map)).toList();

        setState(() {
          _salesmen = roleUsers;
          _filteredSalesmen = roleUsers;

          if (_selectedSalesmanId != null &&
              !_salesmen.any((u) => (u['id'] ?? u['_id']) == _selectedSalesmanId)) {
            _selectedSalesmanId = null;
            _selectedSalesmanName = null;
          }
        });
      } else {
        _showError(usersResult['message'] ?? 'Failed to load users for role');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onAssignmentRoleChanged(String roleKey) async {
    if (roleKey == _assignmentRole) return;

    setState(() {
      _assignmentRole = roleKey;
      _currentStep = 0;
      _salesmanSearchController.clear();
      _selectedSalesmanId = null;
      _selectedSalesmanName = null;
    });

    _pageController.jumpToPage(0);

    if (_isTelecallerRole) {
      if (_telecallers.isEmpty && !_isLoadingTelecaller) {
        await _loadTelecallerData();
      }
      return;
    }

    await _loadUsersForRole(roleKey);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pincodeController.dispose();
    _salesmanSearchController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Load salesmen
  Future<void> _loadSalesmen() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _service.fetchSalesmen();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _salesmen = result['salesmen'] ?? [];
          _filteredSalesmen = _salesmen;
        });
      } else {
        _showError(result['message'] ?? 'Failed to load salesmen');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filter salesmen based on search
  void _filterSalesmen(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSalesmen = _salesmen;
      } else {
        _filteredSalesmen = _salesmen.where((salesman) {
          final name = (salesman['name'] ?? '').toLowerCase();
          final code = (salesman['employeeCode'] ?? '').toLowerCase();
          final phone = (salesman['contactNumber'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
              code.contains(searchLower) ||
              phone.contains(searchLower);
        }).toList();
      }
    });
  }

  // Fetch location by pincode
  Future<void> _fetchLocationByPincode() async {
    final pincode = _pincodeController.text.trim();

    if (pincode.length != 6 || int.tryParse(pincode) == null) {
      _showError('Please enter a valid 6-digit pincode');
      return;
    }

    if (_pincodeLocations.any((loc) => loc['pincode'] == pincode)) {
      _showError('Pincode already added');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _service.fetchLocationByPincode(pincode);
      if (result['success'] == true) {
        final locationData = result['data'] ?? result['location'];
        if (locationData != null) {
          // Convert single area to areas array if needed
          final areas = locationData['areas'] ?? [locationData['area']];
          final processedLocation = Map<String, dynamic>.from(locationData);
          processedLocation['areas'] = areas;

          setState(() {
            _pincodeLocations.add(processedLocation);
            _selectedAreasByPincode[pincode] = [];
            _pincodeController.clear();
            // Auto-expand the newly added pincode
            _expandedPincodes.add(pincode);
          });
          _showSuccess('Pincode $pincode added! Tap to select specific areas.');
        } else {
          _showError('Invalid location data received');
        }
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Remove pincode
  void _removePincode(String pincode) {
    setState(() {
      _pincodeLocations.removeWhere((loc) => loc['pincode'] == pincode);
      _selectedAreasByPincode.remove(pincode);
      _expandedPincodes.remove(pincode);
    });
    _showSuccess('Pincode removed');
  }

  // Fetch businesses
  Future<void> _fetchBusinesses() async {
    if (_pincodeLocations.isEmpty) {
      _showError('Please add at least one pincode');
      return;
    }

    if (_selectedBusinessTypes.isEmpty) {
      _showError('Please select at least one business type');
      return;
    }

    setState(() => _isFetchingBusinesses = true);
    try {
      List<Shop> allShops = [];
      Map<String, int> totalBreakdown = {};

      for (var location in _pincodeLocations) {
        final pincode = location['pincode'];
        final selectedAreas = _selectedAreasByPincode[pincode] ?? [];
        final areasToSearch = selectedAreas.isEmpty
            ? (location['areas'] as List).cast<String>()
            : selectedAreas;

        final result = await _service.searchBusinesses(
          pincode,
          areasToSearch,
          _selectedBusinessTypes.toList(),
        );

        if (result['success'] == true) {
          final businesses = result['businesses'] as List?;
          if (businesses != null) {
            for (var business in businesses) {
              try {
                allShops.add(Shop.fromGooglePlaces(business, pincode));
              } catch (e) {
                // ignore invalid shops
                // print('Error parsing business: $e');
              }
            }
          }

          if (result['breakdown'] != null) {
            (result['breakdown'] as Map).forEach((key, value) {
              totalBreakdown[key] =
                  (totalBreakdown[key] ?? 0) + (value as int? ?? 0);
            });
          }
        }
      }

      setState(() => _shops = allShops);

      if (allShops.isEmpty) {
        _showError('No businesses found. Try different business types.');
      } else {
        _showSuccess('Found ${allShops.length} businesses!');
        // Don't auto-select filters - let user choose
        _mapBusinessTypeFilter.clear();
        _mapStageFilter.clear();
        await _updateMapMarkers();
        _tabController.animateTo(2); // Switch to map tab
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isFetchingBusinesses = false);
    }
  }

  // Simple clustering: group shops when zoomed out
  Future<void> _updateMapMarkers() async {
    if (_mapController == null) {
      return;
    }

    double zoom;
    try {
      zoom = await _mapController!.getZoomLevel();
    } catch (_) {
      zoom = 12;
    }

    final markers = <Marker>{};

    // filter shops first
    final filteredShops = _shops.where((shop) {
      if (shop.latitude == null || shop.longitude == null) return false;

      if (_mapBusinessTypeFilter.isNotEmpty &&
          !_mapBusinessTypeFilter.contains(shop.businessType.toLowerCase()))
        return false;

      if (_mapStageFilter.isNotEmpty &&
          !_mapStageFilter.contains(shop.stage.toLowerCase()))
        return false;

      return true;
    }).toList();

    // If zoomed out, cluster by grid
    if (zoom <= 11 && filteredShops.length > 20) {
      final Map<String, List<Shop>> buckets = {};

      for (final shop in filteredShops) {
        final lat = shop.latitude!;
        final lng = shop.longitude!;

        // grid size: 0.1 degree (~11 km) when zoomed out
        final gridLat = (lat * 10).round() / 10.0;
        final gridLng = (lng * 10).round() / 10.0;
        final key = '$gridLat;$gridLng';

        buckets.putIfAbsent(key, () => []).add(shop);
      }

      buckets.forEach((key, shopsInBucket) {
        if (shopsInBucket.isEmpty) return;
        if (shopsInBucket.length == 1) {
          final shop = shopsInBucket.first;
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
        } else {
          final avgLat =
              shopsInBucket.map((s) => s.latitude!).reduce((a, b) => a + b) /
              shopsInBucket.length;
          final avgLng =
              shopsInBucket.map((s) => s.longitude!).reduce((a, b) => a + b) /
              shopsInBucket.length;
          final count = shopsInBucket.length;

          markers.add(
            Marker(
              markerId: MarkerId('cluster_$key'),
              position: LatLng(avgLat, avgLng),
              infoWindow: InfoWindow(
                title: '$count businesses',
                snippet: 'Zoom in to see individual shops',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
        }
      });
    } else {
      // show all individually
      for (var shop in filteredShops) {
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

    setState(() {
      _markers = markers;
      if (filteredShops.isNotEmpty && filteredShops.first.latitude != null) {
        _initialPosition = LatLng(
          filteredShops.first.latitude!,
          filteredShops.first.longitude!,
        );
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, zoom),
        );
      }
    });
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

  // Show shop details as Google Maps-like bottom sheet
  void _showShopDetails(Shop shop) async {
    // Show loading state
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

      // If no Google Places data, create a PlaceInfo from Shop data
      if (placeInfo == null) {
        placeInfo = PlaceInfo(
          placeId: shop.placeId ?? shop.id,
          name: shop.name,
          address: shop.address ?? 'Address not available',
          latitude: shop.latitude,
          longitude: shop.longitude,
          rating: shop.rating ?? 0.0,
          isOpenNow: true,
          priceLevel: 0,
          types: [shop.businessType],
          phoneNumber: shop.phoneNumber,
          website: shop.website,
          photoUrls: shop.photos ?? [],
          reviews: [],
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        // Always show place details as bottom sheet overlay (like Google Maps)
        setState(() {
          _selectedPlace = placeInfo;
          _showPlaceDetailsOverlay = true;
        });
      }
    } catch (e) {
      print('Error loading place details: $e');
      setState(() => _isLoading = false);

      // Create basic PlaceInfo from shop data as fallback
      if (mounted) {
        final fallbackPlaceInfo = PlaceInfo(
          placeId: shop.placeId ?? shop.id,
          name: shop.name,
          address: shop.address ?? 'Address not available',
          latitude: shop.latitude,
          longitude: shop.longitude,
          rating: shop.rating ?? 0.0,
          isOpenNow: true,
          priceLevel: 0,
          types: [shop.businessType],
          phoneNumber: shop.phoneNumber,
          website: shop.website,
          photoUrls: shop.photos ?? [],
          reviews: [],
        );
        setState(() {
          _selectedPlace = fallbackPlaceInfo;
          _showPlaceDetailsOverlay = true;
        });
      }
    }
  }

  // Assign areas
  Future<void> _assignAreas() async {
    if (_selectedSalesmanId == null) {
      _showError('Please select a ${_currentRoleLabel.toLowerCase()}');
      return;
    }

    if (_pincodeLocations.isEmpty) {
      _showError('Please add at least one pincode');
      return;
    }

    if (_shops.isEmpty) {
      _showError('Please fetch businesses before assigning');
      return;
    }

    // Store counts before starting
    final pincodeCount = _pincodeLocations.length;
    final businessCount = _shops.length;
    final salesmanName = _selectedSalesmanName;

    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Assigning Areas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Processing $pincodeCount pincode(s) with $businessCount businesses...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait, this may take a moment',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      int successCount = 0;

      for (var location in _pincodeLocations) {
        final pincode = location['pincode'];
        final selectedAreas = _selectedAreasByPincode[pincode] ?? [];
        final areasToAssign = selectedAreas.isEmpty
            ? (location['areas'] as List).cast<String>()
            : selectedAreas;

        // Count businesses for this pincode
        final businessesForPincode = _shops
            .where((shop) => shop.pincode == pincode)
            .length;

        print('📤 Sending assignment request:');
        print('   Salesman: $_selectedSalesmanId ($_selectedSalesmanName)');
        print('   Pincode: $pincode');
        print('   Areas: $areasToAssign');
        print('   Business Types: ${_selectedBusinessTypes.toList()}');
        print('   Total Businesses: $businessesForPincode');

        final result = await _service.assignAreasToSalesman(
          _selectedSalesmanId!,
          _selectedSalesmanName!,
          pincode,
          location['country'] ?? '',
          location['state'] ?? '',
          location['district'] ?? '',
          location['city'] ?? '',
          areasToAssign,
          _selectedBusinessTypes.toList(),
          totalBusinesses: businessesForPincode,
        );

        print('📥 Assignment result: $result');

        if (result['success'] == true) {
          successCount++;
          print('✅ Assignment successful for pincode $pincode');
        } else {
          print(
            '❌ Assignment failed for pincode $pincode: ${result['message']}',
          );
        }
      }

      if (_shops.isNotEmpty) {
        await _service.saveShops(_shops, _selectedSalesmanId!);
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Reset form first
      _resetForm();

      // Then show success dialog with stored counts
      print(
        '✅Task Assignment Successfully : $successCount/$pincodeCount pincodes assigned successfully',
      );
      _showSuccessDialog(
        'Task Assignment Successfully!',
        'Successfully assigned $pincodeCount pincode(s) with $businessCount businesses to $salesmanName',
      );
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);
      _showError('Error: $e');
    }
  }

  // Reset form (keep salesman selected to view assignments)
  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _pincodeController.clear();
      // Keep salesman selected: _selectedSalesmanId and _selectedSalesmanName
      _pincodeLocations = [];
      _selectedAreasByPincode = {};
      _selectedBusinessTypes = {};
      _shops = [];
      _markers = {};
    });
    _pageController.jumpToPage(0);
    // Switch to assignments tab to show the new assignment
    _tabController.animateTo(1);
  }

  // Show error
  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  // Show success
  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // Show success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Validate and go to next step
  void _nextStep() {
    // Step 0: Salesman selection
    if (_currentStep == 0) {
      if (_selectedSalesmanId == null) {
        _showError('Please select a ${_currentRoleLabel.toLowerCase()}');
        return;
      }
    }

    // Step 1: Pincode selection
    if (_currentStep == 1) {
      if (_pincodeLocations.isEmpty) {
        _showError('Please add at least one pincode');
        return;
      }
    }

    // Step 2: Business types and fetch
    if (_currentStep == 2) {
      if (_selectedBusinessTypes.isEmpty) {
        _showError('Please select at least one business type');
        return;
      }
      if (_shops.isEmpty) {
        _showError('Please click "Fetch Businesses" before continuing');
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Check if current step is valid
  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedSalesmanId != null;
      case 1:
        return _pincodeLocations.isNotEmpty;
      case 2:
        return _selectedBusinessTypes.isNotEmpty && _shops.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  // Go to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select $_currentRoleLabel';
      case 1:
        return 'Add Pincodes';
      case 2:
        return 'Select Business Types';
      case 3:
        return 'Review & Assign';
      default:
        return '';
    }
  }

  String _ctaLabel() {
    if (_currentStep == 0) {
      return _selectedSalesmanId == null
          ? 'Select $_currentRoleLabel to Continue'
          : 'Continue';
    }
    if (_currentStep == 1) {
      return _pincodeLocations.isEmpty ? 'Add Pincode to Continue' : 'Continue';
    }
    if (_currentStep == 2) {
      return _shops.isEmpty ? 'Fetch Businesses First' : 'Continue to Review';
    }
    return 'Assign';
  }

  Widget _instructionBanner() {
    String text = '';
    switch (_currentStep) {
      case 0:
        text =
            'Step 1: Choose a ${_currentRoleLabel.toLowerCase()}. You must select one to go ahead.';
        break;
      case 1:
        text =
            'Step 2: Add pincodes, then tap each pincode card to expand and select specific areas (or leave unselected to assign all areas).';
        break;
      case 2:
        text =
            'Step 3: Select business types and tap "Fetch Businesses" to load them on the map.';
        break;
      case 3:
        text = 'Step 4: Review everything and click Assign to finalize.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Task Assignment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (!_isTelecallerRole && _selectedSalesmanName != null)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSalesmanName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Assign'),
            Tab(text: 'Assignments'),
            Tab(text: 'Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // 🚫 disable horizontal swipe gesture

        children: [_buildAssignTab(), _buildAssignmentsTab(), _buildMapTab()],
      ),
    );
  }

  Widget _buildAssignTab() {
    return Column(
      children: [
        // Role selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _assignmentRole,
            decoration: InputDecoration(
              labelText: 'Select Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _assignmentRoles.map((roleKey) {
              return DropdownMenuItem<String>(
                value: roleKey,
                child: Text(
                  _assignmentRoleLabels[roleKey] ?? _toRoleLabel(roleKey),
                ),
              );
            }).toList(),
            onChanged: (role) {
              if (role == null) return;
              _onAssignmentRoleChanged(role);
            },
          ),
        ),
        if (_isTelecallerRole)
          // Telecaller: simple 2-step shell (Step 1: telecaller, Step 2: days+pincodes)
          Expanded(
            child: Column(
              children: [
                // Progress bar (2 steps)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: List.generate(2, (index) {
                      final isActive = index <= _telecallerStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive ? primaryColor : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (index < 1) const SizedBox(width: 4),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                // Step header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_telecallerStep + 1} of 2',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      Text(
                        _getTelecallerStepTitle(_telecallerStep),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Simple instruction banner
                Container(
                  width: double.infinity,
                  color: Colors.yellow[50],
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _telecallerStep == 0
                              ? 'Step 1: Choose a telecaller to assign pincodes.'
                              : 'Step 2: Select days and pincodes, then save assignments for that day.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: _buildTelecallerAssignmentBody()),
                // Navigation (Back / Next)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_telecallerStep > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previousTelecallerStep,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: primaryColor),
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ),
                      if (_telecallerStep > 0) const SizedBox(width: 16),
                      if (_telecallerStep == 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTelecallerStepValid()
                                ? _nextTelecallerStep
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Progress indicator
          Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 3) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
        ),
        // Step indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 4',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
              Text(
                _getStepTitle(_currentStep),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        _instructionBanner(),
        // Content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSalesmanStep(),
              _buildPincodeStep(),
              _buildBusinessTypesStep(),
              _buildReviewStep(),
            ],
          ),
        ),
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: primaryColor),
                      foregroundColor: primaryColor,
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentStep == 0 ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: _isCurrentStepValid()
                      ? (_currentStep == 3 ? _assignAreas : _nextStep)
                      : null,
                  icon: Icon(
                    _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                  ),
                  label: Text(_ctaLabel()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == 3
                        ? Colors.green
                        : primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ],
    );
  }

  // ---------------- Telecaller assignment helpers ----------------

  Future<void> _loadTelecallerData() async {
    setState(() {
      _isLoadingTelecaller = true;
      _telecallerError = null;
      _telecallerStep = 0;
    });
    try {
      // Load all users and filter telecallers
      final usersResult = await UserService.getAllUsers();
      final users =
          List<Map<String, dynamic>>.from(usersResult['data'] ?? const []);
      final telecallers = users.where((u) {
        final role =
            (u['role'] ?? u['roleId'] ?? '').toString().toLowerCase();
        return role.contains('telecaller');
      }).toList();

      if (!mounted) return;
      setState(() {
        _telecallers = telecallers.cast<Map<String, dynamic>>();
        _telecallerPincodesAll.clear();
        if (_telecallers.isNotEmpty) {
          _selectedTelecallerId =
              _telecallers.first['id'] ?? _telecallers.first['_id'];
        }
      });

      // Load existing pincodes for default telecaller (all days)
      if (_selectedTelecallerId != null) {
        await _loadTelecallerAllPincodes(_selectedTelecallerId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _telecallerError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTelecaller = false;
        });
      }
    }
  }

  void _addTelecallerPincodeForDay() {
    final pin = _pincodeController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pincodeFieldError = 'Enter a 6-digit pincode');
      return;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() => _pincodeFieldError = 'Pincode must be exactly 6 digits');
      return;
    }
    setState(() => _pincodeFieldError = null);
    if (_telecallerPincodesAll.containsKey(pin)) {
      _showError('Pincode already added for this telecaller');
      return;
    }
    _fetchTelecallerPincodeLocation(pin);
  }

  void _onTelecallerPincodeFieldChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _pincodeFieldError = null);
      return;
    }
    if (trimmed.length > 6) return;
    setState(() {
      _pincodeFieldError = trimmed.length < 6
          ? 'Enter ${6 - trimmed.length} more digit(s)'
          : (int.tryParse(trimmed) == null ? 'Pincode must be numeric' : null);
    });
  }

  Future<void> _fetchTelecallerPincodeLocation(String pincode) async {
    setState(() => _isLoadingTelecaller = true);
    try {
      final result = await _service.fetchLocationByPincode(pincode);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        int count = 0;
        try {
          final countResult =
              await _service.getAccountCountByPincode(pincode);
          if (countResult['success'] == true &&
              countResult['data'] != null &&
              countResult['data']['count'] != null) {
            count = int.tryParse(
                    countResult['data']['count'].toString()) ??
                0;
          }
        } catch (_) {
          // ignore count errors, keep 0
        }

        setState(() {
          _telecallerPincodesAll[pincode] = {
            'count': count,
            'city': data['city']?.toString(),
            'state': data['state']?.toString(),
            'district': data['district']?.toString(),
            'region': data['region']?.toString(),
            'country': data['country']?.toString(),
            'areas': data['areas'],
          };
          _pincodeController.clear();
          _pincodeFieldError = null;
        });
        final loc = [
          data['city'],
          data['district'],
          data['state'],
        ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
        _showSuccess(
            'Pincode $pincode added. Accounts: $count${loc.isNotEmpty ? ' • $loc' : ''}');
      } else {
        _showError(result['message'] ?? 'Pincode not found');
      }
    } catch (e) {
      _showError('Error validating pincode: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTelecaller = false);
      }
    }
  }

  Future<void> _loadTelecallerAllPincodes(String telecallerId) async {
    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
        '${ApiConfig.teleadminUrl}/telecallers/$telecallerId/pincode-assignments',
      );

      final response = await NetworkService.retryApiCall(
        () => http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15)),
        maxRetries: 1,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> rows = data['data'] ?? [];
        final Set<String> pins = {};
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row as Map);
          final pin = (map['pincode'] ?? '').toString();
          final day = int.tryParse(map['dayOfWeek']?.toString() ?? '0') ?? 0;
          // Consider only all-day (0) or, for legacy, any day
          if (pin.isEmpty) continue;
          if (day == 0 || day >= 1 && day <= 7) {
            pins.add(pin);
          }
        }

        // Fetch counts for each pincode (details loaded when user adds pincode)
        final Map<String, Map<String, dynamic>> updated = {};
        for (final pin in pins) {
          int count = 0;
          try {
            final countResult =
                await _service.getAccountCountByPincode(pin);
            if (countResult['success'] == true &&
                countResult['data'] != null &&
                countResult['data']['count'] != null) {
              count = int.tryParse(
                      countResult['data']['count'].toString()) ??
                  0;
            }
          } catch (_) {}
          updated[pin] = {'count': count};
        }

        if (!mounted) return;
        setState(() {
          _telecallerPincodesAll
            ..clear()
            ..addAll(updated);
        });
      }
    } catch (e) {
      // Silent failure – just don't pre-fill if something goes wrong
      debugPrint('⚠️ _loadTelecallerAllPincodes error: $e');
    }
  }
  Future<void> _saveTelecallerAssignments() async {
    if (_selectedTelecallerId == null) {
      _showError('Select a telecaller');
      return;
    }

    final currentPins = _telecallerPincodesAll.keys.toList()..sort();
    if (currentPins.isEmpty) {
      _showError('Add at least one pincode to save');
      return;
    }

    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final body = {
        'pincodes': currentPins,
      };

      final uri = Uri.parse(
        '${ApiConfig.teleadminUrl}/telecallers/$_selectedTelecallerId/pincodes',
      );

      final response = await NetworkService.retryApiCall(
        () => http
            .put(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15)),
        maxRetries: 1,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        final savedCount = data['data']?['count'] ?? currentPins.length;
        final successMessage =
            'Assignments saved successfully. Total pincodes: $savedCount';
        _showSuccess(successMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to save assignments');
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = 'Failed to save assignments: $e';
      _showError(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getTelecallerStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Telecaller';
      case 1:
      default:
        return 'Pincodes';
    }
  }

  bool _isTelecallerStepValid() {
    if (_telecallerStep == 0) {
      return _selectedTelecallerId != null;
    }
    // Step 1 (pincodes) – allow save even with zero pincodes (handled in save)
    return true;
  }

  void _nextTelecallerStep() {
    if (_telecallerStep < 1 && _isTelecallerStepValid()) {
      setState(() {
        _telecallerStep++;
      });
    }
  }

  void _previousTelecallerStep() {
    if (_telecallerStep > 0) {
      setState(() {
        _telecallerStep--;
      });
    }
  }

  Widget _buildTelecallerAssignmentBody() {
    if (_isLoadingTelecaller) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_telecallerError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _telecallerError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _telecallerStep == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a telecaller to assign pincodes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTelecallerId,
                  decoration: const InputDecoration(
                    labelText: 'Telecaller',
                    border: OutlineInputBorder(),
                  ),
                  items: _telecallers
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u['id'] ?? u['_id'],
                          child: Text(u['name'] ?? 'Unknown'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) async {
                    setState(() {
                      _selectedTelecallerId = val;
                      _telecallerPincodesAll.clear();
                    });
                    if (val != null) {
                      await _loadTelecallerAllPincodes(val);
                    }
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add pincodes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: _onTelecallerPincodeFieldChanged,
                        decoration: InputDecoration(
                          labelText: 'Enter 6-digit pincode',
                          hintText: 'e.g. 123456',
                          border: const OutlineInputBorder(),
                          errorText: _pincodeFieldError,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoadingTelecaller ? null : _addTelecallerPincodeForDay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pincodes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final entries = _telecallerPincodesAll.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                      final pins = entries.map((e) => e.key).toList();
                      if (pins.isEmpty) {
                        return const Center(
                          child: Text(
                            'No pincodes added yet. Use the field above to add.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: pins.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final pin = entry.key;
                          final info = entry.value;
                          final count = (info['count'] is int)
                              ? info['count'] as int
                              : int.tryParse(info['count']?.toString() ?? '0') ?? 0;
                          final city = info['city']?.toString();
                          final state = info['state']?.toString();
                          final district = info['district']?.toString();
                          final region = info['region']?.toString();
                          final areas = info['areas'];
                          final areaCount = areas is List ? areas.length : 0;
                          final locationParts = [
                            if (city != null && city.isNotEmpty) city,
                            if (district != null && district.isNotEmpty) district,
                            if (state != null && state.isNotEmpty) state,
                           
                          ];
                          final locationLine = locationParts.join(' • ');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.2),
                                child: const Icon(Icons.pin_drop, color: primaryColor),
                              ),
                              title: Text(
                                pin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Accounts: $count'),
                                    if (locationLine.isNotEmpty)
                                      Text(
                                        locationLine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    if (areaCount > 0)
                                      Text(
                                        '$areaCount area(s)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _telecallerPincodesAll.remove(pin);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTelecallerAssignments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Save Assignments',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSalesmanStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a ${_currentRoleLabel.toLowerCase()} to assign tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // Search field
          TextField(
            controller: _salesmanSearchController,
            decoration: InputDecoration(
              labelText: 'Search $_currentRoleLabel',
              hintText: 'Search by name, code, or phone',
              prefixIcon: const Icon(Icons.search, color: primaryColor),
              suffixIcon: _salesmanSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _salesmanSearchController.clear();
                        _filterSalesmen('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _filterSalesmen,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredSalesmen.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _salesmen.isEmpty
                        ? 'No $_currentRoleLabel found'
                        : 'No matching $_currentRoleLabel',
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_filteredSalesmen.map((salesman) {
              final salesmanId = salesman['id'] ?? salesman['_id'];
              final isSelected = _selectedSalesmanId == salesmanId;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: isSelected
                        ? primaryColor
                        : Colors.grey[300],
                    child: Text(
                      (salesman['name'] ?? 'S')[0].toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    salesman['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Code: ${salesman['employeeCode'] ?? 'N/A'}'),
                      if (salesman['contactNumber'] != null)
                        Text('Phone: ${salesman['contactNumber']}'),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey,
                        ),
                  onTap: () {
                    setState(() {
                      _selectedSalesmanId = salesmanId;
                      _selectedSalesmanName = salesman['name'];
                    });
                  },
                ),
              );
            }).toList()),
        ],
      ),
    );
  }

  Widget _buildPincodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add pincodes to assign',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Enter Pincode',
                        hintText: '6-digit pincode',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _fetchLocationByPincode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_pincodeLocations.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Added Pincodes (${_pincodeLocations.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap cards to expand',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._pincodeLocations.map((location) {
              final pincode = location['pincode'];
              final areas = (location['areas'] as List).cast<String>();
              final selectedAreas = _selectedAreasByPincode[pincode] ?? [];
              final isExpanded = _expandedPincodes.contains(pincode);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isExpanded ? primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ExpansionTile(
                  key: Key(pincode),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedPincodes.add(pincode);
                      } else {
                        _expandedPincodes.remove(pincode);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: isExpanded
                        ? primaryColor
                        : Colors.grey[400],
                    child: Icon(
                      isExpanded ? Icons.location_city : Icons.location_on,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$pincode - ${location['city']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpanded ? primaryColor : Colors.black,
                          ),
                        ),
                      ),
                      if (selectedAreas.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedAreas.length} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${location['state']}, ${location['district']}'),
                      if (!isExpanded)
                        Text(
                          '👆 Tap to select specific areas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePincode(pincode),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Areas (${areas.length} available)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: areas.isNotEmpty &&
                                selectedAreas.length == areas.length,
                            title: const Text('Select All Areas'),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                _selectedAreasByPincode[pincode] ??= [];
                                if (value == true) {
                                  _selectedAreasByPincode[pincode] = List<String>.from(
                                    areas,
                                  );
                                } else {
                                  _selectedAreasByPincode[pincode] = [];
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: areas.map((area) {
                              final isSelected = selectedAreas.contains(area);
                              return FilterChip(
                                label: Text(area),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedAreasByPincode[pincode] ??= [];
                                    if (selected) {
                                      if (!_selectedAreasByPincode[pincode]!
                                          .contains(area)) {
                                        _selectedAreasByPincode[pincode]!.add(
                                          area,
                                        );
                                      }
                                    } else {
                                      _selectedAreasByPincode[pincode]!.remove(
                                        area,
                                      );
                                    }
                                  });
                                },
                                selectedColor: primaryColor.withOpacity(0.3),
                                checkmarkColor: primaryColor,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedAreas.isEmpty
                                ? 'All areas will be assigned'
                                : '${selectedAreas.length} area(s) selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Add pincodes to assign areas to the salesman',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypesStep() {
    final businessTypes = [
      {'name': 'Kirana', 'icon': Icons.shopping_cart},
      {'name': 'Cafe', 'icon': Icons.local_cafe},
      {'name': 'Hotel', 'icon': Icons.hotel},
      {'name': 'Dairy', 'icon': Icons.local_drink},
      {'name': 'Restaurant', 'icon': Icons.restaurant},
      {'name': 'Bakery', 'icon': Icons.bakery_dining},
      {'name': 'Pharmacy', 'icon': Icons.local_pharmacy},
      {'name': 'Supermarket', 'icon': Icons.store},
      {'name': 'Hostel', 'icon': Icons.bed},
      {'name': 'Schools', 'icon': Icons.school},
      {'name': 'Colleges', 'icon': Icons.account_balance},
      {'name': 'Hospitals', 'icon': Icons.local_hospital},
      {'name': 'Others', 'icon': Icons.business},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select business types to fetch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: After selecting types, click "Fetch Businesses" before continuing.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: businessTypes.length,
            itemBuilder: (context, index) {
              final type = businessTypes[index];
              final typeName = type['name'] as String;
              final typeIcon = type['icon'] as IconData;
              final isSelected = _selectedBusinessTypes.contains(
                typeName.toLowerCase(),
              );

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedBusinessTypes.remove(typeName.toLowerCase());
                    } else {
                      _selectedBusinessTypes.add(typeName.toLowerCase());
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        typeIcon,
                        color: isSelected ? primaryColor : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        typeName,
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (_selectedBusinessTypes.isNotEmpty) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Selected Business Types:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedBusinessTypes
                          .map((e) => e[0].toUpperCase() + e.substring(1))
                          .join(', '),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFetchingBusinesses ? null : _fetchBusinesses,
                icon: _isFetchingBusinesses
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isFetchingBusinesses
                      ? 'Fetching Businesses...'
                      : 'Add Businesses',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (_shops.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 48, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_shops.length} Businesses Found',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'You can now move to review or check them on the map.',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review assignment details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignment Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    Icons.person,
                    'Salesman',
                    _selectedSalesmanName ?? 'Not selected',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.location_on,
                    'Pincodes',
                    '${_pincodeLocations.length} pincode(s)',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.category,
                    'Business Types',
                    '${_selectedBusinessTypes.length} type(s)',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.store,
                    'Total Businesses',
                    '${_shops.length} businesses',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_pincodeLocations.isNotEmpty) ...[
            const Text(
              'Pincode Details:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._pincodeLocations.map((location) {
              final pincode = location['pincode'];
              final selectedAreas = _selectedAreasByPincode[pincode] ?? [];
              final totalAreas = (location['areas'] as List).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.pin_drop, color: Colors.white),
                  ),
                  title: Text('$pincode - ${location['city']}'),
                  subtitle: Text(
                    selectedAreas.isEmpty
                        ? 'All $totalAreas areas'
                        : '${selectedAreas.length} of $totalAreas areas',
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ====================== MAP TAB ======================

  void _showMapHelp() {
    if (_mapHelpShown) return;
    _mapHelpShown = true;

    Future.microtask(() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('How to use the map'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Pinch with two fingers to zoom in/out.'),
              Text('• Drag with one finger to move around.'),
              Text('• Tap a marker to view shop details.'),
              Text('• Use the filters at top to refine markers.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMapTab() {
    if (_shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No businesses to display',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetch businesses from the Assign tab',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final filteredShopsCount = _shops.where((shop) {
      if (_mapBusinessTypeFilter.isNotEmpty &&
          !_mapBusinessTypeFilter.contains(shop.businessType.toLowerCase())) {
        return false;
      }
      if (_mapStageFilter.isNotEmpty &&
          !_mapStageFilter.contains(shop.stage.toLowerCase())) {
        return false;
      }
      return true;
    }).length;

    WidgetsBinding.instance.addPostFrameCallback((_) => _showMapHelp());

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 12,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            _updateMapMarkers();
          },

          // Fixed gesture recognizers - each type only once
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
          },

          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          zoomControlsEnabled: false,
          onTap: (_) {
            // Close place details overlay when tapping on map
            if (_showPlaceDetailsOverlay) {
              setState(() {
                _showPlaceDetailsOverlay = false;
                _selectedPlace = null;
              });
            }
          },
        ),
        // Filters
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with collapse/expand button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (_isFilterExpanded &&
                            (_mapBusinessTypeFilter.isNotEmpty ||
                                _mapStageFilter.isNotEmpty))
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _mapBusinessTypeFilter.clear();
                                _mapStageFilter.clear();
                                _updateMapMarkers();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: const Text(
                              'Clear Filters',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        Icon(
                          _isFilterExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: primaryColor,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        // Stage Filter (Funnel)
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Stage:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildStageFilterChip('New', 'new', Colors.yellow),
                            _buildStageFilterChip(
                              'Lead',
                              'lead',
                              Colors.orange,
                            ),
                            _buildStageFilterChip(
                              'Prospect',
                              'prospect',
                              Colors.blue,
                            ),
                            _buildStageFilterChip(
                              'Follow-up',
                              'follow-up',
                              Colors.cyan,
                            ),
                            _buildStageFilterChip(
                              'Converted',
                              'converted',
                              Colors.green,
                            ),
                            _buildStageFilterChip('Lost', 'lost', Colors.red),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        // Business Type Filter
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Business Type: ${_mapBusinessTypeFilter.isEmpty ? "All" : "${_mapBusinessTypeFilter.length} selected"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_selectedBusinessTypes.isNotEmpty) ...[
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_mapBusinessTypeFilter.length ==
                                        _selectedBusinessTypes.length) {
                                      _mapBusinessTypeFilter.clear();
                                    } else {
                                      _mapBusinessTypeFilter = Set.from(
                                        _selectedBusinessTypes,
                                      );
                                    }
                                    _updateMapMarkers();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _mapBusinessTypeFilter.length ==
                                          _selectedBusinessTypes.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedBusinessTypes.map((type) {
                            final isSelected = _mapBusinessTypeFilter.contains(
                              type,
                            );
                            return FilterChip(
                              label: Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _mapBusinessTypeFilter.add(type);
                                  } else {
                                    _mapBusinessTypeFilter.remove(type);
                                  }
                                  _updateMapMarkers();
                                });
                              },
                              selectedColor: primaryColor.withOpacity(0.3),
                              checkmarkColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _mapBusinessTypeFilter.isEmpty &&
                                    _mapStageFilter.isEmpty
                                ? Colors.blue[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  _mapBusinessTypeFilter.isEmpty &&
                                      _mapStageFilter.isEmpty
                                  ? Colors.blue[200]!
                                  : Colors.green[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _mapBusinessTypeFilter.isEmpty &&
                                        _mapStageFilter.isEmpty
                                    ? Icons.info_outline
                                    : Icons.check_circle_outline,
                                size: 14,
                                color:
                                    _mapBusinessTypeFilter.isEmpty &&
                                        _mapStageFilter.isEmpty
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _mapBusinessTypeFilter.isEmpty &&
                                          _mapStageFilter.isEmpty
                                      ? 'Showing all $filteredShopsCount businesses'
                                      : 'Filtered: $filteredShopsCount of ${_shops.length} businesses',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        _mapBusinessTypeFilter.isEmpty &&
                                            _mapStageFilter.isEmpty
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Place Details Overlay (Google Maps-like bottom sheet)
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
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        SizedBox(height: 16),
                        Text('Loading place details...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Floating button to jump to Step 4 (only show when place details not visible)
        if (!_showPlaceDetailsOverlay)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Jump directly to step 4 (review and assign) - same logic as _nextStep()
                setState(() {
                  _currentStep = 3; // Step 4 (0-indexed)
                });
                // Switch back to Assign tab first
                _tabController.animateTo(0);
                // Then animate to the correct page
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'Next',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 2,
              heroTag: "mapToStep4", // Unique hero tag to avoid conflicts
            ),
          ),
      ],
    );
  }

  Widget _buildStageFilterChip(String label, String value, Color color) {
    final isSelected = _mapStageFilter.contains(value);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _mapStageFilter.add(value);
          } else {
            _mapStageFilter.remove(value);
          }
          _updateMapMarkers();
        });
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Delete assignment
  Future<void> _deleteAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Assignment'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the assignment for ${assignment['city']}, ${assignment['pincode']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await _service.deleteAssignment(assignment['id']);
      if (result['success'] == true) {
        _showSuccess('Assignment deleted successfully');
        setState(() {}); // Refresh the list
      } else {
        _showError(result['message'] ?? 'Failed to delete assignment');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // View assignment on map
  void _viewAssignmentOnMap(Map<String, dynamic> assignment) {
    // Navigate to a map view showing this specific assignment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentMapViewScreen(
          assignment: assignment,
          salesmanName: _selectedSalesmanName ?? 'Salesman',
        ),
      ),
    );
  }

  // Edit assignment
  Future<void> _editAssignment(Map<String, dynamic> assignment) async {
    final currentAreas = (assignment['areas'] as List).cast<String>();
    final currentBusinessTypes = (assignment['businessTypes'] as List)
        .cast<String>();
    final pincode = assignment['pincode'];

    // Show loading dialog while fetching areas
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading areas...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Fetch all available areas for this pincode
    List<String> availableAreas = [];
    try {
      final locationResult = await _service.fetchLocationByPincode(pincode);
      if (locationResult['success'] == true) {
        final locationData =
            locationResult['data'] ?? locationResult['location'];
        if (locationData != null) {
          final areas = locationData['areas'] ?? [locationData['area']];
          availableAreas = areas.cast<String>();
        }
      }
    } catch (e) {
      print('Error fetching areas: $e');
    }

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (availableAreas.isEmpty) {
      _showError('Could not load areas for pincode $pincode');
      return;
    }

    // Show edit dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditAssignmentDialog(
        assignment: assignment,
        availableAreas: availableAreas,
        currentAreas: currentAreas,
        currentBusinessTypes: currentBusinessTypes,
      ),
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      final updateResult = await _service.updateAssignment(
        assignment['id'],
        result,
      );
      if (updateResult['success'] == true) {
        _showSuccess('Assignment updated successfully');
        setState(() {}); // Refresh the list
      } else {
        _showError(updateResult['message'] ?? 'Failed to update assignment');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAssignmentsTab() {
    if (_selectedSalesmanId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No salesman selected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a salesman from the Assign tab',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Use a key to force rebuild when switching tabs
    return FutureBuilder(
      key: ValueKey('assignments_$_selectedSalesmanId'),
      future: _service.getAssignmentsBySalesman(_selectedSalesmanId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text(
                  'Error loading assignments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!['success'] != true ||
            (snapshot.data!['assignments'] as List).isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No assignments found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assign tasks to $_selectedSalesmanName',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final assignments = snapshot.data!['assignments'] as List;

        // Calculate totals
        final totalPincodes = assignments.length;
        final totalAreas = assignments.fold<int>(
          0,
          (sum, a) => sum + (a['areas'] as List).length,
        );
        final totalBusinesses = assignments.fold<int>(
          0,
          (sum, a) => sum + (a['totalBusinesses'] as int? ?? 0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: primaryColor,
                            child: Text(
                              (_selectedSalesmanName ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSalesmanName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Assignment Summary',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryStatItem(
                            Icons.pin_drop,
                            totalPincodes.toString(),
                            'Pincodes',
                          ),
                          _buildSummaryStatItem(
                            Icons.location_on,
                            totalAreas.toString(),
                            'Areas',
                          ),
                          _buildSummaryStatItem(
                            Icons.store,
                            totalBusinesses.toString(),
                            'Businesses',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _viewAllAssignmentsOnMap(assignments),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.map, size: 24),
                          label: const Text(
                            'View All on Map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Assigned Pincodes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Pincode List
              ...assignments.map((assignment) {
                final areas = (assignment['areas'] as List).cast<String>();
                final businessTypes = (assignment['businessTypes'] as List)
                    .cast<String>();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${assignment['city']}, ${assignment['state']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pincode: ${assignment['pincode']} • ${areas.length} areas • ${assignment['totalBusinesses'] ?? 0} businesses',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _editAssignment(assignment),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteAssignment(assignment),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAssignmentDetail(
                              Icons.map,
                              'Areas',
                              areas.join(', '),
                            ),
                            const SizedBox(height: 8),
                            _buildAssignmentDetail(
                              Icons.business,
                              'Business Types',
                              businessTypes.isEmpty
                                  ? 'All types'
                                  : businessTypes.join(', '),
                            ),
                            const SizedBox(height: 8),
                            _buildAssignmentDetail(
                              Icons.calendar_today,
                              'Assigned Date',
                              assignment['assignedDate'] != null
                                  ? DateTime.parse(
                                      assignment['assignedDate'],
                                    ).toString().split(' ')[0]
                                  : 'N/A',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _viewAssignmentOnMap(assignment),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: const BorderSide(color: primaryColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('View This Pincode on Map'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // View all assignments on map
  void _viewAllAssignmentsOnMap(List<dynamic> assignments) {
    // Navigate to map view showing all assignments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentMapViewScreen(
          assignment: {
            'salesmanName': _selectedSalesmanName,
            'salesmanId': _selectedSalesmanId, // Add salesmanId
            'assignments': assignments,
            'isMultiple': true,
          },
          salesmanName: _selectedSalesmanName ?? 'Salesman',
        ),
      ),
    );
  }

  Widget _buildAssignmentDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
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
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhanced Shop Details Dialog Widget
class EnhancedShopDetailsDialog extends StatefulWidget {
  final Shop shop;

  const EnhancedShopDetailsDialog({super.key, required this.shop});

  @override
  State<EnhancedShopDetailsDialog> createState() =>
      _EnhancedShopDetailsDialogState();
}

class _EnhancedShopDetailsDialogState extends State<EnhancedShopDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Shop? _enhancedShop;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _enhancedShop = widget.shop;
    _loadGooglePlacesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGooglePlacesData() async {
    if (widget.shop.placeId == null) return;

    setState(() => _isLoading = true);

    try {
      final placeDetails = await GooglePlacesService.getPlaceDetails(
        widget.shop.placeId!,
      );

      if (placeDetails != null && mounted) {
        final reviews = GooglePlacesService.formatReviews(
          placeDetails['reviews'],
        );
        final photos = GooglePlacesService.formatPhotos(placeDetails['photos']);
        final openingHours = GooglePlacesService.getOpeningHours(
          placeDetails['opening_hours'],
        );

        setState(() {
          _enhancedShop = widget.shop.copyWithGooglePlacesData(
            reviews: reviews,
            photos: photos,
            website: placeDetails['website'],
            openingHours: openingHours,
            priceLevel: placeDetails['price_level'],
            formattedPhoneNumber: placeDetails['formatted_phone_number'],
          );
        });
      }
    } catch (e) {
      print('Error loading Google Places data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFD7BE69),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _enhancedShop?.name ?? 'Shop Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_enhancedShop?.businessType ?? ''} • ${_enhancedShop?.stage ?? ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_enhancedShop?.rating != null) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _enhancedShop!.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFD7BE69),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD7BE69),
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Photos'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFD7BE69),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Loading shop details...'),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDetailsTab(),
                        _buildReviewsTab(),
                        _buildPhotosTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_enhancedShop?.address != null)
            _buildShopDetailRow(
              Icons.location_on,
              'Address',
              _enhancedShop!.address!,
            ),

          if (_enhancedShop?.formattedPhoneNumber != null)
            _buildShopDetailRow(
              Icons.phone,
              'Phone',
              _enhancedShop!.formattedPhoneNumber!,
            ),

          if (_enhancedShop?.website != null)
            _buildShopDetailRow(Icons.web, 'Website', _enhancedShop!.website!),

          _buildShopDetailRow(
            Icons.pin_drop,
            'Pincode',
            _enhancedShop?.pincode ?? 'N/A',
          ),

          if (_enhancedShop?.priceLevel != null)
            _buildShopDetailRow(
              Icons.attach_money,
              'Price Level',
              GooglePlacesService.formatPriceLevel(_enhancedShop!.priceLevel),
            ),

          if (_enhancedShop?.openingHours != null &&
              _enhancedShop!.openingHours!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Opening Hours:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _enhancedShop!.openingHours!
                    .map(
                      (hours) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          hours,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_enhancedShop?.reviews == null || _enhancedShop!.reviews!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No reviews available'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _enhancedShop!.reviews!.length,
      itemBuilder: (context, index) {
        final review = _enhancedShop!.reviews![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: review['profile_photo_url'] != null
                          ? NetworkImage(review['profile_photo_url'])
                          : null,
                      child: review['profile_photo_url'] == null
                          ? Text(
                              (review['author_name'] as String? ?? 'A')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['author_name'] ?? 'Anonymous',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < (review['rating'] ?? 0)
                                      ? Colors.amber
                                      : Colors.grey[300],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review['relative_time_description'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (review['text'] != null &&
                    review['text'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(review['text']),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab() {
    if (_enhancedShop?.photos == null || _enhancedShop!.photos!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No photos available'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _enhancedShop!.photos!.length,
      itemBuilder: (context, index) {
        final photoUrl = _enhancedShop!.photos![index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD7BE69),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShopDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
}

// Edit Assignment Dialog Widget
class _EditAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final List<String> availableAreas;
  final List<String> currentAreas;
  final List<String> currentBusinessTypes;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.availableAreas,
    required this.currentAreas,
    required this.currentBusinessTypes,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  late Set<String> selectedAreas;
  late Set<String> selectedBusinessTypes;

  final List<Map<String, dynamic>> businessTypeOptions = [
    {'name': 'Kirana', 'value': 'grocery'},
    {'name': 'Cafe', 'value': 'cafe'},
    {'name': 'Hotel', 'value': 'hotel'},
    {'name': 'Dairy', 'value': 'dairy'},
    {'name': 'Restaurant', 'value': 'restaurant'},
    {'name': 'Bakery', 'value': 'bakery'},
    {'name': 'Pharmacy', 'value': 'pharmacy'},
    {'name': 'Supermarket', 'value': 'supermarket'},
    {'name': 'Hostel', 'value': 'hostel'},
    {'name': 'Schools', 'value': 'schools'},
    {'name': 'Colleges', 'value': 'colleges'},
    {'name': 'Hospitals', 'value': 'hospitals'},
    {'name': 'Others', 'value': 'others'},
  ];

  @override
  void initState() {
    super.initState();
    selectedAreas = Set.from(widget.currentAreas);
    selectedBusinessTypes = Set.from(widget.currentBusinessTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFD7BE69),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Assignment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.assignment['city']} - ${widget.assignment['pincode']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Areas Section
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: Color(0xFFD7BE69),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Areas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${selectedAreas.length}/${widget.availableAreas.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedAreas = Set.from(widget.availableAreas);
                            });
                          },
                          icon: const Icon(Icons.check_box, size: 16),
                          label: const Text(
                            'Select All',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedAreas.clear();
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.availableAreas.length,
                        itemBuilder: (context, index) {
                          final area = widget.availableAreas[index];
                          final isSelected = selectedAreas.contains(area);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(
                              area,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: isSelected,
                            activeColor: const Color(0xFFD7BE69),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedAreas.add(area);
                                } else {
                                  selectedAreas.remove(area);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Business Types Section
                    const Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 20,
                          color: Color(0xFFD7BE69),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Select Business Types',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: businessTypeOptions.map((type) {
                        final isSelected = selectedBusinessTypes.contains(
                          type['value'],
                        );
                        return FilterChip(
                          label: Text(type['name']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedBusinessTypes.add(type['value']!);
                              } else {
                                selectedBusinessTypes.remove(type['value']!);
                              }
                            });
                          },
                          selectedColor: const Color(
                            0xFFD7BE69,
                          ).withOpacity(0.3),
                          checkmarkColor: const Color(0xFFD7BE69),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        selectedAreas.isEmpty || selectedBusinessTypes.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'areas': selectedAreas.toList(),
                              'businessTypes': selectedBusinessTypes.toList(),
                            });
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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
