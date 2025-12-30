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
import '../screens/admin/enhanced_salesman_reports_screen.dart';
import '../screens/admin/modern_task_assignment_screen.dart';
import '../screens/admin/enhanced_attendance_management_screen.dart';
import '../screens/admin/approval_requests_screen.dart';

// Shared screens
import '../screens/shared/account_master_screen.dart';
import '../screens/shared/account_list_screen.dart';
import '../screens/shared/account_detail_screen.dart';
import '../screens/shared/create_expense_screen.dart';
import '../screens/shared/my_expenses_screen.dart';
import '../screens/shared/employee_list_screen.dart';

// Salesman screens
import '../screens/salesman/salesman_accounts_screen.dart';
import '../screens/salesman/salesman_assignments_screen.dart';
import '../screens/salesman/salesman_map_screen.dart';
import '../screens/salesman/enhanced_punch_screen.dart';
import '../screens/salesman/leave_management_screen.dart';
import '../screens/salesman/apply_leave_screen.dart';
import '../screens/salesman/apply_leave_screen_test.dart';
import '../screens/salesman/my_leave_status_screen.dart';

// Admin screens - Leave Management
import '../screens/admin/leave_requests_screen.dart';

// Beat Planning screens
import '../screens/admin/beat_plan_management_screen.dart';
import '../screens/admin/generate_beat_plan_screen.dart';
import '../screens/admin/beat_plan_details_screen.dart';
import '../screens/salesman/todays_beat_plan_screen.dart';

// Telecaller screens
import '../screens/telecaller/verify_account_master_screen.dart';

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
        if (UserService.hasValidAuth && UserService.currentRole != null) {
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

        // For salesman, show custom dashboard with stats
        if (role == 'salesman') {
          return RoleDashboardTemplate(
            roleName: role,
            roleDisplayName: role.toUpperCase(),
            roleIcon: Icons.dashboard_customize_outlined,
            userContactNumber: UserService.contactNumber,
            cards: [
              DashboardCard(
                title: 'Dashboard',
                icon: Icons.dashboard,
                onTap: () {}, // Already on dashboard
              ),
            ],
          );
        }

        return RoleDashboardTemplate(
          roleName: role,
          roleDisplayName: role.toUpperCase(),
          roleIcon: Icons.dashboard_customize_outlined,
          userContactNumber: UserService.contactNumber,
        );
      },

      /// ALL ADMIN, SALESMAN & SHARED ROUTES NESTED HERE
      routes: [
        // Admin-only routes
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
        GoRoute(
          path: 'reports',
          builder: (_, __) => const EnhancedSalesmanReportsScreen(),
        ),
        GoRoute(
          path: 'legacy-reports',
          builder: (_, __) => const ReportsScreen(),
        ),
        GoRoute(
          path: 'task-assignment',
          builder: (_, __) => const ModernTaskAssignmentScreen(),
        ),
        GoRoute(
          path: 'employees/list',
          builder: (_, __) => const EmployeeListScreen(),
        ),
        GoRoute(
          path: 'attendance',
          builder: (_, __) => const EnhancedAttendanceManagementScreen(),
        ),
        GoRoute(
          path: 'approvals',
          builder: (_, __) => const ApprovalRequestsScreen(),
        ),
        GoRoute(
          path: 'leaves',
          builder: (_, __) => const LeaveRequestsScreen(),
        ),

        // Beat Planning routes (Admin)
        GoRoute(
          path: 'beat-plans',
          builder: (_, __) => const BeatPlanManagementScreen(),
        ),
        GoRoute(
          path: 'beat-plans/generate',
          builder: (_, __) => const GenerateBeatPlanScreen(),
        ),
        GoRoute(
          path: 'beat-plans/:id',
          builder: (context, state) {
            final beatPlanId = state.pathParameters['id']!;
            return BeatPlanDetailsScreen(beatPlanId: beatPlanId);
          },
        ),

        // Shared routes (Admin, Salesman, etc.)
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

        // Salesman-specific routes
        GoRoute(
          path: 'accounts',
          builder: (_, __) => const SalesmanAccountsScreen(),
        ),
        GoRoute(
          path: 'assignments',
          builder: (_, __) => const SalesmanAssignmentsScreen(),
        ),
        GoRoute(path: 'map', builder: (_, __) => const SalesmanMapScreen()),
        GoRoute(path: 'punch', builder: (_, __) => const EnhancedPunchScreen()),
        GoRoute(
          path: 'leaves',
          builder: (_, __) => const LeaveManagementScreen(),
        ),
        GoRoute(
          path: 'leaves/apply',
          builder: (_, __) => const ApplyLeaveScreen(),
        ),
        GoRoute(
          path: 'leaves/status',
          builder: (_, __) => const MyLeaveStatusScreen(),
        ),

        // Beat Planning routes (Salesman)
        GoRoute(
          path: 'beat-plan/today',
          builder: (_, __) => const TodaysBeatPlanScreen(),
        ),

        // Telecaller-specific routes
        GoRoute(
          path: 'verify-accounts',
          builder: (_, __) => const VerifyAccountMasterScreen(),
        ),
        GoRoute(
          path: 'call-history',
          builder: (_, __) => Scaffold(
            appBar: AppBar(
              title: const Text('Call History'),
              backgroundColor: const Color(0xFFD7BE69),
            ),
            body: const Center(
              child: Text(
                'Call History - Coming Soon!',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);
