import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/nsm/nsm_dashboard_screen.dart';
import 'screens/rsm/rsm_dashboard_screen.dart';
import 'screens/asm/asm_dashboard_screen.dart';
import 'screens/tso/tso_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loagma CRM',
      theme: ThemeData(primarySwatch: Colors.amber),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpScreen(),
        '/signup': (context) => const SignupScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/nsm-dashboard': (context) => const NsmDashboardScreen(),
        '/rsm-dashboard': (context) => const RsmDashboardScreen(),
        '/asm-dashboard': (context) => const AsmDashboardScreen(),
        '/tso-dashboard': (context) => const TsoDashboardScreen(),
      },
    );
  }
}
