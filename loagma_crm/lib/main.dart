import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/user_service.dart';
import 'utils/exit_dialog.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserService.init(); // load prefs
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

      // ⬇️ BACK BUTTON LOGIC GOES HERE
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () => _handleBackPress(context),
          child: child!,
        );
      },
    );
  }
}
