import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';

class SalesmanMapScreen extends StatefulWidget {
  const SalesmanMapScreen({super.key});

  @override
  State<SalesmanMapScreen> createState() => _SalesmanMapScreenState();
}

class _SalesmanMapScreenState extends State<SalesmanMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool isLoading = true;
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> allAccounts = []; // Store all accounts
  Position? _currentPosition;
  bool _locationPermissionGranted = false;

  // Filter states
  bool isFilterExpanded = false;
  String? selectedCustomerStage;
  String? selectedBusinessType;
  String? selectedBusinessSize;
  String? selectedFunnelStage;
  String? selectedCity;
  String? selectedPincode;
  bool? selectedApprovalStatus;
  bool? selectedActiveStatus;
  bool? selectedHasLocation;

  static const Color primaryColor = Color(0xFFD7BE69);

  // Default location (you can change this to your preferred default)
  static const LatLng _defaultLocation = LatLng(
    28.6139,
    77.2090,
  ); // Delhi, India

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // Dynamic filter options
  List<String> get availableCustomerStages {
    final stages = allAccounts
        .map((a) => a['customerStage']?.toString())
        .where((stage) => stage != null && stage.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    stages.sort();
    return stages;
  }

  List<String> get availableBusinessTypes {
    final types = allAccounts
        .map((a) => a['businessType']?.toString())
        .where((type) => type != null && type.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  List<String> get availableBusinessSizes {
    final sizes = allAccounts
        .map((a) => a['businessSize']?.toString())
        .where((size) => size != null && size.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    sizes.sort();
    return sizes;
  }

  List<String> get availableFunnelStages {
    final stages = allAccounts
        .map((a) => a['funnelStage']?.toString())
        .where((stage) => stage != null && stage.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    stages.sort();
    return stages;
  }

  List<String> get availableCities {
    final cities = allAccounts
        .map((a) => a['city']?.toString())
        .where((city) => city != null && city.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  List<String> get availablePincodes {
    final pincodes = allAccounts
        .map((a) => a['pincode']?.toString())
        .where((pincode) => pincode != null && pincode.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedCustomerStage != null) count++;
    if (selectedBusinessType != null) count++;
    if (selectedBusinessSize != null) count++;
    if (selectedFunnelStage != null) count++;
    if (selectedCity != null) count++;
    if (selectedPincode != null) count++;
    if (selectedApprovalStatus != null) count++;
    if (selectedActiveStatus != null) count++;
    if (selectedHasLocation != null) count++;
    return count;
  }

  void clearAllFilters() {
    setState(() {
      selectedCustomerStage = null;
      selectedBusinessType = null;
      selectedBusinessSize = null;
      selectedFunnelStage = null;
      selectedCity = null;
      selectedPincode = null;
      selectedApprovalStatus = null;
      selectedActiveStatus = null;
      selectedHasLocation = null;
      _applyFilters();
    });
  }

  void _applyFilters() {
    accounts = allAccounts.where((account) {
      if (selectedCustomerStage != null &&
          account['customerStage'] != selectedCustomerStage)
        return false;
      if (selectedBusinessType != null &&
          account['businessType'] != selectedBusinessType)
        return false;
      if (selectedBusinessSize != null &&
          account['businessSize'] != selectedBusinessSize)
        return false;
      if (selectedFunnelStage != null &&
          account['funnelStage'] != selectedFunnelStage)
        return false;
      if (selectedCity != null && account['city'] != selectedCity) return false;
      if (selectedPincode != null && account['pincode'] != selectedPincode)
        return false;
      if (selectedApprovalStatus != null &&
          account['isApproved'] != selectedApprovalStatus)
        return false;
      if (selectedActiveStatus != null &&
          account['isActive'] != selectedActiveStatus)
        return false;
      if (selectedHasLocation != null) {
        final hasLocation =
            account['latitude'] != null && account['longitude'] != null;
        if (hasLocation != selectedHasLocation) return false;
      }
      return true;
    }).toList();
    _createMarkers();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadAccountsWithLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAccountsWithLocations() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;

      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId',
      );

      final response = await http.get(accountsUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          allAccounts = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _applyFilters();
        }
      }
    } catch (e) {
      print('Error loading accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    print('🗺️ Creating markers for ${accounts.length} accounts');

    // Add current location marker if available
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
      print(
        '📍 Added current location marker: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
    }

    // Add account markers
    int accountMarkersAdded = 0;
    for (var account in accounts) {
      // Check if account has location data
      if (account['latitude'] != null && account['longitude'] != null) {
        try {
          final lat = double.parse(account['latitude'].toString());
          final lng = double.parse(account['longitude'].toString());

          // Validate coordinates are reasonable (not 0,0 or invalid)
          if (lat == 0 && lng == 0) {
            print(
              '⚠️ Skipping account ${account['id']} - invalid coordinates (0,0)',
            );
            continue;
          }

          final isApproved = account['isApproved'] == true;
          final personName = account['personName'] ?? 'Unknown';
          final businessName = account['businessName'];
          final contactNumber = account['contactNumber'];

          markers.add(
            Marker(
              markerId: MarkerId('account_${account['id']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: personName,
                snippet: businessName ?? contactNumber ?? 'No details',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isApproved
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
              onTap: () => _showAccountDetails(account),
            ),
          );
          accountMarkersAdded++;
          print('✅ Added marker for ${personName} at $lat, $lng');
        } catch (e) {
          print('❌ Error parsing coordinates for account ${account['id']}: $e');
        }
      } else {
        print(
          '⚠️ Account ${account['id']} (${account['personName']}) has no location data',
        );
      }
    }

    print(
      '📊 Total markers created: ${markers.length} (${accountMarkersAdded} accounts + ${_currentPosition != null ? 1 : 0} current location)',
    );

    setState(() {
      _markers = markers;
    });
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
              'Stage',
              account['customerStage'] ?? 'N/A',
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
                  if (account['latitude'] != null &&
                      account['longitude'] != null) {
                    final lat = double.parse(account['latitude'].toString());
                    final lng = double.parse(account['longitude'].toString());
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
                    );
                  }
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

  void _showAllAccountsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Accounts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${accounts.length} total account(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
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
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                account['personName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (hasLocation)
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.green,
                              )
                            else
                              const Icon(
                                Icons.location_off,
                                size: 16,
                                color: Colors.red,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (account['businessName'] != null)
                              Text(account['businessName']),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    account['contactNumber'] ?? 'No contact',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                if (account['pincode'] != null)
                                  Text(
                                    account['pincode'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
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
                                  Navigator.pop(context);
                                  _zoomToAccount(account);
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
                        onTap: () {
                          if (hasLocation) {
                            Navigator.pop(context);
                            _zoomToAccount(account);
                          } else {
                            Navigator.pop(context);
                            _showAccountDetails(account);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _zoomToAccount(Map<String, dynamic> account) {
    if (account['latitude'] != null && account['longitude'] != null) {
      try {
        final lat = double.parse(account['latitude'].toString());
        final lng = double.parse(account['longitude'].toString());

        print('🎯 Zooming to account: ${account['personName']} at $lat, $lng');

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );

        // Show a brief toast/snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing ${account['personName'] ?? 'account'} on map',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: primaryColor,
          ),
        );

        // Optionally show account details after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showAccountDetails(account);
          }
        });
      } catch (e) {
        print('Error zooming to account: $e');
      }
    }
  }

  void _showAccountsWithoutLocation() {
    final accountsWithoutLocation = accounts
        .where((a) => a['latitude'] == null || a['longitude'] == null)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accounts Without Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${accountsWithoutLocation.length} account(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: accountsWithoutLocation.length,
                  itemBuilder: (context, index) {
                    final account = accountsWithoutLocation[index];
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
                            Text(
                              account['contactNumber'] ?? 'No contact',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: account['isApproved'] == true
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            account['isApproved'] == true
                                ? 'Approved'
                                : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAccountDetails(account);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsOnMap = accounts
        .where((a) => a['latitude'] != null && a['longitude'] != null)
        .length;
    final accountsWithoutLocation = accounts.length - accountsOnMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Locations'),
        backgroundColor: primaryColor,
        actions: [
          // Show all accounts list
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.list),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      accounts.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'View all accounts',
            onPressed: _showAllAccountsList,
          ),
          if (accountsWithoutLocation > 0)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.warning_amber),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        accountsWithoutLocation.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Accounts without location',
              onPressed: _showAccountsWithoutLocation,
            ),
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Go to my location',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Centered on your location'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh map data',
            onPressed: () {
              _initializeMap();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing map data...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading map data...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
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
                  onMapCreated: (controller) {
                    _mapController = controller;
                    print('🗺️ Map created with ${_markers.length} markers');

                    // If we have markers, move camera to show them
                    if (_markers.isNotEmpty) {
                      // Use multiple delays to ensure map is fully loaded
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && _mapController != null) {
                          _fitMarkersInView();
                        }
                      });
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted && _mapController != null) {
                          _fitMarkersInView();
                        }
                      });
                    } else {
                      print('⚠️ No markers to display on map');
                    }
                  },
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Collapsible Filter Section at top
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
                        // Filter Toggle Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              isFilterExpanded = !isFilterExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: 18,
                                  color: activeFilterCount > 0
                                      ? primaryColor
                                      : Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filters',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: activeFilterCount > 0
                                        ? primaryColor
                                        : Colors.grey[800],
                                  ),
                                ),
                                if (activeFilterCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      activeFilterCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                // Legend inline
                                if (!isFilterExpanded) ...[
                                  _buildLegendItem('Me', Colors.blue),
                                  const SizedBox(width: 8),
                                  _buildLegendItem('✓', Colors.green),
                                  const SizedBox(width: 8),
                                  _buildLegendItem('⏱', Colors.orange),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  isFilterExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Filter Content
                        if (isFilterExpanded)
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Clear button
                                  if (activeFilterCount > 0)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: clearAllFilters,
                                        icon: const Icon(
                                          Icons.clear_all,
                                          size: 14,
                                        ),
                                        label: const Text('Clear All'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),

                                  // Customer Stage
                                  if (availableCustomerStages.isNotEmpty) ...[
                                    Text(
                                      'Customer Stage',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          'customerStage',
                                        ),
                                        ...availableCustomerStages.map(
                                          (stage) => _buildFilterChip(
                                            stage,
                                            stage,
                                            'customerStage',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Business Type
                                  if (availableBusinessTypes.isNotEmpty) ...[
                                    Text(
                                      'Business Type',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          'businessType',
                                        ),
                                        ...availableBusinessTypes.map(
                                          (type) => _buildFilterChip(
                                            type,
                                            type,
                                            'businessType',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Business Size
                                  if (availableBusinessSizes.isNotEmpty) ...[
                                    Text(
                                      'Business Size',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          'businessSize',
                                        ),
                                        ...availableBusinessSizes.map(
                                          (size) => _buildFilterChip(
                                            size,
                                            size,
                                            'businessSize',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Funnel Stage
                                  if (availableFunnelStages.isNotEmpty) ...[
                                    Text(
                                      'Funnel Stage',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          'funnelStage',
                                        ),
                                        ...availableFunnelStages.map(
                                          (stage) => _buildFilterChip(
                                            stage,
                                            stage,
                                            'funnelStage',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // City
                                  if (availableCities.isNotEmpty) ...[
                                    Text(
                                      'City',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip('All', null, 'city'),
                                        ...availableCities.map(
                                          (city) => _buildFilterChip(
                                            city,
                                            city,
                                            'city',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Pincode
                                  if (availablePincodes.isNotEmpty) ...[
                                    Text(
                                      'Pincode',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          null,
                                          'pincode',
                                        ),
                                        ...availablePincodes
                                            .take(10)
                                            .map(
                                              (pincode) => _buildFilterChip(
                                                pincode,
                                                pincode,
                                                'pincode',
                                              ),
                                            ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Approval Status
                                  Text(
                                    'Approval Status',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      _buildBooleanFilterChip(
                                        'All',
                                        null,
                                        'approval',
                                        primaryColor,
                                      ),
                                      _buildBooleanFilterChip(
                                        'Approved',
                                        true,
                                        'approval',
                                        Colors.green,
                                      ),
                                      _buildBooleanFilterChip(
                                        'Pending',
                                        false,
                                        'approval',
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Location Status
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      _buildBooleanFilterChip(
                                        'All',
                                        null,
                                        'location',
                                        primaryColor,
                                      ),
                                      _buildBooleanFilterChip(
                                        'With GPS',
                                        true,
                                        'location',
                                        Colors.green,
                                      ),
                                      _buildBooleanFilterChip(
                                        'No GPS',
                                        false,
                                        'location',
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Info card at the bottom
              ],
            ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                print('🎯 Recenter map to show all markers');
                _fitMarkersInView();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Showing ${accounts.length} account${accounts.length != 1 ? 's' : ''} on map',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              backgroundColor: primaryColor,
              icon: const Icon(Icons.center_focus_strong, size: 20),
              label: const Text(
                'Show All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              tooltip: 'Fit all filtered accounts in view',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, String filterType) {
    bool isSelected = false;
    switch (filterType) {
      case 'customerStage':
        isSelected = selectedCustomerStage == value;
        break;
      case 'businessType':
        isSelected = selectedBusinessType == value;
        break;
      case 'businessSize':
        isSelected = selectedBusinessSize == value;
        break;
      case 'funnelStage':
        isSelected = selectedFunnelStage == value;
        break;
      case 'city':
        isSelected = selectedCity == value;
        break;
      case 'pincode':
        isSelected = selectedPincode == value;
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          switch (filterType) {
            case 'customerStage':
              selectedCustomerStage = value;
              break;
            case 'businessType':
              selectedBusinessType = value;
              break;
            case 'businessSize':
              selectedBusinessSize = value;
              break;
            case 'funnelStage':
              selectedFunnelStage = value;
              break;
            case 'city':
              selectedCity = value;
              break;
            case 'pincode':
              selectedPincode = value;
              break;
          }
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildBooleanFilterChip(
    String label,
    bool? value,
    String filterType,
    Color activeColor,
  ) {
    bool isSelected = false;
    switch (filterType) {
      case 'approval':
        isSelected = selectedApprovalStatus == value;
        break;
      case 'active':
        isSelected = selectedActiveStatus == value;
        break;
      case 'location':
        isSelected = selectedHasLocation == value;
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          switch (filterType) {
            case 'approval':
              selectedApprovalStatus = value;
              break;
            case 'active':
              selectedActiveStatus = value;
              break;
            case 'location':
              selectedHasLocation = value;
              break;
          }
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && value != null)
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                size: 11,
                color: Colors.white,
              ),
            if (isSelected && value != null) const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) {
      print(
        '⚠️ Cannot fit markers: markers=${_markers.length}, controller=${_mapController != null}',
      );
      return;
    }

    print('📐 Fitting ${_markers.length} markers in view');

    // If only one marker, just center on it
    if (_markers.length == 1) {
      final marker = _markers.first;
      print(
        '📍 Single marker, centering at: ${marker.position.latitude}, ${marker.position.longitude}',
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 14),
      );
      return;
    }

    // Calculate bounds for multiple markers
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    print('📊 Bounds: SW($minLat, $minLng) to NE($maxLat, $maxLng)');

    // Add some padding to the bounds
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          100, // padding in pixels
        ),
      );
      print('✅ Camera fitted to show all markers');
    } catch (e) {
      print('❌ Error fitting camera: $e');
      // Fallback: center on first marker
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_markers.first.position, 12),
      );
    }
  }
}
