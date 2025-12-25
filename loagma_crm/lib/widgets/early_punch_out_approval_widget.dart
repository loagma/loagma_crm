import 'package:flutter/material.dart';
import 'dart:async';
import '../services/early_punch_out_approval_service.dart';
import '../services/employee_working_hours_service.dart';
import '../services/user_service.dart';
import '../utils/custom_toast.dart';

class EarlyPunchOutApprovalWidget extends StatefulWidget {
  final String attendanceId;
  final Map<String, dynamic>? employeeWorkingHours;
  final VoidCallback? onApprovalRequested;
  final Function(String approvalCode)? onApprovalCodeValidated;

  const EarlyPunchOutApprovalWidget({
    super.key,
    required this.attendanceId,
    this.employeeWorkingHours,
    this.onApprovalRequested,
    this.onApprovalCodeValidated,
  });

  @override
  State<EarlyPunchOutApprovalWidget> createState() =>
      _EarlyPunchOutApprovalWidgetState();
}

class _EarlyPunchOutApprovalWidgetState
    extends State<EarlyPunchOutApprovalWidget> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _approvalStatus;
  bool _isLoadingStatus = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 10 seconds to check for approval updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted &&
          _approvalStatus != null &&
          _approvalStatus!['status'] == 'PENDING') {
        _loadApprovalStatus();
      }
    });
  }

  Future<void> _loadApprovalStatus() async {
    if (!mounted) return;

    setState(() => _isLoadingStatus = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final result = await EarlyPunchOutApprovalService.getApprovalStatus(
        widget.attendanceId,
      );

      print('🔍 Early punch-out approval status result: $result');

      if (result['success'] == true && mounted) {
        final newStatus = result['data'];
        final oldStatus = _approvalStatus?['status'];
        final newStatusValue = newStatus?['status'];

        print('🔍 Old status: $oldStatus, New status: $newStatusValue');

        setState(() {
          _approvalStatus = newStatus;
        });

        // Show notification if status changed from PENDING to APPROVED
        if (oldStatus == 'PENDING' && newStatusValue == 'APPROVED') {
          if (mounted) {
            CustomToast.showSuccess(
              context,
              'Your early punch-out request has been approved! You can now punch out.',
            );

            // Call the callback to enable punch-out (no OTP needed)
            widget.onApprovalCodeValidated?.call('APPROVED');
          }
        } else if (oldStatus == 'PENDING' && newStatusValue == 'REJECTED') {
          if (mounted) {
            CustomToast.showError(
              context,
              'Your early punch-out request has been rejected.',
            );
          }
        }
      }
    } catch (e) {
      print('Error loading early punch-out approval status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _requestApproval() async {
    if (_reasonController.text.trim().length < 10) {
      CustomToast.showError(
        context,
        'Please provide a detailed reason (minimum 10 characters)',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final employeeId = UserService.currentUserId;
      final employeeName = UserService.name;

      if (employeeId == null || employeeName == null) {
        if (mounted) {
          CustomToast.showError(context, 'User information not available');
        }
        return;
      }

      final result =
          await EarlyPunchOutApprovalService.requestEarlyPunchOutApproval(
            employeeId: employeeId,
            employeeName: employeeName,
            attendanceId: widget.attendanceId,
            reason: _reasonController.text.trim(),
          );

      if (result['success'] == true) {
        if (mounted) {
          CustomToast.showSuccess(
            context,
            result['message'] ?? 'Approval request submitted successfully',
          );
        }
        _reasonController.clear();

        // Set a temporary pending status immediately
        setState(() {
          _approvalStatus = {
            'status': 'PENDING',
            'reason': _reasonController.text.trim(),
            'requestTime': DateTime.now().toString(),
          };
        });

        await _loadApprovalStatus();
        widget.onApprovalRequested?.call();
      } else {
        if (mounted) {
          CustomToast.showError(
            context,
            result['message'] ?? 'Failed to submit approval request',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show approved status - user can now punch out directly
    if (_approvalStatus != null && _approvalStatus!['status'] == 'APPROVED') {
      return _buildApprovedStatus();
    }

    // Show pending status if request is pending
    if (_approvalStatus != null && _approvalStatus!['status'] == 'PENDING') {
      return _buildPendingStatus();
    }

    // Show rejected status if request is rejected
    if (_approvalStatus != null && _approvalStatus!['status'] == 'REJECTED') {
      return _buildRejectedStatus();
    }

    // Show request form if no request exists
    return _buildRequestForm();
  }

  Widget _buildRequestForm() {
    // Format the work end time for display
    String formattedWorkEndTime = '6:00 PM';
    String formattedCutoffTime = '5:30 PM';

    if (widget.employeeWorkingHours != null) {
      // Format work end time
      final workEndTimeStr =
          widget.employeeWorkingHours!['workEndTime'] as String?;
      if (workEndTimeStr != null) {
        try {
          final parts = workEndTimeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          formattedWorkEndTime =
              '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        } catch (e) {
          // Use default
        }
      }

      // Format early punch-out cutoff time
      final cutoffTimeStr =
          widget.employeeWorkingHours!['earlyPunchOutCutoffTime'] as String?;
      if (cutoffTimeStr != null) {
        try {
          final parts = cutoffTimeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          formattedCutoffTime =
              '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        } catch (e) {
          // Use default
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Early Punch-Out Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Early Punch-Out Policy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Normal punch-out time is $formattedWorkEndTime. To punch out before $formattedCutoffTime, you need admin approval.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.employeeWorkingHours != null
                        ? EmployeeWorkingHoursService.getTimeUntilEarlyPunchOutCutoff(
                            widget.employeeWorkingHours!,
                          )
                        : 'Loading working hours...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Early Punch-Out *',
                hintText: 'Please provide a detailed reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _requestApproval,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Request Approval from Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.pending, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Approval Pending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your early punch-out request is pending admin approval.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: ${_approvalStatus!['requestTime'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Reason: ${_approvalStatus!['reason'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Auto-refreshing every 10 seconds. You will be notified when approved.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingStatus ? null : _loadApprovalStatus,
                icon: _isLoadingStatus
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(
                  _isLoadingStatus ? 'Refreshing...' : 'Refresh Status',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber[700],
                  side: BorderSide(color: Colors.amber[300]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Request Approved!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your early punch-out request has been approved by admin. You can now punch out directly.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approval Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approved by: ${_approvalStatus!['approvedBy'] ?? 'Admin'}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Approved at: ${_approvalStatus!['approvedAt'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (_approvalStatus!['adminRemarks'] != null) ...[
                  Text(
                    'Remarks: ${_approvalStatus!['adminRemarks']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Punch Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Call the callback to trigger punch out in parent
                widget.onApprovalCodeValidated?.call('APPROVED');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, size: 24),
              label: const Text(
                'PUNCH OUT NOW',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedStatus() {
    // Format the cutoff time for display
    String formattedCutoffTime = '5:30 PM';
    if (widget.employeeWorkingHours != null) {
      final cutoffTimeStr =
          widget.employeeWorkingHours!['earlyPunchOutCutoffTime'] as String?;
      if (cutoffTimeStr != null) {
        try {
          final parts = cutoffTimeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          formattedCutoffTime =
              '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        } catch (e) {
          // Use default
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Request Rejected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your early punch-out request has been rejected by admin. You cannot punch out early today.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rejected by: ${_approvalStatus!['approvedBy'] ?? 'Admin'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Rejected at: ${_approvalStatus!['approvedAt'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (_approvalStatus!['adminRemarks'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${_approvalStatus!['adminRemarks']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must work until $formattedCutoffTime or contact your supervisor.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
