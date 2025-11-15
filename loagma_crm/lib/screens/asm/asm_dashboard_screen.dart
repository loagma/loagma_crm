import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_template.dart';

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
      cards: [
        // Add ASM specific cards here when features are ready
      ],
    );
  }
}
