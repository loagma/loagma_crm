import 'package:flutter/material.dart';
import '../models/leave_model.dart';

class LeaveBalanceCard extends StatelessWidget {
  final LeaveStatistics statistics;

  const LeaveBalanceCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final balance = statistics.balance;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD7BE69).withValues(alpha: 0.1),
              const Color(0xFFD7BE69).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7BE69),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Balance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Year ${balance.year}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (statistics.pendingRequests > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${statistics.pendingRequests} pending',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Leave Types
            Row(
              children: [
                Expanded(
                  child: _buildLeaveTypeCard(
                    'Sick Leave',
                    balance.availableSickLeaves,
                    balance.sickLeaves,
                    Colors.blue,
                    Icons.local_hospital,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLeaveTypeCard(
                    'Casual Leave',
                    balance.availableCasualLeaves,
                    balance.casualLeaves,
                    Colors.green,
                    Icons.beach_access,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLeaveTypeCard(
                    'Earned Leave',
                    balance.availableEarnedLeaves,
                    balance.earnedLeaves,
                    Colors.purple,
                    Icons.star,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Available',
                    balance.totalAvailableLeaves.toString(),
                    Colors.green,
                  ),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _buildSummaryItem(
                    'Used This Year',
                    balance.totalUsedLeaves.toString(),
                    Colors.orange,
                  ),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _buildSummaryItem(
                    'Total Allocated',
                    balance.totalAllocatedLeaves.toString(),
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeCard(
    String title,
    int available,
    int total,
    Color color,
    IconData icon,
  ) {
    final used = total - available;
    final percentage = total > 0 ? (used / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            available.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
          const SizedBox(height: 2),
          Text(
            '$used/$total used',
            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
