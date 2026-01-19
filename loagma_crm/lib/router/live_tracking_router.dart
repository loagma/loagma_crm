import 'package:go_router/go_router.dart';
import '../screens/auth/live_tracking_login_screen.dart';
import '../screens/auth/live_tracking_register_screen.dart';
import '../screens/auth/live_tracking_forgot_password_screen.dart';
import '../screens/live_tracking/admin_dashboard_screen.dart';
import '../screens/live_tracking/salesman_dashboard_screen.dart';
import '../widgets/live_tracking_session_manager.dart';
import '../models/live_tracking/location_models.dart';

/// Router configuration for the Live Salesman Tracking System
/// Handles navigation and route protection based on user roles
class LiveTrackingRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/live-tracking/login',
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/live-tracking/login',
        builder: (context, state) => const LiveTrackingLoginScreen(),
      ),
      GoRoute(
        path: '/live-tracking/register',
        builder: (context, state) => const LiveTrackingRegisterScreen(),
      ),
      GoRoute(
        path: '/live-tracking/forgot-password',
        builder: (context, state) => const LiveTrackingForgotPasswordScreen(),
      ),

      // Protected Admin Routes
      GoRoute(
        path: '/live-tracking/admin',
        builder: (context, state) => const LiveTrackingAuthGuard(
          requiredRole: UserRole.admin,
          child: AdminDashboardScreen(),
        ),
      ),

      // Protected Salesman Routes
      GoRoute(
        path: '/live-tracking/salesman',
        builder: (context, state) => const LiveTrackingAuthGuard(
          requiredRole: UserRole.salesman,
          child: SalesmanDashboardScreen(),
        ),
      ),
    ],
  );
}

/// Extension to add live tracking routes to existing router
extension LiveTrackingRoutes on List<RouteBase> {
  void addLiveTrackingRoutes() {
    addAll([
      // Authentication Routes
      GoRoute(
        path: '/live-tracking/login',
        builder: (context, state) => const LiveTrackingLoginScreen(),
      ),
      GoRoute(
        path: '/live-tracking/register',
        builder: (context, state) => const LiveTrackingRegisterScreen(),
      ),
      GoRoute(
        path: '/live-tracking/forgot-password',
        builder: (context, state) => const LiveTrackingForgotPasswordScreen(),
      ),

      // Protected Admin Routes
      GoRoute(
        path: '/live-tracking/admin',
        builder: (context, state) => const LiveTrackingAuthGuard(
          requiredRole: UserRole.admin,
          child: AdminDashboardScreen(),
        ),
      ),

      // Protected Salesman Routes
      GoRoute(
        path: '/live-tracking/salesman',
        builder: (context, state) => const LiveTrackingAuthGuard(
          requiredRole: UserRole.salesman,
          child: SalesmanDashboardScreen(),
        ),
      ),
    ]);
  }
}
