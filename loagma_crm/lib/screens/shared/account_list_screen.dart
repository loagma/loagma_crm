import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/user_service.dart';
import 'edit_account_master_screen.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;
  String? _filterCustomerStage;
  bool? _filterIsApproved;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Determines whether we should pass createdBy filter (non-admin)
  bool get _shouldFilterByOwner {
    final role = UserService.currentRole?.toLowerCase();
    return role != null && role != 'admin';
  }

  String? get _currentUserId => UserService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAccounts(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_currentPage < _totalPages && !_isLoadingMore) {
        _loadMoreAccounts();
      }
    }
  }

  Future<void> _loadAccounts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      final result = await AccountService.fetchAccounts(
        page: _currentPage,
        limit: 20,
        search: _searchQuery,
        customerStage: _filterCustomerStage,
        isApproved: _filterIsApproved,
        // apply owner filter for non-admin roles
        createdById: _shouldFilterByOwner ? _currentUserId : null,
      );

      // result expected: { 'accounts': List<Account>, 'pagination': {'totalPages': n} }
      final fetched = List<Account>.from(result['accounts'] ?? []);
      final pagination = result['pagination'] ?? {'totalPages': 1};

      setState(() {
        if (refresh) {
          _accounts = fetched;
        } else {
          _accounts.addAll(fetched);
        }
        _totalPages = (pagination['totalPages'] as int?) ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load accounts: $e');
    }
  }

  Future<void> _loadMoreAccounts() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadAccounts();
  }

  Future<void> _refreshAccounts() async {
    await _loadAccounts(refresh: true);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${account.personName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AccountService.deleteAccount(account.id);
        _showSuccess('Account deleted successfully');
        // refresh first page
        await _refreshAccounts();
      } catch (e) {
        _showError('Failed to delete account: $e');
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tmpStage = _filterCustomerStage;
        bool? tmpApproved = _filterIsApproved;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Accounts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: tmpStage,
                    decoration: const InputDecoration(
                      labelText: 'Customer Stage',
                    ),
                    items: ['Lead', 'Prospect', 'Customer']
                        .map(
                          (stage) => DropdownMenuItem(
                            value: stage,
                            child: Text(stage),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => tmpStage = value),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<bool>(
                    initialValue: tmpApproved,
                    decoration: const InputDecoration(
                      labelText: 'Approval Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Approved')),
                      DropdownMenuItem(value: false, child: Text('Pending')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => tmpApproved = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = null;
                      _filterIsApproved = null;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = tmpStage;
                      _filterIsApproved = tmpApproved;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Navigate to create screen
  Future<void> _navigateToCreate() async {
    // expecting a route /account/create to exist
    await context.push('/account/create');
    // after returning, refresh list
    await _refreshAccounts();
  }

  // Navigate to detail screen
  Future<void> _navigateToDetail(String accountId) async {
    context.push(
      "/dashboard/${UserService.currentRole!.toLowerCase()}/account/view/$accountId",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAccounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or phone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD7BE69)),
                suffixIcon: (_searchQuery != null && _searchQuery!.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                          _refreshAccounts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7BE69),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value.isEmpty ? null : value);
                _refreshAccounts();
              },
            ),
          ),

          // Accounts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshAccounts,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(15),
                      itemCount: _accounts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _accounts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildAccountCard(_accounts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push("/dashboard/admin/account/master");
        },
        backgroundColor: const Color(0xFFD7BE69),
        tooltip: "Create New Account",
        child: const Icon(Icons.add),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_box_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Accounts Found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first account to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(account.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7BE69).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFD7BE69),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.personName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          account.accountCode,
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
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: account.isApproved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          account.isApproved
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: account.isApproved
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          account.isApproved ? 'Approved' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: account.isApproved
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone, account.contactNumber),
              if (account.businessType != null)
                _buildInfoRow(Icons.business, account.businessType!),
              if (account.customerStage != null)
                _buildInfoRow(Icons.stairs, account.customerStage!),
              if (account.createdBy != null)
                _buildInfoRow(
                  Icons.person_add,
                  'Created by: ${account.createdByName ?? account.createdBy}',
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditAccountMasterScreen(account: account),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadAccounts(
                            refresh: true,
                          ); // Refresh list after edit
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _deleteAccount(account),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
