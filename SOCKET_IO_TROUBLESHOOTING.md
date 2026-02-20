# Socket.IO Troubleshooting Guide

## 🔧 Common Issues and Fixes

---

## Issue 1: Admin Dashboard Disconnects Immediately

**Symptoms**:
```
🔌 Admin connecting to Socket.IO: ws://10.0.2.2:5000
🔌 Admin socket disconnected: io client disconnect
```

**Root Cause**: Using `ws://` URL instead of `http://` for Socket.IO client

**Fix Applied**: ✅ Updated both files to use `http://` URL
- `loagma_crm/lib/screens/admin/socket_live_tracking_screen.dart`
- `loagma_crm/lib/services/socket_tracking_service.dart`

**Why**: Socket.IO client library handles the WebSocket upgrade internally. You should always pass `http://` or `https://` URLs, not `ws://` or `wss://`.

**Correct Code**:
```dart
// ✅ CORRECT
final socketUrl = ApiConfig.baseUrl; // http://10.0.2.2:5000
_socket = IO.io(socketUrl, ...);

// ❌ WRONG
final socketUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws'); // ws://10.0.2.2:5000
_socket = IO.io(socketUrl, ...);
```

---

## Issue 2: Backend Port Already in Use

**Symptoms**:
```
Error: listen EADDRINUSE: address already in use 0.0.0.0:5000
```

**Fix**:
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID with actual process ID)
taskkill /F /PID [PID]

# Restart backend
cd backend
node src/server.js
```

**Prevention**: Always stop the backend properly before restarting

---

## Issue 3: Widget Lifecycle Error

**Symptoms**:
```
'package:flutter/src/widgets/framework.dart': Failed assertion: 
line 5343 pos 12: '_lifecycleState != _ElementLifecycle.defunct': is not true.
```

**Root Cause**: Calling `setState()` after widget is disposed

**Fix Applied**: ✅ Added `mounted` checks before all `setState()` calls

**Example**:
```dart
// ✅ CORRECT
if (mounted) {
  setState(() {
    _isConnected = true;
  });
}

// ❌ WRONG
setState(() {
  _isConnected = true;
});
```

---

## Issue 4: No Location Updates

**Symptoms**:
- Mobile app connected but no location updates
- Backend not receiving location data

**Possible Causes**:
1. GPS permissions not granted
2. Location services disabled
3. Movement < 10 meters (threshold)
4. Less than 5 seconds since last update (rate limit)

**Fix**:
```dart
// Check permissions
final permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  await Geolocator.requestPermission();
}

// Check location services
final enabled = await Geolocator.isLocationServiceEnabled();
if (!enabled) {
  // Show dialog to enable location
}
```

---

## Issue 5: Authentication Failed

**Symptoms**:
```
❌ Socket authentication failed: jwt malformed
```

**Possible Causes**:
1. JWT token expired
2. JWT token not set
3. Wrong JWT secret on backend

**Fix**:
```dart
// Check token
final token = UserService.token;
print('Token: $token'); // Should not be null

// If null, login again
if (token == null) {
  // Navigate to login screen
}
```

**Backend Check**:
```javascript
// In backend/src/socket/socketServer.js
console.log('JWT_SECRET:', process.env.JWT_SECRET);
```

---

## Issue 6: Admin Not Receiving Updates

**Symptoms**:
- Admin connected but map not updating
- No location updates appearing

**Possible Causes**:
1. Admin not in admin-room
2. Salesman not connected
3. Backend not broadcasting

**Debug Steps**:

1. **Check Backend Logs**:
   ```
   👔 Admin joined: [admin-user] (Total admins: 1)
   📱 Salesman connected: [employee-id] (Total active: 1)
   📍 Location updated: [employee-id] ([lat], [lng])
   ```

2. **Check Socket Status**:
   ```bash
   curl http://localhost:5000/socket/status
   ```
   Should show:
   ```json
   {
     "connections": {
       "salesmen": 1,
       "admins": 1,
       "total": 2
     }
   }
   ```

3. **Check Admin Console**:
   ```
   ✅ Admin socket connected
   📍 Location updated: [employee-id] (1 active)
   ```

---

## Issue 7: Reconnection Not Working

**Symptoms**:
- Airplane mode enabled
- Socket doesn't reconnect after network restored

**Expected Behavior**:
```
🔌 Socket disconnected: transport close
🔄 Socket reconnecting (attempt 1)
✅ Socket connected: [new-socket-id]
```

**Fix**:
```dart
// Check reconnection settings
_socket = IO.io(
  socketUrl,
  IO.OptionBuilder()
    .setReconnectionAttempts(5) // Max 5 attempts
    .setReconnectionDelay(3000) // 3 seconds between attempts
    .build(),
);
```

---

## Issue 8: High Battery Usage

**Symptoms**:
- Battery draining faster than expected
- More than 5% per hour

**Possible Causes**:
1. Movement threshold not working (sending too many updates)
2. Rate limiting not working
3. GPS accuracy set too high

**Fix**:

1. **Check Movement Threshold**:
   ```dart
   // Should skip updates < 10 meters
   if (_lastPosition != null) {
     final distance = Geolocator.distanceBetween(...);
     if (distance < 10) return; // Skip
   }
   ```

2. **Check Rate Limiting**:
   ```dart
   // Should enforce 5-second interval
   if (_lastSentTime != null &&
       now.difference(_lastSentTime!) < Duration(seconds: 5)) {
     return; // Skip
   }
   ```

3. **Adjust GPS Accuracy**:
   ```dart
   // In location_service.dart
   const LocationSettings locationSettings = LocationSettings(
     accuracy: LocationAccuracy.high, // Not 'best'
     distanceFilter: 10, // Only update if moved 10m
   );
   ```

---

## Issue 9: Database Not Saving Points

**Symptoms**:
- Backend receiving updates
- Database query returns 0 rows

**Debug**:
```sql
-- Check if table exists
SELECT * FROM "SalesmanTrackingPoint" LIMIT 1;

