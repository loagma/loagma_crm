import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/map_task_assignment_service.dart';
import '../../services/user_service.dart';

/// Salesman screen: customers allotted by admin (day-wise).
/// Shows accounts where assignedToId = current user; day chip filters by assignedDays (1=Mon .. 7=Sun).
class SalesmanCustomerAllotmentScreen extends StatefulWidget {
  const SalesmanCustomerAllotmentScreen({super.key});

  @override
  State<SalesmanCustomerAllotmentScreen> createState() =>
      _SalesmanCustomerAllotmentScreenState();
}

class _SalesmanCustomerAllotmentScreenState
    extends State<SalesmanCustomerAllotmentScreen> {
  final _taskAssignmentService = MapTaskAssignmentService();
  List<Account> _allAccounts = [];
  final Set<String> _assignedPincodes = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _searchQuery;
  final Set<int> _selectedDaysForAssignment = {};
  final Set<String> _selectedAccountIds = {};
  final Set<String> _expandedPincodes = {};
  final TextEditingController _searchController = TextEditingController();
  Map<String, List<Account>> _accountsByPincode = {};
  static const Map<int, String> _dayLabelMap = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  String? get _currentUserId => UserService.currentUserId;
  static const Color _primary = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AccountService.fetchAccounts(
        assignedToId: userId,
        // Load all allotted customers; we will filter day & search client‑side
        assignedDay: null,
        search: null,
        limit: 500,
      );

      final assignmentResult =
          await _taskAssignmentService.getAssignmentsBySalesman(userId);
      final assignmentRows =
          (assignmentResult['assignments'] as List?) ?? const [];
      final assignedPins = assignmentRows
          .map((e) => (e as Map)['pincode']?.toString().trim() ?? '')
          .where((pin) => pin.isNotEmpty)
          .toSet();

      if (!mounted) return;
      final accounts = List<Account>.from(result['accounts'] ?? []);
      setState(() {
        _assignedPincodes
          ..clear()
          ..addAll(assignedPins);
        _allAccounts = accounts;
        _regroupAccounts();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load allotted customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _regroupAccounts() {
    final query = _searchQuery?.trim().toLowerCase();
    final grouped = <String, List<Account>>{};
    for (final acc in _allAccounts) {
      if (query != null && query.isNotEmpty) {
        final haystack = [
          acc.personName,
          acc.businessName ?? '',
          acc.accountCode,
          acc.contactNumber,
          acc.pincode ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) continue;
      }
      final pin = (acc.pincode == null || acc.pincode!.trim().isEmpty)
          ? 'No Pincode'
          : acc.pincode!.trim();
      grouped.putIfAbsent(pin, () => []).add(acc);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    for (final pin in _assignedPincodes) {
      grouped.putIfAbsent(pin, () => []);
    }
    final allKeys = grouped.keys.toList()..sort();
    _accountsByPincode = {
      for (final key in allKeys)
        key: grouped[key]!..sort((a, b) =>
            (a.businessName ?? a.personName).compareTo(b.businessName ?? b.personName)),
    };

    if (mounted) {
      setState(() {});
    }
  }

  int get _totalVisibleAccounts {
    return _accountsByPincode.values.fold<int>(0, (sum, v) => sum + v.length);
  }

  Future<void> _saveSelectedAssignments() async {
    final userId = _currentUserId;
    if (userId == null) return;

    if (_selectedAccountIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDaysForAssignment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AccountService.bulkAssignAccounts(
        accountIds: _selectedAccountIds.toList(),
        assignedToId: userId,
        assignedDays: _selectedDaysForAssignment.toList()..sort(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assigned ${_selectedAccountIds.length} account(s) to ${_selectedDaysForAssignment.length} day(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _selectedAccountIds.clear();
      await _loadAccounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assignments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          SnackBar(content: Text('Could not open dialer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openAccountDetail(String accountId) {
    context.push('/account/$accountId').then((_) {
      if (mounted) _loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer list allotment'),
        backgroundColor: _primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAccounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 6, color: _primary),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pincode-wise allotted customers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, phone, code...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (v) {
                            _searchQuery = v.trim().isEmpty ? null : v.trim();
                            _regroupAccounts();
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select days to assign',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _dayLabelMap.entries.map((entry) {
                              final day = entry.key;
                              final isSelected =
                                  _selectedDaysForAssignment.contains(day);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(entry.value),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDaysForAssignment.add(day);
                                      } else {
                                        _selectedDaysForAssignment.remove(day);
                                      }
                                    });
                                  },
                                  selectedColor: _primary.withValues(alpha: 0.3),
                                  checkmarkColor: _primary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _totalVisibleAccounts > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '${_accountsByPincode.length} pincode(s) • $_totalVisibleAccounts account(s)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _primary),
                          )
                        : _accountsByPincode.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: _loadAccounts,
                                color: _primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: _accountsByPincode.length,
                                  itemBuilder: (context, index) {
                                    final pincode =
                                        _accountsByPincode.keys.elementAt(index);
                                    final accounts = _accountsByPincode[pincode] ?? [];
                                    final selectedInPin = accounts
                                        .where((a) => _selectedAccountIds.contains(a.id))
                                        .length;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ExpansionTile(
                                        key: PageStorageKey<String>('sales-pin-$pincode'),
                                        initiallyExpanded:
                                            _expandedPincodes.contains(pincode),
                                        onExpansionChanged: (expanded) {
                                          setState(() {
                                            if (expanded) {
                                              _expandedPincodes.add(pincode);
                                            } else {
                                              _expandedPincodes.remove(pincode);
                                            }
                                          });
                                        },
                                        title: Text(
                                          pincode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${accounts.length} account(s)${selectedInPin > 0 ? ' • $selectedInPin selected' : ''}',
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 0, 12, 12),
                                            child: Column(
                                              children: accounts.map((account) {
                                                return _buildAccountItem(account);
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedAccountIds.length} selected • ${_selectedDaysForAssignment.length} day(s)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSelectedAssignments,
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Assign Days'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No customers allotted yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Admin will allot customers to you from the Accounts / Customer list screen.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(Account account) {
    final name = account.businessName ?? account.personName;
    final isSelected = _selectedAccountIds.contains(account.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openAccountDetail(account.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedAccountIds.add(account.id);
                        } else {
                          _selectedAccountIds.remove(account.id);
                        }
                      });
                    },
                    activeColor: _primary,
                  ),
                  CircleAvatar(
                    backgroundColor: _primary,
                    radius: 22,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (account.businessName != null)
                          Text(
                            account.personName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Text(
                          account.accountCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (account.assignedDays != null &&
                            account.assignedDays!.isNotEmpty)
                          Text(
                            'Current: ${account.assignedDays!.where((d) => _dayLabelMap.containsKey(d)).map((d) => _dayLabelMap[d]).join(', ')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 10),
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () => _launchCall(account.contactNumber),
                    color: Colors.green.shade700,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                    ),
                    tooltip: 'Call',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
