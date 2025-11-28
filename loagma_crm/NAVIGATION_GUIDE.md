# Navigation Guide - Task Assignment Module

## Quick Access

### From Code (Programmatic Navigation)

```dart
// Using go_router context extension
context.go('/dashboard/admin/task-assignment');

// Or using push
context.push('/dashboard/admin/task-assignment');
```

### From Dashboard

Add a navigation button/menu item in your dashboard:

```dart
ListTile(
  leading: Icon(Icons.assignment, color: Color(0xFFD7BE69)),
  title: Text('Task Assignment'),
  onTap: () {
    context.go('/dashboard/admin/task-assignment');
  },
)
```

### Example: Add to Sidebar

If you have a sidebar menu (like `enterprise_sidebar.dart`), add:

```dart
{
  'icon': Icons.assignment,
  'title': 'Task Assignment',
  'route': '/dashboard/admin/task-assignment',
}
```

## Route Structure

```
/dashboard/:role/task-assignment
```

- `:role` - Dynamic parameter (e.g., 'admin', 'manager')
- Works with existing role-based routing
- Follows the same pattern as other admin routes

## Testing the Route

### Method 1: Direct URL (Web)
```
http://localhost:port/#/dashboard/admin/task-assignment
```

### Method 2: From Flutter DevTools
1. Open Flutter DevTools
2. Navigate to the widget inspector
3. Use the navigation panel to test routes

### Method 3: Add Test Button
Add a temporary button in your dashboard:

```dart
ElevatedButton(
  onPressed: () => context.go('/dashboard/admin/task-assignment'),
  child: Text('Test Task Assignment'),
)
```

## Integration with Existing Navigation

The route is already integrated into `app_router.dart` as a child route of `/dashboard/:role`, so it:

- ✅ Respects authentication guards
- ✅ Respects role-based access control
- ✅ Maintains navigation history
- ✅ Works with back button
- ✅ Compatible with deep linking

## Example: Full Navigation Flow

```dart
// 1. User logs in
context.go('/login');

// 2. After successful login, redirect to dashboard
context.go('/dashboard/admin');

// 3. Navigate to task assignment
context.go('/dashboard/admin/task-assignment');

// 4. Back to dashboard
context.go('/dashboard/admin');
```

## Access Control

The route inherits access control from the parent `/dashboard/:role` route:

```dart
redirect: (context, state) {
  final auth = authGuard(context, state);
  if (auth != null) return auth;
  return roleGuard(context, state);
}
```

This means:
- User must be logged in
- User must have appropriate role permissions
- Automatic redirect to login if not authenticated

---

**Note**: To make the feature easily accessible, consider adding a menu item in your main navigation/sidebar.
