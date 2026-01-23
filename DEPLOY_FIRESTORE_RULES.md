# Deploy Firestore Rules for Live Tracking

## Issue
The live tracking screen is showing `PERMISSION_DENIED` errors because Firestore security rules haven't been deployed to Firebase.

## Solution

### Option 1: Deploy via Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `loagmacrm-a60ba`
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents from `firebase/firestore.rules`
5. Paste into the Firebase Console rules editor
6. Click **Publish**

### Option 2: Deploy via Firebase CLI

1. Install Firebase CLI (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Deploy the rules:
   ```bash
   cd "c:\sparsh workspace\ADRS\loagma_crm"
   firebase deploy --only firestore:rules
   ```

## Current Rules

The rules file at `firebase/firestore.rules` contains:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tracking_live/{employeeId} {
      allow read, write: if true;
    }

    match /tracking/{employeeId}/sessions/{attendanceId}/points/{pointId} {
      allow read, create: if true;
    }
  }
}
```

**Note**: These rules allow open read/write access. For production, you should implement proper authentication-based rules.

## Verification

After deploying, the live tracking screen should work without permission errors. You can verify by:
1. Opening the Live Tracking screen in the app
2. Checking that employees appear on the map (if any are currently tracking)
3. No permission denied errors in the console
