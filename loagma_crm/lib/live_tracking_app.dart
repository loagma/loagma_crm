import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'router/live_tracking_router.dart';
import 'widgets/live_tracking_session_manager.dart';

/// Main application for the Live Salesman Tracking System
/// Demonstrates Firebase authentication with role-based access control
class LiveTrackingApp extends StatelessWidget {
  const LiveTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Live Salesman Tracking',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFD7BE69),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD7BE69),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routerConfig: LiveTrackingRouter.router,
      builder: (context, child) {
        return LiveTrackingSessionManager(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Entry point for the Live Tracking demo app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const LiveTrackingApp());
}
