import 'package:flutter/material.dart';
import 'dart:async';
import '../services/late_punch_approval_service.dart';
import '../services/user_service.dart';
import '../utils/custom_toast.dart';

class LatePunchApprovalWidget extends StatefulWidget {
  final VoidCallback? onApprovalRequested;
  final VoidCallback? onApprovalReceived;

  const LatePunchApprovalWidget({
    super.key,
    this.onApprovalRequested,
    this.onApprovalReceived,
  });

  @override
  State<LatePunchApprovalWidget> createState() =>
      _LatePunchApprovalWidgetState();
}

class _LatePunchApprovalWidgetState extends State<LatePunchApprovalWidget> {
  final _reasonController = TextEditingController();
  final _approvalCodeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isValidatingCode = false;
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
    _approvalCodeController.dispose();
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

      final result = await LatePunchApprovalService.getEmployeeApprovalStatus(
        employeeId,
      );

      if (result['success'] == true && mounted) {
        final newStatus = result['data'];
        final oldStatus = _approvalStatus?['status'];
        final newStatusValue = newStatus?['status'];

        setState(() {
          _approvalStatus = newStatus;
        });

        // Show notification if status changed from PENDING to APPROVED
        if (oldStatus == 'PENDING' && newStatusValue == 'APPROVED') {
          CustomToast.showSuccess(
            context,
            'Your late punch-in request has been approved! Enter the code to punch in.',
          );
        } else if (oldStatus == 'PENDING' && newStatusValue == 'REJECTED') {
          CustomToast.showError(
            context,
            'Your late punch-in request has been rejected.',
          );
        }
      }
    } catch (e) {
      print('Error loading approval status: $e');
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

      final result = await LatePunchApprovalService.requestLatePunchApproval(
        employeeId: employeeId,
        employeeName: employeeName,
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

      final result = await LatePunchApprovalService.validateApprovalCode(
        employeeId: employeeId,
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
                  'Late Punch-In Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Punch-in is blocked after 9:45 AM. Please request approval from admin.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Late Punch-In *',
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
              'Your late punch-in request is pending admin approval.',
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
                    'Auto-refreshing every 10 seconds. You will receive a notification when approved.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
    final isExpired = _approvalStatus!['codeExpired'] == true;
    final isUsed = _approvalStatus!['codeUsed'] == true;

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
                Icon(
                  isExpired || isUsed ? Icons.error : Icons.check_circle,
                  color: isExpired || isUsed ? Colors.red : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? 'Approval Code Expired'
                      : isUsed
                      ? 'Approval Code Used'
                      : 'Request Approved',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpired || isUsed
                        ? Colors.red[800]
                        : Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isExpired || isUsed) ...[
              Text(
                isExpired
                    ? 'Your approval code has expired. Please request a new approval.'
                    : 'Your approval code has already been used.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ] else ...[
              Text(
                'Your late punch-in request has been approved. Enter the approval code to punch in.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _approvalCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Approval Code',
                  hintText: '6-digit code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code expires at: ${_approvalStatus!['codeExpiresAt'] ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
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
                          'Validate Code & Punch In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
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
            Text(
              'Your late punch-in request has been rejected by admin.',
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
                    'Rejected by: ${_approvalStatus!['rejectedBy'] ?? 'Admin'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Rejected at: ${_approvalStatus!['rejectedAt'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (_approvalStatus!['adminRemarks'] != null) ...[
                    Text(
                      'Reason: ${_approvalStatus!['adminRemarks']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
