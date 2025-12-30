import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/beat_plan_model.dart';
import '../../services/beat_plan_service.dart';

class TodaysBeatPlanScreen extends StatefulWidget {
  const TodaysBeatPlanScreen({super.key});

  @override
  State<TodaysBeatPlanScreen> createState() => _TodaysBeatPlanScreenState();
}

class _TodaysBeatPlanScreenState extends State<TodaysBeatPlanScreen> {
  TodaysBeatPlan? _todaysPlan;
  WeeklyBeatPlan? _weeklyPlan;
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  int _selectedDayIndex = -1; // -1 means today

  // Theme colors - matching existing app
  static const Color primaryColor = Color(0xFFD7BE69);
  static const Color secondaryColor = Color(0xFFB8A054);

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _loadBeatPlan();
    _getCurrentLocation();
  }

  Future<void> _loadBeatPlan() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load this week's beat plan
      final weeklyPlan = await BeatPlanService.getThisWeeksBeatPlan();

      // Also try to get today's specific plan
      final todaysPlan = await BeatPlanService.getTodaysBeatPlan();

      setState(() {
        _weeklyPlan = weeklyPlan;
        _todaysPlan = todaysPlan;
        _isLoading = false;

        // Set selected day to today
        final today = DateTime.now().weekday;
        if (today >= 1 && today <= 6) {
          _selectedDayIndex = today - 1;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _markAreaComplete(String areaName, String dailyBeatId) async {
    try {
      final result = await _showAreaCompletionDialog(areaName);
      if (result == null) return;

      await BeatPlanService.markBeatAreaComplete(
        dailyBeatId: dailyBeatId,
        areaName: areaName,
        accountsVisited: result['accountsVisited'] ?? 0,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        notes: result['notes'],
      );

      await _loadBeatPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$areaName" marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showAreaCompletionDialog(
    String areaName,
  ) async {
    final accountsController = TextEditingController();
    final notesController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete: $areaName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: accountsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Accounts Visited',
                hintText: 'How many accounts did you visit?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'accountsVisited': int.tryParse(accountsController.text) ?? 0,
                'notes': notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text(
              'Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Beat Plan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBeatPlan),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Loading your beat plan...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_weeklyPlan == null && _todaysPlan == null) {
      return _buildNoPlanState();
    }

    return RefreshIndicator(
      onRefresh: _loadBeatPlan,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildWeekHeader(),
            _buildDaySelector(),
            _buildSelectedDayContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBeatPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlanState() {
    final today = DateTime.now();
    final isSunday = today.weekday == 7;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSunday ? Icons.weekend : Icons.calendar_today,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSunday ? 'It\'s Sunday!' : 'No Beat Plan This Week',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isSunday
                  ? 'Enjoy your day off! Beat plans are for Monday-Saturday.'
                  : 'Your admin hasn\'t assigned a beat plan for this week yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadBeatPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final weekStart =
        _weeklyPlan?.weekStartDate ??
        BeatPlanService.getWeekStartDate(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 5)); // Saturday

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week\'s Beat Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderStat(
                'Total Areas',
                '${_weeklyPlan?.totalAreas ?? 0}',
                Icons.location_on_outlined,
              ),
              const SizedBox(width: 32),
              _buildHeaderStat('Days', '6', Icons.calendar_view_week_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final today = DateTime.now().weekday;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(6, (index) {
            final isSelected = _selectedDayIndex == index;
            final isToday = (index + 1) == today;
            final dayNumber = index + 1;

            // Get areas for this day
            final dailyPlan = _weeklyPlan?.dailyPlans?.firstWhere(
              (dp) => dp.dayOfWeek == dayNumber,
              orElse: () => DailyBeatPlan(
                id: '',
                weeklyBeatId: '',
                dayOfWeek: dayNumber,
                dayDate: DateTime.now(),
                assignedAreas: [],
                plannedVisits: 0,
                actualVisits: 0,
                status: 'PLANNED',
              ),
            );

            final areaCount = dailyPlan?.assignedAreas.length ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isToday
                              ? primaryColor.withValues(alpha: 0.1)
                              : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: primaryColor, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _dayNames[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isToday ? primaryColor : Colors.grey[700]),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$areaCount',
                          style: TextStyle(
                            color: isSelected ? Colors.white : primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedDayContent() {
    final dayNumber = _selectedDayIndex + 1;
    final dailyPlan = _weeklyPlan?.dailyPlans?.firstWhere(
      (dp) => dp.dayOfWeek == dayNumber,
      orElse: () => DailyBeatPlan(
        id: '',
        weeklyBeatId: '',
        dayOfWeek: dayNumber,
        dayDate: DateTime.now(),
        assignedAreas: [],
        plannedVisits: 0,
        actualVisits: 0,
        status: 'PLANNED',
      ),
    );

    final areas = dailyPlan?.assignedAreas ?? [];
    final completedAreas =
        dailyPlan?.beatCompletions?.map((bc) => bc.areaName).toList() ?? [];
    final isToday = (dayNumber) == DateTime.now().weekday;

    if (areas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No areas assigned for ${_dayNames[_selectedDayIndex]}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_dayNames[_selectedDayIndex]}\'s Areas',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isToday ? 'TODAY' : '${areas.length} areas',
                  style: TextStyle(
                    color: isToday ? Colors.green : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...areas.map((area) {
            final isCompleted = completedAreas.contains(area);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.3)
                      : primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Area icon/status
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.location_on_rounded,
                        color: isCompleted ? Colors.green : primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Area details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? Colors.grey[600]
                                  : Colors.black87,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.verified : Icons.schedule,
                                size: 14,
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'Completed ✓' : 'Pending visit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted
                                      ? Colors.green
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    if (isToday &&
                        !isCompleted &&
                        dailyPlan?.id != null &&
                        dailyPlan!.id.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () =>
                              _markAreaComplete(area, dailyPlan.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (completedAreas.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress Today',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${completedAreas.length}/${areas.length} areas completed',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${((completedAreas.length / areas.length) * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: completedAreas.length / areas.length,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
