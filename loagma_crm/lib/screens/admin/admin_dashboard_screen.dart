import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'view_users_screen.dart';
import 'manage_roles_screen.dart';
import '../shared/employee_account_master_screen.dart';
import '../shared/account_master_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildDashboardCard(
              context,
              'Create User',
              Icons.person_add,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCreateUserScreen(),
                ),
              ),
            ),
            _buildDashboardCard(
              context,
              'View Users',
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminViewUsersScreen(),
                ),
              ),
            ),
            _buildDashboardCard(
              context,
              'Manage Roles',
              Icons.admin_panel_settings,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRolesScreen(),
                ),
              ),
            ),
            _buildDashboardCard(
              context,
              'Employee Master',
              Icons.badge,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeAccountMasterScreen(),
                ),
              ),
            ),
            _buildDashboardCard(
              context,
              'Account Master',
              Icons.account_box,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountMasterScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: const Color(0xFFD7BE69)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
