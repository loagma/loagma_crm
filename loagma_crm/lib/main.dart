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
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
              backgroundColor: const Color(0xFFD7BE69),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD7BE69),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This feature is under development',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
