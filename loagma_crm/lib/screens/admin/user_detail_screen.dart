import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'edit_user_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUpdate;

  const UserDetailScreen({
    super.key,
    required this.user,
    required this.onUpdate,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Details"),
        backgroundColor: const Color(0xFFD7BE69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(user: widget.user),
                ),
              );
              if (result == true) {
                widget.onUpdate();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFD7BE69),
                    backgroundImage: widget.user['image'] != null
                        ? NetworkImage(widget.user['image'])
                        : null,
                    child: widget.user['image'] == null
                        ? Text(
                            (widget.user['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.user['isActive'] == true
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.user['isActive'] == true ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: widget.user['isActive'] == true
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Contact Information
            _buildSectionTitle("Contact Information"),
            _buildInfoCard([
              _buildInfoRow(
                Icons.phone,
                "Contact Number",
                widget.user['contactNumber'] ?? 'N/A',
                canCopy: true,
              ),
              if (widget.user['alternativeNumber'] != null)
                _buildInfoRow(
                  Icons.phone_android,
                  "Alternative Number",
                  widget.user['alternativeNumber'],
                  canCopy: true,
                ),
              if (widget.user['email'] != null)
                _buildInfoRow(
                  Icons.email,
                  "Email",
                  widget.user['email'],
                  canCopy: true,
                ),
            ]),
            const SizedBox(height: 20),

            // Personal Information
            _buildSectionTitle("Personal Information"),
            _buildInfoCard([
              if (widget.user['gender'] != null)
                _buildInfoRow(Icons.wc, "Gender", widget.user['gender']),
              if (widget.user['preferredLanguages'] != null &&
                  (widget.user['preferredLanguages'] as List).isNotEmpty)
                _buildInfoRow(
                  Icons.language,
                  "Preferred Language",
                  (widget.user['preferredLanguages'] as List).join(', '),
                ),
              if (widget.user['aadharCard'] != null)
                _buildInfoRow(
                  Icons.credit_card,
                  "Aadhar Card",
                  widget.user['aadharCard'],
                  canCopy: true,
                ),
              if (widget.user['panCard'] != null)
                _buildInfoRow(
                  Icons.account_balance_wallet,
                  "PAN Card",
                  widget.user['panCard'],
                  canCopy: true,
                ),
            ]),
            const SizedBox(height: 20),

            // Role & Department
            _buildSectionTitle("Role & Department"),
            _buildInfoCard([
              if (widget.user['role'] != null)
                _buildInfoRow(Icons.badge, "Primary Role", widget.user['role']),
              if (widget.user['roles'] != null &&
                  (widget.user['roles'] as List).isNotEmpty)
                _buildInfoRow(
                  Icons.checklist,
                  "Additional Roles",
                  "${(widget.user['roles'] as List).length} role(s)",
                ),
              if (widget.user['department'] != null)
                _buildInfoRow(
                  Icons.business,
                  "Department",
                  widget.user['department'],
                ),
            ]),
            const SizedBox(height: 20),

            // Address Information
            if (widget.user['address'] != null ||
                widget.user['city'] != null ||
                widget.user['state'] != null ||
                widget.user['pincode'] != null) ...[
              _buildSectionTitle("Address Information"),
              _buildInfoCard([
                if (widget.user['address'] != null)
                  _buildInfoRow(Icons.home, "Address", widget.user['address']),
                if (widget.user['city'] != null)
                  _buildInfoRow(
                    Icons.location_city,
                    "City",
                    widget.user['city'],
                  ),
                if (widget.user['state'] != null)
                  _buildInfoRow(Icons.map, "State", widget.user['state']),
                if (widget.user['pincode'] != null)
                  _buildInfoRow(
                    Icons.pin_drop,
                    "Pincode",
                    widget.user['pincode'],
                  ),
              ]),
              const SizedBox(height: 20),
            ],

            // Salary Information
            if (widget.user['salary'] != null) ...[
              _buildSectionTitle("Salary Information"),
              _buildInfoCard([
                _buildSalaryRow(
                  "Basic Salary",
                  widget.user['salary']['basicSalary'],
                  Colors.blue,
                ),
                if ((widget.user['salary']['hra'] ?? 0) > 0)
                  _buildSalaryRow(
                    "HRA",
                    widget.user['salary']['hra'],
                    Colors.purple,
                  ),
                if ((widget.user['salary']['travelAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Travel Allowance",
                    widget.user['salary']['travelAllowance'],
                    Colors.orange,
                  ),
                if ((widget.user['salary']['dailyAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Daily Allowance",
                    widget.user['salary']['dailyAllowance'],
                    Colors.teal,
                  ),
                if ((widget.user['salary']['medicalAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Medical Allowance",
                    widget.user['salary']['medicalAllowance'],
                    Colors.red,
                  ),
                const Divider(height: 24),
                _buildSalaryRow(
                  "Gross Salary",
                  widget.user['salary']['grossSalary'],
                  Colors.green,
                  isBold: true,
                ),
                if ((widget.user['salary']['totalDeductions'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Total Deductions",
                    widget.user['salary']['totalDeductions'],
                    Colors.red,
                  ),
                const Divider(height: 24),
                _buildSalaryRow(
                  "Net Salary",
                  widget.user['salary']['netSalary'],
                  const Color(0xFFD7BE69),
                  isBold: true,
                  isLarge: true,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment: ${widget.user['salary']['paymentFrequency'] ?? 'Monthly'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "Currency: ${widget.user['salary']['currency'] ?? 'INR'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // Notes
            if (widget.user['notes'] != null) ...[
              _buildSectionTitle("Notes"),
              _buildInfoCard([
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.user['notes'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // System Information
            _buildSectionTitle("System Information"),
            _buildInfoCard([
              _buildInfoRow(
                Icons.calendar_today,
                "Created At",
                _formatDate(widget.user['createdAt']),
              ),
              _buildInfoRow(Icons.fingerprint, "User ID", widget.user['id']),
            ]),
            const SizedBox(height: 30),

            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFD7BE69),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditUserScreen(user: widget.user),
                    ),
                  );
                  if (result == true) {
                    widget.onUpdate();
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Employee", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD7BE69),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool canCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                Fluttertoast.showToast(
                  msg: "Copied to clipboard",
                  toastLength: Toast.LENGTH_SHORT,
                );
              },
              tooltip: "Copy",
            ),
        ],
      ),
    );
  }

  Widget _buildSalaryRow(
    String label,
    dynamic amount,
    Color color, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    final value = amount is String ? double.tryParse(amount) ?? 0 : (amount ?? 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹${_formatNumber(value)}",
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = number is String ? double.tryParse(number) ?? 0 : number;
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}
