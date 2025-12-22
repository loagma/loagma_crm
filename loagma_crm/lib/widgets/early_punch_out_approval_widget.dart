import 'package:flutter/material.dart';
import '../services/early_punch_out_approval_service.dart';
import '../services/user_service.dart';
import '../utils/custom_toast.dart';

class EarlyPunchOutApprovalWidget extends StatefulWidget {
  final String attendanceId;
  final VoidCallback? onApprovalRequested;
  final VoidCallback? onApprovalReceived;

  const EarlyPunchOutApprovalWidget({
    super.key,
    required this.attendanceId,
    this.onApprovalRequested,
    this.onApprovalReceived,
  });

  @override
  State<EarlyPunchOutApprovalWidget> createState() =>
      _EarlyPunchOutApprovalWidgetState();
}

class _EarlyPunchOutApprovalWidgetState
    extends State<EarlyPunchOutApprovalWidget> {
  final _reasonController = TextEditingController();
  final _approvalCodeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isValidatingCode = false;
  Map<String, dynamic>? _approvalStatus;
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _approvalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovalStatus() async {
    setState(() => _isLoadingStatus = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final result =
          await EarlyPunchOutApprovalService.getEmployeeEarlyPunchOutStatus(
            employeeId,
            attendanceId: widget.attendanceId,
          );

      if (result['success'] == true && mounted) {
        setState(() {
          _approvalStatus = result['data'];
        });
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
        CustomToast.showError(context, 'User information not available');
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
        CustomToast.showSuccess(
          context,
          result['message'] ?? 'Approval request submitted successfully',
        );
        _reasonController.clear();
        await _loadApprovalStatus();
        widget.onApprovalRequested?.call();
      } else {
        CustomToast.showError(
          context,
          result['message'] ?? 'Failed to submit approval request',
        );
      }
    } catch (e) {
      CustomToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _validateApprovalCode() async {
    if (_approvalCodeController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please enter the approval code');
      return;
    }

    setState(() => _isValidatingCode = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final result =
          await EarlyPunchOutApprovalService.validateEarlyPunchOutCode(
            employeeId: employeeId,
            attendanceId: widget.attendanceId,
            approvalCode: _approvalCodeController.text.trim(),
          );

      if (result['success'] == true) {
        CustomToast.showSuccess(
          context,
          result['message'] ?? 'Approval code is valid',
        );
        widget.onApprovalReceived?.call();
      } else {
        CustomToast.showError(
          context,
          result['message'] ?? 'Invalid approval code',
        );
      }
    } catch (e) {
      CustomToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isValidatingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show approval code input if request is approved
    if (_approvalStatus != null && _approvalStatus!['status'] == 'APPROVED') {
      return _buildApprovalCodeInput();
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
                    'Normal punch-out time is 6:30 PM. To punch out early, you need admin approval.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EarlyPunchOutApprovalService.getTimeUntilEarlyPunchOutCutoff(),
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
            Text(
              'Reason for Early Punch-Out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    'Please provide a detailed reason for early punch-out (minimum 10 characters)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
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
                        'Request Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                    'Your early punch-out request is being reviewed by admin.',
                    style: TextStyle(fontSize: 14, color: Colors.amber[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${_approvalStatus!['reason']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You will receive a notification once admin responds to your request.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadApprovalStatus,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Status'),
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

  Widget _buildApprovalCodeInput() {
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
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Request Approved',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your early punch-out request has been approved. Enter the approval code to punch out.',
                    style: TextStyle(fontSize: 14, color: Colors.green[700]),
                  ),
                  if (_approvalStatus!['adminRemarks'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Admin Note: ${_approvalStatus!['adminRemarks']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter Approval Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _approvalCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit approval code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidatingCode ? null : _validateApprovalCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isValidatingCode
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
                        'Validate Code & Punch Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedStatus() {
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
                    'Your early punch-out request has been rejected.',
                    style: TextStyle(fontSize: 14, color: Colors.red[700]),
                  ),
                  if (_approvalStatus!['adminRemarks'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${_approvalStatus!['adminRemarks']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You can submit a new request with a different reason if needed.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _approvalStatus = null;
                    _reasonController.clear();
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Submit New Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  side: BorderSide(color: Colors.orange[300]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
