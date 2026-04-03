import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, this.account});

  final Map<String, dynamic>? account;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color _primary = Color(0xFFD7BE69);
  String? _expandedSection;
  String? _selectedStage;
  XFile? _capturedImage;

  static const List<String> _orderStages = [
    'Placed order',
    'Next week',
    'Not interested',
    'Closed shop',
    'Visit again schedule',
    'New customer',
    'Interested',
    'Negotiation',
    'Converted',
    'Deal lost',
  ];

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

  List<int> _assignedDays(Map<String, dynamic> account) {
    final raw = (account['assignedDays'] as List?) ?? const [];
    return raw
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  String _visitType(Map<String, dynamic> account) {
    final freq = (account['visitFrequency']?.toString() ?? '')
        .trim()
        .toUpperCase();
    final recurrenceType =
        (account['recurrenceType']?.toString() ?? '').trim().toLowerCase();
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
    final days = _assignedDays(account);

    if (afterDays != null && afterDays > 0) return 'AFTER_DAYS';
    if (recurrenceType.contains('after')) return 'AFTER_DAYS';
    if (freq.isNotEmpty) return freq;
    if (days.isNotEmpty) return 'WEEKLY';
    return 'WEEKLY';
  }

  String _visitTypeLabel(Map<String, dynamic> account) {
    final type = _visitType(account);
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
    if (type == 'AFTER_DAYS') {
      if (afterDays != null && afterDays > 0) return 'AFTER $afterDays DAYS';
      return 'AFTER N DAYS';
    }
    return type.replaceAll('_', ' ');
  }

  Color _visitTypeBg(Map<String, dynamic> account) {
    switch (_visitType(account)) {
      case 'MONTHLY':
        return const Color(0xFFE8F1FF);
      case 'AFTER_DAYS':
        return const Color(0xFFFFEFE0);
      case 'DAILY':
        return const Color(0xFFE7F9EC);
      default:
        return const Color(0xFFE8F8EC);
    }
  }

  Color _visitTypeText(Map<String, dynamic> account) {
    switch (_visitType(account)) {
      case 'MONTHLY':
        return const Color(0xFF215DA8);
      case 'AFTER_DAYS':
        return const Color(0xFFA35A17);
      case 'DAILY':
        return const Color(0xFF1F8B46);
      default:
        return const Color(0xFF1E7A3C);
    }
  }

  Widget _buildVisitTypeChip(Map<String, dynamic> account) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _visitTypeBg(account),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _visitTypeText(account).withOpacity(0.25),
        ),
      ),
      child: Text(
        _visitTypeLabel(account),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _visitTypeText(account),
        ),
      ),
    );
  }

  Widget _buildDayChip(int day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: Text(
        _dayLabel(day),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF606873),
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F2E6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE6D9B8)),
                ),
                child: const Text(
                  'Take Order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _selectedStage == null ? 'Select Stage' : 'Stage Selected',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9EDF2)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _orderStages.map((stage) {
                    final isSelected = _selectedStage == stage;
                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStage = stage;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD7BE69).withOpacity(0.18)
                                : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _primary.withOpacity(0.45)
                                  : const Color(0xFFE2E6EC),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color:
                                    isSelected ? _primary : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 75,
                    );
                    if (!mounted) return;
                    setState(() {
                      _capturedImage = image;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 14),
                  label: const Text('Take Image'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: (_selectedStage == null || _capturedImage == null)
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Submitted: ${_selectedStage ?? '-'}',
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
          if (_capturedImage != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_capturedImage!.path),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Image attached',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _capturedImage = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.red.shade600,
                  tooltip: 'Remove image',
                ),
              ],
            ),
          ],
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
    final assignedDays = _assignedDays(account);
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
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withOpacity(0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$accountId',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildVisitTypeChip(account),
                              ...assignedDays.map(_buildDayChip),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ownerName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('Visit In'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('Visit Out'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address : ${address.isEmpty ? '-' : address}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
