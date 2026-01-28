import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/user_service.dart';
import '../../utils/custom_toast.dart';

enum _StatusFilter { all, pending, verified }

class VerifyAccountMasterScreen extends StatefulWidget {
  const VerifyAccountMasterScreen({super.key});

  @override
  State<VerifyAccountMasterScreen> createState() =>
      _VerifyAccountMasterScreenState();
}
class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final bool isActive;
  final Map<T?, String> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.isActive,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFD7BE69);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? activeColor : Colors.grey.shade300,
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isActive ? activeColor : Colors.grey.shade600,
          ),
          items: items.entries.map((e) {
            return DropdownMenuItem<T>(
              value: e.key,
              child: Text(
                e.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _VerifyAccountMasterScreenState extends State<VerifyAccountMasterScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _searchQuery;
  _StatusFilter _statusFilter = _StatusFilter.pending;
  String? _salesmanId;
  String? _telecallerId;
  List<Map<String, dynamic>> _users = [];
  bool _usersLoading = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  bool get _isAdmin =>
      UserService.currentRole?.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchControllerChanged);
    _loadUsers();
    _loadAccounts();
  }

  void _onSearchControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim().isEmpty ? null : value.trim();
        _loadAccounts();
      });
    });
  }

  void _onScroll() {
    // Optional: pagination / load more
  }

  Future<void> _loadUsers() async {
    if (_usersLoading) return;
    setState(() => _usersLoading = true);
    try {
      final result = await UserService.getAllUsers();
      if (mounted && result['success'] == true) {
        final data = result['data'] as List<dynamic>?;
        final allUsers = (data ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        
        // Filter to get salesmen (users with salesman role)
        // Check roleId or role field
        final salesmen = allUsers.where((user) {
          final role = user['role']?.toString().toLowerCase() ?? 
                      user['roleId']?.toString().toLowerCase() ?? '';
          return role.contains('salesman') || role.contains('sales');
        }).toList();
        
        print('👥 Loaded ${allUsers.length} total users, ${salesmen.length} salesmen');
        
        setState(() {
          _users = salesmen.isNotEmpty ? salesmen : allUsers; // Fallback to all users if no salesmen found
          _usersLoading = false;
        });
      } else {
        setState(() => _usersLoading = false);
      }
    } catch (e) {
      print('❌ Error loading users: $e');
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      bool? isApproved;
      switch (_statusFilter) {
        case _StatusFilter.pending:
          isApproved = false;
          break;
        case _StatusFilter.verified:
          isApproved = true;
          break;
        case _StatusFilter.all:
          isApproved = null; // Show all regardless of approval status
          break;
      }
      
      // Debug logging
      print('🔍 Loading accounts with filters:');
      print('   Status filter: $_statusFilter (isApproved: $isApproved)');
      print('   Salesman ID: $_salesmanId');
      print('   Telecaller ID: $_telecallerId');
      print('   Search query: $_searchQuery');
      
      // Note: Accounts are linked to salesmen via createdById (who created them)
      // assignedToId is for assignment/allotment, createdById is for ownership
      final result = await AccountService.fetchAccounts(
        isApproved: isApproved,
        search: _searchQuery,
        salesmanId: _salesmanId, // Uses createdById internally (accounts created by this salesman)
        approvedById: _telecallerId,
        limit: 1000, // Increased limit to show more accounts
      );
      
      if (mounted) {
        final accounts = List<Account>.from(result['accounts'] ?? []);
        print('✅ Loaded ${accounts.length} accounts');
        
        setState(() {
          _accounts = accounts;
          _isLoading = false;
        });
        
        // Show feedback if filters are active but no results
        if (accounts.isEmpty && (_salesmanId != null || _statusFilter != _StatusFilter.all || _searchQuery != null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No accounts found matching the selected filters'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading accounts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load accounts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _launchDialer(String phoneNumber) async {
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.length == 10 && !clean.startsWith('+')) clean = '+91$clean';
    if (clean.startsWith('91') && clean.length == 12) clean = '+$clean';
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This device cannot open the phone dialer.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening dialer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmAndCall(String phoneNumber) async {
    if (!mounted) return;
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Confirm Call',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Do you want to call $phoneNumber?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldCall == true && mounted) {
      await _launchDialer(phoneNumber);
    }
  }

  Future<void> _showVerifyDialog(Account account) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Verify Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add notes for this verification (optional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Verification notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.businessName ?? account.personName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.contactNumber,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    final notes = notesController.text.trim();
    notesController.dispose();
    if (confirmed == true) {
      await _verifyAccount(account, notes);
    }
  }

  Future<void> _verifyAccount(Account account, String notes) async {
    try {
      await AccountService.verifyAccount(account.id, notes: notes.isEmpty ? null : notes);
      if (mounted) {
        CustomToast.showSuccess(context, 'Account verified successfully');
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  

  Future<void> _showRejectDialog(Account account) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Reject Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add rejection notes (optional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Rejection notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.businessName ?? account.personName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.contactNumber,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    final notes = notesController.text.trim();
    notesController.dispose();
    if (confirmed == true) {
      await _rejectAccount(account, notes);
    }
  }

  Future<void> _rejectAccount(Account account, String notes) async {
    try {
      await AccountService.rejectAccount(account.id, notes: notes.isEmpty ? null : notes);
      if (mounted) {
        CustomToast.showSuccess(context, 'Account rejected');
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 8,
            color: const Color(0xFFD7BE69),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchAndFilters(isNarrow),
                  if (!_isLoading && _accounts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '${_accounts.length} account${_accounts.length == 1 ? '' : 's'} found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_salesmanId != null || _statusFilter != _StatusFilter.all || _searchQuery != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _salesmanId = null;
                                  _telecallerId = null;
                                  _statusFilter = _StatusFilter.all;
                                  _searchQuery = null;
                                  _searchController.clear();
                                  _loadAccounts();
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear Filters', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFD7BE69),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                          )
                        : _accounts.isEmpty
                            ? _buildEmptyState()
                            : _buildAccountList(isNarrow),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 16 : 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, business...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = null;
                              _loadAccounts();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: _FilterDropdown<_StatusFilter>(
                    label: 'Status',
                    value: _statusFilter,
                    isActive: _statusFilter != _StatusFilter.all,
                    items: const {
                      _StatusFilter.all: 'All',
                      _StatusFilter.pending: 'Pending',
                      _StatusFilter.verified: 'Verified',
                    },
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _statusFilter = val;
                          _loadAccounts();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _FilterDropdown<String>(
                    label: 'Salesman',
                    value: _salesmanId,
                    isActive: _salesmanId != null,
                    items: {
                      null: 'All Salesmen',
                      for (final u in _users)
                        u['id'] as String?: (u['name'] as String? ?? 'Unknown'),
                    },
                    onChanged: (val) {
                      setState(() {
                        _salesmanId = val;
                        _loadAccounts();
                      });
                    },
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _FilterDropdown<String>(
                      label: 'Verified by',
                      value: _telecallerId,
                      isActive: _telecallerId != null,
                      items: {
                        null: 'All',
                        for (final u in _users)
                          u['id'] as String?: (u['name'] as String? ?? 'Unknown'),
                      },
                      onChanged: (val) {
                        setState(() {
                          _telecallerId = val;
                          _loadAccounts();
                        });
                      },
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7BE69).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, size: 22, color: const Color(0xFFD7BE69)),
                    onPressed: _isLoading ? null : _loadAccounts,
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (old DropdownButtonFormField-based filter widgets removed in favor of `_FilterDropdown`)

  Widget _buildEmptyState() {
    final hasActiveFilters = _salesmanId != null || 
                            _statusFilter != _StatusFilter.all || 
                            _searchQuery != null ||
                            (_isAdmin && _telecallerId != null);
    
    String getStatusMessage() {
      if (_salesmanId != null) {
        final salesmanName = _users.firstWhere(
          (u) => u['id'] == _salesmanId,
          orElse: () => {'name': 'Selected'},
        )['name'] as String?;
        
        if (_statusFilter == _StatusFilter.pending) {
          return 'No pending accounts for $salesmanName';
        } else if (_statusFilter == _StatusFilter.verified) {
          return 'No verified accounts for $salesmanName';
        } else {
          return 'No accounts found for $salesmanName';
        }
      }
      
      if (_statusFilter == _StatusFilter.verified) {
        return 'No verified accounts';
      } else if (_statusFilter == _StatusFilter.pending) {
        return 'No accounts pending verification';
      }
      
      return 'No accounts found';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveFilters ? Icons.filter_alt_outlined : Icons.verified_user_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getStatusMessage(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (hasActiveFilters) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (_statusFilter != _StatusFilter.all)
                    Chip(
                      label: Text('Status: ${_statusFilter == _StatusFilter.pending ? 'Pending' : 'Verified'}'),
                      backgroundColor: const Color(0xFFD7BE69).withOpacity(0.2),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _statusFilter = _StatusFilter.all;
                          _loadAccounts();
                        });
                      },
                    ),
                  if (_salesmanId != null)
                    Chip(
                      label: Text('Salesman: ${_users.firstWhere((u) => u['id'] == _salesmanId, orElse: () => {'name': 'Selected'})['name']}'),
                      backgroundColor: const Color(0xFFD7BE69).withOpacity(0.2),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _salesmanId = null;
                          _loadAccounts();
                        });
                      },
                    ),
                  if (_searchQuery != null)
                    Chip(
                      label: Text('Search: $_searchQuery'),
                      backgroundColor: const Color(0xFFD7BE69).withOpacity(0.2),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = null;
                          _loadAccounts();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(
              hasActiveFilters
                  ? 'Try clearing filters or adjusting your search'
                  : 'Try adjusting your filters or search query',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(bool isNarrow) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 20,
        vertical: 20,
      ),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _AccountCard(
          account: account,
          isNarrow: isNarrow,
          onCall: _confirmAndCall,
          onViewDetails: () {
            context.push('/account/${account.id}').then((_) {
              if (context.mounted) _loadAccounts();
            });
          },
          onVerify: account.isApproved ? null : () => _showVerifyDialog(account),
          onReject: account.isApproved ? null : () => _showRejectDialog(account),
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isNarrow;
  final void Function(String) onCall;
  final VoidCallback onViewDetails;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  const _AccountCard({
    required this.account,
    required this.isNarrow,
    required this.onCall,
    required this.onViewDetails,
    this.onVerify,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = account.businessName ?? account.personName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final statusText = account.isApproved ? 'Verified' : 'Pending';
    final statusColor = account.isApproved ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= HEADER =================
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD7BE69),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.personName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.shade200),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            /// ================= BODY =================
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  account.contactNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (account.businessType != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business, size: 18, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    account.businessType!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            /// ================= FOOTER =================
     /// ================= FOOTER =================
Row(
  children: [
    /// View button (Primary)
    Expanded(
      child: OutlinedButton.icon(
        onPressed: onViewDetails,
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('View Details'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    ),

    const SizedBox(width: 8),

    /// Verify
    if (onVerify != null)
      IconButton(
        tooltip: 'Verify',
        onPressed: onVerify,
        icon: const Icon(Icons.check_circle_outline),
        color: Colors.green.shade700,
        style: IconButton.styleFrom(
          backgroundColor: Colors.green.shade50,
        ),
      ),

    /// Reject
    if (onReject != null)
      IconButton(
        tooltip: 'Reject',
        onPressed: onReject,
        icon: const Icon(Icons.close),
        color: Colors.red.shade700,
        style: IconButton.styleFrom(
          backgroundColor: Colors.red.shade50,
        ),
      ),

    /// Call
    IconButton(
      tooltip: 'Call',
      onPressed: () => onCall(account.contactNumber),
      icon: const Icon(Icons.call),
      color: Colors.green.shade700,
      style: IconButton.styleFrom(
        backgroundColor: Colors.green.shade50,
      ),
    ),
  ],
),

          ],
        ),
      ),
    );
  }
}
