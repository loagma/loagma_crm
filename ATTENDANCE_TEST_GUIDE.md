# Attendance System Testing Guide

## Quick Test Scenarios

### 1. Duration Calculation Test
**Scenario**: Verify correct duration display
**Steps**:
1. Open the app and navigate to Attendance/Punch screen
2. Punch in at a specific time (note the exact time)
3. Wait for 1-2 minutes and observe the duration counter
4. Verify it updates every second and shows correct elapsed time
5. Check the dashboard also shows the same duration

**Expected Result**: 
- Duration starts at 00:00:00 and increments every second
- After 1 minute, should show 00:01:00
- Dashboard and punch screen show identical durations

### 2. Location Permission Test
**Scenario**: Test WhatsApp-style location permissions
**Steps**:
1. Fresh install or clear app data
2. Open attendance screen for first time
3. Observe the location permission dialog
4. Grant permissions and verify location tracking starts
5. Check for "Live Location Active" indicator

**Expected Result**:
- Professional permission dialog appears
- Clear explanation of location usage
- Location tracking starts after permission granted
- Live location indicator shows when active

### 3. Live Location Tracking Test
**Scenario**: Verify continuous location updates
**Steps**:
1. Punch in successfully
2. Move around (walk 50+ meters)
3. Check if location coordinates update in the location info section
4. Verify location stream is working

**Expected Result**:
- Location coordinates change as you move
- Updates occur approximately every 10 meters
- No excessive battery drain

### 4. Complete Work Day Test
**Scenario**: Full punch in/out cycle
**Steps**:
1. Punch in at start of day
2. Work for several hours (or simulate with time change)
3. Punch out at end of day
4. Verify total duration calculation
5. Check attendance history

**Expected Result**:
- Accurate total work duration
- Proper punch in/out times recorded
- History shows correct data

## Debug Information

### Duration Calculation Debug
Add these debug prints to verify calculations:

```dart
// In _getCurrentDurationText() method
print('🕐 Debug Duration Calculation:');
print('   isPunchedIn: $isPunchedIn');
print('   punchInTime: $punchInTime');
print('   punchOutTime: $punchOutTime');
print('   currentTime: ${DateTime.now()}');
if (isPunchedIn && punchInTime != null) {
  final duration = DateTime.now().difference(punchInTime!);
  print('   calculated duration: ${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s');
}
```

### Location Tracking Debug
Add these prints to verify location updates:

```dart
// In LocationService
locationService.locationStream.listen((Position position) {
  print('📍 Location Update:');
  print('   Lat: ${position.latitude}');
  print('   Lng: ${position.longitude}');
  print('   Accuracy: ${position.accuracy}m');
  print('   Time: ${DateTime.now()}');
});
```

## Common Issues & Solutions

### Issue 1: Duration Still Shows Wrong Time
**Possible Causes**:
- Backend returning incorrect data
- Timezone mismatch
- DateTime parsing issues

**Debug Steps**:
1. Check device timezone settings
2. Verify backend API response format
3. Add debug prints to see raw data
4. Test with manual time calculation

**Solution**:
```dart
// Force local time calculation
final now = DateTime.now();
final punchIn = DateTime.parse(attendance.punchInTime.toIso8601String()).toLocal();
final duration = now.difference(punchIn);
```

### Issue 2: Location Permission Denied
**Possible Causes**:
- User denied permission
- Device location services disabled
- App-level permission issues

**Debug Steps**:
1. Check device Settings > Privacy > Location Services
2. Verify app has location permission in device settings
3. Test location permission request flow
4. Check for permission_handler package issues

**Solution**:
```dart
// Manual permission check
final status = await Permission.location.status;
print('Location permission status: $status');
if (status.isDenied) {
  final result = await Permission.location.request();
  print('Permission request result: $result');
}
```

### Issue 3: Location Not Updating
**Possible Causes**:
- GPS signal weak (indoors)
- Location service not started
- Stream subscription issues
- Battery optimization killing background location

**Debug Steps**:
1. Test outdoors with clear GPS signal
2. Check if location service is running
3. Verify stream subscription is active
4. Check device battery optimization settings

**Solution**:
```dart
// Force location update
final position = await Geolocator.getCurrentPosition(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  ),
);
```

## Performance Testing

### Battery Usage Test
**Steps**:
1. Fully charge device
2. Start attendance tracking
3. Use normally for 8 hours
4. Check battery usage in device settings

**Expected**: Location tracking should use <5% of battery per day

### Memory Usage Test
**Steps**:
1. Open Flutter DevTools
2. Start attendance tracking
3. Monitor memory usage over time
4. Check for memory leaks

**Expected**: Memory usage should remain stable, no continuous growth

### Network Usage Test
**Steps**:
1. Monitor network requests during attendance
2. Check frequency of location updates sent to server
3. Verify no excessive API calls

**Expected**: Minimal network usage, only necessary API calls

## Production Deployment Checklist

### Before Release:
- [ ] Remove all debug print statements
- [ ] Test on multiple device types (Android/iOS)
- [ ] Verify location permissions work on different OS versions
- [ ] Test with poor GPS signal conditions
- [ ] Verify battery optimization doesn't break location tracking
- [ ] Test timezone handling for different regions
- [ ] Verify duration calculations with various time ranges
- [ ] Test offline functionality (location caching)

### Post-Release Monitoring:
- [ ] Monitor crash reports related to location services
- [ ] Track user feedback on duration accuracy
- [ ] Monitor battery usage complaints
- [ ] Check location permission grant rates
- [ ] Verify attendance data accuracy in backend

## API Testing

### Test Attendance Endpoints:
```bash
# Test punch in
curl -X POST "http://your-api/attendance/punch-in" \
  -H "Content-Type: application/json" \
  -d '{
    "employeeId": "test123",
    "employeeName": "Test User",
    "punchInLatitude": 28.6139,
    "punchInLongitude": 77.2090,
    "punchInPhoto": "base64...",
    "bikeKmStart": "12345"
  }'

# Test get today's attendance
curl -X GET "http://your-api/attendance/today/test123"

# Test punch out
curl -X POST "http://your-api/attendance/punch-out" \
  -H "Content-Type: application/json" \
  -d '{
    "attendanceId": "attendance123",
    "punchOutLatitude": 28.6140,
    "punchOutLongitude": 77.2091,
    "punchOutPhoto": "base64...",
    "bikeKmEnd": "12367"
  }'
```

### Verify API Response Format:
```json
{
  "success": true,
  "data": {
    "id": "attendance123",
    "employeeId": "test123",
    "punchInTime": "2024-12-10T09:39:00.000Z",
    "punchOutTime": "2024-12-10T15:11:32.000Z",
    "totalWorkHours": 5.54,
    "status": "completed"
  }
}
```

---

**Testing Priority**: High
**Estimated Testing Time**: 2-3 hours
**Required Devices**: Android + iOS (minimum)