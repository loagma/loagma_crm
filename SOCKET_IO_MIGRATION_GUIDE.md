# Socket.IO Migration Guide - Step by Step

## Overview

Migrating from Firestore to Socket.IO for live tracking.

**Timeline**: 2-3 hours  
**Difficulty**: Intermediate  
**Downtime**: ~30 minutes (during deployment)

---

## Phase 1: Backend Setup (45 min)

### Step 1: Install Dependencies

```bash
cd backend
npm install socket.io
```

### Step 2: Create Socket Server

File already created: `backend/src/socket/socketServer.js`

### Step 3: Update Main Server

Replace `backend/src/server.js` with `backend/src/server-socket.js`:

```bash
# Backup old server
cp src/server.js src/server-old.js

# Use new socket server
cp src/server-socket.js src/server.js
```

### Step 4: Update package.json

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  }
}
```

### Step 5: Test Backend

```bash
# Start server
npm start

# Check health
curl http://localhost:3000/health

# Expected response:
# {
#   "status": "ok",
#   "connections": { "salesmen": 0, "admins": 0, "total": 0 }
# }
```

---

## Phase 2: Mobile App Setup (60 min)

### Step 1: Add Dependency

```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

```bash
cd loagma_crm
flutter pub get
```

### Step 2: Add Socket Service

File already created: `loagma_crm/lib/services/socket_tracking_service.dart`

### Step 3: Update Attendance Session Manager

```dart
// loagma_crm/lib/services/attendance_session_manager.dart

import 'socket_tracking_service.dart';

// Replace TrackingService with SocketTrackingService

// On punch-in:
await SocketTrackingService.instance.connect();
await SocketTrackingService.instance.startTracking(
  employeeId: employeeId,
  attendanceId: attendanceId,
  employeeName: employeeName,
);

// On punch-out:
await SocketTrackingService.instance.stopTracking();
await SocketTrackingService.instance.disconnect();
```

### Step 4: Remove Firestore Writes

Comment out or remove Firestore tracking writes:

```dart
// OLD CODE - Remove this:
// await _firestore
//     .collection('tracking_live')
//     .doc(employeeId)
//     .set(payload);

// NEW CODE - Already handled by SocketTrackingService
// (No code needed here)
```

### Step 5: Test Mobile App

```bash
flutter run

# Check logs for:
# 🔌 Connecting to Socket.IO: ws://your-server:3000
# ✅ Socket connected: abc123
# 🟢 Socket tracking started for 00028
# 📍 Location sent: 23.123456, 72.654321
```

---

## Phase 3: Admin Dashboard Setup (45 min)

### Step 1: Create Socket Live Tracking Screen

File already created: `loagma_crm/lib/screens/admin/socket_live_tracking_screen.dart`

### Step 2: Update Router

```dart
// loagma_crm/lib/router/app_router.dart

import '../screens/admin/socket_live_tracking_screen.dart';

GoRoute(
  path: 'tracking',
  builder: (_, __) => const SocketLiveTrackingScreen(),
),
```

### Step 3: Test Admin Dashboard

```bash
flutter run

# Navigate to Live Tracking
# Check logs for:
# 🔌 Admin connecting to Socket.IO: ws://your-server:3000
# ✅ Admin socket connected
# 📍 Location updated: 00028 (1 active)
```

---

## Phase 4: Testing (30 min)

### Test 1: Single User

1. Punch in as salesman
2. Open admin dashboard
3. Verify location appears on map
4. Verify updates every 5 seconds

### Test 2: Multiple Users

1. Punch in 3 salesmen
2. Open admin dashboard
3. Verify all 3 appear on map
4. Verify all update in real-time

### Test 3: Reconnection

1. Enable airplane mode on mobile
2. Wait 10 seconds
3. Disable airplane mode
4. Verify reconnection and updates resume

### Test 4: Multiple Admins

1. Open admin dashboard on 2 devices
2. Verify both receive updates
3. Verify no duplicate data

### Test 5: Battery Test

1. Run tracking for 1 hour
2. Check battery usage
3. Should be similar to Firestore version

---

## Phase 5: Deployment (30 min)

### Backend Deployment

```bash
# Build and deploy
cd backend
npm run build  # if using TypeScript
pm2 start src/server.js --name "tracking-server"

# Or with Docker
docker build -t tracking-server .
docker run -d -p 3000:3000 tracking-server
```

### Mobile App Deployment

```bash
cd loagma_crm

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Verify Production

```bash
# Check server health
curl https://your-domain.com/health

