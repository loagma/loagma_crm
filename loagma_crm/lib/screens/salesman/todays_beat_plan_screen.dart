import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account_service.dart';
import '../../services/user_service.dart';

class TodaysBeatPlanScreen extends StatefulWidget {
  const TodaysBeatPlanScreen({super.key});

  @override
  State<TodaysBeatPlanScreen> createState() => _TodaysBeatPlanScreenState();
}

class _TodaysBeatPlanScreenState extends State<TodaysBeatPlanScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  bool _isLoading = true;
  String? _error;

  final DateTime _selectedDate = DateTime.now();
  int _dayOfWeek = DateTime.now().weekday;
  int _total = 0;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadTodayAccounts();
  }

  Future<void> _loadTodayAccounts() async {
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
        date: _selectedDate,
      );

      final rawAccounts = (data['accounts'] as List?) ?? const [];

      if (!mounted) return;
      setState(() {
        _dayOfWeek = (data['dayOfWeek'] as num?)?.toInt() ?? _selectedDate.weekday;
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAssignedDays(dynamic assignedDays) {
    final days = (assignedDays as List?) ?? const [];
    if (days.isEmpty) return '-';

    const short = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return days
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .map((d) => short[d] ?? d.toString())
        .join(', ');
  }

  Color _frequencyColor(String frequency) {
    switch (frequency.toUpperCase()) {
      case 'DAILY':
        return Colors.red.shade700;
      case 'THRICE':
        return Colors.deepOrange.shade700;
      case 'TWICE':
        return Colors.blue.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  Future<void> _callNumber(String number) async {
    final cleaned = number.trim();
    if (cleaned.isEmpty || cleaned == '-') return;

    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openInMaps(Map<String, dynamic> account) async {
    final lat = (account['latitude'] as num?)?.toDouble();
    final lng = (account['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) return;

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Beat Plan',
            style: TextStyle(
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_dayLabel(_dayOfWeek)} | ${_formatDate(_selectedDate)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Total Planned: $_total',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Shown: ${_accounts.length}',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final accountId = account['id']?.toString();
    final personName = account['personName']?.toString().trim().isNotEmpty == true
        ? account['personName'].toString()
        : 'Unknown';
    final businessName = account['businessName']?.toString() ?? '-';
    final contact = account['contactNumber']?.toString() ?? '-';
    final area = account['area']?.toString() ?? '-';
    final pincode = account['pincode']?.toString() ?? '-';
    final address = account['address']?.toString() ?? '-';
    final accountCode = account['accountCode']?.toString() ?? '-';
    final frequency = account['visitFrequency']?.toString() ?? 'ONCE';
    final assignedDays = _formatAssignedDays(account['assignedDays']);
    final canOpenMaps = (account['latitude'] as num?) != null && (account['longitude'] as num?) != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _frequencyColor(frequency).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    frequency,
                    style: TextStyle(
                      color: _frequencyColor(frequency),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              businessName,
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tag('Code: $accountCode', Colors.grey.shade100, Colors.grey.shade800),
                _tag('Phone: $contact', Colors.green.shade50, Colors.green.shade800),
                _tag('Area: $area', Colors.orange.shade50, Colors.orange.shade800),
                _tag('PIN: $pincode', Colors.blue.shade50, Colors.blue.shade800),
              ],
            ),
            const SizedBox(height: 8),
            Text('Planned Days: $assignedDays', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text('Address: $address', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (accountId != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/account/$accountId'),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Details'),
                    ),
                  ),
                if (accountId != null) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: contact == '-' ? null : () => _callNumber(contact),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canOpenMaps ? () => _openInMaps(account) : null,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Map'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Beat Plan'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTodayAccounts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 10),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadTodayAccounts,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodayAccounts,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _buildHeader(),
                      if (_accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy, size: 42, color: Colors.grey.shade500),
                                const SizedBox(height: 10),
                                Text(
                                  'No accounts planned for ${_dayLabel(_dayOfWeek)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Date: ${_formatDate(_selectedDate)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            children: _accounts.map(_buildAccountCard).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
