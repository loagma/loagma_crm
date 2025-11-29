import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/no_role_screen.dart';

// Dashboard
import '../screens/dashboard/role_dashboard_template.dart';

// Admin screens
import '../screens/admin/view_users_screen.dart';
import '../screens/admin/create_user_screen.dart';
import '../screens/admin/manage_roles_screen.dart';
import '../screens/admin/schedule_task_screen.dart';
import '../screens/admin/view_tasks_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/unified_task_assignment_screen.dart';

// Shared screens
import '../screens/shared/account_master_screen.dart';
import '../screens/shared/account_list_screen.dart';
import '../screens/shared/account_detail_screen.dart';
import '../screens/shared/create_expense_screen.dart';
import '../screens/shared/my_expenses_screen.dart';
import '../screens/shared/employee_list_screen.dart';

// Guards & Services
import 'auth_guard.dart';
import 'role_guard.dart';
import '../services/user_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',

  routes: [
    // AUTO ROUTER
    GoRoute(
      path: '/',
      redirect: (context, state) {
        if (UserService.isLoggedIn && UserService.currentRole != null) {
          final role = UserService.currentRole!.toLowerCase();
          return '/dashboard/$role';
        }
        return '/login';
      },
    ),

    // AUTH
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
    GoRoute(path: '/no-role', builder: (_, __) => const NoRoleScreen()),

    // DASHBOARD WITH CHILD ROUTES
    GoRoute(
      path: '/dashboard/:role',
      redirect: (context, state) {
        final auth = authGuard(context, state);
        if (auth != null) return auth;
        return roleGuard(context, state);
      },
      builder: (context, state) {
        final role = state.pathParameters['role']!.toLowerCase();
        return RoleDashboardTemplate(
          roleName: role,
          roleDisplayName: role.toUpperCase(),
          roleIcon: Icons.dashboard_customize_outlined,
          userContactNumber: UserService.contactNumber,
        );
      },

      /// ALL ADMIN & SHARED ROUTES NESTED HERE
      routes: [
        GoRoute(
          path: 'employees',
          builder: (_, __) => const AdminViewUsersScreen(),
        ),
        GoRoute(
          path: 'employees/create',
          builder: (_, __) => const AdminCreateUserScreen(),
        ),
        GoRoute(path: 'roles', builder: (_, __) => const ManageRolesScreen()),
        GoRoute(
          path: 'tasks/schedule',
          builder: (_, __) => const ScheduleTaskScreen(),
        ),
        GoRoute(
          path: 'tasks/view',
          builder: (_, __) => const ViewTasksScreen(),
        ),
        GoRoute(path: 'reports', builder: (_, __) => const ReportsScreen()),
        GoRoute(
          path: 'account/master',
          builder: (_, __) => const AccountMasterScreen(),
        ),

        GoRoute(
          path: 'account/all',
          builder: (_, __) => const AccountListScreen(),
        ),
        GoRoute(
          path: 'account/view/:id',
          builder: (context, state) {
            final accountId = state.pathParameters['id']!;
            return AccountDetailScreen(accountId: accountId);
          },
        ),
        GoRoute(
          path: 'expense/create',
          builder: (_, __) => const CreateExpenseScreen(),
        ),
        GoRoute(
          path: 'expense/my',
          builder: (_, __) => const MyExpensesScreen(),
        ),
        GoRoute(
          path: 'employees/list',
          builder: (_, __) => const EmployeeListScreen(),
        ),
        GoRoute(
          path: 'task-assignment',
          builder: (_, __) => const UnifiedTaskAssignmentScreen(),
        ),
      ],
    ),
  ],
);
