# Windows Build Fix for Mapbox Integration

## Issue

When building the Flutter app on Windows, you may encounter Kotlin compilation errors related to "different roots" between the Pub cache (C:\Users\...) and your project directory (D:\loagma_crm\...).

This is a known issue with Kotlin's incremental compilation on Windows when dependencies are on a different drive than the project.

## Solution Options

### Option 1: Disable Kotlin Incremental Compilation (Recommended)

Add this to your `android/gradle.properties`:

```properties
# Disable Kotlin incremental compilation to avoid path issues on Windows
kotlin.incremental=false
```

### Option 2: Move Project to Same Drive as Pub Cache

Move your project to the C: drive where the Pub cache is located:

```cmd
# Move project to C: drive
xcopy /E /I D:\loagma_crm C:\loagma_crm
cd C:\loagma_crm\loagma_crm
flutter clean
flutter pub get
flutter run
```

### Option 3: Use --no-build-cache Flag

Run Flutter with the no-build-cache flag:

```cmd
flutter run --no-build-cache
```

### Option 4: Clean Build More Aggressively

```cmd
cd loagma_crm
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
flutter run
```

## Applying the Fix

Let's apply Option 1 (disable incremental compilation):

1. The fix has been added to `android/gradle.properties`
2. Clean the project: `flutter clean`
3. Get dependencies: `flutter pub get`
4. Run the app: `flutter run`

## Verification

After applying the fix, you should be able to build successfully:

```cmd
cd loagma_crm
flutter clean
flutter pub get
flutter run
```

## Additional Notes

- This issue affects many Flutter plugins that use Kotlin
- The fix (disabling incremental compilation) will make builds slightly slower but more reliable
- This is a temporary workaround until the Kotlin Gradle plugin fixes the cross-drive path issue

## Related Issues

- https://github.com/flutter/flutter/issues/97251
- https://youtrack.jetbrains.com/issue/KT-48823
