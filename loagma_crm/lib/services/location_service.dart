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

  /// Request all necessary location permissions like WhatsApp
  Future<bool> requestLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Request user to enable location services
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Open app settings for user to manually enable
        await Geolocator.openAppSettings();
        return false;
      }

      // Request background location permission for continuous tracking
      if (permission == LocationPermission.whileInUse) {
        // Try to get always permission for background tracking
        final backgroundPermission = await Permission.locationAlways.request();
        if (backgroundPermission.isDenied) {
          // Still allow with whileInUse permission
          print('Background location not granted, using foreground only');
        }
      }

      return true;
    } catch (e) {
      print('Error requesting location permissions: $e');
      return false;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking() async {
    if (_isTracking) {
      return true;
    }

    try {
      // Request permissions first
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        return false;
      }

      // Configure location settings for high accuracy and continuous tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters for better tracking
        timeLimit: Duration(seconds: 15), // Faster timeout for responsiveness
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
            },
          );

      // Get initial position
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        if (_currentPosition != null) {
          _locationController.add(_currentPosition!);
        }
      } catch (e) {
        print('Error getting initial position: $e');
      }

      _isTracking = true;
      print('✅ Location tracking started');
      return true;
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    print('🛑 Location tracking stopped');
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        return null;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _currentPosition = position;
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
