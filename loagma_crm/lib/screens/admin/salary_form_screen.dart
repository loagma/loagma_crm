import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/salary_service.dart';
import '../../services/user_service.dart';

class SalaryFormScreen extends StatefulWidget {
  final String? employeeId;
  final Map<String, dynamic>? existingSalary;

  const SalaryFormScreen({super.key, this.employeeId, this.existingSalary});

  @override
  State<SalaryFormScreen> createState() => _SalaryFormScreenState();
}

class _SalaryFormScreenState extends State<SalaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoadingEmployees = true;

  List<dynamic> employees = [];
  String? selectedEmployeeId;
  Map<String, dynamic>? selectedEmployee;

  // Controllers
  final TextEditingController basicSalaryController = TextEditingController();
  final TextEditingController hraController = TextEditingController();
  final TextEditingController travelAllowanceController =
      TextEditingController();
  final TextEditingController dailyAllowanceController =
      TextEditingController();
  final TextEditingController medicalAllowanceController =
      TextEditingController();
  final TextEditingController specialAllowanceController =
      TextEditingController();
  final TextEditingController otherAllowancesController =
      TextEditingController();
  final TextEditingController providentFundController = TextEditingController();
  final TextEditingController professionalTaxController =
      TextEditingController();
  final TextEditingController incomeTaxController = TextEditingController();
  final TextEditingController otherDeductionsController =
      TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController panNumberController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  DateTime effectiveFrom = DateTime.now();
  DateTime? effectiveTo;
  String currency = 'INR';
  String paymentFrequency = 'Monthly';
  bool isActive = true;

  double grossSalary = 0;
  double totalDeductions = 0;
  double netSalary = 0;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    if (widget.existingSalary != null) {
      _populateExistingData();
    } else if (widget.employeeId != null) {
      selectedEmployeeId = widget.employeeId;
    }
  }

  Future<void> _loadEmployees() async {
    final result = await UserService.getAllUsers();
    if (mounted) {
      setState(() {
        if (result['success']) {
          employees = result['data'];
        }
        isLoadingEmployees = false;
      });
    }
  }

  void _populateExistingData() {
    final salary = widget.existingSalary!;
    selectedEmployeeId = salary['employeeId'];
    basicSalaryController.text = salary['basicSalary'].toString();
    hraController.text = (salary['hra'] ?? 0).toString();
    travelAllowanceController.text = (salary['travelAllowance'] ?? 0).toString();
    dailyAllowanceController.text = (salary['dailyAllowance'] ?? 0).toString();
    medicalAllowanceController.text =
        (salary['medicalAllowance'] ?? 0).toString();
    specialAllowanceController.text =
        (salary['specialAllowance'] ?? 0).toString();
    otherAllowancesController.text = (salary['otherAllowances'] ?? 0).toString();
    providentFundController.text = (salary['providentFund'] ?? 0).toString();
    professionalTaxController.text =
        (salary['professionalTax'] ?? 0).toString();
    incomeTaxController.text = (salary['incomeTax'] ?? 0).toString();
    otherDeductionsController.text = (salary['otherDeductions'] ?? 0).toString();
    bankNameController.text = salary['bankName'] ?? '';
    accountNumberController.text = salary['accountNumber'] ?? '';
    ifscCodeController.text = salary['ifscCode'] ?? '';
    panNumberController.text = salary['panNumber'] ?? '';
    remarksController.text = salary['remarks'] ?? '';
    effectiveFrom = DateTime.parse(salary['effectiveFrom']);
    effectiveTo =
        salary['effectiveTo'] != null ? DateTime.parse(salary['effectiveTo']) : null;
    currency = salary['currency'] ?? 'INR';
    paymentFrequency = salary['paymentFrequency'] ?? 'Monthly';
    isActive = salary['isActive'] ?? true;
    _calculateTotals();
  }

  void _calculateTotals() {
    setState(() {
      grossSalary = (double.tryParse(basicSalaryController.text) ?? 0) +
          (double.tryParse(hraController.text) ?? 0) +
          (double.tryParse(travelAllowanceController.text) ?? 0) +
          (double.tryParse(dailyAllowanceController.text) ?? 0) +
          (double.tryParse(medicalAllowanceController.text) ?? 0) +
          (double.tryParse(specialAllowanceController.text) ?? 0) +
          (double.tryParse(otherAllowancesController.text) ?? 0);

      totalDeductions = (double.tryParse(providentFundController.text) ?? 0) +
          (double.tryParse(professionalTaxController.text) ?? 0) +
          (double.tryParse(incomeTaxController.text) ?? 0) +
          (double.tryParse(otherDeductionsController.text) ?? 0);

      netSalary = grossSalary - totalDeductions;
    });
  }

  Future<void> _saveSalary() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final salaryData = {
      'employeeId': selectedEmployeeId,
      'basicSalary': double.parse(basicSalaryController.text),
      'hra': double.tryParse(hraController.text) ?? 0,
      'travelAllowance': double.tryParse(travelAllowanceController.text) ?? 0,
      'dailyAllowance': double.tryParse(dailyAllowanceController.text) ?? 0,
      'medicalAllowance': double.tryParse(medicalAllowanceController.text) ?? 0,
      'specialAllowance': double.tryParse(specialAllowanceController.text) ?? 0,
      'otherAllowances': double.tryParse(otherAllowancesController.text) ?? 0,
      'providentFund': double.tryParse(providentFundController.text) ?? 0,
      'professionalTax': double.tryParse(professionalTaxController.text) ?? 0,
      'incomeTax': double.tryParse(incomeTaxController.text) ?? 0,
      'otherDeductions': double.tryParse(otherDeductionsController.text) ?? 0,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'currency': currency,
      'paymentFrequency': paymentFrequency,
      'bankName': bankNameController.text,
      'accountNumber': accountNumberController.text,
      'ifscCode': ifscCodeController.text,
      'panNumber': panNumberController.text,
      'remarks': remarksController.text,
      'isActive': isActive,
    };

    final result = await SalaryService.createOrUpdateSalary(salaryData);

    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Salary saved successfully'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSalary != null
            ? 'Edit Salary Information'
            : 'Add Salary Information'),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: isLoadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Employee Selection
                  if (widget.employeeId == null)
                    DropdownButtonFormField<String>(
                      value: selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Select Employee *',
                        border: OutlineInputBorder(),
                      ),
                      items: employees.map<DropdownMenuItem<String>>((emp) {
                        return DropdownMenuItem<String>(
                          value: emp['id'] as String,
                          child: Text(
                              '${emp['name']} (${emp['employeeCode'] ?? 'N/A'})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedEmployeeId = value;
                          selectedEmployee = employees
                              .firstWhere((emp) => emp['id'] == value);
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select an employee' : null,
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'Salary Components',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // Basic Salary
                  _buildNumberField(
                    controller: basicSalaryController,
                    label: 'Basic Salary *',
                    icon: Icons.currency_rupee,
                    required: true,
                  ),

                  // Allowances
                  _buildNumberField(
                    controller: hraController,
                    label: 'HRA',
                    icon: Icons.home,
                  ),
                  _buildNumberField(
                    controller: travelAllowanceController,
                    label: 'Travel Allowance',
                    icon: Icons.directions_car,
                  ),
                  _buildNumberField(
                    controller: dailyAllowanceController,
                    label: 'Daily Allowance',
                    icon: Icons.calendar_today,
                  ),
                  _buildNumberField(
                    controller: medicalAllowanceController,
                    label: 'Medical Allowance',
                    icon: Icons.medical_services,
                  ),
                  _buildNumberField(
                    controller: specialAllowanceController,
                    label: 'Special Allowance',
                    icon: Icons.star,
                  ),
                  _buildNumberField(
                    controller: otherAllowancesController,
                    label: 'Other Allowances',
                    icon: Icons.add_circle,
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Deductions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  _buildNumberField(
                    controller: providentFundController,
                    label: 'Provident Fund (PF)',
                    icon: Icons.savings,
                  ),
                  _buildNumberField(
                    controller: professionalTaxController,
                    label: 'Professional Tax',
                    icon: Icons.receipt,
                  ),
                  _buildNumberField(
                    controller: incomeTaxController,
                    label: 'Income Tax (TDS)',
                    icon: Icons.account_balance,
                  ),
                  _buildNumberField(
                    controller: otherDeductionsController,
                    label: 'Other Deductions',
                    icon: Icons.remove_circle,
                  ),

                  const SizedBox(height: 20),
                  // Summary Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow('Gross Salary', grossSalary,
                              Colors.green),
                          const Divider(),
                          _buildSummaryRow('Total Deductions',
                              totalDeductions, Colors.red),
                          const Divider(),
                          _buildSummaryRow('Net Salary', netSalary,
                              Colors.blue, isBold: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Bank Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  _buildTextField(
                    controller: bankNameController,
                    label: 'Bank Name',
                    icon: Icons.account_balance,
                  ),
                  _buildTextField(
                    controller: accountNumberController,
                    label: 'Account Number',
                    icon: Icons.credit_card,
                  ),
                  _buildTextField(
                    controller: ifscCodeController,
                    label: 'IFSC Code',
                    icon: Icons.code,
                  ),
                  _buildTextField(
                    controller: panNumberController,
                    label: 'PAN Number',
                    icon: Icons.badge,
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Other Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // Effective From
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Effective From *'),
                    subtitle: Text(
                        '${effectiveFrom.day}/${effectiveFrom.month}/${effectiveFrom.year}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: effectiveFrom,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => effectiveFrom = date);
                      }
                    },
                  ),

                  // Payment Frequency
                  DropdownButtonFormField<String>(
                    value: paymentFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Payment Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Monthly', 'Quarterly', 'Annually']
                        .map((freq) => DropdownMenuItem(
                              value: freq,
                              child: Text(freq),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => paymentFrequency = value!);
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: remarksController,
                    label: 'Remarks',
                    icon: Icons.note,
                    maxLines: 3,
                  ),

                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _saveSalary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Salary Information',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        onChanged: (_) => _calculateTotals(),
        validator: required
            ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    basicSalaryController.dispose();
    hraController.dispose();
    travelAllowanceController.dispose();
    dailyAllowanceController.dispose();
    medicalAllowanceController.dispose();
    specialAllowanceController.dispose();
    otherAllowancesController.dispose();
    providentFundController.dispose();
    professionalTaxController.dispose();
    incomeTaxController.dispose();
    otherDeductionsController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    panNumberController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
