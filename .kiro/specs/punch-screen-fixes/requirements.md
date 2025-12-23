# Requirements Document

## Introduction

This specification addresses critical issues in the punch screen functionality where the duration timer is not working correctly and the early punch-out approval flow is showing generic error messages instead of directing users to the proper approval widget.

## Glossary

- **Punch Screen**: The mobile interface where employees record their work start and end times
- **Duration Timer**: A real-time display showing elapsed work time since punch-in
- **Early Punch-Out**: Attempting to end work before the standard 6:30 PM cutoff time
- **Approval Widget**: A specialized UI component that handles approval request workflows
- **Attendance Model**: The data structure representing an employee's work session

## Requirements

### Requirement 1

**User Story:** As an employee, I want to see my current work duration updating in real-time, so that I can track how long I have been working.

#### Acceptance Criteria

1. WHEN an employee is punched in THEN the system SHALL display a live duration timer that updates every second
2. WHEN the duration timer updates THEN the system SHALL calculate the time difference between punch-in time and current time
3. WHEN displaying the duration THEN the system SHALL format it as HH:MM:SS
4. WHEN the punch-in time is null THEN the system SHALL display 00:00:00 as the duration
5. WHEN the calculated duration is negative THEN the system SHALL display 00:00:00 as the duration

### Requirement 2

**User Story:** As an employee, I want to be properly guided through the early punch-out approval process, so that I can request permission to leave work early when needed.

#### Acceptance Criteria

1. WHEN an employee attempts to punch out before 6:30 PM THEN the system SHALL display the early punch-out approval widget
2. WHEN the early punch-out approval widget is displayed THEN the system SHALL hide the generic punch-out button
3. WHEN an employee has not requested approval THEN the system SHALL show the approval request form
4. WHEN an employee has a pending approval THEN the system SHALL show the pending status with auto-refresh
5. WHEN an employee has an approved request THEN the system SHALL show the approval code input form
6. WHEN an employee enters a valid approval code THEN the system SHALL enable the punch-out functionality
7. WHEN an employee has a rejected request THEN the system SHALL show the rejection reason and allow new request submission

### Requirement 3

**User Story:** As an employee, I want the punch screen to properly handle approval state changes, so that I can complete my punch-out process without confusion.

#### Acceptance Criteria

1. WHEN the approval widget validates a code THEN the system SHALL store the validated code for punch-out
2. WHEN punch-out is successful with approval code THEN the system SHALL clear the stored approval code
3. WHEN punch-out fails due to invalid code THEN the system SHALL clear the stored approval code
4. WHEN punch-out fails due to other reasons THEN the system SHALL retain the stored approval code for retry
5. WHEN the screen refreshes THEN the system SHALL maintain the current approval state