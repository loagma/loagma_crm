import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_approval_service.dart';
import '../../services/user_service.dart';
import '../../utils/custom_toast.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> latePunchRequests = [];
  List<Map<String, dynamic>> earlyPunchOutRequests = [];

  bool isLoadingLatePunch = true;
  bool isLoadingEarlyPunchOut = true;

  Map<String, dynamic>? approvalCounts;

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApprovalRequests();
    _loadApprovalCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovalRequests() async {
    setState(() {
      isLoadingLatePunch = true;
      isLoadingEarlyPunchOut = true;
    });

    // Load late punch-in requests
    try {
      final latePunchResult =
          await AdminApprovalService.getPendingLatePunchRequests();
      if (latePunchResult['success'] == true && mounted) {
        final data = List<Map<String, dynamic>>.from(
          latePunchResult['data'] ?? [],
        );
        // Debug: Print the first request to see the data structure
        if (data.isNotEmpty) {
          print('Late punch request data structure: ${data.first}');
        }
        setState(() {
          latePunchRequests = data;
        });
      }
    } catch (e) {
      print('Error loading late punch requests: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLatePunch = false);
      }
    }

    // Load early punch-out requests
    try {
      final earlyPunchOutResult =
          await AdminApprovalService.getPendingEarlyPunchOutRequests();
      print('Early punch-out result: $earlyPunchOutResult');
      if (earlyPunchOutResult['success'] == true && mounted) {
        final data = List<Map<String, dynamic>>.from(
          earlyPunchOutResult['data'] ?? [],
        );
        if (data.isNotEmpty) {
          print('Early punch-out request data structure: ${data.first}');
        }
        setState(() {
          earlyPunchOutRequests = data;
        });
      }
    } catch (e) {
      print('Error loading early punch-out requests: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingEarlyPunchOut = false);
      }
    }
  }

  Future<void> _loadApprovalCounts() async {
    try {
      final result = await AdminApprovalService.getApprovalCounts();
      if (result['success'] == true && mounted) {
        setState(() {
          approvalCounts = result['data'];
        });
      }
    } catch (e) {
      print('Error loading approval counts: $e');
    }
  }

  Future<void> _handleApproval({
    required String requestId,
    required String type, // 'late_punch_in' or 'early_punch_out'
    required bool isApproval,
    String? remarks,
  }) async {
    final adminId = UserService.currentUserId;
    if (adminId == null) {
      CustomToast.showError(context, 'Admin ID not found');
      return;
    }

    try {
      Map<String, dynamic> result;

      if (type == 'late_punch_in') {
        if (isApproval) {
          result = await AdminApprovalService.approveLatePunchRequest(
            requestId: requestId,
            adminId: adminId,
            adminRemarks: remarks,
          );
        } else {
          result = await AdminApprovalService.rejectLatePunchRequest(
            requestId: requestId,
            adminId: adminId,
            adminRemarks: remarks ?? 'Request rejected',
          );
        }
      } else {
        if (isApproval) {
          result = await AdminApprovalService.approveEarlyPunchOutRequest(
            requestId: requestId,
            adminId: adminId,
            adminRemarks: remarks,
          );
        } else {
          result = await AdminApprovalService.rejectEarlyPunchOutRequest(
            requestId: requestId,
            adminId: adminId,
            adminRemarks: remarks ?? 'Request rejected',
          );
        }
      }

      if (result['success'] == true) {
        CustomToast.showSuccess(
          context,
          result['message'] ??
              (isApproval ? 'Request approved' : 'Request rejected'),
        );

        // Refresh the lists
        await _loadApprovalRequests();
        await _loadApprovalCounts();
      } else {
        CustomToast.showError(
          context,
          result['message'] ?? 'Failed to process request',
        );
      }
    } catch (e) {
      CustomToast.showError(context, 'Error: $e');
    }
  }

  void _showApprovalDialog({
    required String requestId,
    required String type,
    required String employeeName,
    required String reason,
    required bool isApproval,
  }) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApproval ? Icons.check_circle : Icons.cancel,
              color: isApproval ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(isApproval ? 'Approve Request' : 'Reject Request'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee: $employeeName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${type == 'late_punch_in' ? 'Late Punch-In' : 'Early Punch-Out'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(reason),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isApproval
                      ? 'Approval Notes (Optional)'
                      : 'Rejection Reason *',
                  hintText: isApproval
                      ? 'Add any notes for the employee...'
                      : 'Please provide a reason for rejection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (isApproval) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A 6-digit PIN will be generated and sent to the employee.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!isApproval && remarksController.text.trim().isEmpty) {
                CustomToast.showError(
                  context,
                  'Please provide a rejection reason',
                );
                return;
              }

              Navigator.pop(context);
              _handleApproval(
                requestId: requestId,
                type: type,
                isApproval: isApproval,
                remarks: remarksController.text.trim().isEmpty
                    ? null
                    : remarksController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Approval Requests'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: [
            Tab(
              text: 'All',
              icon: approvalCounts != null
                  ? _buildTabBadge(approvalCounts!['total'].toString())
                  : null,
            ),
            Tab(
              text: 'Late Punch-In',
              icon: approvalCounts != null
                  ? _buildTabBadge(approvalCounts!['latePunchIn'].toString())
                  : null,
            ),
            Tab(
              text: 'Early Punch-Out',
              icon: approvalCounts != null
                  ? _buildTabBadge(approvalCounts!['earlyPunchOut'].toString())
                  : null,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadApprovalRequests();
          await _loadApprovalCounts();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAllRequestsTab(),
            _buildLatePunchTab(),
            _buildEarlyPunchOutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBadge(String count) {
    if (count == '0') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    final allRequests = [
      ...latePunchRequests.map((req) => {...req, 'type': 'late_punch_in'}),
      ...earlyPunchOutRequests.map(
        (req) => {...req, 'type': 'early_punch_out'},
      ),
    ];

    // Sort by creation date (newest first)
    allRequests.sort((a, b) {
      final aDate = DateTime.parse(a['createdAt']);
      final bDate = DateTime.parse(b['createdAt']);
      return bDate.compareTo(aDate);
    });

    if (isLoadingLatePunch || isLoadingEarlyPunchOut) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (allRequests.isEmpty) {
      return _buildEmptyState('No pending approval requests');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allRequests.length,
      itemBuilder: (context, index) {
        final request = allRequests[index];
        return _buildRequestCard(request, request['type']);
      },
    );
  }

  Widget _buildLatePunchTab() {
    if (isLoadingLatePunch) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (latePunchRequests.isEmpty) {
      return _buildEmptyState('No pending late punch-in requests');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: latePunchRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(latePunchRequests[index], 'late_punch_in');
      },
    );
  }

  Widget _buildEarlyPunchOutTab() {
    if (isLoadingEarlyPunchOut) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (earlyPunchOutRequests.isEmpty) {
      return _buildEmptyState('No pending early punch-out requests');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: earlyPunchOutRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(
          earlyPunchOutRequests[index],
          'early_punch_out',
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, String type) {
    final isLatePunch = type == 'late_punch_in';
    final createdAt = DateTime.parse(request['createdAt']);
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLatePunch ? Colors.orange[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLatePunch ? Icons.login : Icons.logout,
                    color: isLatePunch ? Colors.orange[700] : Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLatePunch
                            ? 'Late Punch-In Request'
                            : 'Early Punch-Out Request',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Employee',
                    request['employee']?['name'] ??
                        request['employeeName'] ??
                        'Unknown',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Employee Code', _getEmployeeCode(request)),
                  const SizedBox(height: 8),
                  _buildInfoRow('Contact', _getContactNumber(request)),
                  if (request['employee']?['department']?['name'] != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Department',
                      request['employee']['department']['name'],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request['reason'] ?? 'No reason provided',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showApprovalDialog(
                      requestId: request['id'],
                      type: type,
                      employeeName: request['employeeName'] ?? 'Unknown',
                      reason: request['reason'] ?? 'No reason provided',
                      isApproval: false,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(
                      requestId: request['id'],
                      type: type,
                      employeeName: request['employeeName'] ?? 'Unknown',
                      reason: request['reason'] ?? 'No reason provided',
                      isApproval: true,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  String _getEmployeeCode(Map<String, dynamic> request) {
    // Try to get from employee object first
    final employeeCode = request['employee']?['employeeCode'];
    if (employeeCode != null && employeeCode.toString().isNotEmpty) {
      return employeeCode.toString();
    }
    // Try direct field
    final directCode = request['employeeCode'];
    if (directCode != null && directCode.toString().isNotEmpty) {
      return directCode.toString();
    }
    return 'Not assigned';
  }

  String _getContactNumber(Map<String, dynamic> request) {
    // Try to get from employee object first
    final contactNumber = request['employee']?['contactNumber'];
    if (contactNumber != null && contactNumber.toString().isNotEmpty) {
      return contactNumber.toString();
    }
    // Try direct field
    final directContact = request['contactNumber'];
    if (directContact != null && directContact.toString().isNotEmpty) {
      return directContact.toString();
    }
    return 'Not available';
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.approval, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Approval requests will appear here when employees need permission for late punch-in or early punch-out',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
