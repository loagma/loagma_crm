# Socket.IO Migration - Testing Checklist

## 🎯 Quick Start Testing Guide

**Date Started**: February 20, 2026  
**Backend Status**: ✅ Running on http://0.0.0.0:5000  
**Socket.IO Status**: ✅ Active (0 connections)

---

## ✅ Phase 1: Backend Verification (COMPLETED)

- [x] Backend server started successfully
- [x] Socket.IO initialized
- [x] Health endpoint responding: http://localhost:5000/health
- [x] Database connected (PostgreSQL via Prisma)

**Backend Process ID**: 5 (running in background)

---

## 📱 Phase 2: Mobile App Testing (NEXT STEPS)

### Test 2.1: Mobile App Connection (15 min)

**Prerequisites**:
- Backend running (already started ✅)
- Flutter app installed on device/emulator
- Salesman account credentials ready

**Steps**:

1. **Start Flutter App**
   ```bash
   cd loagma_crm
   flutter run
   ```

2. **Login as Salesman**
   - Open the app
   - Login with salesman credentials
   - Navigate to Dashboard

3. **Punch In**
   - Click "Punch In" button
   - Take photo
   - Enter bike KM
   - Submit

4. **Check Mobile Logs**
   Look for these messages in Flutter console:
   ```
   🔌 Connecting to Socket.IO: ws://10.0.2.2:5000
   ✅ Socket connected: [socket-id]
   🟢 Socket tracking started for [employee-id]
   📍 Location sent: [lat], [lng]
   ```

5. **Check Backend Logs**
   Backend should show:
   ```
   ✅ Socket authenticated: [employee-id] (salesman)
   🔌 Client connected: [socket-id] (User: [employee-id])
   📱 Salesman connected: [employee-id] (Total active: 1)
   📍 Location updated: [employee-id] ([lat], [lng])
   ```

6. **Verify Database**
   Check if tracking points are being saved:
   ```sql
   SELECT COUNT(*) FROM "SalesmanTrackingPoint" 
   WHERE "employeeId" = '[your-employee-id]' 
   AND "recordedAt" >= NOW() - INTERVAL '5 minutes';
   ```

**Expected Results**:
- [ ] Mobile app connects to Socket.IO
- [ ] Backend shows 1 salesman connected
- [ ] Location updates appear every 5 seconds
- [ ] Data saved to PostgreSQL
- [ ] No errors in logs

---

### Test 2.2: Admin Dashboard (10 min)

**Steps**:

1. **Open Admin Dashboard**
   - Login as admin (in browser or separate device)
   - Navigate to "Live Tracking"

2. **Check Connection Status**
   - Top-right corner should show "Connected" (green)
   - Backend logs should show:
     ```
     ✅ Socket authenticated: [admin-user] (admin)
     👔 Admin joined: [admin-user] (Total admins: 1)
     ```

3. **Verify Real-time Updates**
   - Salesman marker should appear on map
   - Marker should update every 5 seconds
   - Employee list should show salesman name
   - Can click on marker to select employee

4. **Check Backend Status**
   ```bash
   curl http://localhost:5000/socket/status
   ```
   Should return:
   ```json
   {
     "socketIO": "active",
     "connections": {
       "salesmen": 1,
       "admins": 1,
       "total": 2
     }
   }
   ```

**Expected Results**:
- [ ] Admin connects to Socket.IO
- [ ] Backend shows 1 admin + 1 salesman connected
- [ ] Salesman appears on map
- [ ] Marker updates in real-time
- [ ] Connection status shows "Connected"

---

### Test 2.3: Reconnection (10 min)

**Steps**:

1. **Simulate Network Loss**
   - On mobile device, enable Airplane Mode
   - Wait 10 seconds

2. **Check Logs**
   Mobile should show:
   ```
   🔌 Socket disconnected: transport close
   🔄 Socket reconnecting (attempt 1)
   ```

3. **Restore Network**
   - Disable Airplane Mode
   - Wait for automatic reconnection

4. **Verify Reconnection**
   Mobile should show:
   ```
   ✅ Socket connected: [new-socket-id]
   🟢 Socket tracking started for [employee-id]
   📍 Location sent: [lat], [lng]
   ```

**Expected Results**:
- [ ] Disconnection detected
- [ ] Automatic reconnection attempted
- [ ] Reconnection successful within 10 seconds
- [ ] Location updates resume
- [ ] No manual intervention needed

---

### Test 2.4: Punch Out (5 min)

**Steps**:

1. **Punch Out**
   - Go to Dashboard
   - Click "Punch Out"
   - Take photo
   - Enter bike KM
   - Submit

