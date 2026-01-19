import 'dart:math' as math;
import '../../models/live_tracking/location_models.dart';

/// Service for clustering map markers when they are close together
/// Improves map performance and readability with many markers
class MapClusteringService {
  static MapClusteringService? _instance;
  static MapClusteringService get instance =>
      _instance ??= MapClusteringService._();
  MapClusteringService._();

  // Clustering configuration
  static const double defaultClusterRadius = 50.0; // pixels
  static const int maxClusterZoom = 14;
  static const int minPointsToCluster = 2;

  /// Cluster locations based on their proximity
  List<MapCluster> clusterLocations(
    List<LiveLocation> locations, {
    double clusterRadius = defaultClusterRadius,
    int currentZoom = 12,
  }) {
    if (locations.length < minPointsToCluster || currentZoom > maxClusterZoom) {
      // Don't cluster if too few points or zoom level is too high
      return locations.map((location) => MapCluster.single(location)).toList();
    }

    final clusters = <MapCluster>[];
    final processed = <bool>[];

    // Initialize processed array
    for (int i = 0; i < locations.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < locations.length; i++) {
      if (processed[i]) continue;

      final currentLocation = locations[i];
      final clusterLocations = <LiveLocation>[currentLocation];
      processed[i] = true;

      // Find nearby locations to cluster
      for (int j = i + 1; j < locations.length; j++) {
        if (processed[j]) continue;

        final distance = _calculatePixelDistance(
          currentLocation,
          locations[j],
          currentZoom,
        );

        if (distance <= clusterRadius) {
          clusterLocations.add(locations[j]);
          processed[j] = true;
        }
      }

      // Create cluster
      if (clusterLocations.length == 1) {
        clusters.add(MapCluster.single(clusterLocations.first));
      } else {
        clusters.add(MapCluster.multiple(clusterLocations));
      }
    }

    return clusters;
  }

  /// Calculate pixel distance between two locations at given zoom level
  double _calculatePixelDistance(
    LiveLocation location1,
    LiveLocation location2,
    int zoomLevel,
  ) {
    // Convert lat/lng to pixel coordinates at given zoom level
    final point1 = _latLngToPixel(
      location1.latitude,
      location1.longitude,
      zoomLevel,
    );
    final point2 = _latLngToPixel(
      location2.latitude,
      location2.longitude,
      zoomLevel,
    );

    // Calculate Euclidean distance
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;

    return math.sqrt(dx * dx + dy * dy);
  }

  /// Convert latitude/longitude to pixel coordinates
  PixelPoint _latLngToPixel(double lat, double lng, int zoom) {
    final scale = math.pow(2, zoom).toDouble();

    // Web Mercator projection
    final x = (lng + 180.0) / 360.0 * scale * 256;
    final latRad = lat * math.pi / 180.0;
    final y =
        (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        scale *
        256;

    return PixelPoint(x, y);
  }

  /// Get cluster bounds (bounding box containing all locations in cluster)
  ClusterBounds getClusterBounds(MapCluster cluster) {
    final locations = cluster.locations;
    if (locations.isEmpty) {
      throw ArgumentError('Cluster cannot be empty');
    }

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

    return ClusterBounds(
      southwest: LocationPoint(minLat, minLng),
      northeast: LocationPoint(maxLat, maxLng),
    );
  }

  /// Calculate optimal zoom level to separate clustered locations
  int calculateOptimalZoom(MapCluster cluster) {
    if (cluster.locations.length <= 1) {
      return 16; // Default zoom for single location
    }

    final bounds = getClusterBounds(cluster);
    final latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
    final lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;
    final maxDiff = math.max(latDiff, lngDiff);

    // Calculate zoom level based on bounds
    if (maxDiff > 0.1) return 10;
    if (maxDiff > 0.01) return 12;
    if (maxDiff > 0.001) return 14;
    if (maxDiff > 0.0001) return 16;
    return 18;
  }
}

/// Represents a cluster of map markers
class MapCluster {
  final List<LiveLocation> locations;
  final LocationPoint center;
  final bool isSingleLocation;

  MapCluster._({
    required this.locations,
    required this.center,
    required this.isSingleLocation,
  });

  /// Create a cluster with a single location
  factory MapCluster.single(LiveLocation location) {
    return MapCluster._(
      locations: [location],
      center: LocationPoint(location.latitude, location.longitude),
      isSingleLocation: true,
    );
  }

  /// Create a cluster with multiple locations
  factory MapCluster.multiple(List<LiveLocation> locations) {
    if (locations.isEmpty) {
      throw ArgumentError('Locations list cannot be empty');
    }

    // Calculate center point (centroid)
    double totalLat = 0;
    double totalLng = 0;

    for (final location in locations) {
      totalLat += location.latitude;
      totalLng += location.longitude;
    }

    final centerLat = totalLat / locations.length;
    final centerLng = totalLng / locations.length;

    return MapCluster._(
      locations: List.unmodifiable(locations),
      center: LocationPoint(centerLat, centerLng),
      isSingleLocation: false,
    );
  }

  /// Get the number of locations in this cluster
  int get count => locations.length;

  /// Get the number of active locations in this cluster
  int get activeCount => locations.where((loc) => loc.isActive).length;

  /// Check if all locations in cluster are active
  bool get allActive => locations.every((loc) => loc.isActive);

  /// Check if any location in cluster is active
  bool get hasActive => locations.any((loc) => loc.isActive);

  /// Get cluster display text
  String get displayText {
    if (isSingleLocation) {
      return locations.first.userId.substring(0, 8);
    } else {
      return count.toString();
    }
  }

  /// Get cluster color based on activity status
  int get clusterColor {
    if (isSingleLocation) {
      return locations.first.isActive ? 0xFF4CAF50 : 0xFFFF9800;
    } else {
      if (allActive) return 0xFF4CAF50; // Green - all active
      if (hasActive) return 0xFFFF9800; // Orange - mixed
      return 0xFF9E9E9E; // Grey - all inactive
    }
  }
}

/// Represents a point in pixel coordinates
class PixelPoint {
  final double x;
  final double y;

  PixelPoint(this.x, this.y);
}

/// Represents a geographic point
class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint(this.latitude, this.longitude);
}

/// Represents the bounds of a cluster
class ClusterBounds {
  final LocationPoint southwest;
  final LocationPoint northeast;

  ClusterBounds({required this.southwest, required this.northeast});

  /// Get the center point of the bounds
  LocationPoint get center {
    final centerLat = (southwest.latitude + northeast.latitude) / 2;
    final centerLng = (southwest.longitude + northeast.longitude) / 2;
    return LocationPoint(centerLat, centerLng);
  }

  /// Get the span (width and height) of the bounds
  LocationPoint get span {
    final latSpan = northeast.latitude - southwest.latitude;
    final lngSpan = northeast.longitude - southwest.longitude;
    return LocationPoint(latSpan, lngSpan);
  }
}
