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
import '../screens/manager/manager_reminder_calls_screen.dart';
import '../screens/admin/enhanced_attendance_management_screen.dart';
import '../screens/admin/approval_requests_screen.dart';
import '../screens/admin/socket_live_tracking_screen.dart';

// Shared screens (account_list_screen with prefix to avoid clash with teleadmin AccountListScreen)
import '../screens/shared/account_master_screen.dart';
import '../screens/shared/account_list_screen.dart' as shared;
import '../screens/shared/account_detail_screen.dart';
import '../screens/shared/create_expense_screen.dart';
import '../screens/shared/my_expenses_screen.dart';
import '../screens/shared/employee_list_screen.dart';

// Salesman screens
import '../screens/salesman/salesman_accounts_screen.dart';
import '../screens/salesman/salesman_assignments_screen.dart';
import '../screens/salesman/salesman_customer_allotment_screen.dart';
import '../screens/salesman/salesman_map_screen.dart';
import '../screens/salesman/enhanced_punch_screen.dart';
import '../screens/salesman/leave_management_screen.dart';
import '../screens/salesman/apply_leave_screen.dart';
import '../screens/salesman/my_leave_status_screen.dart';
import '../screens/salesman/today_planned_accounts_screen.dart';
import '../screens/salesman/multi_visit_accounts_screen.dart';

// Admin Map screen
import '../screens/admin/map_view_screen.dart';

// Admin screens - Leave Management
import '../screens/admin/leave_requests_screen.dart';

// Beat Planning screens
import '../screens/admin/salesman_allotment_screen.dart';
import '../screens/admin/beat_plan_management_screen.dart';
import '../screens/admin/generate_beat_plan_screen.dart';
import '../screens/admin/beat_plan_details_screen.dart';
import '../screens/salesman/todays_beat_plan_screen.dart';

// Telecaller screens
import '../screens/telecaller/verify_account_master_screen.dart';
import '../screens/telecaller/telecaller_followup_screen.dart';
import '../screens/telecaller/telecaller_call_history_screen.dart';
import '../screens/telecaller/telecaller_assigned_pincodes_screen.dart';

// Teleadmin screens (alias to avoid clash with shared AccountListScreen)
import '../screens/teleadmin/account_list_ta.dart' as teleadmin;
import '../screens/teleadmin/assign_account_screen.dart';


    // Edit Account Master Screen
import '../screens/shared/edit_account_master_screen.dart';
import '../services/account_service.dart';
import '../models/account_model.dart';

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

    // ACCOUNT DETAIL (accessible from anywhere)
    GoRoute(
      path: '/account/:id',
      builder: (context, state) {
        final accountId = state.pathParameters['id']!;
        return AccountDetailScreen(accountId: accountId);
      },
    ),

    // ACCOUNT EDIT (accessible from anywhere)
    GoRoute(
      path: '/account/edit/:id',
      builder: (context, state) {
        final accountId = state.pathParameters['id']!;
        return _EditAccountWrapper(accountId: accountId);
      },
    ),

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

        // For manager, show custom dashboard with Reminder Calls first
        if (role == 'manager') {
          return RoleDashboardTemplate(
            roleName: role,
            roleDisplayName: 'Manager',
            roleIcon: Icons.manage_accounts_outlined,
            userContactNumber: UserService.contactNumber,
            primaryColor: const Color(0xFFD7BE69),
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
        // Manager routes
        GoRoute(
          path: 'reminder-calls',
          builder: (_, __) => const ManagerReminderCallsScreen(),
        ),
        GoRoute(
          path: 'create-task',
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
        GoRoute(
          path: 'tracking',
          builder: (_, __) => const SocketLiveTrackingScreen(),
        ),

        // Salesman Allotment (Admin) - shows salesman ↔ customers
        GoRoute(
          path: 'salesman-allotment',
          builder: (_, __) => const SalesmanAllotmentScreen(),
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
          path: 'beat-plans/select-accounts',
          builder: (_, __) => const shared.AccountListScreen(
            forBeatPlan: true,
            appBarTitle: 'Beat Plan – Select accounts',
          ),
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
          builder: (context, state) {
            final role = state.pathParameters['role']?.toLowerCase();
            if (role == 'teleadmin') {
              return const teleadmin.AccountListScreen();
            }
            return const shared.AccountListScreen();
          },
        ),
        GoRoute(
          path: 'assign',
          builder: (context, state) => const AssignAccountScreen(),
        ),
        // Admin "Customer List" – shows only telecaller‑approved accounts
        GoRoute(
          path: 'customers',
          builder: (_, __) => const shared.AccountListScreen(
            onlyApproved: true,
            appBarTitle: 'SR Customer List',
          ),
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
          path: 'customer-allotment',
          builder: (_, __) => const SalesmanCustomerAllotmentScreen(),
        ),
        GoRoute(
          path: 'assignments',
          builder: (_, __) => const SalesmanAssignmentsScreen(),
        ),
        GoRoute(
          path: 'map',
          builder: (context, state) {
            final role = state.pathParameters['role']?.toLowerCase();
            if (role == 'admin') {
              return const AdminEnhancedMapScreen();
            }
            return const SalesmanMapScreen();
          },
        ),
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
        GoRoute(
          path: 'planning/today',
          builder: (_, __) => const TodayPlannedAccountsScreen(),
        ),
        GoRoute(
          path: 'planning/multi-visit',
          builder: (_, __) => const MultiVisitAccountsScreen(),
        ),

        // Telecaller-specific routes
        GoRoute(
          path: 'verify-accounts',
          builder: (_, __) => const VerifyAccountMasterScreen(),
        ),
        GoRoute(
          path: 'call-history',
          builder: (_, __) => const TelecallerCallHistoryScreen(),
        ),
        GoRoute(
          path: 'follow-up',
          builder: (_, __) => const TelecallerFollowupScreen(),
        ),
        GoRoute(
          path: 'assigned-pincodes',
          builder: (_, __) => const TelecallerAssignedPincodesScreen(),
        ),
      ],
    ),
  ],
);

// Wrapper widget to load account data for editing
class _EditAccountWrapper extends StatefulWidget {
  final String accountId;

  const _EditAccountWrapper({required this.accountId});

  @override
  State<_EditAccountWrapper> createState() => _EditAccountWrapperState();
}

class _EditAccountWrapperState extends State<_EditAccountWrapper> {
  Account? account;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final loadedAccount = await AccountService.fetchAccountById(
        widget.accountId,
      );
      if (mounted) {
        setState(() {
          account = loadedAccount;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Account...'),
          backgroundColor: const Color(0xFFD7BE69),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFFD7BE69),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (account == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Not Found'),
          backgroundColor: const Color(0xFFD7BE69),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Account not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return EditAccountMasterScreen(account: account!);
  }
}
