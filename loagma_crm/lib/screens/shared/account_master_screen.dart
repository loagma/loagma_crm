import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
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

  // Controllers
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _panCardController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();

  // Dropdown values
  String? _selectedCustomerStage;
  String? _selectedFunnelStage;
  DateTime? _dateOfBirth;
  bool _isActive = true;

  // Images
  String? _ownerImageBase64;
  String? _shopImageBase64;
  File? _ownerImageFile;
  File? _shopImageFile;

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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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
        print(
          '📤 Submitting account with contact number: ${_contactNumberController.text.trim()}',
        );

        await AccountService.createAccount(
          businessName: _businessNameController.text.trim().isEmpty
              ? null
              : _businessNameController.text.trim(),
          personName: _personNameController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          businessType: _businessTypeController.text.trim().isEmpty
              ? null
              : _businessTypeController.text.trim(),
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
          area: _areaController.text.trim().isEmpty
              ? null
              : _areaController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        print('✅ Account created successfully');
        _showSuccess('Account created successfully!');
        _clearForm();
      } catch (e) {
        print('❌ Error creating account: $e');
        print('Error type: ${e.runtimeType}');
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
      _businessTypeController.clear();
      _personNameController.clear();
      _contactNumberController.clear();
      _gstNumberController.clear();
      _panCardController.clear();
      _pincodeController.clear();
      _countryController.clear();
      _stateController.clear();
      _districtController.clear();
      _cityController.clear();
      _areaController.clear();
      _addressController.clear();
      _selectedCustomerStage = null;
      _selectedFunnelStage = null;
      _dateOfBirth = null;
      _isActive = true;
      _ownerImageBase64 = null;
      _shopImageBase64 = null;
      _ownerImageFile = null;
      _shopImageFile = null;
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
            onPressed: () {
              Navigator.push(
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
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                    ).hasMatch(v.toUpperCase())) {
                      return 'Invalid GST format';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _panCardController,
                label: 'PAN Card',
                icon: Icons.credit_card,
                hint: 'ABCDE1234F',
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(
                      r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
                    ).hasMatch(v.toUpperCase())) {
                      return 'Invalid PAN format';
                    }
                  }
                  return null;
                },
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
