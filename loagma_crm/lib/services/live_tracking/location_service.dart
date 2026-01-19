import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Service class for handling GPS location tracking and permissions
/// Provides comprehensive location services with background tracking capability
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  // Privacy and tracking settings
  bool _backgroundTrackingEnabled = false;
  bool _highAccuracyMode = true;
  int _distanceFilter = 10; // meters
  Duration _timeInterval = const Duration(seconds: 30);

  // Tracking state
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();
  final StreamController<LocationServiceStatus> _statusController =
      StreamController<LocationServiceStatus>.broadcast();

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      developer.log(
        'Error checking location service status: $e',
        name: 'LocationService',
      );
      return false;
    }
  }

  /// Request location permissions from the user with detailed handling
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult(
          permission: permission,
          serviceEnabled: false,
          message:
              'Location services are disabled. Please enable them in device settings.',
        );
      }

      return LocationPermissionResult(
        permission: permission,
        serviceEnabled: true,
        message: _getPermissionMessage(permission),
      );
    } catch (e) {
      developer.log(
        'Error requesting location permission: $e',
        name: 'LocationService',
      );
      return LocationPermissionResult(
        permission: LocationPermission.denied,
        serviceEnabled: false,
        message: 'Failed to request location permission: $e',
      );
    }
  }

  /// Get current location with enhanced error handling and settings
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      final permissionResult = await requestLocationPermission();

      if (permissionResult.permission == LocationPermission.denied ||
          permissionResult.permission == LocationPermission.deniedForever) {
        developer.log(
          'Location permission denied: ${permissionResult.message}',
          name: 'LocationService',
        );
        return null;
      }

      if (!permissionResult.serviceEnabled) {
        developer.log('Location service not enabled', name: 'LocationService');
        return null;
      }

      final locationSettings = LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      developer.log(
        'Current location obtained: ${position.latitude}, ${position.longitude}',
        name: 'LocationService',
      );
      return position;
    } catch (e) {
      developer.log(
        'Error getting current location: $e',
        name: 'LocationService',
      );
      return null;
    }
  }

  /// Start continuous location tracking with configurable settings
  Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 30),
  }) async {
    try {
      // Check permissions first
      final permissionResult = await requestLocationPermission();
      if (permissionResult.permission == LocationPermission.denied ||
          permissionResult.permission == LocationPermission.deniedForever) {
        _statusController.add(LocationServiceStatus.permissionDenied);
        return false;
      }

      if (!permissionResult.serviceEnabled) {
        _statusController.add(LocationServiceStatus.serviceDisabled);
        return false;
      }

      // Stop existing tracking if any
      await stopLocationTracking();

      // Update settings
      _highAccuracyMode = accuracy == LocationAccuracy.high;
      _distanceFilter = distanceFilter;
      _timeInterval = timeInterval;

      // Configure location settings
      final LocationSettings locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      // Start position stream
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              developer.log(
                'Location update: ${position.latitude}, ${position.longitude}',
                name: 'LocationService',
              );
              _locationController.add(position);
            },
            onError: (error) {
              developer.log(
                'Location tracking error: $error',
                name: 'LocationService',
              );
              _statusController.add(LocationServiceStatus.error);
            },
          );

      _statusController.add(LocationServiceStatus.tracking);
      developer.log(
        'Location tracking started successfully',
        name: 'LocationService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error starting location tracking: $e',
        name: 'LocationService',
      );
      _statusController.add(LocationServiceStatus.error);
      return false;
    }
  }

  /// Stop continuous location tracking
  Future<void> stopLocationTracking() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _statusController.add(LocationServiceStatus.stopped);
      developer.log('Location tracking stopped', name: 'LocationService');
    } catch (e) {
      developer.log(
        'Error stopping location tracking: $e',
        name: 'LocationService',
      );
    }
  }

  /// Request background location permission with detailed handling
  Future<BackgroundLocationResult> requestBackgroundLocationPermission() async {
    try {
      // First ensure we have basic location permission
      final basicPermission = await requestLocationPermission();
      if (basicPermission.permission == LocationPermission.denied ||
          basicPermission.permission == LocationPermission.deniedForever) {
        return BackgroundLocationResult(
          granted: false,
          message:
              'Basic location permission required first: ${basicPermission.message}',
        );
      }

      // Check current background permission status
      final currentStatus = await Permission.locationAlways.status;
      if (currentStatus == PermissionStatus.granted) {
        _backgroundTrackingEnabled = true;
        return BackgroundLocationResult(
          granted: true,
          message: 'Background location permission already granted',
        );
      }

      // Request background permission
      final status = await Permission.locationAlways.request();
      _backgroundTrackingEnabled = status == PermissionStatus.granted;

      return BackgroundLocationResult(
        granted: _backgroundTrackingEnabled,
        message: _getBackgroundPermissionMessage(status),
      );
    } catch (e) {
      developer.log(
        'Error requesting background location permission: $e',
        name: 'LocationService',
      );
      return BackgroundLocationResult(
        granted: false,
        message: 'Failed to request background location permission: $e',
      );
    }
  }

  /// Enable background location tracking
  Future<bool> enableBackgroundTracking() async {
    final result = await requestBackgroundLocationPermission();
    if (result.granted) {
      _backgroundTrackingEnabled = true;
      developer.log('Background tracking enabled', name: 'LocationService');
      return true;
    } else {
      developer.log(
        'Background tracking could not be enabled: ${result.message}',
        name: 'LocationService',
      );
      return false;
    }
  }

  /// Disable background location tracking
  void disableBackgroundTracking() {
    _backgroundTrackingEnabled = false;
    developer.log('Background tracking disabled', name: 'LocationService');
  }

  /// Get location stream for continuous updates
  Stream<Position> get locationStream => _locationController.stream;

  /// Get service status stream
  Stream<LocationServiceStatus> get statusStream => _statusController.stream;

  /// Check if currently tracking
  bool get isTracking => _positionSubscription != null;

  /// Check if background tracking is enabled
  bool get isBackgroundTrackingEnabled => _backgroundTrackingEnabled;

  /// Get current tracking settings
  LocationTrackingSettings get currentSettings => LocationTrackingSettings(
    highAccuracyMode: _highAccuracyMode,
    distanceFilter: _distanceFilter,
    timeInterval: _timeInterval,
    backgroundTrackingEnabled: _backgroundTrackingEnabled,
  );

  /// Update privacy settings
  void updatePrivacySettings({
    bool? highAccuracyMode,
    int? distanceFilter,
    Duration? timeInterval,
  }) {
    if (highAccuracyMode != null) _highAccuracyMode = highAccuracyMode;
    if (distanceFilter != null) _distanceFilter = distanceFilter;
    if (timeInterval != null) _timeInterval = timeInterval;

    developer.log('Privacy settings updated', name: 'LocationService');
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      developer.log(
        'Error opening location settings: $e',
        name: 'LocationService',
      );
      return false;
    }
  }

  /// Open app-specific location settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      developer.log('Error opening app settings: $e', name: 'LocationService');
      return false;
    }
  }

  /// Get distance between two positions
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Get bearing between two positions
  double getBearingBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Helper method to get permission message
  String _getPermissionMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied. Please grant permission to use location services.';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied. Please enable it in app settings.';
      case LocationPermission.whileInUse:
        return 'Location permission granted for foreground use only.';
      case LocationPermission.always:
        return 'Location permission granted for background use.';
      default:
        return 'Location permission status unknown.';
    }
  }

  /// Helper method to get background permission message
  String _getBackgroundPermissionMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Background location permission granted successfully.';
      case PermissionStatus.denied:
        return 'Background location permission denied. Some features may not work properly.';
      case PermissionStatus.permanentlyDenied:
        return 'Background location permission permanently denied. Please enable it in app settings.';
      case PermissionStatus.restricted:
        return 'Background location permission restricted by device policy.';
      default:
        return 'Background location permission status unknown.';
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    _locationController.close();
    _statusController.close();
  }
}

/// Result class for location permission requests
class LocationPermissionResult {
  final LocationPermission permission;
  final bool serviceEnabled;
  final String message;

  LocationPermissionResult({
    required this.permission,
    required this.serviceEnabled,
    required this.message,
  });

  bool get isGranted =>
      (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) &&
      serviceEnabled;
}

/// Result class for background location permission requests
class BackgroundLocationResult {
  final bool granted;
  final String message;

  BackgroundLocationResult({required this.granted, required this.message});
}

/// Location tracking settings
class LocationTrackingSettings {
  final bool highAccuracyMode;
  final int distanceFilter;
  final Duration timeInterval;
  final bool backgroundTrackingEnabled;

  LocationTrackingSettings({
    required this.highAccuracyMode,
    required this.distanceFilter,
    required this.timeInterval,
    required this.backgroundTrackingEnabled,
  });
}

/// Location service status enum
enum LocationServiceStatus {
  stopped,
  tracking,
  permissionDenied,
  serviceDisabled,
  error,
}
