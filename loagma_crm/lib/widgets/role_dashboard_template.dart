import 'package:flutter/material.dart';
import '../screens/shared/account_master_screen.dart';

class RoleDashboardTemplate extends StatelessWidget {
  final String roleName;
  final String roleDisplayName;
  final IconData roleIcon;
  final List<DashboardCard> cards;
  final Color? primaryColor;
  final String? userContactNumber;

  const RoleDashboardTemplate({
    super.key,
    required this.roleName,
    required this.roleDisplayName,
    required this.roleIcon,
    required this.cards,
    this.primaryColor,
    this.userContactNumber,
  });

  // =========================
  // ROLE-BASED MENU MAP
  // =========================
  List<MenuItem> getRoleMenu(BuildContext context) {
    return _roleMenuConfig(context)[roleName] ??
        _roleMenuConfig(context)["DEFAULT"]!;
  }

  Map<String, List<MenuItem>> _roleMenuConfig(BuildContext context) => {
        "ADMIN": [
          MenuItem(
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            onTap: () => Navigator.pop(context),
          ),
          MenuItem(
            icon: Icons.badge_outlined,
            title: "Employee Master",
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Employee Master - Coming Soon")),
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
                    builder: (context) => const AccountMasterScreen()),
              );
            },
          ),
        ],

        "SALES": [
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
                    builder: (context) => const AccountMasterScreen()),
              );
            },
          ),
        ],

        "MARKETING": [
          MenuItem(
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            onTap: () => Navigator.pop(context),
          ),
        ],

        // fallback
        "DEFAULT": [
          MenuItem(
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            onTap: () => Navigator.pop(context),
          ),
        ],
      };

  // =========================
  // EXIT HANDLER
  // =========================
  Future<bool> _onWillPop(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to go back to login?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFFD7BE69);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
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
    return Column(
      children: [
        _roleHeader(color),
        Expanded(
          child: cards.isEmpty
              ? _comingSoon()
              : _dashboardGrid(context, color),
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
                fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
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

  Widget _dashboardGrid(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.1,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
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
                  fontSize: 14, fontWeight: FontWeight.bold),
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
          ...menuItems.map((item) =>
              _buildMenuItem(context, icon: item.icon, title: item.title, color: color, onTap: item.onTap)),

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
              'Version 1.0.0',
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
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/logo.png', width: 170, height: 105),
          const SizedBox(height: 12),
          const Text(
            'Loagma CRM',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            roleDisplayName,
            style: TextStyle(color: Colors.white.withOpacity(0.95)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  userContactNumber ?? 'No Contact',
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

  DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
