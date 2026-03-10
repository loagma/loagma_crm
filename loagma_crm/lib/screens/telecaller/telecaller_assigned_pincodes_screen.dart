import 'package:flutter/material.dart';
import '../../services/telecaller_api_service.dart';

class TelecallerAssignedPincodesScreen extends StatefulWidget {
  const TelecallerAssignedPincodesScreen({super.key});

  @override
  State<TelecallerAssignedPincodesScreen> createState() =>
      _TelecallerAssignedPincodesScreenState();
}

class _TelecallerAssignedPincodesScreenState
    extends State<TelecallerAssignedPincodesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

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
        if (day >= 1 && day <= 7 && !grouped[pin]!.contains(day)) {
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
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.pin_drop_outlined),
                              title: Text(
                                pin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Days: ${_formatDays(days)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

