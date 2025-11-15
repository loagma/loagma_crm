import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import '../services/master_service.dart';
import '../services/location_service.dart';

class EmployeeAccountMasterScreen extends StatefulWidget {
  const EmployeeAccountMasterScreen({super.key});

  @override
  State<EmployeeAccountMasterScreen> createState() =>
      _EmployeeAccountMasterScreenState();
}

class _EmployeeAccountMasterScreenState
    extends State<EmployeeAccountMasterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _employeeCodeController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _designationController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedDepartmentId;
  String? _selectedPostUnder;
  String? _selectedJobPost;
  DateTime? _dateOfBirth;
  DateTime? _joiningDate;
  bool _isActive = true;
  bool _isSubmitting = false;
  bool _isLoadingDepartments = false;
  List<String> _selectedLanguages = [];

  // Location dropdowns
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedRegionId;
  int? _selectedDistrictId;
  int? _selectedCityId;
  int? _selectedZoneId;
  int? _selectedAreaId;

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _areas = [];

  // Dropdown options
  final List<String> _genders = ['Male', 'Female', 'Other'];
  List<Map<String, dynamic>> _departments = [];
  final List<String> _postUnderOptions = [
    'Manager',
    'Team Lead',
    'Senior Executive',
  ];
  final List<String> _jobPostOptions = [
    'Sales Executive',
    'Marketing Executive',
    'HR Executive',
    'IT Support',
    'Accountant',
  ];
  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Bengali',
    'Gujarati',
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadCountries();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoadingDepartments = true);
    try {
      final departments = await MasterService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => _isLoadingDepartments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load departments: $e')),
        );
      }
    }
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await LocationService.getCountries();
      setState(() => _countries = countries);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadStates(int countryId) async {
    setState(() {
      _selectedStateId = null;
      _selectedRegionId = null;
      _selectedDistrictId = null;
      _selectedCityId = null;
      _selectedZoneId = null;
      _selectedAreaId = null;
      _states = [];
      _regions = [];
      _districts = [];
      _cities = [];
      _zones = [];
      _areas = [];
    });
    try {
      final states = await LocationService.getStates(countryId: countryId);
      setState(() => _states = states);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadRegions(int stateId) async {
    setState(() {
      _selectedRegionId = null;
      _selectedDistrictId = null;
      _selectedCityId = null;
      _selectedZoneId = null;
      _selectedAreaId = null;
      _regions = [];
      _districts = [];
      _cities = [];
      _zones = [];
      _areas = [];
    });
    try {
      final regions = await LocationService.getRegions(stateId: stateId);
      setState(() => _regions = regions);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadDistricts(int regionId) async {
    setState(() {
      _selectedDistrictId = null;
      _selectedCityId = null;
      _selectedZoneId = null;
      _selectedAreaId = null;
      _districts = [];
      _cities = [];
      _zones = [];
      _areas = [];
    });
    try {
      final districts = await LocationService.getDistricts(regionId: regionId);
      setState(() => _districts = districts);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCities(int districtId) async {
    setState(() {
      _selectedCityId = null;
      _selectedZoneId = null;
      _selectedAreaId = null;
      _cities = [];
      _zones = [];
      _areas = [];
    });
    try {
      final cities = await LocationService.getCities(districtId: districtId);
      setState(() => _cities = cities);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadZones(int cityId) async {
    setState(() {
      _selectedZoneId = null;
      _selectedAreaId = null;
      _zones = [];
      _areas = [];
    });
    try {
      final zones = await LocationService.getZones(cityId: cityId);
      setState(() => _zones = zones);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadAreas(int zoneId) async {
    setState(() {
      _selectedAreaId = null;
      _areas = [];
    });
    try {
      final areas = await LocationService.getAreas(zoneId: zoneId);
      setState(() => _areas = areas);
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _employeeNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFD7BE69)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _dateOfBirth = picked;
        } else {
          _joiningDate = picked;
        }
      });
    }
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Preferred Languages'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _languages.map((lang) {
                    return CheckboxListTile(
                      title: Text(lang),
                      value: _selectedLanguages.contains(lang),
                      activeColor: const Color(0xFFD7BE69),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedLanguages.add(lang);
                          } else {
                            _selectedLanguages.remove(lang);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final response = await EmployeeService.createEmployee(
          employeeCode: _employeeCodeController.text.trim().isEmpty
              ? null
              : _employeeCodeController.text.trim(),
          name: _employeeNameController.text.trim(),
          email: _emailController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          designation: _designationController.text.trim().isEmpty
              ? null
              : _designationController.text.trim(),
          dateOfBirth: _dateOfBirth?.toIso8601String(),
          gender: _selectedGender,
          nationality: _nationalityController.text.trim().isEmpty
              ? null
              : _nationalityController.text.trim(),
          departmentId: _selectedDepartmentId,
          postUnder: _selectedPostUnder,
          jobPost: _selectedJobPost,
          joiningDate: _joiningDate?.toIso8601String(),
          preferredLanguages: _selectedLanguages,
          isActive: _isActive,
        );

        if (response['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_employeeCodeController.text.isEmpty &&
        _employeeNameController.text.isEmpty &&
        _contactNumberController.text.isEmpty &&
        _emailController.text.isEmpty) {
      return true; // Allow back if form is empty
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'Are you sure you want to go back? All unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employee Account Master'),
          backgroundColor: const Color(0xFFD7BE69),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7BE69),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Employee Account Master',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Employee Code
                _buildTextField(
                  controller: _employeeCodeController,
                  label: 'Employee Code *',
                  icon: Icons.badge,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 15),

                // Employee Name
                _buildTextField(
                  controller: _employeeNameController,
                  label: 'Employee Name *',
                  icon: Icons.person_outline,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 15),

                // Contact Number
                _buildTextField(
                  controller: _contactNumberController,
                  label: 'Employee Contact Number *',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email ID
                _buildTextField(
                  controller: _emailController,
                  label: 'Employee Email ID *',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Designation
                _buildTextField(
                  controller: _designationController,
                  label: 'Employee Designation',
                  icon: Icons.work,
                ),
                const SizedBox(height: 15),

                // Date of Birth
                _buildDateField(
                  label: 'Employee Date of Birth',
                  icon: Icons.cake,
                  date: _dateOfBirth,
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 15),

                // Gender
                _buildDropdown(
                  value: _selectedGender,
                  label: 'Employee Gender',
                  icon: Icons.wc,
                  items: _genders,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 15),

                // Nationality
                _buildTextField(
                  controller: _nationalityController,
                  label: 'Nationality',
                  icon: Icons.flag,
                ),
                const SizedBox(height: 15),

                // Employee Image (placeholder)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.image, color: Color(0xFFD7BE69)),
                    title: const Text('Employee Image'),
                    subtitle: const Text('Tap to upload'),
                    trailing: const Icon(Icons.upload),
                    onTap: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image upload coming soon'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // Department
                _isLoadingDepartments
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        decoration: InputDecoration(
                          labelText: 'Employee Department *',
                          prefixIcon: const Icon(
                            Icons.business,
                            color: Color(0xFFD7BE69),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFD7BE69),
                              width: 2,
                            ),
                          ),
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept['id'] as String,
                            child: Text(dept['name'] as String),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedDepartmentId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                const SizedBox(height: 15),

                // Post Under
                _buildDropdown(
                  value: _selectedPostUnder,
                  label: 'Employee Post Under',
                  icon: Icons.supervisor_account,
                  items: _postUnderOptions,
                  onChanged: (v) => setState(() => _selectedPostUnder = v),
                ),
                const SizedBox(height: 15),

                // Job Post
                _buildDropdown(
                  value: _selectedJobPost,
                  label: 'Employee Job Post',
                  icon: Icons.work_outline,
                  items: _jobPostOptions,
                  onChanged: (v) => setState(() => _selectedJobPost = v),
                ),
                const SizedBox(height: 15),

                // Joining Date
                _buildDateField(
                  label: 'Employee Joining Date',
                  icon: Icons.calendar_today,
                  date: _joiningDate,
                  onTap: () => _selectDate(context, false),
                ),
                const SizedBox(height: 15),

                // Active Status
                SwitchListTile(
                  title: const Text('Employee Active (Yes/No)'),
                  value: _isActive,
                  activeColor: const Color(0xFFD7BE69),
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 15),

                // Preferred Languages
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: Color(0xFFD7BE69),
                    ),
                    title: const Text('Employee Preferred Languages'),
                    subtitle: Text(
                      _selectedLanguages.isEmpty
                          ? 'Tap to select'
                          : _selectedLanguages.join(', '),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showLanguageSelector,
                  ),
                ),
                const SizedBox(height: 25),

                // Location Section Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFFD7BE69)),
                      SizedBox(width: 10),
                      Text(
                        'Employee Location Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Country
                _buildLocationDropdown<int>(
                  value: _selectedCountryId,
                  label: 'Country',
                  icon: Icons.public,
                  items: _countries,
                  idKey: 'country_id',
                  nameKey: 'country_name',
                  onChanged: (value) {
                    setState(() => _selectedCountryId = value);
                    if (value != null) _loadStates(value);
                  },
                ),
                const SizedBox(height: 15),

                // State
                _buildLocationDropdown<int>(
                  value: _selectedStateId,
                  label: 'State',
                  icon: Icons.map,
                  items: _states,
                  idKey: 'state_id',
                  nameKey: 'state_name',
                  onChanged: (value) {
                    setState(() => _selectedStateId = value);
                    if (value != null) _loadRegions(value);
                  },
                  enabled: _selectedCountryId != null,
                ),
                const SizedBox(height: 15),

                // Region
                _buildLocationDropdown<int>(
                  value: _selectedRegionId,
                  label: 'Region',
                  icon: Icons.terrain,
                  items: _regions,
                  idKey: 'region_id',
                  nameKey: 'region_name',
                  onChanged: (value) {
                    setState(() => _selectedRegionId = value);
                    if (value != null) _loadDistricts(value);
                  },
                  enabled: _selectedStateId != null,
                ),
                const SizedBox(height: 15),

                // District
                _buildLocationDropdown<int>(
                  value: _selectedDistrictId,
                  label: 'District',
                  icon: Icons.location_city,
                  items: _districts,
                  idKey: 'district_id',
                  nameKey: 'district_name',
                  onChanged: (value) {
                    setState(() => _selectedDistrictId = value);
                    if (value != null) _loadCities(value);
                  },
                  enabled: _selectedRegionId != null,
                ),
                const SizedBox(height: 15),

                // City
                _buildLocationDropdown<int>(
                  value: _selectedCityId,
                  label: 'City',
                  icon: Icons.apartment,
                  items: _cities,
                  idKey: 'city_id',
                  nameKey: 'city_name',
                  onChanged: (value) {
                    setState(() => _selectedCityId = value);
                    if (value != null) _loadZones(value);
                  },
                  enabled: _selectedDistrictId != null,
                ),
                const SizedBox(height: 15),

                // Zone
                _buildLocationDropdown<int>(
                  value: _selectedZoneId,
                  label: 'Zone',
                  icon: Icons.explore,
                  items: _zones,
                  idKey: 'zone_id',
                  nameKey: 'zone_name',
                  onChanged: (value) {
                    setState(() => _selectedZoneId = value);
                    if (value != null) _loadAreas(value);
                  },
                  enabled: _selectedCityId != null,
                ),
                const SizedBox(height: 15),

                // Area
                _buildLocationDropdown<int>(
                  value: _selectedAreaId,
                  label: 'Area',
                  icon: Icons.place,
                  items: _areas,
                  idKey: 'area_id',
                  nameKey: 'area_name',
                  onChanged: (value) {
                    setState(() => _selectedAreaId = value);
                  },
                  enabled: _selectedZoneId != null,
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7BE69),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
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
                        onPressed: () {
                          _formKey.currentState?.reset();
                          setState(() {
                            _employeeCodeController.clear();
                            _employeeNameController.clear();
                            _contactNumberController.clear();
                            _emailController.clear();
                            _designationController.clear();
                            _nationalityController.clear();
                            _selectedGender = null;
                            _selectedDepartmentId = null;
                            _selectedPostUnder = null;
                            _selectedJobPost = null;
                            _dateOfBirth = null;
                            _joiningDate = null;
                            _selectedLanguages = [];
                            _selectedCountryId = null;
                            _selectedStateId = null;
                            _selectedRegionId = null;
                            _selectedDistrictId = null;
                            _selectedCityId = null;
                            _selectedZoneId = null;
                            _selectedAreaId = null;
                            _isActive = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
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

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
          ),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select Date',
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item[idKey] as T,
          child: Text(item[nameKey] as String),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
