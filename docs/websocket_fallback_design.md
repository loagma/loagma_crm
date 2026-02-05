# Realtime tracking – WebSocket fallback (design only)

Current production architecture:

- **Realtime channel:** Firebase Firestore (`tracking_live` collection) with
  `snapshots()` powering the admin `LiveTrackingScreen`.
- **Persistence:** Node/Express backend (`/tracking/point`) writing to
  `SalesmanTrackingPoint` via Prisma; admin route details come from
  `/tracking/route`.
- **Mobile client:** `TrackingService` in the Flutter app sends every point to
  both Firestore and the backend.

If we ever need to replace Firestore as the realtime layer (e.g. cost or
vendor lock‑in), we can re‑use the existing HTTP pipeline and add a thin
WebSocket layer:

1. **Backend**
   - Add `socket.io` (or `ws`) server alongside the existing Express app in
     `backend/src/server.js`.
   - In the `/tracking/point` handler (or in a shared tracking service
     module), after persisting the point, emit an event:
     - Event name: `tracking:update`
     - Payload: `{ employeeId, attendanceId, latitude, longitude, speed, accuracy, recordedAt }`.
   - Optionally add a room per employee or per admin tenant so only relevant
     clients receive updates.

2. **Salesman app**
   - **No WebSocket connection required.**
   - Continue sending points via HTTP `POST /tracking/point` and Firestore
     (during migration). Once WebSockets are stable, Firestore writes for
     `tracking_live` could be removed if desired.

3. **Admin app**
   - Add a WebSocket client (for example using `socket_io_client`) that:
     - Connects to `wss://<backend-host>/tracking`.
     - Subscribes to `tracking:update`.
     - Updates the in‑memory list of live points and polylines in
       `LiveTrackingScreen` on each event.
   - During migration we can:
     - Keep Firestore snapshot as a fallback.
     - Prefer WebSocket updates when available (lower latency, fully owned).

4. **Failure / offline behaviour**
   - If the WebSocket disconnects:
     - Admin app can automatically fall back to Firestore snapshots (if still
       enabled) or a lightweight polling endpoint (e.g.
       `/tracking/live?since=<timestamp>`).
   - Since persistence always goes through `/tracking/point`, historical data
     and routes remain unaffected by the realtime channel choice.

This design keeps WebSockets optional and layered on top of the existing
tracking API, so we can switch between Firestore and WebSocket streaming
without changing the salesman app’s core tracking logic.

