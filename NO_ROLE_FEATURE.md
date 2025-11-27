# No Role Assigned Feature

## Overview
When a user logs in but doesn't have a role assigned, they will be redirected to a dedicated screen that informs them to contact their administrator.

## Implementation

### 1. New Screen Created
- **File**: `loagma_crm/lib/screens/auth/no_role_screen.dart`
- **Purpose**: Display a user-friendly message when role is not assigned
- **Features**:
  - Warning icon with clear messaging
  - Contact administrator instructions
  - Logout button to return to login screen

### 2. Navigation Flow Updated
- **OTP Screen**: After successful OTP verification, checks if user has a role
  - If role exists → Navigate to dashboard
  - If role is missing → Navigate to `/no-role` screen

### 3. Route Guard Enhanced
- **Auth Guard**: Added role check to prevent access to protected routes
  - Users without roles are automatically redirected to `/no-role`
  - `/no-role` route is added to public routes list

### 4. Router Configuration
- **New Route**: `/no-role` added to `app_router.dart`
- **Import**: `no_role_screen.dart` imported in router

## User Experience

### When User Has No Role:
1. User enters phone number and receives OTP
2. User verifies OTP successfully
3. System detects missing role
4. User is redirected to "Role Not Assigned" screen
5. User sees clear message to contact administrator
6. User can logout and try again later

### Admin Action Required:
Administrators can assign roles to users through:
- Admin Dashboard → Employees → Edit User
- Update the `roleId` field for the user
- User can then login successfully

## Backend Support
The backend already returns role information in the verify OTP response:
```json
{
  "success": true,
  "data": {
    "role": "admin" // or null if not assigned
  }
}
```

## Testing
To test this feature:
1. Create a user without assigning a role
2. Login with that user's phone number
3. Verify OTP
4. Should see "Role Not Assigned" screen
5. Admin assigns role to the user
6. User logs in again
7. Should successfully access dashboard
