import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/nsm/nsm_dashboard_screen.dart';
import '../screens/rsm/rsm_dashboard_screen.dart';
import '../screens/asm/asm_dashboard_screen.dart';
import '../screens/tso/tso_dashboard_screen.dart';

class RoleRouter {
  static Widget getDashboardForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'nsm':
        return const NsmDashboardScreen();
      case 'rsm':
        return const RsmDashboardScreen();
      case 'asm':
        return const AsmDashboardScreen();
      case 'tso':
        return const TsoDashboardScreen();
      default:
        return const AdminDashboardScreen(); // Default fallback
    }
  }

  static void navigateToRoleDashboard(BuildContext context, String? role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => getDashboardForRole(role)),
    );
  }
}
