import 'package:flutter/material.dart';
import 'dart:async';

class LiveAttendanceStatus extends StatefulWidget {
  final bool isLiveTrackingEnabled;
  final int activeEmployees;
  final DateTime? lastUpdate;
  final VoidCallback onToggleLiveTracking;
  final VoidCallback onRefresh;

  const LiveAttendanceStatus({
    super.key,
    required this.isLiveTrackingEnabled,
    required this.activeEmployees,
    this.lastUpdate,
    required this.onToggleLiveTracking,
    required this.onRefresh,
  });

  @override
  State<LiveAttendanceStatus> createState() => _LiveAttendanceStatusState();
}

class _LiveAttendanceStatusState extends State<LiveAttendanceStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _updateTimer;
  String _timeAgo = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isLiveTrackingEnabled) {
      _animationController.repeat(reverse: true);
    }

    _startUpdateTimer();
    _updateTimeAgo();
  }

  @override
  void didUpdateWidget(LiveAttendanceStatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLiveTrackingEnabled != oldWidget.isLiveTrackingEnabled) {
      if (widget.isLiveTrackingEnabled) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }

    if (widget.lastUpdate != oldWidget.lastUpdate) {
      _updateTimeAgo();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeAgo();
    });
  }

  void _updateTimeAgo() {
    if (widget.lastUpdate != null) {
      final difference = DateTime.now().difference(widget.lastUpdate!);
      setState(() {
        if (difference.inSeconds < 60) {
          _timeAgo = 'Just now';
        } else if (difference.inMinutes < 60) {
          _timeAgo = '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          _timeAgo = '${difference.inHours}h ago';
        } else {
          _timeAgo = '${difference.inDays}d ago';
        }
      });
    } else {
      setState(() {
        _timeAgo = 'Never';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isLiveTrackingEnabled
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (widget.isLiveTrackingEnabled ? Colors.green : Colors.grey)
                .withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isLiveTrackingEnabled
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isLiveTrackingEnabled
                            ? Icons.location_on
                            : Icons.location_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.isLiveTrackingEnabled ? 'Active' : 'Paused',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isLiveTrackingEnabled,
                onChanged: (_) => widget.onToggleLiveTracking(),
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.3),
                inactiveThumbColor: Colors.white.withOpacity(0.7),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Active Employees',
                  '${widget.activeEmployees}',
                  Icons.people,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatusItem('Last Update', _timeAgo, Icons.update),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    _showLiveTrackingInfo(context);
                  },
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'Live Tracking Info',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showLiveTrackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Live Tracking Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Auto Refresh',
              widget.isLiveTrackingEnabled ? 'Every 30 seconds' : 'Disabled',
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Active Employees', 'Employees currently working'),
            const SizedBox(height: 8),
            _buildInfoRow('Location Updates', 'Real-time GPS tracking'),
            const SizedBox(height: 8),
            _buildInfoRow('Data Usage', 'Minimal background sync'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
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
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }
}
