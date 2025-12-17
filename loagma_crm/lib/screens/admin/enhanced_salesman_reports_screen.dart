import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';

class EnhancedSalesmanReportsScreen extends StatefulWidget {
  const EnhancedSalesmanReportsScreen({super.key});

  @override
  State<EnhancedSalesmanReportsScreen> createState() =>
      _EnhancedSalesmanReportsScreenState();
}

class _EnhancedSalesmanReportsScreenState
    extends State<EnhancedSalesmanReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;
  String? errorMessage;

  // Data
  Map<String, dynamic> reportsData = {};
  List<Map<String, dynamic>> salesmenList = [];
  String? selectedSalesmanId;
  String selectedPeriod = 'today';
  DateTime? customStartDate;
  DateTime? customEndDate;

  // Colors
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSalesmenList();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesmenList() async {
    try {
      final token = UserService.token;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = List<Map<String, dynamic>>.from(data['data'] ?? []);
          setState(() {
            salesmenList = users
                .where(
                  (user) =>
                      user['roles'] != null &&
                      (user['roles'] as List).contains('Salesman'),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading salesmen list: $e');
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = UserService.token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, String>{'period': selectedPeriod};

      if (selectedSalesmanId != null) {
        queryParams['salesmanId'] = selectedSalesmanId!;
      }

      if (customStartDate != null) {
        queryParams['startDate'] = customStartDate!.toIso8601String();
      }

      if (customEndDate != null) {
        queryParams['endDate'] = customEndDate!.toIso8601String();
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/salesman-reports/reports',
      ).replace(queryParameters: queryParams);

      print('📡 Loading reports from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Reports response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            reportsData = data['data'];
            isLoading = false;
          });
          print('✅ Reports loaded successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to load reports');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading reports: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading reports: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman Reports'),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Performance'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Daily'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : errorMessage != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildPerformanceTab(),
                      _buildDailyTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Salesman selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSalesmanId,
                  decoration: const InputDecoration(
                    labelText: 'Select Salesman',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Salesmen'),
                    ),
                    ...salesmenList.map((salesman) {
                      return DropdownMenuItem<String>(
                        value: salesman['id'],
                        child: Text(salesman['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSalesmanId = value;
                    });
                    _loadReports();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadReports,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period selector
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'today', label: Text('Today')),
                    ButtonSegment(value: 'week', label: Text('Week')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                    ButtonSegment(value: 'custom', label: Text('Custom')),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      selectedPeriod = newSelection.first;
                      if (selectedPeriod != 'custom') {
                        customStartDate = null;
                        customEndDate = null;
                      }
                    });
                    if (selectedPeriod != 'custom') {
                      _loadReports();
                    }
                  },
                ),
              ),
            ],
          ),

          // Custom date range
          if (selectedPeriod == 'custom') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        customStartDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(customStartDate!)
                            : 'Select start date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        customEndDate != null
                            ? DateFormat('MMM dd, yyyy').format(customEndDate!)
                            : 'Select end date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: customStartDate != null && customEndDate != null
                      ? _loadReports
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          customStartDate = picked;
        } else {
          customEndDate = picked;
        }
      });
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: errorColor),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReports,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = reportsData['summary'] ?? {};
    final performanceMetrics = summary['performanceMetrics'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          const Text(
            'Summary Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Accounts Created',
                summary['totalAccountsCreated']?.toString() ?? '0',
                Icons.add_business,
                infoColor,
              ),
              _buildStatCard(
                'Today\'s Accounts',
                summary['accountsCreatedToday']?.toString() ?? '0',
                Icons.today,
                successColor,
              ),
              _buildStatCard(
                'Approved',
                summary['approvedAccounts']?.toString() ?? '0',
                Icons.verified,
                successColor,
              ),
              _buildStatCard(
                'Pending',
                summary['pendingAccounts']?.toString() ?? '0',
                Icons.pending,
                warningColor,
              ),
              _buildStatCard(
                'Total Visits',
                summary['totalVisits']?.toString() ?? '0',
                Icons.location_on,
                primaryColor,
              ),
              _buildStatCard(
                'Today\'s Visits',
                summary['visitsToday']?.toString() ?? '0',
                Icons.today,
                primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Performance metrics
          const Text(
            'Performance Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricRow(
                    'Accounts per Day',
                    (performanceMetrics['accountsPerDay'] ?? 0.0)
                        .toStringAsFixed(1),
                    Icons.trending_up,
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Visits per Day',
                    (performanceMetrics['visitsPerDay'] ?? 0.0).toStringAsFixed(
                      1,
                    ),
                    Icons.location_on,
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Approval Rate',
                    '${(performanceMetrics['approvalRate'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Avg Work Hours',
                    '${(performanceMetrics['averageWorkHours'] ?? 0.0).toStringAsFixed(1)}h',
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent accounts
          if (reportsData['recentAccounts'] != null) ...[
            const Text(
              'Recent Accounts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...((reportsData['recentAccounts'] as List).take(5).map((account) {
              return _buildAccountCard(account);
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final salesmenPerformance = reportsData['salesmenPerformance'] ?? [];

    if (salesmenPerformance.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No performance data available'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: salesmenPerformance.length,
      itemBuilder: (context, index) {
        final salesman = salesmenPerformance[index];
        return _buildSalesmanPerformanceCard(salesman);
      },
    );
  }

  Widget _buildDailyTab() {
    if (selectedSalesmanId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Please select a salesman to view daily reports'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector for daily report
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Date:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDailyReportDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          customStartDate != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(customStartDate!)
                              : DateFormat(
                                  'MMM dd, yyyy',
                                ).format(DateTime.now()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loadDailyReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    child: const Text('Load Report'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Daily report content will be loaded here
          if (reportsData['dailyReport'] != null) ...[
            _buildDailyReportContent(reportsData['dailyReport']),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Click "Load Report" to view daily details'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDailyReportDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        customStartDate = picked;
      });
    }
  }

  Future<void> _loadDailyReport() async {
    if (selectedSalesmanId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = UserService.token;
      if (token == null) throw Exception('Authentication token not found');

      final queryParams = <String, String>{
        'salesmanId': selectedSalesmanId!,
        'date': (customStartDate ?? DateTime.now()).toIso8601String(),
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/salesman-reports/daily-report',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            reportsData['dailyReport'] = data['data'];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load daily report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading daily report: $e';
      });
    }
  }

  Widget _buildDailyReportContent(Map<String, dynamic> dailyReport) {
    final summary = dailyReport['summary'] ?? {};
    final accountsDetails = dailyReport['accountsDetails'] ?? [];
    final attendance = dailyReport['attendance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Accounts Created',
                summary['accountsCreated']?.toString() ?? '0',
                Icons.add_business,
                infoColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Work Hours',
                '${(summary['workHours'] ?? 0.0).toStringAsFixed(1)}h',
                Icons.access_time,
                primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Attendance info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (attendance != null) ...[
                  _buildAttendanceRow(
                    'Punch In',
                    attendance['punchInTime'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(attendance['punchInTime']))
                        : 'Not punched in',
                    Icons.login,
                  ),
                  const Divider(),
                  _buildAttendanceRow(
                    'Punch Out',
                    attendance['punchOutTime'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(attendance['punchOutTime']))
                        : 'Not punched out',
                    Icons.logout,
                  ),
                  const Divider(),
                  _buildAttendanceRow(
                    'Status',
                    attendance['status'] ?? 'No attendance',
                    Icons.info,
                  ),
                ] else ...[
                  const Text('No attendance record for this date'),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Accounts created today
        if (accountsDetails.isNotEmpty) ...[
          const Text(
            'Accounts Created Today',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...accountsDetails
              .map((account) => _buildAccountCard(account))
              .toList(),
        ] else ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No accounts created on this date')),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttendanceRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final accountsByStage = reportsData['accountsByStage'] ?? [];
    final accountsByBusinessType = reportsData['accountsByBusinessType'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accounts by stage
          const Text(
            'Accounts by Customer Stage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (accountsByStage.isNotEmpty) ...[
            ...accountsByStage.map((item) {
              return _buildAnalyticsBar(
                item['stage'] ?? 'Unknown',
                item['count'] ?? 0,
                primaryColor,
              );
            }).toList(),
          ] else
            const Text('No data available'),

          const SizedBox(height: 32),

          // Accounts by business type
          const Text(
            'Accounts by Business Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (accountsByBusinessType.isNotEmpty) ...[
            ...accountsByBusinessType.map((item) {
              return _buildAnalyticsBar(
                item['type'] ?? 'Unknown',
                item['count'] ?? 0,
                infoColor,
              );
            }).toList(),
          ] else
            const Text('No data available'),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final createdAt = DateTime.parse(account['createdAt']);
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: Text(
            (account['personName'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account['personName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account['businessName'] != null) Text(account['businessName']),
            Text(
              'Created $timeAgo',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: account['isApproved'] == true
            ? const Icon(Icons.verified, color: successColor)
            : const Icon(Icons.pending, color: warningColor),
      ),
    );
  }

  Widget _buildSalesmanPerformanceCard(Map<String, dynamic> salesman) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: Text(
            (salesman['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          salesman['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${salesman['accountsCreated'] ?? 0} accounts • ${salesman['visits'] ?? 0} visits',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      'Accounts',
                      (salesman['accountsCreated'] ?? 0).toString(),
                      Icons.business,
                    ),
                    _buildMiniStat(
                      'Approved',
                      (salesman['accountsApproved'] ?? 0).toString(),
                      Icons.verified,
                    ),
                    _buildMiniStat(
                      'Visits',
                      (salesman['visits'] ?? 0).toString(),
                      Icons.location_on,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      'Approval Rate',
                      '${(salesman['approvalRate'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.percent,
                    ),
                    _buildMiniStat(
                      'Avg Hours',
                      '${(salesman['averageWorkHours'] ?? 0.0).toStringAsFixed(1)}h',
                      Icons.access_time,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAnalyticsBar(String label, int count, Color color) {
    // Calculate percentage for bar width (assuming max count for scaling)
    final maxCount = 100; // You can calculate this dynamically
    final percentage = count / maxCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
