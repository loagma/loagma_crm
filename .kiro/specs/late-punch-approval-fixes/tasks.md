# Implementation Plan

- [x] 1. Enhance Late Punch Approval Widget Callback System
  - Add callback parameter to pass validated approval code to parent screen
  - Update `onApprovalReceived` callback to include the actual approval code
  - Modify `_validateApprovalCode()` method to pass code in callback
  - _Requirements: 1.2, 1.3, 3.1, 4.5_

- [x]* 1.1 Write property test for approval code validation callback
  - **Property 2: Approval code input visibility**
  - **Validates: Requirements 1.2**

- [x]* 1.2 Write property test for code validation triggering
  - **Property 3: Code validation triggers punch dialog**
  - **Validates: Requirements 1.3**

- [ ] 2. Fix Enhanced Punch Screen Approval Code Integration
  - Update `onApprovalReceived` callback to receive and store actual approval code
  - Modify `_handlePunchIn()` to use the validated approval code from widget
  - Fix state management to store actual code instead of 'validated' string
  - Add proper state cleanup after successful punch-in
  - _Requirements: 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 3.4_

- [ ]* 2.1 Write property test for approval code state management
  - **Property 9: State persistence during validation flow**
  - **Validates: Requirements 3.1**

- [ ]* 2.2 Write property test for automatic code inclusion
  - **Property 10: Automatic code inclusion in punch dialog**
  - **Validates: Requirements 3.2**

- [ ]* 2.3 Write property test for state cleanup after punch-in
  - **Property 11: State cleanup after successful punch-in**
  - **Validates: Requirements 3.3**

- [x] 3. Fix Salesman Dashboard Recent Accounts Display
  - ~~Add creation date display to recent accounts section~~ ✅ Already implemented
  - ~~Implement proper time formatting (relative vs absolute)~~ ✅ Already implemented
  - ~~Handle missing timestamp data gracefully~~ ✅ Already implemented
  - ~~Update the account card widget to show creation information~~ ✅ Already implemented
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ]* 3.1 Write property test for timestamp display
  - **Property 6: Account creation date display**
  - **Validates: Requirements 2.1**

- [ ]* 3.2 Write property test for relative time formatting
  - **Property 7: Relative time formatting for recent accounts**
  - **Validates: Requirements 2.2**

- [ ]* 3.3 Write property test for full date formatting
  - **Property 8: Full date formatting for older accounts**
  - **Validates: Requirements 2.3**

- [ ] 4. Create Centralized Time Formatting Utilities
  - Extract `_getTimeAgo()` method to a shared utility file
  - Create `TimeFormattingUtils` class with static methods
  - Update all screens to use centralized utility
  - Add logic to determine relative vs absolute time display (24-hour threshold)
  - _Requirements: 2.2, 2.3, 2.4_

- [ ] 5. Enhance Error Handling and User Feedback
  - Improve error messages for expired or used approval codes in widget
  - Add proper success feedback for code validation
  - Ensure graceful handling of network errors during validation
  - Add retry mechanism for failed validations
  - _Requirements: 3.5, 4.3, 4.4_

- [ ]* 5.1 Write property test for expired code handling
  - **Property 13: Expired code handling**
  - **Validates: Requirements 3.5**

- [ ] 6. Implement Code Retention on Punch-In Failure
  - Modify punch-in error handling to retain validated approval code
  - Add logic to clear code only on successful punch-in
  - Update error messages to indicate code is still valid for retry
  - _Requirements: 3.4_

- [ ]* 6.1 Write property test for code retention on failure
  - **Property 12: Code retention on punch-in failure**
  - **Validates: Requirements 3.4**

- [ ]* 7. Write Property Tests for UI State Management
  - Test widget display conditions based on time and punch status
  - Test approval status UI states for different scenarios
  - Test state transitions during approval workflow
  - _Requirements: 1.1, 4.1, 4.2, 4.3, 4.4_

- [ ]* 7.1 Write property test for widget display conditions
  - **Property 1: Late punch approval widget display**
  - **Validates: Requirements 1.1**

- [ ]* 7.2 Write property test for approval status UI states
  - **Property 14: Approval status UI states**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [ ]* 8. Write Property Tests for Punch-In Integration
  - Test approval code inclusion in punch-in API requests
  - Test code state management after punch-in success/failure
  - Test validation feedback and button states
  - _Requirements: 1.4, 1.5, 4.5_

- [ ]* 8.1 Write property test for approval code inclusion in API
  - **Property 4: Approval code inclusion in punch-in**
  - **Validates: Requirements 1.4**

- [ ]* 8.2 Write property test for code state after punch-in
  - **Property 5: Code state management after punch-in**
  - **Validates: Requirements 1.5**

- [ ]* 8.3 Write property test for validation feedback
  - **Property 15: Validation feedback and button state**
  - **Validates: Requirements 4.5**

- [ ] 9. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Final Integration Testing and Validation
  - Test complete workflow from late punch request to successful punch-in
  - Verify error scenarios and recovery flows work correctly
  - Validate user experience improvements meet requirements
  - Test edge cases like network failures and expired codes
  - _Requirements: All requirements validation_

- [ ] 11. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.