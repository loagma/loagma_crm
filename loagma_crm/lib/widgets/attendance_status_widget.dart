import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/attendance_model.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceStatusWidget extends StatefulWidget {
  final AttendanceModel? attendance;
  final VoidCallback? onTap;
  final bool showLiveLocation;

  const AttendanceStatusWidget({
    super.key,
    this.attendance,
    this.onTap,
    this.showLiveLocation = false,
  });

  @override
  State<AttendanceStatusWidget> createState() => _AttendanceStatusWidgetState();
}

class _AttendanceStatusWidgetState extends State<AttendanceStatusWidget> {
  Timer? _timer;
  String _currentTime = '';
  Duration _currentDuration = Duration.zero;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _updateDuration();
    _startTimer();
    if (widget.showLiveLocation) {
      _startLocationTracking();
    }
  }

  @override
  void didUpdateWidget(AttendanceStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If attendance data changed, update duration immediately
    if (oldWidget.attendance != widget.attendance) {
      _updateDuration();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
      _updateDuration();
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  void _updateDuration() {
    if (widget.attendance?.isPunchedIn == true) {
      final now = DateTime.now();
      final punchInTime = widget.attendance!.punchInTime;

      // Fix timezone issue: Use utility method for safe duration calculation
      final newDuration = _calculateDuration(punchInTime, now);

      setState(() {
        _currentDuration = newDuration.isNegative ? Duration.zero : newDuration;
      });

    } else {
      setState(() {
        _currentDuration = Duration.zero;
      });

    }
  }

  void _startLocationTracking() {
    final locationService = LocationService.instance;
    _locationSubscription = locationService.locationStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  /// Normalize timestamps where backend stored local time as UTC (e.g., with Z).
  DateTime _normalizeTimestamp(DateTime timestamp) {
    if (!timestamp.isUtc) return timestamp;
    // Drop UTC flag but keep the components so it is treated as local time.
    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      timestamp.second,
      timestamp.millisecond,
      timestamp.microsecond,
    );
  }

  /// Safely calculate duration between two DateTime objects, handling timezone differences.
  Duration _calculateDuration(DateTime startTime, DateTime endTime) {
    final normalizedStart = _normalizeTimestamp(startTime);
    final normalizedEnd = _normalizeTimestamp(endTime);
    final duration = normalizedEnd.difference(normalizedStart);
    return duration.isNegative ? Duration.zero : duration;
  }

  String _formatDuration(Duration duration) {
    // Handle null or negative durations
    if (duration.isNegative || duration == Duration.zero) {
      return '00:00:00';
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // Always show hours:minutes:seconds format for clarity
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _getDurationText(AttendanceModel? attendance, bool isPunchedIn) {
    if (attendance == null) {
      return '--:--:--';
    }

    if (isPunchedIn) {
      // Show live duration with blinking indicator
      final durationText = _formatDuration(_currentDuration);
      final indicator = _currentDuration.inSeconds % 2 == 0 ? '●' : '○';
      return '$durationText $indicator';
    } else if (attendance.punchOutTime != null) {
      // Show completed work duration
      return _formatDuration(attendance.totalWorkDuration);
    } else {
      return '--:--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.attendance;
    final isPunchedIn = attendance?.isPunchedIn ?? false;
    final hasAttendance = attendance != null;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPunchedIn
              ? [Colors.green, Colors.green[700]!]
              : hasAttendance
              ? [Colors.blue, Colors.blue[700]!]
              : [Colors.grey, Colors.grey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPunchedIn ? Colors.green : Colors.blue).withValues(
              alpha: 0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Current Time Display
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 20),

                // Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isPunchedIn ? Colors.white : Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isPunchedIn
                          ? 'Currently Working'
                          : hasAttendance
                          ? 'Work Completed'
                          : 'Not Punched In',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                if (hasAttendance) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white30, thickness: 1),
                  const SizedBox(height: 20),

                  // Punch Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTimeInfo(
                        'Punch In',
                        DateFormat('hh:mm a').format(attendance.punchInTime),
                        Icons.login,
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildTimeInfo(
                        'Duration',
                        _getDurationText(attendance, isPunchedIn),
                        Icons.timer,
                      ),
                    ],
                  ),

                  // Live Location Indicator
                  if (widget.showLiveLocation && _currentPosition != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Live Location Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Action Hint
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPunchedIn
                          ? 'Tap to punch out'
                          : hasAttendance
                          ? 'Tap to view details'
                          : 'Tap to punch in',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.touch_app,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
