# Quick Start Guide - Live Salesman Tracking System

## Prerequisites

✅ All prerequisites are configured:
- Flutter SDK installed
- Android SDK configured
- Firebase project set up
- Mapbox account created with access token
- All tokens configured

## Running the App

### Option 1: Run on Connected Device/Emulator

```cmd
cd loagma_crm
flutter run
```

### Option 2: Build APK

```cmd
cd loagma_crm
flutter build apk --debug
```

The APK will be located at: `build\app\outputs\flutter-apk\app-debug.apk`

### Option 3: Build Release APK

```cmd
cd loagma_crm
flutter build apk --release
```

## Troubleshooting

### Build Fails

If the build fails, try:

```cmd
cd loagma_crm
flutter clean
flutter pub get
flutter run
```

### Kotlin Compilation Errors on Windows

This has been fixed by disabling incremental compilation. If you still see issues:

```cmd
cd loagma_crm
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
flutter run
```

### Map Not Displaying

1. Check internet connectivity
2. Verify Mapbox token in `lib/config/mapbox_config.dart`
3. Check console logs for errors

### Firebase Connection Issues

1. Verify `google-services.json` is in `android/app/`
2. Verify `GoogleService-Info.plist` is in `ios/Runner/`
3. Check Firebase console for project status

## Project Structure

```
loagma_crm/
├── lib/
│   ├── config/
│   │   ├── mapbox_config.dart          # Mapbox configuration
│   │   └── firebase_config.dart        # Firebase configuration
│   ├── services/
│   │   └── live_tracking/
│   │       ├── mapbox_service.dart     # Mapbox integration
│   │       ├── location_service.dart   # GPS tracking
│   │       └── firebase_live_tracking_service.dart
│   ├── screens/
│   │   └── live_tracking/
│   │       ├── admin_dashboard_screen.dart
│   │       └── salesman_dashboard_screen.dart
│   └── models/
│       └── live_tracking/
│           └── location_models.dart
├── android/
│   ├── app/
│   │   └── google-services.json        # Firebase config
│   └── gradle.properties               # Mapbox tokens
└── ios/
    └── Runner/
        ├── GoogleService-Info.plist    # Firebase config
        └── Info.plist                  # Mapbox token

```

## Key Features Implemented

### Phase 1 - Foundation (✅ Complete)

1. **Firebase Integration**
   - Authentication with email/password
   - Firestore for data storage
   - Realtime Database for live locations
   - Role-based access control (Admin/Salesman)

2. **Mapbox Integration**
   - Interactive maps with zoom, pan, rotation
   - Custom markers for salesman locations
   - Marker clustering for nearby locations
   - Route visualization with polylines
   - Multiple map styles (Streets, Satellite, Outdoors)

3. **Location Services**
   - GPS tracking with high accuracy
   - Background location tracking
   - Location permission handling
   - Offline data queuing

4. **User Interface**
   - Admin dashboard for monitoring
   - Salesman dashboard for tracking
   - Live map view with real-time updates
   - Role-based navigation

## Configuration Files

### Mapbox Token

**Location**: `loagma_crm/lib/config/mapbox_config.dart`

```dart
static const String accessToken = 'pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3J2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA';
```

### Firebase Configuration

- Android: `loagma_crm/android/app/google-services.json`
- iOS: `loagma_crm/ios/Runner/GoogleService-Info.plist`

## Testing

### Run Integration Tests

```cmd
cd loagma_crm
flutter test test/integration/
```

### Run Unit Tests

```cmd
cd loagma_crm
flutter test
```

## Documentation

- `mapbox/SETUP_COMPLETE.md` - Complete Mapbox setup guide
- `mapbox/WINDOWS_BUILD_FIX.md` - Windows-specific build fixes
- `mapbox/BUILD_FIX_SUMMARY.md` - Summary of fixes applied
- `firebase/README.md` - Firebase setup guide
- `.kiro/specs/live-salesman-tracking/` - Complete specification

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the documentation in `mapbox/` and `firebase/` directories
3. Check the spec files in `.kiro/specs/live-salesman-tracking/`

---

**Last Updated**: January 15, 2026
**Status**: Phase 1 Complete ✅
**Ready for**: Phase 2 Implementation
