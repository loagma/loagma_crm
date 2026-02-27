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

  // Date filter
  DateTime? _selectedDate;

  // Pagination
  int _latePunchPage = 1;
  int _earlyPunchOutPage = 1;
  final int _limit = 20;

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
          await AdminApprovalService.getPendingLatePunchRequests(
            page: _latePunchPage,
            limit: _limit,
            date: _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
          );
      if (latePunchResult['success'] == true && mounted) {
        final data = List<Map<String, dynamic>>.from(
          latePunchResult['data'] ?? [],
        );
        setState(() {
          latePunchRequests = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading late punch requests: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLatePunch = false);
      }
    }

    // Load early punch-out requests
    try {
      final earlyPunchOutResult =
          await AdminApprovalService.getPendingEarlyPunchOutRequests(
            page: _earlyPunchOutPage,
            limit: _limit,
            date: _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
          );
      if (earlyPunchOutResult['success'] == true && mounted) {
        final data = List<Map<String, dynamic>>.from(
          earlyPunchOutResult['data'] ?? [],
        );
        setState(() {
          earlyPunchOutRequests = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading early punch-out requests: $e');
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
      debugPrint('Error loading approval counts: $e');
    }
  }

  Future<void> _handleApproval({
    required String requestId,
    required String type,
    required bool isApproval,
    String? remarks,
  }) async {
    final adminId = UserService.currentUserId;
    if (adminId == null) {
      if (mounted) {
        CustomToast.showError(context, 'Admin ID not found');
      }
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

      if (!mounted) return;

      if (result['success'] == true) {
        CustomToast.showSuccess(
          context,
          result['message'] ??
              (isApproval ? 'Request approved' : 'Request rejected'),
        );

        await _loadApprovalRequests();
        await _loadApprovalCounts();
      } else {
        CustomToast.showError(
          context,
          result['message'] ?? 'Failed to process request',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error: $e');
      }
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
      builder: (dialogContext) => AlertDialog(
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
                    const Text(
                      'Reason:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!isApproval && remarksController.text.trim().isEmpty) {
                CustomToast.showError(
                  dialogContext,
                  'Please provide a rejection reason',
                );
                return;
              }

              Navigator.pop(dialogContext);
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

  void _showDetailsDialog(Map<String, dynamic> request, String type) {
    final isLatePunch = type == 'late_punch_in';
    final createdAt = DateTime.parse(request['createdAt']);
    final formattedDate = DateFormat('dd MMM yyyy').format(createdAt);
    final formattedTime = DateFormat('hh:mm a').format(createdAt);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLatePunch ? Colors.orange[50] : Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLatePunch
                              ? Colors.orange[100]
                              : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isLatePunch ? Icons.login : Icons.logout,
                          color: isLatePunch
                              ? Colors.orange[700]
                              : Colors.blue[700],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLatePunch
                                  ? 'Late Punch-In Request'
                                  : 'Early Punch-Out Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLatePunch
                                    ? Colors.orange[900]
                                    : Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Information
                      _buildDetailSection(
                        'Employee Information',
                        Icons.person,
                        [
                          _buildDetailRow(
                            'Name',
                            request['employee']?['name'] ??
                                request['employeeName'] ??
                                'Unknown',
                          ),
                          _buildDetailRow(
                            'Employee Code',
                            _getEmployeeCode(request),
                          ),
                          _buildDetailRow(
                            'Contact Number',
                            _getContactNumber(request),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Request Details
                      _buildDetailSection(
                        'Request Details',
                        Icons.info_outline,
                        [
                          _buildDetailRow('Date', formattedDate),
                          _buildDetailRow('Time', formattedTime),
                          _buildDetailRow(
                            'Type',
                            isLatePunch ? 'Late Punch-In' : 'Early Punch-Out',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Reason
                      _buildDetailSection('Reason', Icons.description, [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            request['reason'] ?? 'No reason provided',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showConfirmationDialog(
                                  requestId: request['id'],
                                  type: type,
                                  employeeName:
                                      request['employee']?['name'] ??
                                      request['employeeName'] ??
                                      'Unknown',
                                  reason:
                                      request['reason'] ?? 'No reason provided',
                                  isApproval: false,
                                );
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showConfirmationDialog(
                                  requestId: request['id'],
                                  type: type,
                                  employeeName:
                                      request['employee']?['name'] ??
                                      request['employeeName'] ??
                                      'Unknown',
                                  reason:
                                      request['reason'] ?? 'No reason provided',
                                  isApproval: true,
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog({
    required String requestId,
    required String type,
    required String employeeName,
    required String reason,
    required bool isApproval,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApproval ? Icons.check_circle : Icons.cancel,
              color: isApproval ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isApproval ? 'Confirm Approval' : 'Confirm Rejection',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApproval
                  ? 'Do you confirm to approve this request?'
                  : 'Do you confirm to reject this request?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
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
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${type == 'late_punch_in' ? 'Late Punch-In' : 'Early Punch-Out'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showApprovalDialog(
                requestId: requestId,
                type: type,
                employeeName: employeeName,
                reason: reason,
                isApproval: isApproval,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isApproval ? 'Yes, Approve' : 'Yes, Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _latePunchPage = 1;
        _earlyPunchOutPage = 1;
      });
      _loadApprovalRequests();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _latePunchPage = 1;
      _earlyPunchOutPage = 1;
    });
    _loadApprovalRequests();
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
      body: Column(
        children: [
          // Date Filter Bar
          _buildDateFilterBar(),
          // Content
          Expanded(
            child: RefreshIndicator(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDate != null
                        ? primaryColor
                        : Colors.grey[300]!,
                    width: _selectedDate != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedDate != null
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _selectedDate != null
                          ? primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                            : 'Filter by Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: _selectedDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _selectedDate != null
                          ? primaryColor
                          : Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
              ),
              tooltip: 'Clear filter',
            ),
          ],
        ],
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

    // Group by date
    final groupedRequests = _groupRequestsByDate(allRequests);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRequests.length,
      itemBuilder: (context, index) {
        final entry = groupedRequests.entries.elementAt(index);
        final dateKey = entry.key;
        final requests = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey),
            ...requests.map(
              (request) => _buildRequestCard(request, request['type']),
            ),
          ],
        );
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

    final groupedRequests = _groupRequestsByDate(
      latePunchRequests
          .map((req) => {...req, 'type': 'late_punch_in'})
          .toList(),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRequests.length,
      itemBuilder: (context, index) {
        final entry = groupedRequests.entries.elementAt(index);
        final dateKey = entry.key;
        final requests = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey),
            ...requests.map(
              (request) => _buildRequestCard(request, 'late_punch_in'),
            ),
          ],
        );
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

    final groupedRequests = _groupRequestsByDate(
      earlyPunchOutRequests
          .map((req) => {...req, 'type': 'early_punch_out'})
          .toList(),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRequests.length,
      itemBuilder: (context, index) {
        final entry = groupedRequests.entries.elementAt(index);
        final dateKey = entry.key;
        final requests = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey),
            ...requests.map(
              (request) => _buildRequestCard(request, 'early_punch_out'),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupRequestsByDate(
    List<Map<String, dynamic>> requests,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final request in requests) {
      final createdAt = DateTime.parse(request['createdAt']);
      final dateKey = _getDateKey(createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(request);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final requestDate = DateTime(date.year, date.month, date.day);

    if (requestDate == today) {
      return 'Today';
    } else if (requestDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  Widget _buildDateHeader(String dateKey) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dateKey,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B7355),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, String type) {
    final isLatePunch = type == 'late_punch_in';
    final createdAt = DateTime.parse(request['createdAt']);
    final formattedTime = DateFormat('hh:mm a').format(createdAt);

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
                        request['employee']?['name'] ??
                            request['employeeName'] ??
                            'Unknown',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isLatePunch ? 'Late Punch-In' : 'Early Punch-Out'} • $formattedTime',
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
            // Action Buttons Row
            Row(
              children: [
                // View Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDetailsDialog(request, type),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text(
                      'View',
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Approve Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmationDialog(
                      requestId: request['id'],
                      type: type,
                      employeeName:
                          request['employee']?['name'] ??
                          request['employeeName'] ??
                          'Unknown',
                      reason: request['reason'] ?? 'No reason provided',
                      isApproval: true,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve', textAlign: TextAlign.center),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmationDialog(
                      requestId: request['id'],
                      type: type,
                      employeeName:
                          request['employee']?['name'] ??
                          request['employeeName'] ??
                          'Unknown',
                      reason: request['reason'] ?? 'No reason provided',
                      isApproval: false,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject', textAlign: TextAlign.center),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 3,
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

  String _getEmployeeCode(Map<String, dynamic> request) {
    final employeeCode = request['employee']?['employeeCode'];
    if (employeeCode != null && employeeCode.toString().isNotEmpty) {
      return employeeCode.toString();
    }
    final directCode = request['employeeCode'];
    if (directCode != null && directCode.toString().isNotEmpty) {
      return directCode.toString();
    }
    return 'Not assigned';
  }

  String _getContactNumber(Map<String, dynamic> request) {
    final contactNumber = request['employee']?['contactNumber'];
    if (contactNumber != null && contactNumber.toString().isNotEmpty) {
      return contactNumber.toString();
    }
    final directContact = request['contactNumber'];
    if (directContact != null && directContact.toString().isNotEmpty) {
      return directContact.toString();
    }
    return 'Not available';
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.approval, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate != null
                  ? 'No requests found for ${DateFormat('dd MMM yyyy').format(_selectedDate!)}'
                  : 'Approval requests will appear here when employees need permission',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Date Filter'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
