import 'package:flutter/material.dart';
import '../../models/beat_plan_model.dart';
import '../../services/beat_plan_service.dart';
import '../../services/user_service.dart';
import 'generate_beat_plan_screen.dart';
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
  String? _selectedStatus;
  String? _selectedSalesman;

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
        status: _selectedStatus,
        salesmanId: _selectedSalesman,
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
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBeatPlans() async {
    _currentPage++;
    await _loadBeatPlans();
  }

  Future<void> _toggleBeatPlanLock(WeeklyBeatPlan beatPlan, bool lock) async {
    try {
      await BeatPlanService.toggleBeatPlanLock(
        beatPlanId: beatPlan.id,
        lock: lock,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Beat plan ${lock ? 'locked' : 'unlocked'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      await _loadBeatPlans(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${lock ? 'lock' : 'unlock'} beat plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBeatPlanStatus(
    WeeklyBeatPlan beatPlan,
    String newStatus,
  ) async {
    try {
      await BeatPlanService.updateWeeklyBeatPlan(
        beatPlanId: beatPlan.id,
        status: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beat plan status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      await _loadBeatPlans(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update beat plan status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Beat Plans'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'LOCKED', child: Text('Locked')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // TODO: Add salesman dropdown when user list is available
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedSalesman = null;
              });
              Navigator.pop(context);
              _loadBeatPlans(refresh: true);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadBeatPlans(refresh: true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beat Plan Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBeatPlans(refresh: true),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GenerateBeatPlanScreen(),
            ),
          );

          if (result == true) {
            _loadBeatPlans(refresh: true);
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _beatPlans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _beatPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading beat plans',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadBeatPlans(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_beatPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Beat Plans Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Create your first beat plan by tapping the + button.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBeatPlans(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _beatPlans.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _beatPlans.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildBeatPlanCard(_beatPlans[index]);
        },
      ),
    );
  }

  Widget _buildBeatPlanCard(WeeklyBeatPlan beatPlan) {
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
                        beatPlan.salesmanName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        beatPlan.weekDisplayName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(beatPlan.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Areas',
                    beatPlan.totalAreas.toString(),
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completion',
                    '${beatPlan.completionRate}%',
                    Icons.pie_chart,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pincodes',
                    beatPlan.pincodes.length.toString(),
                    Icons.pin_drop,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (!beatPlan.isLocked) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showActionMenu(beatPlan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Actions'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _toggleBeatPlanLock(beatPlan, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Unlock'),
                    ),
                  ),
                ],
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(
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

  void _showActionMenu(WeeklyBeatPlan beatPlan) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.green),
            title: const Text('Activate Plan'),
            onTap: () {
              Navigator.pop(context);
              _updateBeatPlanStatus(beatPlan, 'ACTIVE');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Lock Plan'),
            onTap: () {
              Navigator.pop(context);
              _toggleBeatPlanLock(beatPlan, true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.blue),
            title: const Text('Mark Complete'),
            onTap: () {
              Navigator.pop(context);
              _updateBeatPlanStatus(beatPlan, 'COMPLETED');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.grey),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
