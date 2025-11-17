import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_template.dart';
import '../shared/account_master_screen.dart';

class AsmDashboardScreen extends StatelessWidget {
  final String? userRole;
  final String? userContactNumber;

  const AsmDashboardScreen({super.key, this.userRole, this.userContactNumber});

  @override
  Widget build(BuildContext context) {
    return RoleDashboardTemplate(
      roleName: 'asm',
      roleDisplayName: userRole ?? 'Area Sales Manager',
      roleIcon: Icons.location_city,
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
