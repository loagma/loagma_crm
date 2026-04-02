import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, this.account});

  final Map<String, dynamic>? account;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color _primary = Color(0xFFD7BE69);
  String? _expandedSection;

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
    return labels[day] ?? 'Day $day';
  }

  String _visitPlanLabel(Map<String, dynamic> account) {
    final freq = (account['visitFrequency']?.toString() ?? '')
        .trim()
        .toUpperCase();
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
    final daysRaw = (account['assignedDays'] as List?) ?? const [];
    final days = daysRaw
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();

    if (afterDays != null && afterDays > 0) return 'After every $afterDays day(s)';
    if (days.isNotEmpty) return 'Assigned on ${days.map(_dayLabel).join(', ')}';
    if (freq.isNotEmpty) return freq;
    return '-';
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  Widget _buildSectionButton({
    required String id,
    required String label,
  }) {
    final isOpen = _expandedSection == id;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _toggleSection(id),
        style: OutlinedButton.styleFrom(
          backgroundColor: isOpen ? _primary : Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(
            color: isOpen ? const Color(0xFF8A7631) : const Color(0xFFE1E5EA),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildExpandedBody() {
    if (_expandedSection == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: const Text(
          'Tap any section above to open details.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_expandedSection == 'history') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Order History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('No historical orders available for this account yet.'),
          ],
        ),
      );
    }

    if (_expandedSection == 'summary') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Product Order Summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Summary placeholders can be replaced with API data.'),
            SizedBox(height: 6),
            Text('Total Items: 0'),
            Text('Total Qty: 0'),
            Text('Total Value: Rs 0'),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Take Order',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order saved (demo UI).')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black87,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Save Order'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account ?? const <String, dynamic>{};
    final shopName = (account['businessName']?.toString() ?? 'Order Details').trim();
    final ownerName = (account['personName']?.toString() ?? '-').trim();
    final accountCode = (account['accountCode']?.toString() ?? '-').trim();
    final address = (account['address']?.toString() ?? '-').trim();
    final plan = _visitPlanLabel(account);
    final accountId = (accountCode.isNotEmpty && accountCode != '-')
        ? accountCode
        : (account['id']?.toString() ?? '-').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: _primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account ID: $accountId',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ownerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address: ${address.isEmpty ? '-' : address}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.event_repeat_outlined, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visit Plan: ${plan.isEmpty ? '-' : plan}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSectionButton(id: 'history', label: 'Order History'),
              const SizedBox(width: 8),
              _buildSectionButton(
                id: 'summary',
                label: 'Product Summary',
              ),
              const SizedBox(width: 8),
              _buildSectionButton(id: 'take', label: 'Take Order'),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildExpandedBody(),
          ),
        ],
      ),
    );
  }
}
