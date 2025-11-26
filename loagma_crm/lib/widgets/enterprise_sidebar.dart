import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EnterpriseSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final Color primaryColor;
  final String roleName;
  final String? userContact;
  final String? appName;
  final String? logoPath;

  const EnterpriseSidebar({
    super.key,
    required this.items,
    required this.primaryColor,
    required this.roleName,
    this.userContact,
    this.appName,
    this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 10,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items.map((item) => _buildTile(context, item)).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            logoPath ?? "assets/logo1.jpeg",
            width: 100,
            height: 60,
          ),
          const SizedBox(height: 8),
          Text(
            appName ?? "Loagma CRM",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            roleName.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (userContact != null)
            Text(
              userContact!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            )
        ],
      ),
    );
  }

  // ---------------- TILE ----------------
  Widget _buildTile(BuildContext context, SidebarItem item) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isActive = currentPath.startsWith(item.route);

    return ListTile(
      leading: Icon(
        item.icon,
        color: isActive ? primaryColor : Colors.grey[700],
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? primaryColor : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer properly
        context.go(item.route); // Navigate cleanly
      },
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  final String route;

  SidebarItem(this.title, this.icon, this.route);
}
