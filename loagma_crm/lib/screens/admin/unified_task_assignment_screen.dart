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

  // Form controllers
  final _pincodeController = TextEditingController();
  String? _selectedSalesmanId;
  String? _selectedSalesmanName;
  List<dynamic> _salesmen = [];
  List<Map<String, dynamic>> _pincodeLocations = []; // Multiple pincodes
  List<String> _selectedAreas = [];
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
      print('✅ Fetch result: $result');
      if (result['success']) {
        setState(() => _salesmen = result['salesmen']);
        print('✅ Loaded ${_salesmen.length} salesmen');
      } else {
        _showError(result['message'] ?? 'Failed to load salesmen');
        print('❌ Failed: ${result['message']}');
      }
    } catch (e) {
      _showError('Failed to load salesmen: $e');
      print('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationByPincode() async {
    if (_pincodeController.text.length != 6) {
      _showError('Please enter a valid 6-digit pincode');
      return;
    }

    // Check if pincode already added
    final pincode = _pincodeController.text;
    if (_pincodeLocations.any((loc) => loc['pincode'] == pincode)) {
      _showError('Pincode already added');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _service.fetchLocationByPincode(pincode);
      if (result['success']) {
        setState(() {
          _pincodeLocations.add(result['location']);
          _pincodeController.clear();
        });
        Fluttertoast.showToast(msg: 'Pincode added successfully');
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePincode(int index) {
    setState(() {
      _pincodeLocations.removeAt(index);
      _selectedAreas.clear();
    });
  }

  Future<void> _fetchBusinesses() async {
    if (_pincodeLocations.isEmpty || _selectedBusinessTypes.isEmpty) {
      _showError('Please add pincodes and select business types');
      return;
    }

    setState(() => _isFetchingBusinesses = true);
    try {
      List<Shop> allShops = [];
      Map<String, dynamic> totalBreakdown = {};

      // Fetch businesses for each pincode
      for (var location in _pincodeLocations) {
        final result = await _service.searchBusinesses(
          location['pincode'],
          _selectedAreas.isEmpty
              ? (location['areas'] as List).cast<String>()
              : _selectedAreas,
          _selectedBusinessTypes.toList(),
        );

        if (result['success']) {
          final businesses = result['businesses'] as List;
          allShops.addAll(businesses.map((b) => Shop.fromJson(b)).toList());

          // Merge breakdown
          if (result['breakdown'] != null) {
            (result['breakdown'] as Map<String, dynamic>).forEach((key, value) {
              totalBreakdown[key] = (totalBreakdown[key] ?? 0) + (value ?? 0);
            });
          }
        }
      }

      setState(() {
        _shops = allShops;
      });

      _showSuccessDialog(
        'Found ${allShops.length} businesses across ${_pincodeLocations.length} pincodes',
        totalBreakdown,
      );

      _updateMapMarkers();
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
        final color = _getMarkerColor(shop.stage);
        markers.add(
          Marker(
            markerId: MarkerId(shop.id),
            position: LatLng(shop.latitude!, shop.longitude!),
            infoWindow: InfoWindow(
              title: shop.name,
              snippet: '${shop.businessType} - ${shop.stage}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(color),
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
          CameraUpdate.newLatLngZoom(_initialPosition, 13),
        );
      }
    });
  }

  double _getMarkerColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'new':
        return BitmapDescriptor.hueYellow;
      case 'follow-up':
        return BitmapDescriptor.hueBlue;
      case 'converted':
        return BitmapDescriptor.hueGreen;
      case 'lost':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _showShopDetails(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shop.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${shop.businessType}'),
            Text('Stage: ${shop.stage}'),
            if (shop.address != null) Text('Address: ${shop.address}'),
            if (shop.rating != null) Text('Rating: ${shop.rating} ⭐'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateShopStage(shop);
            },
            child: const Text('Update Stage'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateShopStage(Shop shop) async {
    final stages = ['new', 'follow-up', 'converted', 'lost'];
    String? selectedStage = shop.stage;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Shop Stage'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: stages
                .map(
                  (stage) => RadioListTile<String>(
                    title: Text(stage.toUpperCase()),
                    value: stage,
                    groupValue: selectedStage,
                    onChanged: (value) => setState(() => selectedStage = value),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStage != null) {
                try {
                  await _service.updateShopStage(shop.id, selectedStage!);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: 'Stage updated successfully');
                  _fetchBusinesses();
                } catch (e) {
                  _showError('Failed to update stage');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignAreas() async {
    if (_selectedSalesmanId == null || _pincodeLocations.isEmpty) {
      _showError('Please select salesman and add pincodes');
      return;
    }

    setState(() => _isLoading = true);
    try {
      int totalAssignments = 0;

      // Create assignment for each pincode
      for (var location in _pincodeLocations) {
        final areasToAssign = _selectedAreas.isEmpty
            ? (location['areas'] as List).cast<String>()
            : _selectedAreas;

        final result = await _service.assignAreasToSalesman(
          _selectedSalesmanId!,
          _selectedSalesmanName!,
          location['pincode'],
          location['country'],
          location['state'],
          location['district'],
          location['city'],
          areasToAssign,
          _selectedBusinessTypes.toList(),
        );

        if (result['success']) {
          totalAssignments++;
        }
      }

      // Save all shops
      if (_shops.isNotEmpty) {
        await _service.saveShops(_shops, _selectedSalesmanId!);
      }

      _showSuccessDialog('Assignment Successful', {
        'Pincodes': totalAssignments.toString(),
        'Shops': _shops.length.toString(),
      });
      _resetForm();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _pincodeController.clear();
      _selectedSalesmanId = null;
      _selectedSalesmanName = null;
      _pincodeLocations = [];
      _selectedAreas = [];
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

  void _showSuccessDialog(String title, Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${e.key}: ${e.value}'),
                ),
              )
              .toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
            Tab(icon: Icon(Icons.list), text: 'Assignments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAssignTab(), _buildMapTab(), _buildAssignmentsTab()],
      ),
    );
  }

  Widget _buildAssignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSalesmanId,
            decoration: const InputDecoration(
              labelText: 'Select Salesman',
              border: OutlineInputBorder(),
            ),
            items: _salesmen
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s['id'] as String,
                    child: Text('${s['name']} (${s['employeeCode']})'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSalesmanId = value;
                _selectedSalesmanName = _salesmen.firstWhere(
                  (s) => s['id'] == value,
                )['name'];
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Pin Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchLocationByPincode,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Fetch'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_pincodeLocations.isNotEmpty) ...[
            const Text(
              'Added Pincodes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._pincodeLocations.asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${location['pincode']} - ${location['city']}'),
                  subtitle: Text(
                    '${location['state']}, ${location['district']}\n${(location['areas'] as List).length} areas available',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePincode(index),
                  ),
                  isThreeLine: true,
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text(
              'Select Specific Areas (Optional - Leave empty to use all areas)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_pincodeLocations.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _pincodeLocations
                    .expand((loc) => (loc['areas'] as List).cast<String>())
                    .toSet()
                    .map(
                      (area) => FilterChip(
                        label: Text(area),
                        selected: _selectedAreas.contains(area),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAreas.add(area);
                            } else {
                              _selectedAreas.remove(area);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            const Text(
              'Select Business Types',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [
                        'grocery',
                        'cafe',
                        'hotel',
                        'dairy',
                        'restaurant',
                        'bakery',
                        'pharmacy',
                        'supermarket'
                            'hostel'
                            'schools',
                        'colleges',
                        'Hospitals',
                        'others',
                      ]
                      .map(
                        (type) => FilterChip(
                          label: Text(type),
                          selected: _selectedBusinessTypes.contains(type),
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
            ElevatedButton.icon(
              onPressed: _isFetchingBusinesses ? null : _fetchBusinesses,
              icon: _isFetchingBusinesses
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isFetchingBusinesses ? 'Fetching...' : 'Fetch Businesses',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _assignAreas,
              icon: const Icon(Icons.assignment),
              label: const Text('Assign Areas to Salesman'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(215, 190, 105, 1),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return _shops.isEmpty
        ? const Center(child: Text('Fetch businesses to view on map'))
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 13,
                ),
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('New', Colors.yellow),
                        _buildLegendItem('Follow-up', Colors.blue),
                        _buildLegendItem('Converted', Colors.green),
                        _buildLegendItem('Lost', Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_selectedSalesmanId == null) {
      return const Center(child: Text('Select a salesman to view assignments'));
    }

    return FutureBuilder(
      future: _service.getAssignmentsBySalesman(_selectedSalesmanId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!['assignments'].isEmpty) {
          return const Center(child: Text('No assignments found'));
        }

        final assignments = snapshot.data!['assignments'] as List;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text('${assignment['city']}, ${assignment['state']}'),
                subtitle: Text(
                  'Pin: ${assignment['pincode']} • ${assignment['areas'].length} areas',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Country: ${assignment['country']}'),
                        Text('District: ${assignment['district']}'),
                        Text(
                          'Areas: ${(assignment['areas'] as List).join(', ')}',
                        ),
                        Text(
                          'Business Types: ${(assignment['businessTypes'] as List).join(', ')}',
                        ),
                        Text(
                          'Total Businesses: ${assignment['totalBusinesses'] ?? 0}',
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
}
