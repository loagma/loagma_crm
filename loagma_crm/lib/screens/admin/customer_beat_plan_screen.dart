import 'package:flutter/material.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/beat_plan_service.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Create beat plan by assigning allotted customers day-wise (Mon–Sat).
class CustomerBeatPlanScreen extends StatefulWidget {
  final String salesmanId;
  final String salesmanName;
  final int allottedCount;

  const CustomerBeatPlanScreen({
    super.key,
    required this.salesmanId,
    required this.salesmanName,
    required this.allottedCount,
  });

  @override
  State<CustomerBeatPlanScreen> createState() => _CustomerBeatPlanScreenState();
}

class _CustomerBeatPlanScreenState extends State<CustomerBeatPlanScreen> {
  List<Account> _customers = [];
  Map<int, List<String>> _dayAssignments = {}; // dayOfWeek (1-6) -> accountIds
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _weekStart;
  String? _error;

  static const Color primaryColor = Color(0xFFD7BE69);
  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = BeatPlanService.getWeekStartDate(DateTime.now());
    for (int d = 1; d <= 6; d++) {
      _dayAssignments[d] = [];
    }
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AccountService.fetchAccounts(
        assignedToId: widget.salesmanId,
        limit: 500,
        page: 1,
      );
      if (!mounted) return;
      final accounts = List<Account>.from(result['accounts'] ?? []);
      setState(() {
        _customers = accounts;
        _isLoading = false;
        // Pre-fill from existing assignedDays
        for (final a in accounts) {
          if (a.assignedDays != null && a.assignedDays!.isNotEmpty) {
            for (final d in a.assignedDays!) {
              if (d >= 1 && d <= 6 && !_dayAssignments[d]!.contains(a.id)) {
                _dayAssignments[d]!.add(a.id);
              }
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _autoDistribute() {
    if (_customers.isEmpty) return;
    setState(() {
      for (int d = 1; d <= 6; d++) {
        _dayAssignments[d] = [];
      }
      for (int i = 0; i < _customers.length; i++) {
        final day = (i % 6) + 1;
        _dayAssignments[day]!.add(_customers[i].id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customers distributed across Mon–Sat'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      for (int d = 1; d <= 6; d++) {
        _dayAssignments[d] = [];
      }
    });
  }

  Future<void> _saveBeatPlan() async {
    setState(() => _isSaving = true);

    try {
      final token = UserService.token;
      if (token == null) throw Exception('Login required');

      // Build dayAssignments: { "1": ["id1","id2"], "2": [...], ... }
      final dayAssignmentsJson = <String, List<String>>{};
      for (final e in _dayAssignments.entries) {
        dayAssignmentsJson[e.key.toString()] = e.value;
      }
      final body = {
        'salesmanId': widget.salesmanId,
        'weekStartDate': _weekStart!.toIso8601String(),
        'dayAssignments': dayAssignmentsJson,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/beat-plans/generate-from-customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Beat plan created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to create beat plan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _moveCustomer(String accountId, int fromDay, int toDay) {
    setState(() {
      if (fromDay >= 1 && fromDay <= 6) {
        _dayAssignments[fromDay]!.remove(accountId);
      }
      if (toDay >= 1 && toDay <= 6) {
        if (!_dayAssignments[toDay]!.contains(accountId)) {
          _dayAssignments[toDay]!.add(accountId);
        }
      }
    });
  }

  int _getTotalAssigned() {
    int n = 0;
    for (int d = 1; d <= 6; d++) {
      n += _dayAssignments[d]!.length;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beat Plan — ${widget.salesmanName}'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Loading allotted customers...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCustomers,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No allotted customers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Account List → select accounts → Allot → pick this salesman',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _buildSimpleInstructions(),
          // const SizedBox(height: 16),
          _buildWeekSelector(),
          const SizedBox(height: 16),
          _buildSummary(),
          const SizedBox(height: 16),
          _buildActions(),
          const SizedBox(height: 20),
          _buildDaySections(),
        ],
      ),
    );
  }

  // Widget _buildSimpleInstructions() {
  //   return Container(
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: Colors.blue.shade50,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.blue.shade200),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.touch_app, color: Colors.blue.shade700, size: 22),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Quick steps',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.blue.shade900,
  //                 fontSize: 15,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           '1. Tap "Auto Distribute" to split customers across Mon–Sat\n'
  //           '2. (Optional) Change any customer\'s day using the dropdown\n'
  //           '3. Tap "Create Beat Plan" at the bottom',
  //           style: TextStyle(
  //             fontSize: 13,
  //             color: Colors.blue.shade900,
  //             height: 1.4,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }



  Widget _buildWeekSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: primaryColor),
        title: const Text('Week Starting'),
        subtitle: Text(
          _weekStart != null
              ? BeatPlanService.formatWeekRange(_weekStart!)
              : 'Select',
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _weekStart ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 7)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() {
              _weekStart = BeatPlanService.getWeekStartDate(picked);
            });
          }
        },
      ),
    );
  }

  Widget _buildSummary() {
    final total = _getTotalAssigned();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${_customers.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Text('Total Allotted'),
            ],
          ),
          Column(
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Text('Assigned to Days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _customers.isEmpty ? null : _autoDistribute,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text('Auto Distribute (split across Mon–Sat)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_getTotalAssigned() > 0) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _clearAll,
            icon: Icon(Icons.refresh, size: 18, color: Colors.grey[700]),
            label: Text(
              'Start over',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDaySections() {
    final inAnyDay = <String>{};
    for (final ids in _dayAssignments.values) {
      inAnyDay.addAll(ids);
    }
    final trulyUnassigned =
        _customers.where((a) => !inAnyDay.contains(a.id)).toList();

    return Column(
      children: [
        if (trulyUnassigned.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.orange.shade50,
            child: ExpansionTile(
              leading: Icon(Icons.warning_amber, color: Colors.orange[700]),
              title: Text(
                'Unassigned (${trulyUnassigned.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
              subtitle: const Text('Assign these customers to a day'),
              children: trulyUnassigned
                  .map((a) => _buildCustomerTile(a, 0))
                  .toList(),
            ),
          ),
        ...List.generate(6, (index) {
        final day = index + 1;
        final accountIds = _dayAssignments[day] ?? [];
        final accounts = _customers
            .where((a) => accountIds.contains(a.id))
            .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              child: Text(
                '${accountIds.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            title: Text(
              _dayNames[index],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${accountIds.length} customers'),
            children: accounts.map((a) => _buildCustomerTile(a, day)).toList(),
          ),
        );
      }),
      ],
    );
  }

  Widget _buildCustomerTile(Account account, int currentDay) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.person_outline, size: 20),
      title: Text(
        account.personName,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: account.businessName != null && account.businessName!.isNotEmpty
          ? Text(account.businessName!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: SizedBox(
        width: 140,
        child: DropdownButton<int>(
          value: currentDay > 0 ? currentDay : null,
          hint: const Text('Assign'),
          isExpanded: true,
          items: [
            if (currentDay > 0)
              const DropdownMenuItem(value: 0, child: Text('Remove')),
            ...List.generate(6, (i) {
              final d = i + 1;
              return DropdownMenuItem(
                value: d,
                child: Text(_dayNames[i]),
              );
            }),
          ],
          onChanged: (d) {
            if (d != null) {
              _moveCustomer(account.id, currentDay, d);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSaving || _getTotalAssigned() == 0
              ? null
              : _saveBeatPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _getTotalAssigned() > 0
                      ? 'Save Beat Plan (${_getTotalAssigned()} customers)'
                      : 'Tap Auto Distribute first',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
