# Auto-Generate Dashboard Cards from Sidebar Menu

## What Changed

### The Problem
Previously, you had to manually define dashboard cards in each role's dashboard screen, which meant maintaining the same menu items in two places:
1. Sidebar menu in `role_dashboard_template.dart`
2. Dashboard cards in each `*_dashboard_screen.dart` file

This was redundant and error-prone.

### The Solution
Now dashboard cards are **automatically generated** from the sidebar menu items! 

## How It Works

### 1. Template Changes (`role_dashboard_template.dart`)

**Made `cards` parameter optional:**
```dart
final List<DashboardCard>? cards; // Now optional
```

**Added auto-generation method:**
```dart
List<DashboardCard> getDashboardCards(BuildContext context) {
  // If cards are manually provided, use them
  if (cards != null && cards!.isNotEmpty) {
    return cards!;
  }
  
  // Otherwise, auto-generate from menu items (excluding Dashboard item)
  final menuItems = getRoleMenu(context);
  return menuItems
      .where((item) => item.title != "Dashboard") // Skip Dashboard menu item
      .map((item) => DashboardCard(
            title: item.title,
            icon: item.icon,
            onTap: item.onTap,
          ))
      .toList();
}
```

### 2. Dashboard Screen Changes

**Before (Manual):**
```dart
return RoleDashboardTemplate(
  roleName: 'admin',
  roleDisplayName: userRole ?? 'Administrator',
  roleIcon: Icons.admin_panel_settings,
  cards: [
    DashboardCard(title: 'User Management', icon: Icons.people_outline, onTap: ...),
    DashboardCard(title: 'Create User', icon: Icons.person_add_outlined, onTap: ...),
    // ... many more cards
  ],
);
```

**After (Auto-generated):**
```dart
return RoleDashboardTemplate(
  roleName: 'admin',
  roleDisplayName: userRole ?? 'Administrator',
  roleIcon: Icons.admin_panel_settings,
  // Cards will be auto-generated from sidebar menu
);
```

## Benefits

✅ **Single Source of Truth**: Define menu items once in the template, they appear in both sidebar AND dashboard cards

✅ **Less Code**: Dashboard screens are now much simpler (5-10 lines instead of 50+)

✅ **Consistency**: Sidebar and dashboard cards are always in sync

✅ **Easy Maintenance**: Add/remove/modify menu items in one place, changes reflect everywhere

✅ **Flexible**: You can still manually provide cards if needed for special cases

## What Gets Auto-Generated

For each role, the sidebar menu items (except "Dashboard") automatically become dashboard cards:

### Admin Role
- User Management
- Create User
- Manage Roles
- Account Master
- System Settings
- Reports & Analytics

### NSM Role
- Account Master
- Team Overview
- National Reports
- Targets & Goals
- Regional Performance

### RSM Role
- Account Master
- My Team
- Regional Reports
- Performance Tracking
- Territory Management

### ASM Role
- Account Master
- Field Team
- Area Coverage
- Daily Activities
- Area Performance

### TSO Role
- Account Master
- New Orders
- My Route
- Visit Checklist
- Visit History

## How to Add New Features

To add a new feature to any role:

1. **Open** `role_dashboard_template.dart`
2. **Find** the role's menu in `_roleMenuConfig()`
3. **Add** a new `MenuItem` with icon, title, and onTap action
4. **Done!** It will automatically appear in both sidebar and dashboard cards

Example:
```dart
"admin": [
  // ... existing items ...
  MenuItem(
    icon: Icons.new_feature_icon,
    title: "New Feature",
    onTap: () {
      Navigator.pop(context);
      // Navigate to new feature screen
    },
  ),
],
```

## Testing

Run your app and verify:
1. ✅ Each role shows dashboard cards matching their sidebar menu
2. ✅ Clicking a card performs the same action as clicking the sidebar item
3. ✅ Icons and titles match between sidebar and cards
4. ✅ "Dashboard" menu item doesn't appear as a card (only in sidebar)
