import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_config.dart';
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
  Map<String, dynamic>? workingHours;
  bool isLoadingWorkingHours = false;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    setState(() => isLoadingWorkingHours = true);
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/employee-working-hours/${widget.user['id']}',
      );
      print('🔄 Loading working hours from: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);

      print('📡 Working hours API response: ${response.statusCode}');
      print('📦 Working hours data: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          workingHours = data['data'];
        });
        print('✅ Working hours loaded successfully: $workingHours');
      } else {
        print(
          '❌ Working hours API failed: ${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('❌ Error loading working hours: $e');
      // Silently fail - working hours are optional to display
    } finally {
      if (mounted) {
        setState(() => isLoadingWorkingHours = false);
      }
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Not set';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);

      final displayHour = timeOfDay.hourOfPeriod == 0
          ? 12
          : timeOfDay.hourOfPeriod;
      final displayMinute = timeOfDay.minute.toString().padLeft(2, '0');
      final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';

      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 FIXED SALARY HANDLING HERE (NOT INSIDE UI)
    final salary =
        widget.user['salary'] ??
        widget.user['Salary'] ??
        widget.user['salaryInfo'];

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
                // Reload working hours after edit
                _loadWorkingHours();
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
            // ============================================
            // PROFILE SECTION
            // ============================================
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFD7BE69),
                    backgroundImage:
                        widget.user['image'] != null &&
                            widget.user['image'].toString().startsWith('http')
                        ? NetworkImage(widget.user['image'])
                        : null,
                    child:
                        widget.user['image'] == null ||
                            !widget.user['image'].toString().startsWith('http')
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

            // CONTACT INFORMATION
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

            // PERSONAL INFORMATION
            _buildSectionTitle("Personal Information"),
            _buildInfoCard([
              if (widget.user['gender'] != null)
                _buildInfoRow(Icons.wc, "Gender", widget.user['gender']),
              if (widget.user['dateOfBirth'] != null)
                _buildInfoRow(
                  Icons.cake,
                  "Date of Birth",
                  _formatDate(widget.user['dateOfBirth']),
                ),
              if (widget.user['preferredLanguages'] != null &&
                  (widget.user['preferredLanguages'] as List).isNotEmpty)
                _buildInfoRow(
                  Icons.language,
                  "Preferred Languages",
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

            // ROLE & DEPARTMENT
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

            // WORKING HOURS
            _buildSectionTitle("Working Hours"),
            _buildWorkingHoursCard(),

            const SizedBox(height: 20),

            // ADDRESS INFORMATION
            if (widget.user['address'] != null ||
                widget.user['city'] != null ||
                widget.user['state'] != null ||
                widget.user['pincode'] != null ||
                widget.user['area'] != null) ...[
              _buildSectionTitle("Address Information"),
              _buildInfoCard([
                if (widget.user['address'] != null)
                  _buildInfoRow(Icons.home, "Address", widget.user['address']),
                if (widget.user['area'] != null)
                  _buildInfoRow(Icons.place, "Area", widget.user['area']),
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

            // GEOLOCATION INFORMATION
            if (widget.user['latitude'] != null &&
                widget.user['longitude'] != null) ...[
              _buildSectionTitle("Geolocation"),
              _buildInfoCard([
                _buildInfoRow(
                  Icons.location_on,
                  "Coordinates",
                  "Lat: ${_formatCoordinate(widget.user['latitude'])}, Lng: ${_formatCoordinate(widget.user['longitude'])}",
                  canCopy: true,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD7BE69),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FlutterMap(
                      options: MapOptions(
                        center: LatLng(
                          _parseCoordinate(widget.user['latitude']),
                          _parseCoordinate(widget.user['longitude']),
                        ),
                        zoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.loagma.crm',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _parseCoordinate(widget.user['latitude']),
                                _parseCoordinate(widget.user['longitude']),
                              ),
                              width: 40,
                              height: 40,
                              builder: (context) => const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // ============================================
            // SALARY INFORMATION (FIXED)
            // ============================================
            if (salary != null) ...[
              _buildSectionTitle("Salary Information"),
              _buildInfoCard([
                _buildSalaryRow(
                  "Basic Salary",
                  salary['basicSalary'],
                  Colors.blue,
                ),
                if ((salary['hra'] ?? 0) > 0)
                  _buildSalaryRow("HRA", salary['hra'], Colors.purple),
                if ((salary['travelAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Travel Allowance",
                    salary['travelAllowance'],
                    Colors.orange,
                  ),
                if ((salary['dailyAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Daily Allowance",
                    salary['dailyAllowance'],
                    Colors.teal,
                  ),
                if ((salary['medicalAllowance'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Medical Allowance",
                    salary['medicalAllowance'],
                    Colors.red,
                  ),

                const Divider(height: 24),

                _buildSalaryRow(
                  "Gross Salary",
                  salary['grossSalary'],
                  Colors.green,
                  isBold: true,
                ),

                if ((salary['totalDeductions'] ?? 0) > 0)
                  _buildSalaryRow(
                    "Total Deductions",
                    salary['totalDeductions'],
                    Colors.red,
                  ),

                const Divider(height: 24),

                _buildSalaryRow(
                  "Net Salary",
                  salary['netSalary'],
                  const Color(0xFFD7BE69),
                  isBold: true,
                  isLarge: true,
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment: ${salary['paymentFrequency'] ?? 'Monthly'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "Currency: ${salary['currency'] ?? 'INR'}",
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

            // NOTES
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

            // SYSTEM INFORMATION
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

            // EDIT BUTTON
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL WIDGET BUILDERS
  // ============================================================

  Widget _buildWorkingHoursCard() {
    print(
      '🔍 Building working hours card - Loading: $isLoadingWorkingHours, Data: $workingHours',
    );

    if (isLoadingWorkingHours) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFD7BE69)),
                SizedBox(height: 12),
                Text('Loading working hours...'),
              ],
            ),
          ),
        ),
      );
    }

    if (workingHours == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.schedule_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                "Working hours not configured",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                "Default schedule applies (9:00 AM - 6:00 PM)",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap edit to configure working hours",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Work Schedule
            _buildWorkingHoursRow(
              Icons.login,
              "Work Start Time",
              _formatTime(workingHours!['workStartTime']),
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildWorkingHoursRow(
              Icons.logout,
              "Work End Time",
              _formatTime(workingHours!['workEndTime']),
              Colors.red,
            ),

            const Divider(height: 24),

            // Grace Periods
            _buildWorkingHoursRow(
              Icons.timer,
              "Late Punch-In Grace",
              "${workingHours!['latePunchInGraceMinutes'] ?? 45} minutes",
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildWorkingHoursRow(
              Icons.timer_off,
              "Early Punch-Out Grace",
              "${workingHours!['earlyPunchOutGraceMinutes'] ?? 30} minutes",
              Colors.purple,
            ),

            const Divider(height: 24),

            // Calculated Cutoffs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Approval Required",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Late punch-in after ${_formatTime(workingHours!['latePunchInCutoffTime'])}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "• Early punch-out before ${_formatTime(workingHours!['earlyPunchOutCutoffTime'])}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
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
      ],
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
                Fluttertoast.showToast(msg: "Copied to clipboard");
              },
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
    final value = amount is String
        ? double.tryParse(amount) ?? 0
        : (amount ?? 0);

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

  // Number formatter
  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = number is String ? double.tryParse(number) ?? 0 : number;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // Date formatter
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  // Coordinate parser
  double _parseCoordinate(dynamic coord) {
    if (coord == null) return 0.0;
    if (coord is double) return coord;
    if (coord is int) return coord.toDouble();
    if (coord is String) return double.tryParse(coord) ?? 0.0;
    return 0.0;
  }

  // Coordinate formatter
  String _formatCoordinate(dynamic coord) {
    final value = _parseCoordinate(coord);
    return value.toStringAsFixed(6);
  }
}
