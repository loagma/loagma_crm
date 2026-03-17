import 'package:flutter/material.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/telecaller_api_service.dart';
import '../../services/map_task_assignment_service.dart';
import '../../services/user_service.dart';

class TelecallerAssignedPincodesScreen extends StatefulWidget {
  const TelecallerAssignedPincodesScreen({super.key});

  @override
  State<TelecallerAssignedPincodesScreen> createState() =>
      _TelecallerAssignedPincodesScreenState();
}

class _TelecallerAssignedPincodesScreenState
    extends State<TelecallerAssignedPincodesScreen> {
  final _service = MapTaskAssignmentService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Map<String, Map<String, dynamic>> _detailsByPin = {};
  final Map<String, List<Account>> _accountsByPin = {};
  final Set<String> _loadingPins = {};
  final Set<String> _expandedPins = {};
  final Set<String> _selectedAccountIds = {};
  final Set<int> _selectedDaysForAssignment = {};

  static const Map<int, String> _dayLabelMap = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _detailsByPin.clear();
      _accountsByPin.clear();
      _loadingPins.clear();
      _selectedAccountIds.clear();
    });
    final result = await TelecallerApiService.getPincodeAssignments();
    if (!mounted) return;
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      // Group by pincode → list of dayOfWeek ints
      final Map<String, List<int>> grouped = {};
      for (final row in data) {
        final map = Map<String, dynamic>.from(row as Map);
        final pin = (map['pincode'] ?? '').toString();
        final dynamic rawDay = map['dayOfWeek'];
        final int day = switch (rawDay) {
          int v => v,
          String v => int.tryParse(v) ?? 0,
          num v => v.toInt(),
          _ => 0,
        };
        if (pin.isEmpty) continue;
        grouped.putIfAbsent(pin, () => []);
        if (!grouped[pin]!.contains(day)) {
          grouped[pin]!.add(day);
        }
      }
      final rows = grouped.entries
          .map((e) => {
                'pincode': e.key,
                'days': (e.value..sort()),
              })
          .toList()
        ..sort((a, b) =>
            (a['pincode'] as String).compareTo(b['pincode'] as String));

      setState(() {
        _rows = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ??
            'Failed to load pincode assignments';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPincodeDetails(String pincode) async {
    if (_detailsByPin.containsKey(pincode)) return;
    if (_loadingPins.contains(pincode)) return;

    setState(() {
      _loadingPins.add(pincode);
    });

    try {
      // Location details
      final locResult = await _service.fetchLocationByPincode(pincode);
      final locData = (locResult['success'] == true && locResult['data'] != null)
          ? Map<String, dynamic>.from(locResult['data'] as Map)
          : null;

      // Account count
      int count = 0;
      try {
        final countResult = await _service.getAccountCountByPincode(pincode);
        if (countResult['success'] == true &&
            countResult['data'] != null &&
            (countResult['data'] as Map)['count'] != null) {
          count = int.tryParse(
                  (countResult['data'] as Map)['count'].toString()) ??
              0;
        }
      } catch (_) {
        // ignore count errors
      }

      final areas = locData?['areas'];
      final areaCount = areas is List ? areas.length : 0;

      if (!mounted) return;
      setState(() {
        _detailsByPin[pincode] = {
          'count': count,
          'city': locData?['city']?.toString(),
          'district': locData?['district']?.toString(),
          'state': locData?['state']?.toString(),
          'region': locData?['region']?.toString(),
          'country': locData?['country']?.toString(),
          'areaCount': areaCount,
          'ok': locData != null,
          if (locData == null)
            'message': locResult['message']?.toString() ??
                'Failed to fetch pincode details',
        };
        _loadingPins.remove(pincode);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsByPin[pincode] = {
          'ok': false,
          'message': e.toString(),
        };
        _loadingPins.remove(pincode);
      });
    }
  }

  Future<void> _loadAccountsByPincode(String pincode) async {
    if (_accountsByPin.containsKey(pincode)) return;
    final userId = UserService.currentUserId;
    if (userId == null) return;

    try {
      final result = await AccountService.fetchAccounts(
        assignedToId: userId,
        pincode: pincode,
        limit: 500,
        page: 1,
      );
      if (!mounted) return;
      final accounts = List<Account>.from(result['accounts'] ?? []);
      setState(() {
        _accountsByPin[pincode] = accounts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accountsByPin[pincode] = [];
      });
    }
  }

  Future<void> _saveSelectedAssignments() async {
    final userId = UserService.currentUserId;
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
      await _load();
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

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'All days';
    if (days.contains(0)) return 'All days';
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return days.map((d) => labels[d] ?? d.toString()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Pincodes'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _rows.isEmpty
                  ? const Center(
                      child: Text(
                        'No pincodes assigned yet.\nPlease contact Tele Admin.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          final pin = row['pincode'] as String;
                          final days = List<int>.from(row['days'] as List);
                          final details = _detailsByPin[pin];
                          final isPinLoading = _loadingPins.contains(pin);

                          final count = (details?['count'] is int)
                              ? details!['count'] as int
                              : int.tryParse(details?['count']?.toString() ?? '0') ?? 0;
                          final city = details?['city']?.toString();
                          final district = details?['district']?.toString();
                          final state = details?['state']?.toString();
                          final region = details?['region']?.toString();
                          final areaCount = (details?['areaCount'] is int)
                              ? details!['areaCount'] as int
                              : int.tryParse(details?['areaCount']?.toString() ?? '0') ?? 0;
                            final accounts = _accountsByPin[pin] ?? const <Account>[];
                            final selectedInPin = accounts
                              .where((a) => _selectedAccountIds.contains(a.id))
                              .length;

                          final locParts = <String>[
                            if (city != null && city.isNotEmpty) city,
                            if (district != null && district.isNotEmpty) district,
                            if (state != null && state.isNotEmpty) state,
                            if (region != null && region.isNotEmpty) region,
                          ];
                          final locLine = locParts.join(' • ');

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey<String>('pin-$pin'),
                              initiallyExpanded: _expandedPins.contains(pin),
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  if (expanded) {
                                    _expandedPins.add(pin);
                                  } else {
                                    _expandedPins.remove(pin);
                                  }
                                });
                                if (expanded) {
                                  _loadPincodeDetails(pin);
                                  _loadAccountsByPincode(pin);
                                }
                              },
                              leading: const Icon(
                                Icons.pin_drop_outlined,
                                color: Color(0xFFD7BE69),
                              ),
                              title: Text(
                                pin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Days: ${_formatDays(days)}'),
                                  if (selectedInPin > 0)
                                    Text(
                                      '$selectedInPin account(s) selected',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (locLine.isNotEmpty)
                                    Text(
                                      locLine,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isPinLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD7BE69),
                                      ),
                                    )
                                  : null,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Accounts: $count',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (areaCount > 0)
                                            Text(
                                              '$areaCount area(s)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (details != null &&
                                          details['ok'] == false &&
                                          (details['message']?.toString().isNotEmpty ??
                                              false)) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          details['message']?.toString() ?? '',
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ],
                                      if (details == null && !isPinLoading) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Details not loaded yet. Pull to refresh.',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      if (!_accountsByPin.containsKey(pin))
                                        Text(
                                          'Loading accounts...',
                                          style: TextStyle(color: Colors.grey[700]),
                                        )
                                      else if (accounts.isEmpty)
                                        Text(
                                          'No accounts available for this pincode',
                                          style: TextStyle(color: Colors.grey[700]),
                                        )
                                      else
                                        ...accounts.map((account) {
                                          final isSelected =
                                              _selectedAccountIds.contains(account.id);
                                          return CheckboxListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            value: isSelected,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedAccountIds.add(account.id);
                                                } else {
                                                  _selectedAccountIds.remove(account.id);
                                                }
                                              });
                                            },
                                            title: Text(
                                              account.businessName ?? account.personName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${account.accountCode} • ${account.contactNumber}',
                                            ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _dayLabelMap.entries.map((entry) {
                    final selected =
                        _selectedDaysForAssignment.contains(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedDaysForAssignment.add(entry.key);
                            } else {
                              _selectedDaysForAssignment.remove(entry.key);
                            }
                          });
                        },
                        selectedColor:
                            const Color(0xFFD7BE69).withOpacity(0.3),
                        checkmarkColor: const Color(0xFFD7BE69),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedAccountIds.length} selected • ${_selectedDaysForAssignment.length} day(s)',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSelectedAssignments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

