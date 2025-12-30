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
                    'Total Areas',
                    beatPlan.totalAreas.toString(),
                    Icons.location_on,
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
            const Text(
              'Assigned Pincodes:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        ...dailyPlans.map((dailyPlan) => _buildDailyPlanCard(dailyPlan)),
      ],
    );
  }

  Widget _buildDailyPlanCard(DailyBeatPlan dailyPlan) {
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
            Row(
              children: [
                Expanded(
                  child: _buildDayStatItem(
                    'Areas',
                    dailyPlan.totalAreasCount.toString(),
                    Icons.location_on,
                    primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildDayStatItem(
                    'Completed',
                    dailyPlan.completedAreasCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDayStatItem(
                    'Visits',
                    '${dailyPlan.actualVisits}/${dailyPlan.plannedVisits}',
                    Icons.business,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: dailyPlan.completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                dailyPlan.completionPercentage == 100
                    ? Colors.green
                    : primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${dailyPlan.completionPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (dailyPlan.assignedAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Assigned Areas:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dailyPlan.assignedAreas.map((area) {
                  final isCompleted = dailyPlan.completedAreas.contains(area);
                  return Chip(
                    label: Text(area),
                    backgroundColor: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    avatar: Icon(
                      isCompleted ? Icons.check_circle : Icons.location_on,
                      size: 16,
                      color: isCompleted ? Colors.green : Colors.grey,
                    ),
                  );
                }).toList(),
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

  Widget _buildDayStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
