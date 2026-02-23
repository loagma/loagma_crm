# Complete Attendance & Live Tracking System
## From Punch-In to Punch-Out - A Complete Journey

---

## 📋 Table of Contents
1. [System Overview](#system-overview)
2. [The Three Phases](#the-three-phases)
3. [Phase 1: Punch-In](#phase-1-punch-in)
4. [Phase 2: Live Tracking](#phase-2-live-tracking)
5. [Phase 3: Punch-Out](#phase-3-punch-out)
6. [Technology Stack](#technology-stack)
7. [System Architecture](#system-architecture)
8. [Data Flow Diagrams](#data-flow-diagrams)
9. [Key Concepts](#key-concepts)
10. [Performance & Optimization](#performance--optimization)

---

## 🎯 System Overview

### What Does This System Do?

This is a real-time employee attendance and location tracking system designed for field employees (salesmen). It tracks three critical aspects:

1. **When** employees start and end their work shifts
2. **Where** employees are located throughout their shift
3. **How far** employees travel during their shift

### The Big Picture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   MORNING              DURING SHIFT              EVENING         │
│                                                                  │
│   Punch-In    ───►    Live Tracking    ───►    Punch-Out       │
│                                                                  │
│   📍 Start            📡 Real-time             📍 End           │
│   Location            GPS Streaming            Location         │
│                                                                  │
│   ✓ Capture           ✓ Monitor                ✓ Calculate     │
│   ✓ Validate          ✓ Visualize              ✓ Summarize     │
│   ✓ Approve           ✓ Track                  ✓ Report        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Who Uses This System?

**Employees (Salesmen)**
- Punch in when starting work
- App tracks location automatically
- Punch out when ending work
- View their own attendance history

**Administrators/Managers**
- Monitor all active employees in real-time
- View live locations on a map
- See routes traveled by employees
- Approve late/early punch requests
- Generate reports



---

## 🔄 The Three Phases

### Phase Overview

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║  PHASE 1: PUNCH-IN                                               ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  Duration: 5-10 seconds                                          ║
║  Purpose: Start work session, capture starting location          ║
║  Output: Attendance record with punch-in location                ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  PHASE 2: LIVE TRACKING                                          ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  Duration: Entire work shift (6-10 hours)                        ║
║  Purpose: Monitor employee location continuously                 ║
║  Output: GPS tracking points every 5 meters                      ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  PHASE 3: PUNCH-OUT                                              ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  Duration: 5-10 seconds                                          ║
║  Purpose: End work session, calculate hours & distance           ║
║  Output: Complete attendance record with statistics              ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

### Timeline Example

```
09:00 AM ─────────────────────────────────────────────── 06:00 PM
   │                                                          │
   │                                                          │
   ▼                                                          ▼
┌──────┐                                                  ┌──────┐
│PUNCH │                                                  │PUNCH │
│ IN   │                                                  │ OUT  │
└──────┘                                                  └──────┘
   │                                                          │
   │◄─────────────── LIVE TRACKING ──────────────────────►│
   │                                                          │
   │  GPS updates every 5 meters                             │
   │  Location sent to server via WebSocket                  │
   │  Admin sees real-time movement on map                   │
   │                                                          │
   └──────────────────────────────────────────────────────────┘
                    8 hours, 45.3 km traveled
```

---

## 📍 Phase 1: Punch-In

### What Happens During Punch-In?

Punch-in is the process of starting a work session. The system captures the employee's location and creates an attendance record.

### The Punch-In Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  STEP 1: Employee Opens App                                     │
│  ┌────────────────────────────────────────────────────┐        │
│  │  📱 Mobile App                                      │        │
│  │  • Check if location services enabled              │        │
│  │  • Check if GPS permission granted                 │        │
│  │  • Display "Punch In" button                       │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 2: Request Location Permission                            │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🔐 Permission Dialog                               │        │
│  │  "Allow Loagma CRM to access location?"            │        │
│  │  • While using the app                             │        │
│  │  • All the time (for background tracking)          │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 3: Get GPS Location                                       │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🛰️ GPS Service                                     │        │
│  │  • Acquire GPS signal (2-5 seconds)                │        │
│  │  • Get latitude & longitude                        │        │
│  │  • Get accuracy (in meters)                        │        │
│  │  Example: 24.8607°N, 67.0011°E (±8m)              │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 4: Validate Working Hours                                 │
│  ┌────────────────────────────────────────────────────┐        │
│  │  ⏰ Time Validation                                 │        │
│  │  Work Start: 09:00 AM                              │        │
│  │  Grace Period: +45 minutes                         │        │
│  │  Cutoff Time: 09:45 AM                             │        │
│  │                                                     │        │
│  │  Current Time: 09:30 AM ✓ OK                       │        │
│  │  Current Time: 10:00 AM ✗ Needs Approval           │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 5: Create Attendance Record                               │
│  ┌────────────────────────────────────────────────────┐        │
│  │  💾 Database                                        │        │
│  │  Save:                                             │        │
│  │  • Employee ID & Name                              │        │
│  │  • Punch-in time (UTC)                             │        │
│  │  • Punch-in location (lat/lng)                     │        │
│  │  • Status: "active"                                │        │
│  │  • Attendance ID: att_123456                       │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 6: Notify Admin                                           │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🔔 Notification                                    │        │
│  │  "John Doe punched in at 09:00 AM"                 │        │
│  │  Location: Office Area                             │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 7: Start Live Tracking                                    │
│  ┌────────────────────────────────────────────────────┐        │
│  │  📡 Tracking Service                                │        │
│  │  • Connect to WebSocket server                     │        │
│  │  • Start GPS location stream                       │        │
│  │  • Show "Tracking Active" notification             │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



### Late Punch-In Approval Flow

When an employee tries to punch in after the cutoff time:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Employee tries to punch in at 10:30 AM                         │
│  (Cutoff time was 09:45 AM)                                     │
│                                                                  │
│  ┌──────────────┐                                               │
│  │   BLOCKED    │                                               │
│  │  ⛔ Cannot   │                                               │
│  │  punch in    │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────────────────────┐                      │
│  │  Request Approval                    │                      │
│  │  • Employee enters reason            │                      │
│  │  • Request sent to admin             │                      │
│  │  • Status: PENDING                   │                      │
│  └──────────────┬───────────────────────┘                      │
│                 │                                                │
│                 ▼                                                │
│  ┌──────────────────────────────────────┐                      │
│  │  Admin Reviews Request               │                      │
│  │  • See employee name & reason        │                      │
│  │  • See requested time                │                      │
│  │  • Approve or Reject                 │                      │
│  └──────────────┬───────────────────────┘                      │
│                 │                                                │
│        ┌────────┴────────┐                                      │
│        ▼                 ▼                                       │
│  ┌──────────┐     ┌──────────┐                                 │
│  │ APPROVED │     │ REJECTED │                                 │
│  └────┬─────┘     └────┬─────┘                                 │
│       │                │                                         │
│       ▼                ▼                                         │
│  Employee can    Employee cannot                                │
│  punch in now    punch in today                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Punch-In Location Matters

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Punch-In Location = Starting Point of Everything               │
│                                                                  │
│  1. ROUTE VISUALIZATION                                         │
│     🟢 Green marker on map shows where employee started         │
│                                                                  │
│  2. DISTANCE CALCULATION                                        │
│     📏 First point in distance measurement                      │
│     Distance = Sum of all segments from punch-in to punch-out   │
│                                                                  │
│  3. VERIFICATION                                                │
│     ✓ Confirms employee started from correct location          │
│     ✓ Audit trail for compliance                               │
│                                                                  │
│  4. ROUTE TRACKING                                              │
│     📍 First point in the polyline route                        │
│     All subsequent GPS points connect to this                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📡 Phase 2: Live Tracking

### What is Live Tracking?

Live tracking is the continuous monitoring of employee location throughout their work shift. The system captures GPS coordinates every 5 meters and streams them in real-time to the admin dashboard.

### Why WebSocket? (Not HTTP)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ❌ OLD WAY: HTTP Polling                                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Mobile App          Server                                     │
│      │                  │                                        │
│      │──── Request ────►│  (Every 5 seconds)                    │
│      │◄─── Response ────│                                        │
│      │                  │                                        │
│      │──── Request ────►│  (Every 5 seconds)                    │
│      │◄─── Response ────│                                        │
│      │                  │                                        │
│      │──── Request ────►│  (Every 5 seconds)                    │
│      │◄─── Response ────│                                        │
│                                                                  │
│  Problems:                                                       │
│  • High battery drain (constant requests)                       │
│  • High server load (many connections)                          │
│  • Latency (delay between updates)                              │
│  • Inefficient (repeated handshakes)                            │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ NEW WAY: WebSocket                                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Mobile App          Server                                     │
│      │                  │                                        │
│      │──── Connect ────►│  (Once at start)                      │
│      │◄─── Connected ───│                                        │
│      │                  │                                        │
│      │═══════════════════│  (Persistent connection)             │
│      │                  │                                        │
│      │──── Location ───►│  (When moved 5m)                      │
│      │──── Location ───►│  (When moved 5m)                      │
│      │──── Location ───►│  (When moved 5m)                      │
│      │                  │                                        │
│      │═══════════════════│  (Connection stays open)             │
│                                                                  │
│  Benefits:                                                       │
│  • Low battery drain (single connection)                        │
│  • Low server load (efficient)                                  │
│  • Real-time (instant updates)                                  │
│  • Bidirectional (server can push too)                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



### Live Tracking Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                    LIVE TRACKING SYSTEM                          │
│                                                                  │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────┐│
│  │              │         │              │         │          ││
│  │  MOBILE APP  │◄───────►│    SERVER    │◄───────►│  ADMIN   ││
│  │  (Employee)  │WebSocket│  (Socket.IO) │WebSocket│DASHBOARD ││
│  │              │         │              │         │          ││
│  └──────┬───────┘         └──────┬───────┘         └──────────┘│
│         │                        │                               │
│         │ GPS                    │ Save                          │
│         │ Stream                 │ Points                        │
│         ▼                        ▼                               │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │              │         │              │                     │
│  │ GPS SERVICE  │         │  DATABASE    │                     │
│  │ (Geolocator) │         │ (PostgreSQL) │                     │
│  │              │         │              │                     │
│  └──────────────┘         └──────────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### The Complete Live Tracking Flow

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║  STEP 1: GPS Captures Location                                   ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  📱 Mobile Device                                                 ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  GPS Chip continuously monitors position        │            ║
║  │  • Latitude: 24.8607                            │            ║
║  │  • Longitude: 67.0011                           │            ║
║  │  • Accuracy: ±8 meters                          │            ║
║  │  • Speed: 1.5 m/s                               │            ║
║  │  • Timestamp: 2024-01-15 09:05:15               │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 2: Filter Location Updates                                 ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  🔍 Two-Level Filtering                                           ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  FILTER 1: Movement Check                       │            ║
║  │  Has employee moved at least 5 meters?          │            ║
║  │  • Yes → Continue to Filter 2                   │            ║
║  │  • No → Discard (GPS drift/stationary)          │            ║
║  │                                                  │            ║
║  │  FILTER 2: Time Check                           │            ║
║  │  Has 3 seconds passed since last update?        │            ║
║  │  • Yes → Send to server                         │            ║
║  │  • No → Wait (rate limiting)                    │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 3: Send via WebSocket                                      ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  📤 WebSocket Emit                                                ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  Event: "location-update"                       │            ║
║  │  Data: {                                        │            ║
║  │    employeeId: "emp_789",                       │            ║
║  │    employeeName: "John Doe",                    │            ║
║  │    attendanceId: "att_123456",                  │            ║
║  │    latitude: 24.8607,                           │            ║
║  │    longitude: 67.0011,                          │            ║
║  │    speed: 1.5,                                  │            ║
║  │    accuracy: 8.0,                               │            ║
║  │    timestamp: "2024-01-15T09:05:15Z"            │            ║
║  │  }                                              │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 4: Server Receives & Validates                             ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  🔐 Server-Side Validation                                        ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  ✓ Check JWT token (authentication)             │            ║
║  │  ✓ Validate required fields exist               │            ║
║  │  ✓ Validate coordinate ranges                   │            ║
║  │    (-90 to 90 for lat, -180 to 180 for lng)     │            ║
║  │  ✓ Check movement threshold (5 meters)          │            ║
║  │  ✓ Rate limiting (max 1 per 3 seconds)          │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 5: Save to Database                                        ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  💾 PostgreSQL Storage                                            ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  Table: SalesmanTrackingPoint                   │            ║
║  │  Insert new record:                             │            ║
║  │  • ID: auto-generated                           │            ║
║  │  • Employee ID: emp_789                         │            ║
║  │  • Attendance ID: att_123456                    │            ║
║  │  • Latitude: 24.8607                            │            ║
║  │  • Longitude: 67.0011                           │            ║
║  │  • Speed: 1.5                                   │            ║
║  │  • Accuracy: 8.0                                │            ║
║  │  • Recorded At: 2024-01-15 09:05:15 UTC         │            ║
║  │                                                  │            ║
║  │  Purpose: Permanent storage for history         │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 6: Broadcast to Admins                                     ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  📡 WebSocket Broadcast                                           ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  To: "admin-room" (all connected admins)        │            ║
║  │  Event: "location-update"                       │            ║
║  │  Data: Same location data                       │            ║
║  │                                                  │            ║
║  │  All admins receive update simultaneously       │            ║
║  └─────────────────────────────────────────────────┘            ║
║                          │                                        ║
║                          ▼                                        ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  STEP 7: Admin Dashboard Updates                                 ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  🗺️ Map Visualization                                            ║
║  ┌─────────────────────────────────────────────────┐            ║
║  │  1. Update employee's current location          │            ║
║  │  2. Move marker to new position                 │            ║
║  │  3. Add point to route polyline                 │            ║
║  │  4. Calculate distance from last point          │            ║
║  │  5. Add to total distance                       │            ║
║  │  6. Update "Last seen" timestamp                │            ║
║  │  7. Refresh UI                                  │            ║
║  │                                                  │            ║
║  │  Admin sees marker move in real-time!           │            ║
║  └─────────────────────────────────────────────────┘            ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```



### What Admin Sees on Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│  LIVE TRACKING DASHBOARD                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Select Employee: [John Doe (45.3km) ▼]               │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    🗺️ MAP VIEW                         │    │
│  │                                                         │    │
│  │         🟢 ←─────────────────────────────→ 🟡         │    │
│  │      Punch-in                Route              Current│    │
│  │      Location              Polyline            Location│    │
│  │      (Start)              (Gold line)           (Live) │    │
│  │                                                         │    │
│  │  Route shows complete path traveled                    │    │
│  │  Marker moves as employee moves                        │    │
│  │                                                         │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  STATISTICS                                            │    │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │    │
│  │  📍 Distance: 45.3 km                                  │    │
│  │  ⏱️ Duration: 8h 15m                                   │    │
│  │  🚀 Avg Speed: 5.5 km/h                                │    │
│  │  📌 Points: 287                                        │    │
│  │  🕐 Last Update: 2 seconds ago                         │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Distance Calculation Theory

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  HOW DISTANCE IS CALCULATED                                     │
│                                                                  │
│  Method: Haversine Formula (Follows Exact Route)                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  ❌ NOT USED: Straight-Line Distance                            │
│  ┌──────────────────────────────────────────────────┐          │
│  │                                                   │          │
│  │   Start ─────────────────────────► End           │          │
│  │   (A)                               (B)           │          │
│  │                                                   │          │
│  │   Distance = 5 km (straight line)                │          │
│  │   Problem: Ignores actual path traveled          │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ✅ USED: Route Following Distance                              │
│  ┌──────────────────────────────────────────────────┐          │
│  │                                                   │          │
│  │   Start ──► P1 ──► P2 ──► P3 ──► P4 ──► End     │          │
│  │   (A)                                    (B)     │          │
│  │                                                   │          │
│  │   Distance = d(A,P1) + d(P1,P2) + d(P2,P3)      │          │
│  │            + d(P3,P4) + d(P4,B)                  │          │
│  │            = 0.5 + 1.2 + 0.8 + 1.5 + 0.7         │          │
│  │            = 4.7 km (actual route)               │          │
│  │   Benefit: Captures every turn and detour        │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  EXAMPLE: Employee's Day                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  09:00 AM - Point 1 (Punch-in)    : 0.00 km                    │
│  09:05 AM - Point 2               : +0.05 km → Total: 0.05 km  │
│  09:10 AM - Point 3               : +0.08 km → Total: 0.13 km  │
│  09:15 AM - Point 4               : +0.12 km → Total: 0.25 km  │
│  ...                                                             │
│  05:30 PM - Point 287 (Punch-out) : +0.15 km → Total: 45.30 km │
│                                                                  │
│  Each segment distance is calculated using Haversine formula    │
│  which accounts for Earth's curvature                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Foreground Service (Background Tracking)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WHY FOREGROUND SERVICE?                                        │
│                                                                  │
│  Problem: Android kills background apps to save battery         │
│  Solution: Foreground service with persistent notification      │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  📱 Phone Screen                                    │        │
│  │  ┌──────────────────────────────────────────────┐  │        │
│  │  │  🔔 Loagma CRM – Tracking active             │  │        │
│  │  │  Live work tracking is on. Keep this for    │  │        │
│  │  │  your shift.                                 │  │        │
│  │  └──────────────────────────────────────────────┘  │        │
│  │                                                      │        │
│  │  This notification tells Android:                   │        │
│  │  "This app is doing important work, don't kill it!" │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  BENEFITS:                                                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  ✓ Tracking continues when screen is off                       │
│  ✓ Tracking continues when app is in background                │
│  ✓ Tracking continues when phone is locked                     │
│  ✓ User knows tracking is active (notification visible)        │
│  ✓ Android won't kill the service                              │
│                                                                  │
│  CONFIGURATION:                                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  • Wake Lock: Keeps CPU awake for GPS                          │
│  • WiFi Lock: Maintains network connection                     │
│  • Ongoing: Notification can't be dismissed                    │
│  • High Priority: Ensures service isn't killed                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



---

## 🔴 Phase 3: Punch-Out

### What Happens During Punch-Out?

Punch-out is the process of ending a work session. The system captures the final location, stops tracking, calculates total hours and distance, and completes the attendance record.

### The Punch-Out Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  STEP 1: Employee Clicks Punch-Out                              │
│  ┌────────────────────────────────────────────────────┐        │
│  │  📱 Mobile App                                      │        │
│  │  • Employee taps "Punch Out" button                │        │
│  │  • App prepares to end session                     │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 2: Validate Working Hours                                 │
│  ┌────────────────────────────────────────────────────┐        │
│  │  ⏰ Time Validation                                 │        │
│  │  Work End: 06:00 PM                                │        │
│  │  Grace Period: -30 minutes                         │        │
│  │  Cutoff Time: 05:30 PM                             │        │
│  │                                                     │        │
│  │  Current Time: 05:45 PM ✓ OK                       │        │
│  │  Current Time: 05:00 PM ✗ Needs Approval           │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 3: Get Final Location                                     │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🛰️ GPS Service                                     │        │
│  │  • Get current GPS position                        │        │
│  │  • This is the punch-out location                  │        │
│  │  Example: 24.8789°N, 67.0234°E (±10m)             │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 4: Stop Live Tracking                                     │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🛑 Stop Services                                   │        │
│  │  • Stop GPS location stream                        │        │
│  │  • Disconnect WebSocket                            │        │
│  │  • Remove foreground notification                  │        │
│  │  • Release wake locks                              │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 5: Calculate Work Hours                                   │
│  ┌────────────────────────────────────────────────────┐        │
│  │  ⏱️ Time Calculation                                │        │
│  │  Punch-in:  09:00:00 AM                            │        │
│  │  Punch-out: 05:30:00 PM                            │        │
│  │  Duration:  8 hours 30 minutes                     │        │
│  │  Decimal:   8.5 hours                              │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 6: Calculate Distance                                     │
│  ┌────────────────────────────────────────────────────┐        │
│  │  📏 Distance Calculation                            │        │
│  │  Method: Sum of all route segments                 │        │
│  │  Points: 287 GPS coordinates                       │        │
│  │  Total Distance: 45.3 km                           │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 7: Update Attendance Record                               │
│  ┌────────────────────────────────────────────────────┐        │
│  │  💾 Database Update                                 │        │
│  │  Update attendance record:                         │        │
│  │  • Punch-out time: 05:30 PM                        │        │
│  │  • Punch-out location: (lat, lng)                  │        │
│  │  • Total work hours: 8.5                           │        │
│  │  • Total distance: 45.3 km                         │        │
│  │  • Status: "completed"                             │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 8: Notify Admin                                           │
│  ┌────────────────────────────────────────────────────┐        │
│  │  🔔 Notification                                    │        │
│  │  "John Doe punched out at 05:30 PM"                │        │
│  │  "Worked 8h 30m, traveled 45.3 km"                 │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  STEP 9: Show Summary to Employee                               │
│  ┌────────────────────────────────────────────────────┐        │
│  │  ✅ Success Message                                 │        │
│  │  "Punched out successfully!"                       │        │
│  │  "Worked for 8h 30m"                               │        │
│  │  "Traveled 45.3 km"                                │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Early Punch-Out Approval Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Employee tries to punch out at 05:00 PM                        │
│  (Cutoff time is 05:30 PM)                                      │
│                                                                  │
│  ┌──────────────┐                                               │
│  │   BLOCKED    │                                               │
│  │  ⛔ Cannot   │                                               │
│  │  punch out   │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────────────────────┐                      │
│  │  Request Approval                    │                      │
│  │  • Employee enters reason            │                      │
│  │  • "Family emergency"                │                      │
│  │  • Request sent to admin             │                      │
│  │  • Status: PENDING                   │                      │
│  └──────────────┬───────────────────────┘                      │
│                 │                                                │
│                 ▼                                                │
│  ┌──────────────────────────────────────┐                      │
│  │  Admin Reviews Request               │                      │
│  │  • See employee name & reason        │                      │
│  │  • See current work hours (5h)       │                      │
│  │  • Approve or Reject                 │                      │
│  └──────────────┬───────────────────────┘                      │
│                 │                                                │
│        ┌────────┴────────┐                                      │
│        ▼                 ▼                                       │
│  ┌──────────┐     ┌──────────┐                                 │
│  │ APPROVED │     │ REJECTED │                                 │
│  └────┬─────┘     └────┬─────┘                                 │
│       │                │                                         │
│       ▼                ▼                                         │
│  Employee can    Employee must                                  │
│  punch out now   continue working                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



### Complete Attendance Record

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ATTENDANCE RECORD: att_123456                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  EMPLOYEE INFORMATION                                           │
│  • Employee ID: emp_789                                         │
│  • Employee Name: John Doe                                      │
│  • Date: 2024-01-15                                             │
│                                                                  │
│  PUNCH-IN DETAILS                                               │
│  • Time: 09:00:00 AM (IST)                                      │
│  • Location: 24.8607°N, 67.0011°E                              │
│  • Address: Office Area, Karachi                                │
│  • Photo: [captured]                                            │
│                                                                  │
│  PUNCH-OUT DETAILS                                              │
│  • Time: 05:30:00 PM (IST)                                      │
│  • Location: 24.8789°N, 67.0234°E                              │
│  • Address: Client Area, Karachi                                │
│  • Photo: [captured]                                            │
│                                                                  │
│  WORK SUMMARY                                                    │
│  • Total Work Hours: 8.5 hours (8h 30m)                        │
│  • Total Distance: 45.3 km                                      │
│  • GPS Points Recorded: 287                                     │
│  • Status: Completed                                            │
│                                                                  │
│  APPROVALS                                                       │
│  • Late Punch-In: No                                            │
│  • Early Punch-Out: No                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  MOBILE APPLICATION                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Framework:  Flutter 3.x                                        │
│  Language:   Dart                                               │
│  Platform:   Android (iOS compatible)                           │
│                                                                  │
│  Key Packages:                                                   │
│  • geolocator          → GPS location tracking                  │
│  • socket_io_client    → WebSocket communication                │
│  • flutter_map         → Map visualization                      │
│  • latlong2            → Coordinate calculations                │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  BACKEND SERVER                                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Runtime:    Node.js                                            │
│  Framework:  Express.js                                         │
│  Language:   JavaScript (ES6+)                                  │
│                                                                  │
│  Key Libraries:                                                  │
│  • socket.io           → WebSocket server                       │
│  • jsonwebtoken        → Authentication                         │
│  • prisma              → Database ORM                           │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DATABASE                                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  System:     PostgreSQL                                         │
│  ORM:        Prisma                                             │
│                                                                  │
│  Main Tables:                                                    │
│  • Attendance              → Punch-in/out records               │
│  • SalesmanTrackingPoint   → GPS coordinates                    │
│  • User                    → Employee information               │
│  • LatePunchApproval       → Late punch-in requests             │
│  • EarlyPunchOutApproval   → Early punch-out requests           │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  REAL-TIME COMMUNICATION                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Protocol:   WebSocket (Socket.IO)                              │
│  Transport:  WebSocket only (no polling fallback)               │
│  Auth:       JWT in handshake                                   │
│  Rooms:      admin-room, employee-specific rooms                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why These Technologies?

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  FLUTTER                                                         │
│  ✓ Cross-platform (Android + iOS from single codebase)         │
│  ✓ Native performance                                           │
│  ✓ Rich UI components                                           │
│  ✓ Strong GPS/location support                                 │
│                                                                  │
│  SOCKET.IO                                                       │
│  ✓ Real-time bidirectional communication                        │
│  ✓ Automatic reconnection                                       │
│  ✓ Room-based broadcasting                                      │
│  ✓ Fallback mechanisms                                          │
│                                                                  │
│  POSTGRESQL                                                      │
│  ✓ Reliable and robust                                          │
│  ✓ ACID compliance                                              │
│  ✓ Excellent for geospatial data                                │
│  ✓ Scalable                                                     │
│                                                                  │
│  PRISMA ORM                                                      │
│  ✓ Type-safe database queries                                   │
│  ✓ Auto-generated types                                         │
│  ✓ Easy migrations                                              │
│  ✓ Great developer experience                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



---

## 🏗️ System Architecture

### High-Level Architecture

```
                    ┌─────────────────────────────────┐
                    │                                 │
                    │      MOBILE APPLICATION         │
                    │         (Flutter)               │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │   Punch-In Screen        │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Location Service       │  │
                    │  │   (GPS Tracking)         │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Socket Service         │  │
                    │  │   (WebSocket Client)     │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Punch-Out Screen       │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    └────────────┬────────────────────┘
                                 │
                                 │ WebSocket
                                 │ (ws://)
                                 │
                    ┌────────────▼────────────────────┐
                    │                                 │
                    │      BACKEND SERVER             │
                    │       (Node.js)                 │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │   Socket.IO Server       │  │
                    │  │   • Authentication       │  │
                    │  │   • Connection Mgmt      │  │
                    │  │   • Broadcasting         │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Express API            │  │
                    │  │   • Punch-In Endpoint    │  │
                    │  │   • Punch-Out Endpoint   │  │
                    │  │   • Approval Endpoints   │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Business Logic         │  │
                    │  │   • Validation           │  │
                    │  │   • Calculations         │  │
                    │  │   • Notifications        │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    └────────────┬────────────────────┘
                                 │
                                 │ SQL
                                 │
                    ┌────────────▼────────────────────┐
                    │                                 │
                    │      DATABASE                   │
                    │     (PostgreSQL)                │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │   Attendance Table       │  │
                    │  │   • Punch records        │  │
                    │  │   • Work hours           │  │
                    │  │   • Distance             │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   TrackingPoint Table    │  │
                    │  │   • GPS coordinates      │  │
                    │  │   • Timestamps           │  │
                    │  │   • Speed & accuracy     │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   User Table             │  │
                    │  │   • Employee info        │  │
                    │  │   • Working hours        │  │
                    │  │   • Permissions          │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    └─────────────────────────────────┘
                                 │
                                 │ WebSocket
                                 │ Broadcast
                                 │
                    ┌────────────▼────────────────────┐
                    │                                 │
                    │      ADMIN DASHBOARD            │
                    │      (Flutter Web)              │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │   Live Tracking Screen   │  │
                    │  │   • Real-time map        │  │
                    │  │   • Employee list        │  │
                    │  │   • Route visualization  │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Historical Routes      │  │
                    │  │   • Date picker          │  │
                    │  │   • Route playback       │  │
                    │  │   • Statistics           │  │
                    │  └──────────────────────────┘  │
                    │  ┌──────────────────────────┐  │
                    │  │   Approval Management    │  │
                    │  │   • Pending requests     │  │
                    │  │   • Approve/Reject       │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    └─────────────────────────────────┘
```



---

## 📊 Data Flow Diagrams

### Complete System Data Flow

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    COMPLETE DATA FLOW                             ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  MORNING: PUNCH-IN                                                ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  Employee → Get GPS → Validate Hours → Create Record             ║
║                                            ↓                      ║
║                                       Save to DB                  ║
║                                            ↓                      ║
║                                    Notify Admin                   ║
║                                            ↓                      ║
║                                    Start Tracking                 ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  DURING SHIFT: LIVE TRACKING                                      ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  GPS Chip → Location Service → Filter (5m + 3s)                  ║
║                                      ↓                            ║
║                              Socket Service                       ║
║                                      ↓                            ║
║                          WebSocket Emit                           ║
║                                      ↓                            ║
║                              Server Receives                      ║
║                                      ↓                            ║
║                          Validate & Check Movement                ║
║                                      ↓                            ║
║                          Save to Database                         ║
║                                      ↓                            ║
║                          Broadcast to Admins                      ║
║                                      ↓                            ║
║                          Admin Dashboard Updates                  ║
║                                      ↓                            ║
║                          Map Marker Moves                         ║
║                          Route Extends                            ║
║                          Distance Increases                       ║
║                                                                   ║
║  (This repeats every 5 meters throughout the shift)               ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  EVENING: PUNCH-OUT                                               ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  Employee → Get GPS → Validate Hours → Stop Tracking             ║
║                                            ↓                      ║
║                                    Calculate Hours                ║
║                                            ↓                      ║
║                                    Calculate Distance             ║
║                                            ↓                      ║
║                                    Update Record                  ║
║                                            ↓                      ║
║                                    Save to DB                     ║
║                                            ↓                      ║
║                                    Notify Admin                   ║
║                                            ↓                      ║
║                                    Show Summary                   ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

### WebSocket Communication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WEBSOCKET LIFECYCLE                                            │
│                                                                  │
│  ┌──────────────┐                          ┌──────────────┐    │
│  │   MOBILE     │                          │    SERVER    │    │
│  │     APP      │                          │  (Socket.IO) │    │
│  └──────┬───────┘                          └──────┬───────┘    │
│         │                                         │             │
│         │──────── Connect (JWT) ─────────────────►│             │
│         │                                         │             │
│         │                                    Authenticate       │
│         │                                         │             │
│         │◄────── Connected (Socket ID) ───────────│             │
│         │                                         │             │
│         │                                    Join Rooms         │
│         │                                         │             │
│         │                                         │             │
│         │──────── location-update ───────────────►│             │
│         │         (GPS data)                      │             │
│         │                                         │             │
│         │                                    Validate           │
│         │                                         │             │
│         │                                    Save to DB         │
│         │                                         │             │
│         │                                    Broadcast          │
│         │                                         │             │
│         │◄────── location-ack ────────────────────│             │
│         │         (confirmation)                  │             │
│         │                                         │             │
│         │                                         │             │
│         │──────── location-update ───────────────►│             │
│         │         (next GPS point)                │             │
│         │                                         │             │
│         │                                    (repeat)           │
│         │                                         │             │
│         │                                         │             │
│         │──────── session-end ───────────────────►│             │
│         │         (punch-out)                     │             │
│         │                                         │             │
│         │                                    Cleanup            │
│         │                                         │             │
│         │──────── Disconnect ─────────────────────│             │
│         │                                         │             │
│         │                                    Remove from        │
│         │                                    Active List        │
│         │                                         │             │
│  ┌──────▼───────┐                          ┌──────▼───────┐    │
│  │   MOBILE     │                          │    SERVER    │    │
│  │     APP      │                          │  (Socket.IO) │    │
│  └──────────────┘                          └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



---

## 💡 Key Concepts

### 1. GPS Filtering Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WHY FILTERING IS NECESSARY                                     │
│                                                                  │
│  Problem: GPS is not perfect                                    │
│  • GPS drift when stationary (±5-10 meters)                     │
│  • Rapid updates drain battery                                  │
│  • Too many points = memory issues                              │
│  • Server overload with excessive updates                       │
│                                                                  │
│  Solution: Two-level filtering                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LEVEL 1: MOVEMENT FILTER (5 meters)              │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  GPS Update → Calculate distance from last point  │        │
│  │                                                     │        │
│  │  Distance < 5m → DISCARD (GPS drift/stationary)   │        │
│  │  Distance ≥ 5m → PASS to Level 2                  │        │
│  │                                                     │        │
│  │  Benefit: Removes noise, creates smooth routes    │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LEVEL 2: TIME FILTER (3 seconds)                 │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  Check time since last sent update                │        │
│  │                                                     │        │
│  │  Time < 3s → WAIT (rate limiting)                 │        │
│  │  Time ≥ 3s → SEND to server                       │        │
│  │                                                     │        │
│  │  Benefit: Prevents excessive updates, saves       │        │
│  │           battery and server resources             │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  RESULT:                                                         │
│  • ~6-12 updates per minute (optimal)                           │
│  • Smooth routes without noise                                  │
│  • Battery efficient                                             │
│  • Server friendly                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2. Distance Calculation Method

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  HAVERSINE FORMULA                                              │
│  (Calculates distance on a sphere)                              │
│                                                                  │
│  Why Haversine?                                                  │
│  • Earth is not flat (it's a sphere)                            │
│  • Simple Pythagorean theorem is inaccurate                     │
│  • Haversine accounts for Earth's curvature                     │
│  • Industry standard for GPS distance                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │                                                     │        │
│  │  Given two GPS points:                             │        │
│  │  Point A: (lat1, lon1)                             │        │
│  │  Point B: (lat2, lon2)                             │        │
│  │                                                     │        │
│  │  Steps:                                            │        │
│  │  1. Convert degrees to radians                     │        │
│  │  2. Calculate differences (Δlat, Δlon)             │        │
│  │  3. Apply Haversine formula                        │        │
│  │  4. Multiply by Earth's radius (6371 km)           │        │
│  │                                                     │        │
│  │  Result: Distance in kilometers                    │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  ACCUMULATION STRATEGY                                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                                  │
│  Total Distance = Sum of all segment distances                  │
│                                                                  │
│  Segment 1: Point 1 → Point 2 = 0.05 km                        │
│  Segment 2: Point 2 → Point 3 = 0.08 km                        │
│  Segment 3: Point 3 → Point 4 = 0.12 km                        │
│  ...                                                             │
│  Segment N: Point N-1 → Point N = 0.15 km                      │
│                                                                  │
│  Total = 0.05 + 0.08 + 0.12 + ... + 0.15 = 45.3 km             │
│                                                                  │
│  This follows the EXACT route traveled, not straight-line!      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3. Route Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PROBLEM: Too Many Points                                       │
│                                                                  │
│  During an 8-hour shift:                                        │
│  • Employee moves constantly                                    │
│  • GPS updates every 5 meters                                   │
│  • Could generate 1000+ points                                  │
│  • Memory usage increases                                       │
│  • Map rendering slows down                                     │
│                                                                  │
│  SOLUTION: Douglas-Peucker Simplification                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │                                                     │        │
│  │  Original Route: 1000 points                       │        │
│  │                                                     │        │
│  │  A──B──C──D──E──F──G──H──I──J──K──L──M──N──O──P  │        │
│  │                                                     │        │
│  │  After Optimization: 350 points                    │        │
│  │                                                     │        │
│  │  A────────D─────F────────J──────M────────────P    │        │
│  │                                                     │        │
│  │  • Keeps important points (turns, changes)         │        │
│  │  • Removes redundant points (straight lines)       │        │
│  │  • Maintains route accuracy                        │        │
│  │  • Reduces memory usage                            │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  STRATEGY:                                                       │
│  • Keep punch-in location (always)                              │
│  • Keep recent 200 points (full detail)                         │
│  • Simplify older points (remove redundant)                     │
│  • Recalculate distance after optimization                      │
│                                                                  │
│  RESULT:                                                         │
│  • Memory efficient                                              │
│  • Fast map rendering                                            │
│  • Accurate distance maintained                                 │
│  • Smooth visualization                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



### 4. Authentication & Security

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SECURITY LAYERS                                                │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LAYER 1: JWT Authentication                       │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  • User logs in with credentials                   │        │
│  │  • Server generates JWT token                      │        │
│  │  • Token contains: user ID, role, expiry           │        │
│  │  • Token sent with every request                   │        │
│  │  • Server verifies token signature                 │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LAYER 2: WebSocket Authentication                 │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  • JWT token sent in WebSocket handshake           │        │
│  │  • Server verifies before accepting connection     │        │
│  │  • Invalid token = connection rejected             │        │
│  │  • User info attached to socket                    │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LAYER 3: Data Validation                          │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  • Validate coordinate ranges                      │        │
│  │  • Check required fields                           │        │
│  │  • Verify employee ID matches token                │        │
│  │  • Rate limiting (prevent spam)                    │        │
│  │  • Movement threshold check                        │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────┐        │
│  │  LAYER 4: Role-Based Access                        │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │                                                     │        │
│  │  • Employees: Can only see own data                │        │
│  │  • Admins: Can see all employees                   │        │
│  │  • Managers: Can see team members                  │        │
│  │  • Permissions checked on every action             │        │
│  │                                                     │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Performance & Optimization

### Battery Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  BATTERY CONSUMPTION BREAKDOWN                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  GPS (High Accuracy)         5-8% per hour         │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │  • Largest battery consumer                        │        │
│  │  • Necessary for accurate tracking                 │        │
│  │  • Optimized with distance filter (5m)             │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  WebSocket Connection        1-2% per hour         │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │  • Persistent connection                           │        │
│  │  • Minimal data transfer                           │        │
│  │  • Efficient protocol                              │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  Foreground Service          0.5-1% per hour       │        │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │        │
│  │  • Keeps app alive                                 │        │
│  │  • Minimal overhead                                │        │
│  │  • Necessary for background tracking               │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  TOTAL: ~6.5-11% per hour                                       │
│                                                                  │
│  For 8-hour shift: ~52-88% battery usage                        │
│  (Phone should start with >90% battery)                         │
│                                                                  │
│  OPTIMIZATION TECHNIQUES:                                        │
│  ✓ Distance filter (5m) reduces GPS queries                    │
│  ✓ Time filter (3s) reduces network usage                      │
│  ✓ WebSocket (not polling) saves battery                       │
│  ✓ Efficient data format (minimal payload)                     │
│  ✓ Wake locks only when needed                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Network Usage

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  DATA CONSUMPTION                                               │
│                                                                  │
│  Per Location Update:                                           │
│  ┌────────────────────────────────────────────────────┐        │
│  │  Payload Size: ~200 bytes                          │        │
│  │  {                                                  │        │
│  │    employeeId: "emp_789",        (10 bytes)        │        │
│  │    employeeName: "John Doe",     (15 bytes)        │        │
│  │    attendanceId: "att_123456",   (15 bytes)        │        │
│  │    latitude: 24.8607,            (8 bytes)         │        │
│  │    longitude: 67.0011,           (8 bytes)         │        │
│  │    speed: 1.5,                   (4 bytes)         │        │
│  │    accuracy: 8.0,                (4 bytes)         │        │
│  │    timestamp: "2024-01-15..."    (25 bytes)        │        │
│  │  }                                                  │        │
│  │  + WebSocket overhead            (~100 bytes)      │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  Per Hour:                                                       │
│  • Updates: ~360-720 (6-12 per minute)                         │
│  • Data: ~70-150 KB                                             │
│                                                                  │
│  Per 8-Hour Shift:                                              │
│  • Updates: ~2,880-5,760                                        │
│  • Data: ~560 KB - 1.2 MB                                       │
│                                                                  │
│  VERY EFFICIENT! Less than 2 MB per day                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Database Storage

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  STORAGE REQUIREMENTS                                           │
│                                                                  │
│  Per Attendance Record:                                         │
│  ┌────────────────────────────────────────────────────┐        │
│  │  • Employee info          ~50 bytes                │        │
│  │  • Timestamps             ~16 bytes                │        │
│  │  • Locations (lat/lng)    ~32 bytes                │        │
│  │  • Photos (optional)      ~50-200 KB               │        │
│  │  • Metadata               ~50 bytes                │        │
│  │                                                     │        │
│  │  Total: ~500 bytes (without photos)                │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  Per Tracking Point:                                            │
│  ┌────────────────────────────────────────────────────┐        │
│  │  • Coordinates            ~16 bytes                │        │
│  │  • Speed & accuracy       ~8 bytes                 │        │
│  │  • Timestamp              ~8 bytes                 │        │
│  │  • References             ~16 bytes                │        │
│  │                                                     │        │
│  │  Total: ~50 bytes per point                        │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  Per Employee Per Day:                                          │
│  • Attendance: 500 bytes                                        │
│  • Tracking points: ~300 × 50 = 15 KB                          │
│  • Total: ~15.5 KB per day                                      │
│                                                                  │
│  For 100 Employees:                                             │
│  • Per Day: ~1.5 MB                                             │
│  • Per Month: ~45 MB                                            │
│  • Per Year: ~540 MB                                            │
│                                                                  │
│  VERY SCALABLE! Even with 1000 employees = ~5.4 GB/year        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```



---

## 🎯 Summary

### What This System Does

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  COMPLETE ATTENDANCE & TRACKING SOLUTION                        │
│                                                                  │
│  ✅ PUNCH-IN                                                    │
│     • Captures employee start location                          │
│     • Validates working hours                                   │
│     • Handles late punch-in approvals                           │
│     • Creates attendance record                                 │
│     • Starts live tracking                                      │
│                                                                  │
│  ✅ LIVE TRACKING                                               │
│     • Continuous GPS monitoring (5-meter accuracy)              │
│     • Real-time WebSocket streaming                             │
│     • Admin dashboard with live map                             │
│     • Route visualization with polylines                        │
│     • Distance calculation (Haversine formula)                  │
│     • Battery optimized (6-11% per hour)                        │
│     • Network efficient (<2 MB per day)                         │
│                                                                  │
│  ✅ PUNCH-OUT                                                   │
│     • Captures employee end location                            │
│     • Validates working hours                                   │
│     • Handles early punch-out approvals                         │
│     • Calculates total work hours                               │
│     • Calculates total distance traveled                        │
│     • Completes attendance record                               │
│     • Stops tracking                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Technologies

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  TECHNOLOGY STACK                                               │
│                                                                  │
│  📱 Mobile: Flutter + Dart                                      │
│     • Cross-platform (Android/iOS)                              │
│     • Native performance                                        │
│     • Rich GPS support                                          │
│                                                                  │
│  🔌 Real-time: Socket.IO (WebSocket)                            │
│     • Bidirectional communication                               │
│     • Low latency                                               │
│     • Auto-reconnect                                            │
│                                                                  │
│  🖥️ Backend: Node.js + Express                                 │
│     • Fast and scalable                                         │
│     • JavaScript ecosystem                                      │
│     • Easy to maintain                                          │
│                                                                  │
│  💾 Database: PostgreSQL + Prisma                               │
│     • Reliable and robust                                       │
│     • ACID compliance                                           │
│     • Type-safe queries                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Solution Works

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SUCCESS FACTORS                                                │
│                                                                  │
│  🎯 REAL-TIME TRACKING                                          │
│     WebSocket provides instant updates to admin dashboard       │
│     No polling delays, no refresh needed                        │
│                                                                  │
│  📍 ACCURATE DISTANCE                                           │
│     Haversine formula follows exact route traveled              │
│     Not straight-line, captures every turn and detour           │
│                                                                  │
│  🔋 BATTERY EFFICIENT                                           │
│     Smart filtering (5m + 3s) reduces GPS queries               │
│     Foreground service optimized for long shifts                │
│                                                                  │
│  📶 NETWORK EFFICIENT                                           │
│     WebSocket uses single persistent connection                 │
│     Minimal data payload (~200 bytes per update)                │
│                                                                  │
│  🔐 SECURE                                                      │
│     JWT authentication on all connections                       │
│     Role-based access control                                   │
│     Data validation at every step                               │
│                                                                  │
│  📊 SCALABLE                                                    │
│     Handles 100+ employees simultaneously                       │
│     Database optimized for geospatial data                      │
│     Route optimization prevents memory issues                   │
│                                                                  │
│  👥 USER FRIENDLY                                               │
│     Simple punch-in/out buttons                                 │
│     Automatic tracking (no user interaction)                    │
│     Clear admin dashboard with live map                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### The Complete Journey

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    EMPLOYEE'S WORK DAY                            ║
║                                                                   ║
║  09:00 AM ─────────────────────────────────────────── 05:30 PM   ║
║     │                                                      │       ║
║     │                                                      │       ║
║     ▼                                                      ▼       ║
║  ┌──────┐                                              ┌──────┐   ║
║  │PUNCH │                                              │PUNCH │   ║
║  │ IN   │                                              │ OUT  │   ║
║  └──────┘                                              └──────┘   ║
║     │                                                      │       ║
║     │ • Get GPS location                                  │       ║
║     │ • Validate hours                                    │       ║
║     │ • Create record                                     │       ║
║     │ • Start tracking                                    │       ║
║     │                                                      │       ║
║     │◄──────────── LIVE TRACKING ────────────────────────►│       ║
║     │                                                      │       ║
║     │ • GPS updates every 5 meters                        │       ║
║     │ • WebSocket streaming                               │       ║
║     │ • Admin sees real-time map                          │       ║
║     │ • Distance accumulates                              │       ║
║     │ • 287 GPS points recorded                           │       ║
║     │                                                      │       ║
║     │                                                      │       ║
║     │                                                      │ • Get GPS location       ║
║     │                                                      │ • Validate hours         ║
║     │                                                      │ • Stop tracking          ║
║     │                                                      │ • Calculate hours (8.5h) ║
║     │                                                      │ • Calculate distance (45.3km) ║
║     │                                                      │ • Complete record        ║
║     │                                                      │                          ║
║     └──────────────────────────────────────────────────────┘                          ║
║                                                                   ║
║  RESULT: Complete attendance record with accurate tracking       ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 📚 Conclusion

This system provides a comprehensive solution for employee attendance and location tracking. It combines modern technologies (Flutter, Socket.IO, PostgreSQL) with smart algorithms (Haversine distance, GPS filtering, route optimization) to deliver:

- **Real-time tracking** with instant updates
- **Accurate distance** following exact routes
- **Battery efficiency** for all-day tracking
- **Network efficiency** with minimal data usage
- **Security** with JWT authentication
- **Scalability** for growing teams
- **User-friendly** interface for both employees and admins

The WebSocket-based architecture ensures that admins can monitor employee locations in real-time without any delays, while the smart filtering and optimization techniques ensure the system remains efficient and scalable.

