# Requirements Document

## Introduction

This document outlines the requirements for fixing the late punch-in approval workflow in the salesman dashboard. Currently, when an admin approves a late punch-in request and sends an OTP, the salesman cannot see where to enter the OTP or complete the punch-in process. Additionally, the recent accounts section needs to display the creation date for each account.

## Glossary

- **Salesman**: An employee who creates accounts and needs to punch in/out for attendance
- **Admin**: A user with administrative privileges who can approve/reject late punch-in requests
- **OTP**: One-Time Password - a 6-digit code sent to the salesman after admin approval
- **Late Punch-In**: A punch-in attempt made after the 9:45 AM cutoff time
- **Approval Code**: The OTP code that must be validated before allowing late punch-in
- **Recent Accounts**: A list of recently created accounts displayed on the salesman dashboard
- **Punch Screen**: The screen where salesmen can punch in/out for attendance tracking

## Requirements

### Requirement 1

**User Story:** As a salesman, I want to see the approval status and enter the OTP code on the punch screen, so that I can complete my late punch-in after admin approval.

#### Acceptance Criteria

1. WHEN a salesman navigates to the punch screen after 9:45 AM AND has not yet punched in, THEN the system SHALL display the late punch approval widget
2. WHEN the admin approves the late punch-in request, THEN the system SHALL display an input field for the approval code on the punch screen
3. WHEN the salesman enters a valid approval code, THEN the system SHALL validate the code and automatically trigger the punch-in dialog
4. WHEN the salesman completes the punch-in dialog with photo and bike KM, THEN the system SHALL submit the punch-in with the validated approval code
5. WHEN the approval code is successfully used for punch-in, THEN the system SHALL mark the code as used and update the attendance record

### Requirement 2

**User Story:** As a salesman, I want to see when each account was created in the recent accounts section, so that I can track my account creation activity over time.

#### Acceptance Criteria

1. WHEN the salesman views the recent accounts section on the dashboard, THEN the system SHALL display the creation date and time for each account
2. WHEN an account was created less than 24 hours ago, THEN the system SHALL display a relative time format (e.g., "2h 30m ago", "Created 5 hours ago")
3. WHEN an account was created more than 24 hours ago, THEN the system SHALL display the full date and time format (e.g., "Dec 22, 2024 • 02:30 PM")
4. WHEN the account creation timestamp is not available, THEN the system SHALL display "Date not available" instead of showing no information
5. WHEN the recent accounts list is refreshed, THEN the system SHALL update the displayed timestamps to reflect the current time

### Requirement 3

**User Story:** As a salesman, I want the approval code validation to seamlessly integrate with the punch-in process, so that I don't have to manually re-enter information or navigate between screens.

#### Acceptance Criteria

1. WHEN the salesman validates an approval code successfully, THEN the system SHALL store the validated code in the component state
2. WHEN the punch-in dialog is triggered after code validation, THEN the system SHALL automatically include the validated approval code in the punch-in request
3. WHEN the punch-in is successful with an approval code, THEN the system SHALL clear the stored approval code from state
4. WHEN the punch-in fails, THEN the system SHALL retain the approval code so the salesman can retry without re-validating
5. WHEN the approval code expires or is used, THEN the system SHALL display an appropriate message and allow the salesman to request a new approval

### Requirement 4

**User Story:** As a salesman, I want clear visual feedback about my approval status, so that I understand what actions I need to take to complete my punch-in.

#### Acceptance Criteria

1. WHEN the salesman has no pending approval request, THEN the system SHALL display a form to request approval with a reason field
2. WHEN the salesman has a pending approval request, THEN the system SHALL display the pending status with request details and auto-refresh every 10 seconds
3. WHEN the admin approves the request, THEN the system SHALL display a success message and show the approval code input field
4. WHEN the admin rejects the request, THEN the system SHALL display the rejection reason and allow the salesman to submit a new request
5. WHEN the approval code is validated successfully, THEN the system SHALL display a confirmation message and enable the punch-in button
