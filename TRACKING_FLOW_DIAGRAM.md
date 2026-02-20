# Tracking System Flow Diagram

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP                                │
│                     (Salesman Device)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ GPS Updates Every 5 Seconds
                              │ (latitude, longitude, timestamp)
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐  ┌───────────────────┐
        │   FIREBASE        │  │   POSTGRESQL      │
        │   (Real-time)     │  │   (Permanent)     │
        └───────────────────┘  └───────────────────┘
        │                      │
        │ tracking_live/       │ SalesmanTrackingPoint
        │ {employeeId}         │ Table
        │                      │
        │ Retention: 24 hrs    │ Retention: Forever
        │ Purpose: Live view   │ Purpose: History
        └───────────────────┘  └───────────────────┘
                    │                   │
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐  ┌───────────────────┐
        │   LIVE TAB        │  │  HISTORICAL TAB   │
        │   (Admin UI)      │  │   (Admin UI)      │
        └───────────────────┘  └───────────────────┘
        │                      │
        │ Shows:               │ Shows:
        │ • Current position   │ • Past routes
        │ • Active employees   │ • Any date
        │ • Real-time updates  │ • Polylines
        └───────────────────┘  └───────────────────┘
```

---

## Live Tracking Flow

```
┌──────────────┐
│ Salesman     │
│ Punches In   │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Tracking Service Starts              │
│ • GPS updates every 5 seconds        │
│ • Sends to Firebase + PostgreSQL    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Firebase: tracking_live/{employeeId} │
│ • Overwrites previous position       │
│ • Shows current location only        │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Admin Opens Live Tracking Tab        │
│ • Streams from Firebase              │
│ • Shows marker at current position   │
│ • Updates in real-time               │
└──────────────────────────────────────┘
```

---

## Historical Route Flow

```
┌──────────────┐
│ Admin Selects│
│ Employee +   │
│ Date         │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Frontend Calls Backend API           │
│ GET /tracking/route?                 │
│   employeeId=00028&                  │
│   start=2026-02-19T00:00:00Z&        │
│   end=2026-02-19T23:59:59Z           │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Backend Queries PostgreSQL           │
│ SELECT * FROM SalesmanTrackingPoint  │
│ WHERE employeeId = '00028'           │
│   AND recordedAt BETWEEN start, end  │
│ ORDER BY recordedAt ASC              │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Returns GPS Points (Every 5 sec)     │
│ [                                    │
│   {lat: 23.123, lng: 72.654, ...},   │
│   {lat: 23.124, lng: 72.655, ...},   │
│   {lat: 23.125, lng: 72.656, ...},   │
│   ... (720 points per hour)          │
│ ]                                    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Frontend Converts to LatLng List     │
│ List<LatLng> points = [              │
│   LatLng(23.123, 72.654),            │
│   LatLng(23.124, 72.655),            │
│   LatLng(23.125, 72.656),            │
│   ...                                │
│ ]                                    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│ Draws Polyline on Map                │
│ PolylineLayer(                       │
│   polylines: [                       │
│     Polyline(                        │
│       points: points,                │
│       color: Colors.blue,            │
│     )                                │
│   ]                                  │
│ )                                    │
└──────────────────────────────────────┘
```

---

## UI Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    ENHANCED LIVE TRACKING                    │
│                                                              │
│  ┌────────────────────┬────────────────────┐               │
│  │   Live Tracking    │  Historical Routes │               │
│  └────────────────────┴────────────────────┘               │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                                                       │  │
│  │                    LIVE TAB                          │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │ [Employee 1] [Employee 2] [Employee 3] ...  │    │  │
│  │  │ (Only punched-in employees)                 │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │                                              │    │  │
│  │  │              MAP VIEW                        │    │  │
│  │  │                                              │    │  │
│  │  │    📍 Employee 1 (2m ago)                   │    │  │
│  │  │    📍 Employee 2 (5m ago)                   │    │  │
│  │  │    📍 Employee 3 (1m ago) 🟢               │    │  │
│  │  │                                              │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                                                       │  │
│  │                 HISTORICAL TAB                       │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │ Employee: [Dropdown - All Employees]        │    │  │
│  │  │ Date: [📅 February 19, 2026]                │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │                                              │    │  │
│  │  │              MAP VIEW                        │    │  │
│  │  │                                              │    │  │
│  │  │    🟢 Start (09:00 AM)                      │    │  │
│  │  │     ╲                                        │    │  │
│  │  │      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │    │  │
│  │  │                                        ╱     │    │  │
│  │  │                              🔴 End (06:00 PM)   │    │  │
│  │  │                                              │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │ Points: 7,200 | Distance: 45.3 km | ...    │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Storage Comparison

```
┌─────────────────────────────────────────────────────────────┐
│                        FIREBASE                              │
├─────────────────────────────────────────────────────────────┤
│ Collection: tracking_live                                    │
│                                                              │
│ tracking_live/                                               │
│   ├─ 00028/                                                 │
│   │   ├─ employeeId: "00028"                                │
│   │   ├─ latitude: 23.123456                                │
│   │   ├─ longitude: 72.654321                               │
│   │   ├─ updatedAt: 2026-02-20T10:30:45Z                   │
│   │   └─ ... (OVERWRITES every 5 seconds)                   │
│   │                                                          │
│   ├─ 00029/                                                 │
│   │   └─ ... (current position only)                        │
│   │                                                          │
│   └─ ...                                                     │
│                                                              │
│ Purpose: Show current position in Live Tab                   │
│ Retention: Last 24 hours (auto-cleanup)                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      POSTGRESQL                              │
├─────────────────────────────────────────────────────────────┤
│ Table: SalesmanTrackingPoint                                 │
│                                                              │
│ ┌────┬──────────┬─────────────┬──────────┬───────────┬─────┐│
│ │ id │employeeId│attendanceId │ latitude │ longitude │ ... ││
│ ├────┼──────────┼─────────────┼──────────┼───────────┼─────┤│
│ │ 1  │  00028   │  clx123...  │ 23.12345 │ 72.65432  │ ... ││
│ │ 2  │  00028   │  clx123...  │ 23.12346 │ 72.65433  │ ... ││
│ │ 3  │  00028   │  clx123...  │ 23.12347 │ 72.65434  │ ... ││
│ │ ...│   ...    │    ...      │   ...    │   ...     │ ... ││
│ │7200│  00028   │  clx123...  │ 23.15678 │ 72.68765  │ ... ││
│ └────┴──────────┴─────────────┴──────────┴───────────┴─────┘│
│                                                              │
│ Purpose: Store all points for historical routes             │
│ Retention: Permanent (all historical data)                  │
│ Points: ~7,200 per 10-hour shift (every 5 seconds)          │
└─────────────────────────────────────────────────────────────┘
```

---

## Polyline Generation

```
Step 1: Fetch Points from PostgreSQL
┌─────────────────────────────────────┐
│ GET /tracking/route?                │
│   employeeId=00028&                 │
│   start=2026-02-19T00:00:00Z&       │
│   end=2026-02-19T23:59:59Z          │
└─────────────────────────────────────┘
                 ↓
