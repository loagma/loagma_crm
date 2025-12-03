import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/map_task_assignment_service.dart';
import '../../models/shop_model.dart';

class UnifiedTaskAssignmentScreen extends StatefulWidget {
  const UnifiedTaskAssignmentScreen({super.key});

  @override
  State<UnifiedTaskAssignmentScreen> createState() =>
      _UnifiedTaskAssignmentScreenState();
}

class _UnifiedTaskAssignmentScreenState
    extends State<UnifiedTaskAssignmentScreen>
    with SingleTickerProviderStateMixin {
  final _service = MapTaskAssignmentService();
  late TabController _tabController;
  int _currentStep = 0;

  // Form data
  final _pincodeController = TextEditingController();
  String? _selectedSalesmanId;
  String? _selectedSalesmanName;
  List<dynamic> _salesmen = [];
  List<Map<String, dynamic>> _pincodeLocations = [];
  Map<String, List<String>> _selectedAreasByPincode = {};
  Set<String> _selectedBusinessTypes = {};
  bool _isLoading = false;
  bool _isFetchingBusinesses = false;

  // Map data
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Shop> _shops = [];
  LatLng _initialPosition = const LatLng(20.5937, 78.9629);

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSalesmen() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.fetchSalesmen();
      if (result['success'] == true) {
        setState(() => _salesmen = result['salesmen'] ?? []);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationByPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) {
      _showError('Enter valid 6-digit pincode');
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
        Fluttertoast.showToast(
          msg: 'Pincode added',
          backgroundColor: Colors.green,
        );
      } else {
        _showError(result['message'] ?? 'Failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePincode(String pincode) {
    setState(() {
      _pincodeLocations.removeWhere((loc) => loc['pincode'] == pincode);
      _selectedAreasByPincode.remove(pincode);
    });
  }

  Future<void> _fetchBusinesses() async {
    if (_pincodeLocations.isEmpty || _selectedBusinessTypes.isEmpty) {
      _showError('Add pincodes and select business types');
      return;
    }
    setState(() => _isFetchingBusinesses = true);
    try {
      List<Shop> allShops = [];
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
                print('Error: $e');
              }
            }
          }
        }
      }
      setState(() => _shops = allShops);
      if (allShops.isEmpty) {
        _showError('No businesses found');
      } else {
        Fluttertoast.showToast(
          msg: 'Found ${allShops.length} businesses',
          backgroundColor: Colors.green,
        );
        _updateMapMarkers();
        _tabController.animateTo(1);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isFetchingBusinesses = false);
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    for (var shop in _shops) {
      if (shop.latitude != null && shop.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(shop.placeId ?? shop.name),
            position: LatLng(shop.latitude!, shop.longitude!),
            infoWindow: InfoWindow(
              title: shop.name,
              snippet: shop.businessType,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
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

  Future<void> _assignAreas() async {
    if (_selectedSalesmanId == null || _pincodeLocations.isEmpty) {
      _showError('Select salesman and add pincodes');
      return;
    }
    setState(() => _isLoading = true);
    try {
      for (var location in _pincodeLocations) {
        final pincode = location['pincode'];
        final selectedAreas = _selectedAreasByPincode[pincode] ?? [];
        final areasToAssign = selectedAreas.isEmpty
            ? (location['areas'] as List).cast<String>()
            : selectedAreas;
        await _service.assignAreasToSalesman(
          _selectedSalesmanId!,
          _selectedSalesmanName!,
          pincode,
          location['country'] ?? '',
          location['state'] ?? '',
          location['district'] ?? '',
          location['city'] ?? '',
          areasToAssign,
          _selectedBusinessTypes.toList(),
        );
      }
      if (_shops.isNotEmpty) {
        await _service.saveShops(_shops, _selectedSalesmanId!);
      }
      Fluttertoast.showToast(
        msg: 'Task Assignment Successfully!',
        backgroundColor: Colors.green,
      );
      _resetForm();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _pincodeController.clear();
      _selectedSalesmanId = null;
      _selectedSalesmanName = null;
      _pincodeLocations = [];
      _selectedAreasByPincode = {};
      _selectedBusinessTypes = {};
      _shops = [];
      _markers = {};
    });
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Assignment'),
        backgroundColor: const Color.fromRGBO(215, 190, 105, 1),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Assign'),
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to prevent map conflict
        children: [_buildAssignTab(), _buildMapTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildAssignTab() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep == 0 && _selectedSalesmanId == null) {
          _showError('Select a salesman');
          return;
        }
        if (_currentStep == 1 && _pincodeLocations.isEmpty) {
          _showError('Add at least one pincode');
          return;
        }
        if (_currentStep == 2 && _selectedBusinessTypes.isEmpty) {
          _showError('Select business types');
          return;
        }
        if (_currentStep < 3) {
          setState(() => _currentStep++);
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      steps: [
        Step(
          title: const Text('Select Salesman'),
          content: _buildSalesmanStep(),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Add Pincodes'),
          content: _buildPincodeStep(),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Select Business Types'),
          content: _buildBusinessTypesStep(),
          isActive: _currentStep >= 2,
        ),
        Step(
          title: const Text('Review & Assign'),
          content: _buildReviewStep(),
          isActive: _currentStep >= 3,
        ),
      ],
    );
  }

  Widget _buildSalesmanStep() {
    if (_isLoading) return const CircularProgressIndicator();
    if (_salesmen.isEmpty) return const Text('No salesmen found');
    return Column(
      children: _salesmen.map((s) {
        final isSelected = _selectedSalesmanId == s['id'];
        return Card(
          color: isSelected ? Colors.amber.shade100 : null,
          child: ListTile(
            title: Text(s['name'] ?? 'Unknown'),
            subtitle: Text('Code: ${s['employeeCode'] ?? 'N/A'}'),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              setState(() {
                _selectedSalesmanId = s['id'];
                _selectedSalesmanName = s['name'];
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPincodeStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _fetchLocationByPincode,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._pincodeLocations.map((loc) {
          final pincode = loc['pincode'];
          return Card(
            child: ListTile(
              title: Text('$pincode - ${loc['city']}'),
              subtitle: Text('${loc['state']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removePincode(pincode),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBusinessTypesStep() {
    // Official Google Maps API Place Types
    final types = [
      'supermarket', // Grocery stores, supermarkets
      'convenience_store', // Small grocery/convenience stores
      'restaurant', // Restaurants
      'cafe', // Cafes, coffee shops
      'bakery', // Bakeries
      'meal_takeaway', // Takeaway/delivery restaurants
      'food', // General food establishments
      'bar', // Bars, pubs
      'lodging', // Hotels, lodging
      'pharmacy', // Pharmacies, drugstores
      'store', // General retail stores
      'shopping_mall', // Shopping malls
      'clothing_store', // Clothing/apparel stores
      'electronics_store', // Electronics shops
      'furniture_store', // Furniture stores
      'home_goods_store', // Home goods/hardware stores
      'jewelry_store', // Jewelry shops
      'shoe_store', // Shoe stores
      'book_store', // Book stores
      'liquor_store', // Liquor/wine shops
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text(
            'Select business types to fetch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Business type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types
                .map(
                  (type) => FilterChip(
                    label: Text(
                      type.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _selectedBusinessTypes.contains(type),
                    selectedColor: const Color.fromRGBO(215, 190, 105, 0.3),
                    checkmarkColor: const Color.fromRGBO(215, 190, 105, 1),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBusinessTypes.add(type);
                        } else {
                          _selectedBusinessTypes.remove(type);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),

          // Selected count
          if (_selectedBusinessTypes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedBusinessTypes.length} business type(s) selected',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Fetch Businesses Button
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
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(215, 190, 105, 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Success message
          if (_shops.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Found ${_shops.length} businesses',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        Text('Salesman: ${_selectedSalesmanName ?? 'N/A'}'),
        Text('Pincodes: ${_pincodeLocations.length}'),
        Text('Business Types: ${_selectedBusinessTypes.length}'),
        Text('Businesses: ${_shops.length}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _assignAreas,
          child: const Text('Confirm Assignment'),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    if (_shops.isEmpty) {
      return const Center(child: Text('No businesses to display'));
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
      markers: _markers,
      onMapCreated: (controller) => _mapController = controller,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  Widget _buildHistoryTab() {
    if (_selectedSalesmanId == null) {
      return const Center(child: Text('Select a salesman'));
    }
    return FutureBuilder(
      future: _service.getAssignmentsBySalesman(_selectedSalesmanId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            (snapshot.data!['assignments'] as List).isEmpty) {
          return const Center(child: Text('No assignments'));
        }
        final assignments = snapshot.data!['assignments'] as List;
        return ListView.builder(
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              child: ListTile(
                title: Text('${a['city']}, ${a['state']}'),
                subtitle: Text('Pincode: ${a['pincode']}'),
              ),
            );
          },
        );
      },
    );
  }
}
