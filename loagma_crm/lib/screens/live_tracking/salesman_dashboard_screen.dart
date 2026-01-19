import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../services/live_tracking/auth_service.dart';
import '../../services/live_tracking/location_service.dart';
import '../../services/live_tracking/firebase_live_tracking_service.dart';
import '../../models/live_tracking/location_models.dart';

/// Enhanced Salesman dashboard for the Live Salesman Tracking System
/// Provides comprehensive location tracking controls, status indicators, and notifications
class SalesmanDashboardScreen extends StatefulWidget {
  const SalesmanDashboardScreen({super.key});

  @override
  State<SalesmanDashboardScreen> createState() =>
      _SalesmanDashboardScreenState();
}

class _SalesmanDashboardScreenState extends State<SalesmanDashboardScreen>
    with WidgetsBindingObserver {
  TrackingUser? _currentUser;
  bool _isLoading = true;
  bool _isTracking = false;
  Position? _currentLocation;
  LocationServiceStatus _locationStatus = LocationServiceStatus.stopped;
  String _statusMessage = 'Ready to start tracking';

  // Tracking statistics
  Duration _trackingDuration = Duration.zero;
  double _totalDistance = 0.0;
  int _locationUpdates = 0;
  Timer? _trackingTimer;
  DateTime? _trackingStartTime;

  // Stream subscriptions
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<LocationServiceStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _setupLocationListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingTimer?.cancel();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes for background tracking
    if (state == AppLifecycleState.paused && _isTracking) {
      _showNotification('Tracking continues in background');
    } else if (state == AppLifecycleState.resumed && _isTracking) {
      _updateTrackingStats();
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Ensure user has salesman role
      await AuthService.instance.requireSalesmanRole();

      setState(() {
        _currentUser = AuthService.instance.currentTrackingUser;
        _isLoading = false;
      });
    } on AuthException {
      // User doesn't have salesman role, redirect to login
      if (mounted) {
        context.go('/live-tracking/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load user data: ${e.toString()}');
    }
  }

  void _setupLocationListeners() {
    // Listen to location updates
    _locationSubscription = LocationService.instance.locationStream.listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _currentLocation = position;
            _locationUpdates++;
            _updateTrackingStats();
          });

          // Send location to Firebase
          _sendLocationUpdate(position);
        }
      },
      onError: (error) {
        _showErrorSnackBar('Location error: ${error.toString()}');
      },
    );

    // Listen to location service status changes
    _statusSubscription = LocationService.instance.statusStream.listen((
      LocationServiceStatus status,
    ) {
      if (mounted) {
        setState(() {
          _locationStatus = status;
          _statusMessage = _getStatusMessage(status);
        });
      }
    });
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      if (_currentUser != null) {
        // Use the Position directly with the Firebase service
        await FirebaseLiveTrackingService.instance.updateLiveLocation(position);
      }
    } catch (e) {
      // Don't show error for every location update failure
      // Just log it for debugging
      debugPrint('Failed to send location update: $e');
    }
  }

  String _getStatusMessage(LocationServiceStatus status) {
    switch (status) {
      case LocationServiceStatus.tracking:
        return 'Tracking active - Location updates enabled';
      case LocationServiceStatus.stopped:
        return 'Tracking stopped';
      case LocationServiceStatus.permissionDenied:
        return 'Location permission required';
      case LocationServiceStatus.serviceDisabled:
        return 'Location services disabled';
      case LocationServiceStatus.error:
        return 'Location service error';
    }
  }

  void _updateTrackingStats() {
    if (_trackingStartTime != null) {
      _trackingDuration = DateTime.now().difference(_trackingStartTime!);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      // Stop tracking before signing out
      if (_isTracking) {
        await _stopTracking();
      }

      await AuthService.instance.signOut();
      if (mounted) {
        context.go('/live-tracking/login');
      }
    } catch (e) {
      _showErrorSnackBar('Error signing out: ${e.toString()}');
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Starting location tracking...';
      });

      // Request location permissions
      final permissionResult = await LocationService.instance
          .requestLocationPermission();
      if (!permissionResult.isGranted) {
        _showPermissionDialog(permissionResult.message);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Start location tracking
      final success = await LocationService.instance.startLocationTracking(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 meters
        timeInterval: const Duration(seconds: 30),
      );

      if (success) {
        setState(() {
          _isTracking = true;
          _trackingStartTime = DateTime.now();
          _trackingDuration = Duration.zero;
          _totalDistance = 0.0;
          _locationUpdates = 0;
          _statusMessage = 'Location tracking started';
        });

        // Start tracking timer
        _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            _updateTrackingStats();
            setState(() {});
          }
        });

        _showSuccessSnackBar('Location tracking started successfully');
      } else {
        _showErrorSnackBar('Failed to start location tracking');
      }
    } catch (e) {
      _showErrorSnackBar('Error starting tracking: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopTracking() async {
    try {
      setState(() {
        _statusMessage = 'Stopping location tracking...';
      });

      await LocationService.instance.stopLocationTracking();
      _trackingTimer?.cancel();

      setState(() {
        _isTracking = false;
        _trackingStartTime = null;
        _statusMessage = 'Location tracking stopped';
      });

      _showSuccessSnackBar('Location tracking stopped');
    } catch (e) {
      _showErrorSnackBar('Error stopping tracking: ${e.toString()}');
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              LocationService.instance.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFD7BE69),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking - Salesman'),
        backgroundColor: const Color(0xFFD7BE69),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile screen
                  break;
                case 'settings':
                  // TODO: Navigate to settings screen
                  break;
                case 'logout':
                  _handleSignOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      _currentUser?.name.isNotEmpty == true
                          ? _currentUser!.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Color(0xFFD7BE69),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle,
                      size: 48,
                      color: Color(0xFFD7BE69),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${_currentUser?.name ?? 'Salesman'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${_isTracking ? 'Active' : 'Inactive'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isTracking ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tracking Control Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _isTracking ? Icons.location_on : Icons.location_off,
                      size: 64,
                      color: _isTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTracking
                          ? 'Location Tracking Active'
                          : 'Location Tracking Inactive',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTracking
                          ? 'Your location is being shared with administrators'
                          : 'Tap the button below to start location tracking',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleTracking,
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          _isTracking ? 'Stop Tracking' : 'Start Tracking',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking
                              ? Colors.red
                              : const Color(0xFFD7BE69),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.history,
                    title: 'My Routes',
                    subtitle: 'View route history',
                    onTap: () {
                      // TODO: Navigate to route history screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Route History - Coming Soon'),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.map,
                    title: 'Current Location',
                    subtitle: 'View on map',
                    onTap: () {
                      // TODO: Navigate to current location screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Current Location - Coming Soon'),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.analytics,
                    title: 'My Stats',
                    subtitle: 'View statistics',
                    onTap: () {
                      // TODO: Navigate to statistics screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Statistics - Coming Soon'),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.support,
                    title: 'Help',
                    subtitle: 'Get support',
                    onTap: () {
                      // TODO: Navigate to help screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFFD7BE69)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
