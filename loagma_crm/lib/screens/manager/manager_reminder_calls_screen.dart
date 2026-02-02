import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';

/// Manager screen: Reminder Calls - accounts in Follow-up stage with prominent call buttons
class ManagerReminderCallsScreen extends StatefulWidget {
  const ManagerReminderCallsScreen({super.key});

  @override
  State<ManagerReminderCallsScreen> createState() =>
      _ManagerReminderCallsScreenState();
}

class _ManagerReminderCallsScreenState extends State<ManagerReminderCallsScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _searchQuery;
  static const Color _primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _loadReminderAccounts();
  }

  Future<void> _loadReminderAccounts() async {
    setState(() => _isLoading = true);
    try {
      final result = await AccountService.fetchAccounts(
        funnelStage: 'Follow-up',
        limit: 100,
        page: 1,
        search: _searchQuery?.trim().isEmpty == true ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _accounts = List<Account>.from(result['accounts'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load reminder accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchCall(String phoneNumber) async {
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.length == 10 && !clean.startsWith('+')) clean = '+91$clean';
    if (clean.startsWith('91') && clean.length == 12) clean = '+$clean';
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAccountDetail(String accountId) {
    context.push('/account/$accountId').then((_) {
      if (mounted) _loadReminderAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.phone_callback_outlined, size: 26),
            SizedBox(width: 12),
            Text(
              'Reminder Calls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReminderAccounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _accounts.isEmpty
                    ? _buildEmptyState()
                    : _buildAccountList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _loadReminderAccounts();
        },
        decoration: InputDecoration(
          hintText: 'Search by name, business, contact...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_in_talk_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reminder calls pending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accounts in Follow-up stage will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final a = _accounts[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _openAccountDetail(a.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryColor.withValues(alpha: 0.3),
                    child: Icon(Icons.person, color: _primaryColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.personName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (a.businessName != null && a.businessName!.isNotEmpty)
                          Text(
                            a.businessName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          a.contactNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _launchCall(a.contactNumber),
                    icon: const Icon(Icons.call, size: 20),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
