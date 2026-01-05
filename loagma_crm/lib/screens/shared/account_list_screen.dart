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
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterSalesmanId;
  List<Map<String, dynamic>> _salesmen = [];

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
    _loadSalesmen();
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
      print('🔍 Loading accounts with filters:');
      print('   Customer Stage: $_filterCustomerStage');
      print('   Is Approved: $_filterIsApproved');
      print('   Salesman ID: $_filterSalesmanId');
      print('   Start Date: $_filterStartDate');
      print('   End Date: $_filterEndDate');
      print('   Should Filter By Owner: $_shouldFilterByOwner');
      print('   Current User ID: $_currentUserId');

      final result = await AccountService.fetchAccounts(
        page: _currentPage,
        limit: 20,
        search: _searchQuery,
        customerStage: _filterCustomerStage,
        isApproved: _filterIsApproved,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        // For non-admin users, if no salesman filter is selected, show only their accounts
        // For admin users, show all accounts unless a specific salesman is selected
        createdById:
            _filterSalesmanId ?? (_shouldFilterByOwner ? _currentUserId : null),
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

  Future<void> _loadSalesmen() async {
    try {
      final result = await UserService.getAllUsers();
      if (result['success'] == true) {
        setState(() {
          _salesmen = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      }
    } catch (e) {
      // Silently handle error - salesmen dropdown will just be empty
      print('Error loading salesmen: $e');
    }
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
        DateTime? tmpStartDate = _filterStartDate;
        DateTime? tmpEndDate = _filterEndDate;
        String? tmpSalesmanId = _filterSalesmanId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFFD7BE69)),
                  SizedBox(width: 8),
                  Text('Filter Accounts'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: tmpStage,
                        decoration: const InputDecoration(
                          labelText: 'Customer Stage',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Stages'),
                          ),
                          ...['Lead', 'Prospect', 'Customer'].map(
                            (stage) => DropdownMenuItem(
                              value: stage,
                              child: Text(stage),
                            ),
                          ),
                        ],
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
                          DropdownMenuItem<bool>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Approved'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Pending'),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => tmpApproved = value),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: tmpSalesmanId,
                        decoration: const InputDecoration(
                          labelText: 'Salesman',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Salesmen'),
                          ),
                          ..._salesmen.map(
                            (salesman) => DropdownMenuItem<String>(
                              value: salesman['id'] ?? salesman['_id'],
                              child: Text(salesman['name'] ?? 'Unknown'),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => tmpSalesmanId = value),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: tmpStartDate != null
                                    ? '${tmpStartDate!.day}/${tmpStartDate!.month}/${tmpStartDate!.year}'
                                    : '',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: tmpStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() => tmpStartDate = date);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: tmpEndDate != null
                                    ? '${tmpEndDate!.day}/${tmpEndDate!.month}/${tmpEndDate!.year}'
                                    : '',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: tmpEndDate ?? DateTime.now(),
                                  firstDate: tmpStartDate ?? DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() => tmpEndDate = date);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = null;
                      _filterIsApproved = null;
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterSalesmanId = null;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = tmpStage;
                      _filterIsApproved = tmpApproved;
                      _filterStartDate = tmpStartDate;
                      _filterEndDate = tmpEndDate;
                      _filterSalesmanId = tmpSalesmanId;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _filterCustomerStage != null ||
        _filterIsApproved != null ||
        _filterStartDate != null ||
        _filterEndDate != null ||
        _filterSalesmanId != null;
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];

    if (_filterCustomerStage != null) {
      activeFilters.add(_filterCustomerStage!);
    }
    if (_filterIsApproved != null) {
      activeFilters.add(_filterIsApproved! ? 'Approved' : 'Pending');
    }
    if (_filterSalesmanId != null) {
      final salesman = _salesmen.firstWhere(
        (s) => (s['id'] ?? s['_id']) == _filterSalesmanId,
        orElse: () => {'name': 'Unknown Salesman'},
      );
      activeFilters.add('By: ${salesman['name'] ?? 'Unknown'}');
    }
    if (_filterStartDate != null || _filterEndDate != null) {
      String dateRange = 'Date: ';
      if (_filterStartDate != null && _filterEndDate != null) {
        dateRange +=
            '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}';
      } else if (_filterStartDate != null) {
        dateRange +=
            'From ${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year}';
      } else if (_filterEndDate != null) {
        dateRange +=
            'Until ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}';
      }
      activeFilters.add(dateRange);
    }

    return activeFilters.join(', ');
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
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

          // Active filters indicator
          if (_hasActiveFilters())
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFD7BE69).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFD7BE69).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Color(0xFFD7BE69)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters active: ${_getActiveFiltersText()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD7BE69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterCustomerStage = null;
                        _filterIsApproved = null;
                        _filterStartDate = null;
                        _filterEndDate = null;
                        _filterSalesmanId = null;
                      });
                      _refreshAccounts();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD7BE69),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
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
                      color: const Color(0xFFD7BE69).withValues(alpha: 0.1),
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
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
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
              if (account.createdByName != 'Unknown')
                _buildInfoRow(
                  Icons.person_add,
                  'Created by: ${account.createdByName}',
                ),
              _buildInfoRow(
                Icons.calendar_today,
                'Created: ${account.createdAt.day}/${account.createdAt.month}/${account.createdAt.year}',
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
