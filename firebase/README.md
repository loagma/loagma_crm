# Firebase Configuration for Live Salesman Tracking

This directory contains all Firebase configuration files and setup instructions for the Live Salesman Tracking System.

## Files Overview

### Configuration Files
- `firebase.json` - Main Firebase project configuration
- `firestore.rules` - Firestore security rules with role-based access control
- `firestore.indexes.json` - Firestore database indexes for optimal query performance
- `database.rules.json` - Realtime Database security rules for live location data

### Templates
- `firebase_config_template.dart` - Flutter Firebase configuration template
- `service_account_template.json` - Service account key template for admin operations

### Implementation Files
- `firebase_service.dart` - Firebase service class for Flutter integration
- `setup_firebase.md` - Detailed setup instructions
- `README.md` - This file

## Quick Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project: "Live Salesman Tracking"
   - Enable Authentication (Email/Password)
   - Create Firestore Database
   - Create Realtime Database

2. **Deploy Configuration**
   ```bash
   firebase login
   firebase init
   firebase deploy
   ```

3. **Configure Flutter Apps**
   - Add platform-specific configuration files
   - Update `firebase_config_template.dart` with your project details
   - Copy `firebase_service.dart` to your Flutter project

## Security Rules

### Firestore Rules
- **Role-based access control**: Admin and Salesman roles
- **Data validation**: Ensures data integrity
- **Owner-based access**: Users can only access their own data (except admins)

### Realtime Database Rules
- **Live location data**: Only salesmen can write, admins can read all
- **Data validation**: Validates location coordinates and data types
- **Real-time updates**: Optimized for live tracking scenarios

## Data Structure

### Firestore Collections
```
users/
├── {userId}/
    ├── email: string
    ├── role: "admin" | "salesman"
    ├── name: string
    ├── active: boolean
    └── created_at: timestamp

location_history/
├── {locationId}/
    ├── user_id: string
    ├── latitude: number
    ├── longitude: number
    ├── timestamp: timestamp
    ├── accuracy: number
    └── speed: number

daily_distance/
├── {date}_{userId}/
    ├── user_id: string
    ├── date: string
    ├── total_distance: number
    ├── start_time: timestamp
    └── end_time: timestamp
```

### Realtime Database Structure
```
live_locations/
├── {userId}/
    ├── latitude: number
    ├── longitude: number
    ├── timestamp: number
    ├── accuracy: number
    ├── speed: number
    ├── heading: number
    └── is_active: boolean
```

## Usage in Flutter

```dart
import 'firebase_service.dart';

// Initialize Firebase
await FirebaseService.instance.initialize(
  options: FirebaseConfig.currentPlatform,
);

// Validate connection
final isValid = await FirebaseService.instance.validateConnection();

// Get current user role
final role = await FirebaseService.instance.getUserRole();
```

## Environment Variables

Create `.env` file:
```
FIREBASE_PROJECT_ID=live-salesman-tracking
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=live-salesman-tracking.firebaseapp.com
FIREBASE_DATABASE_URL=https://live-salesman-tracking-default-rtdb.firebaseio.com
FIREBASE_STORAGE_BUCKET=live-salesman-tracking.appspot.com
```

## Testing

Use Firebase Emulators for development:
```bash
firebase emulators:start
```

This will start:
- Authentication Emulator (port 9099)
- Firestore Emulator (port 8080)
- Realtime Database Emulator (port 9000)
- Hosting Emulator (port 5000)

## Security Considerations

1. **Never commit service account keys** to version control
2. **Use environment variables** for sensitive configuration
3. **Regularly rotate API keys** and access tokens
4. **Monitor Firebase usage** and set up billing alerts
5. **Test security rules** thoroughly before production deployment

## Next Steps

After completing Firebase setup:
1. Proceed to Mapbox configuration (Task 2)
2. Implement Flutter authentication service (Task 5)
3. Set up location tracking service (Task 8)
4. Test end-to-end data flow

For detailed setup instructions, see `setup_firebase.md`.