import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Service class for managing Mapbox map operations
/// Handles map initialization, camera controls, and map interactions
class MapboxService {
  MapboxMap? _mapboxMap;

  /// Initialize Mapbox map instance
  void initialize(MapboxMap map) {
    _mapboxMap = map;
  }

  /// Get the current map instance
  MapboxMap? get map => _mapboxMap;

  /// Check if map is initialized
  bool get isInitialized => _mapboxMap != null;

  /// Animate camera to a specific position
  Future<void> animateCamera({
    required Point center,
    double? zoom,
    double? bearing,
    double? pitch,
  }) async {
    if (_mapboxMap == null) return;

    final cameraOptions = CameraOptions(
      center: center,
      zoom: zoom,
      bearing: bearing,
      pitch: pitch,
    );

    await _mapboxMap!.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  /// Fit camera to bounds
  Future<void> fitBounds({
    required CoordinateBounds bounds,
    double padding = 50.0,
  }) async {
    if (_mapboxMap == null) return;

    final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
      bounds,
      MbxEdgeInsets(
        top: padding,
        left: padding,
        bottom: padding,
        right: padding,
      ),
      null,
      null,
      null,
      null,
    );

    await _mapboxMap!.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  /// Get current camera position
  Future<CameraState?> getCameraState() async {
    if (_mapboxMap == null) return null;
    return await _mapboxMap!.getCameraState();
  }

  /// Set map style
  Future<void> setStyle(String styleUri) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.loadStyleURI(styleUri);
  }

  /// Dispose map resources
  void dispose() {
    _mapboxMap = null;
  }
}
