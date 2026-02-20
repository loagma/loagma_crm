# Socket.IO Migration - Testing Guide

## 🧪 Complete Testing Procedure

---

## Prerequisites

### 1. Backend Running
```bash
cd backend
node src/server.js

# Should see:
# ✅ Server running on http://0.0.0.0:5000
# 🚀 Socket.IO server initialized
```

### 2. Check Backend Health
```bash
curl http://localhost:5000/health

# Expected response:
# {
#   "success": true,
#   "socketIO": {
#     "active": true,
#     "connections": {"salesmen": 0, "admins": 0, "total": 0}
#   }
# }
```

---

## Test 1: Mobile App Connection (15 min)

### Step 1: Start Mobile App
```bash
cd loagma_crm
flutter run
```

### Step 2: Login as Salesman
- Username: Your salesman account
- Password: Your password

### Step 3: Punch In
1. Go to Dashboard
2. Click "Punch In"
3. Take photo
4. Enter bike KM
5. Submit

### Step 4: Check Logs

**Mobile App Logs** (look for):
```
🔌 Connecting to Socket.IO: ws://your-server:5000
✅ Socket connected: abc123
🟢 Socket tracking started for 00028
📍 Location sent: 23.123456, 72.654321
```

**Backend Logs** (look for):
```
✅ Socket authenticated: 00028 (salesman)
🔌 Client connected: abc123 (User: 00028)
📱 Salesman connected: 00028 (Total active: 1)
📍 Location updated: 00028 (23.123456, 72.654321)
```

### Step 5: Verify Database
```sql
-- Check if points are being saved
SELECT COUNT(*) FROM "SalesmanTrackingPoint" 
WHERE "employeeId" = '00028' 
AND "recordedAt" >= NOW() - INTERVAL '5 minutes';

-- Should show multiple points (1 every 5 seconds)
```

### ✅ Success Criteria
- [ ] Mobile app connects to Socket.IO
- [ ] Backend shows 1 salesman connected
- [ ] Location updates appear in logs every 5 seconds
- [ ] Data saved to PostgreSQL
- [ ] No errors in logs

---

## Test 2: Admin Dashboard (10 min)

### Step 1: Open Admin Dashboard
1. Login as admin
2. Go to "Live Tracking"

### Step 2: Check Connection

**Admin Logs** (look for):
```
🔌 Admin connecting to Socket.IO: ws://your-server:5000
✅ Admin socket connected
```

**Backend Logs** (look for):
```
✅ Socket authenticated: admin-user (admin)
👔 Admin joined: admin-user (Total admins: 1)
```

### Step 3: Verify Real-time Updates
1. Check if salesman appears on map
2. Watch for marker updates (every 5 seconds)
3. Verify connection status shows "Connected"

### Step 4: Check Backend Status
```bash
curl http://localhost:5000/socket/status

# Expected:
# {
#   "socketIO": "active",
#   "connections": {
#     "salesmen": 1,
#     "admins": 1,
#     "total": 2
#   }
# }
```

### ✅ Success Criteria
- [ ] Admin connects to Socket.IO
- [ ] Backend shows 1 admin connected
- [ ] Salesman marker appears on map
- [ ] Marker updates in real-time
- [ ] Connection status shows "Connected"

---

## Test 3: Multiple Salesmen (15 min)

### Step 1: Punch In Multiple Salesmen
- Use 2-3 different salesman accounts
- Punch in on different devices/emulators

### Step 2: Check Backend
```bash
curl http://localhost:5000/socket/status

# Expected:
# {
#   "connections": {
#     "salesmen": 3,
#     "admins": 1,
#     "total": 4
#   }
# }
```

### Step 3: Verify Admin Dashboard
1. All 3 salesmen appear on map
2. All markers update independently
3. Can select each salesman
4. Employee list shows all 3

### ✅ Success Criteria
- [ ] All salesmen connect successfully
- [ ] Backend shows correct count
- [ ] All appear on admin dashboard
- [ ] All update in real-time
- [ ] No performance issues

