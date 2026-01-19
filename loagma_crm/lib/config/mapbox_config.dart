/// Mapbox configuration constants
class MapboxConfig {
  // Mapbox access token - configured for Live Salesman Tracking System
  // Token: pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA',
  );

  // Default map style
  static const String defaultMapStyle = 'mapbox://styles/mapbox/streets-v12';

  // Alternative map styles
  static const String satelliteMapStyle = 'mapbox://styles/mapbox/satellite-v9';
  static const String outdoorsMapStyle = 'mapbox://styles/mapbox/outdoors-v12';

  // Default camera settings
  static const double defaultZoom = 14.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;

  // Marker clustering settings
  static const int clusterRadius = 50;
  static const int maxClusterZoom = 14;

  // Map interaction settings
  static const bool enableRotation = true;
  static const bool enableTilt = true;
  static const bool enableZoom = true;
  static const bool enablePan = true;

  /// Validate if Mapbox is properly configured
  static bool isConfigured() {
    return accessToken != 'YOUR_MAPBOX_ACCESS_TOKEN_HERE' &&
        accessToken.isNotEmpty;
  }
}
