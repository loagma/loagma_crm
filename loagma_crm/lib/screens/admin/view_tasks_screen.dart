import 'package:flutter/material.dart';
import '../../services/map_task_assignment_service.dart';

class ViewTasksScreen extends StatefulWidget {
  const ViewTasksScreen({super.key});

  @override
  State<ViewTasksScreen> createState() => _ViewTasksScreenState();
}

class _ViewTasksScreenState extends State<ViewTasksScreen> {
  final _service = MapTaskAssignmentService();
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAssignments();
  }

  Future<void> _loadAllAssignments() async {
    setState(() => _isLoading = true);
    try {
      // Get all salesmen first
      final salesmenResult = await _service.fetchSalesmen();
      if (salesmenResult['success'] == true) {
        final salesmen = salesmenResult['salesmen'] as List;

        // Fetch assignments for each salesman
        List<Map<String, dynamic>> allAssignments = [];
        for (var salesman in salesmen) {
          final result = await _service.getAssignmentsBySalesman(
            salesman['id'],
          );
          if (result['success'] == true) {
            final assignments = result['assignments'] as List;
            for (var assignment in assignments) {
              allAssignments.add({
                ...assignment,
                'salesmanName': salesman['name'],
                'salesmanPhone': salesman['contactNumber'],
              });
            }
          }
        }

        setState(() {
          _assignments = allAssignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.list_alt_outlined, size: 24),
            SizedBox(width: 10),
            Text('View All Assignments'),
          ],
        ),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllAssignments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No assignments found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create assignments from Task Assignment screen',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${_assignments.length} Assignments',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      return _buildAssignmentCard(assignment);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final areas = (assignment['areas'] as List?)?.cast<String>() ?? [];
    final businessTypes =
        (assignment['businessTypes'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFD7BE69),
                  child: Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${assignment['city']}, ${assignment['state']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pincode: ${assignment['pincode']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Salesman
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  assignment['salesmanName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Areas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Areas: ${areas.join(', ')}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Business Types
            if (businessTypes.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Types: ${businessTypes.join(', ')}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Total Businesses
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Total Businesses: ${assignment['totalBusinesses'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date
            if (assignment['assignedDate'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned: ${DateTime.parse(assignment['assignedDate']).toString().split(' ')[0]}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
