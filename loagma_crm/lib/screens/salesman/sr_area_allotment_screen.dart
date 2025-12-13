import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/user_service.dart';
import '../../services/network_service.dart';
import '../../services/area_assignment_service.dart';

class SRAreaAllotmentScreen extends StatefulWidget {
  const SRAreaAllotmentScreen({super.key});

  @override
  State<SRAreaAllotmentScreen> createState() => _SRAreaAllotmentScreenState();
}

class _SRAreaAllotmentScreenState extends State<SRAreaAllotmentScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  List<Map<String, dynamic>> _areaAssignments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreaAssignments();
  }

  Future<void> _loadAreaAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check internet connectivity first
      final hasConnection = await NetworkService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final userId = UserService.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in. Please login again.');
      }

      final token = UserService.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      print('🔍 Loading area assignments for user: $userId');
      print('🔑 Token available: ${token.isNotEmpty}');

      print('📡 Fetching area assignments using service...');
      final assignments =
          await AreaAssignmentService.getSalesmanAreaAssignments();

      // Create a mock response structure for compatibility
      final response = http.Response(
        jsonEncode({
          'success': true,
          'assignments': assignments.map((a) => a.toJson()).toList(),
        }),
        200,
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You don\'t have permission to view area assignments.',
        );
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _areaAssignments = List<Map<String, dynamic>>.from(
              data['assignments'] ?? data['data'] ?? [],
            );
          });
          print('✅ Loaded ${_areaAssignments.length} area assignments');
        } else {
          throw Exception(data['message'] ?? 'Failed to load area assignments');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error loading area assignments: $e');

      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication')) {
        errorMessage = 'Authentication failed. Please logout and login again.';
      } else if (e.toString().contains('No internet connection')) {
        errorMessage = e.toString();
      } else {
        errorMessage = NetworkService.getNetworkErrorMessage(e);
      }

      setState(() {
        _error = errorMessage;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _debugAreaAssignments() async {
    // Debug function removed for now
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('SR Area Allotments'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugAreaAssignments,
            tooltip: 'Debug Data',
          ),
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () async {
              final hasConnection =
                  await NetworkService.hasInternetConnection();
              if (mounted) {
                NetworkService.showNetworkStatus(context, hasConnection);
              }
            },
            tooltip: 'Check Connection',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAreaAssignments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading area assignments...'),
                ],
              ),
            )
          : _error != null
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: TextStyle(fontSize: 18, color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Troubleshooting card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.help_outline, color: primaryColor),
                                const SizedBox(width: 8),
                                const Text(
                                  'Troubleshooting Tips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('• Check your internet connection'),
                            const Text(
                              '• Try switching between WiFi and mobile data',
                            ),
                            const Text('• Wait 30-60 seconds and try again'),
                            const Text(
                              '• The server may be starting up (free hosting)',
                            ),
                            const Text('• Restart the app if problem persists'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final hasConnection =
                                await NetworkService.hasInternetConnection();
                            if (mounted) {
                              NetworkService.showNetworkStatus(
                                context,
                                hasConnection,
                              );
                            }
                          },
                          icon: const Icon(Icons.wifi),
                          label: const Text('Test Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadAreaAssignments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                        if (_error != null &&
                            _error!.contains('Authentication'))
                          ElevatedButton.icon(
                            onPressed: () async {
                              await UserService.logout();
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : _areaAssignments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Area Assignments',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no area assignments yet.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAreaAssignments,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_city,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Assignments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_areaAssignments.length}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${_areaAssignments.where((a) => a['isActive'] == true).length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Data Table
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Area Assignments Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey[50],
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'City',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'District',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Pincode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Assigned Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _areaAssignments.map((assignment) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(assignment['city'] ?? 'N/A')),
                                    DataCell(
                                      Text(assignment['district'] ?? 'N/A'),
                                    ),
                                    DataCell(
                                      Text(assignment['pinCode'] ?? 'N/A'),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: assignment['isActive'] == true
                                              ? Colors.green
                                              : Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          assignment['isActive'] == true
                                              ? 'Active'
                                              : 'Inactive',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        assignment['assignedDate'] != null
                                            ? DateTime.parse(
                                                assignment['assignedDate'],
                                              ).toLocal().toString().split(
                                                ' ',
                                              )[0]
                                            : 'N/A',
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
