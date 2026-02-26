# Live Tracking & Historical Routes — What's Actually Happening (Feb 25, 2026)

---

## TL;DR — Why It's Not Working Yet

The **code is fully written** on both sides (Flutter + Node.js). The system is architecturally complete. But it has **never been successfully tested end-to-end** because of a chain of small but critical issues:

| # | Blocker | Impact | Difficulty to Fix |
|---|---------|--------|-------------------|
| 1 | **No real testing done** — salesman connection never verified | We don't know if GPS data ever reaches the DB | 30 min hands-on test |
| 2 | **REST tracking endpoints have no auth** | Anyone can insert/query tracking points without login | Add middleware |

---

## What IS Built (Code Exists and Is Complete)

### Backend (Node.js + Socket.IO + PostgreSQL)

| Component | File | Status |
|-----------|------|--------|
| Socket.IO server with JWT auth | `backend/src/socket/socketServer.js` | ✅ Written |
| `session-start` event handler | socketServer.js | ✅ Written |
| `location-update` → save to PostgreSQL | socketServer.js | ✅ Written |
| `location-update` → broadcast to admin-room | socketServer.js | ✅ Written |
| `location-ack` back to salesman | socketServer.js | ✅ Written |
| `session-end` event handler | socketServer.js | ✅ Written (persists totalDistanceKm) |
| REST: `POST /tracking/point` (single) | trackingController.js | ✅ Written |
| REST: `POST /tracking/points/batch` (batch fallback) | trackingController.js | ✅ Written |
| REST: `GET /tracking/route` (historical) | trackingController.js | ✅ Written |
| REST: `GET /tracking/route-stats` | trackingController.js | ✅ Written |
| REST: `GET /tracking/live` (latest per employee) | trackingController.js | ✅ Written |
| Redis cache for latest positions | trackingController.js | ✅ Written |
| `SalesmanTrackingPoint` DB table | schema.prisma | ✅ Migrated |
| Compound index on (employeeId, attendanceId, recordedAt) | schema.prisma | ✅ Created |

### Flutter — Salesman Side

| Component | File | Status |
|-----------|------|--------|
| `SocketTrackingService` — connects, sends GPS | `lib/services/socket_tracking_service.dart` | ✅ Written |
| `LocationService` — foreground GPS stream | `lib/services/location_service.dart` | ✅ Written |
| `AttendanceSessionManager` — punch in starts tracking | `lib/services/attendance_session_manager.dart` | ✅ Written |
| REST batch fallback (flush un-acked points) | socket_tracking_service.dart | ✅ Written |
| Auto-reconnect (5 attempts with backoff) | socket_tracking_service.dart | ✅ Written |
| Android foreground service notification | location_service.dart | ✅ Written |
| 5-second send interval + 10m movement filter | socket_tracking_service.dart | ✅ Written |

### Flutter — Admin Side

| Component | File | Status |
|-----------|------|--------|
| Live tracking tab (Socket.IO + REST fallback) | `lib/screens/admin/socket_live_tracking_screen.dart` | ✅ Written |
| Historical routes tab (fetches from API) | socket_live_tracking_screen.dart | ✅ Written |
| Map with polylines, markers, punch-in points | socket_live_tracking_screen.dart | ✅ Written |
| Employee dropdown + search | socket_live_tracking_screen.dart | ✅ Written |
| `TrackingApiService` (REST helper) | `lib/services/tracking_api_service.dart` | ✅ Written |

---

## What Has NEVER Been Successfully Tested

These are the things that have never been verified working in a real scenario:

| Test | Status | Why |
|------|--------|-----|
| Salesman punches in → socket connects to backend | ❌ **Never confirmed** | Backend was fixed after the last punch-in, nobody retested |
| GPS location appears in backend logs | ❌ **Never confirmed** | No salesman has punched in since backend JWT fix |
| Location data saved to `SalesmanTrackingPoint` table | ❌ **Never confirmed** | No DB query ever showed real tracking rows |
| Admin sees real-time marker movement | ❌ **Never confirmed** | No live data was flowing to test with |
| Historical route loads for a past date | ❌ **Never confirmed** | No data in table to load |
| Route polyline draws correctly on map | ❌ **Never confirmed** | Depends on data existing |
| Reconnection after airplane mode | ❌ **Never tested** | — |
| Multiple salesmen tracking simultaneously | ❌ **Never tested** | — |
| Battery usage under tracking | ❌ **Never measured** | — |

**Bottom line: The entire pipeline has never had data flow through it end-to-end.**

---

## The Actual Data Flow (and Where It Breaks)

```
SALESMAN PHONE                    BACKEND (Render)                    ADMIN PHONE
─────────────                     ────────────────                    ───────────

1. Punch In
   └→ AttendanceSessionManager
      └→ SocketTrackingService.connect()
         └→ Socket.IO to https://loagma-crm.onrender.com
                                                                      
         ✅ UptimeRobot is pinging https://loagma-crm.onrender.com/   
            to keep the server warm (cold start risk reduced).        
                                                                      
2. LocationService.startLocationTracking()
   └→ Geolocator.getPositionStream()
   └→ GPS fixes stream in every 5m movement
                                                                      
3. Every 5 seconds:
   └→ _emitCurrentPoint()
      └→ socket.emit('location-update', {...})
         ──────────────────────────────►
                                  4. handleLocationUpdate()
                                     └→ Validate coords ✅
                                     └→ Rate limit (700ms) ✅
                                     └→ Reject accuracy > 20m ✅
                                     └→ prisma.salesmanTrackingPoint.create() ✅
                                     └→ Redis cache latest position ✅
                                     └→ io.to('admin-room').emit('location-update')
                                        ──────────────────────────────────────────►
                                                                      5. Admin receives
                                                                         └→ Update marker ✅
                                                                         └→ Extend polyline ✅
                                  
                                     └→ socket.emit('location-ack')
         ◄──────────────────────────────
   └→ Remove from pending queue ✅

6. If socket fails:
   └→ Every 12 seconds: REST batch flush
      └→ POST /tracking/points/batch
         ──────────────────────────────►
                                     └→ Save to DB ✅
                                     └→ Broadcast to admin-room ✅

7. Punch Out
   └→ SocketTrackingService.stopTracking()
      └→ socket.emit('session-end')
         ──────────────────────────────►
                                     └→ Persist totalDistanceKm ✅
```

