# Account Form Improvements

## Changes Made

### 1. Enhanced Success Toast with Custom Duration
**File**: `loagma_crm/lib/utils/custom_toast.dart`

- Added optional `duration` parameter to `showSuccess()` method
- Default duration: 2 seconds
- Can now specify custom duration (e.g., 5 seconds)

```dart
CustomToast.showSuccess(
  context,
  "✅ Account Master Created Successfully!",
  duration: 5, // 5 seconds
);
```

### 2. Account Master Create Screen
**File**: `loagma_crm/lib/screens/shared/account_master_screen.dart`

**Changes**:
- Shows success toast for 5 seconds with redirect message
- Automatically redirects to dashboard after 5 seconds
- Smooth navigation using `context.go()`
- Respects user role (admin/salesman) for correct dashboard route

**Flow**:
1. User submits form
2. Account is created successfully
3. Toast appears: "✅ Account Master Created Successfully! Redirecting to dashboard..."
4. Toast displays for 5 seconds
5. Automatically navigates to user's dashboard (`/dashboard/salesman` or `/dashboard/admin`)

### 3. Account Master Edit Screen
**File**: `loagma_crm/lib/screens/shared/edit_account_master_screen.dart`

**Changes**:
- Added `go_router` and `user_service` imports
- Shows success toast for 5 seconds with redirect message
- Automatically redirects to dashboard after 5 seconds
- Smooth navigation using `context.go()`

**Flow**:
1. User submits edit form
2. Account is updated successfully
3. Toast appears: "✅ Account Master Updated Successfully! Redirecting to dashboard..."
4. Toast displays for 5 seconds
5. Automatically navigates to user's dashboard

## Benefits

✅ **Better User Experience**: Users see confirmation for 5 seconds before redirect
✅ **Smooth Navigation**: Uses GoRouter for clean navigation
✅ **Role-Aware**: Redirects to correct dashboard based on user role
✅ **Consistent Behavior**: Both create and edit forms work the same way
✅ **No Manual Navigation**: Users don't need to click back button

## Testing

### Test Create Flow:
1. Go to Account Master create form
2. Fill in all required fields
3. Submit the form
4. Verify toast appears for 5 seconds
5. Verify automatic redirect to dashboard

### Test Edit Flow:
1. Go to an existing account
2. Click Edit
3. Make changes
4. Submit the form
5. Verify toast appears for 5 seconds
6. Verify automatic redirect to dashboard

## Technical Details

- **Toast Duration**: Configurable via `duration` parameter
- **Navigation Method**: `context.go()` from GoRouter
- **User Role Detection**: `UserService.currentRole?.toLowerCase()`
- **Default Role**: Falls back to 'salesman' if role not found
