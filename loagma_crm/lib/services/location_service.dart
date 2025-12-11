import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Request all necessary location permissions like WhatsApp
  Future<bool> requestLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permissions: $e');
      return false;
    }
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
        distanceFilter: 3, // Update every 3 meters for better tracking
        timeLimit: Duration(seconds: 10), // Faster timeout for responsiveness
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

  /// Show location permission dialog like WhatsApp
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[600], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Location Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This app needs location access to:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    Icons.punch_clock,
                    'Track attendance location',
                  ),
                  _buildPermissionItem(Icons.map, 'Show your position on maps'),
                  _buildPermissionItem(
                    Icons.directions,
                    'Calculate travel distance',
                  ),
                  _buildPermissionItem(Icons.security, 'Verify work location'),
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
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Location data is only used for attendance tracking and is not shared with third parties.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Allow Location'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Widget _buildPermissionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
  }
}
