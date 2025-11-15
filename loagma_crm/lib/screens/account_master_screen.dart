import 'package:flutter/material.dart';
import '../services/location_service.dart';

class AccountMasterScreen extends StatefulWidget {
  const AccountMasterScreen({super.key});

  @override
  State<AccountMasterScreen> createState() => _AccountMasterScreenState();
}

class _AccountMasterScreenState extends State<AccountMasterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _businessTypeController = TextEditingController();

  // Dropdown values
  DateTime? _dateOfBirth;
  String? _customerStage;
  String? _funnelStage;

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

  bool _isSubmitting = false;

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
    'Purchase',
  ];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _contactNumberController.dispose();
    _businessTypeController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        // TODO: Implement account creation API call
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Master'),
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
                    Icon(Icons.account_circle, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Create New Account',
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
              TextFormField(
                controller: _personNameController,
                decoration: InputDecoration(
                  labelText: 'Person Name *',
                  prefixIcon: const Icon(
                    Icons.person,
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
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // Contact Number
              TextFormField(
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Number *',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFD7BE69)),
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
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: const Icon(
                      Icons.cake,
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
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select Date',
                    style: TextStyle(
                      color: _dateOfBirth != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Business Type
              TextFormField(
                controller: _businessTypeController,
                decoration: InputDecoration(
                  labelText: 'Business Type',
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
              ),
              const SizedBox(height: 15),

              // Customer Stage
              DropdownButtonFormField<String>(
                value: _customerStage,
                decoration: InputDecoration(
                  labelText: 'Customer Stage',
                  prefixIcon: const Icon(
                    Icons.stairs,
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
                items: _customerStages.map((stage) {
                  return DropdownMenuItem(value: stage, child: Text(stage));
                }).toList(),
                onChanged: (v) => setState(() => _customerStage = v),
              ),
              const SizedBox(height: 15),

              // Funnel Stage
              DropdownButtonFormField<String>(
                value: _funnelStage,
                decoration: InputDecoration(
                  labelText: 'Funnel Stage',
                  prefixIcon: const Icon(
                    Icons.filter_alt,
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
                items: _funnelStages.map((stage) {
                  return DropdownMenuItem(value: stage, child: Text(stage));
                }).toList(),
                onChanged: (v) => setState(() => _funnelStage = v),
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
                label: 'Country *',
                icon: Icons.public,
                items: _countries,
                idKey: 'country_id',
                nameKey: 'country_name',
                onChanged: (value) {
                  setState(() => _selectedCountryId = value);
                  if (value != null) _loadStates(value);
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // State
              _buildLocationDropdown<int>(
                value: _selectedStateId,
                label: 'State *',
                icon: Icons.map,
                items: _states,
                idKey: 'state_id',
                nameKey: 'state_name',
                onChanged: (value) {
                  setState(() => _selectedStateId = value);
                  if (value != null) _loadRegions(value);
                },
                enabled: _selectedCountryId != null,
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // Region
              _buildLocationDropdown<int>(
                value: _selectedRegionId,
                label: 'Region *',
                icon: Icons.terrain,
                items: _regions,
                idKey: 'region_id',
                nameKey: 'region_name',
                onChanged: (value) {
                  setState(() => _selectedRegionId = value);
                  if (value != null) _loadDistricts(value);
                },
                enabled: _selectedStateId != null,
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // District
              _buildLocationDropdown<int>(
                value: _selectedDistrictId,
                label: 'District *',
                icon: Icons.location_city,
                items: _districts,
                idKey: 'district_id',
                nameKey: 'district_name',
                onChanged: (value) {
                  setState(() => _selectedDistrictId = value);
                  if (value != null) _loadCities(value);
                },
                enabled: _selectedRegionId != null,
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // City
              _buildLocationDropdown<int>(
                value: _selectedCityId,
                label: 'City *',
                icon: Icons.apartment,
                items: _cities,
                idKey: 'city_id',
                nameKey: 'city_name',
                onChanged: (value) {
                  setState(() => _selectedCityId = value);
                  if (value != null) _loadZones(value);
                },
                enabled: _selectedDistrictId != null,
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // Zone
              _buildLocationDropdown<int>(
                value: _selectedZoneId,
                label: 'Zone *',
                icon: Icons.explore,
                items: _zones,
                idKey: 'zone_id',
                nameKey: 'zone_name',
                onChanged: (value) {
                  setState(() => _selectedZoneId = value);
                  if (value != null) _loadAreas(value);
                },
                enabled: _selectedCityId != null,
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // Area
              _buildLocationDropdown<int>(
                value: _selectedAreaId,
                label: 'Area *',
                icon: Icons.place,
                items: _areas,
                idKey: 'area_id',
                nameKey: 'area_name',
                onChanged: (value) => setState(() => _selectedAreaId = value),
                enabled: _selectedZoneId != null,
                validator: (v) => v == null ? 'Required' : null,
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
                          _personNameController.clear();
                          _contactNumberController.clear();
                          _businessTypeController.clear();
                          _dateOfBirth = null;
                          _customerStage = null;
                          _funnelStage = null;
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

  Widget _buildLocationDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required void Function(T?) onChanged,
    bool enabled = true,
    String? Function(T?)? validator,
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
      validator: validator,
    );
  }
}
