import 'package:flutter/material.dart';
import '../../services/map_task_assignment_service.dart';
import 'admin_assignments_map_screen.dart';
import 'assignment_map_detail_screen.dart';

class ViewTasksScreen extends StatefulWidget {
  const ViewTasksScreen({super.key});

  @override
  State<ViewTasksScreen> createState() => _ViewTasksScreenState();
}

class _ViewTasksScreenState extends State<ViewTasksScreen> {
  final _service = MapTaskAssignmentService();
  Map<String, List<Map<String, dynamic>>> _salesmenAssignments = {};
  List<Map<String, dynamic>> _salesmen = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAssignments();
  }

  Future<void> _loadAllAssignments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Get all salesmen first
      final salesmenResult = await _service.fetchSalesmen();
      if (salesmenResult['success'] == true) {
        final salesmen =
            (salesmenResult['salesmen'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        // Fetch assignments for each salesman
        Map<String, List<Map<String, dynamic>>> salesmenAssignments = {};

        for (var salesman in salesmen) {
          final salesmanId = salesman['id'];
          final result = await _service.getAssignmentsBySalesman(salesmanId);

          if (result['success'] == true) {
            final assignments =
                (result['assignments'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

            if (assignments.isNotEmpty) {
              salesmenAssignments[salesmanId] = assignments;
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _salesmen = salesmen
              .where((s) => salesmenAssignments.containsKey(s['id']))
              .toList();
          _salesmenAssignments = salesmenAssignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSalesmen {
    if (_searchQuery.isEmpty) return _salesmen;

    return _salesmen.where((salesman) {
      final name = (salesman['name'] ?? '').toLowerCase();
      final phone = (salesman['contactNumber'] ?? '').toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      return name.contains(searchLower) || phone.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalAssignments = _salesmenAssignments.values.fold<int>(
      0,
      (sum, assignments) => sum + assignments.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.list_alt_outlined, size: 24),
            SizedBox(width: 10),
            Text('Allotments Management'),
          ],
        ),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Map View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAssignmentsMapScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllAssignments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salesmen.isEmpty
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
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by salesman name or phone...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFD7BE69),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD7BE69),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredSalesmen.length} Salesmen',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalAssignments Total Assignments',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: _filteredSalesmen.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No salesmen found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSalesmen.length,
                          itemBuilder: (context, index) {
                            final salesman = _filteredSalesmen[index];
                            final assignments =
                                _salesmenAssignments[salesman['id']] ?? [];
                            return _buildSalesmanCard(salesman, assignments);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSalesmanCard(
    Map<String, dynamic> salesman,
    List<Map<String, dynamic>> assignments,
  ) {
    final totalPincodes = assignments.length;
    final totalAreas = assignments.fold<int>(
      0,
      (sum, a) => sum + ((a['areas'] as List?)?.length ?? 0),
    );
    final totalBusinesses = assignments.fold<int>(
      0,
      (sum, a) => sum + ((a['totalBusinesses'] as int?) ?? 0),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFD7BE69).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFD7BE69),
                  child: Text(
                    (salesman['name'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salesman['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (salesman['contactNumber'] != null)
                        Text(
                          salesman['contactNumber'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.pin_drop,
                  totalPincodes.toString(),
                  'Pincodes',
                ),
                _buildStatItem(
                  Icons.location_on,
                  totalAreas.toString(),
                  'Areas',
                ),
                _buildStatItem(
                  Icons.store,
                  totalBusinesses.toString(),
                  'Businesses',
                ),
              ],
            ),
          ),
          // View All Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _viewAllAssignmentsOnMap(salesman, assignments),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.map, size: 22),
                label: const Text(
                  'View All on Map',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Pincode List
          ExpansionTile(
            title: Text(
              'View Pincodes ($totalPincodes)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: assignments.map((assignment) {
              final areas =
                  (assignment['areas'] as List?)?.cast<String>() ?? [];
              return ListTile(
                leading: const Icon(
                  Icons.location_city,
                  color: Color(0xFFD7BE69),
                ),
                title: Text(
                  '${assignment['city']} - ${assignment['pincode']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${areas.length} areas • ${assignment['totalBusinesses'] ?? 0} businesses',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.map, color: Color(0xFFD7BE69)),
                  onPressed: () =>
                      _viewAssignmentOnMap(assignment, salesman['name']),
                  tooltip: 'View on Map',
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD7BE69), size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD7BE69),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _viewAllAssignmentsOnMap(
    Map<String, dynamic> salesman,
    List<Map<String, dynamic>> assignments,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentMapViewScreen(
          assignment: {
            'salesmanName': salesman['name'],
            'assignments': assignments,
            'isMultiple': true,
          },
          salesmanName: salesman['name'] ?? 'Salesman',
        ),
      ),
    );
  }

  void _viewAssignmentOnMap(
    Map<String, dynamic> assignment,
    String salesmanName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentMapViewScreen(
          assignment: assignment,
          salesmanName: salesmanName,
        ),
      ),
    );
  }
}
