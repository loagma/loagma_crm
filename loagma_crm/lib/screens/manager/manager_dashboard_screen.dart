import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/account_service.dart';
import '../../services/user_service.dart';

/// Manager dashboard: Reminder Calls first, Create Task second - matching app theme
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _reminderCount = 0;
  bool _isLoading = true;
  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _loadReminderCount();
  }

  Future<void> _loadReminderCount() async {
    setState(() => _isLoading = true);
    try {
      final result = await AccountService.fetchAccounts(
        funnelStage: 'Follow-up',
        limit: 1,
        page: 1,
      );
      if (!mounted) return;
      final pagination = result['pagination'];
      int total = 0;
      if (pagination is Map && pagination['total'] != null) {
        total = (pagination['total'] as num).toInt();
      }
      setState(() {
        _reminderCount = total;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildReminderCard(),
          const SizedBox(height: 16),
          _buildCreateTaskCard(),
          const SizedBox(height: 16),
          _buildOtherCards(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manager Dashboard',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (UserService.name != null) ...[
            const SizedBox(height: 4),
            Text(
              'Welcome, ${UserService.name}!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/dashboard/manager/reminder-calls'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.phone_callback, size: 40, color: primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reminder Calls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : '$_reminderCount accounts need follow-up',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTaskCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/dashboard/manager/create-task'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.task_alt, size: 40, color: primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assign tasks to salesmen & other roles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMiniCard(
          'View Accounts',
          Icons.people_outline,
          () => context.go('/dashboard/manager/account/all'),
        ),
        _buildMiniCard(
          'Task Allotments',
          Icons.route_outlined,
          () => context.go('/dashboard/manager/tasks/view'),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
