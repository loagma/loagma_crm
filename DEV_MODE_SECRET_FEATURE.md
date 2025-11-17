# 🔧 Secret Dev Mode Feature

## Problem Solved
Dev mode was only showing in debug builds (emulator) but not in release APK on physical devices.

## Solution Implemented
Added a **secret tap gesture** to enable dev mode in release builds!

## How to Enable Dev Mode in Release APK

### Step 1: Open the App
Launch the Loagma CRM app on your phone

### Step 2: Tap the Logo 5 Times
On the login screen, **tap the Loagma logo 5 times quickly**

### Step 3: Dev Mode Appears!
After 5 taps, you'll see:
- ✅ Toast message: "Dev Mode Enabled! 🔧"
- ✅ Dev mode section appears below the login form
- ✅ Role selection dropdown
- ✅ "Skip Login (Dev Mode)" button

## Visual Guide

```
┌─────────────────────────────┐
│                             │
│      [LOAGMA LOGO]          │  ← Tap here 5 times!
│                             │
│   Login or Signup           │
│                             │
│   [Phone Number Input]      │
│   [Next Button]             │
│                             │
│   ─────────────────────     │
│                             │
│   Dev Mode - Select Role    │  ← Appears after 5 taps
│   [Choose role dropdown]    │
│   [Skip Login (Dev Mode)]   │
│                             │
└─────────────────────────────┘
```

## Features

### Auto-Reset
- If you stop tapping for 3 seconds, the tap count resets
- You need to tap 5 times within 3 seconds

### One-Time Activation
- Once enabled, dev mode stays enabled for that session
- Closes when you restart the app
- Tap 5 times again to re-enable

### Works in Both Modes
- **Debug Mode (Emulator):** Dev mode shows automatically
- **Release Mode (Phone):** Tap logo 5 times to enable

## What You Can Do in Dev Mode

1. **Select Any Role**
   - Choose from: Admin, NSM, RSM, ASM, TSO, etc.
   - Test different role dashboards

2. **Skip Login**
   - No need to enter phone number
   - No OTP required
   - Instant access to dashboard

3. **Quick Testing**
   - Test features without backend
   - Switch between roles easily
   - Perfect for demos

## Technical Details

### Implementation
```dart
// State variables
bool showDevMode = kDebugMode; // Auto-show in debug
int logoTapCount = 0;
Timer? _tapResetTimer;

// Tap handler
void _onLogoTap() {
  logoTapCount++;
  
  // Reset after 3 seconds
  _tapResetTimer?.cancel();
  _tapResetTimer = Timer(Duration(seconds: 3), () {
    logoTapCount = 0;
  });
  
  // Enable after 5 taps
  if (logoTapCount >= 5 && !showDevMode) {
    showDevMode = true;
    _loadRoles();
    Fluttertoast.showToast(msg: "Dev Mode Enabled! 🔧");
  }
}
```

### Logo with Gesture
```dart
GestureDetector(
  onTap: _onLogoTap,
  child: Image.asset('assets/logo.png', width: 120, height: 120),
)
```

### Conditional Display
```dart
if (showDevMode) ...[
  // Dev mode UI
  Text('Dev Mode - Select Role'),
  DropdownButton(...),
  ElevatedButton('Skip Login (Dev Mode)'),
]
```

## New APK Build

**Version:** 1.0.2+3
**Size:** 46.8MB
**Location:** `loagma_crm/build/app/outputs/flutter-apk/app-release.apk`

**Includes:**
✅ Secret dev mode activation
✅ All previous features (logout fix, back button, etc.)
✅ Works on both emulator and physical devices

## Installation Steps

1. **Transfer APK** to your phone
2. **Uninstall old version** (recommended)
3. **Install new APK**
4. **Open app**
5. **Tap logo 5 times** to enable dev mode
6. **Select role** and click "Skip Login (Dev Mode)"

## Troubleshooting

### Dev Mode Not Appearing?
- Make sure you tap 5 times **quickly** (within 3 seconds)
- Tap directly on the logo image
- Look for the green toast: "Dev Mode Enabled! 🔧"

### Roles Not Loading?
- Check internet connection
- Backend must be running
- API endpoint: `https://loagma-crm.onrender.com/roles`

### Want to Disable Dev Mode?
- Restart the app
- Dev mode will be hidden again
- Tap 5 times to re-enable

## Security Note

This is a **hidden feature** for testing purposes:
- Not obvious to regular users
- Requires specific gesture (5 taps)
- Resets on app restart
- Perfect for demos and testing

## For Production Release

If you want to completely remove dev mode from production:

1. Remove the tap gesture
2. Change condition to:
```dart
if (false) ...[  // Never show
  // Dev mode UI
]
```

Or keep it as a secret feature for support/testing! 🎯

## Summary

✅ Dev mode now works in release APK
✅ Hidden behind secret gesture (5 taps on logo)
✅ Shows toast confirmation when enabled
✅ Auto-resets after 3 seconds of inactivity
✅ Perfect for testing and demos

**Tap the logo 5 times and enjoy dev mode on your phone! 🚀**
