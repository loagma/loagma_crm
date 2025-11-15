import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/nsm/nsm_dashboard_screen.dart';
import '../screens/rsm/rsm_dashboard_screen.dart';
import '../screens/asm/asm_dashboard_screen.dart';
import '../screens/tso/tso_dashboard_screen.dart';

class RoleRouter {
  static Widget getDashboardForRole(String? role, {String? userContact}) {
    // Normalize role name for comparison
    final normalizedRole = role?.toLowerCase().trim();

    // Check for common role patterns
    if (normalizedRole == null || normalizedRole.isEmpty) {
      return AdminDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      );
    }

    // Match role patterns - handles various role formats
    if (normalizedRole.contains('admin')) {
      return AdminDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      );
    } else if (normalizedRole.contains('nsm') ||
        normalizedRole.contains('national')) {
      return NsmDashboardScreen(userRole: role, userContactNumber: userContact);
    } else if (normalizedRole.contains('rsm') ||
        normalizedRole.contains('regional')) {
      return RsmDashboardScreen(userRole: role, userContactNumber: userContact);
    } else if (normalizedRole.contains('asm') ||
        normalizedRole.contains('area')) {
      return AsmDashboardScreen(userRole: role, userContactNumber: userContact);
    } else if (normalizedRole.contains('tso') ||
        normalizedRole.contains('territory')) {
      return TsoDashboardScreen(userRole: role, userContactNumber: userContact);
    } else if (normalizedRole.contains('salesman')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Salesman uses TSO dashboard
    } else if (normalizedRole.contains('telecaller')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Telecaller uses TSO dashboard
    } else if (normalizedRole.contains('field') ||
        normalizedRole.contains('executive')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Field roles use TSO dashboard
    } else if (normalizedRole.contains('promoter')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Promoter uses TSO dashboard
    } else if (normalizedRole.contains('support')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Support uses TSO dashboard
    } else if (normalizedRole.contains('business') ||
        normalizedRole.contains('developer')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Business Developer uses TSO dashboard
    } else if (normalizedRole.contains('marketing')) {
      return TsoDashboardScreen(
        userRole: role,
        userContactNumber: userContact,
      ); // Marketing uses TSO dashboard
    } else {
      // Default fallback - show role name as-is
      return TsoDashboardScreen(userRole: role, userContactNumber: userContact);
    }
  }

  static void navigateToRoleDashboard(
    BuildContext context,
    String? role, {
    String? userContact,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            getDashboardForRole(role, userContact: userContact),
      ),
    );
  }
}
