import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/live_tracking/location_models.dart';
import '../../config/mapbox_config.dart';

/// Service class for handling Mapbox map integration
/// Provides comprehensive map functionality including markers, clustering, and interactions
class MapboxService {
  static MapboxService? _instance;
  static MapboxService get instance => _instance ??= MapboxService._();
  MapboxService._();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;

  // Marker tracking
  final Map<String, PointAnnotation> _markers = {};
  final Map<String, LiveLocation> _liveLocations = {};

  // Map state
  bool _isInitialized = false;
  String _currentMapStyle = MapboxConfig.defaultMapStyle;

  /// Check if Mapbox is properly configured
  bool get isConfigured => MapboxConfig.isConfigured();

  /// Check if map is initialized
  bool get isInitialized => _isInitialized;

  /// Get current map style
  String get currentMapStyle => _currentMapStyle;

  /// Initialize Mapbox map with comprehensive setup
  Future<void> initializeMap(MapboxMap mapboxMap) async {
    try {
      if (!isConfigured) {
        throw MapboxException('Mapbox access token not configured');
      }

      _mapboxMap = mapboxMap;

      // Initialize annotation managers
      await _initializeAnnotationManagers();

      // Configure map settings
      await _configureMapSettings();

      _isInitialized = true;
    } catch (e) {
      throw MapboxException('Failed to initialize Mapbox map: ${e.toString()}');
    }
  }

  /// Initialize all annotation managers
  Future<void> _initializeAnnotationManagers() async {
    if (_mapboxMap == null) return;

    try {
      _pointAnnotationManager = await _mapboxMap!.annotations
          .createPointAnnotationManager();

      _polylineAnnotationManager = await _mapboxMap!.annotations
          .createPolylineAnnotationManager();

      _circleAnnotationManager = await _mapboxMap!.annotations
          .createCircleAnnotationManager();
    } catch (e) {
      throw MapboxException(
        'Failed to initialize annotation managers: ${e.toString()}',
      );
    }
  }

