import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/account_service.dart';
import 'customer_beat_plan_screen.dart';

/// Shows which customers are allotted to which salesman.
/// Admin can see salesman ↔ customer allotment and create beat plans.
class SalesmanAllotmentScreen extends StatefulWidget {
  const SalesmanAllotmentScreen({super.key});

  @override
  State<SalesmanAllotmentScreen> createState() => _SalesmanAllotmentScreenState();
}

class _SalesmanAllotmentScreenState extends State<SalesmanAllotmentScreen> {
  List<Map<String, dynamic>> _salesmen = [];
  Map<String, int> _allotmentCounts = {};
  bool _isLoading = true;
  String? _error;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usersResult = await UserService.getAllUsers();
      if (usersResult['success'] != true) {
        throw Exception(usersResult['message'] ?? 'Failed to load users');
      }

      final users = (usersResult['data'] as List<dynamic>)
          .map((u) => Map<String, dynamic>.from(u))
          .toList();

      // Filter salesmen
      final salesmen = users.where((u) {
        final role = (u['role'] ?? '').toString().toLowerCase();
        return role.contains('sales') ||
            role.contains('salesman') ||
            role.contains('sr') ||
            role.contains('tso');
      }).toList();

      // Get allotment count per salesman
      final counts = <String, int>{};
      for (final s in salesmen) {
        final id = s['id'] ?? s['_id'] ?? '';
        if (id.isEmpty) continue;
        try {
          final result = await AccountService.fetchAccounts(
            assignedToId: id,
            limit: 1,
            page: 1,
          );
          final pagination = result['pagination'];
          counts[id] = (pagination is Map && pagination['total'] != null)
              ? (pagination['total'] as num).toInt()
              : 0;
        } catch (_) {
          counts[id] = 0;
        }
      }

      if (!mounted) return;
      setState(() {
        _salesmen = salesmen;
        _allotmentCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openCreateBeatPlan(Map<String, dynamic> salesman) {
    final id = salesman['id'] ?? salesman['_id'] ?? '';
    final name = salesman['name'] ?? 'Salesman';
    if (id.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerBeatPlanScreen(
          salesmanId: id,
          salesmanName: name,
          allottedCount: _allotmentCounts[id] ?? 0,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beat Plan — Salesmen'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
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
            Text('Loading allotment...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_salesmen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No salesmen found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create employees with Salesman role first',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _salesmen.length,
        itemBuilder: (context, index) {
          final s = _salesmen[index];
          final id = s['id'] ?? s['_id'] ?? '';
          final name = s['name'] ?? 'Unknown';
          final code = s['employeeCode'] ?? s['contactNumber'] ?? '';
          final count = _allotmentCounts[id] ?? 0;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: count > 0 ? () => _openCreateBeatPlan(s) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (code.isNotEmpty)
                                Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count customers',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: count > 0 ? () => _openCreateBeatPlan(s) : null,
                        icon: const Icon(Icons.calendar_view_week, size: 18),
                        label: Text(
                          count > 0
                              ? 'Create Beat Plan ($count customers)'
                              : 'No customers allotted yet',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
