import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../widgets/enterprise_sidebar.dart';
import '../../widgets/notification_bell.dart';
import '../salesman/salesman_dashboard_screen.dart';

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
  Future<bool> _onBackPressed(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Exit Application"),
        content: const Text("Do you really want to exit the app?"),
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

    return result ?? false; // block exit when dialog dismissed
  }

  // ------------------------------------------------------------
  // Sidebar menu definitions (with nested GoRouter paths)
  // ------------------------------------------------------------
  List<SidebarItem> getSidebarMenu() {
    switch (roleName.toLowerCase()) {
      case "admin":
        return [
          SidebarItem(
            "Dashboard",
            Icons.space_dashboard_outlined,
            "/dashboard/admin",
          ),
          SidebarItem(
            "Manage Roles",
            Icons.manage_accounts_outlined,
            "/dashboard/admin/roles",
          ),
          SidebarItem(
            "Create Employee",
            Icons.person_add_alt_1_outlined,
            "/dashboard/admin/employees/create",
          ),
          SidebarItem(
            "Employees Management",
            Icons.group_outlined,
            "/dashboard/admin/employees",
          ),
          SidebarItem(
            "Account Master",
            Icons.account_tree_outlined,
            "/dashboard/admin/account/master",
          ),
          SidebarItem(
            "Accounts Master Management",
            Icons.folder_special_outlined, // cleaner than list_alt
            "/dashboard/admin/account/all",
          ),
          SidebarItem(
            "SR Area Allotment",
            Icons.map_outlined, // visually represents allotment/area
            "/dashboard/admin/task-assignment",
          ),
          SidebarItem(
            "Allotments Management",
            Icons
                .route_outlined, // route-based visualization for assigned tasks
            "/dashboard/admin/tasks/view",
          ),
          SidebarItem(
            "SR Customer Allotment",
            Icons.map_outlined, // visually represents allotment/area
            "/dashboard/admin/customer-allotment",
          ),
          SidebarItem(
            "Performance Reports",
            Icons.stacked_line_chart, // great for analytics
            "/dashboard/admin/reports",
          ),
          SidebarItem("Maps", Icons.map_outlined, "/dashboard/admin/map"),
          SidebarItem(
            "Live Tracking",
            Icons.location_searching,
            "/dashboard/admin/tracking",
          ),

          SidebarItem(
            "Attendance Management",
            Icons.add_chart_sharp, // great for analytics
            "/dashboard/admin/attendance",
          ),
          SidebarItem(
            "Leave Requests",
            Icons.event_available,
            "/dashboard/admin/leaves",
          ),
          SidebarItem(
            "Beat Plan Management",
            Icons.route,
            "/dashboard/admin/beat-plans",
          ),
          SidebarItem(
            "Verify Accounts",
            Icons.verified_user_outlined,
            "/dashboard/admin/verify-accounts",
          ),
        ];

      case "employee":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/employee"),
          SidebarItem("Profile", Icons.person, "/dashboard/employee/profile"),
          SidebarItem(
            "Settings",
            Icons.settings,
            "/dashboard/employee/settings",
          ),
        ];
      case "salesman":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/salesman"),
          SidebarItem(
            "Create Account",
            Icons.person_add_outlined,
            "/dashboard/salesman/account/master",
          ),
          SidebarItem(
            "List of Accounts",
            Icons.folder_open_outlined,
            "/dashboard/salesman/accounts",
          ),
          SidebarItem(
            "Area Allotments",
            Icons.map_outlined,
            "/dashboard/salesman/assignments",
          ),
          // SidebarItem(
          //   "Create Expense",
          //   Icons.add_card_outlined,
          //   "/dashboard/salesman/expense/create",
          // ),
          // SidebarItem(
          //   "My Expenses",
          //   Icons.receipt_long_outlined,
          //   "/dashboard/salesman/expense/my",
          // ),
          SidebarItem("Maps", Icons.map_outlined, "/dashboard/salesman/map"),
          SidebarItem("Punch", Icons.map_outlined, "/dashboard/salesman/punch"),
          SidebarItem(
            "Leave Management",
            Icons.event_available,
            "/dashboard/salesman/leaves",
          ),
          SidebarItem(
            "Today's Beat Plan",
            Icons.today,
            "/dashboard/salesman/beat-plan/today",
          ),
        ];

      case "telecaller":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/telecaller"),
          SidebarItem(
            "Account Master",
            Icons.person_add_outlined,
            "/dashboard/telecaller/account/master",
          ),
          SidebarItem(
            "Manage Accounts",
            Icons.manage_accounts_outlined,
            "/dashboard/telecaller/account/all",
          ),
          SidebarItem(
            "Verify Accounts",
            Icons.verified_user_outlined,
            "/dashboard/telecaller/verify-accounts",
          ),
          SidebarItem(
            "Call History",
            Icons.call_outlined,
            "/dashboard/telecaller/call-history",
          ),
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, color),
        drawer: EnterpriseSidebar(
          items: getSidebarMenu(),
          primaryColor: color,
          roleName: roleDisplayName,
          userName: UserService.name,
          userContact: userContactNumber,
          logoPath: logoPath,
          appName: appName,
        ),
        body: _buildBody(context, color, dashCards),
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
          // Icon(roleIcon, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$roleDisplayName Dashboard",
                  style: const TextStyle(fontSize: 18),
                ),
                if (UserService.name != null)
                  Text(
                    UserService.name!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Show notification bell only for admin role
        if (roleName.toLowerCase() == 'admin')
          const NotificationBell(role: 'admin'),
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
  // Body + Cards Grid
  // ------------------------------------------------------------
  Widget _buildBody(
    BuildContext context,
    Color color,
    List<DashboardCard> cards,
  ) {
    // Show custom dashboard for salesman
    if (roleName.toLowerCase() == 'salesman') {
      return const SalesmanDashboardScreen();
    }

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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
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
