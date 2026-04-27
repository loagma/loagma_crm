import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/attendance_session_manager.dart';
import '../../models/attendance_model.dart';
import '../../widgets/enterprise_sidebar.dart';
import '../../widgets/compact_attendance_widget.dart';
import '../../widgets/notification_bell.dart';
import '../salesman/salesman_dashboard_screen.dart';
import '../manager/manager_dashboard_screen.dart';

class RoleDashboardTemplate extends StatefulWidget {
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

  @override
  State<RoleDashboardTemplate> createState() => _RoleDashboardTemplateState();
}

class _RoleDashboardTemplateState extends State<RoleDashboardTemplate> {
  AttendanceModel? todayAttendance;
  bool isLoadingAttendance = false;

  @override
  void initState() {
    super.initState();
    // Load attendance only for salesman
    if (widget.roleName.toLowerCase() == 'salesman') {
      _loadTodayAttendance();
    }
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => isLoadingAttendance = true);

    try {
      if (!UserService.hasValidAuth) {
        print('❌ User authentication invalid - skipping attendance load');
        return;
      }

      final employeeId = UserService.currentUserId;
      if (employeeId == null) return;

      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (mounted) {
        setState(() {
          todayAttendance = attendance;
        });

        // Bootstrap live tracking
        await AttendanceSessionManager.ensureTrackingForActiveSession(context);
      }
    } catch (e) {
      print('Error loading attendance: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingAttendance = false);
      }
    }
  }

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
    // Normalize role: "tele admin" / "Tele Admin" -> "teleadmin" for matching
    final roleKey = widget.roleName.toLowerCase().replaceAll(' ', '');
    switch (roleKey) {
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
            "Area Assignment (Pincode)",
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
            "Weekly Beat Plan",
            Icons.calendar_view_week,
            "/dashboard/admin/beat-plans/select-accounts",
          ),
          // SidebarItem(
          //   "Existing Beat Plans",
          //   Icons.route,
          //   "/dashboard/admin/beat-plans",
          // ),
          SidebarItem(
            "Verify Accounts",
            Icons.verified_user_outlined,
            "/dashboard/admin/verify-accounts",
          ),
          SidebarItem(
            "SR Customer List",
            Icons.people_outline,
            "/dashboard/admin/customers",
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
            "Allotted Customers",
            Icons.people_alt_outlined,
            "/dashboard/salesman/customer-allotment",
          ),
          // SidebarItem(
          //   "Area Allotments",
          //   Icons.map_outlined,
          //   "/dashboard/salesman/assignments",
          // ),
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
          SidebarItem(
            "All Beat Plan",
            Icons.today,
            "/dashboard/salesman/beat-plan/all",
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
            "To Verify Accounts",
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
          SidebarItem(
            "Follow up Management",
            Icons.follow_the_signs_sharp,
            "/dashboard/telecaller/follow-up",
          ),
          SidebarItem(
            "Allotted Customers",
            Icons.people_alt_outlined,
            "/dashboard/telecaller/customer-allotment",
          ),
        ];

      case "manager":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/manager"),
          SidebarItem(
            "Reminder Calls",
            Icons.phone_callback_outlined,
            "/dashboard/manager/reminder-calls",
          ),
          SidebarItem(
            "Create Task",
            Icons.task_alt_outlined,
            "/dashboard/manager/create-task",
          ),
          SidebarItem(
            "View Accounts",
            Icons.people_outline,
            "/dashboard/manager/account/all",
          ),
        ];
      case "teleadmin":
        return [
          SidebarItem("Dashboard", Icons.dashboard, "/dashboard/teleadmin"),

          SidebarItem(
            "Accounts Master Management",
            Icons.route_outlined,
            "/dashboard/teleadmin/account/all",
          ),
          // SidebarItem(
          //   "Assign Account",
          //   Icons.route_outlined,
          //   "/dashboard/teleadmin/assign",
          // ),
          SidebarItem(
            "Verify Accounts",
            Icons.verified_user_outlined,
            "/dashboard/teleadmin/verify-accounts",
          ),
        ];

      default:
        return [
          SidebarItem(
            "Dashboard",
            Icons.dashboard,
            "/dashboard/${widget.roleName}",
          ),
        ];
    }
  }

  List<DashboardCard> getDashCards(BuildContext context) {
    if (widget.cards != null && widget.cards!.isNotEmpty) return widget.cards!;

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
    final color = widget.primaryColor ?? const Color(0xFFD7BE69);
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
        drawer: _buildDrawer(context, color),
        body: _buildBody(context, color, dashCards),
      ),
    );
  }

  // Build drawer with attendance widget for salesman
  Widget _buildDrawer(BuildContext context, Color color) {
    print('🔍 Building drawer for role: ${widget.roleName}');
    print('🔍 Today attendance: $todayAttendance');

    // Always show attendance widget for salesman (no conditions)
    Widget? attendanceWidget;
    if (widget.roleName.toLowerCase() == 'salesman') {
      print('✅ Creating CompactAttendanceWidget for salesman');
      attendanceWidget = CompactAttendanceWidget(
        attendance: todayAttendance,
        showLiveLocation: true,
        onTap: () {
          Navigator.pop(context); // Close drawer
          context.go('/dashboard/salesman/punch');
        },
      );
    } else {
      print('❌ Not salesman role, skipping attendance widget');
    }

    print(
      '🔍 Attendance widget is: ${attendanceWidget != null ? "NOT NULL" : "NULL"}',
    );

    return EnterpriseSidebar(
      items: getSidebarMenu(),
      primaryColor: color,
      roleName: widget.roleDisplayName,
      userName: UserService.name,
      userContact: widget.userContactNumber,
      logoPath: widget.logoPath,
      appName: widget.appName,
      attendanceWidget: attendanceWidget,
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
                  "${widget.roleDisplayName} Dashboard",
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
        // Show notification bell for admin and manager
        if (widget.roleName.toLowerCase() == 'admin')
          const NotificationBell(role: 'admin'),
        if (widget.roleName.toLowerCase() == 'manager')
          const NotificationBell(role: 'manager'),
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
    if (widget.roleName.toLowerCase() == 'salesman') {
      return const SalesmanDashboardScreen();
    }
    // Show custom dashboard for manager
    if (widget.roleName.toLowerCase() == 'manager') {
      return const ManagerDashboardScreen();
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
