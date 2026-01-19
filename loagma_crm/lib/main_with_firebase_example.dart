// Example of how to modify your main.dart to include Firebase initialization
// Copy the relevant parts to your actual main.dart file

import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'config/app_initialization.dart';
import 'utils/exit_dialog.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all app services including Firebase
  await AppInitialization.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _isDashboardRoute(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    return loc.startsWith('/dashboard');
  }

  Future<bool> _handleBackPress(BuildContext context) async {
    if (!_isDashboardRoute(context)) return true;
    return await showExitDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      title: 'Loagma CRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
