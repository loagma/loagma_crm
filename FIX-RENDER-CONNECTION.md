# Fix Render Backend Connection Issue

## ✅ Backend is Working!

The backend at `https://loagma-crm.onrender.com` is accessible and responding correctly.

## 🔧 Fix DNS Resolution Issue

The error "No address associated with hostname" is a DNS caching issue on your device/emulator.

### Solution 1: Restart Emulator/Device (Quickest)

1. **Stop your Flutter app**
2. **Close the emulator completely**
3. **Restart the emulator**
4. **Run the app again**

### Solution 2: Clear DNS Cache on Emulator

**For Android Emulator:**
```bash
# Restart with DNS servers
flutter run --dart-define=FLUTTER_WEB_USE_SKIA=true
```

**Or manually in emulator:**
1. Open Settings
2. Go to Network & Internet
3. Toggle Airplane mode ON then OFF
4. Restart the app

### Solution 3: Use IP Address (Temporary)

If DNS still doesn't work, you can use Cloudflare's IP temporarily:

```dart
// In api_config.dart, temporarily change:
return 'https://loagma-crm.onrender.com';
// to use IP (not recommended for production):
return 'https://104.21.0.0'; // Example, get actual IP from nslookup
```

### Solution 4: Add Internet Permission (Android)

Make sure you have internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Solution 5: Clear App Data

```bash
flutter clean
flutter pub get
flutter run
```

## 🧪 Test Backend Connection

Run this to verify backend is accessible:

```bash
curl https://loagma-crm.onrender.com/health
```

Should return:
```json
{
  "success": true,
  "message": "Server is healthy"
}
```

## 📱 Quick Fix Steps

1. **Stop the app** (Ctrl+C in terminal)
2. **Close emulator**
3. **Restart emulator**
4. **Run app again:**
   ```bash
   cd loagma_crm
   flutter run
   ```

## ⚠️ Note About Render Free Tier

- Free tier services sleep after 15 minutes of inactivity
- First request after sleep takes 30-60 seconds to wake up
- This is normal behavior

## ✅ Verification

After restart, you should see:
```
I/flutter: 📡 Fetching roles from https://loagma-crm.onrender.com/roles
I/flutter: ✅ Response status: 200
I/flutter: ✅ Loaded X roles from backend
```

## 🔄 Toggle Between Local and Production

To switch back to local backend:

```dart
// In lib/services/api_config.dart
static const bool useProduction = false; // Local
static const bool useProduction = true;  // Render
```

---

**Current Status:** Backend is UP and responding ✅
**Issue:** DNS cache on emulator/device
**Fix:** Restart emulator
