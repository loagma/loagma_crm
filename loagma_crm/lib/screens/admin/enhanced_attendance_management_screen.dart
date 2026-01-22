import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../services/user_service.dart';
import '../../services/api_config.dart';

class EnhancedAttendanceManagementScreen extends StatefulWidget {
  const EnhancedAttendanceManagementScreen({super.key});

  @override
  State<EnhancedAttendanceManagementScreen> createState() =>
      _EnhancedAttendanceManagementScreenState();
}

class _EnhancedAttendanceManagementScreenState
    extends State<EnhancedAttendanceManagementScreen> {
  // Data
  List<AttendanceModel> detailedAttendanceRecords = [];
  List<dynamic> allEmployees = [];
  bool isLoadingEmployees = false;

  // Filters
  DateTime selectedDate = DateTime.now();
  String? selectedEmployeeId;
  bool isLoading = false;

  // Controllers
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
    _loadEmployees();
    _loadDetailedAttendance();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (mounted) setState(() => isLoadingEmployees = true);

    try {
      print('� TLoading employees...');
      print('🌐 API URL: ${ApiConfig.baseUrl}/users/get-all');
      print('🔑 Token: ${UserService.token?.substring(0, 20)}...');

      final result = await UserService.getAllUsers();
      if (mounted) {
        print('📊 Employee load result: $result');
        if (result['success'] == true) {
          final List<dynamic> users = result['data'] ?? [];
          print('✅ Loaded ${users.length} employees');
          print(
            '👥 Employee names: ${users.map((u) => u['name']).take(3).toList()}',
          );
          setState(() {
            allEmployees = users;
            isLoadingEmployees = false;
          });
        } else {
          print('❌ Failed to load employees: ${result['message']}');
          setState(() {
            allEmployees = [];
            isLoadingEmployees = false;
          });
          // Show error to user
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load employees: ${result['message']}'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _loadEmployees,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error loading employees: $e');
      if (mounted) {
        setState(() {
          allEmployees = [];
          isLoadingEmployees = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading employees: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadEmployees,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadDetailedAttendance() async {
    if (mounted) setState(() => isLoading = true);

    try {
      print(
        '🔄 Loading detailed attendance for date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
      );
      // API expects yyyy-MM-dd format
      final result = await AttendanceService.getDetailedAttendance(
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        employeeId: selectedEmployeeId,
      );
      if (mounted) {
        if (result['success'] == true) {
          final List<AttendanceModel> records = result['data'] ?? [];
          print('✅ Loaded ${records.length} detailed attendance records');
          setState(() {
            detailedAttendanceRecords = records;
            isLoading = false;
          });
        } else {
          print('❌ Failed to load detailed attendance: ${result['message']}');
          setState(() {
            detailedAttendanceRecords = [];
            isLoading = false;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load attendance: ${result['message']}',
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _loadDetailedAttendance,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error loading detailed attendance: $e');
      if (mounted) {
        setState(() {
          detailedAttendanceRecords = [];
          isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading attendance: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadDetailedAttendance,
              ),
            ),
          );
        }
      }
    }
  }

  void _showEmployeeDetails(AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEmployeeDetailsSheet(attendance),
    );
  }

  Widget _buildEmployeeDetailsSheet(AttendanceModel attendance) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: Text(
                    attendance.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.employeeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${attendance.employeeId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: attendance.isPunchedOut
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.isPunchedOut ? 'Completed' : 'Active',
                    style: TextStyle(
                      color: attendance.isPunchedOut
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Punch In Time',
                    DateFormat(
                      'MMM dd, yyyy - HH:mm:ss',
                    ).format(attendance.punchInTime),
                    Icons.login,
                  ),
                  if (attendance.punchOutTime != null)
                    _buildDetailRow(
                      'Punch Out Time',
                      DateFormat(
                        'MMM dd, yyyy - HH:mm:ss',
                      ).format(attendance.punchOutTime!),
                      Icons.logout,
                    ),
                  _buildDetailRow(
                    'Work Duration',
                    _formatDuration(
                      attendance.totalWorkHours ??
                          _calculateCurrentWorkHours(attendance),
                    ),
                    Icons.schedule,
                  ),
                  if (attendance.totalDistanceKm != null)
                    _buildDetailRow(
                      'Distance Traveled',
                      '${attendance.totalDistanceKm!.toStringAsFixed(2)} km',
                      Icons.directions,
                    ),
                  if (attendance.punchInAddress != null)
                    _buildDetailRow(
                      'Punch In Location',
                      attendance.punchInAddress!,
                      Icons.location_on,
                    ),
                  if (attendance.punchOutAddress != null)
                    _buildDetailRow(
                      'Punch Out Location',
                      attendance.punchOutAddress!,
                      Icons.location_off,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCurrentWorkHours(AttendanceModel attendance) {
    if (attendance.isPunchedOut) return attendance.totalWorkHours ?? 0;

    final now = DateTime.now();
    final duration = now.difference(attendance.punchInTime);
    return duration.inMinutes / 60.0;
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD7BE69),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetailedAttendance,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetailedViewTab(),
    );
  }

  Widget _buildDetailedViewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Column(
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  if (isSmallScreen)
                    // Stack filters vertically on small screens
                    Column(
                      children: [
                        // Date Filter
                        TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                                _dateController.text = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(date);
                              });
                              _loadDetailedAttendance();
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Employee Filter
                        DropdownButtonFormField<String>(
                          value: selectedEmployeeId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: isLoadingEmployees
                                ? 'Loading employees...'
                                : allEmployees.isEmpty
                                ? 'No employees found'
                                : 'Select Employee',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixIcon: allEmployees.isEmpty
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadEmployees,
                                    tooltip: 'Refresh employees',
                                  ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Employees'),
                            ),
                            ...allEmployees.map(
                              (employee) => DropdownMenuItem<String>(
                                value:
                                    employee['id']?.toString() ??
                                    employee['_id']?.toString(),
                                child: Text(
                                  employee['name']?.toString() ??
                                      'Unknown Employee',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: allEmployees.isEmpty
                              ? null
                              : (value) {
                                  setState(() => selectedEmployeeId = value);
                                  _loadDetailedAttendance();
                                },
                        ),
                        const SizedBox(height: 12),

                        // Refresh Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    _loadDetailedAttendance();
                                    _loadEmployees();
                                  },
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(
                              isLoading ? 'Loading...' : 'Refresh Data',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Horizontal layout for larger screens
                    Row(
                      children: [
                        // Date Filter
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                  _dateController.text = DateFormat(
                                    'dd-MM-yyyy',
                                  ).format(date);
                                });
                                _loadDetailedAttendance();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Employee Filter
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: selectedEmployeeId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isLoadingEmployees
                                  ? 'Loading employees...'
                                  : allEmployees.isEmpty
                                  ? 'No employees found'
                                  : 'Select Employee',
                              prefixIcon: const Icon(Icons.person),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Employees'),
                              ),
                              ...allEmployees.map(
                                (employee) => DropdownMenuItem<String>(
                                  value:
                                      employee['id']?.toString() ??
                                      employee['_id']?.toString(),
                                  child: Text(
                                    employee['name']?.toString() ??
                                        'Unknown Employee',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: allEmployees.isEmpty
                                ? null
                                : (value) {
                                    setState(() => selectedEmployeeId = value);
                                    _loadDetailedAttendance();
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Refresh Button
                        IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _loadDetailedAttendance();
                                  _loadEmployees();
                                },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          ),
                          tooltip: isLoading ? 'Loading...' : 'Refresh Data',
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Summary Stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      'Total Records',
                      detailedAttendanceRecords.length.toString(),
                      Icons.list_alt,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildQuickStat(
                      'Active Sessions',
                      detailedAttendanceRecords
                          .where((a) => a.status == 'active')
                          .length
                          .toString(),
                      Icons.play_circle,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildQuickStat(
                      'Completed',
                      detailedAttendanceRecords
                          .where((a) => a.status == 'completed')
                          .length
                          .toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading attendance records...'),
                        ],
                      ),
                    )
                  : detailedAttendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No attendance records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selected date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedDate = DateTime.now();
                                _dateController.text = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(selectedDate);
                                selectedEmployeeId = null;
                              });
                              _loadDetailedAttendance();
                            },
                            icon: const Icon(Icons.today),
                            label: const Text('View Today\'s Records'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: detailedAttendanceRecords.length,
                      itemBuilder: (context, index) {
                        final attendance = detailedAttendanceRecords[index];
                        return _buildComprehensiveAttendanceCard(attendance);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildComprehensiveAttendanceCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: attendance.isPunchedOut
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        attendance.employeeName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: attendance.isPunchedOut
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Employee ID: ${attendance.employeeId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Session: ${DateFormat('MMM dd, yyyy').format(attendance.punchInTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: attendance.isPunchedOut
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          attendance.isPunchedOut
                              ? Icons.check_circle
                              : Icons.access_time,
                          size: 16,
                          color: attendance.isPunchedOut
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendance.isPunchedOut ? 'Completed' : 'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: attendance.isPunchedOut
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Punch In/Out Times Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punch In/Out Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Punch In Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.login,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Punch In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'hh:mm:ss a',
                                ).format(attendance.punchInTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (attendance.punchInAddress != null)
                                Text(
                                  attendance.punchInAddress!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (attendance.punchOutTime != null) ...[
                      const SizedBox(height: 16),

                      // Punch Out Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Punch Out',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'hh:mm:ss a',
                                  ).format(attendance.punchOutTime!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                if (attendance.punchOutAddress != null)
                                  Text(
                                    attendance.punchOutAddress!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Still Active - Not Punched Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Work Duration and Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStat(
                      'Work Duration',
                      _formatDuration(
                        attendance.totalWorkHours ??
                            _calculateCurrentWorkHours(attendance),
                      ),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  if (attendance.totalDistanceKm != null)
                    Expanded(
                      child: _buildDetailStat(
                        'Distance',
                        '${attendance.totalDistanceKm!.toStringAsFixed(2)} km',
                        Icons.directions,
                        Colors.purple,
                      ),
                    ),
                  if (attendance.bikeKmStart != null ||
                      attendance.bikeKmEnd != null)
                    Expanded(
                      child: _buildDetailStat(
                        'Vehicle KM',
                        '${attendance.bikeKmStart ?? 'N/A'} - ${attendance.bikeKmEnd ?? 'Active'}',
                        Icons.motorcycle,
                        Colors.indigo,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEmployeeDetails(attendance),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Full Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildDetailStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}
