import 'package:flutter/material.dart';
import 'dart:async';
import '../services/late_punch_approval_service.dart';
import '../services/employee_working_hours_service.dart';
import '../services/user_service.dart';
import '../utils/custom_toast.dart';

class LatePunchApprovalWidget extends StatefulWidget {
  final VoidCallback? onApprovalRequested;
  final VoidCallback? onApprovalReceived;
  final Function(String)? onApprovalCodeValidated;
  final Map<String, dynamic>? employeeWorkingHours;

  const LatePunchApprovalWidget({
    super.key,
    this.onApprovalRequested,
    this.onApprovalReceived,
    this.onApprovalCodeValidated,
    this.employeeWorkingHours,
  });

  @override
  State<LatePunchApprovalWidget> createState() =>
      _LatePunchApprovalWidgetState();
}

class _LatePunchApprovalWidgetState extends State<LatePunchApprovalWidget> {
  final _reasonController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _approvalStatus;
  Map<String, dynamic>? _workingHours;
  bool _isLoadingStatus = false;
  bool _isLoadingWorkingHours = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
    _loadApprovalStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _reasonController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 10 seconds to check for admin approval
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _approvalStatus != null) {
        final status = _approvalStatus!['status'];
        // Only refresh for PENDING status
        if (status == 'PENDING') {
          _loadApprovalStatus();
        }
      }
    });
  }

  Future<void> _loadWorkingHours() async {
    if (!mounted) return;

    // Use passed working hours if available
    if (widget.employeeWorkingHours != null) {
      setState(() {
        _workingHours = widget.employeeWorkingHours;
      });
      return;
    }

    setState(() => _isLoadingWorkingHours = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final result = await EmployeeWorkingHoursService.getWorkingHours(
        employeeId,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          _workingHours = result['data'];
        });
      }
    } catch (e) {
      print('Error loading working hours: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingWorkingHours = false);
      }
    }
  }

  Future<void> _loadApprovalStatus() async {
    if (!mounted) return;

    setState(() => _isLoadingStatus = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final result = await LatePunchApprovalService.getApprovalStatus(
        employeeId,
      );

      if (result['success'] == true && mounted) {
        final responseData = result['data'];
        final oldStatus = _approvalStatus?['status'];
        final newStatus = responseData;
        final newStatusValue = newStatus?['status'];

        print('🔍 Approval status loaded: $responseData');

        setState(() {
          _approvalStatus = newStatus;
        });

        // If status is already APPROVED on initial load, notify parent
        if (newStatus != null && newStatus['status'] == 'APPROVED') {
          print('🎉 Found existing APPROVED status on load!');
          // Call the callback to enable punch-in (no OTP needed for simplified system)
          widget.onApprovalCodeValidated?.call('APPROVED');
          widget.onApprovalReceived?.call();
        }

        // Show notification if status changed from PENDING to APPROVED
        if (oldStatus == 'PENDING' && newStatusValue == 'APPROVED') {
          print('🎉 Status changed from PENDING to APPROVED!');
          CustomToast.showSuccess(
            context,
            'Your late punch-in request has been approved! Enter the OTP to punch in.',
          );
          widget.onApprovalReceived?.call();
        } else if (oldStatus == 'PENDING' && newStatusValue == 'REJECTED') {
          print('❌ Status changed from PENDING to REJECTED!');
          CustomToast.showError(
            context,
            'Your late punch-in request has been rejected.',
          );
        }
      } else if (result['success'] == false && mounted) {
        final errorMessage = result['message'] ?? 'Unknown error';
        print('❌ Error loading approval status: $errorMessage');

        if (result['statusCode'] != 404) {
          CustomToast.showError(context, 'Failed to load approval status');
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

      print('🔍 Approval request result: $result');

      if (result['success'] == true) {
        final reason = _reasonController.text.trim();
        CustomToast.showSuccess(
          context,
          result['message'] ?? 'Approval request submitted successfully',
        );
        _reasonController.clear();

        // Set a temporary pending status immediately to show pending UI
        setState(() {
          _approvalStatus = {
            'status': 'PENDING',
            'reason': reason,
            'requestTime': DateTime.now().toString(),
          };
        });

        // Then load the actual status from server
        await _loadApprovalStatus();
        widget.onApprovalRequested?.call();
      } else {
        // Check if the error is due to existing pending request
        if (result['message']?.contains('pending approval request') == true &&
            result['data'] != null) {
          // There's already a pending request, show it
          setState(() {
            _approvalStatus = {
              'status': 'PENDING',
              'reason': result['data']['reason'] ?? 'Pending approval',
              'requestTime':
                  result['data']['requestTime'] ?? DateTime.now().toString(),
            };
          });

          CustomToast.showSuccess(
            context,
            'You already have a pending approval request for today.',
          );
        } else {
          CustomToast.showError(
            context,
            result['message'] ?? 'Failed to submit approval request',
          );
        }
      }
    } catch (e) {
      CustomToast.showError(context, 'Error: $e');
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

    // Show approved status - user can now punch in directly
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
    // Format the cutoff time for display
    String formattedCutoffTime = '9:45 AM';
    if (_workingHours != null) {
      final cutoffTimeStr = _workingHours!['latePunchInCutoffTime'] as String?;
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
              'Punch-in is blocked after $formattedCutoffTime. Please request approval from admin.',
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
    final hasApprovalCode = _approvalStatus!['hasApprovalCode'] ?? false;
    final codeExpired = _approvalStatus!['codeExpired'] ?? false;
    final codeUsed = _approvalStatus!['codeUsed'] ?? false;

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
            hasApprovalCode
                ? 'Your late punch-in request has been approved. Enter the OTP sent by admin to punch in.'
                : 'Your late punch-in request has been approved. You can now punch in directly.',
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
                if (hasApprovalCode) ...[
                  Text(
                    'Code expires at: ${_approvalStatus!['codeExpiresAt'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // Show OTP input if approval code is required
          if (hasApprovalCode && !codeUsed) ...[
            const SizedBox(height: 16),
            if (codeExpired) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OTP has expired. Please request a new approval.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Enter OTP Code:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _validateOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
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
                          'Validate OTP & Enable Punch-In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],

          // Show success message if code is already used
          if (hasApprovalCode && codeUsed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP validated successfully. You can now punch in.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _validateOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      if (mounted) {
        CustomToast.showError(context, 'Please enter a valid 6-digit OTP');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call the parent callback with the OTP for validation
      widget.onApprovalCodeValidated?.call(otp);

      if (mounted) {
        CustomToast.showSuccess(context, 'OTP validated successfully!');
      }

      // Clear the OTP field
      _otpController.clear();

      // Refresh status to update UI
      await _loadApprovalStatus();
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to validate OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              'Your late punch-in request has been rejected by admin. You cannot punch in today.',
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
                      'You cannot punch in today due to rejection. Please contact your supervisor or try again tomorrow.',
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
