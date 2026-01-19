// Mapbox Configuration Template for Live Salesman Tracking System
// Copy this file to your Flutter project and update with your actual values

class MapboxConfig {
  // IMPORTANT: Replace with your actual Mapbox access token
  // Get your token from: https://account.mapbox.com/access-tokens/
  static const String accessToken = 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';

  // Default map style - choose from available options
  // Streets (recommended): mapbox://styles/mapbox/streets-v12
  // Satellite: mapbox://styles/mapbox/satellite-v9
  // Outdoors: mapbox://styles/mapbox/outdoors-v12
  // Light: mapbox://styles/mapbox/light-v11
  // Dark: mapbox://styles/mapbox/dark-v11
  static const String defaultMapStyle = 'mapbox://styles/mapbox/streets-v12';

  // Map configuration settings
  static const double defaultZoom = 10.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;

  // Default center coordinates (update for your region)
  static const double defaultLatitude = 28.6139; // New Delhi, India
  static const double defaultLongitude = 77.2090;

  // Clustering configuration
  static const int clusterRadius = 50;
  static const int maxClusterZoom = 14;

  // Marker configuration
  static const double markerSize = 30.0;
  static const String salesmanMarkerColor = '#FF0000'; // Red
  static const String adminMarkerColor = '#0000FF'; // Blue

  // Route visualization settings
  static const String routeLineColor = '#00FF00'; // Green
  static const double routeLineWidth = 3.0;
  static const double routeLineOpacity = 0.8;

  // Performance settings
  static const bool enableTelemetry = false; // Set to false for privacy
  static const int maxCacheSize = 50; // MB

  // Validation method
  static bool isConfigured() {
    return accessToken != 'YOUR_MAPBOX_ACCESS_TOKEN_HERE' &&
        accessToken.isNotEmpty;
  }

  // Get environment-specific configuration
  static String getAccessToken() {
    // In production, read from environment variables or secure storage
    // For development, you can use the constant above
    const String? envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    return envToken.isNotEmpty == true ? envToken : accessToken;
  }
}

// Environment-specific configurations
class MapboxEnvironment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  static String getCurrentEnvironment() {
    const String env = String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: development,
    );
    return env;
  }

  static MapboxConfig getConfigForEnvironment(String environment) {
    switch (environment) {
      case production:
        return ProductionMapboxConfig();
      case staging:
        return StagingMapboxConfig();
      default:
        return DevelopmentMapboxConfig();
    }
  }
}

// Development configuration
class DevelopmentMapboxConfig extends MapboxConfig {
  static const String devAccessToken = 'YOUR_DEV_MAPBOX_ACCESS_TOKEN_HERE';

  @override
  static String getAccessToken() {
    return devAccessToken;
  }
}

// Staging configuration
class StagingMapboxConfig extends MapboxConfig {
  static const String stagingAccessToken =
      'YOUR_STAGING_MAPBOX_ACCESS_TOKEN_HERE';

  @override
  static String getAccessToken() {
    return stagingAccessToken;
  }
}

// Production configuration
class ProductionMapboxConfig extends MapboxConfig {
  static const String prodAccessToken = 'YOUR_PROD_MAPBOX_ACCESS_TOKEN_HERE';

  @override
  static String getAccessToken() {
    return prodAccessToken;
  }
}
