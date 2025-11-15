import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_template.dart';

class NsmDashboardScreen extends StatelessWidget {
  final String? userRole;
  final String? userContactNumber;

  const NsmDashboardScreen({super.key, this.userRole, this.userContactNumber});

  @override
  Widget build(BuildContext context) {
    return RoleDashboardTemplate(
      roleName: 'nsm',
      roleDisplayName: userRole ?? 'National Sales Manager',
      roleIcon: Icons.business_center,
      primaryColor: const Color(0xFFD7BE69), // Gold
      userContactNumber: userContactNumber,
      cards: [
        // Add NSM specific cards here when features are ready
      ],
    );
  }
}
