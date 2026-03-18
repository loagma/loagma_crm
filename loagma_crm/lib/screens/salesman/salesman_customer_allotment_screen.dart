import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/map_task_assignment_service.dart';
import '../../services/user_service.dart';

/// Salesman screen: customers allotted by admin (day-wise).
/// Shows existing accounts from assigned pincodes; day chips are used for reassignment (1=Mon .. 7=Sun).
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
  final Map<String, Map<String, int>> _pincodeStatsByCode = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _searchQuery;
  final Set<int> _selectedDaysForAssignment = {};
  final Set<String> _selectedAccountIds = {};
  final Set<String> _expandedPincodes = {};
  final TextEditingController _searchController = TextEditingController();
  final DateTime _activeWeekStart = AccountService.toWeekStart(DateTime.now());
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

  List<Account> _parseWeeklyAccountList(dynamic rawList, {required bool assigned}) {
    if (rawList is! List) return const <Account>[];

    final parsed = <Account>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);

      if (assigned) {
        final rawDays = raw['assignedDays'];
        final normalizedDays = (rawDays is List)
            ? rawDays
                .map((d) => int.tryParse(d.toString()) ?? 0)
                .where((d) => d >= 1 && d <= 7)
                .toList()
            : <int>[];
        raw['assignedDays'] = normalizedDays;
      } else {
        // Remaining accounts are unassigned for this selected week.
        raw['assignedDays'] = null;
      }

      try {
        parsed.add(Account.fromJson(raw));
      } catch (_) {
        // Ignore malformed rows to keep screen usable.
      }
    }
    return parsed;
  }

  int _remainingCountForPincode(String pincode) {
    final accounts = _accountsByPincode[pincode] ?? const [];
    return accounts.where((a) => (a.assignedDays?.isEmpty ?? true)).length;
  }

  Future<void> _loadAccounts() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final assignmentResult =
          await _taskAssignmentService.getAssignmentsBySalesman(userId);
      final assignmentRows =
          (assignmentResult['assignments'] as List?) ?? const [];
      final statsRaw = assignmentResult['pincodeStats'];
      final assignedPins = assignmentRows
          .map((e) => (e as Map)['pincode']?.toString().trim() ?? '')
          .where((pin) => pin.isNotEmpty)
          .toSet();

      final parsedStats = <String, Map<String, int>>{};
      if (statsRaw is Map) {
        for (final entry in statsRaw.entries) {
          final pin = entry.key.toString().trim();
          if (pin.isEmpty) continue;
          final value = entry.value;
          if (value is Map) {
            parsedStats[pin] = {
              'totalBusinessCount':
                  (value['totalBusinessCount'] as num?)?.toInt() ?? 0,
              'existingAccountsCount':
                  (value['existingAccountsCount'] as num?)?.toInt() ?? 0,
            };
          }
        }
      }

      final weeklyData = await AccountService.fetchWeeklyAssignmentsView(
        salesmanId: userId,
        weekStartDate: _activeWeekStart,
      );

      final weeklyGroups = (weeklyData['pincodes'] as List?) ?? const [];
      final accountById = <String, Account>{};
      final pinsFromWeekly = <String>{};

      for (final group in weeklyGroups) {
        if (group is! Map) continue;
        final map = Map<String, dynamic>.from(group);
        final pin = (map['pincode']?.toString() ?? '').trim();
        if (pin.isNotEmpty) {
          pinsFromWeekly.add(pin);
        }

        final assignedAccounts = _parseWeeklyAccountList(
          map['assigned'],
          assigned: true,
        );
        final remainingAccounts = _parseWeeklyAccountList(
          map['remaining'],
          assigned: false,
        );

        for (final account in [...remainingAccounts, ...assignedAccounts]) {
          final existing = accountById[account.id];
          if (existing == null) {
            accountById[account.id] = account;
            continue;
          }
          final existingHasDays = existing.assignedDays?.isNotEmpty ?? false;
          final incomingHasDays = account.assignedDays?.isNotEmpty ?? false;
          if (!existingHasDays && incomingHasDays) {
            accountById[account.id] = account;
          }
        }

        if (pin.isNotEmpty && !parsedStats.containsKey(pin)) {
          parsedStats[pin] = {
            'totalBusinessCount':
                (map['totalAccounts'] as num?)?.toInt() ?? 0,
            'existingAccountsCount':
                (map['totalAccounts'] as num?)?.toInt() ?? 0,
          };
        }
      }

      final accounts = accountById.values.toList();
      final effectiveAssignedPins = <String>{...assignedPins, ...pinsFromWeekly};

      _selectedAccountIds.removeWhere((id) => !accountById.containsKey(id));

      if (!mounted) return;
      setState(() {
        _assignedPincodes
          ..clear()
          ..addAll(effectiveAssignedPins);
        _pincodeStatsByCode
          ..clear()
          ..addAll(parsedStats);
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

  Map<int, int> _computeDayWiseAccountCounts(List<Account> accounts) {
    final dayCounts = <int, int>{};
    for (final account in accounts) {
      final days = account.assignedDays ?? const <int>[];
      for (final day in days) {
        if (!_dayLabelMap.containsKey(day)) continue;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    }
    return dayCounts;
  }

  Widget _buildDayWiseChips(Map<int, int> dayCounts) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _dayLabelMap.entries.map((entry) {
        final count = dayCounts[entry.key] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: count > 0 ? _primary.withValues(alpha: 0.18) : Colors.grey.shade200,
            border: Border.all(
              color: count > 0 ? _primary : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Text(
            '${entry.value}: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayWiseChipsCompact(Map<int, int> dayCounts) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _dayLabelMap.entries.map((entry) {
        final count = dayCounts[entry.key] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: count > 0 ? _primary.withValues(alpha: 0.14) : Colors.grey.shade100,
              border: Border.all(
                color: count > 0 ? _primary : Colors.grey.shade300,
                width: 0.5,
              ),
            ),
            child: Text(
              '${entry.value}:$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDayWiseCounts(Map<int, int> dayCounts) {
    return _dayLabelMap.entries
        .map((entry) => '${entry.value}:${dayCounts[entry.key] ?? 0}')
        .join(' • ');
  }

  int _countAssignedAccounts(List<Account> accounts) {
    return accounts.where((a) => (a.assignedDays?.isNotEmpty ?? false)).length;
  }

  int _countRemainingAccounts(List<Account> accounts) {
    return accounts.length - _countAssignedAccounts(accounts);
  }

  void _openWeeklyView() {
    if (_isLoading) return;
    final userId = _currentUserId;
    if (userId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WeeklyAssignmentViewScreen(
          salesmanId: userId,
          initialWeekStart: _activeWeekStart,
          dayLabelMap: _dayLabelMap,
          primary: _primary,
        ),
      ),
    );
  }

  void _showSummaryDialog() {
    final totalDayCounts = _computeDayWiseAccountCounts(_allAccounts);
    final pincodeBreakdown = <String, Map<int, int>>{};
    for (final pin in _accountsByPincode.keys) {
      pincodeBreakdown[pin] = _computeDayWiseAccountCounts(_accountsByPincode[pin] ?? const []);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Day-wise Assignment Summary'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total existing accounts: ${_allAccounts.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildDayWiseChips(totalDayCounts),
                const SizedBox(height: 14),
                const Text(
                  'Pincode-wise Day Count',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...pincodeBreakdown.entries.map((entry) {
                  final pin = entry.key;
                  final chips = _buildDayWiseChipsCompact(entry.value);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pin, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: chips,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _selectAllForPincode(String pincode) {
    final accounts = _accountsByPincode[pincode] ?? const [];
    if (accounts.isEmpty) return;

    setState(() {
      _selectedAccountIds.addAll(accounts.map((a) => a.id));
    });
  }

  void _clearSelectionForPincode(String pincode) {
    final accounts = _accountsByPincode[pincode] ?? const [];
    if (accounts.isEmpty) return;

    setState(() {
      for (final account in accounts) {
        _selectedAccountIds.remove(account.id);
      }
    });
  }

  Future<void> _showSelectCountDialogForPincode(String pincode) async {
    final accounts = _accountsByPincode[pincode] ?? const [];
    if (accounts.isEmpty) return;

    final remainingCount = _remainingCountForPincode(pincode);
    if (remainingCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No unassigned account left in $pincode for this week'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    int enteredCount = 0;
    final count = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Select Accounts ($pincode)'),
          content: Form(
            key: formKey,
            child: TextFormField(
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter number (max $remainingCount)',
              ),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter valid number';
                }
                return null;
              },
              onChanged: (value) {
                enteredCount = int.tryParse(value.trim()) ?? 0;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(enteredCount);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(enteredCount);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (!mounted || count == null) return;
    await _selectCountForPincode(pincode, count);
  }

  Future<void> _selectCountForPincode(String pincode, int requestedCount) async {
    final accounts = _accountsByPincode[pincode] ?? const [];
    if (accounts.isEmpty) return;

    final remainingCount = _remainingCountForPincode(pincode);
    if (remainingCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No unassigned account left in $pincode for this week'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = _currentUserId;
    if (userId == null) return;

    if (_selectedDaysForAssignment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select exactly one day before using Select N'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDaysForAssignment.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select N works with one day only. Choose one day.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final takeCount = requestedCount > remainingCount
      ? remainingCount
        : requestedCount;

    try {
      final selectedDay = _selectedDaysForAssignment.first;
      final result = await AccountService.autoAssignNextUnassignedAccounts(
        salesmanId: userId,
        pincode: pincode,
        weekStartDate: _activeWeekStart,
        day: selectedDay,
        countN: takeCount,
      );
      final assignedCount = (result['assignedCount'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$assignedCount account(s) auto-assigned for ${_dayLabelMap[selectedDay]} in $pincode',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAccounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to auto-assign next accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (requestedCount > remainingCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only $takeCount account(s) available in $pincode, selected all in this pincode',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
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

    if (_selectedDaysForAssignment.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select exactly one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AccountService.manualAssignWeeklyAccounts(
        salesmanId: userId,
        weekStartDate: _activeWeekStart,
        accountIds: _selectedAccountIds.toList(),
        assignedDays: _selectedDaysForAssignment.toList()..sort(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assigned ${_selectedAccountIds.length} account(s) to ${_dayLabelMap[_selectedDaysForAssignment.first]}',
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
            icon: const Icon(Icons.info_outline),
            onPressed: _openWeeklyView,
            tooltip: 'Weekly view',
          ),
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
                          'Select day to assign',
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
                                        _selectedDaysForAssignment.clear();
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_accountsByPincode.length} pincode(s) • $_totalVisibleAccounts account(s)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDayWiseChips(
                            _computeDayWiseAccountCounts(_allAccounts),
                          ),
                        ],
                      ),
                    ),
                  if (!_isLoading && _totalVisibleAccounts == 0 && _allAccounts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildDayWiseChips(
                        _computeDayWiseAccountCounts(_allAccounts),
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
                                    final stats = _pincodeStatsByCode[pincode];
                                    final totalBusinessCount =
                                      stats?['totalBusinessCount'] ?? 0;
                                    final existingAccountsCount =
                                      stats?['existingAccountsCount'] ?? 0;
                                    final pincodeDayCounts =
                                        _computeDayWiseAccountCounts(accounts);
                                    final pincodeDaySummary =
                                        _formatDayWiseCounts(pincodeDayCounts);
                                    final assignedCount =
                                      _countAssignedAccounts(accounts);
                                    final remainingCount =
                                      _countRemainingAccounts(accounts);

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
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Business: $totalBusinessCount • Existing Accounts: $existingAccountsCount • Assigned: $assignedCount • Remaining: $remainingCount${selectedInPin > 0 ? ' • $selectedInPin selected' : ''}',
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              pincodeDaySummary,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 0, 12, 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                if (accounts.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 6,
                                                    ),
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _selectAllForPincode(
                                                                  pincode),
                                                          icon: const Icon(
                                                            Icons.done_all,
                                                            size: 16,
                                                          ),
                                                          label:
                                                              const Text('All'),
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            minimumSize: const Size(0, 30),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize.shrinkWrap,
                                                            visualDensity:
                                                                VisualDensity.compact,
                                                            textStyle: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _showSelectCountDialogForPincode(
                                                                  pincode),
                                                          icon: const Icon(
                                                            Icons.filter_9_plus,
                                                            size: 16,
                                                          ),
                                                          label:
                                                              const Text('Select N'),
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            minimumSize: const Size(0, 30),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize.shrinkWrap,
                                                            visualDensity:
                                                                VisualDensity.compact,
                                                            textStyle: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _clearSelectionForPincode(
                                                                  pincode),
                                                          icon: const Icon(
                                                            Icons.clear_all,
                                                            size: 16,
                                                          ),
                                                          label: const Text(
                                                              'Clear Pin'),
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            minimumSize: const Size(0, 30),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize.shrinkWrap,
                                                            visualDensity:
                                                                VisualDensity.compact,
                                                            textStyle: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ...accounts.map((account) {
                                                  return _buildAccountItem(
                                                    account,
                                                  );
                                                }),
                                              ],
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
                  '${_selectedAccountIds.length} selected • ${_selectedDaysForAssignment.isEmpty ? 0 : 1} day',
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
                label: Text(_isSaving ? 'Saving...' : 'Assign Day'),
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
              const SizedBox(height: 2),
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

class _WeeklyAssignmentViewScreen extends StatefulWidget {
  const _WeeklyAssignmentViewScreen({
    required this.salesmanId,
    required this.initialWeekStart,
    required this.dayLabelMap,
    required this.primary,
  });

  final String salesmanId;
  final DateTime initialWeekStart;
  final Map<int, String> dayLabelMap;
  final Color primary;

  @override
  State<_WeeklyAssignmentViewScreen> createState() =>
      _WeeklyAssignmentViewScreenState();
}

class _WeeklyAssignmentViewScreenState extends State<_WeeklyAssignmentViewScreen> {
  int _weekOffset = 0;
  bool _isLoading = true;
  Map<int, int> _dayTotals = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 };
  List<Map<String, dynamic>> _pincodeGroups = [];

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime get _selectedWeekStart {
    final currentWeek = _startOfWeek(widget.initialWeekStart);
    return currentWeek.add(Duration(days: _weekOffset * 7));
  }

  String _weekRangeLabel() {
    final start = _selectedWeekStart;
    final end = start.add(const Duration(days: 6));
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AccountService.fetchWeeklyAssignmentsView(
        salesmanId: widget.salesmanId,
        weekStartDate: _selectedWeekStart,
      );

      final rawTotals = (data['dayTotals'] as Map?) ?? const {};
      final totals = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      for (final entry in rawTotals.entries) {
        final day = int.tryParse(entry.key.toString());
        if (day == null || !totals.containsKey(day)) continue;
        totals[day] = (entry.value as num?)?.toInt() ?? 0;
      }

      final groups = ((data['pincodes'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      setState(() {
        _dayTotals = totals;
        _pincodeGroups = groups;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dayTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        _pincodeGroups = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Assignment View'),
        backgroundColor: widget.primary,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      setState(() => _weekOffset--);
                      await _loadWeekData();
                    },
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous week',
                  ),
                  Expanded(
                    child: Text(
                      _weekRangeLabel(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      setState(() => _weekOffset++);
                      await _loadWeekData();
                    },
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next week',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Week-specific assignments (independent data per selected week)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: widget.dayLabelMap.entries.map((dayEntry) {
                  final day = dayEntry.key;
                  final dayLabel = dayEntry.value;
                  final totalForDay = _dayTotals[day] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        '$dayLabel • $totalForDay assigned account(s)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: _pincodeGroups.map((group) {
                              final pin = (group['pincode'] ?? '').toString();
                              final rawDayCounts = (group['dayCounts'] as Map?) ?? const {};
                              final countForDay = (rawDayCounts[day.toString()] as num?)?.toInt() ??
                                  (rawDayCounts[day] as num?)?.toInt() ?? 0;
                              if (countForDay == 0) {
                                return const SizedBox.shrink();
                              }

                              final unassignedForWeek =
                                  (group['remainingAccounts'] as num?)?.toInt() ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pin,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$countForDay assigned on $dayLabel • $unassignedForWeek unassigned',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
