import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/beat_plan_model.dart';
import '../../services/beat_plan_service.dart';
import '../../services/user_service.dart';

class TodaysBeatPlanScreen extends StatefulWidget {
  const TodaysBeatPlanScreen({super.key});

  @override
  State<TodaysBeatPlanScreen> createState() => _TodaysBeatPlanScreenState();
}

class _TodaysBeatPlanScreenState extends State<TodaysBeatPlanScreen> {
  TodaysBeatPlan? _todaysPlan;
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadTodaysBeatPlan();
    _getCurrentLocation();
  }

  Future<void> _loadTodaysBeatPlan() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to get from cache first for offline support
      TodaysBeatPlan? cachedPlan =
          await BeatPlanService.getCachedTodaysBeatPlan();

      if (cachedPlan != null) {
        setState(() {
          _todaysPlan = cachedPlan;
          _isLoading = false;
        });
      }

      // Fetch fresh data from API
      final plan = await BeatPlanService.getTodaysBeatPlan();

      if (plan != null) {
        // Cache the fresh data
        await BeatPlanService.cacheTodaysBeatPlan(plan);
      }

      setState(() {
        _todaysPlan = plan;
        _isLoading = false;
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
      print('Error getting location: $e');
    }
  }

  Future<void> _markAreaComplete(String areaName) async {
    if (_todaysPlan?.dailyPlan == null) return;

    try {
      // Show completion dialog
      final result = await _showAreaCompletionDialog(areaName);
      if (result == null) return;

      // Mark area as complete
      await BeatPlanService.markBeatAreaComplete(
        dailyBeatId: _todaysPlan!.dailyPlan!.id,
        areaName: areaName,
        accountsVisited: result['accountsVisited'] ?? 0,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        notes: result['notes'],
      );

      // Refresh the beat plan
      await _loadTodaysBeatPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Area "$areaName" marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark area complete: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text('Complete Area: $areaName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: accountsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Accounts Visited',
                hintText: 'Enter number of accounts visited',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes about this area visit',
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
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Beat Plan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodaysBeatPlan,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading beat plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTodaysBeatPlan,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_todaysPlan == null || !_todaysPlan!.hasBeatPlan) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Beat Plan for Today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your admin hasn\'t assigned a beat plan for today.\nPlease contact your admin.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodaysBeatPlan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanOverview(),
            const SizedBox(height: 20),
            _buildAreasSection(),
            const SizedBox(height: 20),
            _buildAccountsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOverview() {
    final plan = _todaysPlan!;
    final dailyPlan = plan.dailyPlan!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Areas Assigned',
                    plan.totalAreas.toString(),
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    plan.completedAreasCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plan.completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                plan.completionPercentage == 100 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.completionPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAreasSection() {
    final plan = _todaysPlan!;
    final dailyPlan = plan.dailyPlan!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Areas to Visit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dailyPlan.assignedAreas.map((area) => _buildAreaTile(area)),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaTile(String areaName) {
    final isCompleted = _todaysPlan!.completedAreas.contains(areaName);
    final accountsInArea = _todaysPlan!.accounts
        .where((account) => account['area'] == areaName)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCompleted ? Colors.green.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.location_on,
          color: isCompleted ? Colors.green : Colors.orange,
        ),
        title: Text(
          areaName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('$accountsInArea accounts'),
        trailing: isCompleted
            ? Icon(Icons.done, color: Colors.green)
            : ElevatedButton(
                onPressed: () => _markAreaComplete(areaName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Complete'),
              ),
      ),
    );
  }

  Widget _buildAccountsSection() {
    final accounts = _todaysPlan!.accounts;

    if (accounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.business, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No Accounts Found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('No accounts found for today\'s assigned areas.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Accounts to Visit (${accounts.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) => _buildAccountTile(account)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(Map<String, dynamic> account) {
    final areaCompleted = _todaysPlan!.completedAreas.contains(account['area']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: areaCompleted ? Colors.green.withOpacity(0.05) : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: areaCompleted ? Colors.green : Colors.blue,
          child: Text(
            (account['personName'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account['personName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account['businessName'] != null) Text(account['businessName']),
            Text('📞 ${account['contactNumber'] ?? 'No contact'}'),
            Text('📍 ${account['area'] ?? 'No area'}'),
          ],
        ),
        trailing: areaCompleted
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to account details or call
        },
      ),
    );
  }
}
