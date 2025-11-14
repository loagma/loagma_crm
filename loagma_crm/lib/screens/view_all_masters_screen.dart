import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/account_service.dart';

class ViewAllMastersScreen extends StatefulWidget {
  const ViewAllMastersScreen({super.key});

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

  final List<String> customerStages = ['All', 'Lead', 'Prospect', 'Customer'];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => isLoading = true);
    try {
      final data = await AccountService.fetchAccounts(
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        customerStage: filterCustomerStage != 'All' ? filterCustomerStage : null,
      );
      setState(() {
        accounts = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load accounts: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AccountService.deleteAccount(id);
        _showSuccess('Account deleted successfully');
        _loadAccounts();
      } catch (e) {
        _showError('Failed to delete account: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Account Masters'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
          ),
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
                  decoration: InputDecoration(
                    hintText: 'Search by name, code, or contact...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFD7BE69)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
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
                        value: filterCustomerStage ?? 'All',
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
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[300],
                            ),
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
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFD7BE69),
                                  child: Text(
                                    account.personName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  account.personName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                          color: _getStageColor(account.customerStage!),
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
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      _showAccountDetails(account);
                                    } else if (value == 'edit') {
                                      _showError('Edit functionality coming soon!');
                                    } else if (value == 'delete') {
                                      _deleteAccount(account.id, account.personName);
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
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
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
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
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

  void _showAccountDetails(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_circle, color: Color(0xFFD7BE69)),
            const SizedBox(width: 8),
            const Text('Account Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Account Code', account.accountCode),
              _buildDetailRow('Person Name', account.personName),
              _buildDetailRow('Contact Number', account.contactNumber),
              if (account.dateOfBirth != null)
                _buildDetailRow(
                  'Date of Birth',
                  '${account.dateOfBirth!.day}/${account.dateOfBirth!.month}/${account.dateOfBirth!.year}',
                ),
              if (account.businessType != null)
                _buildDetailRow('Business Type', account.businessType!),
              if (account.customerStage != null)
                _buildDetailRow('Customer Stage', account.customerStage!),
              if (account.funnelStage != null)
                _buildDetailRow('Funnel Stage', account.funnelStage!),
              _buildDetailRow(
                'Created At',
                '${account.createdAt.day}/${account.createdAt.month}/${account.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFD7BE69),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
