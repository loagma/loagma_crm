# Fix Android Emulator DNS Issue

## Problem
Android emulator cannot resolve `loagma-crm.onrender.com` hostname.

## ✅ Solutions (Try in Order)

### Solution 1: Use Chrome/Physical Device (Recommended)

**The emulator has DNS issues. Use a real device or Chrome instead:**

```bash
# Run on Chrome (works perfectly)
cd loagma_crm
flutter run -d chrome

# Or on physical device
flutter run -d <device-id>
```

### Solution 2: Fix Emulator DNS

**Close emulator and restart with DNS fix:**

```bash
# Stop emulator completely
# Then start with custom DNS:
emulator -avd <your_avd_name> -dns-server 8.8.8.8,8.8.4.4
```

**Or in Android Studio:**
1. Tools → AVD Manager
2. Edit your emulator
3. Show Advanced Settings
4. Network → DNS Server: `8.8.8.8`
5. Save and restart

### Solution 3: Use Local Backend (Easiest)

**Switch to local backend temporarily:**

1. Start your local backend:
   ```bash
   cd backend
   npm run dev
   ```

2. Update `lib/services/api_config.dart`:
   ```dart
   static const bool useProduction = false;
   ```

3. Run app:
   ```bash
   flutter run
   ```

### Solution 4: Cold Boot Emulator

1. Close emulator
2. In Android Studio: Tools → AVD Manager
3. Click dropdown next to your emulator
4. Select "Cold Boot Now"
5. Wait for emulator to fully start
6. Run app again

### Solution 5: Recreate Emulator

If nothing works, create a new emulator:

1. Android Studio → Tools → AVD Manager
2. Create Virtual Device
3. Choose Pixel 6 or newer
4. Select latest Android version (API 34+)
5. Finish and start new emulator

### Solution 6: Use Physical Device

**Best option for testing:**

1. Enable USB Debugging on your phone
2. Connect via USB
3. Run:
   ```bash
   flutter devices
   flutter run -d <your-device-id>
   ```

## 🌐 Test Backend Accessibility

**From your computer (should work):**
```bash
curl https://loagma-crm.onrender.com/health
```

**From emulator (may fail):**
```bash
adb shell
ping loagma-crm.onrender.com
```

## 🎯 Recommended Approach

**For Development:**
```dart
// Use local backend
static const bool useProduction = false;
```

**For Testing Production:**
```bash
# Use Chrome or physical device
flutter run -d chrome
# or
flutter run -d <physical-device>
```

## 📱 Quick Commands

```bash
# List available devices
flutter devices

# Run on Chrome
flutter run -d chrome

# Run on specific device
flutter run -d <device-id>

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## ⚠️ Why This Happens

Android emulator has known DNS resolution issues:
- Uses different DNS than host machine
- May not resolve external domains properly
- Cloudflare/Render domains sometimes fail
- Local network (10.0.2.2) works fine

## ✅ Best Solution

**Use Chrome for testing production backend:**
```bash
flutter run -d chrome
```

Chrome uses your computer's DNS and will work perfectly with Render!

---

**Current Status:**
- ✅ Backend is UP and accessible
- ❌ Android emulator DNS issue
- ✅ Chrome/Physical device will work
- ✅ Local backend works on emulator
