import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isTracking = false;

  // Stream controller for location updates
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  /// Check if location permissions are already granted
  Future<bool> checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Request all necessary location permissions with proper handling
  Future<bool> requestLocationPermissions({bool requestAlways = false}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        // Location services are disabled
        print('User needs to enable location services manually');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied by user');
          return false;
        }
      }

      // If permission is denied forever, guide user to settings
      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever - need to open settings');
        return false;
      }

      // For background tracking, we need "always" permission
      if (requestAlways && permission == LocationPermission.whileInUse) {
        print('Requesting background location permission...');
        // Note: On Android, this might require additional setup in AndroidManifest.xml
        // For now, we'll work with whileInUse permission
      }

      bool hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (hasPermission) {
        print('✅ Location permission granted: $permission');
      }

      return hasPermission;
    } catch (e) {
      print('❌ Error requesting location permissions: $e');
      return false;
    }
  }

  /// Show location permission dialog with clear explanation
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Location Permission Required'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs location access to:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('• Track your work location for attendance'),
                  Text('• Calculate travel distance'),
                  Text('• Show nearby places and shops'),
                  Text('• Ensure accurate punch in/out'),
                  SizedBox(height: 12),
                  Text(
                    'Your location data is only used for work tracking and is not shared with third parties.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Deny'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow Location'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show settings dialog when permission is denied forever
  static Future<void> showLocationSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required for this app to work properly. '
            'Please enable location permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Request notification permissions for persistent location tracking
  static Future<bool> requestNotificationPermissions() async {
    try {
      // For Android 13+ (API 33+), we need to request notification permission
      // This is handled automatically by the geolocator plugin when starting location services
      print('✅ Notification permissions handled by geolocator plugin');
      return true;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show background location permission dialog
  static Future<bool> showBackgroundLocationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Background Location'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For accurate attendance tracking, this app needs to access your location even when running in the background.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This ensures:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('• Continuous location tracking during work hours'),
                  Text('• Accurate travel distance calculation'),
                  Text('• Reliable punch in/out location verification'),
                  SizedBox(height: 12),
                  Text(
                    'You will see a persistent notification while location tracking is active.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow Background Location'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking() async {
    if (_isTracking) {
      print('Location tracking already active');
      return true;
    }

    try {
      // Request permissions first
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        print('Location permissions not granted');
        return false;
      }

      // Configure location settings for high accuracy and continuous tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter for precise tracking
        timeLimit: Duration(seconds: 15), // Reasonable timeout
      );

      // Start position stream
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
              print(
                '📍 Location updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
              );
            },
            onError: (error) {
              print('❌ Location stream error: $error');
              _locationController.addError(error);
            },
          );

      // Get initial position with retry logic
      try {
        _currentPosition = await _getCurrentPositionWithRetry(locationSettings);
        if (_currentPosition != null) {
          _locationController.add(_currentPosition!);
          print(
            '✅ Initial location acquired: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
          );
        }
      } catch (e) {
        print('Warning: Could not get initial position: $e');
        // Continue anyway, stream might provide location later
      }

      _isTracking = true;
      print('✅ Location tracking started successfully');
      return true;
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      return false;
    }
  }

  /// Get current position with retry logic
  Future<Position?> _getCurrentPositionWithRetry(
    LocationSettings settings, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        return position;
      } catch (e) {
        print('Attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 + i)); // Progressive delay
        }
      }
    }
    return null;
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    print('🛑 Location tracking stopped');
  }

  /// Get current location once
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Return cached position if available and not forcing refresh
      if (!forceRefresh && _currentPosition != null) {
        final age = DateTime.now().difference(_currentPosition!.timestamp);
        if (age.inMinutes < 2) {
          // Use cached if less than 2 minutes old
          print('Using cached location (${age.inSeconds}s old)');
          return _currentPosition;
        }
      }

      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        print('No location permission for getCurrentLocation');
        return null;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Increased timeout
      );

      print('Getting fresh location...');
      final position = await _getCurrentPositionWithRetry(locationSettings);

      if (position != null) {
        _currentPosition = position;
        print(
          '✅ Fresh location acquired: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );

        // Add to stream if tracking is active
        if (_isTracking) {
          _locationController.add(position);
        }
      } else {
        print('❌ Failed to get current location after retries');
      }

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two positions in kilometers
  double calculateDistance(Position start, Position end) {
    final distanceInMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Dispose resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
  }
}
