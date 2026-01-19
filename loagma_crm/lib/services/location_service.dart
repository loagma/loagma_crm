import 'dart:async';
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> f4afc93f9441ec54221a2ce0ab45a5b4a3028517
import 'package:geolocator/geolocator.dart';

/// Location service for continuous GPS tracking
/// Supports background location updates with foreground service notification
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

  /// Check if location permissions are granted
  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permissions with background support
  Future<bool> requestLocationPermissions({bool requestAlways = false}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return false;
        }
      }

      // Handle permanently denied
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return false;
      }

      // For background tracking, request "always" permission
      if (requestAlways && permission == LocationPermission.whileInUse) {
        debugPrint(
          'Background location: whileInUse granted, "always" recommended',
        );
        // Note: On Android 10+, user must manually grant "always" in settings
        // The app will still work with whileInUse + foreground service
      }

      bool hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (hasPermission) {
        debugPrint('✅ Location permission granted: $permission');
      }

      return hasPermission;
    } catch (e) {
      debugPrint('❌ Error requesting location permissions: $e');
      return false;
    }
  }

  /// Show location permission dialog
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
                  Text('Location Permission'),
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
                  Text('• Track your work location'),
                  Text('• Calculate travel distance'),
                  Text('• Show nearby places'),
                  Text('• Verify punch in/out location'),
                  SizedBox(height: 12),
                  Text(
                    'Your location is only used for work tracking.',
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
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show settings dialog when permission denied forever
  static Future<void> showLocationSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required. Please enable it in settings.',
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

  /// Show background location dialog
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
                    'For accurate tracking, this app needs background location access.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This ensures:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('• Continuous tracking during work'),
                  Text('• Accurate distance calculation'),
                  Text('• Reliable location verification'),
                  SizedBox(height: 12),
                  Text(
                    'A notification will show while tracking is active.',
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
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Start continuous location tracking with foreground service
  Future<bool> startLocationTracking() async {
    if (_isTracking) {
      debugPrint('Location tracking already active');
      return true;
    }

    try {
      final hasPermission = await requestLocationPermissions(
        requestAlways: true,
      );
      if (!hasPermission) {
        debugPrint('Location permissions not granted');
        return false;
      }

      // Configure for high accuracy continuous tracking
      // Uses foreground service on Android for background support
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter
        timeLimit: Duration(seconds: 30),
      );

      // Start position stream
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
              debugPrint(
                '📍 GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy.toStringAsFixed(0)}m)',
              );
            },
            onError: (error) {
              debugPrint('❌ Location stream error: $error');
              _locationController.addError(error);
            },
          );

      // Get initial position
      try {
        _currentPosition = await _getCurrentPositionWithRetry(locationSettings);
        if (_currentPosition != null) {
          _locationController.add(_currentPosition!);
          debugPrint(
            '✅ Initial location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
          );
        }
      } catch (e) {
        debugPrint('Warning: Could not get initial position: $e');
      }

      _isTracking = true;
      debugPrint('✅ Location tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
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
        debugPrint('Attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 + i));
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
    debugPrint('🛑 Location tracking stopped');
  }

  /// Get current location once
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Use cached if recent and not forcing refresh
      if (!forceRefresh && _currentPosition != null) {
        final age = DateTime.now().difference(_currentPosition!.timestamp);
        if (age.inMinutes < 2) {
          debugPrint('Using cached location (${age.inSeconds}s old)');
          return _currentPosition;
        }
      }

      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) return null;

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );

      debugPrint('Getting fresh location...');
      final position = await _getCurrentPositionWithRetry(locationSettings);

      if (position != null) {
        _currentPosition = position;
        debugPrint(
          '✅ Fresh location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );

        if (_isTracking) {
          _locationController.add(position);
        }
      }

      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
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
    return distanceInMeters / 1000;
  }

  /// Dispose resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
  }
}
