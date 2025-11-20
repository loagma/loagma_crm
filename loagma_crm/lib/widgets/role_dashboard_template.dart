import 'package:flutter/material.dart';
import '../screens/shared/account_master_screen.dart';
import '../screens/admin/view_users_screen.dart';
import '../screens/admin/create_user_screen.dart';
import '../screens/admin/manage_roles_screen.dart';
import '../screens/view_all_masters_screen.dart';
import '../screens/shared/create_expense_screen.dart';

class RoleDashboardTemplate extends StatelessWidget {
  final String roleName;
  final String roleDisplayName;
  final IconData roleIcon;
  final List<DashboardCard>? cards; // Now optional
  final Color? primaryColor;
  final String? userContactNumber;

  // Customizable sidebar content
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
    this.cards, // Now optional - will auto-generate from menu
    this.primaryColor,
    this.userContactNumber,
    this.logoPath,
    this.logoWidth,
    this.logoHeight,
    this.appName,
    this.appVersion,
  });

  // =========================
  // ROLE-BASED MENU MAP
  // =========================
  List<MenuItem> getRoleMenu(BuildContext context) {
    // Debug: Print the roleName to help troubleshoot
    print('🔍 DEBUG: roleName = "$roleName"');
    print(
      '🔍 DEBUG: Available keys = ${_roleMenuConfig(context).keys.toList()}',
    );

    final menu = _roleMenuConfig(context)[roleName];
    if (menu == null) {
      print('⚠️ WARNING: No menu found for role "$roleName", using DEFAULT');
    }

    return menu ?? _roleMenuConfig(context)["DEFAULT"]!;
  }

  // =========================
  // AUTO-GENERATE DASHBOARD CARDS FROM MENU
  // =========================
  List<DashboardCard> getDashboardCards(BuildContext context) {
    // If cards are manually provided, use them
    if (cards != null && cards!.isNotEmpty) {
      return cards!;
    }

    // Otherwise, auto-generate from menu items (excluding Dashboard item)
    final menuItems = getRoleMenu(context);
    return menuItems
        .where((item) => item.title != "Dashboard") // Skip Dashboard menu item
        .map(
          (item) => DashboardCard(
            title: item.title,
            icon: item.icon,
            onTap: item.onTap,
          ),
        )
        .toList();
  }

  Map<String, List<MenuItem>> _roleMenuConfig(BuildContext context) => {
    // ========== ADMIN MENU ==========
    "admin": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.people_outline,
        title: "Employee Management",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminViewUsersScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.person_add_outlined,
        title: "Create Employee",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCreateUserScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.admin_panel_settings_outlined,
        title: "Manage Roles",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageRolesScreen()),
          );
        },
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.list_alt_outlined,
        title: "View All Accounts",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ViewAllMastersScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.settings_outlined,
        title: "System Settings",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("System Settings - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.analytics_outlined,
        title: "Reports & Analytics",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reports - Coming Soon")),
          );
        },
      ),
    ],

    // ========== SALES MENU ==========
    "sales": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      // MenuItem(
      //   icon: Icons.shopping_cart_outlined,
      //   title: "Orders",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(
      //       context,
      //     ).showSnackBar(const SnackBar(content: Text("Orders - Coming Soon")));
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.inventory_outlined,
      //   title: "Products",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Products - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.bar_chart_outlined,
      //   title: "Sales Reports",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Sales Reports - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.location_on_outlined,
      //   title: "Territory",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Territory - Coming Soon")),
      //     );
      //   },
      // ),
    ],

    // ========== MARKETING MENU ==========
    "marketing": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      // MenuItem(
      //   icon: Icons.campaign_outlined,
      //   title: "Campaigns",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Campaigns - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.email_outlined,
      //   title: "Email Marketing",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Email Marketing - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.trending_up_outlined,
      //   title: "Social Media",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Social Media - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.insights_outlined,
      //   title: "Marketing Analytics",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Marketing Analytics - Coming Soon")),
      //     );
      //   },
      // ),
      // MenuItem(
      //   icon: Icons.content_paste_outlined,
      //   title: "Content Library",
      //   onTap: () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("Content Library - Coming Soon")),
      //     );
      //   },
      // ),
    ],

    // ========== NSM (National Sales Manager) MENU ==========
    "nsm": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.groups_outlined,
        title: "Team Overview",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Team Overview - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.assessment_outlined,
        title: "National Reports",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("National Reports - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.flag_outlined,
        title: "Targets & Goals",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Targets & Goals - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.map_outlined,
        title: "Regional Performance",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Regional Performance - Coming Soon")),
          );
        },
      ),
    ],

    // ========== RSM (Regional Sales Manager) MENU ==========
    "rsm": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.people_alt_outlined,
        title: "My Team",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("My Team - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.location_city_outlined,
        title: "Regional Reports",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Regional Reports - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.track_changes_outlined,
        title: "Performance Tracking",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Performance Tracking - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.store_outlined,
        title: "Territory Management",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Territory Management - Coming Soon")),
          );
        },
      ),
    ],

    // ========== ASM (Area Sales Manager) MENU ==========
    "asm": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.supervisor_account_outlined,
        title: "Field Team",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Field Team - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.place_outlined,
        title: "Area Coverage",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Area Coverage - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.checklist_outlined,
        title: "Daily Activities",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily Activities - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.leaderboard_outlined,
        title: "Area Performance",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Area Performance - Coming Soon")),
          );
        },
      ),
    ],

    // ========== TSO (Territory Sales Officer) MENU ==========
    "tso": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.add_business_outlined,
        title: "New Orders",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New Orders - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.route_outlined,
        title: "My Route",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("My Route - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.check_circle_outline,
        title: "Visit Checklist",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visit Checklist - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.history_outlined,
        title: "Visit History",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visit History - Coming Soon")),
          );
        },
      ),
    ],
    // ========== TELECALLER MENU ==========
    "telecaller": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.account_box_outlined,
        title: "Account Master",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountMasterScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        title: "Submit Expense",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExpenseScreen(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.call_outlined,
        title: "Call Logs",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Call Logs - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.contacts_outlined,
        title: "Lead Management",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lead Management - Coming Soon")),
          );
        },
      ),
      MenuItem(
        icon: Icons.assignment_outlined,
        title: "Call Scripts",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Call Scripts - Coming Soon")),
          );
        },
      ),
    ],
    // ========== DEFAULT FALLBACK ==========
    "DEFAULT": [
      MenuItem(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () => Navigator.pop(context),
      ),
      MenuItem(
        icon: Icons.info_outline,
        title: "Help & Support",
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Help & Support - Coming Soon")),
          );
        },
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFFD7BE69);

    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yes, Exit'),
              ),
            ],
          ),
        );

        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: _buildAppBar(context, color),
        drawer: _buildDrawer(context, color),
        body: _buildBody(context, color),
      ),
    );
  }

  // =========================
  // APP BAR
  // =========================
  AppBar _buildAppBar(BuildContext context, Color color) {
    return AppBar(
      title: Row(
        children: [
          Icon(roleIcon, size: 24),
          const SizedBox(width: 10),
          Text('$roleDisplayName Dashboard'),
        ],
      ),
      backgroundColor: color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to exit the application?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Yes, Exit'),
                ),
              ],
            ),
          );
          if (shouldExit == true && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout cancelled'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // =========================
  // BODY
  // =========================
  Widget _buildBody(BuildContext context, Color color) {
    final dashboardCards = getDashboardCards(context);

    return Column(
      children: [
        _roleHeader(color),
        Expanded(
          child: dashboardCards.isEmpty
              ? _comingSoon()
              : _dashboardGrid(context, color, dashboardCards),
        ),
      ],
    );
  }

  Widget _roleHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(roleIcon, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleDisplayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Welcome to your dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'Dashboard Coming Soon',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Features will be added here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _dashboardGrid(
    BuildContext context,
    Color color,
    List<DashboardCard> dashboardCards,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.1,
        ),
        itemCount: dashboardCards.length,
        itemBuilder: (context, index) {
          final card = dashboardCards[index];
          return _buildDashboardCard(card, color);
        },
      ),
    );
  }

  Widget _buildDashboardCard(DashboardCard card, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: card.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DRAWER (ROLE-BASED)
  // =========================
  Widget _buildDrawer(BuildContext context, Color color) {
    final menuItems = getRoleMenu(context);

    return Drawer(
      child: Column(
        children: [
          _drawerHeader(color),
          const SizedBox(height: 8),

          // DYNAMIC ROLE-BASED MENU
          ...menuItems.map(
            (item) => _buildMenuItem(
              context,
              icon: item.icon,
              title: item.title,
              color: color,
              onTap: item.onTap,
            ),
          ),

          const Spacer(),

          // Logout Button
          _buildMenuItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Logout',
            color: Colors.red,
            onTap: () => _handleLogout(context),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              appVersion ?? 'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.85)]),
      ),
      child: Column(
        children: [
          // Customizable Logo
          Image.asset(
            logoPath ?? 'assets/logo.png',
            width: logoWidth ?? 170,
            height: logoHeight ?? 105,
          ),
          const SizedBox(height: 12),

          // Customizable App Name
          Text(
            appName ?? 'Loagma CRM',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),

          // Role Display Name
          Text(
            roleDisplayName,
            style: TextStyle(color: Colors.white.withOpacity(0.95)),
          ),
          const SizedBox(height: 10),

          // Contact Number Badge
          if (userContactNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    userContactNumber!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
}

// =========================
// DATA MODELS
// =========================
class DashboardCard {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DashboardCard({required this.title, required this.icon, required this.onTap});
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  MenuItem({required this.icon, required this.title, required this.onTap});
}
