import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'view_users_screen.dart';
import '../models/location_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedMasterOption = '';
  bool isMasterExpanded = false;
  bool showAccountMasterForm = false;

  // Location selection
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict;
  String? selectedCity;
  String? selectedZone;
  String? selectedArea;

  final List<Map<String, dynamic>> masterOptions = [
    {'name': 'Country', 'icon': Icons.public},
    {'name': 'State', 'icon': Icons.map},
    {'name': 'District', 'icon': Icons.location_city},
    {'name': 'City', 'icon': Icons.location_on},
    {'name': 'Zone', 'icon': Icons.place},
    {'name': 'Area', 'icon': Icons.pin_drop},
  ];

  void _resetLocationAndForm() {
    setState(() {
      selectedCountry = null;
      selectedState = null;
      selectedDistrict = null;
      selectedCity = null;
      selectedZone = null;
      selectedArea = null;
      showAccountMasterForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFD7BE69),
            ),
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
                leading:
                    Icon(option['icon'], color: Color(0xFFD7BE69), size: 20),
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
          // ListTile(
          //   leading: const Icon(Icons.person_add, color: Color(0xFFD7BE69)),
          //   title: const Text('Create User'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const CreateUserScreen()),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.list, color: Color(0xFFD7BE69)),
          //   title: const Text('View Users'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const ViewUsersScreen()),
          //     );
          //   },
          // ),
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
            Icon(
              Icons.dashboard,
              size: 100,
              color: Colors.grey[300],
            ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Show Account Master form if location is complete
    if (showAccountMasterForm) {
      // Build location data with only filled fields
      Map<String, String> locationData = {};
      if (selectedCountry != null) locationData['country'] = selectedCountry!;
      if (selectedState != null) locationData['state'] = selectedState!;
      if (selectedDistrict != null) locationData['district'] = selectedDistrict!;
      if (selectedCity != null) locationData['city'] = selectedCity!;
      if (selectedZone != null) locationData['zone'] = selectedZone!;
      if (selectedArea != null) locationData['area'] = selectedArea!;
      
      return _AccountMasterForm(
        locationData: locationData,
        onBack: () {
          setState(() {
            showAccountMasterForm = false;
          });
        },
      );
    }

    // Show location selection form
    return _buildLocationSelectionForm();
  }

  Widget _buildLocationSelectionForm() {
    // Determine which fields to show based on selected option
    int maxLevel = _getMaxLevelForOption(selectedMasterOption);
    
    List<String> countries = LocationData.getCountries();
    List<String> states = selectedCountry != null
        ? LocationData.getStates(selectedCountry!)
        : [];
    List<String> districts = (selectedCountry != null && selectedState != null)
        ? LocationData.getDistricts(selectedCountry!, selectedState!)
        : [];
    List<String> cities = (selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null)
        ? LocationData.getCities(
            selectedCountry!, selectedState!, selectedDistrict!)
        : [];
    List<String> zones = (selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null &&
            selectedCity != null)
        ? LocationData.getZones(
            selectedCountry!, selectedState!, selectedDistrict!, selectedCity!)
        : [];
    List<String> areas = (selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null &&
            selectedCity != null &&
            selectedZone != null)
        ? LocationData.getAreas(selectedCountry!, selectedState!,
            selectedDistrict!, selectedCity!, selectedZone!)
        : [];

    // Check if form is complete based on selected option level
    bool isComplete = _isFormCompleteForLevel(maxLevel);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                masterOptions
                    .firstWhere((opt) => opt['name'] == selectedMasterOption)[
                        'icon'],
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

          // Country - Always show
          _buildDropdown(
            label: 'Country',
            icon: Icons.public,
            value: selectedCountry,
            items: countries,
            onChanged: (v) {
              setState(() {
                selectedCountry = v;
                selectedState = null;
                selectedDistrict = null;
                selectedCity = null;
                selectedZone = null;
                selectedArea = null;
              });
            },
          ),
          
          // State - Show if maxLevel >= 2
          if (maxLevel >= 2) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'State',
              icon: Icons.map,
              value: selectedState,
              items: states,
              enabled: selectedCountry != null,
              onChanged: (v) {
                setState(() {
                  selectedState = v;
                  selectedDistrict = null;
                  selectedCity = null;
                  selectedZone = null;
                  selectedArea = null;
                });
              },
            ),
          ],

          // District - Show if maxLevel >= 3
          if (maxLevel >= 3) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'District',
              icon: Icons.location_city,
              value: selectedDistrict,
              items: districts,
              enabled: selectedState != null,
              onChanged: (v) {
                setState(() {
                  selectedDistrict = v;
                  selectedCity = null;
                  selectedZone = null;
                  selectedArea = null;
                });
              },
            ),
          ],

          // City - Show if maxLevel >= 4
          if (maxLevel >= 4) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'City',
              icon: Icons.location_on,
              value: selectedCity,
              items: cities,
              enabled: selectedDistrict != null,
              onChanged: (v) {
                setState(() {
                  selectedCity = v;
                  selectedZone = null;
                  selectedArea = null;
                });
              },
            ),
          ],

          // Zone - Show if maxLevel >= 5
          if (maxLevel >= 5) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Zone',
              icon: Icons.place,
              value: selectedZone,
              items: zones,
              enabled: selectedCity != null,
              onChanged: (v) {
                setState(() {
                  selectedZone = v;
                  selectedArea = null;
                });
              },
            ),
          ],

          // Area - Show if maxLevel >= 6
          if (maxLevel >= 6) ...[
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Area',
              icon: Icons.pin_drop,
              value: selectedArea,
              items: areas,
              enabled: selectedZone != null,
              onChanged: (v) {
                setState(() {
                  selectedArea = v;
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
                backgroundColor:
                    isComplete ? const Color(0xFFD7BE69) : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isComplete
                  ? () {
                      setState(() {
                        showAccountMasterForm = true;
                      });
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get max level for selected option
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

  // Helper method to check if form is complete for the level
  bool _isFormCompleteForLevel(int level) {
    switch (level) {
      case 1:
        return selectedCountry != null;
      case 2:
        return selectedCountry != null && selectedState != null;
      case 3:
        return selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null;
      case 4:
        return selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null &&
            selectedCity != null;
      case 5:
        return selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null &&
            selectedCity != null &&
            selectedZone != null;
      case 6:
        return selectedCountry != null &&
            selectedState != null &&
            selectedDistrict != null &&
            selectedCity != null &&
            selectedZone != null &&
            selectedArea != null;
      default:
        return false;
    }
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFFD7BE69) : Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      hint: Text('Select $label'),
    );
  }
}

// Account Master Form Widget
class _AccountMasterForm extends StatefulWidget {
  final Map<String, String> locationData;
  final VoidCallback onBack;

  const _AccountMasterForm({
    required this.locationData,
    required this.onBack,
  });

  @override
  State<_AccountMasterForm> createState() => _AccountMasterFormState();
}

class _AccountMasterFormState extends State<_AccountMasterForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _employeeCodeController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _nationalCodeController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobPostCodeController = TextEditingController();
  final _jobPostNameController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedDepartment;
  String? _selectedDesignation;
  DateTime? _dateOfBirth;
  DateTime? _joiningDate;
  bool _isActive = true;
  bool _isIncharge = false;
  List<String> _selectedLanguages = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _departments = [
    'Sales',
    'Marketing',
    'HR',
    'IT',
    'Finance',
    'Operations'
  ];
  final List<String> _designations = [
    'Manager',
    'Executive',
    'Senior Executive',
    'Team Lead',
    'Associate'
  ];
  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada'
  ];

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _employeeNameController.dispose();
    _nationalCodeController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _jobPostCodeController.dispose();
    _jobPostNameController.dispose();
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD7BE69),
            ),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Master saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
                const Icon(Icons.account_box,
                    color: Color(0xFFD7BE69), size: 30),
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
            const SizedBox(height: 20),

            // Location Info Card
            Card(
              elevation: 3,
              color: const Color(0xFFD7BE69).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD7BE69),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.locationData.containsKey('country'))
                      Text('Country: ${widget.locationData['country']}'),
                    if (widget.locationData.containsKey('state'))
                      Text('State: ${widget.locationData['state']}'),
                    if (widget.locationData.containsKey('district'))
                      Text('District: ${widget.locationData['district']}'),
                    if (widget.locationData.containsKey('city'))
                      Text('City: ${widget.locationData['city']}'),
                    if (widget.locationData.containsKey('zone'))
                      Text('Zone: ${widget.locationData['zone']}'),
                    if (widget.locationData.containsKey('area'))
                      Text('Area: ${widget.locationData['area']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Employee Details Section
            const Text(
              'Employee Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD7BE69),
              ),
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _employeeCodeController,
              label: 'Employee Code *',
              icon: Icons.badge,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _employeeNameController,
              label: 'Employee Name *',
              icon: Icons.person,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _nationalCodeController,
              label: 'National Code',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _contactNumberController,
              label: 'Contact Number *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _emailController,
              label: 'Email ID *',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Gender Dropdown
            _buildDropdown(
              value: _selectedGender,
              label: 'Gender *',
              icon: Icons.wc,
              items: _genders,
              onChanged: (v) => setState(() => _selectedGender = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            // Date of Birth
            _buildDateField(
              label: 'Date of Birth',
              icon: Icons.cake,
              date: _dateOfBirth,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 15),

            // Department Dropdown
            _buildDropdown(
              value: _selectedDepartment,
              label: 'Department *',
              icon: Icons.business,
              items: _departments,
              onChanged: (v) => setState(() => _selectedDepartment = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            // Designation Dropdown
            _buildDropdown(
              value: _selectedDesignation,
              label: 'Designation *',
              icon: Icons.work,
              items: _designations,
              onChanged: (v) => setState(() => _selectedDesignation = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 15),

            // Joining Date
            _buildDateField(
              label: 'Joining Date',
              icon: Icons.calendar_today,
              date: _joiningDate,
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 15),

            // Preferred Languages
            _buildMultiSelectField(),
            const SizedBox(height: 20),

            // Job Post Section
            const Text(
              'Job Post Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD7BE69),
              ),
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _jobPostCodeController,
              label: 'Job Post Code',
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _jobPostNameController,
              label: 'Job Post Name',
              icon: Icons.title,
            ),
            const SizedBox(height: 15),

            // Switches
            SwitchListTile(
              title: const Text('Incharge (Yes/No)'),
              value: _isIncharge,
              activeThumbColor: const Color(0xFFD7BE69),
              onChanged: (v) => setState(() => _isIncharge = v),
            ),

            SwitchListTile(
              title: const Text('Active Status'),
              value: _isActive,
              activeThumbColor: const Color(0xFFD7BE69),
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitForm,
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
                        _nationalCodeController.clear();
                        _contactNumberController.clear();
                        _emailController.clear();
                        _jobPostCodeController.clear();
                        _jobPostNameController.clear();
                        _selectedGender = null;
                        _selectedDepartment = null;
                        _selectedDesignation = null;
                        _dateOfBirth = null;
                        _joiningDate = null;
                        _selectedLanguages = [];
                        _isActive = true;
                        _isIncharge = false;
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
    String? Function(String?)? validator,
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
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectField() {
    return InkWell(
      onTap: () async {
        final selected = await showDialog<List<String>>(
          context: context,
          builder: (context) => _LanguageSelectionDialog(
            selectedLanguages: _selectedLanguages,
            allLanguages: _languages,
          ),
        );
        if (selected != null) {
          setState(() => _selectedLanguages = selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Preferred Languages',
          prefixIcon: const Icon(Icons.language, color: Color(0xFFD7BE69)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
          ),
        ),
        child: Text(
          _selectedLanguages.isEmpty
              ? 'Select Languages'
              : _selectedLanguages.join(', '),
          style: TextStyle(
            color: _selectedLanguages.isEmpty ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _LanguageSelectionDialog extends StatefulWidget {
  final List<String> selectedLanguages;
  final List<String> allLanguages;

  const _LanguageSelectionDialog({
    required this.selectedLanguages,
    required this.allLanguages,
  });

  @override
  State<_LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<_LanguageSelectionDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Languages'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.allLanguages.map((lang) {
            return CheckboxListTile(
              title: Text(lang),
              value: _tempSelected.contains(lang),
              activeColor: const Color(0xFFD7BE69),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _tempSelected.add(lang);
                  } else {
                    _tempSelected.remove(lang);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD7BE69),
          ),
          onPressed: () => Navigator.pop(context, _tempSelected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
