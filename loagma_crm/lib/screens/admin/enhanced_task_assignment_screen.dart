import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/salesman_model.dart';
import '../../models/location_info_model.dart';
import '../../models/area_assignment_model.dart';
import '../../models/business_type_model.dart';
import '../../services/enhanced_task_assignment_service.dart';

class EnhancedTaskAssignmentScreen extends StatefulWidget {
  const EnhancedTaskAssignmentScreen({super.key});

  @override
  State<EnhancedTaskAssignmentScreen> createState() =>
      _EnhancedTaskAssignmentScreenState();
}

class _EnhancedTaskAssignmentScreenState
    extends State<EnhancedTaskAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Loading states
  bool isLoadingSalesmen = true;
  bool isLoadingLocation = false;
  bool isAssigning = false;
  bool isFetchingBusinesses = false;

  // Data
  List<Salesman> salesmen = [];
  Salesman? selectedSalesman;
  LocationInfo? locationInfo;
  List<AreaAssignment> assignments = [];

  // Form controllers
  final TextEditingController _pinCodeController = TextEditingController();

  // Selections
  List<String> selectedAreas = [];
  List<String> selectedBusinessTypes = [];
  List<BusinessType> businessTypes = BusinessType.getDefaultTypes();

  // Business fetch result
  Map<String, dynamic>? businessFetchResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSalesmen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesmen() async {
    setState(() => isLoadingSalesmen = true);
    try {
      final fetchedSalesmen =
          await EnhancedTaskAssignmentService.fetchAllSalesmen();
      setState(() {
        salesmen = fetchedSalesmen;
        isLoadingSalesmen = false;
      });
    } catch (e) {
      setState(() => isLoadingSalesmen = false);
      Fluttertoast.showToast(msg: 'Error loading salesmen: $e');
    }
  }

  Future<void> _fetchLocationByPinCode() async {
    final pinCode = _pinCodeController.text.trim();
    if (pinCode.isEmpty || pinCode.length != 6) {
      Fluttertoast.showToast(msg: 'Please enter a valid 6-digit pin code');
      return;
    }

    setState(() => isLoadingLocation = true);
    try {
      final location =
          await EnhancedTaskAssignmentService.fetchLocationByPinCode(pinCode);
      setState(() {
        locationInfo = location;
        selectedAreas = [];
        isLoadingLocation = false;
      });
      Fluttertoast.showToast(
        msg: 'Location fetched: ${location.city}, ${location.state}',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() => isLoadingLocation = false);
      Fluttertoast.showToast(msg: 'Error fetching location: $e');
    }
  }

  Future<void> _assignAreas() async {
    if (selectedSalesman == null) {
      Fluttertoast.showToast(msg: 'Please select a salesman');
      return;
    }
    if (locationInfo == null) {
      Fluttertoast.showToast(msg: 'Please fetch location by pin code first');
      return;
    }
    if (selectedAreas.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one area');
      return;
    }
    if (selectedBusinessTypes.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one business type');
      return;
    }

    setState(() => isAssigning = true);
    try {
      final result = await EnhancedTaskAssignmentService.assignAreasToSalesman(
        salesmanId: selectedSalesman!.id,
        salesmanName: selectedSalesman!.name,
        pinCode: locationInfo!.pinCode,
        country: locationInfo!.country,
        state: locationInfo!.state,
        district: locationInfo!.district,
        city: locationInfo!.city,
        selectedAreas: selectedAreas,
        businessTypes: selectedBusinessTypes,
      );

      if (result['success'] == true) {
        _showSuccessDialog(result);
        _resetForm();
        _loadAssignments();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => isAssigning = false);
    }
  }

  Future<void> _fetchBusinesses() async {
    if (locationInfo == null ||
        selectedAreas.isEmpty ||
        selectedBusinessTypes.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select areas and business types first',
      );
      return;
    }

    setState(() => isFetchingBusinesses = true);
    try {
      final result =
          await EnhancedTaskAssignmentService.fetchBusinessesByAreaAndType(
            pinCode: locationInfo!.pinCode,
            areas: selectedAreas,
            businessTypes: selectedBusinessTypes,
          );

      setState(() {
        businessFetchResult = result;
        isFetchingBusinesses = false;
      });

      _showBusinessResultDialog(result);
    } catch (e) {
      setState(() => isFetchingBusinesses = false);
      Fluttertoast.showToast(msg: 'Error fetching businesses: $e');
    }
  }

  Future<void> _loadAssignments() async {
    if (selectedSalesman == null) return;
    try {
      final fetchedAssignments =
          await EnhancedTaskAssignmentService.getAssignmentsBySalesman(
            selectedSalesman!.id,
          );
      setState(() {
        assignments = fetchedAssignments;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading assignments: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _pinCodeController.clear();
      locationInfo = null;
      selectedAreas = [];
      selectedBusinessTypes = [];
      businessFetchResult = null;
    });
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(76, 175, 80, 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? 'Assignment successful'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(215, 190, 105, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7BE69)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedAreas.length} Areas Assigned',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${selectedBusinessTypes.length} Business Types',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD7BE69))),
          ),
        ],
      ),
    );
  }

  void _showBusinessResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Business Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(215, 190, 105, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${result['totalBusinesses']}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD7BE69),
                    ),
                  ),
                  const Text('Total Businesses Found'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD7BE69))),
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
        backgroundColor: const Color(0xFFD7BE69),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assign Areas', icon: Icon(Icons.add_location)),
            Tab(text: 'View Assignments', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAssignTab(), _buildViewTab()],
      ),
    );
  }

  Widget _buildAssignTab() {
    if (isLoadingSalesmen) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesmanDropdown(),
          const SizedBox(height: 20),
          _buildPinCodeSection(),
          if (locationInfo != null) ...[
            const SizedBox(height: 20),
            _buildLocationDetails(),
            const SizedBox(height: 20),
            _buildAreaSelection(),
            const SizedBox(height: 20),
            _buildBusinessTypeSelection(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesmanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Salesman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD7BE69)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Salesman>(
              isExpanded: true,
              value: selectedSalesman,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Choose a salesman'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: salesmen.map((salesman) {
                return DropdownMenuItem<Salesman>(
                  value: salesman,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFD7BE69),
                        child: Text(
                          salesman.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              salesman.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              salesman.contactNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Salesman? value) {
                setState(() {
                  selectedSalesman = value;
                  _resetForm();
                });
                if (value != null) {
                  _loadAssignments();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Pin Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit pin code',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0xFFD7BE69),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD7BE69)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD7BE69),
                      width: 2,
                    ),
                  ),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isLoadingLocation ? null : _fetchLocationByPinCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7BE69),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Fetch'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Country', locationInfo!.country),
            _buildInfoRow('State', locationInfo!.state),
            _buildInfoRow('District', locationInfo!.district),
            _buildInfoRow('City', locationInfo!.city),
            _buildInfoRow('Pin Code', locationInfo!.pinCode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Areas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${selectedAreas.length} selected',
              style: const TextStyle(
                color: Color(0xFFD7BE69),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: locationInfo!.areas.map((area) {
            final isSelected = selectedAreas.contains(area);
            return FilterChip(
              label: Text(area),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedAreas.add(area);
                  } else {
                    selectedAreas.remove(area);
                  }
                });
              },
              selectedColor: const Color.fromRGBO(215, 190, 105, 0.3),
              checkmarkColor: const Color(0xFFD7BE69),
              side: BorderSide(
                color: isSelected ? const Color(0xFFD7BE69) : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Business Types',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${selectedBusinessTypes.length} selected',
              style: const TextStyle(
                color: Color(0xFFD7BE69),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: businessTypes.map((type) {
            final isSelected = selectedBusinessTypes.contains(type.id);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(type.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedBusinessTypes.add(type.id);
                  } else {
                    selectedBusinessTypes.remove(type.id);
                  }
                });
              },
              selectedColor: const Color.fromRGBO(215, 190, 105, 0.3),
              checkmarkColor: const Color(0xFFD7BE69),
              side: BorderSide(
                color: isSelected ? const Color(0xFFD7BE69) : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isFetchingBusinesses ? null : _fetchBusinesses,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isFetchingBusinesses
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(
              isFetchingBusinesses ? 'Fetching...' : 'Fetch All Businesses',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAssigning ? null : _assignAreas,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isAssigning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(
              isAssigning ? 'Assigning...' : 'Assign Areas to Salesman',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTab() {
    if (selectedSalesman == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Please select a salesman first',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No assignments yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(215, 190, 105, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_city, color: Color(0xFFD7BE69)),
            ),
            title: Text(
              '${assignment.city}, ${assignment.state}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Pin: ${assignment.pinCode} • ${assignment.areas.length} areas',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssignmentDetail('Country', assignment.country),
                    _buildAssignmentDetail('District', assignment.district),
                    const SizedBox(height: 12),
                    const Text(
                      'Assigned Areas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: assignment.areas
                          .map(
                            (area) => Chip(
                              label: Text(
                                area,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: const Color.fromRGBO(
                                215,
                                190,
                                105,
                                0.1,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Business Types:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: assignment.businessTypes.map((typeId) {
                        final type = businessTypes.firstWhere(
                          (t) => t.id == typeId,
                          orElse: () => BusinessType(
                            id: typeId,
                            name: typeId,
                            icon: '📦',
                          ),
                        );
                        return Chip(
                          label: Text(
                            '${type.icon} ${type.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[50],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Businesses:'),
                          Text(
                            '${assignment.totalBusinesses}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
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
        );
      },
    );
  }

  Widget _buildAssignmentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
