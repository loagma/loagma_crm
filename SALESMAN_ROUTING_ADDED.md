# Salesman Routing Added

## Summary
Successfully added proper routing for the Salesman role with dedicated menu items and navigation paths.

## Changes Made

### 1. Updated Role Dashboard Template
**File**: `loagma_crm/lib/screens/dashboard/role_dashboard_template.dart`

Updated salesman sidebar menu items:
- Dashboard → `/dashboard/salesman`
- Account Master → `/dashboard/salesman/account/master`
- Accounts Master Management → `/dashboard/salesman/account/all`
- My Expenses → `/dashboard/salesman/expense/my`
- Create Expense → `/dashboard/salesman/expense/create`

Removed generic profile/settings placeholders and added relevant business features.

### 2. Updated App Router
**File**: `loagma_crm/lib/router/app_router.dart`

Reorganized routes for better clarity:
- **Admin-only routes**: employees, roles, tasks, reports, task-assignment
- **Shared routes**: account/master, account/all, expense/create, expense/my

The shared routes work for both admin and salesman roles using the same path structure.

## Salesman Features

✅ Dashboard home
✅ Create new account masters
✅ View and manage all accounts
✅ Create expense entries
✅ View personal expenses

## How It Works

The routing system uses dynamic role-based paths:
- `/dashboard/salesman` - Main dashboard
- `/dashboard/salesman/account/*` - Account management
- `/dashboard/salesman/expense/*` - Expense management

All routes are protected by auth and role guards.