# Check socket status
curl https://your-domain.com/socket/status
```

---

## Rollback Plan

If issues occur, rollback to Firestore:

### Backend

```bash
# Restore old server
cp src/server-old.js src/server.js
npm start
```

### Mobile App

```dart
// Re-enable Firestore writes
await _firestore
    .collection('tracking_live')
    .doc(employeeId)
    .set(payload);

// Disable Socket.IO
// await SocketTrackingService.instance.stopTracking();
```

### Admin Dashboard

```dart
// Use old Firestore screen
import '../screens/admin/enhanced_live_tracking_screen.dart';

GoRoute(
  path: 'tracking',
  builder: (_, __) => const EnhancedLiveTrackingScreen(),
),
```

---

## Monitoring

### Server Logs

```bash
# View logs
pm2 logs tracking-server

# Or with Docker
docker logs -f tracking-server
```

### Key Metrics to Monitor

1. **Connection Count**: Should match active employees
2. **Update Frequency**: Should be ~1 per 5 seconds per employee
3. **Error Rate**: Should be < 1%
4. **Response Time**: Should be < 100ms
5. **Memory Usage**: Should be stable (no leaks)

### Alerts to Set Up

1. Server down
2. High error rate (> 5%)
3. High memory usage (> 80%)
4. No connections for > 5 minutes

---

## Performance Tuning

### If Updates Are Slow

1. Check server CPU usage
2. Check network latency
3. Reduce update frequency to 10 seconds
4. Increase movement threshold to 20 meters

### If Battery Usage Is High

1. Reduce GPS accuracy to `balanced`
2. Increase update interval to 10 seconds
3. Increase movement threshold to 20 meters
4. Disable background tracking when not needed

### If Server Is Overloaded

1. Scale vertically (more CPU/RAM)
2. Implement Redis adapter for horizontal scaling
3. Add load balancer
4. Optimize database queries

---

## Troubleshooting

### Mobile App Won't Connect

**Check**:
```dart
// Verify URL
print(ApiConfig.baseUrl); // Should be http://your-server:3000

// Verify token
print(UserService.token); // Should not be null

// Check connection status
print(SocketTrackingService.instance.isConnected); // Should be true
```

**Fix**:
1. Ensure server is running
2. Ensure JWT token is valid
3. Check network connectivity
4. Verify WebSocket port is open

### Admin Dashboard Not Receiving Updates

**Check**:
```dart
// Verify socket connection
print(_socket?.connected); // Should be true

// Check active employees
print(_activeEmployees.length); // Should match connected salesmen
```

**Fix**:
1. Verify admin is in admin-room
2. Check server logs for broadcasts
3. Verify JWT token has admin role
4. Restart admin dashboard

### Updates Are Delayed

**Check**:
- Server CPU usage
- Network latency
- Database query performance

**Fix**:
1. Optimize database indexes
2. Reduce payload size
3. Implement caching
4. Scale server resources

---

## Success Criteria

✅ **Migration is successful if**:

1. All salesmen can connect and send updates
2. All admins receive real-time updates
3. Updates appear within 5 seconds
4. Reconnection works automatically
5. Battery usage is acceptable
6. No data loss (all points in PostgreSQL)
7. Server is stable for 24 hours
8. Multiple admins can watch simultaneously

---

## Post-Migration

### Week 1: Monitor Closely

- Check logs daily
- Monitor server resources
- Collect user feedback
- Fix any issues immediately

### Week 2-4: Optimize

- Tune performance based on metrics
- Adjust thresholds if needed
- Implement additional features
- Document lessons learned

### Month 2+: Scale

- Add Redis adapter if needed
- Implement load balancing
- Add more monitoring
- Plan for growth

---

## Cost Analysis

### Before (Firestore)

- Firestore: $2-5/month
- PostgreSQL: $10/month (already have)
- **Total**: $12-15/month

### After (Socket.IO)

- Server: $5-10/month
- PostgreSQL: $10/month (already have)
- **Total**: $15-20/month

**Difference**: +$3-5/month, but with full control and better scalability

---

## Summary

### Timeline

- Backend setup: 45 min
- Mobile app: 60 min
- Admin dashboard: 45 min
- Testing: 30 min
- Deployment: 30 min
- **Total**: ~3 hours

### Benefits

✅ Full control over infrastructure  
✅ Better scalability (1000+ users)  
✅ Predictable costs  
✅ No vendor lock-in  
✅ Custom business logic  

### Trade-offs

⚠️ Server maintenance required  
⚠️ No built-in offline support  
⚠️ More code to maintain  
⚠️ Need DevOps knowledge  

---

*Ready to migrate? Follow the steps above and you'll be live with Socket.IO in ~3 hours!*