-- Check recent points
SELECT * FROM "SalesmanTrackingPoint" 
WHERE "recordedAt" >= NOW() - INTERVAL '1 hour'
ORDER BY "recordedAt" DESC;

-- Check for specific employee
SELECT COUNT(*) FROM "SalesmanTrackingPoint" 
WHERE "employeeId" = '00029';
```

**Possible Causes**:
1. Database connection lost
2. Prisma schema mismatch
3. Validation errors

**Fix**:
```bash
# Regenerate Prisma client
cd backend
npx prisma generate

# Check database connection
npx prisma db pull
```

---

## Issue 10: Multiple Connections from Same User

**Symptoms**:
- Backend shows multiple connections for same employee
- Duplicate location updates

**Possible Causes**:
1. Old socket not disconnected
2. Multiple app instances
3. Reconnection creating new socket

**Fix**:
```dart
// Always disconnect before connecting
await SocketTrackingService.instance.disconnect();
await SocketTrackingService.instance.connect();
```

**Backend Fix**:
```javascript
// Track connections by employeeId, not socketId
// Disconnect old socket when new one connects
if (activeConnections.has(employeeId)) {
  const oldSocket = activeConnections.get(employeeId);
  oldSocket.disconnect();
}
```

---

## 🔍 Debugging Tools

### 1. Backend Logs
```bash
# View real-time logs
# Backend is running as background process (ID: 8)
# Logs visible in Kiro terminal
```

### 2. Mobile Logs
```bash
# Flutter console shows all debug prints
flutter run

# Look for:
# 🔌 Socket events
# 📍 Location updates
# ❌ Errors
```

### 3. Network Inspector
```bash
# Chrome DevTools for admin dashboard
# Network tab → WS (WebSocket)
# Should show Socket.IO connection
```

### 4. Database Query
```sql
-- Check recent activity
SELECT 
  "employeeId",
  COUNT(*) as points,
  MAX("recordedAt") as last_update
FROM "SalesmanTrackingPoint"
WHERE "recordedAt" >= NOW() - INTERVAL '1 hour'
GROUP BY "employeeId";
```

---

## 📋 Pre-Flight Checklist

Before testing, verify:

- [ ] Backend running on port 5000
- [ ] Health check returns 200: `curl http://localhost:5000/health`
- [ ] Database connected
- [ ] JWT_SECRET set in backend .env
- [ ] API URL correct in `api_config.dart`
- [ ] Location permissions granted on mobile
- [ ] GPS enabled on mobile
- [ ] Network connectivity (mobile can reach backend)

---

## 🆘 Still Having Issues?

1. **Check Backend Logs**: Look for error messages
2. **Check Mobile Logs**: Look for connection errors
3. **Verify Network**: Can mobile reach backend?
   ```bash
   # On mobile browser, visit:
   http://10.0.2.2:5000/health
   ```
4. **Restart Everything**:
   ```bash
   # Stop backend
   # Stop Flutter app
   # Clear app data
   # Restart backend
   # Restart Flutter app
   ```

---

## 📚 Related Documentation

- `SOCKET_IO_QUICK_START.md` - Quick testing guide
- `SOCKET_IO_TESTING_CHECKLIST.md` - Comprehensive tests
- `SOCKET_IO_ARCHITECTURE.md` - System design
- `MIGRATION_STATUS.md` - Current progress

---

*Last Updated: February 20, 2026 - 09:35 AM*
