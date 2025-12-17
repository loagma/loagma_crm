import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/task_assignment_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/attendance_status_widget.dart';
import 'sr_area_allotment_screen.dart';
import 'enhanced_salesman_map_screen.dart';

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
  List<Map<String, dynamic>> areaAssignments =
      []; // Real area assignments from backend
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
      // Check if user has valid authentication
      if (!UserService.hasValidAuth) {
        print('❌ User authentication invalid - skipping attendance load');
        return;
      }

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

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication failed')) {
        if (mounted) {
          _showAuthenticationErrorDialog();
        }
        return; // Don't continue if authentication failed
      }
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
      // Check if user has valid authentication
      if (!UserService.hasValidAuth) {
        print('❌ User authentication invalid');
        if (mounted) {
          _showAuthenticationErrorDialog();
        }
        return;
      }

      final userId = UserService.currentUserId;
      final userName = UserService.name;
      final userRole = UserService.currentRole;

      print('🔍 Debug Info:');
      print('   User ID: $userId');
      print('   User Name: $userName');
      print('   User Role: $userRole');
      print('   Token: ${UserService.token != null ? "Available" : "Missing"}');

      if (userId == null || userId.isEmpty) {
        print('❌ User ID is null or empty');
        if (mounted) {
          _showAuthenticationErrorDialog();
        }
        return;
      }

      print('📊 Fetching dashboard data for user: $userId');

      // Fetch account stats
      final accountStatsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts/stats?createdById=$userId',
      );
      print('📡 Fetching stats from: $accountStatsUrl');

      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final accountStatsResponse = await http.get(
        accountStatsUrl,
        headers: headers,
      );
      print('📥 Stats Response Status: ${accountStatsResponse.statusCode}');
      print('📥 Stats Response Body: ${accountStatsResponse.body}');

      final accountStatsData = jsonDecode(accountStatsResponse.body);

      // Fetch all accounts for recent list with pagination
      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId&limit=$itemsPerPage&page=$currentPage',
      );
      print('📡 Fetching accounts from: $accountsUrl');

      final accountsResponse = await http.get(accountsUrl, headers: headers);
      print('📥 Accounts Response Status: ${accountsResponse.statusCode}');
      print('📥 Accounts Response Body: ${accountsResponse.body}');

      final accountsData = jsonDecode(accountsResponse.body);

      // Get total count if available
      if (accountsData['total'] != null) {
        totalAccounts = accountsData['total'];
      } else if (accountsData['data'] != null) {
        totalAccounts = accountsData['data'].length;
      }

      // Fetch task assignments
      final assignmentsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments/assignments/salesman/$userId',
      );
      print('📡 Fetching task assignments from: $assignmentsUrl');

      final assignmentsResponse = await http.get(
        assignmentsUrl,
        headers: headers,
      );
      print(
        '📥 Task Assignments Response Status: ${assignmentsResponse.statusCode}',
      );

      final assignmentsData = jsonDecode(assignmentsResponse.body);

      // Fetch task assignments using the service
      print('📡 Fetching task assignments using service...');
      final fetchedTaskAssignments =
          await TaskAssignmentService.getSalesmanTaskAssignments();
      print('📥 Task Assignments loaded: ${fetchedTaskAssignments.length}');

      final areaAssignmentsData = {
        'success': true,
        'assignments': fetchedTaskAssignments.map((a) => a.toJson()).toList(),
      };

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
      print('   Task Assignments: ${assignmentsData['data']?.length}');
      final areaAssignmentsList =
          areaAssignmentsData['assignments'] as List<dynamic>? ?? [];
      print('   Area Assignments: ${areaAssignmentsList.length}');

      setState(() {
        accountStats = accountStatsData['data'] ?? {};
        assignments = List<Map<String, dynamic>>.from(
          assignmentsData['data'] ?? [],
        );
        areaAssignments = List<Map<String, dynamic>>.from(areaAssignmentsList);
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
        // Check if it's an authentication error
        if (e.toString().contains('401') ||
            e.toString().contains('Invalid token') ||
            e.toString().contains('Authentication')) {
          // Show authentication error dialog
          _showAuthenticationErrorDialog();
        } else {
          // Show general error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading dashboard: ${_getErrorMessage(e)}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => fetchDashboardData(),
              ),
            ),
          );
        }
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAuthenticationErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Authentication Error',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your session has expired or you are not properly logged in.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Please log in again to continue using the app.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear user data and navigate to login
              UserService.logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else if (errorString.contains('server')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
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
                      // Welcome Header with Salesman Name
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, Color(0xFFB8A054)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Welcome Back!',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        UserService.name ?? 'Salesman',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Role: ${UserService.currentRole?.toUpperCase() ?? 'SALESMAN'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Enhanced Attendance Status Widget
                      AttendanceStatusWidget(
                        attendance: todayAttendance,
                        showLiveLocation: true,
                        onTap: () => context.go('/dashboard/salesman/punch'),
                      ),

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
                                    areaAssignments.length.toString(),
                                    Icons.map,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Area Allotments Section
                      if (areaAssignments.isNotEmpty)
                        _buildAreaAllotmentsSection(),

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

  Widget _buildAreaAllotmentsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Area Allotments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SRAreaAllotmentScreen(),
                  ),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: areaAssignments.length,
              itemBuilder: (context, index) {
                final assignment = areaAssignments[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildAreaAllotmentCard(assignment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaAllotmentCard(Map<String, dynamic> assignment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignment['city'] ?? 'Unknown City',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assignment['district'] ?? 'Unknown District',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.pin_drop, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  assignment['pinCode'] ?? 'N/A',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: assignment['isActive'] == true
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignment['isActive'] == true ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId&limit=$itemsPerPage&page=$page',
      );

      final accountsResponse = await http.get(accountsUrl, headers: headers);
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
            color: Colors.grey.withValues(alpha: 0.1),
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
              color: primaryColor.withValues(alpha: 0.1),
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
                'SR Area Allotment',
                Icons.location_city,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SRAreaAllotmentScreen(),
                  ),
                ),
              ),
              _buildActionCard(
                'Maps',
                Icons.map,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedSalesmanMapScreen(),
                  ),
                ),
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
