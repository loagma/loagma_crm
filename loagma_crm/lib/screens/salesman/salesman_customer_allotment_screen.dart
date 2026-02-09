import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
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
  // All allotted accounts for the salesman (unfiltered)
  List<Account> _allAccounts = [];

  // Currently visible accounts after applying day/search filters
  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _searchQuery;
  int _selectedDayIndex = 0; // 0 = All days, 1–7 = Mon–Sun

  final TextEditingController _searchController = TextEditingController();
  static const List<String> _dayLabels = [
    'All days',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Cached count of customers per day (1–7) for quick UX summary.
  final Map<int, int> _dayCounts = {};

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
      if (!mounted) return;
      final accounts = List<Account>.from(result['accounts'] ?? []);
      setState(() {
        _allAccounts = accounts;
        _recomputeDayCounts();
        _applyFilters();
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

  /// Recalculate how many customers fall on each beat day (1–7).
  void _recomputeDayCounts() {
    _dayCounts.clear();
    for (final acc in _allAccounts) {
      final days = acc.assignedDays ?? const [];
      for (final d in days) {
        if (d < 1 || d > 7) continue;
        _dayCounts[d] = (_dayCounts[d] ?? 0) + 1;
      }
    }
  }

  /// Apply current day + search filters to `_allAccounts`.
  void _applyFilters() {
    final query = _searchQuery?.trim().toLowerCase();
    final selectedDay = _selectedDayIndex; // 0 = All

    _accounts = _allAccounts.where((acc) {
      // Day filter
      if (selectedDay > 0) {
        final days = acc.assignedDays ?? const [];
        if (!days.contains(selectedDay)) return false;
      }

      // Search filter
      if (query != null && query.isNotEmpty) {
        final haystack = [
          acc.personName,
          acc.businessName ?? '',
          acc.accountCode,
          acc.contactNumber,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      return true;
    }).toList();

    // Trigger rebuild
    if (mounted) {
      setState(() {});
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
                          'Customers allotted to you by admin (day-wise)',
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
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Day',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_dayLabels.length, (i) {
                              final isSelected = _selectedDayIndex == i;
                              // For index 0 show total unique customers,
                              // for other days show per‑day counts.
                              String labelText;
                              if (i == 0) {
                                labelText =
                                    'All days (${_allAccounts.length})';
                              } else {
                                final count = _dayCounts[i] ?? 0;
                                labelText =
                                    '${_dayLabels[i]}${count > 0 ? ' ($count)' : ''}';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(labelText),
                                  selected: isSelected,
                                  onSelected: (v) {
                                    _selectedDayIndex = v == true ? i : 0;
                                    _applyFilters();
                                  },
                                  selectedColor: _primary.withValues(alpha: 0.3),
                                  checkmarkColor: _primary,
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _accounts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '${_accounts.length} customer(s) allotted',
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
                        : _accounts.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: _loadAccounts,
                                color: _primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: _accounts.length,
                                  itemBuilder: (context, index) =>
                                      _buildCard(_accounts[index]),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            _selectedDayIndex == 0
                ? 'No customers allotted yet'
                : 'No customers allotted for ${_dayLabels[_selectedDayIndex]}',
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

  Widget _buildCard(Account account) {
    final name = account.businessName ?? account.personName;
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
