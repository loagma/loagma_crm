# 🔄 REBUILD FLUTTER APP

## The Issue

Hot restart (`R`) doesn't pick up changes to `const` values like `useProduction`.

Your app is still using the old cached value: `useProduction = true`

## The Solution

You need to **STOP and REBUILD** the app completely.

---

## Option 1: Stop and Rebuild (Recommended)

### In your Flutter terminal:

1. **Stop the app:**
   - Press `q` to quit

2. **Rebuild and run:**
   ```bash
   flutter run
   ```

---

## Option 2: Full Clean Rebuild (If Option 1 doesn't work)

```bash
flutter clean
flutter pub get
flutter run
```

---

## Option 3: Quick Command (Windows)

Stop the current Flutter process (Ctrl+C), then:

```bash
cd loagma_crm
flutter run
```

---

## What You'll See After Rebuild

### Before (Old - Still calling production):
```
I/flutter: 📡 POST https://loagma-crm.onrender.com/auth/send-otp
I/flutter: ✅ Response 500: {"success":false,...}
```

### After (New - Calling local backend):
```
I/flutter: 📡 POST http://10.0.2.2:5000/auth/send-otp
I/flutter: ✅ Response 200: {"success":true,...}
```

---

## Verification

After rebuild, when you click "Send OTP", you should see:

1. **Flutter console:**
   ```
   📡 POST http://10.0.2.2:5000/auth/send-otp
   ```

2. **Backend console (Terminal 1):**
   ```
   📱 OTP: 1234
   ```

---

## Quick Steps

1. ✅ Make sure backend is running: `cd backend && npm run dev`
2. ✅ Stop Flutter: Press `q` in Flutter terminal
3. ✅ Rebuild: `flutter run`
4. ✅ Test OTP: Click "Send OTP"
5. ✅ Check backend console for OTP

---

**Status:** Config is correct, just needs rebuild!