---

## Specific Bugs Found in Code

### Bug 1: `session-end` Doesn't Persist Distance (MEDIUM)
**Status:** ✅ Fixed — now persists `totalDistanceKm` on session end.

### Bug 2: REST Tracking Routes Have No Auth (MEDIUM)
**File:** `backend/src/routes/trackingRoutes.js`  
**Problem:** None of the `/tracking/*` REST endpoints use authentication middleware. Anyone on the internet can call `GET /tracking/route?employeeId=xxx` or `POST /tracking/point` without a token.  
**Fix:** Add `authMiddleware` to the route registration.

### Bug 3: Admin Listens for Wrong Session Event Names (LOW)
**Status:** ✅ Fixed — admin now listens to both raw connection and session lifecycle events.

### Bug 4: REST Batch Flush Doesn't Broadcast to Admins (MEDIUM)
**Status:** ✅ Fixed — REST batch now emits `location-update` to `admin-room`.

### Bug 5: `getLatestLocation` Calls Non-Existent Endpoint (LOW)
**Status:** ✅ Fixed — now calls `GET /tracking/live?employeeId=...`.

### Bug 6: Heartbeat Events Not Handled Server-Side (LOW)
**File:** `loagma_crm/lib/services/socket_tracking_service.dart`  
**Problem:** The salesman app emits `'heartbeat'` every 20 seconds, but the backend never listens for this event.  
**Impact:** Just wasted bandwidth, no functionality impact.

### Bug 7: DB Query on Every Location Update for Distance (PERFORMANCE)
**File:** `backend/src/socket/socketServer.js`  
**Problem:** For every incoming GPS point, the server runs a `prisma.salesmanTrackingPoint.findFirst()` query to get the previous point for distance calculation. At 5-second intervals with multiple salesmen, this is costly.  
**Fix:** Use the in-memory `sessionMetrics` or Redis to store the last point instead of hitting DB.

---

## Render Cold Start Status

✅ **Mitigated:** UptimeRobot is pinging `https://loagma-crm.onrender.com/` to keep Render awake.

Residual risk: If the ping stops or Render still sleeps, the first socket connect may still be slow. If you notice timeouts again, switch to paid tier or add a warm-up call on app launch.

---

## Historical Routes — Current State

### The API is built and functional:
- `GET /tracking/route?employeeId=X&start=DATE1&end=DATE2` → returns tracking points
- Flutter admin screen has "Historical Routes" tab that calls this API
- Map renders polyline with start (green) and end (red) markers

### Why it shows nothing:
- **No tracking data exists in the database** because live tracking has never successfully run
- No data → API returns empty array → map shows nothing

### Minor issues with historical routes:
1. **Duration is estimated, not actual:** Calculates `points × 5 seconds` instead of using actual timestamps from data
2. **No pagination:** Fetches ALL points for a day in one request (could be 17,000+ points for an 8-hour shift at 5s intervals)
3. **Default is today-only:** If no date range is provided, backend defaults to today. Flutter side passes the selected date correctly.

---

## What Needs to Happen (In Priority Order)

### Step 1: Test Locally First (30 min)
```
1. Set `useProduction = false` in api_config.dart
2. Run backend locally: cd backend && node src/server.js
3. Run Flutter app on emulator
4. Punch in as a salesman
5. Walk around (or use mock location)
6. Check backend console for "📍 Location updated" logs
7. Query DB: SELECT COUNT(*) FROM "SalesmanTrackingPoint";
8. Open admin screen to see live updates
```
This will tell you instantly if the code actually works when the server is awake.

### Step 2: Fix Remaining Bugs (15-30 min)
1. Add auth middleware to `/tracking/*` routes → 1 line

### Step 3: Solve the Render Cold Start (30 min)
- Option A: Use UptimeRobot / cron-job.org to ping `/health` every 10 min
- Option B: Switch to Render paid ($7/mo) for always-on
- Option C: Add a "warm up" call before socket connect in the app

### Step 4: Real Device Testing (1 hour)
- Punch in on real phone, walk around for 10 min
- Verify data appears in DB
- Verify admin sees movement on map
- Verify historical route loads for the day
- Test airplane mode → reconnection
- Test with 2+ salesmen

---

## Why This "Isn't That Tough" But Still Isn't Working

You're right — it's NOT that tough. The architecture is sound and the code is complete. The reason it hasn't worked yet is a **testing gap**, not a code gap:

1. **Backend was fixed AFTER the last punch-in attempt** — JWT auth mapping was wrong, got fixed, but nobody punched in again to test
2. **Render cold starts silently kill the first connection** — nobody realized the server was sleeping
3. **No local testing was ever done** — everyone went straight to production URL
4. **The bugs are minor** — wrong event names, missing 1-line persistence call, etc.

**If you test locally with `useProduction = false`, you'll likely see it working within 10 minutes.** The handful of bugs above are all quick fixes after that.

---

*Generated: February 25, 2026*
