import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Production WebSocket Server for Real-time Live Location Tracking
 * 
 * Features:
 * - JWT Authentication
 * - In-memory location storage
 * - Admin broadcast system
 * - Heartbeat monitoring
 * - Memory cleanup
 * - Route persistence on disconnect
 */

class LiveTrackingServer {
    constructor() {
        this.wss = null;

        // In-memory structures
        this.salesmanSockets = new Map(); // salesmanId -> WebSocket
        this.adminSockets = new Set(); // Set of admin WebSockets
        this.salesmanLocations = new Map(); // salesmanId -> { lastLocation, route[] }

        // Heartbeat monitoring
        this.heartbeatInterval = null;
        this.HEARTBEAT_INTERVAL = 30000; // 30 seconds
        this.CONNECTION_TIMEOUT = 60000; // 60 seconds
    }

    /**
     * Initialize WebSocket server
     * @param {number} port - WebSocket port
     * @param {Object} httpServer - Optional HTTP server for upgrade
     */
    initialize(port = 8081, httpServer = null) {
        const options = {
            port: httpServer ? undefined : port,
            server: httpServer || undefined,
            verifyClient: this.verifyClient.bind(this)
        };

        this.wss = new WebSocketServer(options);

        this.wss.on('connection', this.handleConnection.bind(this));
        this.startHeartbeat();

        console.log(`🔗 WebSocket Live Tracking Server running on port ${port}`);
    }

    /**
     * Verify client connection with JWT authentication
     */
    verifyClient(info) {
        try {
            const url = new URL(info.req.url, 'ws://localhost');
            const token = url.searchParams.get('token');

            if (!token) {
                console.log('❌ WebSocket connection rejected: No token provided');
                return false;
            }

            // Handle development mode token (for testing only)
            if (token === 'dev_mode_token') {
                console.log('✅ WebSocket connection verified for development mode');
                const userType = url.searchParams.get('userType');
                const employeeId = url.searchParams.get('employeeId');

                if (userType === 'salesman' && employeeId) {
                    info.req.user = {
                        id: employeeId,
                        roles: ['salesman'],
                        name: `Dev Salesman ${employeeId}`
                    };
                    console.log(`🔧 Dev mode salesman connection: ${employeeId}`);
                } else {
                    info.req.user = {
                        id: 'dev_admin',
                        roles: ['admin'],
                        name: 'Dev Admin'
                    };
                    console.log('🔧 Dev mode admin connection');
                }
                return true;
            }

            // Verify JWT token for production
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

            // Store JWT payload temporarily, we'll fetch user details in handleConnection
            info.req.jwtPayload = decoded;

            console.log(`✅ WebSocket JWT verified for user: ${decoded.id}`);
            return true;

        } catch (error) {
            console.log('❌ WebSocket authentication failed:', error.message);
            return false;
        }
    }

    /**
     * Get user details from JWT payload
     */
    async getUserFromJWT(jwtPayload) {
        try {
            const user = await prisma.user.findUnique({
                where: { id: jwtPayload.id },
                select: {
                    id: true,
                    name: true,
                    roleId: true,
                    isActive: true
                }
            });

            if (!user || !user.isActive) {
                console.log(`❌ User not found or inactive: ${jwtPayload.id}`);
                return null;
            }

            // Map role IDs to role names - this matches your database structure
            const roleMapping = {
                'R001': 'admin',
                'R002': 'salesman',
                'R003': 'telecaller'
            };

            // Get role from roleId field (primary source based on your DB)
            let roleName = 'unknown';

            // 1. First check user's roleId from database
            if (user.roleId && roleMapping[user.roleId]) {
                roleName = roleMapping[user.roleId];
            }
            // 2. Fallback to JWT roleId if database roleId is null
            else if (jwtPayload.roleId && roleMapping[jwtPayload.roleId]) {
                roleName = roleMapping[jwtPayload.roleId];
            }

            console.log(`🔍 User ${user.id} (${user.name}) role: ${user.roleId} -> ${roleName}`);

            return {
                id: user.id,
                name: user.name,
                roles: [roleName]
            };
        } catch (error) {
            console.error('Error fetching user from database:', error);
            return null;
        }
    }

