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
  final double? logoWidth;
  final double? logoHeight;
  final String? appName;
  final String? appVersion;

  const RoleDashboardTemplate({
    super.key,
    required this.roleName,
    required this.roleDisplayName,
    required this.roleIcon,
    this.cards,
    this.primaryColor,
    this.userContactNumber,
    this.logoPath,
    this.logoWidth,
    this.logoHeight,
    this.appName,
    this.appVersion,
  });

  // ------------------------------------------------------------
  // Sidebar items for each role
  // ------------------------------------------------------------
  List<SidebarItem> getSidebarMenu() {
    switch (roleName) {
      case "admin":
        return [
          SidebarItem(
            "Dashboard",
            Icons.dashboard_outlined,
            "/dashboard/admin",
          ),
          SidebarItem("Employees", Icons.people_outline, "/admin/employees"),
          SidebarItem(
            "Create Employee",
            Icons.person_add,
            "/admin/employees/create",
          ),
          SidebarItem(
            "Manage Roles",
            Icons.admin_panel_settings,
            "/admin/roles",
          ),
          SidebarItem(
            "Schedule Task",
            Icons.task_outlined,
            "/admin/tasks/schedule",
          ),
          SidebarItem(
            "View Tasks",
            Icons.list_alt_outlined,
            "/admin/tasks/view",
          ),
          SidebarItem("Account Master", Icons.account_box, "/account/master"),
          SidebarItem("View All Accounts", Icons.list_alt, "/account/all"),
          SidebarItem("Submit Expense", Icons.receipt_long, "/expense/create"),
          SidebarItem("My Expenses", Icons.history, "/expense/my"),
        ];

      case "employee":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/employee"),
          SidebarItem("Profile", Icons.person, "/profile"),
          SidebarItem("Settings", Icons.settings, "/settings"),
        ];

      default:
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/$roleName"),
        ];
    }
  }

  // ------------------------------------------------------------
  // Auto-generate cards (same as your current logic)
  // ------------------------------------------------------------
  List<DashboardCard> getDashCards(BuildContext context) {
    if (cards != null && cards!.isNotEmpty) return cards!;

    return getSidebarMenu().where((item) => item.title != "Dashboard").map((
      item,
    ) {
      return DashboardCard(
        title: item.title,
        icon: item.icon,
        onTap: () => context.go(item.route),
      );
    }).toList();
  }

  // ------------------------------------------------------------
  // Build UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFFD7BE69);
    final items = getSidebarMenu();
    final dashCards = getDashCards(context);

    return WillPopScope(
      onWillPop: () async {
        final exit = await _confirmExit(context);
        return exit ?? false;
      },
      child: Scaffold(
        appBar: _buildAppBar(context, color),
        drawer: EnterpriseSidebar(
          items: items,
          primaryColor: color,
          roleName: roleDisplayName,
          userContact: userContactNumber,
          logoPath: logoPath,
          appName: appName,
        ),
        body: _buildBody(context, color, dashCards),
      ),
    );
  }

  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you want to exit the application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Yes, Exit"),
          ),
        ],
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
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
  // Body + Grid
  // ------------------------------------------------------------
  Widget _buildBody(
    BuildContext context,
    Color color,
    List<DashboardCard> cards,
  ) {
    return Column(
      children: [
        _header(color),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: cards
                .map(
                  (c) => Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: c.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c.icon, size: 40, color: color),
                          const SizedBox(height: 10),
                          Text(
                            c.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
          Icon(roleIcon, color: Colors.white, size: 35),
          const SizedBox(width: 12),
          Text(
            roleDisplayName,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// MODEL
// ----------------------------------------------------------------
class DashboardCard {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DashboardCard({required this.title, required this.icon, required this.onTap});
}
