# Implementation Plan

- [ ] 1. Fix duration timer calculation and display




  - Fix the `liveWorkDuration` getter to properly calculate elapsed time
  - Ensure `_getCurrentDurationText()` method formats duration correctly
  - Update timer to refresh duration display every second
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ]* 1.1 Write property test for duration calculation
  - **Property 1: Duration calculation accuracy**
  - **Validates: Requirements 1.2**

- [ ]* 1.2 Write property test for duration formatting
  - **Property 2: Duration formatting consistency**
  - **Validates: Requirements 1.3**

- [ ]* 1.3 Write unit tests for edge cases
  - Test null punch-in time returns 00:00:00
  - Test negative duration returns 00:00:00
  - _Requirements: 1.4, 1.5_

- [ ] 2. Fix early punch-out approval widget integration
  - Remove generic error dialog for early punch-out attempts
  - Ensure proper conditional rendering of approval widget vs punch-out button
  - Fix approval code storage and state management
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ]* 2.1 Write property test for widget visibility
  - **Property 3: Widget visibility exclusivity**
  - **Validates: Requirements 2.1, 2.2**

- [ ]* 2.2 Write property test for approval code validation
  - **Property 4: Approval code validation behavior**
  - **Validates: Requirements 2.6**

- [ ]* 2.3 Write unit tests for approval widget states
  - Test request form display when no approval exists
  - Test pending status display for pending approvals
  - Test code input form display for approved requests
  - Test rejection display for rejected requests
  - _Requirements: 2.3, 2.4, 2.5, 2.7_

- [ ] 3. Implement proper approval state management
  - Fix approval code storage and cleanup logic
  - Ensure state persistence across screen refreshes
  - Handle approval code validation callbacks correctly
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ]* 3.1 Write property test for state management
  - **Property 5: State management consistency**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**

- [ ]* 3.2 Write property test for state persistence
  - **Property 6: State persistence across refreshes**
  - **Validates: Requirements 3.5**

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Test the complete punch-out flow
  - Verify duration timer works correctly during active session
  - Test early punch-out approval flow end-to-end
  - Verify proper error handling and state management
  - _Requirements: All requirements_

- [ ]* 5.1 Write integration tests for complete flow
  - Test full punch-out flow with approval
  - Test timer updates during active session
  - Test screen refresh behavior
  - _Requirements: All requirements_