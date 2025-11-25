import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';

// Dashboard
import '../screens/dashboard/role_dashboard_template.dart';

// Admin screens
import '../screens/admin/view_users_screen.dart';
import '../screens/admin/create_user_screen.dart';
import '../screens/admin/manage_roles_screen.dart';
import '../screens/admin/schedule_task_screen.dart';
import '../screens/admin/view_tasks_screen.dart';

// Shared screens
import '../screens/shared/account_master_screen.dart';
import '../screens/shared/account_list_screen.dart';
import '../screens/shared/create_expense_screen.dart';
import '../screens/shared/my_expenses_screen.dart';
import '../screens/shared/employee_list_screen.dart';
import '../screens/shared/view_all_masters_screen.dart';

// Guards & Services
import 'auth_guard.dart';
import 'role_guard.dart';
import '../services/user_service.dart';

// GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',

  routes: [
    // ==================== HOME → AUTO ROUTER ====================
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

    // ==================== AUTH ROUTES ====================
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),

    // ==================== DASHBOARD (Protected) ====================
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
    ),

    // ==================== ADMIN ROUTES ====================
    GoRoute(
      path: '/admin/employees',
      redirect: authGuard,
      builder: (context, state) => const AdminViewUsersScreen(),
    ),
    GoRoute(
      path: '/admin/employees/create',
      redirect: authGuard,
      builder: (context, state) => const AdminCreateUserScreen(),
    ),
    GoRoute(
      path: '/admin/roles',
      redirect: authGuard,
      builder: (context, state) => const ManageRolesScreen(),
    ),
    GoRoute(
      path: '/admin/tasks/schedule',
      redirect: authGuard,
      builder: (context, state) => const ScheduleTaskScreen(),
    ),
    GoRoute(
      path: '/admin/tasks/view',
      redirect: authGuard,
      builder: (context, state) => const ViewTasksScreen(),
    ),

    // ==================== ACCOUNT ROUTES ====================
    GoRoute(
      path: '/account/master',
      redirect: authGuard,
      builder: (context, state) => const AccountMasterScreen(),
    ),
    GoRoute(
      path: '/account/all',
      redirect: authGuard,
      builder: (context, state) => const AccountListScreen(),
    ),
    GoRoute(
      path: '/account/masters/all',
      redirect: authGuard,
      builder: (context, state) => const ViewAllMastersScreen(),
    ),

    // ==================== EXPENSE ROUTES ====================
    GoRoute(
      path: '/expense/create',
      redirect: authGuard,
      builder: (context, state) => const CreateExpenseScreen(),
    ),
    GoRoute(
      path: '/expense/my',
      redirect: authGuard,
      builder: (context, state) => const MyExpensesScreen(),
    ),

    // ==================== EMPLOYEE ROUTES ====================
    GoRoute(
      path: '/employees/list',
      redirect: authGuard,
      builder: (context, state) => const EmployeeListScreen(),
    ),
  ],
);
