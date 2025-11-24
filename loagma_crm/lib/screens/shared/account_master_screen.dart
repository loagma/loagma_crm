import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/pincode_service.dart';
import '../../services/account_service.dart';
import '../view_all_masters_screen.dart';

class AccountMasterScreen extends StatefulWidget {
  const AccountMasterScreen({super.key});

  @override
  State<AccountMasterScreen> createState() => _AccountMasterScreenState();
}

class _AccountMasterScreenState extends State<AccountMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  bool isLoadingLocation = false;
  bool isLoadingAreas = false;
  bool isLoadingGeolocation = false;
  bool isCheckingContact = false;
  String? contactNumberError;
  Map<String, dynamic>? existingAccountData;

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

  // Business Type options
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

  // Business Size options
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

  Future<void> _checkContactNumber(String contactNumber) async {
    if (contactNumber.length != 10) return;

    setState(() {
      isCheckingContact = true;
      contactNumberError = null;
      existingAccountData = null;
    });

    try {
      final result = await AccountService.checkContactNumber(contactNumber);
      
      if (result['exists'] == true && result['data'] != null) {
        final account = result['data'];
        setState(() {
          contactNumberError = 'Contact number already exists';
          existingAccountData = account;
        });
      } else {
        setState(() {
          contactNumberError = null;
          existingAccountData = null;
        });
      }
    } catch (e) {
      print('Error checking contact number: $e');
    } finally {
      if (mounted) {
        setState(() => isCheckingContact = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingGeolocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        setState(() => isLoadingGeolocation = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => isLoadingGeolocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        setState(() => isLoadingGeolocation = false);
        return;
      }

      // Get current position
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
      if (mounted) {
        setState(() => isLoadingGeolocation = false);
      }
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_latitude == null || _longitude == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open Google Maps');
      }
    } catch (e) {
      _showError('Error opening Google Maps: $e');
    }
  }

  Future<void> _lookupPincode() async {
    final pincode = _pincodeController.text.trim();

    if (pincode.isEmpty) {
      _showError('Please enter pincode');
      return;
    }

    if (!PincodeService.isValidPincode(pincode)) {
      _showError('Pincode must be exactly 6 digits');
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

          // Load areas
          _availableAreas = List<Map<String, dynamic>>.from(
            data['areas'] ?? [],
          );
          _selectedArea = null; // Reset area selection
        });
        _showSuccess('Location details fetched successfully');
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
        setState(() {
          _availableAreas = [];
          _selectedArea = null;
        });
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          isLoadingAreas = false;
        });
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if contact number already exists
      if (contactNumberError != null) {
        _showError('Please use a different contact number');
        return;
      }

      setState(() => isSubmitting = true);

      try {
        await AccountService.createAccount(
          businessName: _businessNameController.text.trim().isEmpty
              ? null
              : _businessNameController.text.trim(),
          personName: _personNameController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          businessType: _selectedBusinessType,
          businessSize: _selectedBusinessSize,
          dateOfBirth: _dateOfBirth?.toIso8601String(),
          customerStage: _selectedCustomerStage,
          funnelStage: _selectedFunnelStage,
          gstNumber: _gstNumberController.text.trim().isEmpty
              ? null
              : _gstNumberController.text.trim().toUpperCase(),
          panCard: _panCardController.text.trim().isEmpty
              ? null
              : _panCardController.text.trim().toUpperCase(),
          ownerImage: _ownerImageBase64,
          shopImage: _shopImageBase64,
          isActive: _isActive,
          pincode: _pincodeController.text.trim().isEmpty
              ? null
              : _pincodeController.text.trim(),
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
          state: _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          district: _districtController.text.trim().isEmpty
              ? null
              : _districtController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          area: _selectedArea,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );

        _showSuccess('Account created successfully!');
        _clearForm();
      } catch (e) {
        _showError('Failed to create account: $e');
      } finally {
        if (mounted) {
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _businessNameController.clear();
      _personNameController.clear();
      _contactNumberController.clear();
      _gstNumberController.clear();
      _panCardController.clear();
      _pincodeController.clear();
      _countryController.clear();
      _stateController.clear();
      _districtController.clear();
      _cityController.clear();
      _addressController.clear();
      _selectedBusinessType = null;
      _selectedBusinessSize = null;
      _selectedArea = null;
      _selectedCustomerStage = null;
      _selectedFunnelStage = null;
      _dateOfBirth = null;
      _isActive = true;
      _latitude = null;
      _longitude = null;
      _ownerImageBase64 = null;
      _shopImageBase64 = null;
      _ownerImageFile = null;
      _shopImageFile = null;
      _availableAreas = [];
      contactNumberError = null;
      existingAccountData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Master'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View All Accounts',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewAllMastersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Business Information', Icons.business),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _contactNumberController,
                label: 'Contact Number *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Contact number is required';
                  if (v!.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.store,
                hint: 'Enter business name',
              ),
              const SizedBox(height: 15),

              _buildDropdown(
                value: _selectedBusinessType,
                label: 'Business Type *',
                icon: Icons.category,
                items: _businessTypes,
                onChanged: (v) => setState(() => _selectedBusinessType = v),
                validator: (v) =>
                    v == null ? 'Business type is required' : null,
              ),
              const SizedBox(height: 15),

              _buildDropdown(
                value: _selectedBusinessSize,
                label: 'Business Size *',
                icon: Icons.business_center,
                items: _businessSizes,
                onChanged: (v) => setState(() => _selectedBusinessSize = v),
                validator: (v) =>
                    v == null ? 'Business size is required' : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _personNameController,
                label: 'Person Name *',
                icon: Icons.person,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Person name is required' : null,
              ),
              const SizedBox(height: 15),

              _buildDropdown(
                value: _selectedCustomerStage,
                label: 'Customer Stage',
                icon: Icons.stairs,
                items: _customerStages,
                onChanged: (v) => setState(() => _selectedCustomerStage = v),
              ),
              const SizedBox(height: 15),

              _buildDropdown(
                value: _selectedFunnelStage,
                label: 'Funnel Stage',
                icon: Icons.filter_list,
                items: _funnelStages,
                onChanged: (v) => setState(() => _selectedFunnelStage = v),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _gstNumberController,
                label: 'GST Number',
                icon: Icons.receipt_long,
                hint: '22AAAAA0000A1Z5',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _panCardController,
                label: 'PAN Card',
                icon: Icons.credit_card,
                hint: 'ABCDE1234F',
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
              ),
              const SizedBox(height: 25),

              _buildSectionHeader('Images', Icons.image),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Owner Image',
                      imageFile: _ownerImageFile,
                      imageBase64: _ownerImageBase64,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Shop Image',
                      imageFile: _shopImageFile,
                      imageBase64: _shopImageBase64,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              _buildSectionHeader('Status', Icons.toggle_on),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: Text(_isActive ? 'Active' : 'Inactive'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: const Color(0xFFD7BE69),
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 25),

              _buildSectionHeader('Location Details', Icons.location_on),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      hint: '400001',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search, size: 20),
                      label: const Text('Lookup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7BE69),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isLoadingLocation ? null : _lookupPincode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _countryController,
                label: 'Country',
                icon: Icons.public,
                readOnly: true,
                filled: true,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _stateController,
                label: 'State',
                icon: Icons.map,
                readOnly: true,
                filled: true,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _districtController,
                label: 'District',
                icon: Icons.location_city,
                readOnly: true,
                filled: true,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.apartment,
                readOnly: true,
                filled: true,
              ),
              const SizedBox(height: 15),

              // Area Dropdown
              if (_availableAreas.isNotEmpty)
                Column(
                  children: [
                    _buildDropdown(
                      value: _selectedArea,
                      label: 'Area *',
                      icon: Icons.place,
                      items: _availableAreas
                          .map((area) => area['name'] as String)
                          .toList(),
                      onChanged: (v) => setState(() => _selectedArea = v),
                      validator: (v) =>
                          v == null ? 'Please select an area' : null,
                    ),
                    const SizedBox(height: 15),
                  ],
                )
              else if (isLoadingAreas)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_pincodeController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'No areas found for this pincode',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
                maxLines: 3,
                hint: 'Enter complete address manually',
              ),
              const SizedBox(height: 25),

              _buildSectionHeader('Geolocation', Icons.my_location),
              const SizedBox(height: 15),

              if (_latitude != null && _longitude != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Captured',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          _latitude = null;
                          _longitude = null;
                        }),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: isLoadingGeolocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isLoadingGeolocation
                      ? 'Getting Location...'
                      : 'Capture Current Location',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoadingGeolocation ? null : _getCurrentLocation,
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7BE69),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD7BE69),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFFD7BE69)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _clearForm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD7BE69).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7BE69).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD7BE69)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD7BE69),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
    String? hint,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool filled = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      enabled: true,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
        filled: filled,
        fillColor: filled ? Colors.grey[100] : null,
        counterText: maxLength != null ? '' : null,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required String? imageBase64,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD7BE69)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
        ),
        child: (imageFile != null && !kIsWeb)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : (imageBase64 != null && kIsWeb)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(imageBase64.split(',')[1]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Color(0xFFD7BE69),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFD7BE69),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }
}
