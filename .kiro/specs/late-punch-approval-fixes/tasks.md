# Implementation Plan

- [ ] 1. Enhance Late Punch Approval Widget
  - Update the widget to provide better callback integration with the punch screen
  - Add callback for successful approval code validation with the validated code
  - Improve state management for approval code validation flow
  - _Requirements: 1.2, 1.3, 3.1, 4.3, 4.5_

- [ ] 1.1 Write property test for approval code validation callback
  - **Property 2: Approval code input visibility**
  - **Validates: Requirements 1.2**

- [ ] 1.2 Write property test for code validation triggering
  - **Property 3: Code validation triggers punch dialog**
  - **Validates: Requirements 1.3**

- [ ] 2. Update Enhanced Punch Screen Integration
  - Modify the punch screen to properly handle approval code validation callbacks
  - Implement seamless integration between approval code validation and punch-in process
  - Add state management for validated approval codes
  - Update punch-in method to accept and use approval codes
  - _Requirements: 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 3.4_

- [ ] 2.1 Write property test for approval code state management
  - **Property 9: State persistence during validation flow**
  - **Validates: Requirements 3.1**

- [ ] 2.2 Write property test for automatic code inclusion
  - **Property 10: Automatic code inclusion in punch dialog**
  - **Validates: Requirements 3.2**

- [ ] 2.3 Write property test for state cleanup after punch-in
  - **Property 11: State cleanup after successful punch-in**
  - **Validates: Requirements 3.3**

- [ ] 3. Fix Salesman Dashboard Recent Accounts Display
  - Add creation date display to recent accounts section
  - Implement proper time formatting (relative vs absolute)
  - Handle missing timestamp data gracefully
  - Update the account card widget to show creation information
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 3.1 Write property test for timestamp display
  - **Property 6: Account creation date display**
  - **Validates: Requirements 2.1**

- [ ] 3.2 Write property test for relative time formatting
  - **Property 7: Relative time formatting for recent accounts**
  - **Validates: Requirements 2.2**

- [ ] 3.3 Write property test for full date formatting
  - **Property 8: Full date formatting for older accounts**
  - **Validates: Requirements 2.3**

- [ ] 4. Implement Time Formatting Utilities
  - Create or enhance time formatting functions for account creation dates
  - Add logic to determine relative vs absolute time display
  - Handle edge cases for missing or invalid timestamps
  - _Requirements: 2.2, 2.3, 2.4_

- [ ] 5. Update Approval Widget Callback Integration
  - Modify the enhanced punch screen to use the new approval code validation callback
  - Ensure proper state synchronization between widget and parent screen
  - Add error handling for approval code validation failures
  - _Requirements: 1.3, 3.1, 3.4, 4.5_

- [ ] 5.1 Write property test for callback integration
  - **Property 15: Validation feedback and button state**
  - **Validates: Requirements 4.5**

- [ ] 6. Enhance Error Handling and User Feedback
  - Improve error messages for expired or used approval codes
  - Add proper feedback for successful code validation
  - Ensure graceful handling of network errors during validation
  - _Requirements: 3.5, 4.3, 4.4_

- [ ] 6.1 Write property test for expired code handling
  - **Property 13: Expired code handling**
  - **Validates: Requirements 3.5**

- [ ] 7. Update Punch-In Flow Integration
  - Ensure approval codes are properly included in punch-in API requests
  - Add validation to prevent punch-in without valid approval when required
  - Update success/failure handling to manage approval code state
  - _Requirements: 1.4, 1.5, 3.2, 3.3_

- [ ] 7.1 Write property test for approval code inclusion in API
  - **Property 4: Approval code inclusion in punch-in**
  - **Validates: Requirements 1.4**

- [ ] 7.2 Write property test for code state after punch-in
  - **Property 5: Code state management after punch-in**
  - **Validates: Requirements 1.5**

- [ ] 8. Test UI State Management
  - Verify proper display of late punch approval widget based on time and punch status
  - Test approval status UI states for different scenarios
  - Ensure proper state transitions during the approval workflow
  - _Requirements: 1.1, 4.1, 4.2, 4.3, 4.4_

- [ ] 8.1 Write property test for widget display conditions
  - **Property 1: Late punch approval widget display**
  - **Validates: Requirements 1.1**

- [ ] 8.2 Write property test for approval status UI states
  - **Property 14: Approval status UI states**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [ ] 9. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Final Integration Testing
  - Test complete workflow from late punch request to successful punch-in
  - Verify dashboard displays creation dates correctly
  - Test error scenarios and recovery flows
  - Validate user experience improvements
  - _Requirements: All requirements validation_

- [ ] 10.1 Write property test for code retention on failure
  - **Property 12: Code retention on punch-in failure**
  - **Validates: Requirements 3.4**

- [ ] 11. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.