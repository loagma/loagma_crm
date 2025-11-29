# 🔧 Salesman Fetching Issue - Fix Guide

## 🔍 Problem

Salesmen are not showing in the dropdown on the Map Task Assignment screen.

---

## ✅ Solutions

### Solution 1: Check API Configuration (Most Common)

The app is currently configured to use **production backend** (Render). If you're testing **locally**, you need to change this:

**File**: `loagma_crm/lib/services/api_config.dart`

**Change**:
```dart
static const bool useProduction = true; // ❌ Currently using production
```

**To**:
```dart
static const bool useProduction = false; // ✅ Use local backend
```

Then restart the app:
```bash
flutter run
```

---

### Solution 2: Verify Backend is Running

Make sure your backend server is running:

```bash
cd backend
npm run dev
```

You should see:
```
✅ Server running and accessible on http://0.0.0.0:5000
```

---

### Solution 3: Test API Endpoint Directly

Test if the endpoint works:

```bash
# Get your auth token first (login via app or Postman)
# Then test:

curl http://localhost:5000/task-assignments/salesmen \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Expected response:
```json
{
  "success": true,
  "salesmen": [
    {
      "id": "...",
      "name": "ramesh",
      "contactNumber": "...",
      "employeeCode": "000005",
      "email": "..."
    }
  ]
}
```

---

### Solution 4: Check Database for Salesmen

Run the test script to verify salesmen exist:

```bash
cd backend
node test-salesmen.js
```

Expected output:
```
✅ Salesmen in database:
1. ramesh (000005) - Roles: salesman
```

If no salesmen found, add salesman role to a user:

```bash
node add-salesman-role.js <userId>
```

---

### Solution 5: Check Authentication

The endpoint requires authentication. Make sure you're logged in:

1. Login to the app as Admin
2. Check if other features work (Account Master, etc.)
3. If other features don't work, there's an auth issue

---

### Solution 6: Check Console Logs

With the improved logging, check the console when the screen loads:

**Expected logs**:
```
🔍 Fetching salesmen from: http://localhost:5000/task-assignments/salesmen
📡 Response status: 200
📡 Response body: {"success":true,"salesmen":[...]}
✅ Salesmen data: {success: true, salesmen: [...]}
✅ Loaded 1 salesmen
```

**If you see errors**:
- `❌ Failed with status: 401` → Authentication issue
- `❌ Failed with status: 404` → Route not found
- `❌ Failed with status: 500` → Backend error
- `❌ Error fetching salesmen: ...` → Network or parsing error

---

## 🚀 Quick Fix Steps

### For Local Development:

1. **Change API config to local**:
   ```dart
   // loagma_crm/lib/services/api_config.dart
   static const bool useProduction = false;
   ```

2. **Start backend**:
   ```bash
   cd backend
   npm run dev
   ```

3. **Restart Flutter app**:
   ```bash
   flutter run
   ```

4. **Check logs** in console for any errors

---

### For Production (Render):

1. **Verify backend is deployed and running**:
   ```bash
   curl https://loagma-crm.onrender.com/health
   ```

2. **Check if route exists**:
   ```bash
   curl https://loagma-crm.onrender.com/task-assignments/salesmen \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

3. **If 404**, redeploy backend with new routes

---

## 🔍 Debugging Checklist

- [ ] Backend server is running
- [ ] API config points to correct URL (local vs production)
- [ ] User is logged in (has valid auth token)
- [ ] Salesman exists in database with correct role
- [ ] Route is registered in backend (`/task-assignments/salesmen`)
- [ ] No CORS errors in browser console
- [ ] Network request completes (check Network tab)

---

## 📝 Test Script Output

Run `node test-salesmen.js` to see:

```
🔍 Checking for salesmen in database...

📊 Total users in database: 5

👥 Salesmen found: 1

✅ Salesmen in database:
1. ramesh (000005) - Roles: salesman
```

---

## 🎯 Most Likely Issue

**API Configuration**: The app is set to use production backend, but you're testing locally.

**Fix**: Change `useProduction` to `false` in `api_config.dart`

---

## 📞 Still Not Working?

Check the console logs with the improved logging:

1. Open Flutter DevTools or terminal
2. Navigate to Map Task Assignment screen
3. Look for these logs:
   - `🔍 Fetching salesmen from: ...`
   - `📡 Response status: ...`
   - `📡 Response body: ...`

Share these logs to diagnose the issue.

---

**Last Updated**: November 29, 2025
