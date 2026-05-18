// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import '../models/attendance_model.dart';
// import '../services/location_service.dart';
// import 'package:geolocator/geolocator.dart';

// class CompactAttendanceWidget extends StatefulWidget {
//   final AttendanceModel? attendance;
//   final VoidCallback? onTap;
//   final bool showLiveLocation;

//   const CompactAttendanceWidget({
//     super.key,
//     this.attendance,
//     this.onTap,
//     this.showLiveLocation = false,
//   });

//   @override
//   State<CompactAttendanceWidget> createState() =>
//       _CompactAttendanceWidgetState();
// }

// class _CompactAttendanceWidgetState extends State<CompactAttendanceWidget> {
//   Timer? _timer;
//   String _currentTime = '';
//   Duration _currentDuration = Duration.zero;
//   Position? _currentPosition;
//   StreamSubscription<Position>? _locationSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _updateDuration();
//     _startTimer();
//     if (widget.showLiveLocation) {
//       _startLocationTracking();
//     }
//   }

//   @override
//   void didUpdateWidget(CompactAttendanceWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.attendance != widget.attendance) {
//       _updateDuration();
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _locationSubscription?.cancel();
//     super.dispose();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateTime();
//       _updateDuration();
//     });
//   }

//   void _updateTime() {
//     setState(() {
//       _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
//     });
//   }

//   void _updateDuration() {
//     if (widget.attendance?.isPunchedIn == true) {
//       final now = DateTime.now();
//       final punchInTime = widget.attendance!.punchInTime;
//       final newDuration = _calculateDuration(punchInTime, now);
//       setState(() {
//         _currentDuration = newDuration.isNegative ? Duration.zero : newDuration;
//       });
//     } else {
//       setState(() {
//         _currentDuration = Duration.zero;
//       });
//     }
//   }

//   void _startLocationTracking() {
//     final locationService = LocationService.instance;
//     _locationSubscription = locationService.locationStream.listen((position) {
//       setState(() {
//         _currentPosition = position;
//       });
//     });
//   }

//   DateTime _normalizeTimestamp(DateTime timestamp) {
//     if (!timestamp.isUtc) return timestamp;
//     return DateTime(
//       timestamp.year,
//       timestamp.month,
//       timestamp.day,
//       timestamp.hour,
//       timestamp.minute,
//       timestamp.second,
//       timestamp.millisecond,
//       timestamp.microsecond,
//     );
//   }

//   Duration _calculateDuration(DateTime startTime, DateTime endTime) {
//     final normalizedStart = _normalizeTimestamp(startTime);
//     final normalizedEnd = _normalizeTimestamp(endTime);
//     final duration = normalizedEnd.difference(normalizedStart);
//     return duration.isNegative ? Duration.zero : duration;
//   }

//   String _formatDuration(Duration duration) {
//     if (duration.isNegative || duration == Duration.zero) {
//       return '00:00:00';
//     }

//     String twoDigits(int n) => n.toString().padLeft(2, '0');

//     final totalSeconds = duration.inSeconds;
//     final hours = totalSeconds ~/ 3600;
//     final minutes = (totalSeconds % 3600) ~/ 60;
//     final seconds = totalSeconds % 60;

//     return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
//   }

//   String _getDurationText(AttendanceModel? attendance, bool isPunchedIn) {
//     if (attendance == null) {
//       return '--:--:--';
//     }

//     if (isPunchedIn) {
//       final durationText = _formatDuration(_currentDuration);
//       final indicator = _currentDuration.inSeconds % 2 == 0 ? '●' : '○';
//       return '$durationText $indicator';
//     } else if (attendance.punchOutTime != null) {
//       return _formatDuration(attendance.totalWorkDuration);
//     } else {
//       return '--:--:--';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attendance = widget.attendance;
//     final isPunchedIn = attendance?.isPunchedIn ?? false;
//     final hasAttendance = attendance != null;

//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isPunchedIn
//               ? [Colors.green, Colors.green[700]!]
//               : hasAttendance
//               ? [Colors.blue, Colors.blue[700]!]
//               : [Colors.grey, Colors.grey[700]!],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: (isPunchedIn ? Colors.green : Colors.blue).withValues(
//               alpha: 0.3,
//             ),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: widget.onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Current Time
//                 Text(
//                   _currentTime,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     letterSpacing: 1,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   DateFormat('EEE, MMM dd').format(DateTime.now()),
//                   style: const TextStyle(fontSize: 11, color: Colors.white70),
//                 ),
//                 const SizedBox(height: 12),

//                 // Status
//                 Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: isPunchedIn ? Colors.white : Colors.white70,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         isPunchedIn
//                             ? 'Working'
//                             : hasAttendance
//                             ? 'Completed'
//                             : 'Not Punched',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 if (hasAttendance) ...[
//                   const SizedBox(height: 12),
//                   const Divider(color: Colors.white30, height: 1),
//                   const SizedBox(height: 12),

//                   // Punch Details
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Punch In',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.white70,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             DateFormat(
//                               'hh:mm a',
//                             ).format(attendance.punchInTime),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           const Text(
//                             'Duration',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.white70,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             _getDurationText(attendance, isPunchedIn),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   // Live Location
//                   if (widget.showLiveLocation && _currentPosition != null) ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.location_on,
//                           color: Colors.white70,
//                           size: 12,
//                         ),
//                         const SizedBox(width: 4),
//                         const Text(
//                           'Live Tracking',
//                           style: TextStyle(color: Colors.white70, fontSize: 10),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],

