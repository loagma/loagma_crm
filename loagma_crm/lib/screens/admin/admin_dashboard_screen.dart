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
      cards: [
        DashboardCard(
          title: 'Create User',
          icon: Icons.person_add,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCreateUserScreen(),
            ),
          ),
        ),
        DashboardCard(
          title: 'View Users',
          icon: Icons.people,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminViewUsersScreen(),
            ),
          ),
        ),
        DashboardCard(
          title: 'Manage Roles',
          icon: Icons.admin_panel_settings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageRolesScreen()),
          ),
        ),
        DashboardCard(
          title: 'Employee Master',
          icon: Icons.badge,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Employee Master - Coming Soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        DashboardCard(
          title: 'Account Master',
          icon: Icons.account_box,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
