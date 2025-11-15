import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_template.dart';

class RsmDashboardScreen extends StatelessWidget {
  final String? userRole;
  final String? userContactNumber;

  const RsmDashboardScreen({super.key, this.userRole, this.userContactNumber});

  @override
  Widget build(BuildContext context) {
    return RoleDashboardTemplate(
      roleName: 'rsm',
      roleDisplayName: userRole ?? 'Regional Sales Manager',
      roleIcon: Icons.map,
      primaryColor: const Color(0xFFD7BE69), // Gold
      userContactNumber: userContactNumber,
      cards: [
        // Add RSM specific cards here when features are ready
      ],
    );
  }
}
