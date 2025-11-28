# Quick Access Button - Add to Your Dashboard

To quickly access the Task Assignment screen, add this button to your dashboard:

## Option 1: Floating Action Button

Add this to your dashboard screen (e.g., `role_dashboard_template.dart`):

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    context.go('/dashboard/admin/task-assignment');
  },
  backgroundColor: const Color(0xFFD7BE69),
  icon: const Icon(Icons.assignment),
  label: const Text('Task Assignment'),
),
```

## Option 2: Card Button in Dashboard

Add this card to your dashboard body:

```dart
Card(
  margin: const EdgeInsets.all(16),
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: InkWell(
    onTap: () {
      context.go('/dashboard/admin/task-assignment');
    },
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD7BE69).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment,
              color: Color(0xFFD7BE69),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Assignment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assign pin-code areas to salesmen',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  ),
)
```

## Option 3: Menu Item in Sidebar

If you have `enterprise_sidebar.dart` or similar, add this menu item:

```dart
ListTile(
  leading: const Icon(Icons.assignment, color: Color(0xFFD7BE69)),
  title: const Text('Task Assignment'),
  subtitle: const Text('Assign areas to salesmen'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    context.go('/dashboard/admin/task-assignment');
  },
)
```

## Option 4: Direct Navigation (For Testing)

Add this temporary button anywhere in your app:

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFD7BE69),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  onPressed: () {
    context.go('/dashboard/admin/task-assignment');
  },
  child: const Text('🚀 Test Task Assignment'),
)
```

---

## 🎯 Where to Add These?

### For Admin Dashboard:
Look for files like:
- `lib/screens/dashboard/role_dashboard_template.dart`
- `lib/screens/admin/admin_dashboard.dart`
- `lib/widgets/enterprise_sidebar.dart`

### Quick Test Location:
Add the button in the `build()` method of your dashboard, inside a `Column` or `ListView`.

---

## 🔗 Direct Route

You can also navigate directly using the route:
```dart
context.go('/dashboard/admin/task-assignment');
```

Or from anywhere in your code:
```dart
Navigator.of(context).pushNamed('/dashboard/admin/task-assignment');
```
