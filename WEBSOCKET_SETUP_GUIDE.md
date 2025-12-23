# WebSocket Setup Guide

## Installation Steps

### 1. Install Flutter Dependencies
```bash
cd loagma_crm
flutter pub get
```

### 2. Install Backend Dependencies
```bash
cd backend
npm install
```

## Dependencies Added

### Flutter (`loagma_crm/pubspec.yaml`)
- `web_socket_channel: ^2.4.0` - WebSocket client for Flutter

### Backend (`backend/package.json`)
- `ws: ^8.18.0` - WebSocket server for Node.js

## Verification

### Check Flutter Dependencies
```bash
cd loagma_crm
flutter pub deps
```

### Check Backend Dependencies
```bash
cd backend
npm list ws
```

## Running the Application

### 1. Start Backend Server
```bash
cd backend
npm run dev
```
This will start:
- REST API on port 5000
- WebSocket server on port 8081

### 2. Start Flutter App
```bash
cd loagma_crm
flutter run
```

## Testing WebSocket Connection

### Backend Logs
Look for these messages when starting the backend:
```
✅ Server running on http://0.0.0.0:5000
🔗 WebSocket Live Tracking Server running on port 8081
```

### Flutter Logs
When salesman punches in, look for:
```
✅ WebSocket live location tracking started
📍 Location sent: 28.123456, 77.654321
```

When admin opens live tracking, look for:
```
✅ Admin WebSocket connected successfully
📍 Location update for SM101: 28.123456, 77.654321
```

## Troubleshooting

### Flutter Issues
- **Import Error**: Run `flutter pub get` to install dependencies
- **Build Error**: Run `flutter clean && flutter pub get`

### Backend Issues
- **Module Not Found**: Run `npm install` to install dependencies
- **Port Conflict**: Change `WS_PORT` in environment variables

### WebSocket Connection Issues
- **Connection Failed**: Check if backend is running on correct ports
- **Authentication Failed**: Verify JWT token is valid
- **Network Error**: Check firewall settings for port 8081

## Environment Variables

Add to your backend `.env` file:
```bash
WS_PORT=8081
JWT_SECRET=your-secret-key
```

## Production Deployment

### Backend
- Ensure port 8081 is open in firewall
- Use WSS (secure WebSocket) for HTTPS domains
- Configure load balancer for WebSocket support

### Flutter
- Update WebSocket URL for production server
- Test on different network conditions
- Verify auto-reconnect functionality

## Status: ✅ Ready to Install

Run the installation commands above to set up WebSocket dependencies.