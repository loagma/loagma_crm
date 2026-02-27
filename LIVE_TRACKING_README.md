## Live Tracking Module – Key Files

**Flutter app**
- `loagma_crm/lib/screens/salesman/enhanced_punch_screen.dart`
- `loagma_crm/lib/services/attendance_session_manager.dart`
- `loagma_crm/lib/services/socket_tracking_service.dart`
- `loagma_crm/lib/services/location_service.dart`
- `loagma_crm/lib/services/tracking_api_service.dart`
- `loagma_crm/lib/services/tracking_service.dart`
- `loagma_crm/lib/screens/admin/socket_live_tracking_screen.dart`
- `loagma_crm/lib/screens/admin/live_tracking_screen.dart`
- `loagma_crm/lib/screens/admin/enhanced_live_tracking_screen.dart`

**Backend (Node.js)**
- `backend/src/socket/socketServer.js`
- `backend/src/controllers/trackingController.js`
- `backend/src/routes/trackingRoutes.js`

**Database**
- Table: `SalesmanTrackingPoint` (stores GPS tracking points)

