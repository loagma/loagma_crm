import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/pincode_service.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isEditing = false;
  bool isLoadingLocation = false;
  bool isLoadingAreas = false;
  bool isLoadingGeolocation = false;

  Account? _account;

  // Controllers
  final _businessNameController = TextEditingController();
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _panCardController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Dropdown values
  String? _selectedBusinessType;
  String? _selectedBusinessSize;
  String? _selectedArea;
  String? _selectedCustomerStage;
  String? _selectedFunnelStage;
  DateTime? _dateOfBirth;
  bool _isActive = true;

  // Geolocation
  double? _latitude;
  double? _longitude;

  // Images
  String? _ownerImageBase64;
  String? _shopImageBase64;
  File? _ownerImageFile;
  File? _shopImageFile;

  // Areas list
  List<Map<String, dynamic>> _availableAreas = [];

  // Options
  final List<String> _businessTypes = [
    'Kirana Store',
    'Sweet Shop',
    'Restaurant',
    'Bakery',
    'Caterer',
    'Hostel',
    'Hotel',
    'Cafe',
    'Other',
  ];
  final List<String> _businessSizes = [
    'Semi Retailer',
    'Retailer',
    'Semi Wholesaler',
    'Wholesaler',
    'Home Buyer',
  ];
  final List<String> _customerStages = [
    'Lead',
    'Prospect',
    'Customer',
    'Inactive',
  ];
  final List<String> _funnelStages = [
    'Awareness',
    'Interest',
    'Consideration',
    'Intent',
    'Evaluation',
    'Converted',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _personNameController.dispose();
    _contactNumberController.dispose();
    _gstNumberController.dispose();
    _panCardController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await AccountService.fetchAccountById(widget.accountId);

      // Debug: Print latitude and longitude
      print(
        '📍 Account loaded - Latitude: ${account.latitude}, Longitude: ${account.longitude}',
      );

      setState(() {
        _account = account;
        _businessNameController.text = account.businessName ?? '';
        _personNameController.text = account.personName;
        _contactNumberController.text = account.contactNumber;
        _selectedBusinessType = account.businessType;
        _selectedBusinessSize = account.businessSize;
        _gstNumberController.text = account.gstNumber ?? '';
        _panCardController.text = account.panCard ?? '';
        _selectedCustomerStage = account.customerStage;
        _selectedFunnelStage = account.funnelStage;
        _dateOfBirth = account.dateOfBirth;
        _isActive = account.isActive ?? true;
        _pincodeController.text = account.pincode ?? '';
        _countryController.text = account.country ?? '';
        _stateController.text = account.state ?? '';
        _districtController.text = account.district ?? '';
        _cityController.text = account.city ?? '';
        _selectedArea = account.area;
        _addressController.text = account.address ?? '';
        _latitude = account.latitude;
        _longitude = account.longitude;
        _ownerImageBase64 = account.ownerImage;
        _shopImageBase64 = account.shopImage;
        _isLoading = false;
      });

      print('📍 State updated - Latitude: $_latitude, Longitude: $_longitude');

      if (account.pincode != null && account.pincode!.isNotEmpty) {
        _lookupPincode();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load account: $e');
    }
  }

  Future<void> _pickImage(bool isOwnerImage) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          if (isOwnerImage) {
            if (!kIsWeb) _ownerImageFile = File(image.path);
            _ownerImageBase64 = 'data:image/jpeg;base64,$base64Image';
          } else {
            if (!kIsWeb) _shopImageFile = File(image.path);
            _shopImageBase64 = 'data:image/jpeg;base64,$base64Image';
          }
        });
        _showSuccess(
          isOwnerImage ? 'Owner image selected' : 'Shop image selected',
        );
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingGeolocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        setState(() => isLoadingGeolocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => isLoadingGeolocation = false);
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _showSuccess(
        'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      if (mounted) setState(() => isLoadingGeolocation = false);
    }
  }

  Future<void> _lookupPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.isEmpty || !PincodeService.isValidPincode(pincode)) {
      _showError('Please enter valid 6-digit pincode');
      return;
    }
    setState(() {
      isLoadingLocation = true;
      isLoadingAreas = true;
    });
    try {
      final result = await PincodeService.getAreasByPincode(pincode);
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _countryController.text = data['country'] ?? '';
          _stateController.text = data['state'] ?? '';
          _districtController.text = data['district'] ?? '';
          _cityController.text = data['city'] ?? '';
          _availableAreas = List<Map<String, dynamic>>.from(
            data['areas'] ?? [],
          );
          if (_selectedArea != null &&
              !_availableAreas.any((a) => a['name'] == _selectedArea)) {
            _selectedArea = null;
          }
        });
        _showSuccess('Location details fetched');
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
        setState(() {
          _availableAreas = [];
          _selectedArea = null;
        });
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted)
        setState(() {
          isLoadingLocation = false;
          isLoadingAreas = false;
        });
    }
  }

  Future<void> _updateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final updates = {
          'businessName': _businessNameController.text.trim().isEmpty
              ? null
              : _businessNameController.text.trim(),
          'personName': _personNameController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          'businessType': _selectedBusinessType,
          'businessSize': _selectedBusinessSize,
          if (_dateOfBirth != null)
            'dateOfBirth': _dateOfBirth!.toIso8601String(),
          'customerStage': _selectedCustomerStage,
          'funnelStage': _selectedFunnelStage,
          'gstNumber': _gstNumberController.text.trim().isEmpty
              ? null
              : _gstNumberController.text.trim().toUpperCase(),
          'panCard': _panCardController.text.trim().isEmpty
              ? null
              : _panCardController.text.trim().toUpperCase(),
          'ownerImage': _ownerImageBase64,
          'shopImage': _shopImageBase64,
          'isActive': _isActive,
          'pincode': _pincodeController.text.trim().isEmpty
              ? null
              : _pincodeController.text.trim(),
          'country': _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
          'state': _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          'district': _districtController.text.trim().isEmpty
              ? null
              : _districtController.text.trim(),
          'city': _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          'area': _selectedArea,
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
        };
        await AccountService.updateAccount(widget.accountId, updates);
        _showSuccess('Account updated successfully');
        setState(() => _isEditing = false);
        _loadAccount();
      } catch (e) {
        _showError('Failed to update: $e');
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _account == null
          ? const Center(child: Text('Account not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isEditing ? _buildEditForm() : _buildViewMode(),
            ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _account!.personName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_account!.businessName != null)
                  Text(
                    _account!.businessName!,
                    style: const TextStyle(fontSize: 18),
                  ),
                Text(
                  _account!.accountCode,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        _account!.isApproved ? 'Approved' : 'Pending',
                      ),
                      backgroundColor: _account!.isApproved
                          ? Colors.green[100]
                          : Colors.orange[100],
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(_account!.isActive! ? 'Active' : 'Inactive'),
                      backgroundColor: _account!.isActive!
                          ? Colors.blue[100]
                          : Colors.red[100],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildDetailRow('Contact', _account!.contactNumber),
                if (_account!.businessType != null)
                  _buildDetailRow('Business Type', _account!.businessType!),
                if (_account!.businessSize != null)
                  _buildDetailRow('Business Size', _account!.businessSize!),
                if (_account!.gstNumber != null)
                  _buildDetailRow('GST', _account!.gstNumber!),
                if (_account!.panCard != null)
                  _buildDetailRow('PAN', _account!.panCard!),
                if (_account!.customerStage != null)
                  _buildDetailRow('Customer Stage', _account!.customerStage!),
                if (_account!.funnelStage != null)
                  _buildDetailRow('Funnel Stage', _account!.funnelStage!),
              ],
            ),
          ),
        ),
        if (_account!.pincode != null ||
            _account!.address != null ||
            _account!.latitude != null) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (_account!.pincode != null)
                    _buildDetailRow('Pincode', _account!.pincode!),
                  if (_account!.area != null)
                    _buildDetailRow('Area', _account!.area!),
                  if (_account!.city != null)
                    _buildDetailRow('City', _account!.city!),
                  if (_account!.district != null)
                    _buildDetailRow('District', _account!.district!),
                  if (_account!.state != null)
                    _buildDetailRow('State', _account!.state!),
                  if (_account!.country != null)
                    _buildDetailRow('Country', _account!.country!),
                  if (_account!.address != null)
                    _buildDetailRow('Address', _account!.address!),
                  if (_account!.latitude != null && _account!.longitude != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Color(0xFFD7BE69),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GPS Coordinates',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitude: ${_account!.latitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Longitude: ${_account!.longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
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
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Edit Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _personNameController,
            decoration: const InputDecoration(
              labelText: 'Person Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _contactNumberController,
            decoration: const InputDecoration(
              labelText: 'Contact Number *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (v!.length != 10) return 'Must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            decoration: const InputDecoration(
              labelText: 'Business Type',
              border: OutlineInputBorder(),
            ),
            items: _businessTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _selectedBusinessType = v),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedBusinessSize,
            decoration: const InputDecoration(
              labelText: 'Business Size',
              border: OutlineInputBorder(),
            ),
            items: _businessSizes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedBusinessSize = v),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _gstNumberController,
            decoration: const InputDecoration(
              labelText: 'GST Number',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _panCardController,
            decoration: const InputDecoration(
              labelText: 'PAN Card',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isLoadingLocation ? null : _lookupPincode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lookup'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_availableAreas.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
              items: _availableAreas
                  .map(
                    (a) => DropdownMenuItem(
                      value: a['name'] as String,
                      child: Text(a['name']),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedArea = v),
            ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            icon: isLoadingGeolocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              isLoadingGeolocation ? 'Getting Location...' : 'Capture Location',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: isLoadingGeolocation ? null : _getCurrentLocation,
          ),
          if (_latitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Active Status'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _isSubmitting ? null : _updateAccount,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadAccount();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
