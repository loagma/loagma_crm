import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../services/user_service.dart';

class TodayPlannedAccountsScreen extends StatefulWidget {
  const TodayPlannedAccountsScreen({super.key});

  @override
  State<TodayPlannedAccountsScreen> createState() => _TodayPlannedAccountsScreenState();
}

class _TodayPlannedAccountsScreenState extends State<TodayPlannedAccountsScreen> {
  bool _isLoading = true;
  String? _error;
  int _dayOfWeek = DateTime.now().weekday;
  int _total = 0;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = UserService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final data = await AccountService.fetchTodayPlannedAccounts(
        salesmanId: userId,
      );

      final rawAccounts = (data['accounts'] as List?) ?? const [];

      if (!mounted) return;
      setState(() {
        _dayOfWeek = (data['dayOfWeek'] as num?)?.toInt() ?? DateTime.now().weekday;
        _total = (data['total'] as num?)?.toInt() ?? rawAccounts.length;
        _accounts = rawAccounts
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _dayLabel(int day) {
    const labels = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return labels[day] ?? 'Day $day';
  }

  Color _frequencyColor(String frequency) {
    switch (frequency.toUpperCase()) {
      case 'DAILY':
        return Colors.red.shade600;
      case 'THRICE':
        return Colors.deepOrange.shade600;
      case 'TWICE':
        return Colors.blue.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today Plan'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.today, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_dayLabel(_dayOfWeek)}: $_total planned account(s)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _accounts.isEmpty
                          ? const Center(
                              child: Text('No accounts planned for today'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _accounts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final account = _accounts[index];
                                final personName = account['personName']?.toString() ?? 'Unknown';
                                final businessName = account['businessName']?.toString();
                                final pincode = account['pincode']?.toString() ?? '-';
                                final contact = account['contactNumber']?.toString() ?? '-';
                                final frequency = account['visitFrequency']?.toString() ?? 'ONCE';
                                final assignedDays = ((account['assignedDays'] as List?) ?? const [])
                                    .map((e) => e.toString())
                                    .join(', ');

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                personName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _frequencyColor(frequency).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                frequency,
                                                style: TextStyle(
                                                  color: _frequencyColor(frequency),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (businessName != null && businessName.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              businessName,
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text('Pincode: $pincode  •  Contact: $contact'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Planned Days: $assignedDays',
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
