import 'package:flutter/material.dart';
import '../models/location_models.dart' as models;
import '../services/location_service.dart';
import '../services/account_service.dart';
import 'shared/employee_account_master_screen.dart';
import 'employee_list_screen.dart';
import 'view_all_masters_screen.dart';

class DashboardScreenNew extends StatefulWidget {
  const DashboardScreenNew({super.key});

  @override
  State<DashboardScreenNew> createState() => _DashboardScreenNewState();
}

class _DashboardScreenNewState extends State<DashboardScreenNew> {
  String selectedMasterOption = '';
  bool isMasterExpanded = false;
  bool showAccountMasterForm = false;
  bool isLoading = false;

  // Location data
  List<models.Country> countries = [];
  List<models.State> states = [];
  List<models.District> districts = [];
  List<models.City> cities = [];
  List<models.Zone> zones = [];
  List<models.Area> areas = [];

  // Selected IDs
  int? selectedCountryId;
  int? selectedStateId;
  int? selectedDistrictId;
  int? selectedCityId;
  int? selectedZoneId;
  int? selectedAreaId;

  final List<Map<String, dynamic>> masterOptions = [
    {'name': 'Country', 'icon': Icons.public},
    {'name': 'State', 'icon': Icons.map},
    {'name': 'District', 'icon': Icons.location_city},
    {'name': 'City', 'icon': Icons.location_on},
    {'name': 'Zone', 'icon': Icons.place},
    {'name': 'Area', 'icon': Icons.pin_drop},
  ];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchCountries();
      setState(() {
        countries = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load countries: $e');
    }
  }

  Future<void> _loadStates(int countryId) async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchStates(countryId);
      setState(() {
        states = data;
        selectedStateId = null;
        districts = [];
        cities = [];
        zones = [];
        areas = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load states: $e');
    }
  }

  Future<void> _loadDistricts(int regionId) async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchDistricts(regionId);
      setState(() {
        districts = data;
        selectedDistrictId = null;
        cities = [];
        zones = [];
        areas = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load districts: $e');
    }
  }

  Future<void> _loadCities(int districtId) async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchCities(districtId);
      setState(() {
        cities = data;
        selectedCityId = null;
        zones = [];
        areas = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load cities: $e');
    }
  }

  Future<void> _loadZones(int cityId) async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchZones(cityId);
      setState(() {
        zones = data;
        selectedZoneId = null;
        areas = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load zones: $e');
    }
  }

