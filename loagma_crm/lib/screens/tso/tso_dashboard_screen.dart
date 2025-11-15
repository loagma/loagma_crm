import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_template.dart';

class TsoDashboardScreen extends StatelessWidget {
  final String? userRole;
  final String? userContactNumber;

  const TsoDashboardScreen({super.key, this.userRole, this.userContactNumber});

  @override
  Widget build(BuildContext context) {
    return RoleDashboardTemplate(
      roleName: 'tso',
      roleDisplayName: userRole ?? 'Territory Sales Officer',
      roleIcon: Icons.person_pin_circle,
      primaryColor: const Color(0xFFD7BE69), // Gold
      userContactNumber: userContactNumber,
      cards: [
        // Add TSO specific cards here when features are ready
      ],
    );
  }
}
