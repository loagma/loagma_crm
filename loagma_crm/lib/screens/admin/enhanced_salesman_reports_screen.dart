import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (token == null) {
        print('❌ No token available for loading salesmen');
        return;
      }

      print('📡 Loading salesmen list from: ${ApiConfig.baseUrl}/admin/users');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('👥 Salesmen list response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '👥 Salesmen list response data: ${data.toString().substring(0, 500)}...',
        );

        if (data['success'] == true) {
          final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          print('👥 Total users found: ${users.length}');

          // Debug: Print first few users to see structure
          if (users.isNotEmpty) {
            print('👥 Sample user structure: ${jsonEncode(users.first)}');
            print('👥 Sample user roles: ${users.first['roles']}');
            print('👥 Sample user roleId: ${users.first['roleId']}');
          }

          final salesmen = users.where((user) {
            try {
              // Check multiple possible role field structures
              bool isSalesman = false;

              // Tertiary check: roles array
              if (!isSalesman &&
                  user['roles'] != null &&
                  user['roles'] is List) {
                final roles = user['roles'] as List;
                // Check for various salesman role variations including R002
                isSalesman = roles.any(
                  (role) =>
                      role.toString() == 'R002' || // Direct role ID
                      role.toString().toLowerCase().contains('salesman') ||
                      role.toString().toLowerCase().contains('sales'),
                );
                print(
                  '👥 User ${user['name']} roles array check: $roles -> $isSalesman',
                );
              }

              // Primary check: role field (most reliable)
              if (!isSalesman && user['role'] != null) {
                final roleName = user['role'].toString().toLowerCase();
                isSalesman =
                    roleName.contains('salesman') || roleName.contains('sales');
                print(
                  '👥 User ${user['name']} role check: $roleName -> $isSalesman',
                );
              }

              // Secondary check: roleId field (R002 = salesman)
              if (!isSalesman && user['roleId'] != null) {
                final roleId = user['roleId'].toString();
                isSalesman =
                    roleId == 'R002' || // Direct salesman role ID
                    roleId.toLowerCase().contains('salesman') ||
                    roleId.toLowerCase().contains('sales');
                print(
                  '👥 User ${user['name']} roleId check: $roleId -> $isSalesman',
                );
              }

              // Debug each user
              if (user['name'] != null) {
                print(
                  '👥 User: ${user['name']} (roleId: ${user['roleId']}, role: ${user['role']}, roles: ${user['roles']}) -> isSalesman: $isSalesman',
                );
              }

              return isSalesman;
            } catch (e) {
              print('❌ Error processing user ${user['name']}: $e');
              return false;
            }
          }).toList();

          print('👥 Salesmen found: ${salesmen.length}');

          // Update state immediately
          print('🔄 Setting salesmenList with ${salesmen.length} salesmen');
          setState(() {
            salesmenList = salesmen;
          });
          print(
            '✅ salesmenList updated. Current length: ${salesmenList.length}',
          );

          // Debug output (separate from state update)
          if (salesmen.isNotEmpty) {
            print('✅ Salesmen names:');
            for (int i = 0; i < salesmen.length; i++) {
              final salesman = salesmen[i];
              print('  ${i + 1}. ${salesman['name']} (ID: ${salesman['id']})');
            }
          } else {
            print('❌ No salesmen found');
          }
        } else {
          print('❌ API response success = false: ${data['message']}');
        }
      } else {
        print('❌ Failed to load salesmen: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading salesmen list: $e');
      setState(() {
        errorMessage = 'Failed to load salesmen list: $e';
      });
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
    print(
      '🎨 Building filter section. salesmenList length: ${salesmenList.length}',
    );
    if (salesmenList.isNotEmpty) {
      print(
        '🎨 First salesman: ${salesmenList.first['name']} (${salesmenList.first['id']})',
      );
    }
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
                      final id = salesman['id']?.toString() ?? '';
                      final name = salesman['name']?.toString() ?? 'Unknown';
                      print('🎯 Creating dropdown item: $name ($id)');
                      return DropdownMenuItem<String>(
                        value: id.isNotEmpty ? id : null,
                        child: Text(name),
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
                icon: const Icon(Icons.download),
                onPressed: _exportReports,
                tooltip: 'Export',
              ),
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
          // Key insights card
          _buildKeyInsightsCard(summary, performanceMetrics),
          const SizedBox(height: 16),

          // Visit tracking info card
          const SizedBox(height: 24),
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
            childAspectRatio: 1.8,
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
                    ((performanceMetrics['visitsPerDay'] ?? 0.0) as num)
                        .toDouble()
                        .toStringAsFixed(1),
                    Icons.location_on,
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Approval Rate',
                    '${((performanceMetrics['approvalRate'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Avg Work Hours',
                    '${((performanceMetrics['averageWorkHours'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}h',
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
    final selectedSalesman = reportsData['salesman'];
    final summary = reportsData['summary'] ?? {};
    final performanceMetrics = summary['performanceMetrics'] ?? {};

    // If a specific salesman is selected, show their individual performance
    if (selectedSalesmanId != null && selectedSalesman != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected salesman header
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor,
                      radius: 30,
                      child: Text(
                        (selectedSalesman['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSalesman['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Employee ID: ${selectedSalesman['id'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (selectedSalesman['contactNumber'] != null)
                            Text(
                              'Contact: ${selectedSalesman['contactNumber']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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

            // Performance metrics for selected salesman
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Key performance indicators
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard(
                  'Accounts Created',
                  summary['totalAccountsCreated']?.toString() ?? '0',
                  Icons.add_business,
                  infoColor,
                ),
                _buildStatCard(
                  'Accounts Approved',
                  summary['approvedAccounts']?.toString() ?? '0',
                  Icons.verified,
                  successColor,
                ),
                _buildStatCard(
                  'Total Visits',
                  summary['totalVisits']?.toString() ?? '0',
                  Icons.location_on,
                  primaryColor,
                ),
                _buildStatCard(
                  'Approval Rate',
                  '${((performanceMetrics['approvalRate'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}%',
                  Icons.percent,
                  performanceMetrics['approvalRate'] != null &&
                          performanceMetrics['approvalRate'] >= 70
                      ? successColor
                      : performanceMetrics['approvalRate'] != null &&
                            performanceMetrics['approvalRate'] >= 50
                      ? warningColor
                      : errorColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Detailed performance breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow(
                      'Accounts per Day',
                      ((performanceMetrics['accountsPerDay'] ?? 0.0) as num)
                          .toDouble()
                          .toStringAsFixed(1),
                      Icons.trending_up,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'Visits per Day',
                      ((performanceMetrics['visitsPerDay'] ?? 0.0) as num)
                          .toDouble()
                          .toStringAsFixed(1),
                      Icons.location_on,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'Average Work Hours',
                      '${((performanceMetrics['averageWorkHours'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}h',
                      Icons.access_time,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'Today\'s Accounts',
                      summary['accountsCreatedToday']?.toString() ?? '0',
                      Icons.today,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'Today\'s Visits',
                      summary['visitsToday']?.toString() ?? '0',
                      Icons.today,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Performance insights
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Performance Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPerformanceInsight(performanceMetrics, summary),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If "All Salesmen" is selected, show comparison view
    if (salesmenPerformance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No performance data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Select "All Salesmen" to see team performance comparison',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show all salesmen performance comparison
    return Column(
      children: [
        // Header for comparison view
        Container(
          padding: const EdgeInsets.all(16),
          color: primaryColor.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(Icons.leaderboard, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Team Performance Comparison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Salesmen list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salesmenPerformance.length,
            itemBuilder: (context, index) {
              final salesman = salesmenPerformance[index];
              return _buildSalesmanPerformanceCard(salesman);
            },
          ),
        ),
      ],
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
                '${((summary['workHours'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}h',
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

  Widget _buildKeyInsightsCard(
    Map<String, dynamic> summary,
    Map<String, dynamic> performanceMetrics,
  ) {
    final totalAccounts = summary['totalAccountsCreated'] ?? 0;
    final approvalRate = (performanceMetrics['approvalRate'] ?? 0.0).toDouble();
    final accountsPerDay = (performanceMetrics['accountsPerDay'] ?? 0.0)
        .toDouble();

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.1),
              primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Key Insights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Insights based on data
            if (totalAccounts > 0) ...[
              _buildInsightItem(
                Icons.trending_up,
                'Performance Status',
                _getPerformanceStatus(approvalRate, accountsPerDay),
                _getPerformanceColor(approvalRate),
              ),
              const SizedBox(height: 12),
            ],

            if (approvalRate > 0) ...[
              _buildInsightItem(
                Icons.check_circle,
                'Approval Rate',
                '${approvalRate.toStringAsFixed(1)}% of accounts get approved',
                approvalRate >= 70
                    ? successColor
                    : approvalRate >= 50
                    ? warningColor
                    : errorColor,
              ),
              const SizedBox(height: 12),
            ],

            if (accountsPerDay > 0) ...[
              _buildInsightItem(
                Icons.speed,
                'Daily Productivity',
                '${accountsPerDay.toStringAsFixed(1)} accounts created per day on average',
                accountsPerDay >= 5
                    ? successColor
                    : accountsPerDay >= 2
                    ? warningColor
                    : errorColor,
              ),
            ],

            if (totalAccounts == 0) ...[
              _buildInsightItem(
                Icons.info,
                'No Data',
                'No accounts found for the selected period',
                Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPerformanceStatus(double approvalRate, double accountsPerDay) {
    if (approvalRate >= 80 && accountsPerDay >= 5) {
      return 'Excellent performance! High approval rate and productivity';
    } else if (approvalRate >= 70 && accountsPerDay >= 3) {
      return 'Good performance with room for improvement';
    } else if (approvalRate >= 50 || accountsPerDay >= 2) {
      return 'Average performance, consider training or support';
    } else {
      return 'Below average performance, needs attention';
    }
  }

  Color _getPerformanceColor(double approvalRate) {
    if (approvalRate >= 70) return successColor;
    if (approvalRate >= 50) return warningColor;
    return errorColor;
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
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
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Accounts',
                        (salesman['accountsCreated'] ?? 0).toString(),
                        Icons.business,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Approved',
                        (salesman['accountsApproved'] ?? 0).toString(),
                        Icons.verified,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Visits',
                        (salesman['visits'] ?? 0).toString(),
                        Icons.location_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Approval Rate',
                        '${((salesman['approvalRate'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}%',
                        Icons.percent,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Avg Hours',
                        '${((salesman['averageWorkHours'] ?? 0.0) as num).toDouble().toStringAsFixed(1)}h',
                        Icons.access_time,
                      ),
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ), // Empty space for balance
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

  Future<void> _exportReports() async {
    try {
      // Generate CSV content
      String csvContent = _generateCSVContent();

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: csvContent));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report data copied to clipboard as CSV format'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting reports: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  String _generateCSVContent() {
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Salesman Reports Export');
    csv.writeln(
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    csv.writeln('Period: $selectedPeriod');
    if (selectedSalesmanId != null) {
      final selectedSalesman = salesmenList.firstWhere(
        (s) => s['id'] == selectedSalesmanId,
        orElse: () => {'name': 'Unknown'},
      );
      csv.writeln('Salesman: ${selectedSalesman['name']}');
    }
    csv.writeln('');

    // Summary statistics
    final summary = reportsData['summary'] ?? {};
    csv.writeln('SUMMARY STATISTICS');
    csv.writeln('Metric,Value');
    csv.writeln(
      'Total Accounts Created,${summary['totalAccountsCreated'] ?? 0}',
    );
    csv.writeln(
      'Accounts Created Today,${summary['accountsCreatedToday'] ?? 0}',
    );
    csv.writeln('Approved Accounts,${summary['approvedAccounts'] ?? 0}');
    csv.writeln('Pending Accounts,${summary['pendingAccounts'] ?? 0}');
    csv.writeln('Total Visits,${summary['totalVisits'] ?? 0}');
    csv.writeln('Visits Today,${summary['visitsToday'] ?? 0}');
    csv.writeln('');

    // Performance metrics
    final performanceMetrics = summary['performanceMetrics'] ?? {};
    csv.writeln('PERFORMANCE METRICS');
    csv.writeln('Metric,Value');
    csv.writeln(
      'Accounts per Day,${((performanceMetrics['accountsPerDay'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
    );
    csv.writeln(
      'Visits per Day,${((performanceMetrics['visitsPerDay'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
    );
    csv.writeln(
      'Approval Rate (%),${((performanceMetrics['approvalRate'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
    );
    csv.writeln(
      'Average Work Hours,${((performanceMetrics['averageWorkHours'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
    );
    csv.writeln('');

    // Salesmen performance (if showing all salesmen)
    final salesmenPerformance = reportsData['salesmenPerformance'] ?? [];
    if (salesmenPerformance.isNotEmpty) {
      csv.writeln('SALESMEN PERFORMANCE');
      csv.writeln(
        'Name,Accounts Created,Accounts Approved,Visits,Approval Rate (%),Average Work Hours',
      );
      for (final salesman in salesmenPerformance) {
        csv.writeln(
          '${salesman['name'] ?? 'Unknown'},'
          '${salesman['accountsCreated'] ?? 0},'
          '${salesman['accountsApproved'] ?? 0},'
          '${salesman['visits'] ?? 0},'
          '${((salesman['approvalRate'] ?? 0.0) as num).toDouble().toStringAsFixed(2)},'
          '${((salesman['averageWorkHours'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
        );
      }
      csv.writeln('');
    }

    // Recent accounts
    final recentAccounts = reportsData['recentAccounts'] ?? [];
    if (recentAccounts.isNotEmpty) {
      csv.writeln('RECENT ACCOUNTS');
      csv.writeln(
        'Person Name,Business Name,Contact Number,Customer Stage,Business Type,Approved,Created At',
      );
      for (final account in recentAccounts.take(50)) {
        csv.writeln(
          '${account['personName'] ?? ''},'
          '${account['businessName'] ?? ''},'
          '${account['contactNumber'] ?? ''},'
          '${account['customerStage'] ?? ''},'
          '${account['businessType'] ?? ''},'
          '${account['isApproved'] == true ? 'Yes' : 'No'},'
          '${account['createdAt'] ?? ''}',
        );
      }
    }

    return csv.toString();
  }

  Widget _buildInfoStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: infoColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsight(
    Map<String, dynamic> performanceMetrics,
    Map<String, dynamic> summary,
  ) {
    final approvalRate = (performanceMetrics['approvalRate'] ?? 0.0) as num;
    final accountsPerDay = (performanceMetrics['accountsPerDay'] ?? 0.0) as num;
    final visitsPerDay = (performanceMetrics['visitsPerDay'] ?? 0.0) as num;
    final totalAccounts = summary['totalAccountsCreated'] ?? 0;

    List<Widget> insights = [];

    // Performance level insight
    if (approvalRate >= 80 && accountsPerDay >= 3) {
      insights.add(
        _buildInsightItem(
          Icons.star,
          'Excellent Performance',
          'High approval rate (${approvalRate.toStringAsFixed(1)}%) and good productivity',
          successColor,
        ),
      );
    } else if (approvalRate >= 60 && accountsPerDay >= 2) {
      insights.add(
        _buildInsightItem(
          Icons.trending_up,
          'Good Performance',
          'Solid results with room for improvement',
          primaryColor,
        ),
      );
    } else {
      insights.add(
        _buildInsightItem(
          Icons.trending_down,
          'Needs Improvement',
          'Consider additional training or support',
          warningColor,
        ),
      );
    }

    // Productivity insight
    if (accountsPerDay > 0) {
      insights.add(
        _buildInsightItem(
          Icons.speed,
          'Daily Productivity',
          '${accountsPerDay.toStringAsFixed(1)} accounts created per day on average',
          infoColor,
        ),
      );
    }

    // Visit efficiency
    if (visitsPerDay > 0) {
      insights.add(
        _buildInsightItem(
          Icons.location_on,
          'Visit Frequency',
          '${visitsPerDay.toStringAsFixed(1)} visits per day on average',
          primaryColor,
        ),
      );
    }

    // Total contribution
    if (totalAccounts > 0) {
      insights.add(
        _buildInsightItem(
          Icons.business,
          'Total Contribution',
          '$totalAccounts accounts created in selected period',
          infoColor,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        _buildInsightItem(
          Icons.info,
          'No Data',
          'No performance data available for the selected period',
          Colors.grey,
        ),
      );
    }

    return Column(
      children: insights
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: insight,
            ),
          )
          .toList(),
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

  void _showVisitInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: infoColor),
              const SizedBox(width: 8),
              const Text('Visit Tracking Instructions'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How Salesmen Mark Visits:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildInstructionStep(
                  '1. Open Mobile App',
                  'Salesman opens the Loagma CRM mobile app on their phone',
                  Icons.phone_android,
                ),

                _buildInstructionStep(
                  '2. Navigate to Attendance',
                  'Go to the attendance section in the app',
                  Icons.access_time,
                ),

                _buildInstructionStep(
                  '3. Punch In with Location',
                  'Tap "Punch In" button which captures GPS location automatically',
                  Icons.location_on,
                ),

                _buildInstructionStep(
                  '4. System Records Visit',
                  'Each punch-in is counted as one visit for that day',
                  Icons.check_circle,
                ),

                _buildInstructionStep(
                  '5. Work Throughout Day',
                  'Salesman can create accounts, visit customers, etc.',
                  Icons.work,
                ),

                _buildInstructionStep(
                  '6. Punch Out (Optional)',
                  'At end of day, punch out to calculate total work hours',
                  Icons.logout,
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: warningColor, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Important Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• GPS location is required for punch-in'),
                      const Text('• One punch-in = One visit per day'),
                      const Text('• Multiple sessions allowed per day'),
                      const Text('• Work hours calculated automatically'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionStep(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewAttendanceRecords() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attendance Records'),
          content: const Text(
            'This feature will show detailed attendance records for all salesmen. '
            'You can view punch-in/out times, locations, and work hours.\n\n'
            'Coming soon in the next update!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAttendanceHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Attendance Help Guide'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'For Admins:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Monitor salesman visits through this reports screen',
                ),
                const Text('• Each punch-in counts as one visit'),
                const Text('• Filter by date range to see historical data'),
                const Text('• Export reports for further analysis'),

                const SizedBox(height: 16),
                const Text(
                  'For Salesmen:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Must punch in daily to record visits'),
                const Text('• GPS location is automatically captured'),
                const Text('• Can have multiple sessions per day'),
                const Text('• Punch out to complete work hours calculation'),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: successColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Best Practices:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Encourage daily punch-in for accurate tracking',
                      ),
                      const Text(
                        '• Review reports weekly to monitor performance',
                      ),
                      const Text('• Use date filters to analyze trends'),
                      const Text('• Export data for monthly reviews'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
