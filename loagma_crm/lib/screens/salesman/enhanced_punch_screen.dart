import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../services/tracking_service.dart';
import '../../services/employee_working_hours_service.dart';
import '../../services/early_punch_out_approval_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/late_punch_approval_widget.dart';
import '../../widgets/early_punch_out_approval_widget.dart';
import '../../utils/custom_toast.dart';

class EnhancedPunchScreen extends StatefulWidget {
  const EnhancedPunchScreen({super.key});

  @override
  State<EnhancedPunchScreen> createState() => _EnhancedPunchScreenState();
}

class _EnhancedPunchScreenState extends State<EnhancedPunchScreen> with WidgetsBindingObserver {
  static const Color primaryColor = Color(0xFFD7BE69);

  // Punch status
  bool isPunchedIn = false;
  DateTime? punchInTime;
  AttendanceModel? currentAttendance;
  bool isLoadingAttendance = false;

  // Time tracking
  String currentTime = '';
  String currentDate = '';
  Timer? _timer;

  // Location
  Position? _currentPosition;
  bool isLoadingLocation = false;
  String locationStatus = 'Getting location...';

  // Late punch approval
  bool isAfterCutoff = false;
  bool hasLatePunchApproval = false;

  // Working hours configuration
  Map<String, dynamic>? employeeWorkingHours;
  bool isLoadingWorkingHours = false;

