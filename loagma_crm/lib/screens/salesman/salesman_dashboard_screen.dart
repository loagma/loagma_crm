import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class SalesmanDashboardScreen extends StatefulWidget {
  const SalesmanDashboardScreen({super.key});

  @override
  State<SalesmanDashboardScreen> createState() =>
      _SalesmanDashboardScreenState();
}

class _SalesmanDashboardScreenState extends State<SalesmanDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? accountStats;
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> recentAccounts = [];
  Map<String, int> customerStageBreakdown = {};
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pagination for recent accounts
  int currentPage = 1;
  int itemsPerPage = 2;
  int totalAccounts = 0;
  bool isLoadingMore = false;

  // Attendance status
  AttendanceModel? todayAttendance;
  bool isLoadingAttendance = false;

  // Theme colors
  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    fetchDashboardData();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => isLoadingAttendance = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (mounted) {
        setState(() {
          todayAttendance = attendance;
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingAttendance = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;
      final userName = UserService.name;
      final userRole = UserService.currentRole;

      print('🔍 Debug Info:');
      print('   User ID: $userId');
      print('   User Name: $userName');
      print('   User Role: $userRole');

      if (userId == null || userId.isEmpty) {
        print('❌ User ID is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in properly'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      print('📊 Fetching dashboard data for user: $userId');

      // Fetch account stats
      final accountStatsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts/stats?createdById=$userId',
      );
      print('📡 Fetching stats from: $accountStatsUrl');

      final accountStatsResponse = await http.get(accountStatsUrl);
      print('📥 Stats Response Status: ${accountStatsResponse.statusCode}');
      print('📥 Stats Response Body: ${accountStatsResponse.body}');

      final accountStatsData = jsonDecode(accountStatsResponse.body);

      // Fetch all accounts for recent list with pagination
      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId&limit=$itemsPerPage&page=$currentPage',
      );
      print('📡 Fetching accounts from: $accountsUrl');

      final accountsResponse = await http.get(accountsUrl);
      print('📥 Accounts Response Status: ${accountsResponse.statusCode}');
      print('📥 Accounts Response Body: ${accountsResponse.body}');

      final accountsData = jsonDecode(accountsResponse.body);

      // Get total count if available
      if (accountsData['total'] != null) {
        totalAccounts = accountsData['total'];
      } else if (accountsData['data'] != null) {
        totalAccounts = accountsData['data'].length;
      }

      // Fetch assignments
      final assignmentsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments?salesmanId=$userId',
      );
      print('📡 Fetching assignments from: $assignmentsUrl');

      final assignmentsResponse = await http.get(assignmentsUrl);
      print(
        '📥 Assignments Response Status: ${assignmentsResponse.statusCode}',
      );

      final assignmentsData = jsonDecode(assignmentsResponse.body);

      // Process customer stage breakdown
      Map<String, int> stageBreakdown = {};
      if (accountStatsData['success'] == true &&
          accountStatsData['data']?['byCustomerStage'] != null) {
        for (var stage in accountStatsData['data']['byCustomerStage']) {
          stageBreakdown[stage['customerStage'] ?? 'Unknown'] =
              stage['_count'] ?? 0;
        }
      }

      print('📊 Processed Data:');
      print('   Total Accounts: ${accountStatsData['data']?['totalAccounts']}');
      print('   Recent Accounts: ${accountsData['data']?.length}');
      print('   Assignments: ${assignmentsData['data']?.length}');

      setState(() {
        accountStats = accountStatsData['data'] ?? {};
        assignments = List<Map<String, dynamic>>.from(
          assignmentsData['data'] ?? [],
        );
        recentAccounts = List<Map<String, dynamic>>.from(
          accountsData['data'] ?? [],
        );
        customerStageBreakdown = stageBreakdown;
      });

      _animationController.forward();
      print('✅ Dashboard data loaded successfully');
    } catch (e, stackTrace) {
      print('❌ Error fetching dashboard data: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: () async {
                await fetchDashboardData();
                await _loadTodayAttendance();
              },
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Punch Status Widget - FIRST
                      _buildPunchStatusWidget(),

                      // Quick Actions Section
                      _buildQuickActionsSection(),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // 👈 THIS ALIGNS TEXT TO START
                          children: [
                            const Text(
                              'Stats',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Main Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Accounts',
                                    accountStats?['totalAccounts']
                                            ?.toString() ??
                                        '0',
                                    Icons.account_circle,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Approved',
                                    accountStats?['approvedAccounts']
                                            ?.toString() ??
                                        '0',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Pending',
                                    accountStats?['pendingAccounts']
                                            ?.toString() ??
                                        '0',
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Area Allotments',
                                    assignments.length.toString(),
                                    Icons.map,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Recent Accounts with Pagination
                      if (recentAccounts.isNotEmpty)
                        _buildRecentAccountsSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAccountsSection() {
    final totalPages = (totalAccounts / itemsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Accounts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/dashboard/salesman/accounts'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentAccounts.map((account) => _buildRecentAccountCard(account)),

          // Pagination Controls
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage > 1 && !isLoadingMore
                        ? () => _loadPage(currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: currentPage < totalPages && !isLoadingMore
                        ? () => _loadPage(currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    color: primaryColor,
                  ),
                ],
              ),
            ),

          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      isLoadingMore = true;
      currentPage = page;
    });

    try {
      final userId = UserService.currentUserId;
      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId&limit=$itemsPerPage&page=$page',
      );

      final accountsResponse = await http.get(accountsUrl);
      final accountsData = jsonDecode(accountsResponse.body);

      setState(() {
        recentAccounts = List<Map<String, dynamic>>.from(
          accountsData['data'] ?? [],
        );
        if (accountsData['total'] != null) {
          totalAccounts = accountsData['total'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingMore = false);
    }
  }

  Widget _buildRecentAccountCard(Map<String, dynamic> account) {
    final isApproved = account['isApproved'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['personName'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (account['businessName'] != null)
                  Text(
                    account['businessName'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Text(
                  account['contactNumber'] ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isApproved ? 'Approved' : 'Pending',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchStatusWidget() {
    if (isLoadingAttendance) {
      return const SizedBox.shrink();
    }

    final isPunchedIn = todayAttendance?.isPunchedIn ?? false;
    final hasAttendance = todayAttendance != null;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    IconData actionIcon;

    if (!hasAttendance) {
      statusColor = Colors.grey;
      statusIcon = Icons.schedule;
      statusText = 'Not Punched In';
      actionIcon = Icons.login;
    } else if (isPunchedIn) {
      statusColor = Colors.green;
      statusIcon = Icons.work;
      statusText = 'Working';
      actionIcon = Icons.logout;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
      actionIcon = Icons.visibility;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/dashboard/salesman/punch'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(statusIcon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasAttendance)
                        Text(
                          DateFormat(
                            'hh:mm a',
                          ).format(todayAttendance!.punchInTime),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(actionIcon, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionCard(
                'Create Account',
                Icons.person_add,
                Colors.green,
                () => context.go('/dashboard/salesman/account/master'),
              ),
              _buildActionCard(
                'Lists of Accounts',
                Icons.folder_open,
                Colors.blue,
                () => context.go('/dashboard/salesman/accounts'),
              ),
              _buildActionCard(
                'Area Allotments',
                Icons.map_outlined,
                Colors.purple,
                () => context.go('/dashboard/salesman/assignments'),
              ),
              _buildActionCard(
                'Maps',
                Icons.map,
                Colors.orange,
                () => context.go('/dashboard/salesman/map'),
              ),
              _buildActionCard(
                'Punch',
                Icons.punch_clock,
                const Color.fromARGB(255, 206, 52, 25),
                () => context.go('/dashboard/salesman/punch'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
