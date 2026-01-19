# Firebase Project Setup Guide

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Google Cloud account with billing enabled
- Flutter development environment set up

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Project name: `Live Salesman Tracking`
4. Project ID: `live-salesman-tracking` (or similar if taken)
5. Enable Google Analytics (recommended)
6. Select region: Choose closest to your users

## Step 2: Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Optionally enable "Email link (passwordless sign-in)"

## Step 3: Set up Firestore Database

1. Go to Firestore Database
2. Click "Create database"
3. Start in "test mode" (we'll apply security rules later)
4. Choose location closest to your users
5. Deploy security rules: `firebase deploy --only firestore:rules`
6. Deploy indexes: `firebase deploy --only firestore:indexes`

## Step 4: Set up Realtime Database

1. Go to Realtime Database
2. Click "Create Database"
3. Choose location (same as Firestore)
4. Start in "locked mode"
5. Deploy security rules: `firebase deploy --only database`

## Step 5: Configure Flutter Apps

### Android Configuration
1. In Firebase Console, click "Add app" → Android
2. Package name: `com.example.livesalesmantracking`
3. Download `google-services.json`
4. Place in `android/app/` directory
5. Update `android/build.gradle` and `android/app/build.gradle`

### iOS Configuration
1. In Firebase Console, click "Add app" → iOS
2. Bundle ID: `com.example.livesalesmantracking`
3. Download `GoogleService-Info.plist`
4. Add to iOS project in Xcode
5. Update `ios/Runner/Info.plist`

### Web Configuration
1. In Firebase Console, click "Add app" → Web
2. App nickname: `Live Salesman Tracking Web`
3. Copy configuration object
4. Update `firebase_config_template.dart` with actual values

## Step 6: Generate Service Account Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to IAM & Admin → Service Accounts
4. Find Firebase Admin SDK service account
5. Click "Actions" → "Create key"
6. Choose JSON format
7. Download and rename to `service_account.json`
8. Store securely (never commit to version control)

## Step 7: Set up Custom Claims for Roles

Create a Cloud Function or use Admin SDK to set custom claims:

```javascript
// Example Cloud Function to set user roles
const admin = require('firebase-admin');

exports.setUserRole = functions.https.onCall(async (data, context) => {
  // Verify admin user
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can set roles');
  }
  
  const { uid, role } = data;
  
  try {
    await admin.auth().setCustomUserClaims(uid, { role });
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

## Step 8: Deploy Configuration

```bash
# Login to Firebase
firebase login

# Initialize project (if not done)
firebase init

# Deploy all rules and configuration
firebase deploy
```

## Step 9: Test Configuration

1. Start Firebase emulators: `firebase emulators:start`
2. Test authentication flow
3. Test database read/write operations
4. Verify security rules are working

## Environment Variables

Create `.env` file for sensitive configuration:

```
FIREBASE_PROJECT_ID=live-salesman-tracking
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=live-salesman-tracking.firebaseapp.com
FIREBASE_DATABASE_URL=https://live-salesman-tracking-default-rtdb.firebaseio.com
FIREBASE_STORAGE_BUCKET=live-salesman-tracking.appspot.com
MAPBOX_ACCESS_TOKEN=your_mapbox_token
```

## Security Considerations

1. Never commit service account keys to version control
2. Use environment variables for sensitive configuration
3. Regularly rotate API keys and access tokens
4. Monitor Firebase usage and set up billing alerts
5. Review and test security rules thoroughly
6. Enable audit logging for production environments

## Next Steps

After completing this setup:
1. Proceed to Task 2: Mapbox Account and API Setup
2. Test Firebase connection in Flutter app
3. Implement authentication service
4. Set up initial user roles and test data