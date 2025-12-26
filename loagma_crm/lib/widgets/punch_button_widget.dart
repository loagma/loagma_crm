import 'package:flutter/material.dart';
import '../services/punch_status_service.dart';

/// State-driven Punch Button Widget
///
/// This widget demonstrates the correct way to implement punch functionality:
/// 1. NEVER calculate time rules locally
/// 2. ALWAYS fetch state from /punch/status
/// 3. Render UI based on server response
/// 4. Disable buttons aggressively during pending states
class PunchButtonWidget extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final VoidCallback? onPunchIn;
  final VoidCallback? onPunchOut;
  final Function(String type, String? attendanceId)? onRequestApproval;

  const PunchButtonWidget({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.onPunchIn,
    this.onPunchOut,
    this.onRequestApproval,
  });

  @override
  State<PunchButtonWidget> createState() => _PunchButtonWidgetState();
}

class _PunchButtonWidgetState extends State<PunchButtonWidget> {
  PunchStatusResponse? _status;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = await PunchStatusService.getPunchStatus(widget.employeeId);

    setState(() {
      _status = status;
      _isLoading = false;
      if (status == null) {
        _errorMessage = 'Failed to fetch punch status';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_status == null) {
      return _buildErrorState();
    }

    // Render based on uiState from server
    return _buildStateBasedUI(_status!);
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _errorMessage ?? 'Unknown error',
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _fetchStatus, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildStateBasedUI(PunchStatusResponse status) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Server message
        if (status.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              status.message,
              style: TextStyle(
                color: _getMessageColor(status.uiState),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Main action button based on state
        _buildActionButton(status),

        // Session info if active
        if (status.activeSession != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Session started: ${status.activeSession!.punchInTimeIST}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Color _getMessageColor(PunchUIState state) {
    switch (state) {
      case PunchUIState.waitingApproval:
        return Colors.orange;
      case PunchUIState.canPunchIn:
      case PunchUIState.canPunchOut:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton(PunchStatusResponse status) {
    switch (status.uiState) {
      case PunchUIState.canPunchIn:
        return ElevatedButton.icon(
          onPressed: widget.onPunchIn,
          icon: const Icon(Icons.login),
          label: const Text('Punch In'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        );

      case PunchUIState.canPunchOut:
        return ElevatedButton.icon(
          onPressed: widget.onPunchOut,
          icon: const Icon(Icons.logout),
          label: const Text('Punch Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        );

      case PunchUIState.waitingApproval:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(Icons.hourglass_empty),
              label: Text(
                status.approvalType == ApprovalType.latePunchIn
                    ? 'Waiting for Late Punch-In Approval'
                    : 'Waiting for Early Punch-Out Approval',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        );

      case PunchUIState.idle:
      case PunchUIState.sessionActive:
        if (status.requiresApproval) {
          return ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(status),
            icon: const Icon(Icons.approval),
            label: Text(
              status.approvalType == ApprovalType.latePunchIn
                  ? 'Request Late Punch-In Approval'
                  : 'Request Early Punch-Out Approval',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  void _showApprovalDialog(PunchStatusResponse status) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status.approvalType == ApprovalType.latePunchIn
              ? 'Request Late Punch-In Approval'
              : 'Request Early Punch-Out Approval',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for your request:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason (min 10 characters)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reason must be at least 10 characters'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _submitApprovalRequest(
                status,
                reasonController.text.trim(),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApprovalRequest(
    PunchStatusResponse status,
    String reason,
  ) async {
    final type = status.approvalType == ApprovalType.latePunchIn
        ? 'LATE_PUNCH_IN'
        : 'EARLY_PUNCH_OUT';

    final result = await PunchStatusService.requestApproval(
      employeeId: widget.employeeId,
      employeeName: widget.employeeName,
      type: type,
      reason: reason,
      attendanceId: status.activeSession?.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Request submitted'),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
        ),
      );

      // Refresh status after submission
      await _fetchStatus();
    }
  }
}
