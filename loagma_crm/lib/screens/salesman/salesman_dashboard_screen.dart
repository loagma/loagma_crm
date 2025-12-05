import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';

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

      // Fetch all accounts for recent list
      final accountsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId&limit=5',
      );
      print('📡 Fetching accounts from: $accountsUrl');

      final accountsResponse = await http.get(accountsUrl);
      print('📥 Accounts Response Status: ${accountsResponse.statusCode}');
      print('📥 Accounts Response Body: ${accountsResponse.body}');

      final accountsData = jsonDecode(accountsResponse.body);

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
              onRefresh: fetchDashboardData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Header with gradient
                      _buildHeader(),

                      // Stats Cards
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
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

                      // Customer Stage Breakdown
                      if (customerStageBreakdown.isNotEmpty)
                        _buildCustomerStageSection(),

                      // Recent Accounts
                      if (recentAccounts.isNotEmpty)
                        _buildRecentAccountsSection(),

                      // Quick Actions Section
                      _buildQuickActionsSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD7BE69), Color(0xFFC4A952)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                UserService.name ?? 'Salesman',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
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

  Widget _buildCustomerStageSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Stages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: customerStageBreakdown.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStageColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStageColor(entry.key).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getStageColor(entry.key),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAccountsSection() {
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
        ],
      ),
    );
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
                'My Accounts',
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
                'My Expenses',
                Icons.receipt_long,
                Colors.orange,
                () => context.go('/dashboard/salesman/expense/my'),
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

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'lead':
        return const Color(0xFF2196F3);
      case 'prospect':
        return const Color(0xFFFF9800);
      case 'customer':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }
}
