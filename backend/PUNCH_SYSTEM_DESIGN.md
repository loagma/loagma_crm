# Punch In/Out System - Complete Redesign

## 1. STATE MACHINE DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           PUNCH STATE MACHINE                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌──────────┐                                                                   │
│  │   IDLE   │ ◄─────────────────────────────────────────────────────────────┐  │
│  └────┬─────┘                                                               │  │
│       │                                                                     │  │
│       ▼                                                                     │  │
│  ┌────────────────┐     ┌─────────────────────┐                            │  │
│  │ Check Time     │────►│ REQUIRES_LATE_      │                            │  │
│  │ (Late?)        │     │ APPROVAL            │                            │  │
│  └───────┬────────┘     └──────────┬──────────┘                            │  │
│          │                         │                                        │  │
│          │ [On Time]               │ [Submit Request]                       │  │
│          │                         ▼                                        │  │
│          │              ┌─────────────────────┐                            │  │
│          │              │ WAITING_APPROVAL    │◄────────────────┐          │  │
│          │              │ (PENDING)           │                 │          │  │
│          │              └──────────┬──────────┘                 │          │  │
│          │                         │                            │          │  │
│          │         ┌───────────────┼───────────────┐            │          │  │
│          │         │               │               │            │          │  │
│          │    [Approved]      [Rejected]      [Expired]         │          │  │
│          │         │               │               │            │          │  │
│          │         ▼               ▼               ▼            │          │  │
│          │  ┌──────────────┐  ┌─────────┐  ┌──────────────┐     │          │  │
│          │  │ CAN_PUNCH_IN │  │ BLOCKED │  │ EXPIRED      │─────┘          │  │
│          │  └──────┬───────┘  └─────────┘  └──────────────┘                │  │
│          │         │                                                        │  │
│          └─────────┤                                                        │  │
│                    │ [Punch In]                                             │  │
│                    ▼                                                        │  │
│           ┌────────────────┐                                                │  │
│           │ SESSION_ACTIVE │                                                │  │
│           │ (OPEN)         │                                                │  │
│           └───────┬────────┘                                                │  │
│                   │                                                         │  │
│                   ▼                                                         │  │
│           ┌────────────────┐     ┌─────────────────────┐                   │  │
│           │ Check Time     │────►│ REQUIRES_EARLY_     │                   │  │
│           │ (Early?)       │     │ APPROVAL            │                   │  │
│           └───────┬────────┘     └──────────┬──────────┘                   │  │
│                   │                         │                               │  │
│                   │ [Normal]                │ [Submit Request]              │  │
│                   │                         ▼                               │  │
│                   │              ┌─────────────────────┐                   │  │
│                   │              │ WAITING_APPROVAL    │◄────────┐         │  │
│                   │              │ (PENDING)           │         │         │  │
│                   │              └──────────┬──────────┘         │         │  │
│                   │                         │                    │         │  │
│                   │         ┌───────────────┼───────────┐        │         │  │
│                   │         │               │           │        │         │  │
│                   │    [Approved]      [Rejected]  [Expired]     │         │  │
│                   │         │               │           │        │         │  │
│                   │         ▼               ▼           ▼        │         │  │
│                   │  ┌───────────────┐  ┌─────────┐  ┌────────┐  │         │  │
│                   │  │ CAN_PUNCH_OUT │  │ BLOCKED │  │EXPIRED │──┘         │  │
│                   │  └──────┬────────┘  └─────────┘  └────────┘            │  │
│                   │         │                                              │  │
│                   └─────────┤                                              │  │
│                             │ [Punch Out]                                  │  │
│                             ▼                                              │  │
│                    ┌────────────────┐                                      │  │
│                    │ SESSION_CLOSED │──────────────────────────────────────┘  │
│                    │ (COMPLETED)    │                                         │
│                    └────────────────┘                                         │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

## 2. API CONTRACT

### GET /punch/status/:employeeId
**Single source of truth for UI state**

Response:
```json
{
  "success": true,
  "employeeId": "emp123",
  "employeeName": "John Doe",
  "serverTime": "2025-12-26T10:30:00.000Z",
  "serverTimeIST": "26 Dec 2025, 04:00 PM",
  
  "workingHours": {
    "startTime": "09:00:00",
    "endTime": "18:00:00",
    "startGraceMinutes": 45,
    "endGraceMinutes": 30
  },
  
  "activeSession": {
    "id": "session123",
    "punchInTime": "2025-12-26T03:30:00.000Z",
    "punchInTimeIST": "26 Dec 2025, 09:00 AM",
    "status": "OPEN"
  },
  
  "todaySessionsCount": 1,
  
  "canPunchIn": false,
  "canPunchOut": true,
  "requiresApproval": false,
  "approvalType": null,
  "approvalStatus": null,
  "approvalId": null,
  
  "message": "You can punch out now.",
  "uiState": "CAN_PUNCH_OUT"
}
```

### POST /punch/approval/request
Request approval for late punch-in or early punch-out.

Request:
```json
{
  "employeeId": "emp123",
  "employeeName": "John Doe",
  "type": "LATE_PUNCH_IN",  // or "EARLY_PUNCH_OUT"
  "reason": "Traffic jam on highway",
  "attendanceId": "session123"  // Required only for EARLY_PUNCH_OUT
}
```

