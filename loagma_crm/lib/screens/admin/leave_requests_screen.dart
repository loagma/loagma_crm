import 'package:flutter/material.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';
import '../../widgets/leave_card.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<LeaveModel> pendingLeaves = [];
  List<LeaveModel> allLeaves = [];

  bool isPendingLoading = true;
  bool isAllLoading = true;

  String selectedStatus = 'ALL';
  String selectedLeaveType = 'ALL';

  int pendingPage = 1;
  int allPage = 1;

  bool hasPendingMore = true;
  bool hasAllMore = true;

  bool isPendingLoadingMore = false;
  bool isAllLoadingMore = false;

  final ScrollController _pendingScrollController = ScrollController();
  final ScrollController _allScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingLeaves();
    _loadAllLeaves();

    _pendingScrollController.addListener(_onPendingScroll);
    _allScrollController.addListener(_onAllScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingScrollController.dispose();
    _allScrollController.dispose();
    super.dispose();
  }

  void _onPendingScroll() {
    if (_pendingScrollController.position.pixels >=
        _pendingScrollController.position.maxScrollExtent - 200) {
      if (hasPendingMore && !isPendingLoadingMore) {
        _loadMorePendingLeaves();
      }
    }
  }

  void _onAllScroll() {
    if (_allScrollController.position.pixels >=
        _allScrollController.position.maxScrollExtent - 200) {
      if (hasAllMore && !isAllLoadingMore) {
        _loadMoreAllLeaves();
      }
    }
  }

  Future<void> _loadPendingLeaves() async {
    setState(() {
      isPendingLoading = true;
      pendingPage = 1;
      pendingLeaves.clear();
    });

    try {
      final result = await LeaveService.getPendingLeaves(
        page: pendingPage,
        limit: 10,
      );
      setState(() {
        pendingLeaves = result['leaves'];
        hasPendingMore = result['pagination']['hasNext'];
        isPendingLoading = false;
      });
    } catch (e) {
      setState(() => isPendingLoading = false);
      _showError('Error loading pending leaves: $e');
    }
  }

  Future<void> _loadMorePendingLeaves() async {
    if (isPendingLoadingMore) return;

    setState(() => isPendingLoadingMore = true);

    try {
      final result = await LeaveService.getPendingLeaves(
        page: pendingPage + 1,
        limit: 10,
      );

      setState(() {
        pendingLeaves.addAll(result['leaves']);
        pendingPage++;
        hasPendingMore = result['pagination']['hasNext'];
        isPendingLoadingMore = false;
      });
    } catch (e) {
      setState(() => isPendingLoadingMore = false);
      _showError('Error loading more pending leaves: $e');
    }
  }

  Future<void> _loadAllLeaves() async {
    setState(() {
      isAllLoading = true;
      allPage = 1;
      allLeaves.clear();
    });

    try {
      final result = await LeaveService.getAllLeaves(
        status: selectedStatus,
        leaveType: selectedLeaveType,
        page: allPage,
        limit: 15,
      );

      setState(() {
        allLeaves = result['leaves'];
        hasAllMore = result['pagination']['hasNext'];
        isAllLoading = false;
      });
    } catch (e) {
      setState(() => isAllLoading = false);
      _showError('Error loading all leaves: $e');
    }
  }

  Future<void> _loadMoreAllLeaves() async {
    if (isAllLoadingMore) return;

    setState(() => isAllLoadingMore = true);

    try {
      final result = await LeaveService.getAllLeaves(
        status: selectedStatus,
        leaveType: selectedLeaveType,
        page: allPage + 1,
        limit: 15,
      );

      setState(() {
        allLeaves.addAll(result['leaves']);
        allPage++;
        hasAllMore = result['pagination']['hasNext'];
        isAllLoadingMore = false;
      });
    } catch (e) {
      setState(() => isAllLoadingMore = false);
      _showError('Error loading more leaves: $e');
    }
  }

  Future<void> _onRefresh() async {
    if (_tabController.index == 0) {
      await _loadPendingLeaves();
    } else {
      await _loadAllLeaves();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _approveLeave(LeaveModel leave) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: 'Approve Leave Request',
        subtitle:
            '${leave.employeeName} - ${leave.leaveType} (${leave.daysText})',
        actionText: 'Approve',
        actionColor: Colors.green,
        remarksLabel: 'Admin Remarks (Optional)',
        remarksHint: 'Add any remarks for the employee...',
      ),
    );

    if (result != null) {
      try {
        await LeaveService.approveLeave(
          leave.id,
          adminRemarks: result['remarks'],
        );
        _showSuccess('Leave request approved successfully');
        _loadPendingLeaves();
        _loadAllLeaves();
      } catch (e) {
        _showError('Error approving leave: $e');
      }
    }
  }

  Future<void> _rejectLeave(LeaveModel leave) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: 'Reject Leave Request',
        subtitle:
            '${leave.employeeName} - ${leave.leaveType} (${leave.daysText})',
        actionText: 'Reject',
        actionColor: Colors.red,
        remarksLabel: 'Rejection Reason *',
        remarksHint: 'Please provide reason for rejection...',
        isRequired: true,
      ),
    );

    if (result != null) {
      try {
        await LeaveService.rejectLeave(
          leave.id,
          rejectionReason: result['remarks']!,
          adminRemarks: result['adminRemarks'],
        );
        _showSuccess('Leave request rejected successfully');
        _loadPendingLeaves();
        _loadAllLeaves();
      } catch (e) {
        _showError('Error rejecting leave: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leave Requests',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _onRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Pending (${pendingLeaves.length})',
              icon: const Icon(Icons.schedule),
            ),
            const Tab(text: 'All Requests', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Leaves Tab
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: isPendingLoading
                ? const Center(child: CircularProgressIndicator())
                : pendingLeaves.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'No Pending Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All leave requests have been processed',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _pendingScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        pendingLeaves.length + (isPendingLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == pendingLeaves.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final leave = pendingLeaves[index];
                      return LeaveCard(
                        leave: leave,
                        showEmployeeName: true,
                        onApprove: () => _approveLeave(leave),
                        onReject: () => _rejectLeave(leave),
                      );
                    },
                  ),
          ),

          // All Leaves Tab
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: LeaveService.getStatusOptions().map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == 'ALL' ? 'All Status' : status,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != selectedStatus) {
                              setState(() => selectedStatus = value);
                              _loadAllLeaves();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedLeaveType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: ['ALL', ...LeaveService.getLeaveTypes()].map((
                            type,
                          ) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type == 'ALL' ? 'All Types' : type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != selectedLeaveType) {
                              setState(() => selectedLeaveType = value);
                              _loadAllLeaves();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // All Leaves List
                Expanded(
                  child: isAllLoading
                      ? const Center(child: CircularProgressIndicator())
                      : allLeaves.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Leaves Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _allScrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              allLeaves.length + (isAllLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == allLeaves.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final leave = allLeaves[index];
                            return LeaveCard(
                              leave: leave,
                              showEmployeeName: true,
                              onApprove: leave.isPending
                                  ? () => _approveLeave(leave)
                                  : null,
                              onReject: leave.isPending
                                  ? () => _rejectLeave(leave)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final Color actionColor;
  final String remarksLabel;
  final String remarksHint;
  final bool isRequired;

  const _ApprovalDialog({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.actionColor,
    required this.remarksLabel,
    required this.remarksHint,
    this.isRequired = false,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _adminRemarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    _adminRemarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.remarksLabel,
                hintText: widget.remarksHint,
                border: const OutlineInputBorder(),
              ),
              validator: widget.isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    }
                  : null,
            ),
            if (widget.isRequired) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminRemarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional Admin Remarks (Optional)',
                  hintText: 'Any additional comments...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'remarks': _remarksController.text.trim(),
                if (widget.isRequired)
                  'adminRemarks': _adminRemarksController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.actionColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.actionText),
        ),
      ],
    );
  }
}
