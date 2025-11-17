import 'package:flutter/material.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/location_service.dart';

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

  Account? _account;

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
    _loadAccount();
    _loadCountries();
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _contactNumberController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await AccountService.fetchAccountById(widget.accountId);
      setState(() {
        _account = account;
        _personNameController.text = account.personName;
        _contactNumberController.text = account.contactNumber;
        _businessTypeController.text = account.businessType ?? '';
        _selectedCustomerStage = account.customerStage;
        _selectedFunnelStage = account.funnelStage;
        _dateOfBirth = account.dateOfBirth;
        _selectedAreaId = account.areaId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load account: $e');
    }
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await LocationService.getCountries();
      setState(() => _countries = countries);
    } catch (e) {
      _showError('Failed to load countries: $e');
    }
  }

  Future<void> _updateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final updates = {
          'personName': _personNameController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          if (_dateOfBirth != null)
            'dateOfBirth': _dateOfBirth!.toIso8601String(),
          if (_businessTypeController.text.isNotEmpty)
            'businessType': _businessTypeController.text.trim(),
          if (_selectedCustomerStage != null)
            'customerStage': _selectedCustomerStage,
          if (_selectedFunnelStage != null) 'funnelStage': _selectedFunnelStage,
          if (_selectedAreaId != null) 'areaId': _selectedAreaId,
        };

        await AccountService.updateAccount(widget.accountId, updates);
        _showSuccess('Account updated successfully');
        setState(() => _isEditing = false);
        _loadAccount();
      } catch (e) {
        _showError('Failed to update account: $e');
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
        // Header Card
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFD7BE69),
                  child: Text(
                    _account!.personName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _account!.personName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _account!.accountCode,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 15),
                // Approval Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: _account!.isApproved
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _account!.isApproved
                            ? Icons.check_circle
                            : Icons.pending,
                        color: _account!.isApproved
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _account!.isApproved ? 'Approved' : 'Pending Approval',
                        style: TextStyle(
                          color: _account!.isApproved
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Details Card
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildDetailRow(Icons.phone, 'Phone', _account!.contactNumber),
                if (_account!.dateOfBirth != null)
                  _buildDetailRow(
                    Icons.cake,
                    'Date of Birth',
                    '${_account!.dateOfBirth!.day}/${_account!.dateOfBirth!.month}/${_account!.dateOfBirth!.year}',
                  ),
                if (_account!.businessType != null)
                  _buildDetailRow(
                      Icons.business, 'Business Type', _account!.businessType!),
                if (_account!.customerStage != null)
                  _buildDetailRow(Icons.stairs, 'Customer Stage',
                      _account!.customerStage!),
                if (_account!.funnelStage != null)
                  _buildDetailRow(Icons.filter_list, 'Funnel Stage',
                      _account!.funnelStage!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tracking Information
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (_account!.createdBy != null)
                  _buildDetailRow(Icons.person_add, 'Created By',
                      _account!.createdByName),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Created At',
                  '${_account!.createdAt.day}/${_account!.createdAt.month}/${_account!.createdAt.year}',
                ),
                if (_account!.approvedBy != null)
                  _buildDetailRow(Icons.check_circle, 'Approved By',
                      _account!.approvedByName),
                if (_account!.approvedAt != null)
                  _buildDetailRow(
                    Icons.event_available,
                    'Approved At',
                    '${_account!.approvedAt!.day}/${_account!.approvedAt!.month}/${_account!.approvedAt!.year}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD7BE69)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Person Name
          TextFormField(
            controller: _personNameController,
            decoration: InputDecoration(
              labelText: 'Person Name *',
              prefixIcon:
                  const Icon(Icons.person, color: Color(0xFFD7BE69)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),

          // Contact Number
          TextFormField(
            controller: _contactNumberController,
            decoration: InputDecoration(
              labelText: 'Contact Number *',
              prefixIcon: const Icon(Icons.phone, color: Color(0xFFD7BE69)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (v!.length != 10) return 'Must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Business Type
          TextFormField(
            controller: _businessTypeController,
            decoration: InputDecoration(
              labelText: 'Business Type',
              prefixIcon:
                  const Icon(Icons.business, color: Color(0xFFD7BE69)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // Customer Stage
          DropdownButtonFormField<String>(
            value: _selectedCustomerStage,
            decoration: InputDecoration(
              labelText: 'Customer Stage',
              prefixIcon: const Icon(Icons.stairs, color: Color(0xFFD7BE69)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _customerStages
                .map((stage) =>
                    DropdownMenuItem(value: stage, child: Text(stage)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCustomerStage = v),
          ),
          const SizedBox(height: 15),

          // Funnel Stage
          DropdownButtonFormField<String>(
            value: _selectedFunnelStage,
            decoration: InputDecoration(
              labelText: 'Funnel Stage',
              prefixIcon:
                  const Icon(Icons.filter_list, color: Color(0xFFD7BE69)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _funnelStages
                .map((stage) =>
                    DropdownMenuItem(value: stage, child: Text(stage)))
                .toList(),
            onChanged: (v) => setState(() => _selectedFunnelStage = v),
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
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    foregroundColor: const Color(0xFFD7BE69),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFFD7BE69)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
