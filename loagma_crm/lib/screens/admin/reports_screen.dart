import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/api_config.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;
  String? errorMessage;

  // Data
  List<Map<String, dynamic>> salesmenPerformance = [];
  List<Map<String, dynamic>> recentAccounts = [];
  Map<String, dynamic> statistics = {};

  // Filters
  String selectedPeriod = 'today'; // today, week, month, all
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Calculate date range based on selected period
      DateTime now = DateTime.now();
      DateTime start;

      switch (selectedPeriod) {
        case 'today':
          start = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        default:
          start = DateTime(2020, 1, 1); // All time
      }

      if (startDate != null) start = startDate!;
      DateTime end = endDate ?? now;

      // Fetch accounts data
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/accounts'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<Map<String, dynamic>> allAccounts =
              List<Map<String, dynamic>>.from(data['data'] ?? []);

          // Filter by date range
          List<Map<String, dynamic>> filteredAccounts = allAccounts.where((
            account,
          ) {
            if (account['createdAt'] == null) return false;
            DateTime createdAt = DateTime.parse(account['createdAt']);
            return createdAt.isAfter(start) &&
                createdAt.isBefore(end.add(const Duration(days: 1)));
          }).toList();

          // Calculate statistics
          _calculateStatistics(filteredAccounts, allAccounts);

          // Group by salesman
          _groupBySalesman(filteredAccounts);

          // Get recent accounts
          recentAccounts = filteredAccounts
            ..sort(
              (a, b) => DateTime.parse(
                b['createdAt'],
              ).compareTo(DateTime.parse(a['createdAt'])),
            );

          if (recentAccounts.length > 50) {
            recentAccounts = recentAccounts.sublist(0, 50);
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading reports: $e';
      });
    }
  }

  void _calculateStatistics(
    List<Map<String, dynamic>> filtered,
    List<Map<String, dynamic>> all,
  ) {
    statistics = {
      'totalAccounts': all.length,
      'newAccounts': filtered.length,
      'activeAccounts': filtered.where((a) => a['isActive'] == true).length,
      'approvedAccounts': filtered.where((a) => a['isApproved'] == true).length,
      'pendingAccounts': filtered.where((a) => a['isApproved'] == false).length,
      'uniqueSalesmen': filtered.map((a) => a['createdBy']).toSet().length,
    };
  }

  void _groupBySalesman(List<Map<String, dynamic>> accounts) {
    Map<String, Map<String, dynamic>> salesmenMap = {};

    for (var account in accounts) {
      String salesmanId = account['createdBy'] ?? 'Unknown';
      String salesmanName = account['createdByName'] ?? 'Unknown';

      if (!salesmenMap.containsKey(salesmanId)) {
        salesmenMap[salesmanId] = {
          'id': salesmanId,
          'name': salesmanName,
          'totalAccounts': 0,
          'activeAccounts': 0,
          'approvedAccounts': 0,
          'accounts': <Map<String, dynamic>>[],
        };
      }

      salesmenMap[salesmanId]!['totalAccounts']++;
      if (account['isActive'] == true)
        salesmenMap[salesmanId]!['activeAccounts']++;
      if (account['isApproved'] == true)
        salesmenMap[salesmanId]!['approvedAccounts']++;
      salesmenMap[salesmanId]!['accounts'].add(account);
    }

    salesmenPerformance = salesmenMap.values.toList()
      ..sort(
        (a, b) =>
            (b['totalAccounts'] as int).compareTo(a['totalAccounts'] as int),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Reports'),
        backgroundColor: const Color(0xFFD7BE69),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Salesmen'),
            Tab(icon: Icon(Icons.map), text: 'Map View'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  )
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReports,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesmenTab(),
                      _buildMapTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'today', label: Text('Today')),
                    ButtonSegment(value: 'week', label: Text('Week')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                    ButtonSegment(value: 'all', label: Text('All')),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      selectedPeriod = newSelection.first;
                      startDate = null;
                      endDate = null;
                    });
                    _loadReports();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadReports,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'New Accounts',
                statistics['newAccounts']?.toString() ?? '0',
                Icons.add_business,
                Colors.blue,
              ),
              _buildStatCard(
                'Active',
                statistics['activeAccounts']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Approved',
                statistics['approvedAccounts']?.toString() ?? '0',
                Icons.verified,
                Colors.purple,
              ),
              _buildStatCard(
                'Pending',
                statistics['pendingAccounts']?.toString() ?? '0',
                Icons.pending,
                Colors.orange,
              ),
              _buildStatCard(
                'Total Accounts',
                statistics['totalAccounts']?.toString() ?? '0',
                Icons.business,
                Colors.indigo,
              ),
              _buildStatCard(
                'Active Salesmen',
                statistics['uniqueSalesmen']?.toString() ?? '0',
                Icons.people,
                const Color(0xFFD7BE69),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Accounts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recentAccounts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No accounts found for selected period'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentAccounts.length > 10
                  ? 10
                  : recentAccounts.length,
              itemBuilder: (context, index) {
                final account = recentAccounts[index];
                return _buildAccountCard(account);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSalesmenTab() {
    if (salesmenPerformance.isEmpty) {
      return const Center(
        child: Text('No salesman data available for selected period'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: salesmenPerformance.length,
      itemBuilder: (context, index) {
        final salesman = salesmenPerformance[index];
        return _buildSalesmanCard(salesman);
      },
    );
  }

  Widget _buildMapTab() {
    // Get all accounts with valid coordinates
    List<Map<String, dynamic>> accountsWithLocation = recentAccounts.where((
      account,
    ) {
      return account['latitude'] != null && account['longitude'] != null;
    }).toList();

    if (accountsWithLocation.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No accounts with location data'),
          ],
        ),
      );
    }

    // Calculate center point
    double avgLat =
        accountsWithLocation.fold(
          0.0,
          (sum, account) => sum + (account['latitude'] as num).toDouble(),
        ) /
        accountsWithLocation.length;
    double avgLng =
        accountsWithLocation.fold(
          0.0,
          (sum, account) => sum + (account['longitude'] as num).toDouble(),
        ) /
        accountsWithLocation.length;

    Set<Marker> markers = accountsWithLocation.map((account) {
      return Marker(
        markerId: MarkerId(account['id']),
        position: LatLng(
          (account['latitude'] as num).toDouble(),
          (account['longitude'] as num).toDouble(),
        ),
        infoWindow: InfoWindow(
          title: account['personName'] ?? 'Unknown',
          snippet: account['businessName'] ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(avgLat, avgLng),
            zoom: 12,
          ),
          markers: markers,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFD7BE69)),
                  const SizedBox(width: 8),
                  Text(
                    '${accountsWithLocation.length} accounts with location',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    DateTime createdAt = DateTime.parse(account['createdAt']);
    String timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD7BE69),
          child: Text(
            (account['personName'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account['personName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account['businessName'] != null) Text(account['businessName']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  account['createdByName'] ?? 'Unknown',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (account['isApproved'] == true)
              const Icon(Icons.verified, color: Colors.green, size: 20)
            else
              const Icon(Icons.pending, color: Colors.orange, size: 20),
            const SizedBox(height: 4),
            if (account['latitude'] != null)
              const Icon(Icons.location_on, color: Color(0xFFD7BE69), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesmanCard(Map<String, dynamic> salesman) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD7BE69),
          child: Text(
            (salesman['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          salesman['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${salesman['totalAccounts']} accounts created'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      'Total',
                      salesman['totalAccounts'].toString(),
                      Icons.business,
                    ),
                    _buildMiniStat(
                      'Active',
                      salesman['activeAccounts'].toString(),
                      Icons.check_circle,
                    ),
                    _buildMiniStat(
                      'Approved',
                      salesman['approvedAccounts'].toString(),
                      Icons.verified,
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Accounts:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...((salesman['accounts'] as List).take(5).map((account) {
                  DateTime createdAt = DateTime.parse(account['createdAt']);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.account_circle, size: 20),
                    title: Text(
                      account['personName'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: account['latitude'] != null
                        ? const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFFD7BE69),
                          )
                        : null,
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFFD7BE69)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
