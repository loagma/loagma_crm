import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../services/user_service.dart';

class MultiVisitAccountsScreen extends StatefulWidget {
  const MultiVisitAccountsScreen({super.key});

  @override
  State<MultiVisitAccountsScreen> createState() => _MultiVisitAccountsScreenState();
}

class _MultiVisitAccountsScreenState extends State<MultiVisitAccountsScreen> {
  bool _isLoading = true;
  String? _error;
  DateTime _weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  String _frequency = 'TWICE';
  int? _dayFilter;
  List<Map<String, dynamic>> _accounts = [];

  static const List<String> _frequencyOptions = ['TWICE', 'THRICE', 'DAILY'];

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

      final data = await AccountService.fetchMultiVisitWeekAccounts(
        salesmanId: userId,
        weekStartDate: _weekStart,
        frequency: _frequency,
        day: _dayFilter,
      );

      final rows = (data['accounts'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _accounts = rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return labels[day] ?? '$day';
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Visit Accounts'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Week: ${_weekLabel(_weekStart)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _frequencyOptions
                      .map(
                        (f) => ChoiceChip(
                          label: Text(f),
                          selected: _frequency == f,
                          onSelected: (_) {
                            setState(() => _frequency = f);
                            _load();
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Days'),
                        selected: _dayFilter == null,
                        onSelected: (_) {
                          setState(() => _dayFilter = null);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(7, (i) {
                        final day = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_dayLabel(day)),
                            selected: _dayFilter == day,
                            onSelected: (_) {
                              setState(() => _dayFilter = day);
                              _load();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    : _accounts.isEmpty
                        ? const Center(child: Text('No multi-visit accounts found'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _accounts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final a = _accounts[index];
                              final days = ((a['assignedDays'] as List?) ?? const []).map((e) => e.toString()).join(', ');
                              return Card(
                                child: ListTile(
                                  title: Text(a['personName']?.toString() ?? 'Unknown'),
                                  subtitle: Text(
                                    '${a['businessName'] ?? '-'}\nPincode: ${a['pincode'] ?? '-'}\nDays: $days',
                                  ),
                                  isThreeLine: true,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      a['visitFrequency']?.toString() ?? _frequency,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
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
