import 'package:flutter/material.dart';
import '../../services/map_task_assignment_service.dart';
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

  Widget _buildPincodeAssignmentSummary() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    // Get all matching pincode assignments
    Map<String, List<String>> pincodeToSalesmen = {};

    for (var salesman in _filteredSalesmen) {
      final assignments = _salesmenAssignments[salesman['id']] ?? [];
      final salesmanName = salesman['name'] ?? 'Unknown';

      for (var assignment in assignments) {
        final pincode = assignment['pincode']?.toString() ?? '';
        final city = assignment['city']?.toString() ?? '';
        final searchLower = _searchQuery.toLowerCase();

        // Check if this assignment matches the search
        if (pincode.toLowerCase().contains(searchLower) ||
            city.toLowerCase().contains(searchLower)) {
          final key = '$city - $pincode';
          if (!pincodeToSalesmen.containsKey(key)) {
            pincodeToSalesmen[key] = [];
          }
          if (!pincodeToSalesmen[key]!.contains(salesmanName)) {
            pincodeToSalesmen[key]!.add(salesmanName);
          }
        }
      }
    }

    if (pincodeToSalesmen.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD7BE69).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD7BE69).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_city,
                size: 16,
                color: Color(0xFFD7BE69),
              ),
              const SizedBox(width: 6),
              Text(
                'Pincode Assignments (${pincodeToSalesmen.length} matches)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD7BE69),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pincodeToSalesmen.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7BE69).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD7BE69),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value.join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getSearchMatchInfo(Map<String, dynamic> salesman) {
    if (_searchQuery.isEmpty) return '';

    final name = (salesman['name'] ?? '').toLowerCase();
    final phone = (salesman['contactNumber'] ?? '').toLowerCase();
    final searchLower = _searchQuery.toLowerCase();

    // Check what matched
    List<String> matches = [];

    if (name.contains(searchLower)) {
      matches.add('name');
    }
    if (phone.contains(searchLower)) {
      matches.add('phone');
    }

    // Check pincode matches
    final assignments = _salesmenAssignments[salesman['id']] ?? [];
    List<String> matchingPincodes = [];
    for (var assignment in assignments) {
      final pincode = (assignment['pincode'] ?? '').toLowerCase();
      final city = (assignment['city'] ?? '').toLowerCase();
      if (pincode.contains(searchLower)) {
        matchingPincodes.add(assignment['pincode']);
      } else if (city.contains(searchLower)) {
        matchingPincodes.add(
          '${assignment['city']} (${assignment['pincode']})',
        );
      }
    }

    if (matchingPincodes.isNotEmpty) {
      matches.add('pincode: ${matchingPincodes.join(', ')}');
    }

    return matches.isNotEmpty ? 'Matches: ${matches.join(', ')}' : '';
  }

  List<Map<String, dynamic>> get _filteredSalesmen {
    if (_searchQuery.isEmpty) return _salesmen;

    return _salesmen.where((salesman) {
      final name = (salesman['name'] ?? '').toLowerCase();
      final phone = (salesman['contactNumber'] ?? '').toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      // Check if name or phone matches
      bool nameOrPhoneMatch =
          name.contains(searchLower) || phone.contains(searchLower);

      // Check if any assigned pincode matches
      bool pincodeMatch = false;
      final assignments = _salesmenAssignments[salesman['id']] ?? [];
      for (var assignment in assignments) {
        final pincode = (assignment['pincode'] ?? '').toLowerCase();
        final city = (assignment['city'] ?? '').toLowerCase();
        if (pincode.contains(searchLower) || city.contains(searchLower)) {
          pincodeMatch = true;
          break;
        }
      }

      return nameOrPhoneMatch || pincodeMatch;
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
          children: [SizedBox(width: 10), Text('Allotments Management')],
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
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, phone, pincode, or city...',
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
                              : IconButton(
                                  icon: const Icon(Icons.help_outline),
                                  onPressed: _showSearchTips,
                                  tooltip: 'Search Tips',
                                ),
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
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Searching across salesman names, phone numbers, assigned pincodes, and cities',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Pincode Assignment Summary (only when searching)
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPincodeAssignmentSummary(),
                  ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD7BE69,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFD7BE69,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFFD7BE69),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Searching: "$_searchQuery"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD7BE69),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _searchQuery = ''),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFFD7BE69),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              color: const Color(0xFFD7BE69).withValues(alpha: 0.1),
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
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getSearchMatchInfo(salesman),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD7BE69),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

              // Check if this pincode/city matches the search query
              final pincode = (assignment['pincode'] ?? '').toLowerCase();
              final city = (assignment['city'] ?? '').toLowerCase();
              final searchLower = _searchQuery.toLowerCase();
              final isHighlighted =
                  _searchQuery.isNotEmpty &&
                  (pincode.contains(searchLower) || city.contains(searchLower));

              return Container(
                color: isHighlighted
                    ? const Color(0xFFD7BE69).withValues(alpha: 0.1)
                    : null,
                child: ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: isHighlighted
                        ? const Color(0xFFD7BE69)
                        : Colors.grey[600],
                  ),
                  title: Text(
                    '${assignment['city']} - ${assignment['pincode']}',
                    style: TextStyle(
                      fontWeight: isHighlighted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isHighlighted ? const Color(0xFFD7BE69) : null,
                    ),
                  ),
                  subtitle: Text(
                    '${areas.length} areas • ${assignment['totalBusinesses'] ?? 0} businesses',
                    style: TextStyle(
                      color: isHighlighted ? Colors.black87 : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.map, color: Color(0xFFD7BE69)),
                    onPressed: () =>
                        _viewAssignmentOnMap(assignment, salesman['name']),
                    tooltip: 'View on Map',
                  ),
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

  void _showSearchTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFFD7BE69)),
            SizedBox(width: 8),
            Text('Search Tips'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can search by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSearchTipItem(
              Icons.person,
              'Salesman Name',
              'e.g., "ramesh", "john"',
            ),
            _buildSearchTipItem(
              Icons.phone,
              'Phone Number',
              'e.g., "9898989898"',
            ),
            _buildSearchTipItem(
              Icons.location_city,
              'Pincode',
              'e.g., "110001", "400001"',
            ),
            _buildSearchTipItem(
              Icons.location_on,
              'City Name',
              'e.g., "delhi", "mumbai"',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Matching pincodes will be highlighted in the results!',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTipItem(IconData icon, String title, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
