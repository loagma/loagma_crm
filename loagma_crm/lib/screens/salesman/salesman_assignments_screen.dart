import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import 'salesman_assignments_map_screen.dart';

class SalesmanAssignmentsScreen extends StatefulWidget {
  const SalesmanAssignmentsScreen({super.key});

  @override
  State<SalesmanAssignmentsScreen> createState() =>
      _SalesmanAssignmentsScreenState();
}

class _SalesmanAssignmentsScreenState extends State<SalesmanAssignmentsScreen> {
  List<Map<String, dynamic>> assignments = [];
  bool isLoading = true;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchMyAssignments();
  }

  Future<void> fetchMyAssignments() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments?salesmanId=$userId',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          assignments = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching assignments: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAssignments {
    if (selectedStatus == null) return assignments;
    return assignments.where((a) => a['status'] == selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredAssignments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Area Allotments'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Map View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesmanAssignmentsMapScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMyAssignments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedStatus == null,
                    onSelected: (selected) {
                      setState(() => selectedStatus = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Active'),
                    selected: selectedStatus == 'Active',
                    onSelected: (selected) {
                      setState(
                        () => selectedStatus = selected ? 'Active' : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: selectedStatus == 'Completed',
                    onSelected: (selected) {
                      setState(
                        () => selectedStatus = selected ? 'Completed' : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Inactive'),
                    selected: selectedStatus == 'Inactive',
                    onSelected: (selected) {
                      setState(
                        () => selectedStatus = selected ? 'Inactive' : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFD7BE69).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', assignments.length.toString()),
                _buildStatItem(
                  'Active',
                  assignments
                      .where((a) => a['status'] == 'Active')
                      .length
                      .toString(),
                ),
                _buildStatItem(
                  'Completed',
                  assignments
                      .where((a) => a['status'] == 'Completed')
                      .length
                      .toString(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assignments List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No area allotments found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchMyAssignments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final assignment = filtered[index];
                        return _buildAssignmentCard(assignment);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD7BE69),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final area = assignment['area'];
    final status = assignment['status'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      case 'Inactive':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        area?['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (area?['zone']?['name'] != null)
                        Text(
                          '${area['zone']['name']}, ${area['zone']['city']?['name'] ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (assignment['startDate'] != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Start: ${assignment['startDate'].toString().split('T')[0]}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (assignment['endDate'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'End: ${assignment['endDate'].toString().split('T')[0]}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            if (assignment['notes'] != null) ...[
              const SizedBox(height: 8),
              Text(
                assignment['notes'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
