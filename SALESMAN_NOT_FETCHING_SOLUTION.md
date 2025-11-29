# 🔧 Salesman Not Fetching - Complete Solution

## 🎯 The Issue

Salesmen are not showing in the dropdown on the Map Task Assignment screen.

---

## ✅ Root Cause & Solution

### **Most Likely Cause**: Backend Not Running or Wrong API URL

The app is configured to use **production backend** (https://loagma-crm.onrender.com), but you're testing **locally**.

---

## 🚀 Quick Fix (Choose One)

### Option A: Use Local Backend (Recommended for Development)

1. **Start your local backend**:
   ```bash
   cd backend
   npm run dev
   ```
   
   Wait for: `✅ Server running and accessible on http://0.0.0.0:5000`

2. **Change API config to local**:
   
   **File**: `loagma_crm/lib/services/api_config.dart`
   
   **Line 48**: Change from:
   ```dart
   static const bool useProduction = true;
   ```
   
   To:
   ```dart
   static const bool useProduction = false;
   ```

3. **Restart Flutter app**:
   ```bash
   # Stop current app (Ctrl+C)
   flutter run
   ```

4. **Test the feature**:
   - Login as Admin
   - Navigate to "Map Task Assignment"
   - Salesmen should now appear in dropdown

---

### Option B: Use Production Backend

If you want to use the deployed backend on Render:

1. **Verify backend is deployed**:
   ```bash
   curl https://loagma-crm.onrender.com/health
   ```

2. **Ensure task-assignments routes are deployed**:
   - Check if latest code is pushed to Render
   - Verify deployment completed successfully

3. **Keep production config**:
   ```dart
   static const bool useProduction = true; // Keep this
   ```

4. **Restart Flutter app**:
   ```bash
   flutter run
   ```

---

## 🔍 Verification Steps

### Step 1: Verify Backend is Running

**Local**:
```bash
curl http://localhost:5000/health
```

**Production**:
```bash
curl https://loagma-crm.onrender.com/health
```

Expected response:
```json
{
  "success": true,
  "message": "Server is healthy",
  "timestamp": "2025-11-29T..."
}
```

---

### Step 2: Verify Salesmen Exist in Database

```bash
cd backend
node test-salesmen.js
```

Expected output:
```
✅ Salesmen in database:
1. ramesh (000005) - Roles: salesman
```

**If no salesmen found**, add one:
```bash
node add-salesman-role.js <userId>
```

---

### Step 3: Test API Endpoint

**Get auth token** (login via app first), then:

```bash
# Local
curl http://localhost:5000/task-assignments/salesmen \
  -H "Authorization: Bearer YOUR_TOKEN"

# Production
curl https://loagma-crm.onrender.com/task-assignments/salesmen \
  -H "Authorization: Bearer YOUR_TOKEN"
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

### Step 4: Check Flutter Console Logs

With improved logging, you'll see:

**Success**:
```
🔍 Fetching salesmen from: http://localhost:5000/task-assignments/salesmen
📡 Response status: 200
📡 Response body: {"success":true,"salesmen":[...]}
✅ Salesmen data: {success: true, salesmen: [...]}
✅ Loaded 1 salesmen
```

**Failure**:
```
❌ Failed with status: 401  → Not logged in
❌ Failed with status: 404  → Route not found
❌ Failed with status: 500  → Backend error
❌ Error fetching salesmen: ... → Network error
```

---

## 📋 Complete Checklist

- [ ] Backend server is running (`npm run dev`)
- [ ] API config points to correct URL (local vs production)
- [ ] `useProduction` set correctly in `api_config.dart`
- [ ] User is logged in as Admin
- [ ] At least one salesman exists in database
- [ ] Route `/task-assignments/salesmen` is registered
- [ ] No CORS errors in console
- [ ] Auth token is valid

---

## 🎯 Most Common Issues & Fixes

### Issue 1: "Connection refused" or "Network error"
**Cause**: Backend not running  
**Fix**: Start backend with `npm run dev`

### Issue 2: "401 Unauthorized"
**Cause**: Not logged in or token expired  
**Fix**: Logout and login again

### Issue 3: "404 Not Found"
**Cause**: Route not registered or wrong URL  
**Fix**: 
- Check `backend/src/app.js` has `app.use('/task-assignments', taskAssignmentRoutes)`
- Verify API URL in `api_config.dart`

### Issue 4: Empty dropdown but no errors
**Cause**: No salesmen in database  
**Fix**: Run `node add-salesman-role.js <userId>`

### Issue 5: "Failed to fetch salesmen"
**Cause**: Wrong API URL (production vs local)  
**Fix**: Change `useProduction` in `api_config.dart`

---

## 🧪 Testing Commands

```bash
# 1. Check database for salesmen
cd backend
node test-salesmen.js

# 2. Add salesman role to user
node add-salesman-role.js <userId>

# 3. Test endpoint (requires backend running)
node test-endpoint.js

# 4. Start backend
npm run dev

# 5. Restart Flutter
cd ../loagma_crm
flutter run
```

---

## 📞 Still Not Working?

### Debug Steps:

1. **Check Flutter console** for error messages
2. **Check backend console** for incoming requests
3. **Check Network tab** in browser DevTools (if web)
4. **Verify auth token** is being sent in headers

### Share These Logs:

```
🔍 Fetching salesmen from: [URL]
📡 Response status: [STATUS]
📡 Response body: [BODY]
```

---

## ✅ Expected Behavior

When working correctly:

1. Open Map Task Assignment screen
2. Dropdown shows "Select Salesman"
3. Click dropdown
4. See list of salesmen: "ramesh (000005)"
5. Select salesman
6. Continue with pin code entry

---

## 🎉 Quick Summary

**Problem**: Salesmen not fetching  
**Most Likely Cause**: Using production URL but backend not deployed or local backend not running  
**Quick Fix**: Change `useProduction = false` in `api_config.dart` and start local backend  

---

**Last Updated**: November 29, 2025
