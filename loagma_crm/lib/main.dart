import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'router/app_router.dart';
import 'services/user_service.dart';
import 'utils/exit_dialog.dart';
import 'config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await UserService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _isDashboardRoute(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return location.startsWith('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,

      builder: (context, child) {
        return PopScope(
          canPop: false, // we control pop manually
          onPopInvoked: (didPop) async {
            if (didPop) return;

            if (_isDashboardRoute(context)) {
              final shouldExit = await showExitDialog(context);
              if (shouldExit) {
                // ✅ Exit app
                Navigator.of(context).pop();
              }
            } else {
              Navigator.of(context).pop();
            }
          },
          child: child!,
        );
      },
    );
  }
}
