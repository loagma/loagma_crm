import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/map_task_assignment_service.dart';
import '../../models/shop_model.dart';

class ModernTaskAssignmentScreen extends StatefulWidget {
  const ModernTaskAssignmentScreen({super.key});

  @override
  State<ModernTaskAssignmentScreen> createState() =>
      _ModernTaskAssignmentScreenState();
}

class _ModernTaskAssignmentScreenState extends State<ModernTaskAssignmentScreen>
    with SingleTickerProviderStateMixin {
  final _service = MapTaskAssignmentService();
  late TabController _tabController;

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

  // Colors
  static const primaryColor = Color(0xFFD7BE69);
  static const secondaryColor = Color(0xFF2C3E50);
  static const accentColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalesmen();
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
    setState(() => _isLoading = true);
    try {
      final result = await _service.fetchSalesmen();
      if (result['success'] == true) {
        setState(() {
          _salesmen = result['salesmen'] ?? [];
          _filteredSalesmen = _salesmen;
        });
      } else {
        _showError(result['message'] ?? 'Failed to load salesmen');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
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
      if (result['success'] == true && result['location'] != null) {
        setState(() {
          _pincodeLocations.add(result['location']);
          _selectedAreasByPincode[pincode] = [];
          _pincodeController.clear();
        });
        _showSuccess('Pincode $pincode added successfully');
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
                print('Error parsing business: $e');
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
        _mapBusinessTypeFilter = Set.from(_selectedBusinessTypes);
        _updateMapMarkers();
        _tabController.animateTo(2); // Switch to map tab
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isFetchingBusinesses = false);
    }
  }

  // Update map markers
  void _updateMapMarkers() {
    final markers = <Marker>{};

    for (var shop in _shops) {
      // Filter by business type if filter is active
      if (_mapBusinessTypeFilter.isNotEmpty &&
          !_mapBusinessTypeFilter.contains(shop.businessType.toLowerCase())) {
        continue;
      }

      // Filter by stage if filter is active
      if (_mapStageFilter.isNotEmpty &&
          !_mapStageFilter.contains(shop.stage.toLowerCase())) {
        continue;
      }

      if (shop.latitude != null && shop.longitude != null) {
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
      if (_shops.isNotEmpty && _shops.first.latitude != null) {
        _initialPosition = LatLng(
          _shops.first.latitude!,
          _shops.first.longitude!,
        );
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 12),
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

  // Show shop details
  void _showShopDetails(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.store, color: primaryColor),
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

  // Assign areas
  Future<void> _assignAreas() async {
    if (_selectedSalesmanId == null) {
      _showError('Please select a salesman');
      return;
    }

    if (_pincodeLocations.isEmpty) {
      _showError('Please add at least one pincode');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Store counts before resetting
      final pincodeCount = _pincodeLocations.length;
      final businessCount = _shops.length;
      final salesmanName = _selectedSalesmanName;

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
          _showError('Failed to assign pincode $pincode: ${result['message']}');
        }
      }

      if (_shops.isNotEmpty) {
        await _service.saveShops(_shops, _selectedSalesmanId!);
      }

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
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
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
    if (_currentStep == 0 && _selectedSalesmanId == null) {
      _showError('Please select a salesman');
      return;
    }
    if (_currentStep == 1 && _pincodeLocations.isEmpty) {
      _showError('Please add at least one pincode');
      return;
    }
    if (_currentStep == 2 && _selectedBusinessTypes.isEmpty) {
      _showError('Please select at least one business type');
      return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Task Assignment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
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
        children: [_buildAssignTab(), _buildAssignmentsTab(), _buildMapTab()],
      ),
    );
  }

  Widget _buildAssignTab() {
    return Column(
      children: [
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
                      child: Container(
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
                  onPressed: _currentStep == 3 ? _assignAreas : _nextStep,
                  icon: Icon(
                    _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                  ),
                  label: Text(_currentStep == 3 ? 'Assign' : 'Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == 3
                        ? Colors.green
                        : primaryColor,
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
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Salesman';
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

  Widget _buildSalesmanStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a salesman to assign tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // Search field
          TextField(
            controller: _salesmanSearchController,
            decoration: InputDecoration(
              labelText: 'Search Salesman',
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
                          ? 'No salesmen found'
                          : 'No matching salesmen',
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_filteredSalesmen.map((salesman) {
              final isSelected = _selectedSalesmanId == salesman['id'];
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
                      _selectedSalesmanId = salesman['id'];
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
            Text(
              'Added Pincodes (${_pincodeLocations.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._pincodeLocations.map((location) {
              final pincode = location['pincode'];
              final areas = (location['areas'] as List).cast<String>();
              final selectedAreas = _selectedAreasByPincode[pincode] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.location_city, color: Colors.white),
                  ),
                  title: Text(
                    '$pincode - ${location['city']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${location['state']}, ${location['district']}',
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
                                      _selectedAreasByPincode[pincode]!.add(
                                        area,
                                      );
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
      {'name': 'Grocery', 'icon': Icons.shopping_cart},
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
                child: Container(
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
                      : 'Fetch Businesses',
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
                            'Ready to assign to salesman',
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
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          zoomControlsEnabled: false,
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with clear all button
                  Row(
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
                      if (_mapBusinessTypeFilter.isNotEmpty ||
                          _mapStageFilter.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _mapBusinessTypeFilter.clear();
                              _mapStageFilter.clear();
                              _updateMapMarkers();
                            });
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
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
                      _buildStageFilterChip('Lead', 'lead', Colors.orange),
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
                      const Icon(Icons.business, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Business Type:',
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
                    children: _selectedBusinessTypes.map((type) {
                      final isSelected = _mapBusinessTypeFilter.contains(type);
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing $filteredShopsCount of ${_shops.length} businesses',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
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

  // Edit assignment
  Future<void> _editAssignment(Map<String, dynamic> assignment) async {
    final areas = (assignment['areas'] as List).cast<String>();
    final businessTypes = (assignment['businessTypes'] as List).cast<String>();

    final areasController = TextEditingController(text: areas.join(', '));
    final businessTypesController = TextEditingController(
      text: businessTypes.join(', '),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: primaryColor),
            SizedBox(width: 12),
            Text('Edit Assignment'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: areasController,
                decoration: const InputDecoration(
                  labelText: 'Areas (comma-separated)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: businessTypesController,
                decoration: const InputDecoration(
                  labelText: 'Business Types (comma-separated)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              final newAreas = areasController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final newBusinessTypes = businessTypesController.text
                  .split(',')
                  .map((e) => e.trim().toLowerCase())
                  .where((e) => e.isNotEmpty)
                  .toList();

              Navigator.pop(context, {
                'areas': newAreas,
                'businessTypes': newBusinessTypes,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Save'),
          ),
        ],
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

        // Debug logging
        print('📊 Assignments Tab - Salesman ID: $_selectedSalesmanId');
        print('📊 Assignments Tab - Has Data: ${snapshot.hasData}');
        print('📊 Assignments Tab - Data: ${snapshot.data}');

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
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final areas = (assignment['areas'] as List).cast<String>();
            final businessTypes = (assignment['businessTypes'] as List)
                .cast<String>();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${assignment['city']}, ${assignment['state']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Pincode: ${assignment['pincode']} • ${areas.length} areas',
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
                          Icons.public,
                          'Country',
                          assignment['country'],
                        ),
                        const SizedBox(height: 8),
                        _buildAssignmentDetail(
                          Icons.location_city,
                          'District',
                          assignment['district'],
                        ),
                        const SizedBox(height: 8),
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
                          Icons.store,
                          'Total Businesses',
                          '${assignment['totalBusinesses'] ?? 0}',
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
