import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../services/pincode_service.dart';
import '../../services/account_service.dart';
import '../../models/account_model.dart';

class EditAccountMasterScreen extends StatefulWidget {
  final Account account;

  const EditAccountMasterScreen({super.key, required this.account});

  @override
  State<EditAccountMasterScreen> createState() =>
      _EditAccountMasterScreenState();
}

class _EditAccountMasterScreenState extends State<EditAccountMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  bool isLoadingLocation = false;
  bool isLoadingAreas = false;
  bool isLoadingGeolocation = false;

  // Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _personNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _gstNumberController;
  late TextEditingController _panCardController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _businessTypeController;
  late TextEditingController _areaController;

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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers with existing account data
    _businessNameController =
        TextEditingController(text: widget.account.businessName ?? '');
    _businessTypeController =
        TextEditingController(text: widget.account.businessType ?? '');
    _personNameController =
        TextEditingController(text: widget.account.personName);
    _contactNumberController =
        TextEditingController(text: widget.account.contactNumber);
    _gstNumberController =
        TextEditingController(text: widget.account.gstNumber ?? '');
    _panCardController =
        TextEditingController(text: widget.account.panCard ?? '');
    _pincodeController =
        TextEditingController(text: widget.account.pincode ?? '');
    _countryController =
        TextEditingController(text: widget.account.country ?? '');
    _stateController = TextEditingController(text: widget.account.state ?? '');
    _districtController =
        TextEditingController(text: widget.account.district ?? '');
    _cityController = TextEditingController(text: widget.account.city ?? '');
    _areaController = TextEditingController(text: widget.account.area ?? '');
    _addressController =
        TextEditingController(text: widget.account.address ?? '');

    _selectedCustomerStage = widget.account.customerStage;
    _selectedFunnelStage = widget.account.funnelStage;
    _dateOfBirth = widget.account.dateOfBirth;
    _isActive = widget.account.isActive ?? true;

    // Load existing images if available
    _ownerImageBase64 = widget.account.ownerImage;
    _shopImageBase64 = widget.account.shopImage;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _personNameController.dispose();
    _contactNumberController.dispose();
    _gstNumberController.dispose();
    _panCardController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _areaController.dispose();
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
          isOwnerImage ? 'Owner image updated' : 'Shop image updated',
        );
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
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

    setState(() => isLoadingLocation = true);

    try {
      final result = await PincodeService.getLocationByPincode(pincode);

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _countryController.text = data['country'] ?? '';
          _stateController.text = data['state'] ?? '';
          _districtController.text = data['district'] ?? '';
          _cityController.text = data['city'] ?? '';
          _areaController.text = data['area'] ?? '';
        });
        _showSuccess('Location details fetched successfully');
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLocation = false);
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
      setState(() => isSubmitting = true);

      try {
        final updates = <String, dynamic>{};

        // Only include changed fields
        if (_businessNameController.text.trim().isNotEmpty) {
          updates['businessName'] = _businessNameController.text.trim();
        }
        if (_personNameController.text.trim() != widget.account.personName) {
          updates['personName'] = _personNameController.text.trim();
        }
        if (_contactNumberController.text.trim() !=
            widget.account.contactNumber) {
          updates['contactNumber'] = _contactNumberController.text.trim();
        }
        if (_businessTypeController.text.trim().isNotEmpty) {
          updates['businessType'] = _businessTypeController.text.trim();
        }
        if (_dateOfBirth != null) {
          updates['dateOfBirth'] = _dateOfBirth!.toIso8601String();
        }
        if (_selectedCustomerStage != null) {
          updates['customerStage'] = _selectedCustomerStage;
        }
        if (_selectedFunnelStage != null) {
          updates['funnelStage'] = _selectedFunnelStage;
        }
        if (_gstNumberController.text.trim().isNotEmpty) {
          updates['gstNumber'] =
              _gstNumberController.text.trim().toUpperCase();
        }
        if (_panCardController.text.trim().isNotEmpty) {
          updates['panCard'] = _panCardController.text.trim().toUpperCase();
        }
        if (_ownerImageBase64 != null) {
          updates['ownerImage'] = _ownerImageBase64;
        }
        if (_shopImageBase64 != null) {
          updates['shopImage'] = _shopImageBase64;
        }
        updates['isActive'] = _isActive;

        if (_pincodeController.text.trim().isNotEmpty) {
          updates['pincode'] = _pincodeController.text.trim();
        }
        if (_countryController.text.trim().isNotEmpty) {
          updates['country'] = _countryController.text.trim();
        }
        if (_stateController.text.trim().isNotEmpty) {
          updates['state'] = _stateController.text.trim();
        }
        if (_districtController.text.trim().isNotEmpty) {
          updates['district'] = _districtController.text.trim();
        }
        if (_cityController.text.trim().isNotEmpty) {
          updates['city'] = _cityController.text.trim();
        }
        if (_areaController.text.trim().isNotEmpty) {
          updates['area'] = _areaController.text.trim();
        }
        if (_addressController.text.trim().isNotEmpty) {
          updates['address'] = _addressController.text.trim();
        }

        await AccountService.updateAccount(widget.account.id, updates);

        _showSuccess('Account updated successfully!');
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        _showError('Failed to update account: $e');
      } finally {
        if (mounted) {
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account Master'),
        backgroundColor: const Color(0xFFD7BE69),
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
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.store,
                hint: 'Enter business name',
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _businessTypeController,
                label: 'Business Type',
                icon: Icons.category,
                hint: 'e.g., Retail, Wholesale',
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
              _buildTextField(
                controller: _areaController,
                label: 'Area',
                icon: Icons.place,
                readOnly: true,
                filled: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
                maxLines: 3,
                hint: 'Enter complete address manually',
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
                      label: Text(isSubmitting ? 'Updating...' : 'Update'),
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
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD7BE69),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFFD7BE69)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
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
