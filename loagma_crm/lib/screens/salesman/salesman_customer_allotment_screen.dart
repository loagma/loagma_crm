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
  bool _isUnassigning = false;
  String? _searchQuery;
  final Set<int> _selectedDaysForAssignment = {};
  int? _selectedAfterDays;
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
        .join('  |  ');
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

    final takeCount = requestedCount > remainingCount ? remainingCount : requestedCount;
    final candidateIds = accounts
        .where((a) => (a.assignedDays?.isEmpty ?? true))
        .where((a) => !_selectedAccountIds.contains(a.id))
        .map((a) => a.id)
        .take(takeCount)
        .toList();

    if (candidateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No more unassigned accounts available to select in $pincode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedAccountIds.addAll(candidateIds);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${candidateIds.length} account(s) selected in $pincode. Choose a day and tap Assign Day to save.',
        ),
        backgroundColor: Colors.green,
      ),
    );

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
        afterDays: _selectedAfterDays,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedAfterDays != null
                ? 'Assigned ${_selectedAccountIds.length} account(s) to ${_dayLabelMap[_selectedDaysForAssignment.first]} with recurrence every $_selectedAfterDays day(s)'
                : 'Assigned ${_selectedAccountIds.length} account(s) to ${_dayLabelMap[_selectedDaysForAssignment.first]}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _selectedAccountIds.clear();
      _selectedAfterDays = null;
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

  Future<void> _unassignSelectedAccounts() async {
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

    final selectedCount = _selectedAccountIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unassign Selected Accounts'),
          content: Text(
            'Unassign $selectedCount selected account(s) from all weeks? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: const Text('Unassign'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isUnassigning = true);
    try {
      final result = await AccountService.unassignWeeklyAccountsGlobal(
        salesmanId: userId,
        accountIds: _selectedAccountIds.toList(),
      );

      if (!mounted) return;
      final unassignedCount = (result['unassignedCount'] as num?)?.toInt() ?? 0;
      final alreadyUnassignedCount =
          (result['alreadyUnassignedCount'] as num?)?.toInt() ?? 0;
      final outOfScopeCount =
          ((result['outOfScopeAccountIds'] as List?)?.length) ?? 0;

      final message = StringBuffer()
        ..write('Unassigned $unassignedCount account(s)');
      if (alreadyUnassignedCount > 0) {
        message.write(', $alreadyUnassignedCount already unassigned');
      }
      if (outOfScopeCount > 0) {
        message.write(', $outOfScopeCount out of scope');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.toString()),
          backgroundColor: Colors.green,
        ),
      );

      _selectedAccountIds.clear();
      await _loadAccounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unassign accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUnassigning = false);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _showDayPickerDialog() async {
    int? pendingDay =
        _selectedDaysForAssignment.isEmpty ? null : _selectedDaysForAssignment.first;
    int? pendingAfterDays = _selectedAfterDays;
    bool enableAfterDays = pendingAfterDays != null;
    String afterDaysText = pendingAfterDays?.toString() ?? '';

    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? validationError;
            final parsedAfterDays = int.tryParse(afterDaysText.trim());
            final canShowPreview =
                enableAfterDays && pendingDay != null && parsedAfterDays != null && parsedAfterDays > 0;

            DateTime? nextVisitDate;
            if (canShowPreview) {
              final selectedDate = _activeWeekStart.add(Duration(days: pendingDay! - 1));
              nextVisitDate = selectedDate.add(Duration(days: parsedAfterDays));
            }

            return AlertDialog(
              title: const Text('Choose Day'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._dayLabelMap.entries.map((entry) {
                        final isSelected = pendingDay == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (_) {
                            setDialogState(() {
                              pendingDay = entry.key;
                            });
                          },
                          selectedColor: _primary.withValues(alpha: 0.3),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: enableAfterDays,
                        onChanged: (value) {
                          setDialogState(() {
                            enableAfterDays = value == true;
                            if (!enableAfterDays) {
                              afterDaysText = '';
                              pendingAfterDays = null;
                            }
                          });
                        },
                        activeColor: _primary,
                      ),
                      const Text(
                        'After Days (Recurring)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (enableAfterDays)
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter after how many days',
                        hintText: 'e.g. 10',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: afterDaysText)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: afterDaysText.length),
                        ),
                      onChanged: (value) {
                        setDialogState(() {
                          afterDaysText = value;
                        });
                      },
                    ),
                  if (nextVisitDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Next visit: ${_formatDate(nextVisitDate)} (${_dayLabelMap[nextVisitDate.weekday] ?? ''})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (validationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop({
                    'clear': true,
                  }),
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    if (pendingDay == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select one day'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (enableAfterDays) {
                      final parsed = int.tryParse(afterDaysText.trim());
                      if (parsed == null || parsed <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter valid After Days value'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      pendingAfterDays = parsed;
                    } else {
                      pendingAfterDays = null;
                    }

                    Navigator.of(dialogContext).pop({
                      'day': pendingDay,
                      'afterDays': pendingAfterDays,
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selection == null) return;
    setState(() {
      if (selection['clear'] == true) {
        _selectedDaysForAssignment.clear();
        _selectedAfterDays = null;
        return;
      }

      final pickedDay = selection['day'] as int?;
      final pickedAfterDays = selection['afterDays'] as int?;
      _selectedDaysForAssignment.clear();
      if (pickedDay != null) {
        _selectedDaysForAssignment.add(pickedDay);
      }
      _selectedAfterDays = pickedAfterDays;
    });
  }

  Widget _buildDayPickerButton() {
    final selectedDay =
        _selectedDaysForAssignment.isEmpty ? null : _selectedDaysForAssignment.first;
    final selectedDayLabel =
      selectedDay == null
        ? 'Choose Day'
        : (_selectedAfterDays != null
          ? '${_dayLabelMap[selectedDay]} +$_selectedAfterDays d'
          : (_dayLabelMap[selectedDay] ?? 'Choose Day'));

    return OutlinedButton.icon(
      onPressed: _showDayPickerDialog,
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Text(selectedDayLabel),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAccounts,
                      color: _primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                              ],
                            ),
                          ),
                          if (_totalVisibleAccounts > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_accountsByPincode.length} pincode(s)  |  $_totalVisibleAccounts account(s)',
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
                          if (_totalVisibleAccounts == 0 && _allAccounts.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: _buildDayWiseChips(
                                _computeDayWiseAccountCounts(_allAccounts),
                              ),
                            ),
                          if (_accountsByPincode.isEmpty)
                            SizedBox(height: 260, child: _buildEmpty())
                          else
                            ..._accountsByPincode.entries.map((entry) {
                              final pincode = entry.key;
                              final accounts = entry.value;
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
                                        'Total Business: $totalBusinessCount  |  Existing Accounts: $existingAccountsCount  |  Assigned: $assignedCount  |  Remaining: $remainingCount${selectedInPin > 0 ? '  |  $selectedInPin selected' : ''}',
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
                                                        vertical: 2,
                                                      ),
                                                      minimumSize: const Size(0, 28),
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
                                                        vertical: 2,
                                                      ),
                                                      minimumSize: const Size(0, 28),
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
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
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
                                                            vertical: 2,
                                                          ),
                                                          minimumSize: const Size(0, 28),
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
                                                      if (_selectedAccountIds.isNotEmpty)
                                                        const SizedBox(width: 6),
                                                      if (_selectedAccountIds.isNotEmpty)
                                                        _buildDayPickerButton(),
                                                    ],
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
                            }),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                  '${_selectedAccountIds.length} selected  |  ${_selectedDaysForAssignment.isEmpty ? 0 : 1} day',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: (_isSaving || _isUnassigning || _selectedAccountIds.isEmpty)
                    ? null
                    : _unassignSelectedAccounts,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                icon: _isUnassigning
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                        ),
                      )
                    : const Icon(Icons.remove_circle_outline, size: 16),
                label: Text(_isUnassigning ? 'Unassigning...' : 'Unassign'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (_isSaving || _isUnassigning) ? null : _saveSelectedAssignments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 16),
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
    final isAssigned = account.assignedDays != null && account.assignedDays!.isNotEmpty;
    return Card(
      color: isAssigned ? Colors.blue.shade50 : null,
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
                        if (isAssigned)
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

enum _WeeklyTapAssignmentMode { once, allWeek, manual }

class _WeeklyAssignmentViewScreenState extends State<_WeeklyAssignmentViewScreen> {
  int _weekOffset = 0;
  bool _isLoading = true;
  bool _isAssigning = false;
  final Set<int> _expandedDays = <int>{};
  Map<int, int> _dayTotals = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 };
  List<Map<String, dynamic>> _pincodeGroups = [];

  Future<void> _openAccountDetails(String accountId) async {
    final result = await context.push('/account/$accountId');
    if (result == true && mounted) {
      await _loadWeekData();
    }
  }

  Future<void> _openAccountEdit(String accountId) async {
    final result = await context.push('/account/edit/$accountId');
    if (result == true && mounted) {
      await _loadWeekData();
    }
  }

  List<int> _allWeekDays() {
    final days = widget.dayLabelMap.keys.toList()..sort();
    return days;
  }

  String _dayLabels(List<int> days) {
    final sorted = days.toList()..sort();
    return sorted
        .where(widget.dayLabelMap.containsKey)
        .map((d) => widget.dayLabelMap[d]!)
        .join(', ');
  }

  Future<_WeeklyTapAssignmentMode?> _showAssignmentModeSelector(
    String displayName,
    int tappedDay,
  ) async {
    final dayLabel = widget.dayLabelMap[tappedDay] ?? 'Selected Day';
    return showModalBottomSheet<_WeeklyTapAssignmentMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign $displayName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tapped from $dayLabel',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.looks_one_outlined),
                  title: Text('Once ($dayLabel)'),
                  onTap: () => Navigator.of(sheetContext).pop(_WeeklyTapAssignmentMode.once),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_week_outlined),
                  title: const Text('All Week (Mon-Sun)'),
                  onTap: () => Navigator.of(sheetContext).pop(_WeeklyTapAssignmentMode.allWeek),
                ),
                ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: const Text('Manual (Select Days)'),
                  onTap: () => Navigator.of(sheetContext).pop(_WeeklyTapAssignmentMode.manual),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<int>?> _showManualDaySelector(int defaultDay) async {
    final initialDays = <int>{defaultDay};
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) {
        final selectedDays = Set<int>.from(initialDays);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manual Day Selection'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose one or more days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allWeekDays().map((day) {
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(widget.dayLabelMap[day] ?? 'Day $day'),
                        selected: isSelected,
                        onSelected: (value) {
                          setDialogState(() {
                            if (value) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                        selectedColor: widget.primary.withValues(alpha: 0.25),
                        checkmarkColor: widget.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedDays.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(selectedDays),
                  style: ElevatedButton.styleFrom(backgroundColor: widget.primary),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null || selected.isEmpty) return null;
    return selected.toList()..sort();
  }

  Future<void> _assignFromWeeklyTap({
    required String accountId,
    required String displayName,
    required int tappedDay,
  }) async {
    if (_isAssigning) return;

    final mode = await _showAssignmentModeSelector(displayName, tappedDay);
    if (!mounted || mode == null) return;

    List<int>? assignedDays;
    if (mode == _WeeklyTapAssignmentMode.once) {
      assignedDays = [tappedDay];
    } else if (mode == _WeeklyTapAssignmentMode.allWeek) {
      assignedDays = _allWeekDays();
    } else {
      assignedDays = await _showManualDaySelector(tappedDay);
    }

    if (!mounted || assignedDays == null || assignedDays.isEmpty) return;

    setState(() => _isAssigning = true);
    try {
      Future<void> submit({required bool useOverride}) async {
        await AccountService.manualAssignWeeklyAccounts(
          salesmanId: widget.salesmanId,
          weekStartDate: _selectedWeekStart,
          accountIds: [accountId],
          assignedDays: assignedDays!,
          manualOverrideAccountIds: useOverride ? [accountId] : const [],
        );
      }

      bool usedOverride = false;
      try {
        await submit(useOverride: false);
      } catch (e) {
        final message = e.toString().toLowerCase();
        final needsOverride = message.contains('manual override') ||
            message.contains('already assigned in this week') ||
            message.contains('already assigned');

        if (!needsOverride) {
          rethrow;
        }

        usedOverride = true;
        await submit(useOverride: true);
      }

      if (!mounted) return;
      final labels = _dayLabels(assignedDays);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedOverride
                ? 'Assigned $displayName to $labels (manual override applied)'
                : 'Assigned $displayName to $labels',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadWeekData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  int _readDayCount(dynamic rawDayCounts, int day) {
    if (rawDayCounts is! Map) return 0;
    return (rawDayCounts[day.toString()] as num?)?.toInt() ??
        (rawDayCounts[day] as num?)?.toInt() ??
        0;
  }

  List<Map<String, dynamic>> _assignedAccountsForDay(Map<String, dynamic> group, int day) {
    final assigned = (group['assigned'] as List?) ?? const [];
    final result = <Map<String, dynamic>>[];

    for (final item in assigned) {
      if (item is! Map) continue;
      final account = Map<String, dynamic>.from(item);
      final days = ((account['assignedDays'] as List?) ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((d) => d >= 1 && d <= 7)
          .toSet();
      if (days.contains(day)) {
        result.add(account);
      }
    }

    return result;
  }

  Widget _buildDayAccountCard(Map<String, dynamic> account, String pin, int day) {
    final displayName =
        (account['businessName']?.toString().trim().isNotEmpty ?? false)
            ? account['businessName'].toString()
            : (account['personName']?.toString() ?? 'Unknown');
    final personName = account['personName']?.toString() ?? '';
    final accountCode = account['accountCode']?.toString() ?? '-';
    final contactNumber = account['contactNumber']?.toString() ?? '-';
    final accountId = account['id']?.toString();
    final pincode = account['pincode']?.toString() ?? pin;
    final frequency = account['visitFrequency']?.toString() ?? 'ONCE';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: (accountId == null || _isAssigning)
            ? null
            : () => _assignFromWeeklyTap(
            accountId: accountId,
            displayName: displayName,
            tappedDay: day,
          ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: widget.primary.withValues(alpha: 0.18),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: widget.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      frequency,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  if (accountId != null)
                    IconButton(
                      onPressed: () => _openAccountDetails(accountId),
                      icon: const Icon(Icons.open_in_new_outlined, size: 18),
                      tooltip: 'Open details',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: const EdgeInsets.all(0),
                    ),
                  if (accountId != null)
                    IconButton(
                      onPressed: () => _openAccountEdit(accountId),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit account',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: const EdgeInsets.all(0),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                ],
              ),
              if (personName.isNotEmpty && personName != displayName)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    personName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Code: $accountCode',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Phone: $contactNumber',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PIN: $pincode',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
              if (accountId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _isAssigning
                        ? 'Saving assignment...'
                        : 'Tap card to assign. Use open/edit icons for details.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dayTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        _pincodeGroups = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load weekly assignments: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                      key: PageStorageKey<String>(
                        'weekly-day-${_selectedWeekStart.toIso8601String()}-$day',
                      ),
                      initiallyExpanded: _expandedDays.contains(day),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedDays.add(day);
                          } else {
                            _expandedDays.remove(day);
                          }
                        });
                      },
                      title: Text(
                        '$dayLabel - $totalForDay assigned account(s)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: _pincodeGroups.map<Widget>((group) {
                              final pin = (group['pincode'] ?? '').toString();
                              final countForDay = _readDayCount(group['dayCounts'], day);
                              if (countForDay == 0) {
                                return const SizedBox.shrink();
                              }

                              final accountsForDay = _assignedAccountsForDay(group, day);

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
                                            '$countForDay assigned on $dayLabel - $unassignedForWeek unassigned in week',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...accountsForDay.map(
                                            (account) => _buildDayAccountCard(account, pin, day),
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