### POST /punch/approval/approve (Admin)
```json
{
  "requestId": "req123",
  "type": "LATE_PUNCH_IN",
  "adminId": "admin123",
  "adminRemarks": "Approved due to valid reason"
}
```

### POST /punch/approval/reject (Admin)
```json
{
  "requestId": "req123",
  "type": "LATE_PUNCH_IN",
  "adminId": "admin123",
  "adminRemarks": "Reason not acceptable"
}
```

### GET /punch/approval/pending (Admin)
Get all pending approval requests.

## 3. UI STATE MAPPING

| Backend uiState    | Flutter UI                                      |
|--------------------|------------------------------------------------|
| IDLE               | Show "Request Approval" button (if late)       |
| CAN_PUNCH_IN       | Show enabled "Punch In" button                 |
| WAITING_APPROVAL   | Show disabled button + "Waiting for approval"  |
| SESSION_ACTIVE     | Show "Request Approval" button (if early)      |
| CAN_PUNCH_OUT      | Show enabled "Punch Out" button                |

## 4. FLUTTER UI RULES

```dart
// On app open / refresh / resume:
final status = await PunchStatusService.getPunchStatus(employeeId);

// Render UI based on status.uiState:
switch (status.uiState) {
  case PunchUIState.idle:
    if (status.requiresApproval) {
      showApprovalRequestForm(status.approvalType);
    }
    break;
    
  case PunchUIState.canPunchIn:
    showEnabledPunchInButton();
    break;
    
  case PunchUIState.waitingApproval:
    showDisabledButton();
    showMessage(status.message);
    break;
    
  case PunchUIState.sessionActive:
    if (status.requiresApproval) {
      showApprovalRequestForm(status.approvalType);
    }
    break;
    
  case PunchUIState.canPunchOut:
    showEnabledPunchOutButton();
    break;
}
```

**CRITICAL RULES:**
1. NEVER calculate time rules in Flutter
2. ALWAYS call /punch/status on app open/refresh
3. ALWAYS disable buttons while waiting for approval
4. ALWAYS show server message to user

## 5. EDGE CASES HANDLED

### 5.1 Duplicate Approvals
- Backend checks for existing PENDING request before creating new one
- Returns error with existing request ID

### 5.2 Approval Reuse
- Each approval has `codeUsed` flag
- After punch-in/out, approval is marked as USED
- USED approvals cannot be reused

### 5.3 App Refresh During Approval
- `/punch/status` returns current approval state
- UI renders based on `approvalStatus` (PENDING/APPROVED)
- State persists across app restarts

### 5.4 Time Drift (Server vs Client)
- All time calculations happen on server
- Client only displays `serverTimeIST`
- No client-side time validation

### 5.5 Admin Approves After Expiry
- Backend checks expiry before approving
- Returns error if request has expired
- Auto-updates status to EXPIRED

### 5.6 Punch After Session Closed
- Backend checks `attendance.status === 'active'`
- Returns error if session already completed
- For early punch-out: validates attendanceId

### 5.7 Auto-Expiry
- Cron job runs every 5 minutes
- Expires PENDING requests after 30 minutes
- Expires APPROVED but unused codes after 2 hours

## 6. WHY PREVIOUS IMPLEMENTATION FAILED

### Problem 1: Inconsistent Code Generation
**Before:** Late punch-in generated codes, early punch-out didn't
**After:** Both use same approval flow with optional codes

### Problem 2: Time Calculation in Flutter
**Before:** Flutter calculated cutoff times locally
**After:** All time logic on server, Flutter only renders

### Problem 3: No Single Source of Truth
**Before:** Multiple endpoints returned partial state
**After:** `/punch/status` returns complete UI state

### Problem 4: No Expiry Handling
**Before:** Approvals never expired
**After:** Auto-expiry with cron job + validation on every request

### Problem 5: Race Conditions
**Before:** Could submit multiple requests simultaneously
**After:** Backend checks for existing PENDING request

### Problem 6: Approval Reuse
**Before:** Same approval could be used multiple times
**After:** `codeUsed` flag prevents reuse

## 7. DATABASE CHANGES

No schema changes required. Existing models are sufficient:
- `Attendance` - Punch sessions
- `LatePunchApproval` - Late punch-in requests
- `EarlyPunchOutApproval` - Early punch-out requests

Added fields already exist:
- `codeUsed` - Boolean flag
- `codeUsedAt` - Timestamp
- `codeExpiresAt` - Expiry timestamp

## 8. MIGRATION GUIDE

### Backend
1. Add `punchStatusRoutes.js` to routes
2. Register in `server.js`
3. Set up cron job for `expireStaleApprovals()`

### Flutter
1. Replace all punch status calls with `PunchStatusService.getPunchStatus()`
2. Update UI to render based on `uiState`
3. Remove all local time calculations
4. Use `PunchStatusService.requestApproval()` for approval requests

### Cron Job Setup
```javascript
// Run every 5 minutes
import cron from 'node-cron';
import { expireStaleApprovals } from './controllers/punchStatusController.js';

cron.schedule('*/5 * * * *', async () => {
  await expireStaleApprovals();
});
```
