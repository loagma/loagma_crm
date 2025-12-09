import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';

class SalesmanAttendanceHistoryScreen extends StatefulWidget {
  const SalesmanAttendanceHistoryScreen({super.key});

  @override
  State<SalesmanAttendanceHistoryScreen> createState() =>
      _SalesmanAttendanceHistoryScreenState();
}

class _SalesmanAttendanceHistoryScreenState
    extends State<SalesmanAttendanceHistoryScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  List<AttendanceModel> attendances = [];
  bool isLoading = false;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;

  // Stats
  Map<String, dynamic>? stats;
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
    _loadStats();
  }

  Future<void> _loadAttendanceHistory({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final employeeId = UserService.userId;
      if (employeeId == null) {
        _showError('Employee ID not found');
        return;
      }

      final response = await AttendanceService.getAttendanceHistory(
        employeeId: employeeId,
        page: loadMore ? currentPage + 1 : 1,
        limit: 30,
      );

      if (response['success'] == true) {
        final newAttendances = response['data'] as List<AttendanceModel>;
        final pagination = response['pagination'];

        setState(() {
          if (loadMore) {
            attendances.addAll(newAttendances);
            currentPage++;
          } else {
            attendances = newAttendances;
            currentPage = 1;
          }
          totalPages = pagination['totalPages'] ?? 1;
          hasMore = currentPage < totalPages;
        });
      }
    } catch (e) {
      _showError('Failed to load attendance history');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => isLoadingStats = true);

    try {
      final employeeId = UserService.userId;
      if (employeeId == null) return;

      final now = DateTime.now();
      final response = await AttendanceService.getAttendanceStats(
        employeeId: employeeId,
        month: now.month,
        year: now.year,
      );

      if (response['success'] == true) {
        setState(() => stats = response['data']);
      }
    } catch (e) {
      print('Failed to load stats: $e');
    } finally {
      setState(() => isLoadingStats = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDuration(double? hours) {
    if (hours == null) return '--:--';
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAttendanceHistory();
          await _loadStats();
        },
        child: CustomScrollView(
          slivers: [
            // Stats Section
            SliverToBoxAdapter(child: _buildStatsSection()),

            // Attendance List
            if (isLoading && attendances.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (attendances.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == attendances.length) {
                    if (hasMore) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () =>
                                _loadAttendanceHistory(loadMore: true),
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 80);
                  }

                  final attendance = attendances[index];
                  return _buildAttendanceCard(attendance);
                }, childCount: attendances.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (isLoadingStats) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month (${DateFormat('MMMM yyyy').format(DateTime.now())})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Days',
                  '${stats!['totalDays']}',
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Hours',
                  '${stats!['totalWorkHours']?.toStringAsFixed(1) ?? '0'}h',
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Distance',
                  '${stats!['totalDistance']?.toStringAsFixed(1) ?? '0'}km',
                  Icons.directions_car,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final isCompleted = attendance.isPunchedOut;
    final date = DateFormat('EEE, MMM dd, yyyy').format(attendance.punchInTime);
    final punchInTime = DateFormat('hh:mm a').format(attendance.punchInTime);
    final punchOutTime = attendance.punchOutTime != null
        ? DateFormat('hh:mm a').format(attendance.punchOutTime!)
        : '--:--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green[50] : Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isCompleted ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Colors.green[900]
                          : Colors.orange[900],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        'Punch In',
                        punchInTime,
                        Icons.login,
                        Colors.green,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildTimeInfo(
                        'Punch Out',
                        punchOutTime,
                        Icons.logout,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        Icons.timer,
                        _formatDuration(attendance.totalWorkHours),
                        'Duration',
                      ),
                      _buildInfoChip(
                        Icons.directions_car,
                        '${attendance.totalDistanceKm?.toStringAsFixed(2) ?? '0'} km',
                        'Distance',
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
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          time,
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

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