  /// Configure map settings and interactions
  Future<void> _configureMapSettings() async {
    if (_mapboxMap == null) return;

    try {
      // Configure gestures
      await _mapboxMap!.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: MapboxConfig.enableRotation,
          pitchEnabled: MapboxConfig.enableTilt,
          scrollEnabled: MapboxConfig.enablePan,
        ),
      );
    } catch (e) {
      // Configuration is not critical, so we don't throw
      debugPrint('Warning: Failed to configure map settings: $e');
    }
  }

  /// Change map style
  Future<void> changeMapStyle(String styleUri) async {
    if (_mapboxMap == null) {
      throw MapboxException('Map not initialized');
    }

    try {
      await _mapboxMap!.loadStyleURI(styleUri);
      _currentMapStyle = styleUri;

      // Reinitialize annotation managers after style change
      await _initializeAnnotationManagers();

      // Restore markers after style change
      await _restoreMarkersAfterStyleChange();
    } catch (e) {
      throw MapboxException('Failed to change map style: ${e.toString()}');
    }
  }

  /// Restore markers after style change
  Future<void> _restoreMarkersAfterStyleChange() async {
    try {
      final locations = Map<String, LiveLocation>.from(_liveLocations);
      _markers.clear();
      _liveLocations.clear();

      for (final entry in locations.entries) {
        await addLiveLocationMarker(entry.value);
      }
    } catch (e) {
      debugPrint('Warning: Failed to restore markers after style change: $e');
    }
  }

  /// Add a live location marker to the map
  Future<void> addLiveLocationMarker(LiveLocation location) async {
    if (_pointAnnotationManager == null) {
      throw MapboxException('Point annotation manager not initialized');
    }

    try {
      // Remove existing marker if any
      await removeMarker(location.userId);

      final point = Point(
        coordinates: Position(location.longitude, location.latitude),
      );

      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: point,
        iconImage: _getMarkerIcon(location),
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      );

      final annotation = await _pointAnnotationManager!.create(
        pointAnnotationOptions,
      );
      _markers[location.userId] = annotation;
      _liveLocations[location.userId] = location;
    } catch (e) {
      throw MapboxException(
        'Failed to add live location marker: ${e.toString()}',
      );
    }
  }

  /// Get appropriate marker icon based on location status
  String _getMarkerIcon(LiveLocation location) {
    if (location.isActive) {
      return 'active-salesman-marker';
    } else {
      return 'inactive-salesman-marker';
    }
  }

  /// Update live location marker
  Future<void> updateLiveLocationMarker(LiveLocation location) async {
    await addLiveLocationMarker(location); // This will replace existing marker
  }

  /// Add multiple live location markers
  Future<void> addMultipleLiveLocationMarkers(
    List<LiveLocation> locations,
  ) async {
    for (final location in locations) {
      await addLiveLocationMarker(location);
    }
  }

  /// Remove a specific marker
  Future<void> removeMarker(String userId) async {
    if (_pointAnnotationManager == null) return;

    try {
      final marker = _markers[userId];
      if (marker != null) {
        await _pointAnnotationManager!.delete(marker);
        _markers.remove(userId);
        _liveLocations.remove(userId);
      }
    } catch (e) {
      debugPrint('Warning: Failed to remove marker: $e');
    }
  }

  /// Remove all markers
  Future<void> clearAllMarkers() async {
    if (_pointAnnotationManager == null) return;

    try {
      await _pointAnnotationManager!.deleteAll();
      _markers.clear();
      _liveLocations.clear();
    } catch (e) {
      throw MapboxException('Failed to clear markers: ${e.toString()}');
    }
  }

  /// Add route polyline to the map
  Future<void> addRoute(
    List<LocationHistory> locations, {
    int lineColor = 0xFF007AFF,
    double lineWidth = 3.0,
  }) async {
    if (_polylineAnnotationManager == null) {
      throw MapboxException('Polyline annotation manager not initialized');
    }

    try {
      final coordinates = locations
          .map((location) => Position(location.longitude, location.latitude))
          .toList();

      final lineString = LineString(coordinates: coordinates);

      final polylineOptions = PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: lineColor,
        lineWidth: lineWidth,
        lineOpacity: 0.8,
      );

      await _polylineAnnotationManager!.create(polylineOptions);
    } catch (e) {
      throw MapboxException('Failed to add route: ${e.toString()}');
    }
  }

  /// Clear all routes
  Future<void> clearRoutes() async {
    if (_polylineAnnotationManager == null) return;

    try {
      await _polylineAnnotationManager!.deleteAll();
    } catch (e) {
      throw MapboxException('Failed to clear routes: ${e.toString()}');
    }
  }

  /// Add accuracy circle around a location
  Future<void> addAccuracyCircle(LiveLocation location) async {
    if (_circleAnnotationManager == null) {
      throw MapboxException('Circle annotation manager not initialized');
    }

    try {
      final point = Point(
        coordinates: Position(location.longitude, location.latitude),
      );

      final circleOptions = CircleAnnotationOptions(
        geometry: point,
        circleRadius: location.accuracy,
        circleColor: 0x4007AFF,
        circleStrokeColor: 0xFF007AFF,
        circleStrokeWidth: 1.0,
        circleOpacity: 0.3,
      );

      await _circleAnnotationManager!.create(circleOptions);
    } catch (e) {
      throw MapboxException('Failed to add accuracy circle: ${e.toString()}');
    }
  }

  /// Clear all accuracy circles
  Future<void> clearAccuracyCircles() async {
    if (_circleAnnotationManager == null) return;

    try {
      await _circleAnnotationManager!.deleteAll();
    } catch (e) {
      throw MapboxException(
        'Failed to clear accuracy circles: ${e.toString()}',
      );
    }
  }

  /// Move camera to specific location with animation
  Future<void> moveCameraToLocation({
    required double latitude,
    required double longitude,
    double zoom = 14.0,
    double bearing = 0.0,
    double pitch = 0.0,
    Duration animationDuration = const Duration(milliseconds: 1000),
  }) async {
    if (_mapboxMap == null) {
      throw MapboxException('Map not initialized');
    }

    try {
      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
        bearing: bearing,
        pitch: pitch,
      );

      final animationOptions = MapAnimationOptions(
        duration: animationDuration.inMilliseconds,
      );

      await _mapboxMap!.easeTo(cameraOptions, animationOptions);
    } catch (e) {
      throw MapboxException('Failed to move camera: ${e.toString()}');
    }
  }

  /// Fit camera to show all markers
  Future<void> fitCameraToMarkers({
    EdgeInsets padding = const EdgeInsets.all(50),
    Duration animationDuration = const Duration(milliseconds: 1000),
  }) async {
    if (_mapboxMap == null) {
      throw MapboxException('Map not initialized');
    }

    if (_liveLocations.isEmpty) return;

    try {
      final locations = _liveLocations.values.toList();

      // Calculate bounds
      double minLat = locations.first.latitude;
      double maxLat = locations.first.latitude;
      double minLng = locations.first.longitude;
      double maxLng = locations.first.longitude;

      for (final location in locations) {
        minLat = math.min(minLat, location.latitude);
        maxLat = math.max(maxLat, location.latitude);
        minLng = math.min(minLng, location.longitude);
        maxLng = math.max(maxLng, location.longitude);
      }

      // Calculate center and zoom to fit all markers
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Calculate appropriate zoom level based on bounds
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = math.max(latDiff, lngDiff);

      // Simple zoom calculation (can be refined)
      double zoom = 14.0;
      if (maxDiff > 0.1) {
        zoom = 10.0;
      } else if (maxDiff > 0.01) {
        zoom = 12.0;
      } else if (maxDiff > 0.001) {
        zoom = 14.0;
      } else {
        zoom = 16.0;
      }

      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: zoom,
      );

      final animationOptions = MapAnimationOptions(
        duration: animationDuration.inMilliseconds,
      );

      await _mapboxMap!.easeTo(cameraOptions, animationOptions);
    } catch (e) {
      throw MapboxException('Failed to fit camera to markers: ${e.toString()}');
    }
  }

  /// Get current camera position
  Future<CameraState> getCurrentCameraState() async {
    if (_mapboxMap == null) {
      throw MapboxException('Map not initialized');
    }

    try {
      return await _mapboxMap!.getCameraState();
    } catch (e) {
      throw MapboxException('Failed to get camera state: ${e.toString()}');
    }
  }

  /// Enable/disable map interactions
  Future<void> setInteractionsEnabled(bool enabled) async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: enabled && MapboxConfig.enableRotation,
          pitchEnabled: enabled && MapboxConfig.enableTilt,
          scrollEnabled: enabled && MapboxConfig.enablePan,
        ),
      );
    } catch (e) {
      debugPrint('Warning: Failed to set interactions: $e');
    }
  }

  /// Get distance between two points in meters using Haversine formula
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get all current live locations
  Map<String, LiveLocation> get currentLiveLocations =>
      Map.unmodifiable(_liveLocations);

  /// Get marker count
  int get markerCount => _markers.length;

  /// Check if user has marker on map
  bool hasMarkerForUser(String userId) => _markers.containsKey(userId);

  /// Dispose resources and cleanup
  void dispose() {
    _markers.clear();
    _liveLocations.clear();
    _pointAnnotationManager = null;
    _polylineAnnotationManager = null;
    _circleAnnotationManager = null;
    _mapboxMap = null;
    _isInitialized = false;
  }
}

/// Custom exception class for Mapbox operations
class MapboxException implements Exception {
  final String message;

  MapboxException(this.message);

  @override
  String toString() => 'MapboxException: $message';
}