//                 // Action Hint
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.touch_app,
//                       color: Colors.white60,
//                       size: 12,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       isPunchedIn ? 'Tap to punch out' : 'Tap to punch in',
//                       style: const TextStyle(
//                         color: Colors.white60,
//                         fontSize: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/attendance_model.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class CompactAttendanceWidget extends StatefulWidget {
  final AttendanceModel? attendance;
  final VoidCallback? onTap;
  final bool showLiveLocation;

  const CompactAttendanceWidget({
    super.key,
    this.attendance,
    this.onTap,
    this.showLiveLocation = false,
  });

  @override
  State<CompactAttendanceWidget> createState() =>
      _CompactAttendanceWidgetState();
}

class _CompactAttendanceWidgetState extends State<CompactAttendanceWidget> {
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
  void didUpdateWidget(CompactAttendanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      if (!mounted) return;
      _updateTime();
      _updateDuration();
    });
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  void _updateDuration() {
    if (!mounted) return;
    if (widget.attendance?.isPunchedIn == true) {
      final now = DateTime.now();
      final punchInTime = widget.attendance!.punchInTime;
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
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });
  }

  DateTime _normalizeTimestamp(DateTime timestamp) {
    if (!timestamp.isUtc) return timestamp;
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

  Duration _calculateDuration(DateTime startTime, DateTime endTime) {
    final normalizedStart = _normalizeTimestamp(startTime);
    final normalizedEnd = _normalizeTimestamp(endTime);
    final duration = normalizedEnd.difference(normalizedStart);
    return duration.isNegative ? Duration.zero : duration;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _getDurationText(AttendanceModel? attendance, bool isPunchedIn) {
    if (attendance == null) return '--:--:--';
    if (isPunchedIn) {
      final durationText = _formatDuration(_currentDuration);
      final indicator = _currentDuration.inSeconds % 2 == 0 ? '●' : '○';
      return '$durationText $indicator';
    } else if (attendance.punchOutTime != null) {
      return _formatDuration(attendance.totalWorkDuration);
    }
    return '--:--:--';
  }

  // ── Color helpers ────────────────────────────────────────────
  List<Color> get _gradientColors {
    if (widget.attendance?.isPunchedIn == true) {
      return [const Color(0xFF1D9E75), const Color(0xFF0F6E56)];
    } else if (widget.attendance != null) {
      return [const Color(0xFF378ADD), const Color(0xFF185FA5)];
    }
    return [const Color(0xFF888780), const Color(0xFF5F5E5A)];
  }

  Color get _shadowColor {
    if (widget.attendance?.isPunchedIn == true) {
      return const Color(0xFF1D9E75).withOpacity(0.35);
    } else if (widget.attendance != null) {
      return const Color(0xFF378ADD).withOpacity(0.35);
    }
    return const Color(0xFF888780).withOpacity(0.25);
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.attendance;
    final isPunchedIn = attendance?.isPunchedIn ?? false;
    final hasAttendance = attendance != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ── Decorative background circles ──
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -32,
              right: 24,
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // ── Main content ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isPunchedIn, hasAttendance),
                      const SizedBox(height: 12),
                      if (hasAttendance) ...[
                        _buildDivider(),
                        const SizedBox(height: 12),
                        _buildPunchDetails(attendance, isPunchedIn),
                      ] else
                        _buildNoPunchMessage(),
                      const SizedBox(height: 10),
                      _buildFooter(isPunchedIn),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: time + date + status badge ──────────────────────
  Widget _buildHeader(bool isPunchedIn, bool hasAttendance) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('EEE, MMM dd').format(DateTime.now()),
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        // Status badge pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPunchedIn ? Colors.white : Colors.white60,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isPunchedIn
                    ? 'Working'
                    : hasAttendance
                    ? 'Completed'
                    : 'Not Punched',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Divider ─────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(height: 0.5, color: Colors.white.withOpacity(0.25));
  }

  // ── Punch In / Duration / Punch Out row ─────────────────────
  Widget _buildPunchDetails(AttendanceModel attendance, bool isPunchedIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailColumn(
          label: 'Punch In',
          value: DateFormat('hh:mm a').format(attendance.punchInTime),
          crossAlign: CrossAxisAlignment.start,
        ),
        if (!isPunchedIn && attendance.punchOutTime != null)
          _buildDetailColumn(
            label: 'Punch Out',
            value: DateFormat('hh:mm a').format(attendance.punchOutTime!),
            crossAlign: CrossAxisAlignment.center,
          ),
        _buildDetailColumn(
          label: isPunchedIn ? 'Duration' : 'Total',
          value: _getDurationText(attendance, isPunchedIn),
          crossAlign: CrossAxisAlignment.end,
          mono: true,
        ),
      ],
    );
  }

  Widget _buildDetailColumn({
    required String label,
    required String value,
    required CrossAxisAlignment crossAlign,
    bool mono = false,
  }) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  // ── No punch placeholder ─────────────────────────────────────
  Widget _buildNoPunchMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          'No attendance recorded today',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }

  // ── Footer: live tracking + tap hint ────────────────────────
  Widget _buildFooter(bool isPunchedIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live tracking badge
        if (widget.showLiveLocation && _currentPosition != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.white60, size: 11),
              const SizedBox(width: 3),
              const Text(
                'Live Tracking',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          )
        else
          const SizedBox.shrink(),

        // Tap hint
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, color: Colors.white38, size: 11),
            const SizedBox(width: 3),
            Text(
              isPunchedIn ? 'Tap to punch out' : 'Tap to punch in',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