    /**
     * Handle new WebSocket connection
     */
    async handleConnection(ws, req) {
        let user = req.user;

        // If we have a JWT payload instead of user object, fetch user details
        if (!user && req.jwtPayload) {
            user = await this.getUserFromJWT(req.jwtPayload);
            if (!user) {
                console.log('❌ User not found in database, closing connection');
                ws.close(1008, 'User not found');
                return;
            }
        }

        const userId = user.id;
        const userRole = user.roles?.[0] || 'unknown';

        // Set connection metadata
        ws.userId = userId;
        ws.userRole = userRole;
        ws.isAlive = true;
        ws.lastPong = Date.now();

        // Handle different user types
        if (userRole === 'admin') {
            this.handleAdminConnection(ws, userId);
        } else if (userRole === 'salesman') {
            this.handleSalesmanConnection(ws, userId);
        } else {
            console.log(`⚠️ Unknown user role: ${userRole}`);
            ws.close(1008, 'Unknown user role');
            return;
        }

        // Set up message handlers
        ws.on('message', (data) => this.handleMessage(ws, data));
        ws.on('close', () => this.handleDisconnection(ws));
        ws.on('error', (error) => this.handleError(ws, error));
        ws.on('pong', () => {
            ws.isAlive = true;
            ws.lastPong = Date.now();
        });

        console.log(`🔗 ${userRole} connected: ${userId} (${user.name})`);
    }

    /**
     * Handle admin connection
     */
    handleAdminConnection(ws, adminId) {
        this.adminSockets.add(ws);

        // Send current salesman locations to new admin
        const currentLocations = {};
        for (const [salesmanId, locationData] of this.salesmanLocations) {
            if (locationData.lastLocation) {
                currentLocations[salesmanId] = locationData.lastLocation;
            }
        }

        if (Object.keys(currentLocations).length > 0) {
            this.sendToSocket(ws, {
                type: 'INITIAL_LOCATIONS',
                locations: currentLocations
            });
        }
    }

    /**
     * Handle salesman connection
     */
    handleSalesmanConnection(ws, salesmanId) {
        // Close existing connection if any
        const existingSocket = this.salesmanSockets.get(salesmanId);
        if (existingSocket && existingSocket.readyState === ws.OPEN) {
            existingSocket.close(1000, 'New connection established');
        }

        this.salesmanSockets.set(salesmanId, ws);

        // Initialize location data if not exists
        if (!this.salesmanLocations.has(salesmanId)) {
            this.salesmanLocations.set(salesmanId, {
                lastLocation: null,
                route: []
            });
        }
    }

    /**
     * Handle incoming messages
     */
    handleMessage(ws, data) {
        try {
            const message = JSON.parse(data.toString());

            switch (message.type) {
                case 'LOCATION':
                    this.handleLocationUpdate(ws, message);
                    break;

                case 'PING':
                    this.sendToSocket(ws, { type: 'PONG' });
                    break;

                default:
                    console.log(`⚠️ Unknown message type: ${message.type}`);
            }

        } catch (error) {
            console.error('❌ Error parsing message:', error);
            this.sendToSocket(ws, {
                type: 'ERROR',
                message: 'Invalid message format'
            });
        }
    }

    /**
     * Handle location update from salesman
     */
    async handleLocationUpdate(ws, message) {
        const { salesmanId, lat, lng, timestamp, isHomeLocation } = message;

        // Validate message format
        if (!salesmanId || typeof lat !== 'number' || typeof lng !== 'number') {
            console.log('❌ Invalid location message format');
            return;
        }

        // Validate coordinates
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            console.log('❌ Invalid GPS coordinates');
            return;
        }

        // Ensure salesman owns this connection
        if (ws.userId !== salesmanId) {
            console.log(`❌ Unauthorized location update: ${ws.userId} tried to update ${salesmanId}`);
            return;
        }

        const locationData = this.salesmanLocations.get(salesmanId);
        if (!locationData) {
            console.log(`❌ No location data found for salesman: ${salesmanId}`);
            return;
        }

