import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../shared/account_detail_screen.dart';
import '../shared/account_master_screen.dart';

class SalesmanAccountsScreen extends StatefulWidget {
  const SalesmanAccountsScreen({super.key});

  @override
  State<SalesmanAccountsScreen> createState() => _SalesmanAccountsScreenState();
}

class _SalesmanAccountsScreenState extends State<SalesmanAccountsScreen> {
  List<Map<String, dynamic>> accounts = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedStage;

  @override
  void initState() {
    super.initState();
    fetchMyAccounts();
  }

  Future<void> fetchMyAccounts() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;

      print('🔍 Fetching accounts for user: $userId');

      if (userId == null || userId.isEmpty) {
        print('❌ User ID is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId',
      );

      print('📡 Fetching from: $url');

      final response = await http.get(url);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final accountsList = List<Map<String, dynamic>>.from(
          data['data'] ?? [],
        );
        print('✅ Fetched ${accountsList.length} accounts');

        setState(() {
          accounts = accountsList;
        });
      } else {
        print('❌ API returned success: false');
        print('   Message: ${data['message']}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching accounts: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading accounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAccounts {
    return accounts.where((account) {
      final matchesSearch =
          searchQuery.isEmpty ||
          account['personName']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ==
              true ||
          account['businessName']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ==
              true ||
          account['contactNumber']?.toString().contains(searchQuery) == true;

      final matchesStage =
          selectedStage == null || account['customerStage'] == selectedStage;

      return matchesSearch && matchesStage;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMyAccounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search accounts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedStage == null,
                        onSelected: (selected) {
                          setState(() => selectedStage = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Lead'),
                        selected: selectedStage == 'Lead',
                        onSelected: (selected) {
                          setState(
                            () => selectedStage = selected ? 'Lead' : null,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Prospect'),
                        selected: selectedStage == 'Prospect',
                        onSelected: (selected) {
                          setState(
                            () => selectedStage = selected ? 'Prospect' : null,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Customer'),
                        selected: selectedStage == 'Customer',
                        onSelected: (selected) {
                          setState(
                            () => selectedStage = selected ? 'Customer' : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFD7BE69).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', accounts.length.toString()),
                _buildStatItem(
                  'Approved',
                  accounts
                      .where((a) => a['isApproved'] == true)
                      .length
                      .toString(),
                ),
                _buildStatItem(
                  'Pending',
                  accounts
                      .where((a) => a['isApproved'] == false)
                      .length
                      .toString(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Accounts List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No accounts created yet'
                              : 'No accounts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchMyAccounts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final account = filtered[index];
                        return _buildAccountCard(account);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
          if (result == true) {
            fetchMyAccounts();
          }
        },
        backgroundColor: const Color(0xFFD7BE69),
        icon: const Icon(Icons.add),
        label: const Text('Create Account'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD7BE69),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final isApproved = account['isApproved'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AccountDetailScreen(accountId: account['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account['personName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (account['businessName'] != null)
                          Text(
                            account['businessName'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                      color: isApproved ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved ? 'Approved' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    account['contactNumber'] ?? 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    account['accountCode'] ?? 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (account['customerStage'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      account['customerStage'],
                      style: TextStyle(
                        color: const Color(0xFFD7BE69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