  Future<void> _loadAreas(int zoneId) async {
    setState(() => isLoading = true);
    try {
      final data = await LocationService.fetchAreas(zoneId);
      setState(() {
        areas = data;
        selectedAreaId = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load areas: $e');
    }
  }

  void _resetLocationAndForm() {
    setState(() {
      selectedCountryId = null;
      selectedStateId = null;
      selectedDistrictId = null;
      selectedCityId = null;
      selectedZoneId = null;
      selectedAreaId = null;
      states = [];
      districts = [];
      cities = [];
      zones = [];
      areas = [];
      showAccountMasterForm = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (result == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard"),
          backgroundColor: const Color(0xFFD7BE69),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD7BE69)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.business, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Loagma CRM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.storage, color: Color(0xFFD7BE69)),
            title: const Text(
              'Master',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            initiallyExpanded: isMasterExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                isMasterExpanded = expanded;
              });
            },
            children: masterOptions.map((option) {
              return ListTile(
                leading: Icon(
                  option['icon'],
                  color: const Color(0xFFD7BE69),
                  size: 20,
                ),
                title: Text(option['name']),
                selected: selectedMasterOption == option['name'],
                selectedTileColor: const Color(0xFFD7BE69).withOpacity(0.1),
                onTap: () {
                  setState(() {
                    selectedMasterOption = option['name'];
                    _resetLocationAndForm();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Color(0xFFD7BE69)),
            title: const Text('View All Account Masters'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewAllMastersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFFD7BE69)),
            title: const Text('View Employees'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (selectedMasterOption.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Welcome to Loagma CRM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select an option from the menu',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (showAccountMasterForm) {
      return _AccountMasterForm(
        areaId: selectedAreaId,
        onBack: () async {
          // Show confirmation dialog
          final shouldGoBack = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm'),
              content: const Text(
                'Do you want to go back? Any unsaved changes will be lost.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, Go Back'),
                ),
              ],
            ),
          );

          if (shouldGoBack == true) {
            setState(() {
              showAccountMasterForm = false;
            });
          }
        },
        onSuccess: (message) {
          _showSuccess(message);
          setState(() {
            showAccountMasterForm = false;
            _resetLocationAndForm();
          });
        },
        onError: _showError,
      );
    }

    return _buildLocationSelectionForm();
  }

  Widget _buildLocationSelectionForm() {
    int maxLevel = _getMaxLevelForOption(selectedMasterOption);
    bool isComplete = _isFormCompleteForLevel(maxLevel);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                masterOptions.firstWhere(
                  (opt) => opt['name'] == selectedMasterOption,
                )['icon'],
                color: const Color(0xFFD7BE69),
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add $selectedMasterOption Master',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD7BE69),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fill in location details up to $selectedMasterOption level',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Country
          _buildDropdown(
            label: 'Country',
            icon: Icons.public,
            value: selectedCountryId,
            items: countries.map((c) => {'id': c.id, 'name': c.name}).toList(),
            onChanged: (v) {
              setState(() {
                selectedCountryId = v;
              });
              if (v != null) _loadStates(v);
            },
          ),

          // State
          if (maxLevel >= 2) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'State',
              icon: Icons.map,
              value: selectedStateId,
              items: states.map((s) => {'id': s.id, 'name': s.name}).toList(),
              enabled: selectedCountryId != null,
              onChanged: (v) {
                setState(() {
                  selectedStateId = v;
                });
                if (v != null) _loadDistricts(v);
              },
            ),
          ],

          // District
          if (maxLevel >= 3) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'District',
              icon: Icons.location_city,
              value: selectedDistrictId,
              items: districts
                  .map((d) => {'id': d.id, 'name': d.name})
                  .toList(),
              enabled: selectedStateId != null,
              onChanged: (v) {
                setState(() {
                  selectedDistrictId = v;
                });
                if (v != null) _loadCities(v);
              },
            ),
          ],

          // City
          if (maxLevel >= 4) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'City',
              icon: Icons.location_on,
              value: selectedCityId,
              items: cities.map((c) => {'id': c.id, 'name': c.name}).toList(),
              enabled: selectedDistrictId != null,
              onChanged: (v) {
                setState(() {
                  selectedCityId = v;
                });
                if (v != null) _loadZones(v);
              },
            ),
          ],

          // Zone
          if (maxLevel >= 5) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Zone',
              icon: Icons.place,
              value: selectedZoneId,
              items: zones.map((z) => {'id': z.id, 'name': z.name}).toList(),
              enabled: selectedCityId != null,
              onChanged: (v) {
                setState(() {
                  selectedZoneId = v;
                });
                if (v != null) _loadAreas(v);
              },
            ),
          ],

          // Area
          if (maxLevel >= 6) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Area',
              icon: Icons.pin_drop,
              value: selectedAreaId,
              items: areas.map((a) => {'id': a.id, 'name': a.name}).toList(),
              enabled: selectedZoneId != null,
              onChanged: (v) {
                setState(() {
                  selectedAreaId = v;
                });
              },
            ),
          ],

          const SizedBox(height: 40),

          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next: Account Master Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isComplete
                    ? const Color(0xFFD7BE69)
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isComplete
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EmployeeAccountMasterScreen(),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  int _getMaxLevelForOption(String option) {
    switch (option) {
      case 'Country':
        return 1;
      case 'State':
        return 2;
      case 'District':
        return 3;
      case 'City':
        return 4;
      case 'Zone':
        return 5;
      case 'Area':
        return 6;
      default:
        return 6;
    }
  }

  bool _isFormCompleteForLevel(int level) {
    switch (level) {
      case 1:
        return selectedCountryId != null;
      case 2:
        return selectedCountryId != null && selectedStateId != null;
      case 3:
        return selectedCountryId != null &&
            selectedStateId != null &&
            selectedDistrictId != null;
      case 4:
        return selectedCountryId != null &&
            selectedStateId != null &&
            selectedDistrictId != null &&
            selectedCityId != null;
      case 5:
        return selectedCountryId != null &&
            selectedStateId != null &&
            selectedDistrictId != null &&
            selectedCityId != null &&
            selectedZoneId != null;
      case 6:
        return selectedCountryId != null &&
            selectedStateId != null &&
            selectedDistrictId != null &&
            selectedCityId != null &&
            selectedZoneId != null &&
            selectedAreaId != null;
      default:
        return false;
    }
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required List<Map<String, dynamic>> items,
    required void Function(int?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFFD7BE69) : Colors.grey,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['id'] as int,
          child: Text(item['name'] as String),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      hint: Text('Select $label'),
    );
  }
}

// Account Master Form Widget
class _AccountMasterForm extends StatefulWidget {
  final int? areaId;
  final VoidCallback onBack;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AccountMasterForm({
    this.areaId,
    required this.onBack,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AccountMasterForm> createState() => _AccountMasterFormState();
}

class _AccountMasterFormState extends State<_AccountMasterForm> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // Controllers
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _businessTypeController = TextEditingController();

  // Dropdown values
  String? _selectedCustomerStage;
  String? _selectedFunnelStage;
  DateTime? _dateOfBirth;

  final List<String> _customerStages = ['Lead', 'Prospect', 'Customer'];
  final List<String> _funnelStages = ['Awareness', 'Interest', 'Converted'];

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
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      try {
        final account = await AccountService.createAccount(
          personName: _personNameController.text,
          contactNumber: _contactNumberController.text,
          dateOfBirth: _dateOfBirth?.toIso8601String(),
          businessType: _businessTypeController.text.isNotEmpty
              ? _businessTypeController.text
              : null,
          customerStage: _selectedCustomerStage,
          funnelStage: _selectedFunnelStage,
          areaId: widget.areaId,
        );

        widget.onSuccess(
          'Account created successfully! Code: ${account.accountCode}',
        );
      } catch (e) {
        widget.onError('Failed to create account: $e');
      } finally {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFD7BE69)),
                  onPressed: widget.onBack,
                ),
                const Icon(
                  Icons.account_box,
                  color: Color(0xFFD7BE69),
                  size: 30,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Account Master',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD7BE69),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildTextField(
              controller: _personNameController,
              label: 'Person Name *',
              icon: Icons.person,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 15),

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

            _buildDateField(
              label: 'Date of Birth',
              icon: Icons.cake,
              date: _dateOfBirth,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _businessTypeController,
              label: 'Business Type',
              icon: Icons.business,
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
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
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
      initialValue: value,
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
}
