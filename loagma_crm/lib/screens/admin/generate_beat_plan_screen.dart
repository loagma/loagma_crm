import 'package:flutter/material.dart';
import '../../services/beat_plan_service.dart';

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
  final TextEditingController _pincodeController = TextEditingController();

  bool _isLoading = false;
  bool _isGenerating = false;

  // Mock salesman data - In real app, fetch from API
  final List<Map<String, dynamic>> _salesmen = [
    {'id': '000001', 'name': 'John Doe', 'employeeCode': 'EMP001'},
    {'id': '000002', 'name': 'Jane Smith', 'employeeCode': 'EMP002'},
    {'id': '000003', 'name': 'Mike Johnson', 'employeeCode': 'EMP003'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = BeatPlanService.getWeekStartDate(DateTime.now());
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
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
    final weeklyPlan = result['weeklyPlan'];
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
      _pincodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Beat Plan'),
        backgroundColor: Colors.blue,
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
              _buildPincodeSection(),
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
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Select Salesman',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
              onChanged: (value) {
                setState(() {
                  _selectedSalesmanId = value;
                  _selectedSalesmanName = _salesmen.firstWhere(
                    (s) => s['id'] == value,
                  )['name'];
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a salesman';
                }
                return null;
              },
            ),
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
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green),
                SizedBox(width: 8),
                Text(
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

  Widget _buildPincodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pin_drop, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Assign Pincodes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pincodes.isNotEmpty) ...[
              const Text(
                'Added Pincodes:',
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
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ] else ...[
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
                        'Add pincodes to assign areas to the salesman',
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

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateBeatPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Text('Generate Beat Plan'),
                ],
              ),
      ),
    );
  }
}