        const newLocation = {
            lat,
            lng,
            timestamp: timestamp || Date.now(),
            isHomeLocation: isHomeLocation || false
        };

        // Calculate distance from last location
        let distanceFromLast = 0;
        if (locationData.lastLocation) {
            distanceFromLast = this.calculateDistance(
                locationData.lastLocation.lat, locationData.lastLocation.lng,
                lat, lng
            );
        }

        // Update last known location
        locationData.lastLocation = newLocation;

        // Append to route (with distance filtering to avoid spam)
        if (this.shouldAddToRoute(locationData.route, newLocation)) {
            locationData.route.push(newLocation);

            // Store location in database immediately for route visualization
            await this.storeLocationInDatabase(salesmanId, newLocation);
        }

        // Calculate total distance traveled
        const totalDistanceKm = this.calculateTotalRouteDistance(locationData.route);

        // Broadcast to all connected admins with distance info
        this.broadcastToAdmins({
            type: 'LOCATION',
            salesmanId,
            lat,
            lng,
            timestamp: newLocation.timestamp,
            distanceFromLastKm: Math.round(distanceFromLast * 1000) / 1000,
            totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
            totalPoints: locationData.route.length,
            isHomeLocation: newLocation.isHomeLocation
        });

        const homeTag = newLocation.isHomeLocation ? ' (HOME)' : '';
        console.log(`📍 Location updated for ${salesmanId}${homeTag}: ${lat.toFixed(6)}, ${lng.toFixed(6)} | Distance: ${totalDistanceKm.toFixed(2)} km`);
    }

    /**
     * Calculate total distance for a route
     */
    calculateTotalRouteDistance(route) {
        if (!route || route.length < 2) return 0;

        let totalDistance = 0;
        for (let i = 1; i < route.length; i++) {
            totalDistance += this.calculateDistance(
                route[i - 1].lat, route[i - 1].lng,
                route[i].lat, route[i].lng
            );
        }
        return totalDistance;
    }

    /**
     * Store location update in database for route visualization
     * Includes deduplication to avoid storing duplicate points from REST API
     */
    async storeLocationInDatabase(salesmanId, location) {
        try {
            // Find the current active attendance session for this salesman
            const activeAttendance = await prisma.attendance.findFirst({
                where: {
                    employeeId: salesmanId,
                    status: 'active'
                },
                orderBy: {
                    punchInTime: 'desc'
                }
            });

            if (!activeAttendance) {
                console.log(`⚠️ No active attendance found for salesman ${salesmanId}`);
                return;
            }

            // Check for recent duplicate points (within 5 seconds and 10 meters)
            const recentPoint = await prisma.salesmanRouteLog.findFirst({
                where: {
                    attendanceId: activeAttendance.id,
                    recordedAt: {
                        gte: new Date(Date.now() - 5000) // Within last 5 seconds
                    }
                },
                orderBy: { recordedAt: 'desc' }
            });

            if (recentPoint) {
                const distance = this.calculateDistance(
                    recentPoint.latitude, recentPoint.longitude,
                    location.lat, location.lng
                );
                if (distance < 10) { // Less than 10 meters
                    console.log(`⏭️ Skipping duplicate point for ${salesmanId} (${distance.toFixed(1)}m from recent)`);
                    return;
                }
            }

            // Check if this is the first point (home location) - use client flag or check database
            const existingPointsCount = await prisma.salesmanRouteLog.count({
                where: { attendanceId: activeAttendance.id }
            });

            const isFirstPoint = existingPointsCount === 0;
            const shouldMarkAsHome = isFirstPoint || location.isHomeLocation === true;

            // Store the location point in the database
            await prisma.salesmanRouteLog.create({
                data: {
                    employeeId: salesmanId,
                    attendanceId: activeAttendance.id,
                    latitude: location.lat,
                    longitude: location.lng,
                    recordedAt: new Date(location.timestamp),
                    isHomeLocation: shouldMarkAsHome
                }
            });

            console.log(`💾 Stored location in database for ${salesmanId}${shouldMarkAsHome ? ' (HOME)' : ''}`);
        } catch (error) {
            console.error(`❌ Error storing location in database for ${salesmanId}:`, error);
        }
    }

    /**
     * Check if location should be added to route (distance filtering)
     */
    shouldAddToRoute(route, newLocation) {
        if (route.length === 0) return true;

        const lastLocation = route[route.length - 1];
        const distance = this.calculateDistance(
            lastLocation.lat, lastLocation.lng,
            newLocation.lat, newLocation.lng
        );

        // Only add if moved more than 10 meters
        return distance >= 10;
    }

    /**
     * Calculate distance between two points in meters
     */
    calculateDistance(lat1, lng1, lat2, lng2) {
        const R = 6371000; // Earth's radius in meters
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLng = (lng2 - lng1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng / 2) * Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Broadcast message to all connected admins
     */
    broadcastToAdmins(message) {
        const messageStr = JSON.stringify(message);
        let sentCount = 0;

        for (const adminSocket of this.adminSockets) {
            if (adminSocket.readyState === adminSocket.OPEN) {
                adminSocket.send(messageStr);
                sentCount++;
            }
        }

        if (sentCount > 0) {
            console.log(`📡 Broadcasted to ${sentCount} admin(s)`);
        }
    }

    /**
     * Send message to specific socket
     */
    sendToSocket(ws, message) {
        if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify(message));
        }
    }

    /**
     * Handle connection disconnection
     */
    handleDisconnection(ws) {
        const userId = ws.userId;
        const userRole = ws.userRole;

        if (userRole === 'admin') {
            this.adminSockets.delete(ws);
            console.log(`🔌 Admin disconnected: ${userId}`);

        } else if (userRole === 'salesman') {
            this.salesmanSockets.delete(userId);

            // Persist route to database before cleanup
            this.persistSalesmanRoute(userId);

            console.log(`🔌 Salesman disconnected: ${userId}`);
        }
    }

    /**
     * Persist salesman route to database on disconnect
     * Since we now store locations in real-time, this just clears the in-memory route
     */
    async persistSalesmanRoute(salesmanId) {
        try {
            const locationData = this.salesmanLocations.get(salesmanId);
            if (!locationData || locationData.route.length === 0) {
                return;
            }

            console.log(`💾 Clearing in-memory route for ${salesmanId}: ${locationData.route.length} points (already stored in database)`);

            // Clear route after disconnect since points are already stored in database
            locationData.route = [];

        } catch (error) {
            console.error(`❌ Error clearing route for ${salesmanId}:`, error);
        }
    }

    /**
     * Handle WebSocket errors
     */
    handleError(ws, error) {
        console.error(`❌ WebSocket error for ${ws.userId}:`, error);
    }

    /**
     * Start heartbeat monitoring
     */
    startHeartbeat() {
        this.heartbeatInterval = setInterval(() => {
            const now = Date.now();

            this.wss.clients.forEach((ws) => {
                if (!ws.isAlive || (now - ws.lastPong) > this.CONNECTION_TIMEOUT) {
                    console.log(`💔 Terminating stale connection: ${ws.userId}`);
                    ws.terminate();
                    return;
                }

                ws.isAlive = false;
                ws.ping();
            });

        }, this.HEARTBEAT_INTERVAL);
    }

    /**
     * Get server statistics
     */
    getStats() {
        return {
            connectedSalesmen: this.salesmanSockets.size,
            connectedAdmins: this.adminSockets.size,
            trackedSalesmen: this.salesmanLocations.size,
            totalRoutePoints: Array.from(this.salesmanLocations.values())
                .reduce((total, data) => total + data.route.length, 0)
        };
    }

    /**
     * Cleanup and shutdown
     */
    shutdown() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
        }

        if (this.wss) {
            this.wss.close();
        }

        // Persist all routes before shutdown
        for (const salesmanId of this.salesmanSockets.keys()) {
            this.persistSalesmanRoute(salesmanId);
        }

        console.log('🛑 Live Tracking WebSocket Server shutdown');
    }
}

export default LiveTrackingServer;