Step 2: Backend Returns GPS Points
┌─────────────────────────────────────┐
│ [                                   │
│   {lat: 23.123, lng: 72.654, t: 0s} │
│   {lat: 23.124, lng: 72.655, t: 5s} │
│   {lat: 23.125, lng: 72.656, t:10s} │
│   {lat: 23.126, lng: 72.657, t:15s} │
│   ... (every 5 seconds)             │
│   {lat: 23.567, lng: 72.987, t:36000s}│
│ ]                                   │
└─────────────────────────────────────┘
                 ↓
Step 3: Convert to LatLng List
┌─────────────────────────────────────┐
│ List<LatLng> points = [             │
│   LatLng(23.123, 72.654),           │
│   LatLng(23.124, 72.655),           │
│   LatLng(23.125, 72.656),           │
│   LatLng(23.126, 72.657),           │
│   ...                               │
│   LatLng(23.567, 72.987),           │
│ ]                                   │
└─────────────────────────────────────┘
                 ↓
Step 4: Draw Polyline
┌─────────────────────────────────────┐
│        MAP WITH POLYLINE            │
│                                     │
│    🟢 Start                         │
│     ╲                               │
│      ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                              ╱      │
│                    🔴 End           │
│                                     │
│ Smooth line connecting all points   │
│ (7,200 points = very smooth!)       │
└─────────────────────────────────────┘
```

---

## Time-based Point Distribution

```
10-Hour Shift (09:00 AM - 06:00 PM)
═══════════════════════════════════════════════════════════

09:00 AM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
         (720 points in first hour)

10:00 AM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
         (720 points in second hour)

11:00 AM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

12:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

01:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

02:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

03:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

04:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

05:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●

06:00 PM ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
         (720 points in last hour)

═══════════════════════════════════════════════════════════
Total: 7,200 GPS points (one every 5 seconds)
Result: Extremely smooth polyline showing exact route
```

---

## Summary

### ✅ Data Storage (Already Working)
- GPS points stored every 5 seconds
- PostgreSQL has all historical data
- Firebase has real-time current position

### ✅ Backend API (Already Working)
- `/tracking/route` endpoint fetches historical points
- Supports date range queries
- Returns all GPS points with lat/long

### ✨ New UI (Just Created)
- **Live Tab**: Shows active employees only
- **Historical Tab**: Shows any past date with polylines
- Smooth polylines from 5-second GPS points

### 🎯 Result
Perfect historical route tracking with smooth polylines! 🚀

---

*The system is complete and ready to use!*
