# Roles API Troubleshooting Guide

## Issue
Flutter app timing out when fetching roles from remote server (https://loagma-crm.onrender.com/roles)

## Root Cause
The remote server on Render.com may have:
1. **Cold starts** - Takes 30-60 seconds to wake up if inactive
2. **Slow response times** - Free tier has limited resources
3. **Network latency** - Distance between client and server

## Solutions Implemented

### 1. Increased Timeout (30 seconds)
```dart
final response = await http.get(url).timeout(
  const Duration(seconds: 30),
  onTimeout: () {
    throw TimeoutException('Request timed out after 30 seconds');
  },
);
```

### 2. Added Proper Headers
```dart
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

### 3. Fallback Roles (Dev Mode Only)
If API fails in debug mode, uses hardcoded fallback roles:
```dart
roles = [
  {'id': 'admin', 'name': 'Admin'},
  {'id': 'nsm', 'name': 'NSM'},
  // ... etc
];
```

### 4. Enhanced CORS Configuration
```javascript
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
}));
```

### 5. Added Health Check Endpoint
```javascript
app.get('/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Server is healthy',
    timestamp: new Date().toISOString()
  });
});
```

## Testing Steps

### 1. Test API in Browser
Open: https://loagma-crm.onrender.com/roles

**Expected Response:**
```json
{
  "success": true,
  "roles": [
    {"id": "Admin", "name": "Admin", "createdAt": "..."},
    {"id": "NSM", "name": "NSM", "createdAt": "..."},
    ...
  ]
}
```

### 2. Test Health Check
Open: https://loagma-crm.onrender.com/health

**Expected Response:**
```json
{
  "success": true,
  "message": "Server is healthy",
  "timestamp": "2025-11-15T..."
}
```

### 3. Test in Flutter App
1. Hot restart the app
2. Watch console logs:
   ```
   📡 Fetching roles from https://loagma-crm.onrender.com/roles
   ✅ Response status: 200
   📦 Response body: {"success":true,"roles":[...]}
   ✅ Loaded 14 roles
   ```

## Workarounds

### Option 1: Use Local Backend (Recommended for Development)
Update `loagma_crm/lib/services/api_config.dart`:
```dart
static const bool useProduction = false; // Change to false
```

Then run local backend:
```bash
cd backend
npm run dev
```

### Option 2: Wake Up Remote Server First
Before using the app:
1. Open https://loagma-crm.onrender.com/health in browser
2. Wait for response (may take 30-60 seconds on first request)
3. Then use the Flutter app

### Option 3: Use Fallback Roles
The app now automatically uses fallback roles in dev mode if API fails.

## Debugging

### Check Console Logs
Look for these messages:
```
📡 Fetching roles from ...
✅ Response status: 200
📦 Response body: ...
✅ Loaded X roles
```

Or error messages:
```
❌ Error fetching roles: TimeoutException
⚠️ Using fallback roles
```

### Test API Manually
Using curl:
```bash
curl -X GET https://loagma-crm.onrender.com/roles \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

Using Postman:
- Method: GET
- URL: https://loagma-crm.onrender.com/roles
- Headers:
  - Content-Type: application/json
  - Accept: application/json

## Production Recommendations

### 1. Use Paid Hosting
Free tier on Render has:
- Cold starts (30-60s delay)
- Limited resources
- Automatic sleep after inactivity

**Upgrade to:**
- Render Starter ($7/month) - No cold starts
- Or use AWS/GCP/Azure

### 2. Implement Caching
Cache roles locally in Flutter:
```dart
// Save to SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('cached_roles', jsonEncode(roles));

// Load from cache first
final cachedRoles = prefs.getString('cached_roles');
if (cachedRoles != null) {
  roles = jsonDecode(cachedRoles);
}
```

### 3. Add Loading States
Show user-friendly messages:
```dart
if (isLoadingRoles) {
  return Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 10),
        Text('Loading roles from server...'),
        Text('This may take up to 30 seconds'),
      ],
    ),
  );
}
```

### 4. Implement Retry Logic
```dart
Future<void> fetchRolesWithRetry({int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      await fetchRoles();
      return; // Success
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
}
```

## Current Status

✅ **Fixed:**
- Increased timeout to 30 seconds
- Added proper headers
- Enhanced CORS configuration
- Added fallback roles for dev mode
- Better error logging

⚠️ **Known Issues:**
- Remote server (Render free tier) has cold starts
- First request may take 30-60 seconds
- Subsequent requests are fast

💡 **Recommendation:**
Use local backend for development:
```dart
// In api_config.dart
static const bool useProduction = false;
```

## Quick Fix Summary

**Files Updated:**
1. `loagma_crm/lib/screens/login_screen.dart`
   - Increased timeout to 30s
   - Added headers
   - Added fallback roles
   - Better error handling

2. `loagma_crm/lib/screens/admin/create_user_screen.dart`
   - Increased timeout to 30s
   - Added headers
   - Better error messages

3. `backend/src/app.js`
   - Enhanced CORS configuration
   - Added health check endpoint

**Next Steps:**
1. Hot restart Flutter app
2. Wait up to 30 seconds for first request
3. Check console logs
4. If still failing, switch to local backend

## Support

If issues persist:
1. Check backend logs on Render dashboard
2. Verify database connection
3. Test API endpoints manually
4. Switch to local backend for development
