import 'package:flutter/material.dart';
import '../../services/beat_plan_service.dart';
import '../../services/user_service.dart';
import '../../services/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GenerateBeatPlanScreen extends StatefulWidget {
  const GenerateBeatPlanScreen({super.key});

  @override
  State<GenerateBeatPlanScreen> createState() => _GenerateBeatPlanScreenState();
}

class _GenerateBeatPlanScreenState extends State<GenerateBeatPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSalesmanId;
  String? _selectedSalesmanName;
  DateTime? _selectedWeekStart;
  final List<String> _pincodes = [];
  final List<String> _availableAreas = [];
  final List<String> _selectedAreas = [];
  final TextEditingController _pincodeController = TextEditingController();

  bool _isGenerating = false;
  bool _isLoadingSalesmen = false;
  bool _isLoadingAreas = false;
  bool _useRandomGeneration = true;

  // Dynamic salesman data from API
  List<Map<String, dynamic>> _salesmen = [];
  List<Map<String, dynamic>> _salesmanAreaAssignments = [];

  // Theme colors - matching existing app
  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = BeatPlanService.getWeekStartDate(DateTime.now());
    _loadSalesmen();
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  /// Load all salesmen from API
  Future<void> _loadSalesmen() async {
    setState(() => _isLoadingSalesmen = true);

    try {
      final result = await UserService.getAllUsers();

      if (result['success'] == true) {
        final users = result['data'] as List<dynamic>;

        // Filter only salesmen/sales representatives
        final salesmen = users.where((user) {
          final role = user['role']?.toString().toLowerCase() ?? '';
          return role.contains('sales') ||
              role.contains('salesman') ||
              role.contains('sr');
        }).toList();

        setState(() {
          _salesmen = salesmen
              .map(
                (user) => {
                  'id': user['id'] ?? user['_id'] ?? '',
                  'name': user['name'] ?? 'Unknown',
                  'employeeCode':
                      user['employeeCode'] ?? user['contactNumber'] ?? 'N/A',
                  'role': user['role'] ?? 'salesman',
                },
              )
              .toList();
        });

        print('✅ Loaded ${_salesmen.length} salesmen');
      } else {
        throw Exception(result['message'] ?? 'Failed to load salesmen');
      }
    } catch (e) {
      print('❌ Error loading salesmen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load salesmen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingSalesmen = false);
    }
  }

  /// Load area assignments for selected salesman
  Future<void> _loadSalesmanAreaAssignments(String salesmanId) async {
    setState(() => _isLoadingAreas = true);

    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/area-assignments/salesman/$salesmanId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final assignments = data['assignments'] as List<dynamic>;

        setState(() {
          _salesmanAreaAssignments = assignments
              .map((a) => Map<String, dynamic>.from(a))
              .toList();

          // Auto-populate pincodes from assignments
          _pincodes.clear();
          _availableAreas.clear();

          for (var assignment in assignments) {
            final pincode = assignment['pinCode']?.toString();
            if (pincode != null && !_pincodes.contains(pincode)) {
              _pincodes.add(pincode);
            }

            final areas = assignment['areas'] as List<dynamic>? ?? [];
            for (var area in areas) {
              final areaName = area.toString();
              if (!_availableAreas.contains(areaName)) {
                _availableAreas.add(areaName);
              }
            }
          }
        });

        print('✅ Loaded ${assignments.length} area assignments for salesman');
        print('📍 Auto-populated ${_pincodes.length} pincodes');
        print('🏢 Found ${_availableAreas.length} available areas');
      } else {
        throw Exception(data['message'] ?? 'Failed to load area assignments');
      }
    } catch (e) {
      print('❌ Error loading area assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load area assignments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingAreas = false);
    }
  }

  void _addPincode() {
    final pincode = _pincodeController.text.trim();
    if (pincode.isNotEmpty &&
        pincode.length == 6 &&
        !_pincodes.contains(pincode)) {
      setState(() {
        _pincodes.add(pincode);
        _pincodeController.clear();
      });
    }
  }

  void _removePincode(String pincode) {
    setState(() {
      _pincodes.remove(pincode);
    });
  }

  Future<void> _selectWeekStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Week Start Date (Monday)',
    );

    if (picked != null) {
      // Ensure it's a Monday
      final monday = BeatPlanService.getWeekStartDate(picked);
      setState(() {
        _selectedWeekStart = monday;
      });
    }
  }

  Future<void> _generateBeatPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSalesmanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a salesman'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_pincodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one pincode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await BeatPlanService.generateWeeklyBeatPlan(
        salesmanId: _selectedSalesmanId!,
        weekStartDate: _selectedWeekStart!,
        pincodes: _pincodes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beat plan generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Show success dialog with details
        _showSuccessDialog(result['data']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate beat plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final totalAreas = result['totalAreas'];
    final distribution = result['distribution'] as List;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Beat Plan Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salesman: $_selectedSalesmanName'),
            Text(
              'Week: ${BeatPlanService.formatWeekRange(_selectedWeekStart!)}',
            ),
            Text('Total Areas: $totalAreas'),
            Text('Pincodes: ${_pincodes.join(', ')}'),
            const SizedBox(height: 16),
            const Text(
              'Daily Distribution:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List.generate(7, (index) {
              final dayName = BeatPlanService.getDayName(index + 1);
              final areas = distribution[index] as List;
              return Text('$dayName: ${areas.length} areas');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to management screen
            },
            child: const Text('View Beat Plans'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _resetForm(); // Reset form for new plan
            },
            child: const Text('Generate Another'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedSalesmanId = null;
      _selectedSalesmanName = null;
      _selectedWeekStart = BeatPlanService.getWeekStartDate(DateTime.now());
      _pincodes.clear();
      _availableAreas.clear();
      _selectedAreas.clear();
      _salesmanAreaAssignments.clear();
      _pincodeController.clear();
      _useRandomGeneration = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Beat Plan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSalesmanSelection(),
              const SizedBox(height: 20),
              _buildWeekSelection(),
              const SizedBox(height: 20),
              _buildGenerationModeSelection(),
              const SizedBox(height: 20),
              _buildPincodeSection(),
              if (!_useRandomGeneration && _availableAreas.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildManualAreaSelection(),
              ],
              const SizedBox(height: 32),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesmanSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Select Salesman',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingSalesmen) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSalesmanId,
              decoration: const InputDecoration(
                labelText: 'Salesman',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _salesmen.map((salesman) {
                return DropdownMenuItem<String>(
                  value: salesman['id'],
                  child: Text(
                    '${salesman['name']} (${salesman['employeeCode']})',
                  ),
                );
              }).toList(),
              onChanged: _isLoadingSalesmen
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSalesmanId = value;
                        _selectedSalesmanName = _salesmen.firstWhere(
                          (s) => s['id'] == value,
                        )['name'];

                        // Clear previous data
                        _pincodes.clear();
                        _availableAreas.clear();
                        _selectedAreas.clear();
                      });

                      // Load area assignments for selected salesman
                      if (value != null) {
                        _loadSalesmanAreaAssignments(value);
                      }
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a salesman';
                }
                return null;
              },
            ),
            if (_isLoadingAreas) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading area assignments...'),
                ],
              ),
            ],
            if (_salesmanAreaAssignments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Areas:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_salesmanAreaAssignments.length} area assignments found',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Select Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectWeekStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Week Starting',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _selectedWeekStart != null
                                ? BeatPlanService.formatWeekRange(
                                    _selectedWeekStart!,
                                  )
                                : 'Select week start date',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Generation Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text('Random Generation'),
              subtitle: const Text(
                'Automatically distribute areas across 7 days',
              ),
              value: true,
              groupValue: _useRandomGeneration,
              onChanged: (value) {
                setState(() {
                  _useRandomGeneration = value ?? true;
                  _selectedAreas.clear();
                });
              },
              activeColor: primaryColor,
            ),
            RadioListTile<bool>(
              title: const Text('Manual Assignment'),
              subtitle: const Text(
                'Manually select specific areas for the week',
              ),
              value: false,
              groupValue: _useRandomGeneration,
              onChanged: (value) {
                setState(() {
                  _useRandomGeneration = value ?? true;
                  _selectedAreas.clear();
                });
              },
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPincodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pin_drop, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Assigned Pincodes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pincodes.isNotEmpty) ...[
              const Text(
                'Auto-populated from area assignments:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pincodes.map((pincode) {
                  return Chip(
                    label: Text(pincode),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removePincode(pincode),
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Add Additional Pincode',
                      hintText: 'Enter 6-digit pincode',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onFieldSubmitted: (_) => _addPincode(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPincode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            if (_pincodes.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select a salesman to auto-populate pincodes from their area assignments',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualAreaSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Select Areas Manually',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose specific areas to include in the beat plan:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _availableAreas.length,
                itemBuilder: (context, index) {
                  final area = _availableAreas[index];
                  final isSelected = _selectedAreas.contains(area);

                  return CheckboxListTile(
                    title: Text(area),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedAreas.add(area);
                        } else {
                          _selectedAreas.remove(area);
                        }
                      });
                    },
                    activeColor: primaryColor,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedAreas.length} of ${_availableAreas.length} areas selected',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateBeatPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Generating Beat Plan...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 8),
                  Text(
                    _useRandomGeneration
                        ? 'Generate Random Beat Plan'
                        : 'Generate Manual Beat Plan',
                  ),
                ],
              ),
      ),
    );
  }
}
