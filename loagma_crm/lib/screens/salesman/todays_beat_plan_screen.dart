import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account_service.dart';
import '../../services/user_service.dart';
import 'order_details_screen.dart';
import 'salesman_map_screen.dart';

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
    if (!_hasValidCoordinates(account)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No valid map location for this account.')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesmanMapScreen(
          initialAccounts: [_normalizedAccountForMap(account)],
          screenTitle: 'Account Location',
          sourceTag: 'today_beat_single',
        ),
      ),
    );
  }

  Future<void> _openShownInMaps() async {
    final accountsWithLocation = _accounts
        .where(_hasValidCoordinates)
        .map(_normalizedAccountForMap)
        .toList();

    if (accountsWithLocation.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mapped locations found in shown accounts.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesmanMapScreen(
          initialAccounts: accountsWithLocation,
          screenTitle: 'Today Beat Plan Map',
          sourceTag: 'today_beat_all',
        ),
      ),
    );
  }

  Map<String, dynamic> _normalizedAccountForMap(Map<String, dynamic> account) {
    final normalized = Map<String, dynamic>.from(account);
    final lat = _extractLatitude(account);
    final lng = _extractLongitude(account);
    if (lat != null && lng != null) {
      normalized['latitude'] = lat;
      normalized['longitude'] = lng;
    }
    return normalized;
  }

  double? _parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return null;
      final direct = double.tryParse(raw);
      if (direct != null) return direct;
      return double.tryParse(raw.replaceAll(',', '.'));
    }
    return null;
  }

  double? _extractLatitude(Map<String, dynamic> account) {
    return _parseCoordinate(
      account['latitude'] ?? account['lat'] ?? account['Latitude'],
    );
  }

  double? _extractLongitude(Map<String, dynamic> account) {
    return _parseCoordinate(
      account['longitude'] ?? account['lng'] ?? account['lon'] ?? account['Longitude'],
    );
  }

  bool _hasValidCoordinates(Map<String, dynamic> account) {
    final lat = _extractLatitude(account);
    final lng = _extractLongitude(account);
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  String _buildRecurrenceLabel(Map<String, dynamic> account, String frequency) {
    final visitFrequency = (account['visitFrequency']?.toString() ?? frequency)
        .trim()
        .toUpperCase();
    final recurrenceType =
        (account['recurrenceType']?.toString() ?? '').trim().toLowerCase();
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');

    if (afterDays != null && afterDays > 0) {
      return 'AFTER $afterDays DAYS';
    }
    if (recurrenceType.contains('after')) {
      return 'AFTER N DAYS';
    }
    if (visitFrequency == 'WEEKLY') return 'WEEKLY';
    if (visitFrequency == 'MONTHLY') return 'MONTHLY';
    if (visitFrequency == 'ONCE') return 'ONCE';
    return visitFrequency.isEmpty ? 'WEEKLY' : visitFrequency;
  }

  void _openOrderDetails(Map<String, dynamic> account) {
    final accountWithSelectedDay = Map<String, dynamic>.from(account)
      ..['selectedDay'] = _dayOfWeek;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(account: accountWithSelectedDay),
      ),
    );
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Today Beat Plan',
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_dayLabel(_dayOfWeek)} | ${_formatDate(_selectedDate)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
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
              OutlinedButton.icon(
                onPressed: _accounts.isEmpty ? null : _openShownInMaps,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Show in Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade200),
                  backgroundColor: Colors.blue.shade50.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final recurrenceLabel = _buildRecurrenceLabel(account, frequency);
    final canOpenMaps = _hasValidCoordinates(account);

    final rawAssignedDays = (account['assignedDays'] as List?) ?? const [];
    final assignedDays = rawAssignedDays
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    final selectedDays = assignedDays.toSet();
    final todayLabel = _dayLabel(_dayOfWeek);

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
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: selectedDays.contains(_dayOfWeek)
                              ? const Color(0xFF9EA3AD)
                              : const Color(0xFFE8EAEE),
                        ),
                        child: Text(
                          todayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selectedDays.contains(_dayOfWeek)
                                ? Colors.white
                                : const Color(0xFF666B75),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF3E3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          recurrenceLabel,
                          style: const TextStyle(
                            color: Color(0xFF1E7A3C),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      shopName,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ownerName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Address : $address',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () => _openOrderDetails(account),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Proceed'),
                    ),
                  ),
                ],
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
