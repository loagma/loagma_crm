# Design Document

## Overview

This design addresses critical issues in the late punch-in approval workflow where salesmen cannot complete their punch-in process after receiving admin approval. The current system shows the approval status but doesn't provide a clear path to enter the OTP and complete the punch-in. Additionally, the recent accounts section lacks creation date information, making it difficult for salesmen to track their account creation activity.

The solution involves enhancing the punch screen's approval workflow integration and improving the dashboard's account display with proper timestamp formatting.

## Architecture

The fix involves modifications to three main components:

1. **Enhanced Punch Screen**: Improved integration between the late punch approval widget and the punch-in process
2. **Late Punch Approval Widget**: Enhanced state management and user feedback
3. **Salesman Dashboard**: Improved recent accounts display with creation timestamps

The architecture maintains the existing service layer structure while improving the UI flow and state management between components.

## Components and Interfaces

### Enhanced Punch Screen (`enhanced_punch_screen.dart`)

**Responsibilities:**
- Display appropriate UI based on time and punch status
- Manage approval code validation state
- Integrate approval code with punch-in process
- Handle seamless transition from approval to punch-in

**Key State Variables:**
```dart
String? validApprovalCode;  // Stores validated approval code
bool isAfterCutoff;         // Tracks if current time is after 9:45 AM
bool isPunchedIn;           // Current punch status
```

**Methods:**
- `_handleApprovalCodeValidated()`: Called when approval code is successfully validated
- `_handlePunchIn({String? approvalCode})`: Enhanced to accept approval code parameter
- `_checkCutoffTime()`: Determines if late approval is required

### Late Punch Approval Widget (`late_punch_approval_widget.dart`)

**Enhanced Callbacks:**
```dart
final VoidCallback? onApprovalRequested;
final Function(String)? onApprovalCodeValidated;  // New callback with code
final VoidCallback? onApprovalReceived;
```

**State Management:**
- Maintains approval status with auto-refresh
- Handles code validation and expiration
- Provides clear visual feedback for each state

### Salesman Dashboard (`salesman_dashboard_screen.dart`)

**Recent Accounts Enhancement:**
- Display creation timestamps in appropriate format
- Handle missing timestamp data gracefully
- Update timestamps on refresh

## Data Models

### Approval Status Model
```dart
class ApprovalStatus {
  String status;           // PENDING, APPROVED, REJECTED
  String? approvalCode;    // 6-digit OTP
  DateTime? codeExpiresAt; // Code expiration time
  bool codeUsed;          // Whether code has been used
  bool codeExpired;       // Whether code has expired
  String? adminRemarks;    // Admin comments
  DateTime? approvedAt;    // Approval timestamp
  String? approvedBy;      // Admin who approved
}
```

### Account Display Model
```dart
class AccountDisplayInfo {
  String personName;
  String? businessName;
  String? contactNumber;
  DateTime? createdAt;     // Enhanced with creation timestamp
  bool isApproved;
  String timeAgo;          // Computed relative time string
  String formattedDateTime; // Computed full date string
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Late punch approval widget display
*For any* punch screen state where the current time is after 9:45 AM and the user has not punched in, the late punch approval widget should be displayed
**Validates: Requirements 1.1**

### Property 2: Approval code input visibility
*For any* approval status that is "APPROVED" and not expired or used, the approval code input field should be visible on the punch screen
**Validates: Requirements 1.2**

### Property 3: Code validation triggers punch dialog
*For any* valid approval code entered by the salesman, the system should validate the code and automatically display the punch-in dialog
**Validates: Requirements 1.3**

### Property 4: Approval code inclusion in punch-in
*For any* punch-in request made after approval code validation, the validated approval code should be included in the punch-in API request
**Validates: Requirements 1.4**

### Property 5: Code state management after punch-in
*For any* successful punch-in using an approval code, the code should be marked as used and the component state should be cleared
**Validates: Requirements 1.5**

### Property 6: Account creation date display
*For any* account in the recent accounts list that has a creation timestamp, the system should display the creation date and time
**Validates: Requirements 2.1**

### Property 7: Relative time formatting for recent accounts
*For any* account created less than 24 hours ago, the system should display the time in relative format (e.g., "2h 30m ago")
**Validates: Requirements 2.2**

### Property 8: Full date formatting for older accounts
*For any* account created more than 24 hours ago, the system should display the time in full date format (e.g., "Dec 22, 2024 • 02:30 PM")
**Validates: Requirements 2.3**

### Property 9: State persistence during validation flow
*For any* approval code validation, the validated code should be stored in component state and persist until successfully used or cleared
**Validates: Requirements 3.1**

### Property 10: Automatic code inclusion in punch dialog
*For any* punch-in dialog triggered after code validation, the validated approval code should be automatically included without user re-entry
**Validates: Requirements 3.2**

### Property 11: State cleanup after successful punch-in
*For any* successful punch-in operation using an approval code, the stored approval code should be cleared from component state
**Validates: Requirements 3.3**

### Property 12: Code retention on punch-in failure
*For any* failed punch-in attempt, the validated approval code should remain in component state to allow retry without re-validation
**Validates: Requirements 3.4**

### Property 13: Expired code handling
*For any* approval code that is expired or already used, the system should display an appropriate error message and allow requesting new approval
**Validates: Requirements 3.5**

### Property 14: Approval status UI states
*For any* approval request status (none, pending, approved, rejected), the system should display the appropriate UI state with correct actions available
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

### Property 15: Validation feedback and button state
*For any* successful approval code validation, the system should display a confirmation message and enable the punch-in functionality
**Validates: Requirements 4.5**

## Error Handling

### Approval Code Validation Errors
- **Invalid Code**: Display error message, allow retry
- **Expired Code**: Show expiration message, allow new request
- **Used Code**: Show usage message, allow new request
- **Network Error**: Show retry option with error details

### Punch-In Integration Errors
- **Location Missing**: Prevent punch-in, show location requirement
- **Photo Missing**: Prevent punch-in, show photo requirement
- **API Failure**: Retain approval code, allow retry

### Timestamp Display Errors
- **Missing Creation Date**: Display "Date not available"
- **Invalid Date Format**: Display "Invalid date"
- **Parsing Errors**: Graceful fallback to raw timestamp

## Testing Strategy

### Unit Testing
- Test time formatting functions with various date inputs
- Test approval code validation logic
- Test state management during approval flow
- Test error handling for missing data

### Property-Based Testing
The testing strategy will use Flutter's built-in testing framework along with the `test` package for property-based testing. Each correctness property will be implemented as a property-based test that runs 100 iterations with randomly generated inputs.

**Property Test Configuration:**
- Framework: Flutter Test with `test` package
- Iterations: 100 per property test
- Test Data Generation: Custom generators for approval states, timestamps, and UI conditions

**Property Test Implementation:**
- Each property-based test will be tagged with a comment referencing the design document property
- Tests will use the format: `**Feature: late-punch-approval-fixes, Property {number}: {property_text}**`
- Random data generators will create realistic test scenarios for approval codes, timestamps, and user states

### Integration Testing
- Test complete approval workflow from request to punch-in
- Test dashboard refresh with timestamp updates
- Test error scenarios and recovery flows
- Test UI state transitions during approval process

The dual testing approach ensures both specific edge cases are covered (unit tests) and general correctness is verified across all possible inputs (property tests).