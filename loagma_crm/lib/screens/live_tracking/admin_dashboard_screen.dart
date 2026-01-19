import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/live_tracking/auth_service.dart';
import '../../models/live_tracking/location_models.dart';

/// Admin dashboard for the Live Salesman Tracking System
/// Provides administrative controls and monitoring capabilities
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  TrackingUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Ensure user has admin role
      await AuthService.instance.requireAdminRole();

      setState(() {
        _currentUser = AuthService.instance.currentTrackingUser;
        _isLoading = false;
      });
    } on AuthException {
      // User doesn't have admin role, redirect to login
      if (mounted) {
        context.go('/live-tracking/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        context.go('/live-tracking/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking - Admin'),
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
                          : 'A',
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
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Color(0xFFD7BE69),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_currentUser?.name ?? 'Admin'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Live Salesman Tracking System',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dashboard Features Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.map,
                    title: 'Live Map',
                    subtitle: 'View real-time locations',
                    onTap: () {
                      // TODO: Navigate to live map screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Live Map - Coming Soon')),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Manage Users',
                    subtitle: 'Add and manage salesmen',
                    onTap: () {
                      // TODO: Navigate to user management screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User Management - Coming Soon'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.analytics,
                    title: 'Reports',
                    subtitle: 'View tracking reports',
                    onTap: () {
                      // TODO: Navigate to reports screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reports - Coming Soon')),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.history,
                    title: 'Route History',
                    subtitle: 'View past routes',
                    onTap: () {
                      // TODO: Navigate to route history screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Route History - Coming Soon'),
                        ),
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

  Widget _buildFeatureCard({
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
              Icon(icon, size: 48, color: const Color(0xFFD7BE69)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
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
