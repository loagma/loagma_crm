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

  @override
  void initState() {
    super.initState();
    fetchMyAssignments();
  }

  Future<void> fetchMyAssignments() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;

      if (userId == null || userId.isEmpty) {
        print('❌ User ID is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      print('📡 Fetching assignments for user: $userId');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/task-assignments/assignments/salesman/$userId',
      );

      print('📡 URL: $url');

      final response = await http.get(url);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          assignments = List<Map<String, dynamic>>.from(
            data['assignments'] ?? [],
          );
        });
        print('✅ Loaded ${assignments.length} assignments');
      } else {
        print('❌ API returned success: false');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to load assignments'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error fetching assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAssignments {
    return assignments;
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
          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD7BE69), Color(0xFFE8D699)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD7BE69).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Areas',
                  assignments.length.toString(),
                  Icons.location_city,
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatItem(
                  'Total Shops',
                  assignments
                      .fold<int>(
                        0,
                        (sum, a) => sum + (a['totalBusinesses'] as int? ?? 0),
                      )
                      .toString(),
                  Icons.store,
                ),
              ],
            ),
          ),

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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final pincode = assignment['pincode'] ?? 'N/A';
    final city = assignment['city'] ?? '';
    final state = assignment['state'] ?? '';
    final areas = assignment['areas'] as List<dynamic>? ?? [];
    final businessTypes = assignment['businessTypes'] as List<dynamic>? ?? [];
    final totalBusinesses = assignment['totalBusinesses'] ?? 0;
    final assignedDate = assignment['assignedDate'] ?? assignment['createdAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Pincode
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7BE69).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFD7BE69),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pincode: $pincode',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (city.isNotEmpty || state.isNotEmpty)
                        Text(
                          [city, state].where((s) => s.isNotEmpty).join(', '),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalBusinesses Shops',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Areas
            if (areas.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Areas (${areas.length}):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: areas.take(5).map((area) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                area.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[900],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (areas.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${areas.length - 5} more',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Business Types
            if (businessTypes.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Types:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: businessTypes.map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Text(
                                type.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[900],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Assigned Date and View on Map Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (assignedDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned: ${assignedDate.toString().split('T')[0]}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SalesmanAssignmentsMapScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD7BE69),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
