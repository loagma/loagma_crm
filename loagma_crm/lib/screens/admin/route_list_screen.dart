import 'package:flutter/material.dart';
import '../../services/route_service.dart';
import 'route_visualization_screen.dart';

/// Admin screen for listing attendance sessions with route data
/// Provides overview of all routes and navigation to detailed visualization
class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  List<Map<String, dynamic>> _routeSummary = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String? _selectedEmployeeId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadRouteSummary();
  }

  /// Load route summary from API
  Future<void> _loadRouteSummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await RouteService.getRouteSummary(
        employeeId: _selectedEmployeeId,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );

      if (result['success']) {
        setState(() {
          _routeSummary = List<Map<String, dynamic>>.from(result['data']);
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load route data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading routes: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show date picker for filtering
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFD7BE69)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadRouteSummary();
    }
  }

  /// Clear date filters
  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadRouteSummary();
  }

  /// Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Tracking'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRouteSummary,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter summary
          if (_startDate != null || _endDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtered: ${_startDate != null ? _formatDate(_startDate.toString()) : 'All'} - ${_endDate != null ? _formatDate(_endDate.toString()) : 'All'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearDateFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Route list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD7BE69)),
                        SizedBox(height: 16),
                        Text('Loading routes...'),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRouteSummary,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _routeSummary.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No route data available',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Routes will appear here when salesmen are actively tracking',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRouteSummary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _routeSummary.length,
                      itemBuilder: (context, index) {
                        final route = _routeSummary[index];
                        return _buildRouteCard(route);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build route card
  Widget _buildRouteCard(Map<String, dynamic> route) {
    final hasRoute = route['hasRoute'] == true;
    final status = route['status'] ?? 'unknown';
    final routePointsCount = route['routePointsCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: hasRoute ? () => _navigateToRouteVisualization(route) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Employee info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['employeeName'] ?? 'Unknown Employee',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${_formatDate(route['date'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == 'completed' ? 'Completed' : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Route info row
              Row(
                children: [
                  // Route points
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on,
                      'Route Points',
                      routePointsCount.toString(),
                      hasRoute ? Colors.blue : Colors.grey,
                    ),
                  ),

                  // Work hours
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Work Hours',
                      route['totalWorkHours'] != null
                          ? '${route['totalWorkHours'].toStringAsFixed(1)}h'
                          : 'Ongoing',
                      Colors.green,
                    ),
                  ),

                  // Route status
                  Expanded(
                    child: _buildInfoItem(
                      hasRoute ? Icons.route : Icons.location_disabled,
                      'Route',
                      hasRoute ? 'Available' : 'No Data',
                      hasRoute ? Colors.purple : Colors.grey,
                    ),
                  ),
                ],
              ),

              // Action hint
              if (hasRoute) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view route visualization and playback',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'No route data recorded for this attendance session',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build info item
  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Routes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Start Date'),
              subtitle: Text(
                _startDate != null
                    ? _formatDate(_startDate.toString())
                    : 'All dates',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectDate(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('End Date'),
              subtitle: Text(
                _endDate != null
                    ? _formatDate(_endDate.toString())
                    : 'All dates',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectDate(false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearDateFilters();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Navigate to route visualization
  void _navigateToRouteVisualization(Map<String, dynamic> route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteVisualizationScreen(
          attendanceId: route['attendanceId'],
          employeeName: route['employeeName'],
        ),
      ),
    );
  }
}
