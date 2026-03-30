import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account_service.dart';
import '../../services/user_service.dart';

class AllBeatPlanScreen extends StatefulWidget {
  const AllBeatPlanScreen({super.key});

  @override
  State<AllBeatPlanScreen> createState() => _AllBeatPlanScreenState();
}

class _AllBeatPlanScreenState extends State<AllBeatPlanScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  bool _isLoading = true;
  String? _error;
  final DateTime _weekStart = AccountService.toWeekStart(DateTime.now());

  int _totalAccounts = 0;
  int _plannedAccounts = 0;
  int _unplannedAccounts = 0;

  final Map<int, int> _dayCounts = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
    7: 0,
  };
  final Map<int, List<Map<String, dynamic>>> _accountsByDay = {
    1: const [],
    2: const [],
    3: const [],
    4: const [],
    5: const [],
    6: const [],
    7: const [],
  };

  @override
  void initState() {
    super.initState();
    _loadBeatPlan();
  }

  Future<void> _loadBeatPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = UserService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final data = await AccountService.fetchPlanningWeekView(
        salesmanId: userId,
        weekStartDate: _weekStart,
      );

      final summary = (data['summary'] as Map?)?.cast<String, dynamic>() ?? {};
      final byDayRaw = (data['byDay'] as Map?)?.cast<String, dynamic>() ?? {};

      final nextDayCounts = <int, int>{
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0,
      };
      final nextAccountsByDay = <int, List<Map<String, dynamic>>>{
        1: const [],
        2: const [],
        3: const [],
        4: const [],
        5: const [],
        6: const [],
        7: const [],
      };

      for (int day = 1; day <= 7; day++) {
        final rows = (byDayRaw['$day'] as List?) ?? [];
        nextDayCounts[day] = rows.length;
        nextAccountsByDay[day] = rows
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (!mounted) return;

      setState(() {
        _totalAccounts = (summary['totalAccounts'] as num?)?.toInt() ?? 0;
        _plannedAccounts = (summary['plannedAccounts'] as num?)?.toInt() ?? 0;
        _unplannedAccounts =
            (summary['unplannedAccounts'] as num?)?.toInt() ?? 0;

        _dayCounts
          ..clear()
          ..addAll(nextDayCounts);
        _accountsByDay
          ..clear()
          ..addAll(nextAccountsByDay);

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  Future<void> _callNumber(String number) async {
    final cleaned = number.trim();
    if (cleaned.isEmpty || cleaned == '-') return;

    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty || clean == '-') return;

    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInMaps(Map<String, dynamic> account) async {
    final lat = _toDouble(account['latitude']);
    final lng = _toDouble(account['longitude']);
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSheetAccountCard(Map<String, dynamic> account) {
    final accountId = _safeText(account['id'], fallback: '');
    final ownerName = _safeText(account['personName'], fallback: 'Unknown');
    final shopName = _safeText(account['businessName']);
    final contact = _safeText(account['contactNumber']);
    final area = _safeText(account['area']);
    final pincode = _safeText(account['pincode']);
    final accountCode = _safeText(account['accountCode']);
    final address = _safeText(account['address']);
    final canOpenMaps =
        _toDouble(account['latitude']) != null && _toDouble(account['longitude']) != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ownerName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              shopName,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('Code: $accountCode', Colors.blue.shade50, Colors.blue.shade800),
                _chip('Area: $area', Colors.orange.shade50, Colors.orange.shade800),
                _chip('Pin: $pincode', Colors.green.shade50, Colors.green.shade800),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: accountId.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          context.push('/account/$accountId');
                        },
                  icon: const Icon(Icons.visibility, size: 18),
                  tooltip: 'Details',
                  color: Colors.grey.shade700,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(7),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: contact == '-' ? null : () => _callNumber(contact),
                  icon: const Icon(Icons.call, size: 18),
                  tooltip: 'Call',
                  color: Colors.grey.shade700,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(7),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: contact == '-' ? null : () => _launchWhatsApp(contact),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  tooltip: 'WhatsApp',
                  color: Colors.green.shade800,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFC9F1D5),
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(7),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: canOpenMaps ? () => _openInMaps(account) : null,
                  icon: const Icon(Icons.map, size: 18),
                  tooltip: 'Map',
                  color: Colors.blue.shade700,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFDCEBFF),
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(7),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDayAccountsSheet(int day, DateTime date) async {
    final accounts = _accountsByDay[day] ?? const <Map<String, dynamic>>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_dayShortLabel(day)} | ${_formatDate(date)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Planned Accounts: ${accounts.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: accounts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No accounts planned for this day.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            return _buildSheetAccountCard(accounts[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final weekEnd = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + 6,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Beat Plan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(_weekStart)} - ${_formatDate(weekEnd)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Total: $_totalAccounts', Colors.blue.shade50,
                  Colors.blue.shade800),
              _chip('Planned: $_plannedAccounts', Colors.orange.shade50,
                  Colors.orange.shade800),
              _chip('Remaining: $_unplannedAccounts', Colors.green.shade50,
                  Colors.green.shade800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: fg, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  String _dayShortLabel(int day) {
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return labels[day] ?? 'Day $day';
  }

  Widget _buildDayCard({
    required int day,
    required DateTime date,
    required int plannedCount,
  }) {
    final hasPlan = plannedCount > 0;

    final statusText = hasPlan ? 'Planned' : 'Unplanned';
    final statusColor =
        hasPlan ? Colors.green.shade700 : Colors.grey.shade700;

    final cardColor = hasPlan ? primaryColor.withValues(alpha: 0.11) : Colors.white;

    final borderColor =
        hasPlan ? primaryColor.withValues(alpha: 0.7) : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDayAccountsSheet(day, date),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dayShortLabel(day),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Accounts: $plannedCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDaysCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = index + 1;
          final date = DateTime(
            _weekStart.year,
            _weekStart.month,
            _weekStart.day + index,
          );
          final plannedCount = _dayCounts[day] ?? 0;
          return _buildDayCard(
            day: day,
            date: date,
            plannedCount: plannedCount,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('All Beat Plan'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBeatPlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Text(_error!),
                )
              : RefreshIndicator(
                  onRefresh: _loadBeatPlan,
                  child: ListView(
                    children: [
                      _buildHeader(),
                      _buildAllDaysCards(),
                    ],
                  ),
                ),
    );
  }
}
