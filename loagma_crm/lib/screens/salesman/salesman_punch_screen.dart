import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../models/attendance_model.dart';
import 'salesman_attendance_history_screen.dart';

class SalesmanPunchScreen extends StatefulWidget {
  const SalesmanPunchScreen({super.key});

  @override
  State<SalesmanPunchScreen> createState() => _SalesmanPunchScreenState();
}

class _SalesmanPunchScreenState extends State<SalesmanPunchScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  // Punch status
  bool isPunchedIn = false;
  DateTime? punchInTime;
  DateTime? punchOutTime;
  Position? punchInLocation;
  Position? punchOutLocation;

  // Punch In data
  File? punchInPhoto;
  String? punchInPhotoBase64;
  String? bikeKilometers;

  // Current attendance record
  AttendanceModel? currentAttendance;
  bool isLoadingAttendance = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Current time
  String currentTime = '';
  String currentDate = '';
  Timer? _timer;

  // Location
  Position? _currentPosition;
  bool isLoadingLocation = false;
  String locationStatus = 'Getting location...';

  // Work duration
  Duration workDuration = Duration.zero;

  // Travel distance
  double totalDistanceKm = 0.0;

  // Google Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _startTimer();
    _initializeLocationService();
    _loadTodayPunchData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Stop location tracking when leaving the screen
    LocationService.instance.stopLocationTracking();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      if (isPunchedIn && punchInTime != null) {
        setState(() {
          final now = DateTime.now();
          final newDuration = now.difference(punchInTime!);

          // Only update if duration is positive and different
          if (!newDuration.isNegative && newDuration != workDuration) {
            workDuration = newDuration;
          }
        });
      }
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    });
  }

  Future<void> _initializeLocationService() async {
    setState(() {
      isLoadingLocation = true;
      locationStatus = 'Requesting location permissions...';
    });

    try {
      // Show WhatsApp-like permission dialog
      final shouldRequestPermission =
          await LocationService.showLocationPermissionDialog(context);

      if (!shouldRequestPermission) {
        setState(() {
          locationStatus = 'Location permission required for attendance';
          isLoadingLocation = false;
        });
        return;
      }

      // Start location tracking
      final locationService = LocationService.instance;
      final success = await locationService.startLocationTracking();

      if (success) {
        // Listen to location updates
        locationService.locationStream.listen((Position position) {
          setState(() {
            _currentPosition = position;
            locationStatus = 'Location tracking active';
            isLoadingLocation = false;
            _markers = _buildMapMarkers();
          });

          // Update map camera to follow current location
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          }
        });

        // Get initial position
        final initialPosition = await locationService.getCurrentLocation();
        if (initialPosition != null) {
          setState(() {
            _currentPosition = initialPosition;
            locationStatus = 'Location tracking active';
            isLoadingLocation = false;
          });
        }
      } else {
        setState(() {
          locationStatus = 'Failed to start location tracking';
          isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        locationStatus = 'Error: $e';
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
      locationStatus = 'Getting location...';
    });

    try {
      final locationService = LocationService.instance;
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          locationStatus = 'Location acquired';
          isLoadingLocation = false;
        });
      } else {
        setState(() {
          locationStatus = 'Failed to get location';
          isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        locationStatus = 'Error: $e';
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadTodayPunchData() async {
    setState(() => isLoadingAttendance = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) {
        _showError('Employee ID not found. Please login again.');
        return;
      }

      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (attendance != null) {
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = attendance.isPunchedIn;
          punchInTime = attendance.punchInTime;

          // Calculate work duration with proper handling and timezone consideration
          if (attendance.isPunchedIn) {
            // For active attendance, calculate current duration
            final now = DateTime.now();
            final duration = now.difference(attendance.punchInTime);

            // Ensure duration is not negative (handle clock sync issues)
            workDuration = duration.isNegative ? Duration.zero : duration;
          } else if (attendance.isPunchedOut &&
              attendance.punchOutTime != null) {
            // For completed attendance, use the actual work duration
            final duration = attendance.punchOutTime!.difference(
              attendance.punchInTime,
            );

            // Ensure duration is not negative
            workDuration = duration.isNegative ? Duration.zero : duration;
          } else {
            workDuration = Duration.zero;
          }

          // Create punch in location
          punchInLocation = Position(
            latitude: attendance.punchInLatitude,
            longitude: attendance.punchInLongitude,
            timestamp: attendance.punchInTime,
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );

          // Handle punch out data if available
          if (attendance.isPunchedOut) {
            punchOutTime = attendance.punchOutTime;
            if (attendance.punchOutLatitude != null &&
                attendance.punchOutLongitude != null) {
              punchOutLocation = Position(
                latitude: attendance.punchOutLatitude!,
                longitude: attendance.punchOutLongitude!,
                timestamp: attendance.punchOutTime ?? DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            }
            totalDistanceKm = attendance.totalDistanceKm ?? 0.0;
          } else {
            // Reset punch out data for active sessions
            punchOutTime = null;
            punchOutLocation = null;
            totalDistanceKm = 0.0;
          }

          // Update map markers
          _markers = _buildMapMarkers();
        });

        // Show session info if active
        if (attendance.isPunchedIn) {
          final sessionDuration = workDuration.inMinutes;
          if (sessionDuration > 0) {
            print('Active session loaded: ${sessionDuration} minutes worked');
          }
        }
      } else {
        // No attendance found, reset state
        setState(() {
          currentAttendance = null;
          isPunchedIn = false;
          punchInTime = null;
          punchOutTime = null;
          punchInLocation = null;
          punchOutLocation = null;
          workDuration = Duration.zero;
          totalDistanceKm = 0.0;
          _markers = _buildMapMarkers();
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
      _showError('Failed to load attendance data. Please refresh.');
    } finally {
      setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _handlePunchIn() async {
    HapticFeedback.mediumImpact();

    if (_currentPosition == null) {
      _showError('Please wait for location to be acquired');
      HapticFeedback.heavyImpact();
      return;
    }

    // Show multi-step punch in dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PunchInDialog(
        currentTime: currentTime,
        currentPosition: _currentPosition!,
        imagePicker: _imagePicker,
      ),
    );

    if (result != null && result['confirmed'] == true) {
      HapticFeedback.heavyImpact();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Send to backend
      final employeeId = UserService.currentUserId;
      final employeeName = UserService.name;

      if (employeeId == null || employeeName == null) {
        Navigator.pop(context); // Close loading
        _showError('Employee information not found');
        return;
      }

      final response = await AttendanceService.punchIn(
        employeeId: employeeId,
        employeeName: employeeName,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: result['photoBase64'],
        bikeKmStart: result['bikeKm'],
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;

        setState(() {
          currentAttendance = attendance;
          isPunchedIn = true;
          punchInTime = DateTime.now();
          punchInLocation = _currentPosition;
          punchInPhoto = result['photo'];
          punchInPhotoBase64 = result['photoBase64'];
          bikeKilometers = result['bikeKm'];
          workDuration = Duration.zero;
          _markers = _buildMapMarkers();
        });

        _showSuccess('✓ Punched in successfully! Have a great day!');
      } else {
        _showError(response['message'] ?? 'Failed to punch in');
      }
    }
  }

  Future<void> _handlePunchOut() async {
    HapticFeedback.mediumImpact();

    if (_currentPosition == null) {
      _showError('Please wait for location to be acquired');
      HapticFeedback.heavyImpact();
      return;
    }

    // Calculate distance for preview
    double previewDistance = 0.0;
    if (punchInLocation != null && _currentPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        punchInLocation!.latitude,
        punchInLocation!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      previewDistance = distanceInMeters / 1000;
    }

    // Show punch out data collection dialog
    final punchOutData = await _showPunchOutDialog(previewDistance);

    if (punchOutData != null) {
      HapticFeedback.heavyImpact();

      if (currentAttendance == null) {
        _showError('No active attendance record found');
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Send to backend
      final response = await AttendanceService.punchOut(
        attendanceId: currentAttendance!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: punchOutData['photoBase64'],
        bikeKmEnd: punchOutData['kmReading'],
      );

      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        final attendance = response['data'] as AttendanceModel?;

        // Calculate final distance
        if (punchInLocation != null && _currentPosition != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            punchInLocation!.latitude,
            punchInLocation!.longitude,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          totalDistanceKm = distanceInMeters / 1000;
        }

        setState(() {
          currentAttendance = attendance;
          isPunchedIn = false;
          punchOutTime = DateTime.now();
          punchOutLocation = _currentPosition;
          _markers = _buildMapMarkers();
        });

        _showSuccess(
          '✓ Punched out successfully! Total distance: ${totalDistanceKm.toStringAsFixed(2)} km',
        );
      } else {
        _showError(response['message'] ?? 'Failed to punch out');
      }
    }
  }

  Future<Map<String, dynamic>?> _showPunchOutDialog(
    double previewDistance,
  ) async {
    File? punchOutPhoto;
    String? punchOutPhotoBase64;
    final kmController = TextEditingController();

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
              const Expanded(child: Text('Punch Out Details')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide the following details:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (punchOutPhoto != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                punchOutPhoto!,
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
                                    punchOutPhoto = null;
                                    punchOutPhotoBase64 = null;
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
                              final photo = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 50, // Reduced quality
                                maxWidth: 1024, // Limit dimensions
                                maxHeight: 1024,
                                preferredCameraDevice: CameraDevice.rear,
                              );
                              if (photo != null) {
                                final file = File(photo.path);

                                // Check file size
                                final fileSize = await file.length();
                                if (fileSize > 5 * 1024 * 1024) {
                                  // 5MB limit
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Photo is too large. Please try again.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final bytes = await file.readAsBytes();

                                // Additional size check
                                if (bytes.length > 5 * 1024 * 1024) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Photo processing failed. Image too large.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                setState(() {
                                  punchOutPhoto = file;
                                  punchOutPhotoBase64 = base64Encode(bytes);
                                });
                                HapticFeedback.mediumImpact();
                              }
                            } catch (e) {
                              print('Error capturing photo: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error capturing photo: ${e.toString().contains('memory') ? 'Image too large' : 'Camera error'}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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

                // KM Reading Section
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
                            'KM Reading *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: kmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter odometer reading',
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

                // Summary Section
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
                        Icons.timer,
                        'Duration',
                        _formatDuration(workDuration),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.directions_car,
                        'Travel',
                        '${previewDistance.toStringAsFixed(2)} km',
                      ),
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
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Validate
                if (punchOutPhoto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please take a photo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (kmController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter KM reading'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                HapticFeedback.mediumImpact();
                Navigator.pop(context, {
                  'photo': punchOutPhoto,
                  'photoBase64': punchOutPhotoBase64,
                  'kmReading': kmController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _getCurrentDurationText() {
    if (isPunchedIn && punchInTime != null) {
      // Currently working - calculate live duration
      final currentDuration = DateTime.now().difference(punchInTime!);
      return _formatDuration(currentDuration);
    } else if (punchInTime != null && punchOutTime != null) {
      // Already punched out - show total worked duration
      final totalDuration = punchOutTime!.difference(punchInTime!);
      return _formatDuration(totalDuration);
    } else if (currentAttendance?.totalWorkHours != null) {
      // Use backend calculated hours if available
      final hours = currentAttendance!.totalWorkHours!;
      final duration = Duration(milliseconds: (hours * 3600 * 1000).round());
      return _formatDuration(duration);
    } else {
      return '--:--:--';
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Attendance History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesmanAttendanceHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getCurrentLocation();
          await _loadTodayPunchData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Current Time Card
              _buildCurrentTimeCard(),

              // Status Card
              _buildStatusCard(),

              // Punch Button
              _buildPunchButton(),

              // Today's Summary
              _buildTodaySummary(),

              // Location Info
              _buildLocationInfo(),
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
                  _formatDuration(workDuration),
                  Icons.timer,
                  primaryColor,
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPunchButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            InkWell(
              onTap: isPunchedIn ? _handlePunchOut : _handlePunchIn,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPunchedIn
                        ? [Colors.red, Colors.red[700]!]
                        : [Colors.green, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPunchedIn ? Colors.red : Colors.green)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPunchedIn ? Icons.logout : Icons.login,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            isPunchedIn
                ? 'Tap to end your work day'
                : 'Tap to start your work day',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            Icons.login,
            'Punch In Time',
            punchInTime != null
                ? DateFormat('hh:mm a').format(punchInTime!)
                : '--:--',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.logout,
            'Punch Out Time',
            punchOutTime != null
                ? DateFormat('hh:mm a').format(punchOutTime!)
                : '--:--',
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.timer,
            'Total Duration',
            _getCurrentDurationText(),
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
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

  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.map, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Live Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentPosition != null ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Refresh location',
                ),
              ],
            ),
          ),

          // Map Section
          if (_currentPosition != null)
            Container(
              height: 200,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),
              ),
            )
          else
            Container(
              height: 200,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Location not available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locationStatus,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Location Details
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordinates',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Accuracy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _currentPosition!.accuracy < 10
                                ? Colors.green
                                : _currentPosition!.accuracy < 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMapMarkers() {
    Set<Marker> markers = {};

    if (_currentPosition != null) {
      // Current location marker
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet:
                'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Punch in location marker
    if (punchInLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('punch_in_location'),
          position: LatLng(
            punchInLocation!.latitude,
            punchInLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Punch In Location',
            snippet: punchInTime != null
                ? DateFormat('hh:mm a').format(punchInTime!)
                : 'Punch In',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Punch out location marker
    if (punchOutLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('punch_out_location'),
          position: LatLng(
            punchOutLocation!.latitude,
            punchOutLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Punch Out Location',
            snippet: punchOutTime != null
                ? DateFormat('hh:mm a').format(punchOutTime!)
                : 'Punch Out',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }
}

// Punch In Dialog Widget
class _PunchInDialog extends StatefulWidget {
  final String currentTime;
  final Position currentPosition;
  final ImagePicker imagePicker;

  const _PunchInDialog({
    required this.currentTime,
    required this.currentPosition,
    required this.imagePicker,
  });

  @override
  State<_PunchInDialog> createState() => _PunchInDialogState();
}

class _PunchInDialogState extends State<_PunchInDialog> {
  int _currentStep = 0;
  File? _capturedPhoto;
  String? _photoBase64;
  final TextEditingController _bikeKmController = TextEditingController();

  static const Color primaryColor = Color(0xFFD7BE69);

  @override
  void dispose() {
    _bikeKmController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await widget.imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Reduced quality to prevent crashes
        maxWidth: 1024, // Limit image dimensions
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        final File imageFile = File(photo.path);

        // Check file size before processing
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          // 5MB limit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Photo is too large. Please try again with a smaller image.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final bytes = await imageFile.readAsBytes();

        // Additional check on byte array size
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo processing failed. Image too large.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final base64Image = base64Encode(bytes);

        setState(() {
          _capturedPhoto = imageFile;
          _photoBase64 = base64Image;
        });

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error capturing photo: ${e.toString().contains('memory') ? 'Image too large' : 'Camera error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentStep == 1 && _bikeKmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bike kilometers'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      HapticFeedback.lightImpact();
    }
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, {
      'confirmed': true,
      'photo': _capturedPhoto,
      'photoBase64': _photoBase64,
      'bikeKm': _bikeKmController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.login, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Punch In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Step ${_currentStep + 1}/3',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _currentStep == 2 ? _confirm : _nextStep,
                      icon: Icon(
                        _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                      ),
                      label: Text(_currentStep == 2 ? 'Punch In' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStep == 2
                            ? Colors.green
                            : primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildBikeKmStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        const Icon(Icons.camera_alt, size: 64, color: primaryColor),
        const SizedBox(height: 16),
        const Text(
          'Capture Your Photo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a selfie to mark your attendance',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_capturedPhoto != null)
          Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 3),
                  image: DecorationImage(
                    image: FileImage(_capturedPhoto!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Photo captured!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Photo'),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: const Text('Open Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildBikeKmStep() {
    return Column(
      children: [
        const Icon(Icons.two_wheeler, size: 64, color: primaryColor),
        const SizedBox(height: 16),
        const Text(
          'Enter Bike Kilometers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Record your bike odometer reading',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _bikeKmController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Bike Kilometers',
            hintText: 'Enter current KM reading',
            prefixIcon: const Icon(Icons.speed, color: primaryColor),
            suffixText: 'KM',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
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
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enter the exact reading from your bike\'s odometer',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Confirm Punch In',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your details before punching in',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildConfirmRow(Icons.access_time, 'Time', widget.currentTime),
              const Divider(height: 24),
              _buildConfirmRow(
                Icons.location_on,
                'Location',
                '${widget.currentPosition.latitude.toStringAsFixed(4)}, ${widget.currentPosition.longitude.toStringAsFixed(4)}',
              ),
              const Divider(height: 24),
              _buildConfirmRow(
                Icons.two_wheeler,
                'Bike KM',
                '${_bikeKmController.text} KM',
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.camera_alt, size: 20, color: primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Photo:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_capturedPhoto != null)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 2),
                        image: DecorationImage(
                          image: FileImage(_capturedPhoto!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