2. **Check Logs**
   Mobile should show:
   ```
   🔴 Socket tracking stopped
   🔌 Socket disconnected and disposed
   ```
   
   Backend should show:
   ```
   🔴 Session ended: [employee-id]
   🔌 Client disconnected: [socket-id] ([employee-id])
   ```

3. **Verify Admin Dashboard**
   - Salesman should disappear from map
   - Employee list should update
   - Connection count should decrease

**Expected Results**:
- [ ] Tracking stops on punch out
- [ ] Socket disconnects cleanly
- [ ] Salesman removed from admin dashboard
- [ ] Backend connection count correct
- [ ] No errors in logs

---

## 🔍 Phase 3: Advanced Testing (Optional)

### Test 3.1: Multiple Salesmen (15 min)

**Steps**:
1. Punch in 2-3 different salesmen
2. Verify all appear on admin dashboard
3. Check backend connection count
4. Verify all update independently

**Expected Results**:
- [ ] All salesmen connect successfully
- [ ] Backend shows correct count
- [ ] All appear on admin dashboard
- [ ] All update in real-time

---

### Test 3.2: Multiple Admins (10 min)

**Steps**:
1. Open admin dashboard on 2-3 devices/browsers
2. Verify all receive same updates
3. Check backend connection count

**Expected Results**:
- [ ] Multiple admins connect
- [ ] All receive same updates
- [ ] No performance issues

---

### Test 3.3: Movement Threshold (10 min)

**Steps**:
1. Punch in and stay in one place (< 10 meters)
2. Wait 30 seconds
3. Check logs for update frequency
4. Move > 10 meters
5. Verify updates resume

**Expected Results**:
- [ ] Updates skipped when not moving
- [ ] Updates resume when moving > 10m
- [ ] Battery usage optimized

---

## 🐛 Troubleshooting

### Issue: Mobile App Won't Connect

**Check**:
1. Backend is running: `curl http://localhost:5000/health`
2. API URL in `api_config.dart`:
   - Android Emulator: `http://10.0.2.2:5000`
   - Physical Device: `http://[your-local-ip]:5000`
3. JWT token is valid (login again if needed)
4. Network connectivity

**Fix**:
```dart
// In loagma_crm/lib/services/api_config.dart
static const bool useProduction = false; // Local testing
```

---

### Issue: No Location Updates

**Check**:
1. GPS permissions granted
2. Location services enabled
3. Movement > 10 meters
4. 5 seconds elapsed since last update

**Fix**:
- Grant location permissions
- Enable GPS
- Move around
- Check logs for errors

---

### Issue: Admin Dashboard Not Updating

**Check**:
1. Socket connection status (top-right corner)
2. Backend logs for broadcasts
3. Admin in admin-room

**Fix**:
1. Refresh admin dashboard
2. Check Socket.IO connection
3. Verify JWT token has admin role

---

## 📊 Success Criteria

Before declaring migration complete:

- [ ] Backend starts without errors
- [ ] Mobile app connects to Socket.IO
- [ ] Location updates sent every 5 seconds
- [ ] Admin dashboard receives real-time updates
- [ ] Multiple salesmen supported
- [ ] Automatic reconnection works
- [ ] Data saved to PostgreSQL
- [ ] No Firestore writes (migration complete)
- [ ] Battery usage acceptable (< 5%/hour)
- [ ] No memory leaks
- [ ] 24-hour stability test passed

---

## 📝 Test Results

### Test Session 1: February 20, 2026

| Test | Status | Notes |
|------|--------|-------|
| Backend Connection | ✅ | Running on port 5000 |
| Mobile Connection | ⬜ | Pending |
| Admin Dashboard | ⬜ | Pending |
| Reconnection | ⬜ | Pending |
| Punch Out | ⬜ | Pending |
| Multiple Users | ⬜ | Pending |
| Movement Threshold | ⬜ | Pending |

**Overall Status**: 🔄 In Progress

---

## 🚀 Next Steps

1. **Run Flutter App**
   ```bash
   cd loagma_crm
   flutter run
   ```

2. **Test Mobile Connection**
   - Login as salesman
   - Punch in
   - Check logs for Socket.IO connection

3. **Test Admin Dashboard**
   - Login as admin
   - Open Live Tracking
   - Verify real-time updates

4. **Complete All Tests**
   - Follow checklist above
   - Document any issues
   - Update test results table

---

## 📞 Support

If you encounter issues:

1. Check backend logs: Process ID 5 (running in background)
2. Check mobile logs: Flutter console
3. Check database: PostgreSQL `SalesmanTrackingPoint` table
4. Review documentation:
   - `SOCKET_IO_ARCHITECTURE.md`
   - `SOCKET_IO_MIGRATION_GUIDE.md`
   - `SOCKET_IO_TESTING_GUIDE.md`

---

*Last Updated: February 20, 2026 - 09:20 AM*
