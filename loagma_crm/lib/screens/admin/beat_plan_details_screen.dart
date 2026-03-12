import 'package:flutter/material.dart';
import '../../models/beat_plan_model.dart';
import '../../services/beat_plan_service.dart';

class BeatPlanDetailsScreen extends StatefulWidget {
  final String beatPlanId;

  const BeatPlanDetailsScreen({super.key, required this.beatPlanId});

  @override
  State<BeatPlanDetailsScreen> createState() => _BeatPlanDetailsScreenState();
}

class _BeatPlanDetailsScreenState extends State<BeatPlanDetailsScreen> {
  WeeklyBeatPlan? _beatPlan;
  bool _isLoading = true;
  String? _error;
  bool _isEditingDistribution = false;
  final Map<String, List<String>> _editableAreasByDayId = {};
  final Map<String, int> _editablePlannedVisitsByDayId = {};
  List<String> _editablePincodes = [];

  // Theme colors - matching existing app
  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _loadBeatPlanDetails();
  }

  Future<void> _loadBeatPlanDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final beatPlan = await BeatPlanService.getWeeklyBeatPlanDetails(
        widget.beatPlanId,
      );

      setState(() {
        _beatPlan = beatPlan;
        _isLoading = false;
        _isEditingDistribution = false;
        _editableAreasByDayId.clear();
        _editablePlannedVisitsByDayId.clear();
        _editablePincodes = List<String>.from(beatPlan.pincodes);
        if (beatPlan.dailyPlans != null) {
          for (final dp in beatPlan.dailyPlans!) {
            _editableAreasByDayId[dp.id] = List<String>.from(dp.assignedAreas);
            _editablePlannedVisitsByDayId[dp.id] = dp.plannedVisits;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMissedBeat(String dailyBeatId) async {
    try {
      final result = await BeatPlanService.handleMissedBeat(
        dailyBeatId: dailyBeatId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Missed beat handled successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the details
        await _loadBeatPlanDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to handle missed beat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beat Plan Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_beatPlan != null && !_beatPlan!.isLocked)
            // TextButton(
            //   onPressed: () {
            //     setState(() {
            //       _isEditingDistribution = !_isEditingDistribution;
            //     });
            //   },
            //   child: Text(
            //     _isEditingDistribution ? 'Cancel' : 'Edit',
            //     style: const TextStyle(color: Colors.white),
            //   ),
            // ),
          if (_isEditingDistribution && _beatPlan != null)
            TextButton(
              onPressed: _saveDistributionChanges,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBeatPlanDetails,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading beat plan details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBeatPlanDetails,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_beatPlan == null) {
      return const Center(child: Text('Beat plan not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanOverview(),
          const SizedBox(height: 20),
          _buildDailyPlansSection(),
        ],
      ),
    );
  }

  Widget _buildPlanOverview() {
    final beatPlan = _beatPlan!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beatPlan.salesmanName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        beatPlan.weekDisplayName,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(beatPlan.status),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Accounts',
                    beatPlan.totalAreas.toString(),
                    Icons.people,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completion',
                    '${beatPlan.completionRate}%',
                    Icons.pie_chart,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Assigned Pincodes:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditingDistribution) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._editablePincodes.map(
                    (pincode) => InputChip(
                      label: Text(pincode),
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      onDeleted: () {
                        setState(() {
                          _editablePincodes.remove(pincode);
                        });
                      },
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add pincode'),
                    onPressed: () async {
                      final controller = TextEditingController();
                      final value = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Add Pincode'),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, controller.text.trim()),
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                      if (value == null) return;
                      final trimmed = value.trim();
                      if (trimmed.length != 6 ||
                          int.tryParse(trimmed) == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Enter a valid 6-digit pincode.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      setState(() {
                        if (!_editablePincodes.contains(trimmed)) {
                          _editablePincodes.add(trimmed);
                        }
                      });
                    },
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: beatPlan.pincodes.map((pincode) {
                  return Chip(
                    label: Text(pincode),
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'DRAFT':
        color = Colors.orange;
        break;
      case 'ACTIVE':
        color = Colors.green;
        break;
      case 'LOCKED':
        color = Colors.red;
        break;
      case 'COMPLETED':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPlansSection() {
    final dailyPlans = _beatPlan!.dailyPlans ?? [];

    if (dailyPlans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No daily plans found'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Plans',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_isEditingDistribution) ...[
          const SizedBox(height: 8),
          Text(
            'Adjust auto-distributed areas and planned visits for each day, then tap Save. Locked plans cannot be edited.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
        const SizedBox(height: 16),
        ...dailyPlans.map((dailyPlan) => _buildDailyPlanCard(dailyPlan)),
      ],
    );
  }

  Widget _buildDailyPlanCard(DailyBeatPlan dailyPlan) {
    final int accountCount =
        dailyPlan.accounts?.length ?? dailyPlan.plannedVisits;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyPlan.dayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${dailyPlan.dayDate.day}/${dailyPlan.dayDate.month}/${dailyPlan.dayDate.year}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildDayStatusChip(dailyPlan.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Accounts: $accountCount',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Show accounts for this day
            if (dailyPlan.accounts != null && dailyPlan.accounts!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Accounts (${dailyPlan.accounts!.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: dailyPlan.accounts!.map((accountMap) {
                      final accountName = accountMap['personName'] ??
                          accountMap['businessName'] ??
                          'Unknown';
                      final businessName =
                          accountMap['businessName'] ?? '';
                      final contactNumber =
                          accountMap['contactNumber'] ?? '';
                      final address = accountMap['address'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  accountName.isNotEmpty
                                      ? accountName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (businessName.isNotEmpty &&
                                      businessName != accountName) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      businessName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (contactNumber.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          contactNumber,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            if (dailyPlan.isMissed && !_beatPlan!.isLocked) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleMissedBeat(dailyPlan.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Handle Missed Beat'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PLANNED':
        color = Colors.grey;
        break;
      case 'IN_PROGRESS':
        color = Colors.orange;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'MISSED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _saveDistributionChanges() async {
    if (_beatPlan == null) return;
    final beatPlan = _beatPlan!;

    try {
      final dailyPlansPayload = <Map<String, dynamic>>[];
      if (beatPlan.dailyPlans != null) {
        for (final dp in beatPlan.dailyPlans!) {
          final areas = _editableAreasByDayId[dp.id] ?? dp.assignedAreas;
          final visits =
              _editablePlannedVisitsByDayId[dp.id] ?? dp.plannedVisits;
          dailyPlansPayload.add({
            'id': dp.id,
            'assignedAreas': areas,
            'plannedVisits': visits,
          });
        }
      }

      await BeatPlanService.updateWeeklyBeatPlan(
        beatPlanId: beatPlan.id,
        pincodes: _editablePincodes,
        dailyPlans: dailyPlansPayload,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beat plan updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadBeatPlanDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update beat plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
