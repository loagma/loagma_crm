import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import 'edit_account_master_screen.dart';

class ViewAllMastersScreen extends StatefulWidget {
  final String? initialAccountCode;

  const ViewAllMastersScreen({super.key, this.initialAccountCode});

  @override
  State<ViewAllMastersScreen> createState() => _ViewAllMastersScreenState();
}

class _ViewAllMastersScreenState extends State<ViewAllMastersScreen> {
  List<Account> accounts = [];
  bool isLoading = false;
  String searchQuery = '';
  String? filterCustomerStage;
  int currentPage = 1;
  final int itemsPerPage = 20;
  final TextEditingController _searchController = TextEditingController();

  final List<String> customerStages = ['All', 'Lead', 'Prospect', 'Customer'];

  @override
  void initState() {
    super.initState();
    // If initialAccountCode is provided, set it as search query
    if (widget.initialAccountCode != null) {
      searchQuery = widget.initialAccountCode!;
      _searchController.text = widget.initialAccountCode!;
    }
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAccounts(showLoading: false);
      }
    });
  }

  Future<void> _loadAccounts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => isLoading = true);
    }
    try {
      print('🔄 Fetching accounts from API...');
      final data = await AccountService.fetchAccounts(
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        customerStage: filterCustomerStage != 'All'
            ? filterCustomerStage
            : null,
      );
      print('✅ Fetched ${(data['accounts'] as List).length} accounts');
      setState(() {
        accounts = data['accounts'] as List<Account>;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading accounts: $e');
      setState(() => isLoading = false);
      _showError('Failed to load accounts: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteAccount(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete account "$name"?'),
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

    if (confirmed == true) {
      try {
        print('🗑️ Deleting account: $id');
        await AccountService.deleteAccount(id);
        _showSuccess('Account deleted successfully');
        await _loadAccounts(showLoading: false);
      } catch (e) {
        print('❌ Error deleting account: $e');
        _showError('Failed to delete account: $e');
      }
    }
  }

  Future<void> _editAccount(Account account) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountMasterScreen(account: account),
      ),
    );

    // If edit was successful, refresh the list
    if (result == true) {
      print('✅ Account edited successfully, refreshing list...');
      await _loadAccounts(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Account Masters'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAccounts),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, code, or contact...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFD7BE69),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                              _loadAccounts();
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
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                    _loadAccounts();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Dropdown
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFFD7BE69)),
                    const SizedBox(width: 8),
                    const Text('Filter by Stage:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: filterCustomerStage ?? 'All',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: customerStages.map((stage) {
                          return DropdownMenuItem(
                            value: stage,
                            child: Text(stage),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            filterCustomerStage = value;
                          });
                          _loadAccounts();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Accounts List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first account from the Master menu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAccounts,
                    child: ListView.builder(
                      itemCount: accounts.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final isHighlighted =
                            widget.initialAccountCode != null &&
                            account.accountCode == widget.initialAccountCode;
                        return Card(
                          elevation: isHighlighted ? 8 : 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: isHighlighted ? Colors.yellow[100] : null,
                          shape: isHighlighted
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color(0xFFD7BE69),
                                    width: 3,
                                  ),
                                )
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isHighlighted
                                  ? Colors.orange
                                  : const Color(0xFFD7BE69),
                              backgroundImage:
                                  account.ownerImage != null &&
                                      account.ownerImage!.startsWith('http')
                                  ? NetworkImage(account.ownerImage!)
                                  : null,
                              child:
                                  account.ownerImage == null ||
                                      !account.ownerImage!.startsWith('http')
                                  ? Text(
                                      account.personName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    account.personName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isHighlighted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'FOUND',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Code: ${account.accountCode}'),
                                Text('Contact: ${account.contactNumber}'),
                                if (account.customerStage != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStageColor(
                                        account.customerStage!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      account.customerStage!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 20),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showAccountDetails(account);
                                } else if (value == 'edit') {
                                  _editAccount(account);
                                } else if (value == 'delete') {
                                  _deleteAccount(
                                    account.id,
                                    account.personName,
                                  );
                                }
                              },
                            ),
                            onTap: () => _showAccountDetails(account),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Summary Footer
          if (accounts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD7BE69).withOpacity(0.1),
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Accounts: ${accounts.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Page $currentPage',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'lead':
        return Colors.blue;
      case 'prospect':
        return Colors.orange;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _navigateToDetail(String accountId) async {
    await context.push('/account/$accountId');
    // After returning, refresh list
    await _loadAccounts(showLoading: false);
  }

  void _showAccountDetails(Account account) {
    // Navigate to detail screen using go_router
    _navigateToDetail(account.id);
  }
}
