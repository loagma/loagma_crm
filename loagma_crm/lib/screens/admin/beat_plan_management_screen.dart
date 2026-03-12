import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/beat_plan_model.dart';
import '../../services/beat_plan_service.dart';
import 'beat_plan_details_screen.dart';

class BeatPlanManagementScreen extends StatefulWidget {
  const BeatPlanManagementScreen({super.key});

  @override
  State<BeatPlanManagementScreen> createState() =>
      _BeatPlanManagementScreenState();
}

class _BeatPlanManagementScreenState extends State<BeatPlanManagementScreen> {
  List<WeeklyBeatPlan> _beatPlans = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Theme colors - matching existing app
  static const Color primaryColor = Color(0xFFD7BE69);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBeatPlans();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreBeatPlans();
      }
    }
  }

  Future<void> _loadBeatPlans({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _currentPage = 1;
          _beatPlans.clear();
          _hasMoreData = true;
        });
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await BeatPlanService.getWeeklyBeatPlans(
        page: _currentPage,
        limit: 10,
      );

      final newBeatPlans = result['beatPlans'] as List<WeeklyBeatPlan>;
      final pagination = result['pagination'];

      setState(() {
        if (refresh || _currentPage == 1) {
          _beatPlans = newBeatPlans;
        } else {
          _beatPlans.addAll(newBeatPlans);
        }
        _hasMoreData = _currentPage < pagination['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      String message = e.toString();
      // Friendlier message for permission issues
      final lower = message.toLowerCase();
      if (lower.contains('permission') ||
          lower.contains('forbidden') ||
          lower.contains('403')) {
        message =
            'You do not have access to manage beat plans. Please log in as Admin, Tele Admin, or Manager.';
      }
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBeatPlans() async {
    _currentPage++;
    await _loadBeatPlans();
  }

  Future<void> _deleteBeatPlan(WeeklyBeatPlan beatPlan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Beat Plan?'),
        content: Text(
          'Delete beat plan for ${beatPlan.salesmanName}?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BeatPlanService.deleteBeatPlan(beatPlan.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beat plan deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBeatPlans(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Beat Plan Management'),
        backgroundColor: primaryColor,
        foregroundColor: const Color.fromARGB(179, 9, 9, 9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBeatPlans(refresh: true),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/dashboard/admin/beat-plans/select-accounts');
          if (mounted) _loadBeatPlans(refresh: true);
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Select accounts'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _beatPlans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Loading beat plans...'),
          ],
        ),
      );
    }

    if (_error != null && _beatPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Error loading beat plans',
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
                onPressed: () => _loadBeatPlans(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_beatPlans.isEmpty) {
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
                child: const Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Beat Plans Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first beat plan by tapping the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBeatPlans(refresh: true),
      color: primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 1 + _beatPlans.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              color: primaryColor.withValues(alpha: 0.08),
              margin: const EdgeInsets.only(bottom: 16),
            );
          }
          if (index == _beatPlans.length + 1) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );
          }
          return _buildBeatPlanCard(_beatPlans[index - 1]);
        },
      ),
    );
  }

  Widget _buildBeatPlanCard(WeeklyBeatPlan beatPlan) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      beatPlan.salesmanName.isNotEmpty
                          ? beatPlan.salesmanName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beatPlan.salesmanName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        beatPlan.weekDisplayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatItem(
                  '${beatPlan.totalAreas}',
                  'Accounts',
                  Icons.people,
                  primaryColor,
                ),
                _buildStatItem(
                  '${beatPlan.completionRate}%',
                  'Done',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  '${beatPlan.pincodes.length}',
                  'Pincodes',
                  Icons.pin_drop,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Day Distribution Preview
          if (beatPlan.dailyPlans != null && beatPlan.dailyPlans!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(7, (index) {
                  final dayOfWeek = index + 1; // 1=Mon .. 7=Sun
                  final dayPlan = beatPlan.dailyPlans!.firstWhere(
                    (dp) => dp.dayOfWeek == dayOfWeek,
                    orElse: () => DailyBeatPlan(
                      id: '',
                      weeklyBeatId: '',
                      dayOfWeek: dayOfWeek,
                      dayDate: DateTime.now(),
                      assignedAreas: const [],
                      plannedVisits: 0,
                      actualVisits: 0,
                      status: 'PLANNED',
                    ),
                  );
                  final areaCount = dayPlan.assignedAreas.length;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: areaCount > 0
                            ? primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayNames[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$areaCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: areaCount > 0 ? primaryColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BeatPlanDetailsScreen(beatPlanId: beatPlan.id),
                        ),
                      );
                      if (result == true) {
                        _loadBeatPlans(refresh: true);
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteBeatPlan(beatPlan),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$num',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
