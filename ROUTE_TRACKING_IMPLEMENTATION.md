# Route Tracking & KM Tracking Implementation

## Overview
Complete implementation of map route tracking with kilometer tracking for salesmen, using WebSocket for real-time updates and REST API for backup storage.

## Key Features

### 1. Home Location Marking
- First GPS point is automatically marked as "home location" when salesman starts tracking
- Home location is stored in database with `isHomeLocation: true` flag
- Displayed with a special marker (blue/violet) on the map

### 2. Real-time Route Tracking via WebSocket
- Salesman app sends GPS coordinates every 3 seconds via WebSocket
- Server broadcasts location updates to all connected admins
- Route polyline is drawn on map as salesman moves in real-time
- Distance filtering (10m minimum) to avoid GPS noise

### 3. Kilometer Tracking
- Total distance calculated using Haversine formula
- Distance is calculated both on server and client side
- Real-time distance updates sent via WebSocket to admin dashboard
- Historical routes include total distance traveled

### 4. Historical Routes with Full Graph
- View past routes by date with complete route visualization
- Each route shows: home location, start/end points, total distance, duration
- Full polyline drawn from all GPS points (not just preview)
- Date picker to select specific dates

### 5. Deduplication
- Backend prevents duplicate points from REST API and WebSocket
- Points within 5 seconds and 10 meters are skipped
- Ensures clean route data without redundant points

## Complete Data Flow

### Salesman App Flow:
1. Salesman punches in → `AttendanceService.punchIn()`
2. Route tracking starts → `RouteTrackingService.startRouteTracking(attendanceId)`
3. WebSocket connects → `LiveLocationSocket.startTracking()`
4. First location sent with `isHomeLocation: true`
5. Subsequent locations sent every 3 seconds via WebSocket
6. REST API backup stores points every 25 seconds
7. On punch-out → Both services stop tracking

### Admin Dashboard Flow:
1. Admin opens Live Tracking screen
2. WebSocket connects → `AdminLiveTrackingSocket.connect()`
3. Receives `INITIAL_LOCATIONS` with current salesman positions
4. Receives real-time `LOCATION` updates with distance info
5. Map markers and polylines update in real-time
6. Can view historical routes with full graph visualization

## Map Visualization

### Markers:
- 🏠 Home Location (Violet/Blue) - Where salesman started working
- 🟢 Punch In (Green) - Start location
- 🔴 Punch Out (Red) - End location
- 📍 Current Location (Green if moving, Orange if stationary)

### Polylines:
- Live Route (Green, 3px) - Real-time route as salesman moves
- Historical Route (Blue, 4px) - Full route from database
- Selected Route (Blue, 5px) - Highlighted when employee selected

## Testing Checklist
- [ ] Salesman punches in → First location marked as home
- [ ] Salesman moves → Route polyline drawn on admin map in real-time
- [ ] Admin sees real-time distance updates in markers and cards
- [ ] Admin can view historical routes with total distance
- [ ] Home location marker displayed correctly
- [ ] No duplicate points in database
- [ ] WebSocket reconnects on disconnect
