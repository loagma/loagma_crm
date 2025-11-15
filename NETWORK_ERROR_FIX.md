# Network Error Fix - "Failed host lookup"

## Error
```
ClientException with SocketException: Failed host lookup: 'loagma-crm.onrender.com' 
(OS Error: No address associated with hostname, errno = 7)
```

## Root Cause
Yeh error tab aata hai jab:
1. **Internet connection nahi hai** - Device/Emulator offline hai
2. **DNS resolve nahi ho raha** - Hostname ko IP address mein convert nahi ho raha
3. **Firewall/Proxy blocking** - Network security rules block kar rahe hain
4. **Emulator network issue** - Android emulator ka network properly configured nahi hai

## Solutions

### Solution 1: Check Internet Connection ✅

**Android Emulator:**
1. Emulator settings mein jao
2. Settings → Network & Internet
3. WiFi ON hai check karo
4. Browser mein google.com khol ke test karo

**Physical Device:**
1. WiFi/Mobile data ON hai check karo
2. Browser mein koi website khol ke test karo
3. Airplane mode OFF hai check karo

### Solution 2: Restart Emulator/Device 🔄

**Android Emulator:**
```bash
# Emulator ko close karo aur phir se start karo
# Ya cold boot karo:
# AVD Manager → Your Device → Cold Boot Now
```

**Physical Device:**
```bash
# Device ko restart karo
# USB debugging reconnect karo
```

### Solution 3: Check DNS Resolution 🔍

**Test in Browser:**
1. Device/Emulator mein browser kholo
2. Yeh URL kholo: `https://loagma-crm.onrender.com/roles`
3. Agar response aata hai toh DNS working hai

**Expected Response:**
```json
{
  "success": true,
  "roles": [...]
}
```

### Solution 4: Add Internet Permission (Android) 📱

**File:** `android/app/src/main/AndroidManifest.xml`

Check karo yeh permission hai ya nahi:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add this line -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application ...>
        ...
    </application>
</manifest>
```

### Solution 5: Clear DNS Cache 🗑️

**Android Emulator:**
```bash
# Emulator mein:
Settings → Apps → Chrome/Browser → Storage → Clear Cache
```

**Or restart emulator with:**
```bash
flutter clean
flutter pub get
flutter run
```

### Solution 6: Use Local Backend (Temporary) 🏠

Agar deployed API se connect nahi ho raha, toh local backend use karo:

**Step 1:** Backend start karo
```bash
cd backend
npm run dev
```

**Step 2:** API config change karo
```dart
// In api_config.dart
static const bool useProduction = false;
```

**Step 3:** Hot restart
```bash
r
```

### Solution 7: Check Emulator Network Settings ⚙️

**Android Emulator Extended Controls:**
1. Emulator mein `...` (More) button click karo
2. Settings → Proxy
3. "No proxy" select karo
4. Apply karo

**Or:**
1. Settings → Cellular networks
2. Access Point Names
3. Reset to default

### Solution 8: Test with curl/Postman 🧪

**Terminal mein test karo:**
```bash
curl https://loagma-crm.onrender.com/roles
```

**Expected:**
```json
{"success":true,"roles":[...]}
```

**Agar yeh kaam karta hai but app mein nahi:**
- App ka network permission check karo
- Emulator restart karo
- Flutter clean karo

## Quick Fix Checklist

- [ ] Internet connection ON hai?
- [ ] Browser mein API URL khul raha hai?
- [ ] AndroidManifest.xml mein INTERNET permission hai?
- [ ] Emulator/Device restart kiya?
- [ ] Flutter clean kiya?
- [ ] Proxy settings check kiye?
- [ ] DNS working hai? (google.com khul raha hai?)

## Testing Steps

### Step 1: Test Internet
```bash
# Emulator/Device mein browser kholo
# google.com kholo
# Agar khul gaya → Internet working
```

### Step 2: Test API
```bash
# Browser mein kholo:
https://loagma-crm.onrender.com/roles

# Ya terminal mein:
curl https://loagma-crm.onrender.com/roles
```

### Step 3: Test App
```bash
# Hot restart
r

# Console logs dekho:
📡 Fetching roles from https://loagma-crm.onrender.com/roles
✅ Response status: 200
✅ Loaded 14 roles
```

## Common Issues

### Issue 1: "No address associated with hostname"
**Cause:** DNS not resolving
**Fix:** 
- Restart emulator
- Check internet
- Try different network (WiFi/Mobile data)

### Issue 2: "Connection refused"
**Cause:** Server not responding
**Fix:**
- Check if server is up: https://loagma-crm.onrender.com
- Server might be sleeping (Render free tier)
- Wait 30-60 seconds and retry

### Issue 3: "Connection timeout"
**Cause:** Network slow or blocked
**Fix:**
- Check firewall
- Try different network
- Increase timeout (already 30s)

## Current Configuration

**API Config:**
```dart
static const bool useProduction = true;
// Using: https://loagma-crm.onrender.com
```

**Timeout:**
```dart
.timeout(const Duration(seconds: 30))
```

**Headers:**
```dart
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## Recommended Solution

**For Development:**
```dart
// Use local backend
static const bool useProduction = false;
```

**For Testing Deployed API:**
1. Ensure internet is working
2. Test API in browser first
3. Restart emulator
4. Hot restart app
5. Wait up to 30 seconds

## Debug Commands

```bash
# Check Flutter doctor
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check device connectivity
flutter devices

# Hot restart
r

# Check logs
# Look for network errors
```

## Summary

✅ **Fixed:** Changed useProduction to true
⚠️ **Issue:** Network/DNS error
💡 **Solution:** 
1. Check internet connection
2. Restart emulator/device
3. Test API in browser
4. Or use local backend temporarily

**Most Common Fix:** Restart emulator aur internet check karo! 🔄