  // Early punch-out approval
  bool isBeforeEarlyPunchOutCutoff = false;
  bool hasEarlyPunchOutApproval = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen to app lifecycle
    _updateCurrentTime();
    _startTimeTimer();
    _loadEmployeeWorkingHours();
    _loadTodayPunchData();
    _initializeLocationService();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ensure tracking continues when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print('📱 App backgrounded - tracking should continue via foreground service');
      // Tracking service should continue via LocationService foreground service
    } else if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - verifying tracking is active');
      // Verify tracking is still active when app comes back
      if (isPunchedIn && !TrackingService.instance.isTracking) {
        final attendance = currentAttendance;
        if (attendance != null) {
          final employeeId = UserService.currentUserId;
          final employeeName = UserService.name;
          if (employeeId != null && employeeName != null) {
            TrackingService.instance.startTracking(
              attendanceId: attendance.id,
              employeeId: employeeId,
              employeeName: employeeName,
            );
          }
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh when screen becomes active again
    // This helps catch approval status changes when user returns from notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkCutoffTime();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (!TrackingService.instance.isTracking) {
      LocationService.instance.stopLocationTracking();
    }
    super.dispose();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    });
  }

  void _startTimeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateCurrentTime();
        _checkCutoffTime();
        // Trigger rebuild to update duration display when punched in
        if (isPunchedIn) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _loadEmployeeWorkingHours() async {
    setState(() => isLoadingWorkingHours = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null || employeeId.isEmpty) {
        print('❌ Employee ID not found');
        return;
      }

      final result = await EmployeeWorkingHoursService.getWorkingHours(
        employeeId,
      );

      if (result['success'] == true) {
        setState(() {
          employeeWorkingHours = result['data'];
        });
        print('✅ Employee working hours loaded: $employeeWorkingHours');
        _checkCutoffTime(); // Check cutoff times after loading working hours
      } else {
        print('❌ Failed to load working hours: ${result['message']}');
        // Use default working hours if API fails
        setState(() {
          employeeWorkingHours = {
            'workStartTime': '09:00:00',
            'workEndTime': '18:00:00',
            'latePunchInGraceMinutes': 45,
            'earlyPunchOutGraceMinutes': 30,
            'latePunchInCutoffTime': '09:45:00',
            'earlyPunchOutCutoffTime': '17:30:00',
          };
        });
        _checkCutoffTime();
      }
    } catch (e) {
      print('❌ Error loading working hours: $e');
      // Use default working hours on error
      setState(() {
        employeeWorkingHours = {
          'workStartTime': '09:00:00',
          'workEndTime': '18:00:00',
          'latePunchInGraceMinutes': 45,
          'earlyPunchOutGraceMinutes': 30,
          'latePunchInCutoffTime': '09:45:00',
          'earlyPunchOutCutoffTime': '17:30:00',
        };
      });
      _checkCutoffTime();
    } finally {
      setState(() => isLoadingWorkingHours = false);
    }
  }

  void _checkCutoffTime() {
    if (employeeWorkingHours == null) {
      // Working hours not loaded yet, skip cutoff check
      return;
    }

    final newIsAfterCutoff =
        EmployeeWorkingHoursService.isAfterLatePunchInCutoff(
          employeeWorkingHours!,
        );
    final newIsBeforeEarlyPunchOutCutoff =
        EmployeeWorkingHoursService.isBeforeEarlyPunchOutCutoff(
          employeeWorkingHours!,
        );

    print('🕘 Dynamic cutoff check:');
    print(
      '  - Working hours: ${employeeWorkingHours!['workStartTime']} - ${employeeWorkingHours!['workEndTime']}',
    );
    print(
      '  - Late punch-in cutoff: ${employeeWorkingHours!['latePunchInCutoffTime']}',
    );
    print(
      '  - Early punch-out cutoff: ${employeeWorkingHours!['earlyPunchOutCutoffTime']}',
    );
    print('  - isAfterCutoff: $newIsAfterCutoff');
    print('  - isBeforeEarlyPunchOutCutoff: $newIsBeforeEarlyPunchOutCutoff');

    // Always update state to ensure UI reflects current time
    setState(() {
      isAfterCutoff = newIsAfterCutoff;
      isBeforeEarlyPunchOutCutoff = newIsBeforeEarlyPunchOutCutoff;
    });
  }

  Future<void> _initializeLocationService() async {
    if (!mounted) return;

    setState(() {
      isLoadingLocation = true;
      locationStatus = 'Initializing location services...';
    });

    try {
      final locationService = LocationService.instance;
      final hasPermission = await locationService.checkLocationPermission();

      if (!hasPermission) {
        if (mounted) {
          final shouldRequestPermission =
              await LocationService.showLocationPermissionDialog(context);

          if (!shouldRequestPermission) {
            if (mounted) {
              setState(() {
                locationStatus = 'Location permission required for attendance';
                isLoadingLocation = false;
              });
            }
            return;
          }
        }
      }

      // Try to get location with timeout
      try {
        final initialPosition = await locationService
            .getCurrentLocation()
            .timeout(const Duration(seconds: 10));

        if (initialPosition != null && mounted) {
          setState(() {
            _currentPosition = initialPosition;
            locationStatus =
                'Location active (±${initialPosition.accuracy.toStringAsFixed(0)}m)';
            isLoadingLocation = false;
          });
        }
      } catch (timeoutError) {
        // If location times out, try to start tracking anyway
        print('Location timeout, trying to start tracking: $timeoutError');

        final success = await locationService.startLocationTracking();

        if (success && mounted) {
          locationService.locationStream.listen(
            (Position position) {
              if (mounted) {
                setState(() {
                  _currentPosition = position;
                  locationStatus =
                      'Location active (±${position.accuracy.toStringAsFixed(0)}m)';
                  isLoadingLocation = false;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  locationStatus = 'Location error. Tap refresh to retry.';
                  isLoadingLocation = false;
                });
              }
            },
          );
        } else {
          if (mounted) {
            setState(() {
              locationStatus = 'Location timeout. Tap refresh to retry.';
              isLoadingLocation = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationStatus = 'Location error. Tap refresh to retry.';
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadTodayPunchData() async {
    setState(() => isLoadingAttendance = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null || employeeId.isEmpty) {
        CustomToast.showError(
          context,
          'Employee ID not found. Please login again.',
        );
        return;
      }

      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (attendance != null) {
        print(
          '📊 Loaded attendance: isPunchedIn=${attendance.isPunchedIn}, punchInTime=${attendance.punchInTime}',
        );

        // Check if there's an approved early punch-out request for this attendance
        bool hasApprovedEarlyPunchOut = false;
        if (attendance.isPunchedIn) {
          final approvalResult =
              await EarlyPunchOutApprovalService.getApprovalStatus(
                attendance.id,
              );
          if (approvalResult['success'] == true &&
              approvalResult['data'] != null &&
              approvalResult['data']['status'] == 'APPROVED') {
            hasApprovedEarlyPunchOut = true;
            print('📊 Found approved early punch-out request');
          }
        }

        setState(() {
          currentAttendance = attendance;
          isPunchedIn = attendance.isPunchedIn;
          punchInTime = attendance.punchInTime;
          hasEarlyPunchOutApproval = hasApprovedEarlyPunchOut;
        });

        if (attendance.isPunchedIn) {
          final employeeId = UserService.currentUserId;
          final employeeName = UserService.name;
          if (employeeId != null && employeeName != null) {
            await TrackingService.instance.startTracking(
              attendanceId: attendance.id,
              employeeId: employeeId,
              employeeName: employeeName,
            );
          }
        }
      } else {
        print('📊 No attendance found for today');
        setState(() {
          currentAttendance = null;
          isPunchedIn = false;
          punchInTime = null;
          hasEarlyPunchOutApproval = false;
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
      CustomToast.showError(context, 'Failed to load attendance data');
    } finally {
      setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _handlePunchIn() async {
    HapticFeedback.mediumImpact();

    // Check location
    if (_currentPosition == null) {
      CustomToast.showError(context, 'Location required for punch in');
      return;
    }

    // Show punch in dialog
    final result = await _showPunchInDialog();
    if (result == null || result['confirmed'] != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final employeeId = UserService.currentUserId;
      final employeeName = UserService.name;

      if (employeeId == null || employeeName == null) {
        Navigator.pop(context);
        CustomToast.showError(context, 'Employee information not found');
        return;
      }

      // For late punch-in, pass approval flag if user has approval
      final response = await AttendanceService.punchIn(
        employeeId: employeeId,
        employeeName: employeeName,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: result['photoBase64'],
        bikeKmStart: result['bikeKm'],
      );

      print('🔍 Punch-in response: $response');

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = true;
          punchInTime = attendance?.punchInTime;
          hasLatePunchApproval = false; // Clear approval after use
        });

        if (attendance != null) {
          await TrackingService.instance.startTracking(
            attendanceId: attendance.id,
            employeeId: employeeId,
            employeeName: employeeName,
          );
        }

        CustomToast.showSuccess(context, 'Punched in successfully!');
      } else {
        final errorMessage = response['message'] ?? '';

        // Check if it's a late punch-in error that requires approval
        if (errorMessage.contains('9:45 AM')) {
          CustomToast.showError(context, errorMessage);
        } else {
          CustomToast.showError(
            context,
            errorMessage.isNotEmpty ? errorMessage : 'Failed to punch in',
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      CustomToast.showError(context, 'Error: $e');
    }
  }

  Future<Map<String, dynamic>?> _showPunchInDialog() async {
    File? photo;
    String? photoBase64;
    final bikeKmController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              width: screenWidth * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: screenHeight * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.login,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Punch In Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Photo *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (photo != null)
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          photo!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              photo = null;
                                              photoBase64 = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final pickedPhoto = await _imagePicker
                                              .pickImage(
                                                source: ImageSource.camera,
                                                imageQuality: 50,
                                                maxWidth: 1024,
                                                maxHeight: 1024,
                                              );
                                          if (pickedPhoto != null) {
                                            final file = File(pickedPhoto.path);
                                            final bytes = await file
                                                .readAsBytes();
                                            setState(() {
                                              photo = file;
                                              photoBase64 = base64Encode(bytes);
                                            });
                                          }
                                        } catch (e) {
                                          CustomToast.showError(
                                            context,
                                            'Error capturing photo',
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                      ),
                                      label: const Text('Take Photo'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Bike KM Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 18,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Bike KM Reading',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: bikeKmController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter starting KM',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    suffixText: 'km',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Summary
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Time: $currentTime',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Location: ${_currentPosition?.latitude.toStringAsFixed(4) ?? "N/A"}, ${_currentPosition?.longitude.toStringAsFixed(4) ?? "N/A"}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (photo == null) {
                                CustomToast.showError(
                                  context,
                                  'Please take a photo',
                                );
                                return;
                              }
                              Navigator.pop(context, {
                                'confirmed': true,
                                'photo': photo,
                                'photoBase64': photoBase64,
                                'bikeKm': bikeKmController.text.trim(),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Punch In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Duration get liveWorkDuration {
    if (punchInTime == null) {
      print('⏰ Duration calculation: punchInTime is null');
      return Duration.zero;
    }

    final now = DateTime.now();
    final punchIn = punchInTime!;

    // Ensure both times are in the same timezone (local)
    final localPunchIn = punchIn.isUtc ? punchIn.toLocal() : punchIn;
    final diff = now.difference(localPunchIn);

    print(
      '⏰ Duration calculation: punchInTime=$localPunchIn, now=$now, diff=${diff.inSeconds}s',
    );

    // Return zero if negative (shouldn't happen but safety check)
    return diff.isNegative ? Duration.zero : diff;
  }

  String _getCurrentDurationText() {
    final duration = liveWorkDuration;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  /// Get formatted late punch-in cutoff time (e.g., "9:45 AM")
  String _getFormattedLatePunchInCutoff() {
    if (employeeWorkingHours == null) return '9:45 AM';

    final cutoffTimeStr =
        employeeWorkingHours!['latePunchInCutoffTime'] as String?;
    if (cutoffTimeStr == null) return '9:45 AM';

    try {
      final parts = cutoffTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '9:45 AM';
    }
  }

  /// Get formatted early punch-out cutoff time (e.g., "5:30 PM")
  String _getFormattedEarlyPunchOutCutoff() {
    if (employeeWorkingHours == null) return '5:30 PM';

    final cutoffTimeStr =
        employeeWorkingHours!['earlyPunchOutCutoffTime'] as String?;
    if (cutoffTimeStr == null) return '5:30 PM';

    try {
      final parts = cutoffTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '5:30 PM';
    }
  }

  /// Get time remaining until late punch-in cutoff
  String _getTimeUntilLatePunchInCutoff() {
    if (employeeWorkingHours == null) return 'Loading...';
    return EmployeeWorkingHoursService.getTimeUntilLatePunchInCutoff(
      employeeWorkingHours!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Punch System'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadEmployeeWorkingHours();
          await _loadTodayPunchData();
          await _initializeLocationService();
          // Force refresh of approval status by rebuilding the widget
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Current Time Card
              _buildCurrentTimeCard(),

              // Status Card
              _buildStatusCard(),

              // Punch Button or Late Approval Widget
              if (isPunchedIn) ...[
                // Debug: User is punched in
                _buildPunchedInCard(),
              ] else if (isAfterCutoff) ...[
                // Debug: After cutoff, should show approval widget
                // print(
                //   '🔍 BUILD: Showing approval widget (isAfterCutoff=$isAfterCutoff, isPunchedIn=$isPunchedIn)',
                // ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LatePunchApprovalWidget(
                        employeeWorkingHours: employeeWorkingHours,
                        onApprovalRequested: () {
                          // Refresh status after approval request
                          setState(() {});
                        },
                        onApprovalCodeValidated: (String status) {
                          // Store the approval status (no OTP needed)
                          setState(() {
                            hasLatePunchApproval = true;
                          });

                          // Show success message
                          CustomToast.showSuccess(
                            context,
                            'Approval received! You can now punch in.',
                          );
                        },
                        onApprovalReceived: () {
                          // Refresh attendance status when approval is received or code is used
                          _loadTodayPunchData();
                        },
                      ),
                    ),
                    // Show punch-in button when approval is received
                    if (hasLatePunchApproval) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Approval received! You can now punch in directly.',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed:
                                    (_currentPosition != null &&
                                        !isLoadingLocation)
                                    ? () => _handlePunchIn()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: isLoadingAttendance
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login, size: 28),
                                          const SizedBox(width: 12),
                                          Text(
                                            (_currentPosition != null &&
                                                    !isLoadingLocation)
                                                ? 'PUNCH IN (APPROVED)'
                                                : 'Getting Location...',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                // Debug: Before cutoff, showing normal punch button
                // print(
                //   '🔍 BUILD: Showing normal punch button (isAfterCutoff=$isAfterCutoff, isPunchedIn=$isPunchedIn)',
                // ),
                _buildPunchButton(),
              ],

              // Location Info
              _buildLocationInfo(),

              // Debug info for troubleshooting
              if (isPunchedIn)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEBUG INFO:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'isPunchedIn: $isPunchedIn',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'isBeforeEarlyPunchOutCutoff: $isBeforeEarlyPunchOutCutoff',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'currentAttendance: ${currentAttendance?.id}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Current time: ${DateTime.now()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Should show approval: ${isBeforeEarlyPunchOutCutoff && currentAttendance != null}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              (isBeforeEarlyPunchOutCutoff &&
                                  currentAttendance != null)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: isAfterCutoff && !isPunchedIn
          ? FloatingActionButton.small(
              onPressed: () {
                // Force refresh the approval widget
                setState(() {});
                CustomToast.showSuccess(
                  context,
                  'Refreshing approval status...',
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCurrentTimeCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10.0,
            offset: const Offset(0.0, 5.0),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentDate,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              UserService.name ?? 'Employee',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isAfterCutoff && !isPunchedIn && !hasLatePunchApproval) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'After ${_getFormattedLatePunchInCutoff()} - Approval Required',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Show approved badge when user has approval
          if (isAfterCutoff && !isPunchedIn && hasLatePunchApproval) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Approved - Ready to Punch In',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isPunchedIn ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPunchedIn ? 'Currently Working' : 'Not Punched In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPunchedIn ? Colors.green : Colors.grey[700],
                ),
              ),
            ],
          ),
          if (isPunchedIn && punchInTime != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  'Punch In',
                  DateFormat('hh:mm a').format(punchInTime!),
                  Icons.login,
                  Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildTimeInfo(
                  'Duration',
                  _getCurrentDurationText(),
                  Icons.timer,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPunchButton() {
    final canPunchIn = _currentPosition != null && !isLoadingLocation;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isAfterCutoff) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Punch-in available until ${_getFormattedLatePunchInCutoff()} (${_getTimeUntilLatePunchInCutoff()})',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: canPunchIn ? () => _handlePunchIn() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: isLoadingAttendance
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          canPunchIn ? 'PUNCH IN' : 'Getting Location...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchedInCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Session Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Started at ${DateFormat('hh:mm a').format(punchInTime!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  _getCurrentDurationText(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Early Punch-Out Approval Widget or Punch-Out Button
          if (isBeforeEarlyPunchOutCutoff &&
              currentAttendance != null &&
              !hasEarlyPunchOutApproval)
            EarlyPunchOutApprovalWidget(
              attendanceId: currentAttendance!.id,
              employeeWorkingHours: employeeWorkingHours,
              onApprovalRequested: () {
                // Refresh status after approval request
                setState(() {});
              },
              onApprovalCodeValidated: (String status) {
                // Store the approval status - user will click punch out button
                setState(() {
                  hasEarlyPunchOutApproval = true;
                });
                // Don't auto-trigger punch out - let user click the button
                // This prevents race conditions and UI state issues
              },
            )
          else if (hasEarlyPunchOutApproval)
            // Show punch-out button when early approval is received
            _buildEarlyPunchOutButton()
          else
            _buildPunchOutButton(),
        ],
      ),
    );
  }

  Widget _buildPunchOutButton() {
    final canPunchOut = _currentPosition != null && !isLoadingLocation;

    return Column(
      children: [
        // Show info message based on current time
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Normal punch-out available after ${_getFormattedEarlyPunchOutCutoff()}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canPunchOut ? () => _handlePunchOut() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: isLoadingAttendance
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        canPunchOut ? 'PUNCH OUT' : 'Getting Location...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarlyPunchOutButton() {
    final canPunchOut = _currentPosition != null && !isLoadingLocation;

    return Column(
      children: [
        // Show early approval success message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Early punch-out approved! You can now punch out.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canPunchOut ? () => _handlePunchOut() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: isLoadingAttendance
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        canPunchOut
                            ? 'PUNCH OUT (APPROVED)'
                            : 'Getting Location...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePunchOut() async {
    HapticFeedback.mediumImpact();

    // Check location
    if (_currentPosition == null) {
      CustomToast.showError(context, 'Location required for punch out');
      return;
    }

    // Check if attendance exists
    if (currentAttendance == null) {
      CustomToast.showError(context, 'No active attendance session found');
      return;
    }

    // Show punch out dialog
    final result = await _showPunchOutDialog();
    if (result == null || result['confirmed'] != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await AttendanceService.punchOut(
        attendanceId: currentAttendance!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: result['photoBase64'],
        bikeKmEnd: result['bikeKm'],
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = false;
          punchInTime = null;
          hasEarlyPunchOutApproval = false; // Clear approval after use
        });

        await TrackingService.instance.stopTracking();

        CustomToast.showSuccess(context, 'Punched out successfully!');
      } else {
        // Check if it's an early punch-out error that requires approval
        if (response['message']?.contains('6:30 PM') == true) {
          CustomToast.showError(context, response['message']);
        } else {
          CustomToast.showError(
            context,
            response['message'] ?? 'Failed to punch out',
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      CustomToast.showError(context, 'Error: $e');
    }
  }

  Future<Map<String, dynamic>?> _showPunchOutDialog() async {
    File? photo;
    String? photoBase64;
    final bikeKmController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              width: screenWidth * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: screenHeight * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Punch Out Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Photo *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (photo != null)
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          photo!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              photo = null;
                                              photoBase64 = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final pickedPhoto = await _imagePicker
                                              .pickImage(
                                                source: ImageSource.camera,
                                                imageQuality: 50,
                                                maxWidth: 1024,
                                                maxHeight: 1024,
                                              );
                                          if (pickedPhoto != null) {
                                            final file = File(pickedPhoto.path);
                                            final bytes = await file
                                                .readAsBytes();
                                            setState(() {
                                              photo = file;
                                              photoBase64 = base64Encode(bytes);
                                            });
                                          }
                                        } catch (e) {
                                          CustomToast.showError(
                                            context,
                                            'Error capturing photo',
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                      ),
                                      label: const Text('Take Photo'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Bike KM Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 18,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Bike KM Reading',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: bikeKmController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter ending KM',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    suffixText: 'km',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Summary
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Time: $currentTime',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Location: ${_currentPosition?.latitude.toStringAsFixed(4) ?? "N/A"}, ${_currentPosition?.longitude.toStringAsFixed(4) ?? "N/A"}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Duration: ${_getCurrentDurationText()}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (photo == null) {
                                CustomToast.showError(
                                  context,
                                  'Please take a photo',
                                );
                                return;
                              }
                              Navigator.pop(context, {
                                'confirmed': true,
                                'photo': photo,
                                'photoBase64': photoBase64,
                                'bikeKm': bikeKmController.text.trim(),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Punch Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _currentPosition != null ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _initializeLocationService,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Location',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            locationStatus,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (_currentPosition != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
              'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

}
