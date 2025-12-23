# Design Document

## Overview

This design addresses two critical issues in the punch screen functionality:
1. Duration timer showing 00:00:00 instead of calculating elapsed work time
2. Early punch-out showing generic error dialog instead of proper approval widget

The solution involves fixing the timer calculation logic and ensuring proper widget state management for the early punch-out approval flow.

## Architecture

The punch screen follows a stateful widget pattern with the following key components:
- **Timer Management**: Periodic timer that updates every second to refresh duration display
- **State Management**: Local state tracking punch status, approval codes, and widget visibility
- **Approval Flow**: Conditional widget rendering based on time constraints and approval status

## Components and Interfaces

### Enhanced Punch Screen
- **Duration Calculation**: `liveWorkDuration` getter that calculates time difference
- **Duration Formatting**: `_getCurrentDurationText()` method that formats duration as HH:MM:SS
- **Approval State**: Boolean flags and string variables to track approval status
- **Widget Rendering**: Conditional logic to show appropriate widgets based on state

### Early Punch-Out Approval Widget
- **Approval Status Tracking**: Monitors approval request state (none, pending, approved, rejected)
- **Code Validation**: Validates approval codes and triggers callbacks
- **Auto-refresh**: Periodic status updates to detect approval changes

## Data Models

### Duration Calculation
```dart
Duration get liveWorkDuration {
  if (punchInTime == null) return Duration.zero;
  final now = DateTime.now();
  final diff = now.difference(punchInTime!);
  return diff.isNegative ? Duration.zero : diff;
}
```

### Approval State
```dart
bool isBeforeEarlyPunchOutCutoff = false;
String? validEarlyPunchOutCode;
Map<String, dynamic>? approvalStatus;
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Property 1: Duration calculation accuracy
*For any* punch-in time and current time, the calculated duration should equal the time difference between current time and punch-in time, or zero if negative
**Validates: Requirements 1.2**

Property 2: Duration formatting consistency
*For any* valid duration, the formatted string should follow HH:MM:SS pattern with zero-padded values
**Validates: Requirements 1.3**

Property 3: Widget visibility exclusivity
*For any* early punch-out scenario, either the approval widget or the generic punch-out button should be visible, but never both simultaneously
**Validates: Requirements 2.1, 2.2**

Property 4: Approval code validation behavior
*For any* approval code input, validation should either store the code for punch-out or reject it, but never leave the system in an inconsistent state
**Validates: Requirements 2.6**

Property 5: State management consistency
*For any* approval code validation, the stored code should be cleared on successful punch-out or invalid code errors, but retained for other error types
**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

Property 6: State persistence across refreshes
*For any* approval state, refreshing the screen should maintain the current approval status without losing progress
**Validates: Requirements 3.5**

## Error Handling

### Duration Calculation Errors
- Null punch-in time: Return Duration.zero
- Negative duration: Return Duration.zero
- Timer disposal: Cancel timer to prevent memory leaks

### Approval Flow Errors
- Network failures: Show error message but retain approval state
- Invalid codes: Clear stored code and show validation error
- Widget lifecycle: Properly dispose timers and controllers

## Testing Strategy

### Unit Testing
- Duration calculation with various time inputs
- Duration formatting with edge cases (zero, large values)
- Approval state transitions
- Widget visibility logic

### Property-Based Testing
The testing approach will use Flutter's built-in testing framework along with property-based testing principles:

- **Duration Properties**: Test duration calculation and formatting across random time inputs
- **State Management Properties**: Test approval code storage and cleanup across various scenarios
- **Widget Rendering Properties**: Test conditional widget display logic across different states

### Integration Testing
- Full punch-out flow with approval
- Timer updates during active session
- Screen refresh behavior
- Approval widget callbacks