---

## Test 4: Reconnection (10 min)

### Step 1: Simulate Network Loss
1. On mobile device, enable Airplane Mode
2. Wait 10 seconds

### Step 2: Check Logs

**Mobile Logs** (should see):
```
🔌 Socket disconnected: transport close
🔄 Socket reconnecting (attempt 1)
```

**Backend Logs** (should see):
```
🔌 Client disconnected: abc123 (00028) - Reason: transport close
```

### Step 3: Restore Network
1. Disable Airplane Mode
2. Wait for reconnection

### Step 4: Verify Reconnection

**Mobile Logs** (should see):
```
✅ Socket connected: xyz789
🟢 Socket tracking started for 00028
📍 Location sent: 23.123456, 72.654321
```

**Backend Logs** (should see):
```
🔌 Client connected: xyz789 (User: 00028)
📱 Salesman connected: 00028 (Total active: 1)
```

### ✅ Success Criteria
- [ ] Disconnection detected
- [ ] Automatic reconnection attempted
- [ ] Reconnection successful
- [ ] Location updates resume
- [ ] No manual intervention needed

---

## Test 5: Punch Out (5 min)

### Step 1: Punch Out
1. Go to Dashboard
2. Click "Punch Out"
3. Take photo
4. Enter bike KM
5. Submit

### Step 2: Check Logs

**Mobile Logs** (should see):
```
🔴 Socket tracking stopped
🔌 Socket disconnected and disposed
```

**Backend Logs** (should see):
```
🔴 Session ended: 00028
🔌 Client disconnected: abc123 (00028)
```

### Step 3: Verify Admin Dashboard
1. Salesman should disappear from map
2. Employee list should update
3. Connection count should decrease

### Step 4: Check Backend
```bash
curl http://localhost:5000/socket/status

# Expected:
# {
#   "connections": {
#     "salesmen": 0,  // Decreased
#     "admins": 1,
#     "total": 1
#   }
# }
```

### ✅ Success Criteria
- [ ] Tracking stops on punch out
- [ ] Socket disconnects cleanly
- [ ] Salesman removed from admin dashboard
- [ ] Backend connection count correct
- [ ] No errors in logs

---

## Test 6: Movement Threshold (10 min)

### Step 1: Stay in One Place
1. Punch in
2. Don't move (< 10 meters)
3. Wait 30 seconds

### Step 2: Check Logs
- Should see fewer updates (threshold filtering)
- Backend should skip updates < 10 meters

### Step 3: Move Significantly
1. Walk > 10 meters
2. Check logs

### Step 4: Verify Updates Resume
- Should see location updates again
- Backend should accept updates

### ✅ Success Criteria
- [ ] Updates skipped when not moving
- [ ] Updates resume when moving > 10m
- [ ] Battery usage optimized
- [ ] No unnecessary database writes

---

## Test 7: Rate Limiting (5 min)

### Step 1: Check Update Frequency
1. Monitor logs for 1 minute
2. Count location updates

### Step 2: Verify Interval
- Should be ~12 updates per minute (1 every 5 seconds)
- Not more frequent

### ✅ Success Criteria
- [ ] Updates sent every 5 seconds
- [ ] No more frequent updates
- [ ] Rate limiting working

---

## Test 8: Battery Usage (1 hour)

### Step 1: Full Battery Test
1. Charge device to 100%
2. Punch in
3. Run tracking for 1 hour
4. Check battery usage

### Step 2: Compare with Firestore
- Should be similar or better
- Target: < 5% battery per hour

### ✅ Success Criteria
- [ ] Battery usage acceptable
- [ ] Similar to Firestore version
- [ ] No excessive drain

---

## Test 9: Data Integrity (10 min)

### Step 1: Track for 10 Minutes
1. Punch in
2. Move around
3. Wait 10 minutes

