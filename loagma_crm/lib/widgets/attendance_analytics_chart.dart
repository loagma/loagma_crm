import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceAnalyticsChart extends StatelessWidget {
  final List<dynamic> dailyAnalytics;
  final String title;

  const AttendanceAnalyticsChart({
    super.key,
    required this.dailyAnalytics,
    this.title = 'Attendance Analytics',
  });

  @override
  Widget build(BuildContext context) {
    if (dailyAnalytics.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No analytics data available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dailyAnalytics.map((dayData) {
                  return _buildDayBar(dayData);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildDayBar(dynamic dayData) {
    final date = DateTime.parse(dayData['date']);
    final totalEmployees = (dayData['totalEmployees'] ?? 0).toDouble();
    final completedEmployees = (dayData['completedEmployees'] ?? 0).toDouble();
    final activeEmployees = (dayData['activeEmployees'] ?? 0).toDouble();

    final maxHeight = 120.0;
    final totalHeight = totalEmployees > 0 ? maxHeight : 10.0;
    final completedHeight = totalEmployees > 0
        ? (completedEmployees / totalEmployees) * maxHeight
        : 0.0;
    final activeHeight = totalEmployees > 0
        ? (activeEmployees / totalEmployees) * maxHeight
        : 0.0;

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Total bar (background)
                Container(
                  width: 30,
                  height: totalHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Completed bar
                Container(
                  width: 30,
                  height: completedHeight,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Active bar (on top of completed)
                Positioned(
                  bottom: completedHeight,
                  child: Container(
                    width: 30,
                    height: activeHeight,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd').format(date),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('MMM').format(date),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Completed', Colors.green),
        const SizedBox(width: 16),
        _buildLegendItem('Active', Colors.orange),
        const SizedBox(width: 16),
        _buildLegendItem('Total', Colors.grey[300]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
