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
import '../../services/late_punch_approval_service.dart';
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

class _EnhancedPunchScreenState extends State<EnhancedPunchScreen> {
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
  String? validApprovalCode;

  // Early punch-out approval
  bool isBeforeEarlyPunchOutCutoff = false;
  String? validEarlyPunchOutCode;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _startTimeTimer();
    _loadTodayPunchData();
    _initializeLocationService();
    _checkCutoffTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    LocationService.instance.stopLocationTracking();
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
      }
    });
  }

  void _checkCutoffTime() {
    final wasAfterCutoff = isAfterCutoff;
    final newIsAfterCutoff = LatePunchApprovalService.isAfterCutoffTime();

    final wasBeforeEarlyPunchOutCutoff = isBeforeEarlyPunchOutCutoff;
    final newIsBeforeEarlyPunchOutCutoff =
        EarlyPunchOutApprovalService.isBeforeEarlyPunchOutCutoff();

    if (wasAfterCutoff != newIsAfterCutoff ||
        wasBeforeEarlyPunchOutCutoff != newIsBeforeEarlyPunchOutCutoff) {
      setState(() {
        isAfterCutoff = newIsAfterCutoff;
        isBeforeEarlyPunchOutCutoff = newIsBeforeEarlyPunchOutCutoff;
      });
    }
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
                locationStatus = 'Location error: ${error.toString()}';
                isLoadingLocation = false;
              });
            }
          },
        );

        final initialPosition = await locationService.getCurrentLocation();
        if (initialPosition != null && mounted) {
          setState(() {
            _currentPosition = initialPosition;
            locationStatus =
                'Location active (±${initialPosition.accuracy.toStringAsFixed(0)}m)';
            isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            locationStatus = 'Failed to start location tracking';
            isLoadingLocation = false;
          });
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
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = attendance.isPunchedIn;
          punchInTime = attendance.punchInTime;
        });
      } else {
        setState(() {
          currentAttendance = null;
          isPunchedIn = false;
          punchInTime = null;
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
      CustomToast.showError(context, 'Failed to load attendance data');
    } finally {
      setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _handlePunchIn({String? approvalCode}) async {
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

      final response = await AttendanceService.punchIn(
        employeeId: employeeId,
        employeeName: employeeName,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: result['photoBase64'],
        bikeKmStart: result['bikeKm'],
        approvalCode: approvalCode ?? validApprovalCode,
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = true;
          punchInTime = attendance?.punchInTime;
          validApprovalCode = null; // Clear used code
        });
        CustomToast.showSuccess(context, 'Punched in successfully!');
      } else {
        // Check if it's a late punch-in error that requires approval
        if (response['message']?.contains('9:45 AM') == true) {
          CustomToast.showError(context, response['message']);
        } else {
          CustomToast.showError(
            context,
            response['message'] ?? 'Failed to punch in',
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.login, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Punch In Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Photo *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (photo != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                photo!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    photo = null;
                                    photoBase64 = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final pickedPhoto = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 50,
                                maxWidth: 1024,
                                maxHeight: 1024,
                              );
                              if (pickedPhoto != null) {
                                final file = File(pickedPhoto.path);
                                final bytes = await file.readAsBytes();
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
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bike KM Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bike KM Reading',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bikeKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter starting KM reading',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'km',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.access_time, 'Time', currentTime),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (photo == null) {
                  CustomToast.showError(context, 'Please take a photo');
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Punch In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Duration get liveWorkDuration {
    if (punchInTime == null) return Duration.zero;
    final now = DateTime.now();
    final diff = now.difference(punchInTime!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Enhanced Punch System'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTodayPunchData();
          await _initializeLocationService();
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
              if (isPunchedIn)
                _buildPunchedInCard()
              else if (isAfterCutoff)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LatePunchApprovalWidget(
                    onApprovalRequested: () {
                      // Refresh status after approval request
                      setState(() {});
                    },
                    onApprovalReceived: () {
                      // Set flag that approval is received and allow punch in
                      setState(() {
                        validApprovalCode =
                            'validated'; // This will be handled by the widget
                      });
                    },
                  ),
                )
              else
                _buildPunchButton(),

              // Location Info
              _buildLocationInfo(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
            blurRadius: 10,
            offset: const Offset(0, 5),
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
              letterSpacing: 2,
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
          if (isAfterCutoff && !isPunchedIn) ...[
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
                  const Text(
                    'After 9:45 AM - Approval Required',
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
                      'Punch-in available until 9:45 AM (${LatePunchApprovalService.getTimeUntilCutoff()})',
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
                            letterSpacing: 1,
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
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Early Punch-Out Approval Widget or Punch-Out Button
          if (isBeforeEarlyPunchOutCutoff && currentAttendance != null)
            EarlyPunchOutApprovalWidget(
              attendanceId: currentAttendance!.id,
              onApprovalRequested: () {
                // Refresh status after approval request
                setState(() {});
              },
              onApprovalReceived: () {
                // Set flag that approval is received and allow punch out
                setState(() {
                  validEarlyPunchOutCode = 'validated';
                });
              },
            )
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
        if (isBeforeEarlyPunchOutCutoff) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Early punch-out requires approval (${EarlyPunchOutApprovalService.getTimeUntilEarlyPunchOutCutoff()})',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
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
                    'Normal punch-out available after 6:30 PM',
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
        ],
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
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePunchOut({String? earlyPunchOutCode}) async {
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
        earlyPunchOutCode: earlyPunchOutCode ?? validEarlyPunchOutCode,
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = false;
          punchInTime = null;
          validEarlyPunchOutCode = null; // Clear used code
        });
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Punch Out Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Photo *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (photo != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                photo!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    photo = null;
                                    photoBase64 = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final pickedPhoto = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 50,
                                maxWidth: 1024,
                                maxHeight: 1024,
                              );
                              if (pickedPhoto != null) {
                                final file = File(pickedPhoto.path);
                                final bytes = await file.readAsBytes();
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
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bike KM Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Bike KM Reading',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bikeKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter ending KM reading',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'km',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.access_time, 'Time', currentTime),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.timer,
                        'Work Duration',
                        _getCurrentDurationText(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (photo == null) {
                  CustomToast.showError(context, 'Please take a photo');
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Punch Out'),
            ),
          ],
        ),
      ),
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
