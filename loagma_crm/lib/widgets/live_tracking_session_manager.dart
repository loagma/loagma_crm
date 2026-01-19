import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/live_tracking/auth_service.dart';
import '../models/live_tracking/location_models.dart';

/// Session manager widget for Live Tracking System
/// Handles authentication state changes and role-based navigation
class LiveTrackingSessionManager extends StatefulWidget {
  final Widget child;

  const LiveTrackingSessionManager({super.key, required this.child});

  @override
  State<LiveTrackingSessionManager> createState() =>
      _LiveTrackingSessionManagerState();
}

class _LiveTrackingSessionManagerState
    extends State<LiveTrackingSessionManager> {
  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    await AuthService.instance.initialize();

    // Listen to authentication state changes
    AuthService.instance.trackingUserChanges.listen((TrackingUser? user) {
      if (mounted) {
        _handleAuthStateChange(user);
      }
    });
  }

  void _handleAuthStateChange(TrackingUser? user) {
    final currentRoute = GoRouterState.of(context).uri.path;

    if (user == null) {
      // User signed out, redirect to login if not already there
      if (!currentRoute.startsWith('/live-tracking/login') &&
          !currentRoute.startsWith('/live-tracking/register') &&
          !currentRoute.startsWith('/live-tracking/forgot-password')) {
        context.go('/live-tracking/login');
      }
    } else {
      // User signed in, redirect based on role if on auth screens
      if (currentRoute.startsWith('/live-tracking/login') ||
          currentRoute.startsWith('/live-tracking/register') ||
          currentRoute.startsWith('/live-tracking/forgot-password')) {
        switch (user.role) {
          case UserRole.admin:
            context.go('/live-tracking/admin');
            break;
          case UserRole.salesman:
            context.go('/live-tracking/salesman');
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Authentication guard widget for protected routes
class LiveTrackingAuthGuard extends StatelessWidget {
  final Widget child;
  final UserRole? requiredRole;

  const LiveTrackingAuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TrackingUser?>(
      stream: AuthService.instance.trackingUserChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // No user signed in
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/live-tracking/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check role requirement
        if (requiredRole != null && user.role != requiredRole) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have permission to access this page.\nRequired role: ${requiredRole.toString().split('.').last}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to appropriate dashboard based on user role
                      switch (user.role) {
                        case UserRole.admin:
                          context.go('/live-tracking/admin');
                          break;
                        case UserRole.salesman:
                          context.go('/live-tracking/salesman');
                          break;
                      }
                    },
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        // User has required role, show the protected content
        return child;
      },
    );
  }
}
