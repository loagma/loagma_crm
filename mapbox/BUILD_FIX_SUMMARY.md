# Mapbox Build Fix Summary

## Issue Encountered

When attempting to run `flutter run` on Windows, the build failed with:

1. **SDK Registry Token Missing**: The Mapbox SDK requires `SDK_REGISTRY_TOKEN` for downloading the SDK
2. **Namespace Not Specified**: Old Mapbox plugin version (1.1.0) incompatible with newer Android Gradle Plugin
3. **Kotlin Compilation Errors**: Cross-drive path issues between Pub cache (C:) and project (D:)

## Fixes Applied

### 1. Added SDK Registry Token

**File**: `loagma_crm/android/gradle.properties`

```properties
SDK_REGISTRY_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA
```

**File**: `~/.gradle/gradle.properties` (global)

```properties
MAPBOX_DOWNLOADS_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3J2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA
SDK_REGISTRY_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3J2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA
```

### 2. Upgraded Mapbox Plugin

**File**: `loagma_crm/pubspec.yaml`

Changed from:
```yaml
mapbox_maps_flutter: ^1.1.0
```

To:
```yaml
mapbox_maps_flutter: ^2.17.0
```

### 3. Updated Mapbox Service for New API

**File**: `loagma_crm/lib/services/live_tracking/mapbox_service.dart`

Removed `.toJson()` calls as the new API accepts objects directly:

```dart
// Old API (1.1.0)
geometry: point.toJson()

// New API (2.17.0)
geometry: point
```

### 4. Disabled Kotlin Incremental Compilation

**File**: `loagma_crm/android/gradle.properties`

```properties
# Disable Kotlin incremental compilation to avoid path issues on Windows
kotlin.incremental=false
```

This fixes the "different roots" error when Pub cache is on C: drive and project is on D: drive.

## Build Result

✅ **Build Successful!**

```
Running Gradle task 'assembleDebug'...                            154.3s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

## Configuration Summary

### Tokens Configured

1. **MAPBOX_ACCESS_TOKEN**: Public token for map display
   - Location: `loagma_crm/android/gradle.properties`
   - Location: `loagma_crm/ios/Runner/Info.plist`
   - Location: `loagma_crm/lib/config/mapbox_config.dart`
   - Location: `backend/.env`

2. **MAPBOX_DOWNLOADS_TOKEN**: Token for SDK downloads
   - Location: `loagma_crm/android/gradle.properties`
   - Location: `~/.gradle/gradle.properties`

3. **SDK_REGISTRY_TOKEN**: Token required by mapbox_maps_flutter plugin
   - Location: `loagma_crm/android/gradle.properties`
   - Location: `~/.gradle/gradle.properties`

### Files Modified

1. `loagma_crm/pubspec.yaml` - Upgraded Mapbox plugin to 2.17.0
2. `loagma_crm/android/gradle.properties` - Added tokens and disabled incremental compilation
3. `~/.gradle/gradle.properties` - Added global tokens
4. `loagma_crm/lib/services/live_tracking/mapbox_service.dart` - Updated API calls
5. `mapbox/SETUP_COMPLETE.md` - Added Windows troubleshooting section
6. `mapbox/WINDOWS_BUILD_FIX.md` - Created Windows-specific fix documentation

## Next Steps

You can now run the app:

```cmd
cd loagma_crm
flutter run
```

Or build for release:

```cmd
flutter build apk --release
```

## Notes

- The Kotlin incremental compilation fix makes builds slightly slower but more reliable on Windows
- The Mapbox plugin upgrade (1.1.0 → 2.17.0) brings new features and better compatibility
- All tokens are using the same public token - for production, create a secret token with DOWNLOADS:READ scope

## Documentation Created

- `mapbox/WINDOWS_BUILD_FIX.md` - Detailed Windows build fix guide
- `mapbox/BUILD_FIX_SUMMARY.md` - This file
- Updated `mapbox/SETUP_COMPLETE.md` - Added Windows troubleshooting

---

**Fix Completed**: January 15, 2026
**Build Status**: ✅ Successful
**Platform**: Windows (cmd shell)
