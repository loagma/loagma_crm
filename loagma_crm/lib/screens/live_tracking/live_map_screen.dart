import 'package:flutter/material.dart';
import '../../widgets/live_tracking_map_widget.dart';
import '../../models/live_tracking/location_models.dart';
import '../../services/live_tracking/auth_service.dart';

/// Live map screen for viewing real-time salesman locations
/// Provides different views for admin and salesman roles
class LiveMapScreen extends StatefulWidget {
  final bool isAdminView;
  final String? specificUserId;

  const LiveMapScreen({
    super.key,
    this.isAdminView = true,
    this.specificUserId,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  bool _showRoutes = false;
  bool _enableClustering = true;
  TrackingUser? _currentUser;
  LiveLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.instance.currentTrackingUser;
    setState(() {
      _currentUser = user;
    });
  }

  void _onMarkerTap(LiveLocation location) {
    setState(() {
      _selectedLocation = location;
    });

    // Show marker info bottom sheet
    _showMarkerInfo(location);
  }

  void _showMarkerInfo(LiveLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoTile(
              icon: Icons.person,
              title: 'User ID',
              subtitle: location.userId.substring(0, 12),
            ),

            _buildInfoTile(
              icon: location.isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              title: 'Status',
              subtitle: location.isActive ? 'Active' : 'Inactive',
              subtitleColor: location.isActive ? Colors.green : Colors.orange,
            ),

            _buildInfoTile(
              icon: Icons.location_on,
              title: 'Coordinates',
              subtitle:
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            ),

            _buildInfoTile(
              icon: Icons.access_time,
              title: 'Last Update',
              subtitle: _formatDateTime(location.lastUpdate),
            ),

            if (location.speed != null)
              _buildInfoTile(
                icon: Icons.speed,
                title: 'Speed',
                subtitle: '${location.speed!.toStringAsFixed(1)} m/s',
              ),

            _buildInfoTile(
              icon: Icons.gps_fixed,
              title: 'Accuracy',
              subtitle: '${location.accuracy.toStringAsFixed(1)} meters',
            ),

            const SizedBox(height: 16),

            if (widget.isAdminView) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showUserDetails(location.userId);
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('View User Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLocationHistory(location.userId);
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View Location History'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD7BE69)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: subtitleColor ?? Colors.black87,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  void _showUserDetails(String userId) {
    // TODO: Navigate to user details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User details for $userId - Coming Soon')),
    );
  }

  void _showLocationHistory(String userId) {
    // TODO: Navigate to location history screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location history for $userId - Coming Soon')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdminView ? 'Live Tracking - Admin' : 'Live Tracking',
        ),
        backgroundColor: const Color(0xFFD7BE69),
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdminView) ...[
            IconButton(
              icon: Icon(
                _enableClustering ? Icons.group_work : Icons.scatter_plot,
              ),
              onPressed: () {
                setState(() {
                  _enableClustering = !_enableClustering;
                });
              },
              tooltip: _enableClustering
                  ? 'Disable Clustering'
                  : 'Enable Clustering',
            ),
            IconButton(
              icon: Icon(_showRoutes ? Icons.route : Icons.location_on),
              onPressed: () {
                setState(() {
                  _showRoutes = !_showRoutes;
                });
              },
              tooltip: _showRoutes ? 'Hide Routes' : 'Show Routes',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  // Force refresh the map
                  setState(() {});
                  break;
                case 'settings':
                  _showMapSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Map Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: LiveTrackingMapWidget(
        showAllSalesmen: widget.isAdminView,
        specificUserId: widget.specificUserId ?? _currentUser?.id,
        enableClustering: _enableClustering,
        showRoutes: _showRoutes,
        onMarkerTap: _onMarkerTap,
        onMapReady: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map loaded successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      floatingActionButton: widget.isAdminView
          ? null
          : FloatingActionButton(
              onPressed: _toggleTracking,
              backgroundColor: const Color(0xFFD7BE69),
              tooltip: 'Center on My Location',
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
    );
  }

  void _toggleTracking() {
    // TODO: Implement location tracking toggle for salesman
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location tracking toggle - Coming Soon')),
    );
  }

  void _showMapSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Enable Clustering'),
              subtitle: const Text('Group nearby markers together'),
              value: _enableClustering,
              onChanged: (value) {
                setState(() {
                  _enableClustering = value;
                });
                Navigator.pop(context);
              },
              activeThumbColor: const Color(0xFFD7BE69),
            ),

            if (widget.isAdminView)
              SwitchListTile(
                title: const Text('Show Routes'),
                subtitle: const Text('Display salesman route history'),
                value: _showRoutes,
                onChanged: (value) {
                  setState(() {
                    _showRoutes = value;
                  });
                  Navigator.pop(context);
                },
                activeThumbColor: const Color(0xFFD7BE69),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