### Step 2: Check Database
```sql
SELECT COUNT(*) FROM "SalesmanTrackingPoint" 
WHERE "employeeId" = '00028' 
AND "recordedAt" >= NOW() - INTERVAL '10 minutes';

-- Should show ~120 points (1 every 5 seconds)
```

### Step 3: Verify Data Quality
```sql
SELECT * FROM "SalesmanTrackingPoint" 
WHERE "employeeId" = '00028' 
ORDER BY "recordedAt" DESC 
LIMIT 10;

-- Check:
-- - Coordinates are valid
-- - Timestamps are sequential
-- - No duplicates
-- - Accuracy values present
```

### ✅ Success Criteria
- [ ] All points saved to database
- [ ] No data loss
- [ ] Coordinates valid
- [ ] Timestamps correct

---

## Test 10: Multiple Admins (10 min)

### Step 1: Open Multiple Admin Dashboards
- Open on 2-3 different devices/browsers
- All as admin users

### Step 2: Verify All Receive Updates
1. All should show same salesmen
2. All should update simultaneously
3. No lag or delay

### Step 3: Check Backend
```bash
curl http://localhost:5000/socket/status

# Expected:
# {
#   "connections": {
#     "salesmen": 1,
#     "admins": 3,  // Multiple admins
#     "total": 4
#   }
# }
```

### ✅ Success Criteria
- [ ] Multiple admins connect
- [ ] All receive same updates
- [ ] No performance degradation
- [ ] Backend handles multiple admins

---

## 🐛 Troubleshooting

### Issue: Mobile App Won't Connect

**Check**:
```dart
// In socket_tracking_service.dart
print(ApiConfig.baseUrl); // Should be http://your-server:5000
print(UserService.token); // Should not be null
```

**Fix**:
1. Verify backend is running
2. Check API URL in `api_config.dart`
3. Verify JWT token is valid
4. Check network connectivity

### Issue: No Location Updates

**Check**:
- GPS permissions granted
- Location services enabled
- Movement > 10 meters
- 5 seconds elapsed since last update

**Fix**:
1. Grant location permissions
2. Enable GPS
3. Move around
4. Check logs for errors

### Issue: Admin Dashboard Not Updating

**Check**:
- Socket connection status
- Backend logs for broadcasts
- Admin in admin-room

**Fix**:
1. Refresh admin dashboard
2. Check Socket.IO connection
3. Verify JWT token has admin role
4. Check backend logs

---

## 📊 Performance Metrics

### Target Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Connection Time | < 2s | ___ |
| Update Latency | < 100ms | ___ |
| Battery Usage | < 5%/hour | ___ |
| Memory Usage | < 100MB | ___ |
| CPU Usage | < 10% | ___ |
| Data Usage | < 1MB/hour | ___ |

### Fill in Actual Values During Testing

---

## ✅ Final Checklist

Before declaring migration successful:

- [ ] All 10 tests passed
- [ ] No errors in logs
- [ ] Performance metrics met
- [ ] Battery usage acceptable
- [ ] Data integrity verified
- [ ] Multiple users supported
- [ ] Reconnection works
- [ ] Admin dashboard functional
- [ ] No Firestore writes (migration complete)
- [ ] 24-hour stability test passed

---

## 📝 Test Results

### Date: _______________
### Tester: _______________

| Test | Status | Notes |
|------|--------|-------|
| 1. Mobile Connection | ⬜ | |
| 2. Admin Dashboard | ⬜ | |
| 3. Multiple Salesmen | ⬜ | |
| 4. Reconnection | ⬜ | |
| 5. Punch Out | ⬜ | |
| 6. Movement Threshold | ⬜ | |
| 7. Rate Limiting | ⬜ | |
| 8. Battery Usage | ⬜ | |
| 9. Data Integrity | ⬜ | |
| 10. Multiple Admins | ⬜ | |

**Overall Result**: ⬜ Pass / ⬜ Fail

---

*Ready to test? Start with Test 1 and work through each test systematically!*
