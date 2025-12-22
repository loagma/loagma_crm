import 'package:flutter/material.dart';
import '../../services/account_service.dart';
import '../../models/account_model.dart';
import '../../utils/custom_toast.dart';
import '../shared/account_detail_screen.dart';

class VerifyAccountMasterScreen extends StatefulWidget {
  const VerifyAccountMasterScreen({super.key});

  @override
  State<VerifyAccountMasterScreen> createState() =>
      _VerifyAccountMasterScreenState();
}

class _VerifyAccountMasterScreenState extends State<VerifyAccountMasterScreen> {
  List<Account> _pendingAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAccounts();
  }

  Future<void> _loadPendingAccounts() async {
    try {
      setState(() => _isLoading = true);
      final result = await AccountService.fetchAccounts(
        isApproved: false, // Get only non-approved accounts
        limit: 100,
      );
      setState(() {
        _pendingAccounts = result['accounts'] as List<Account>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pending accounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveAccount(Account account) async {
    try {
      await AccountService.approveAccount(account.id);
      CustomToast.showSuccess(context, 'Account approved successfully');
      _loadPendingAccounts(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAccount(Account account) async {
    try {
      await AccountService.rejectAccount(account.id);
      CustomToast.showSuccess(context, 'Account rejected');
      _loadPendingAccounts(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7BE69), Color(0xFFF5F5F5)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingAccounts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No accounts pending verification',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingAccounts.length,
                itemBuilder: (context, index) {
                  final account = _pendingAccounts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFD7BE69),
                                child: Text(
                                  (account.businessName?.isNotEmpty == true
                                          ? account.businessName![0]
                                          : account.personName[0])
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.businessName ??
                                          account.personName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      account.personName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                account.contactNumber,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              if (account.businessType != null) ...[
                                Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    account.businessType!,
                                    style: TextStyle(color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AccountDetailScreen(
                                              accountId: account.id,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveAccount(account),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _rejectAccount(account),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
