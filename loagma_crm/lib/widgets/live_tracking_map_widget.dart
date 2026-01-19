import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import '../services/live_tracking/mapbox_service.dart';
import '../services/live_tracking/firebase_live_tracking_service.dart';
import '../models/live_tracking/location_models.dart';
import '../config/mapbox_config.dart';

/// Live tracking map widget that displays real-time salesman locations
/// Supports marker clustering, route visualization, and map interactions
class LiveTrackingMapWidget extends StatefulWidget {
  final bool showAllSalesmen;
  final String? specificUserId;
  final bool enableClustering;
  final bool showRoutes;
  final VoidCallback? onMapReady;
  final Function(LiveLocation)? onMarkerTap;

  const LiveTrackingMapWidget({
    super.key,
    this.showAllSalesmen = true,
    this.specificUserId,
    this.enableClustering = true,
    this.showRoutes = false,
    this.onMapReady,
    this.onMarkerTap,
  });

  @override
  State<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget> {
  final MapboxService _mapboxService = MapboxService.instance;
  final FirebaseLiveTrackingService _trackingService =
      FirebaseLiveTrackingService.instance;

  StreamSubscription<List<LiveLocation>>? _locationsSubscription;
  bool _isMapReady = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkMapboxConfiguration();
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    super.dispose();
  }

  void _checkMapboxConfiguration() {
    if (!_mapboxService.isConfigured) {
      setState(() {
        _errorMessage =
            'Mapbox access token not configured. Please set up Mapbox in task 2.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    try {
      // Initialize Mapbox service
      await _mapboxService.initializeMap(mapboxMap);

      // Initialize tracking service
      await _trackingService.initialize();

      setState(() {
        _isMapReady = true;
        _isLoading = false;
      });

      // Start listening to location updates
      _startLocationUpdates();

      // Notify parent that map is ready
      widget.onMapReady?.call();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize map: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() {
    if (widget.showAllSalesmen) {
      // Listen to all active salesmen locations
      _locationsSubscription = _trackingService
          .listenToActiveSalesmenLocations()
          .listen(
            _updateMapMarkers,
            onError: (error) {
              debugPrint('Error listening to locations: $error');
            },
          );
    } else if (widget.specificUserId != null) {
      // Listen to specific user location
      _locationsSubscription = _trackingService
          .listenToUserLocation(widget.specificUserId!)
          .map((location) => location != null ? [location] : <LiveLocation>[])
          .listen(
            _updateMapMarkers,
            onError: (error) {
              debugPrint('Error listening to user location: $error');
            },
          );
    }
  }

  Future<void> _updateMapMarkers(List<LiveLocation> locations) async {
    if (!_isMapReady || !mounted) return;

    try {
      // Clear existing markers
      await _mapboxService.clearAllMarkers();

      // Add new markers
      if (locations.isNotEmpty) {
        await _mapboxService.addMultipleLiveLocationMarkers(locations);

        // Fit camera to show all markers if there are multiple locations
        if (locations.length > 1) {
          await _mapboxService.fitCameraToMarkers();
        } else if (locations.length == 1) {
          // Center on single location
          final location = locations.first;
          await _mapboxService.moveCameraToLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            zoom: 16.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating map markers: $e');
    }
  }

  Future<void> _onStyleLoadedListener(StyleLoadedEventData data) async {
    // Style loaded, can add custom images or perform style-specific operations
    try {
      // Custom marker images can be added here in the future
    } catch (e) {
      debugPrint('Error in style loaded listener: $e');
    }
  }

  Widget _buildMapView() {
    return MapWidget(
      key: const ValueKey('mapbox_map'),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(77.2090, 28.6139), // Default to Delhi, India
        ),
        zoom: 12.0,
      ),
      styleUri: MapboxConfig.defaultMapStyle,
      textureView: true,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoadedListener,
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD7BE69)),
            SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Map Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _checkMapboxConfiguration();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        _buildMapView(),

        // Map controls overlay
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Map style toggle
              FloatingActionButton(
                mini: true,
                heroTag: 'map_style',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD7BE69),
                onPressed: _toggleMapStyle,
                child: const Icon(Icons.layers),
              ),
              const SizedBox(height: 8),

              // Fit to markers button
              if (_mapboxService.markerCount > 0)
                FloatingActionButton(
                  mini: true,
                  heroTag: 'fit_markers',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD7BE69),
                  onPressed: () => _mapboxService.fitCameraToMarkers(),
                  child: const Icon(Icons.center_focus_strong),
                ),
            ],
          ),
        ),

        // Status indicator
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isMapReady ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isMapReady
                      ? '${_mapboxService.markerCount} active'
                      : 'Connecting...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleMapStyle() {
    if (!_isMapReady) return;

    String newStyle;
    switch (_mapboxService.currentMapStyle) {
      case MapboxConfig.defaultMapStyle:
        newStyle = MapboxConfig.satelliteMapStyle;
        break;
      case MapboxConfig.satelliteMapStyle:
        newStyle = MapboxConfig.outdoorsMapStyle;
        break;
      default:
        newStyle = MapboxConfig.defaultMapStyle;
        break;
    }

    _mapboxService.changeMapStyle(newStyle).catchError((error) {
      debugPrint('Error changing map style: $error');
    });
  }
}

/// Map marker info widget that shows details about a location
class MapMarkerInfoWidget extends StatelessWidget {
  final LiveLocation location;
  final VoidCallback? onClose;

  const MapMarkerInfoWidget({super.key, required this.location, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Salesman Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.person,
            label: 'User ID',
            value: location.userId.substring(0, 8),
          ),

          _buildInfoRow(
            icon: location.isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            label: 'Status',
            value: location.isActive ? 'Active' : 'Inactive',
            valueColor: location.isActive ? Colors.green : Colors.orange,
          ),

          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Last Update',
            value: _formatTime(location.lastUpdate),
          ),

          _buildInfoRow(
            icon: Icons.speed,
            label: 'Speed',
            value: location.speed != null
                ? '${location.speed!.toStringAsFixed(1)} m/s'
                : 'Unknown',
          ),

          _buildInfoRow(
            icon: Icons.gps_fixed,
            label: 'Accuracy',
            value: '${location.accuracy.toStringAsFixed(1)} m',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
