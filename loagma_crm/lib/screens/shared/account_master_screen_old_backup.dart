import 'package:flutter/material.dart';
import '../../services/location_service.dart';
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
  bool isLoadingLocations = false;

  // Controllers
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _businessTypeController = TextEditingController();

  // Dropdown values
  String? _selectedCustomerStage;
  String? _selectedFunnelStage;
  DateTime? _dateOfBirth;

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

  final List<String> _customerStages = ['Lead', 'Prospect', 'Customer'];
  final List<String> _funnelStages = ['Awareness', 'Interest', 'Converted'];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => isLoadingLocations = true);
    try {
      final countries = await LocationService.getCountries();
      setState(() {
        _countries = countries;
        isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => isLoadingLocations = false);
      _showError('Failed to load countries: $e');
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
      _showError('Failed to load states: $e');
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
      _showError('Failed to load regions: $e');
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
      _showError('Failed to load districts: $e');
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
      _showError('Failed to load cities: $e');
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
      _showError('Failed to load zones: $e');
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
      _showError('Failed to load areas: $e');
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _contactNumberController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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
      setState(() => _dateOfBirth = picked);
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
        final account = await AccountService.createAccount(
          personName: _personNameController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          dateOfBirth: _dateOfBirth?.toIso8601String(),
          businessType: _businessTypeController.text.trim().isEmpty
              ? null
              : _businessTypeController.text.trim(),
          customerStage: _selectedCustomerStage,
          funnelStage: _selectedFunnelStage,
          areaId: _selectedAreaId,
        );

        _showSuccess(
          'Account created successfully! Code: ${account.accountCode}',
        );

        // Clear form
        _formKey.currentState?.reset();
        setState(() {
          _personNameController.clear();
          _contactNumberController.clear();
          _businessTypeController.clear();
          _selectedCustomerStage = null;
          _selectedFunnelStage = null;
          _dateOfBirth = null;
          _selectedCountryId = null;
          _selectedStateId = null;
          _selectedRegionId = null;
          _selectedDistrictId = null;
          _selectedCityId = null;
          _selectedZoneId = null;
          _selectedAreaId = null;
        });
      } catch (e) {
        _showError('Failed to create account: $e');
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
              // Header
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7BE69),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_box, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Account Master',
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

              // Person Name
              _buildTextField(
                controller: _personNameController,
                label: 'Person Name *',
                icon: Icons.person,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // Contact Number
              _buildTextField(
                controller: _contactNumberController,
                label: 'Contact Number *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Date of Birth
              _buildDateField(
                label: 'Date of Birth',
                icon: Icons.cake,
                date: _dateOfBirth,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 15),

              // Business Type
              _buildTextField(
                controller: _businessTypeController,
                label: 'Business Type',
                icon: Icons.business,
              ),
              const SizedBox(height: 15),

              // Customer Stage
              _buildDropdown(
                value: _selectedCustomerStage,
                label: 'Customer Stage',
                icon: Icons.stairs,
                items: _customerStages,
                onChanged: (v) => setState(() => _selectedCustomerStage = v),
              ),
              const SizedBox(height: 15),

              // Funnel Stage
              _buildDropdown(
                value: _selectedFunnelStage,
                label: 'Funnel Stage',
                icon: Icons.filter_list,
                items: _funnelStages,
                onChanged: (v) => setState(() => _selectedFunnelStage = v),
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
                      'Location Details',
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
                      onPressed: () {
                        _formKey.currentState?.reset();
                        setState(() {
                          _personNameController.clear();
                          _contactNumberController.clear();
                          _businessTypeController.clear();
                          _selectedCustomerStage = null;
                          _selectedFunnelStage = null;
                          _dateOfBirth = null;
                          _selectedCountryId = null;
                          _selectedStateId = null;
                          _selectedRegionId = null;
                          _selectedDistrictId = null;
                          _selectedCityId = null;
                          _selectedZoneId = null;
                          _selectedAreaId = null;
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
