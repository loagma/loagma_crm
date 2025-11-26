import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../widgets/enterprise_sidebar.dart';

class RoleDashboardTemplate extends StatelessWidget {
  final String roleName;
  final String roleDisplayName;
  final IconData roleIcon;
  final List<DashboardCard>? cards;
  final Color? primaryColor;
  final String? userContactNumber;

  final String? logoPath;
  final String? appName;

  const RoleDashboardTemplate({
    super.key,
    required this.roleName,
    required this.roleDisplayName,
    required this.roleIcon,
    this.cards,
    this.primaryColor,
    this.userContactNumber,
    this.logoPath,
    this.appName,
  });

  // ------------------------------------------------------------
  // Sidebar menu definitions (with nested GoRouter paths)
  // ------------------------------------------------------------
  List<SidebarItem> getSidebarMenu() {
    switch (roleName.toLowerCase()) {
      case "admin":
        return [
          SidebarItem("Dashboard", Icons.dashboard_outlined, "/dashboard/admin"),
          SidebarItem("Employees", Icons.people_outline, "/dashboard/admin/employees"),
          SidebarItem("Create Employee", Icons.person_add, "/dashboard/admin/employees/create"),
          SidebarItem("Manage Roles", Icons.admin_panel_settings, "/dashboard/admin/roles"),
          SidebarItem("Schedule Task", Icons.task_outlined, "/dashboard/admin/tasks/schedule"),
          SidebarItem("View Tasks", Icons.list_alt_outlined, "/dashboard/admin/tasks/view"),
          SidebarItem("Account Master", Icons.account_box, "/dashboard/admin/account/master"),
          SidebarItem("View All Accounts", Icons.list_alt, "/dashboard/admin/account/all"),
          SidebarItem("Submit Expense", Icons.receipt_long, "/dashboard/admin/expense/create"),
          SidebarItem("My Expenses", Icons.history, "/dashboard/admin/expense/my"),
        ];

      case "employee":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/employee"),
          SidebarItem("Profile", Icons.person, "/dashboard/employee/profile"),
          SidebarItem("Settings", Icons.settings, "/dashboard/employee/settings"),
        ];

      default:
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/$roleName"),
        ];
    }
  }

  List<DashboardCard> getDashCards(BuildContext context) {
    if (cards != null && cards!.isNotEmpty) return cards!;

    return getSidebarMenu()
        .where((m) => m.title != "Dashboard")
        .map(
          (m) => DashboardCard(
            title: m.title,
            icon: m.icon,
            onTap: () => context.go(m.route),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFFD7BE69);
    final dashCards = getDashCards(context);

    return Scaffold(
      appBar: _buildAppBar(context, color),
      drawer: EnterpriseSidebar(
        items: getSidebarMenu(),
        primaryColor: color,
        roleName: roleDisplayName,
        userContact: userContactNumber,
        logoPath: logoPath,
        appName: appName,
      ),
      body: _buildBody(context, color, dashCards),
    );
  }

  // ------------------------------------------------------------
  // AppBar
  // ------------------------------------------------------------
  AppBar _buildAppBar(BuildContext context, Color color) {
    return AppBar(
      backgroundColor: color,
      elevation: 2,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Icon(roleIcon, size: 24),
          const SizedBox(width: 10),
          Text("$roleDisplayName Dashboard"),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Logout",
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              UserService.logout();
              Navigator.pop(c);
              context.go('/login');
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Body + Cards Grid
  // ------------------------------------------------------------
  Widget _buildBody(BuildContext context, Color color, List<DashboardCard> cards) {
    return Column(
      children: [
        _header(color),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: cards
                .map(
                  (c) => Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: c.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c.icon, size: 40, color: color),
                          const SizedBox(height: 10),
                          Text(
                            c.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _header(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
      ),
      child: Row(
        children: [
          Icon(roleIcon, size: 35, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            roleDisplayName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// MODEL
// ------------------------------------------------------------
class DashboardCard {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DashboardCard({required this.title, required this.icon, required this.onTap});
}
