# APK Installation Guide - Getting New Updates

## Issue
When installing a new release APK, the updates aren't showing on your phone.

## Solution Steps

### 1. Clean Build (Completed ✅)
```bash
flutter clean
flutter pub get
```

### 2. Update Version Number (Completed ✅)
Updated `pubspec.yaml`:
- **Old Version:** 1.0.1+2
- **New Version:** 1.0.2+3

The version format is: `major.minor.patch+buildNumber`
- `1.0.2` = Version name (shown to users)
- `3` = Build number (used by Android to determine if it's newer)

### 3. Build Release APK (Completed ✅)
```bash
flutter build apk --release
```

**APK Location:**
```
loagma_crm/build/app/outputs/flutter-apk/app-release.apk
```

**APK Size:** 46.8MB

## Installation Steps on Phone

### Option 1: Uninstall Old Version First (Recommended)
1. **Uninstall the old app** from your phone
   - Go to Settings → Apps → Loagma CRM → Uninstall
   - OR long-press the app icon → Uninstall
2. **Transfer the new APK** to your phone
   - Via USB cable, Bluetooth, or cloud storage
3. **Install the new APK**
   - Open the APK file
   - Allow installation from unknown sources if prompted
   - Click Install

### Option 2: Update Over Existing App
1. **Transfer the new APK** to your phone
2. **Install the new APK**
   - Open the APK file
   - Click "Update" or "Install"
   - Android will recognize it as an update because:
     - Same package name: `com.example.loagma_crm`
     - Higher build number: 3 (was 2)

**Note:** Option 2 only works if:
- The package name is the same
- The new build number is higher
- The APK is signed with the same key

## Why Updates Weren't Showing Before

### Common Reasons:
1. **Same Version Number** - Android won't update if build number is the same
2. **Cache Issues** - Old build artifacts were being used
3. **Not Uninstalling** - Old app data was interfering

### What We Fixed:
✅ Ran `flutter clean` to remove old build artifacts
✅ Incremented version from `1.0.1+2` to `1.0.2+3`
✅ Built fresh release APK

## Verify New Version After Installation

### Check Version in App:
1. Open the app
2. Go to sidebar/drawer
3. Look at the bottom - should show "Version 1.0.2" (if you update the version display in code)

### Check in Android Settings:
1. Settings → Apps → Loagma CRM
2. Scroll down to "App details"
3. Should show version 1.0.2

## For Future Updates

### Always Follow These Steps:

1. **Update Version Number** in `pubspec.yaml`:
```yaml
# Increment build number each time
version: 1.0.3+4  # Next version
version: 1.0.4+5  # After that
# etc.
```

2. **Clean and Build**:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

3. **Uninstall Old App** (recommended for testing)

4. **Install New APK**

## Quick Commands for Next Time

```bash
# Navigate to project
cd loagma_crm

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### If Update Still Doesn't Show:

1. **Check Build Number:**
   - Open `pubspec.yaml`
   - Ensure the number after `+` is higher than before

2. **Completely Uninstall:**
   - Uninstall the app
   - Clear app data from Settings
   - Restart phone
   - Install new APK

3. **Check Package Name:**
   - Open `android/app/build.gradle`
   - Verify `applicationId "com.example.loagma_crm"`
   - Must be the same for updates

4. **Build Split APKs (if needed):**
```bash
flutter build apk --split-per-abi
```
This creates smaller APKs for different CPU architectures.

## Current Build Info

**Version Name:** 1.0.2
**Build Number:** 3
**APK Size:** 46.8MB
**Location:** `loagma_crm/build/app/outputs/flutter-apk/app-release.apk`

## Summary

✅ Version updated to 1.0.2+3
✅ Clean build completed
✅ Release APK generated successfully
✅ Ready to install on phone

**Next Steps:**
1. Transfer `app-release.apk` to your phone
2. Uninstall old version (recommended)
3. Install new APK
4. Verify updates are showing

**The new APK includes all recent updates:**
- Edit user functionality
- Employee dashboard for users without roles
- Toast confirmations for delete/logout
- Back button confirmation
- Fixed logout navigation errors
