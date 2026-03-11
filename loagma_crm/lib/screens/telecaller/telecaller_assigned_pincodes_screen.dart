import 'package:flutter/material.dart';
import '../../services/telecaller_api_service.dart';
import '../../services/map_task_assignment_service.dart';

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
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Map<String, Map<String, dynamic>> _detailsByPin = {};
  final Set<String> _loadingPins = {};
  final Set<String> _expandedPins = {};

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
      _loadingPins.clear();
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
                        padding: const EdgeInsets.all(16),
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

