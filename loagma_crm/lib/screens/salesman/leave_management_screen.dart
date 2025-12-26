import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';
import '../../widgets/leave_card.dart';
import '../../widgets/leave_balance_card.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  List<LeaveModel> leaves = [];
  LeaveStatistics? statistics;
  bool isLoading = true;
  String selectedStatus = 'ALL';
  int currentPage = 1;
  bool hasMore = true;
  bool isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLeaves();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (hasMore && !isLoadingMore) {
        _loadMoreLeaves();
      }
    }
  }

  Future<void> _loadLeaves() async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      leaves.clear();
    });

    try {
      final result = await LeaveService.getMyLeaves(
        status: selectedStatus,
        page: currentPage,
        limit: 10,
      );

      setState(() {
        leaves = result['leaves'];
        statistics = result['statistics'];
        hasMore = result['pagination']['hasNext'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMoreLeaves() async {
    if (isLoadingMore) return;

    setState(() => isLoadingMore = true);

    try {
      final result = await LeaveService.getMyLeaves(
        status: selectedStatus,
        page: currentPage + 1,
        limit: 10,
      );

      setState(() {
        leaves.addAll(result['leaves']);
        currentPage++;
        hasMore = result['pagination']['hasNext'];
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadLeaves();
  }

  void _onStatusChanged(String? status) {
    if (status != null && status != selectedStatus) {
      setState(() => selectedStatus = status);
      _loadLeaves();
    }
  }

  Future<void> _cancelLeave(LeaveModel leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave'),
        content: Text(
          'Are you sure you want to cancel your ${leave.leaveType} leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LeaveService.cancelLeave(leave.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadLeaves(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling leave: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leave Management',
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
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            // Leave Balance Card
            if (statistics != null)
              Container(
                margin: const EdgeInsets.all(16),
                child: LeaveBalanceCard(statistics: statistics!),
              ),

            // Status Filter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Filter: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: LeaveService.getStatusOptions().map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status == 'ALL' ? 'All Leaves' : status),
                        );
                      }).toList(),
                      onChanged: _onStatusChanged,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Leaves List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : leaves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No leaves found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedStatus == 'ALL'
                                ? 'You haven\'t applied for any leaves yet'
                                : 'No ${selectedStatus.toLowerCase()} leaves found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: leaves.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == leaves.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final leave = leaves[index];
                        return LeaveCard(
                          leave: leave,
                          onCancel: leave.canCancel
                              ? () => _cancelLeave(leave)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/salesman/leaves/apply'),
        backgroundColor: const Color(0xFFD7BE69),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Apply Leave',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
