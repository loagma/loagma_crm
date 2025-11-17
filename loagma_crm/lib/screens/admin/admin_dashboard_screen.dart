import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'view_users_screen.dart';
import 'manage_roles_screen.dart';
import '../shared/account_master_screen.dart';
import '../../widgets/role_dashboard_template.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String? userRole;
  final String? userContactNumber;

  const AdminDashboardScreen({
    super.key,
    this.userRole,
    this.userContactNumber,
  });

  @override
  Widget build(BuildContext context) {
    return RoleDashboardTemplate(
      roleName: 'admin',
      roleDisplayName: userRole ?? 'Administrator',
      roleIcon: Icons.admin_panel_settings,
      primaryColor: const Color(0xFFD7BE69), // Gold
      userContactNumber: userContactNumber,
      
      // Customize sidebar content here
      logoPath: 'assets/logo.png',
      logoWidth: 170,
      logoHeight: 105,
      appName: 'Loagma CRM',
      appVersion: 'Version 1.0.2',
      
      // Cards will be auto-generated from sidebar menu
    );
  }
}
