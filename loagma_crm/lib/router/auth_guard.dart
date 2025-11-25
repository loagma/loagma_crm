import 'package:go_router/go_router.dart';
import '../services/user_service.dart';

String? authGuard(context, GoRouterState state) {
  final isLogged = UserService.isLoggedIn;
  final path = state.uri.path; // safer than toString()

  // PUBLIC ROUTES (Unauthenticated Allowed)
  const publicRoutes = ['/login', '/otp', '/signup'];

  // Allow public routes
  if (publicRoutes.contains(path)) {
    return null;
  }

  // If NOT logged in => redirect to login
  if (!isLogged) {
    return '/login';
  }

  // Otherwise allow access
  return null;
}
