# Requirements Document

## Introduction

This specification defines the simplification of the Verify Accounts screen for telecallers. The current implementation has a complex card layout with multiple buttons. The goal is to create a cleaner, more streamlined interface that matches the visual design of other screens in the application, with a simpler card layout and better visual hierarchy.

## Glossary

- **Verify_Accounts_Screen**: The telecaller interface for reviewing and approving/rejecting pending customer accounts
- **Account_Card**: A visual card component displaying account information with action buttons
- **Pending_Account**: A customer account that has been created but not yet approved or rejected
- **Telecaller**: A user role responsible for verifying customer account information

## Requirements

### Requirement 1: Simplified Card Layout

**User Story:** As a telecaller, I want to see pending accounts in a clean, simple card format, so that I can quickly review account information without visual clutter.

#### Acceptance Criteria

1. WHEN the Verify Accounts screen loads, THE Verify_Accounts_Screen SHALL display each pending account in a rounded card with white background
2. WHEN displaying an account card, THE Account_Card SHALL show a circular avatar with the first letter of the business name
3. WHEN displaying account information, THE Account_Card SHALL show the business name as the primary heading
4. WHEN displaying account information, THE Account_Card SHALL show the person name as secondary text below the business name
5. WHEN displaying account information, THE Account_Card SHALL show the contact number with a phone icon
6. WHEN displaying account information, THE Account_Card SHALL show the business type with a business icon
7. WHEN displaying the account status, THE Account_Card SHALL show a "Pending" badge in orange color on the top right

### Requirement 2: Streamlined Action Buttons

**User Story:** As a telecaller, I want clear action buttons for each account, so that I can quickly approve or reject accounts with minimal clicks.

#### Acceptance Criteria

1. WHEN displaying action buttons, THE Account_Card SHALL show three buttons in a horizontal row
2. WHEN displaying the View Details button, THE Account_Card SHALL use a blue background with white text and an eye icon
3. WHEN displaying the Approve button, THE Account_Card SHALL use a green background with white text and a checkmark icon
4. WHEN displaying the Reject button, THE Account_Card SHALL use a red background with white text and an X icon
5. WHEN a user taps the View Details button, THE Verify_Accounts_Screen SHALL navigate to the account detail screen
6. WHEN a user taps the Approve button, THE Verify_Accounts_Screen SHALL approve the account and refresh the list
7. WHEN a user taps the Reject button, THE Verify_Accounts_Screen SHALL reject the account and refresh the list

### Requirement 3: Visual Consistency

**User Story:** As a telecaller, I want the Verify Accounts screen to match the visual style of other screens, so that the application feels cohesive and professional.

#### Acceptance Criteria

1. WHEN the screen loads, THE Verify_Accounts_Screen SHALL use the standard app color scheme with the golden yellow (#D7BE69) header
2. WHEN displaying the screen background, THE Verify_Accounts_Screen SHALL use a gradient from golden yellow to light gray
3. WHEN displaying cards, THE Account_Card SHALL have consistent spacing of 16 pixels between cards
4. WHEN displaying cards, THE Account_Card SHALL have rounded corners with 12 pixel radius
5. WHEN displaying cards, THE Account_Card SHALL have a subtle shadow elevation of 4

### Requirement 4: Empty State Handling

**User Story:** As a telecaller, I want to see a clear message when there are no pending accounts, so that I know the system is working correctly.

#### Acceptance Criteria

1. WHEN there are no pending accounts, THE Verify_Accounts_Screen SHALL display a centered icon and message
2. WHEN displaying the empty state, THE Verify_Accounts_Screen SHALL show a verified user icon in gray
3. WHEN displaying the empty state, THE Verify_Accounts_Screen SHALL show the text "No accounts pending verification"

### Requirement 5: Loading State

**User Story:** As a telecaller, I want to see a loading indicator while accounts are being fetched, so that I know the system is working.

#### Acceptance Criteria

1. WHEN the screen is loading data, THE Verify_Accounts_Screen SHALL display a centered circular progress indicator
2. WHEN accounts are successfully loaded, THE Verify_Accounts_Screen SHALL hide the loading indicator and show the account list

### Requirement 6: Error Handling

**User Story:** As a telecaller, I want to see clear error messages when operations fail, so that I understand what went wrong.

#### Acceptance Criteria

1. IF loading accounts fails, THEN THE Verify_Accounts_Screen SHALL display an error message using a snackbar
2. IF approving an account fails, THEN THE Verify_Accounts_Screen SHALL display an error message using a snackbar
3. IF rejecting an account fails, THEN THE Verify_Accounts_Screen SHALL display an error message using a snackbar
4. WHEN an operation succeeds, THE Verify_Accounts_Screen SHALL display a success toast message

### Requirement 7: Context Safety

**User Story:** As a developer, I want the screen to handle async operations safely, so that the app doesn't crash when the widget is unmounted.

#### Acceptance Criteria

1. WHEN using BuildContext after an async operation, THE Verify_Accounts_Screen SHALL check if the widget is still mounted
2. WHEN the widget is unmounted, THE Verify_Accounts_Screen SHALL not attempt to show dialogs or snackbars
