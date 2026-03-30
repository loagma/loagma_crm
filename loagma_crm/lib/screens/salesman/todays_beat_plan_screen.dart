import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty || clean == '-') return;

    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final ownerName = account['personName']?.toString().trim().isNotEmpty == true
        ? account['personName'].toString().trim()
        : 'Unknown';
    final shopName = (account['businessName']?.toString() ?? '-').trim();
    final contact = (account['contactNumber']?.toString() ?? '-').trim();
    final area = (account['area']?.toString() ?? '-').trim();
    final pincode = (account['pincode']?.toString() ?? '-').trim();
    final address = (account['address']?.toString() ?? '-').trim();
    final accountCode = (account['accountCode']?.toString() ?? '-').trim();
    final frequency = account['visitFrequency']?.toString() ?? 'ONCE';
    final canOpenMaps =
        (account['latitude'] as num?) != null &&
        (account['longitude'] as num?) != null;

    final rawAssignedDays = (account['assignedDays'] as List?) ?? const [];
    final assignedDays = rawAssignedDays
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    final selectedDays = assignedDays.toSet();

    const dayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final dayEntries = dayLabels.entries.toList();

    final dayCardColors = <int, Color>{
      1: const Color(0xFFFDE2E2),
      2: const Color(0xFFE3EEFF),
      3: const Color(0xFFECF8D8),
      4: const Color(0xFFE3F7FA),
      5: const Color(0xFFFFE4F1),
      6: const Color(0xFFFFEBD6),
      7: const Color(0xFFF1E6FF),
    };
    final dayBorderColors = <int, Color>{
      1: const Color(0xFFE8A8A8),
      2: const Color(0xFFAEC4EF),
      3: const Color(0xFFBBD992),
      4: const Color(0xFFA8D9E0),
      5: const Color(0xFFE8AFCB),
      6: const Color(0xFFE6C29E),
      7: const Color(0xFFCAB7E8),
    };
    final firstAssignedDay = assignedDays.isEmpty ? null : assignedDays.first;
    final cardColor = firstAssignedDay == null
        ? Colors.white
        : (dayCardColors[firstAssignedDay] ?? Colors.white);
    final borderColor = firstAssignedDay == null
        ? const Color(0xFFE5E7EB)
        : (dayBorderColors[firstAssignedDay] ?? const Color(0xFFE5E7EB));

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 0.8),
      ),
      child: InkWell(
        onTap: accountId == null ? null : () => context.push('/account/$accountId'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      accountCode,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ownerName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                shopName,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Address : $address',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Main area : $area',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'PIN : $pincode',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Days :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: List.generate(dayEntries.length, (index) {
                        final entry = dayEntries[index];
                        final isActive = selectedDays.contains(entry.key);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == dayEntries.length - 1 ? 0 : 3,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isActive
                                    ? const Color(0xFFB0B4BD)
                                    : const Color(0xFFE8EAEE),
                              ),
                              child: Text(
                                entry.value,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF666B75),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              contact,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: accountId == null
                        ? null
                        : () => context.push('/account/$accountId'),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
              ),
            ],
          ),
        ),
      ),
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
