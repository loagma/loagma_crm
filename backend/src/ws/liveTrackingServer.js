import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Production WebSocket Server for Real-time Live Location Tracking
 * 
 * Features:
 * - JWT Authentication
 * - Real-time location broadcast to admins
 * - Accurate distance calculation using Haversine formula
 * - Route persistence in database
 * - Heartbeat monitoring for connection health
 * - Auto-cleanup on disconnect
 */

class LiveTrackingServer {
    constructor() {
        this.wss = null;

        // In-memory structures for real-time tracking
        this.salesmanSockets = new Map(); // salesmanId -> WebSocket
        this.adminSockets = new Set(); // Set of admin WebSockets
        this.salesmanLocations = new Map(); // salesmanId -> { lastLocation, route[], totalDistanceKm }

        // Heartbeat monitoring
        this.heartbeatInterval = null;
        this.HEARTBEAT_INTERVAL = 30000; // 30 seconds
        this.CONNECTION_TIMEOUT = 90000; // 90 seconds
    }

    /**
     * Initialize WebSocket server
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
                console.log('❌ WebSocket rejected: No token');
                return false;
            }

            // Development mode token
            if (token === 'dev_mode_token') {
                const userType = url.searchParams.get('userType');
                const employeeId = url.searchParams.get('employeeId');

                if (userType === 'salesman' && employeeId) {
                    info.req.user = {
                        id: employeeId,
                        roles: ['salesman'],
                        name: `Dev Salesman ${employeeId}`
                    };
                } else {
                    info.req.user = {
                        id: 'dev_admin',
                        roles: ['admin'],
                        name: 'Dev Admin'
                    };
                }
                return true;
            }

            // Verify JWT token
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
            info.req.jwtPayload = decoded;
            console.log(`✅ WebSocket JWT verified: ${decoded.id}`);
            return true;

        } catch (error) {
            console.log('❌ WebSocket auth failed:', error.message);
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
                select: { id: true, name: true, roleId: true, isActive: true }
            });

            if (!user || !user.isActive) return null;

            const roleMapping = {
                'R001': 'admin',
                'R002': 'salesman',
                'R003': 'telecaller'
            };

            let roleName = 'unknown';
            if (user.roleId && roleMapping[user.roleId]) {
                roleName = roleMapping[user.roleId];
            } else if (jwtPayload.roleId && roleMapping[jwtPayload.roleId]) {
                roleName = roleMapping[jwtPayload.roleId];
            }

            return { id: user.id, name: user.name, roles: [roleName] };
        } catch (error) {
            console.error('Error fetching user:', error);
            return null;
        }
    }

    /**
     * Handle new WebSocket connection
     */
    async handleConnection(ws, req) {
        let user = req.user;

        if (!user && req.jwtPayload) {
            user = await this.getUserFromJWT(req.jwtPayload);
            if (!user) {
                ws.close(1008, 'User not found');
                return;
            }
        }

        const userId = user.id;
        const userRole = user.roles?.[0] || 'unknown';

        ws.userId = userId;
        ws.userRole = userRole;
        ws.isAlive = true;
        ws.lastPong = Date.now();

        if (userRole === 'admin') {
            this.handleAdminConnection(ws, userId);
        } else if (userRole === 'salesman') {
            this.handleSalesmanConnection(ws, userId);
        } else {
            ws.close(1008, 'Unknown user role');
            return;
        }

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
     * Handle admin connection - send current salesman locations
     */
    handleAdminConnection(ws, adminId) {
        this.adminSockets.add(ws);

        // Send all current salesman locations to new admin
        const currentLocations = {};
        for (const [salesmanId, locationData] of this.salesmanLocations) {
            if (locationData.lastLocation) {
                currentLocations[salesmanId] = {
                    ...locationData.lastLocation,
                    totalDistanceKm: locationData.totalDistanceKm || 0,
                    totalPoints: locationData.route?.length || 0
                };
            }
        }

        if (Object.keys(currentLocations).length > 0) {
            this.sendToSocket(ws, {
                type: 'INITIAL_LOCATIONS',
                locations: currentLocations
            });
        }

        console.log(`📡 Admin ${adminId} connected, sent ${Object.keys(currentLocations).length} locations`);
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

        // Initialize or preserve location data
        if (!this.salesmanLocations.has(salesmanId)) {
            this.salesmanLocations.set(salesmanId, {
                lastLocation: null,
                route: [],
                totalDistanceKm: 0
            });
        }

        console.log(`📍 Salesman ${salesmanId} connected`);
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
            this.sendToSocket(ws, { type: 'ERROR', message: 'Invalid message format' });
        }
    }

    /**
     * Handle location update from salesman
     */
    async handleLocationUpdate(ws, message) {
        const { salesmanId, lat, lng, timestamp, isHomeLocation, accuracy, speed } = message;

        // Validate
        if (!salesmanId || typeof lat !== 'number' || typeof lng !== 'number') {
            console.log('❌ Invalid location message');
            return;
        }

        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            console.log('❌ Invalid GPS coordinates');
            return;
        }

        if (ws.userId !== salesmanId) {
            console.log(`❌ Unauthorized: ${ws.userId} tried to update ${salesmanId}`);
            return;
        }

        let locationData = this.salesmanLocations.get(salesmanId);
        if (!locationData) {
            locationData = { lastLocation: null, route: [], totalDistanceKm: 0 };
            this.salesmanLocations.set(salesmanId, locationData);
        }

        const newLocation = {
            lat,
            lng,
            timestamp: timestamp || Date.now(),
            isHomeLocation: isHomeLocation || false,
            accuracy: accuracy || null,
            speed: speed || null
        };

        // Calculate distance from last location
        let distanceFromLastKm = 0;
        if (locationData.lastLocation) {
            distanceFromLastKm = this.calculateDistanceKm(
                locationData.lastLocation.lat, locationData.lastLocation.lng,
                lat, lng
            );
        }

        // Update total distance
        if (distanceFromLastKm > 0.005) { // Only add if > 5 meters
            locationData.totalDistanceKm += distanceFromLastKm;
        }

        // Update last location
        locationData.lastLocation = newLocation;

        // Add to route if significant movement (> 5 meters)
        if (this.shouldAddToRoute(locationData.route, newLocation)) {
            locationData.route.push(newLocation);

            // Store in database
            await this.storeLocationInDatabase(salesmanId, newLocation, locationData.totalDistanceKm);
        }

        // Broadcast to all admins with full data
        this.broadcastToAdmins({
            type: 'LOCATION',
            salesmanId,
            lat,
            lng,
            timestamp: newLocation.timestamp,
            distanceFromLastKm: Math.round(distanceFromLastKm * 1000) / 1000,
            totalDistanceKm: Math.round(locationData.totalDistanceKm * 100) / 100,
            totalPoints: locationData.route.length,
            isHomeLocation: newLocation.isHomeLocation,
            accuracy: newLocation.accuracy,
            speed: newLocation.speed
        });

        // Send acknowledgment to salesman
        this.sendToSocket(ws, { type: 'ACK', timestamp: newLocation.timestamp });

        const homeTag = newLocation.isHomeLocation ? ' (HOME)' : '';
        console.log(`📍 ${salesmanId}${homeTag}: ${lat.toFixed(6)}, ${lng.toFixed(6)} | ${locationData.totalDistanceKm.toFixed(2)} km | ${locationData.route.length} pts`);
    }

    /**
     * Calculate distance in kilometers using Haversine formula
     */
    calculateDistanceKm(lat1, lng1, lat2, lng2) {
        const R = 6371; // Earth's radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLng = (lng2 - lng1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng / 2) * Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Check if location should be added to route (distance filtering)
     */
    shouldAddToRoute(route, newLocation) {
        if (route.length === 0) return true;

        const lastLocation = route[route.length - 1];
        const distance = this.calculateDistanceKm(
            lastLocation.lat, lastLocation.lng,
            newLocation.lat, newLocation.lng
        );

        // Add if moved more than 5 meters
        return distance >= 0.005;
    }

    /**
     * Store location in database
     */
    async storeLocationInDatabase(salesmanId, location, totalDistanceKm) {
        try {
            // Find active attendance
            const activeAttendance = await prisma.attendance.findFirst({
                where: { employeeId: salesmanId, status: 'active' },
                orderBy: { punchInTime: 'desc' }
            });

            if (!activeAttendance) {
                console.log(`⚠️ No active attendance for ${salesmanId}`);
                return;
            }

            // Check for recent duplicate
            const recentPoint = await prisma.salesmanRouteLog.findFirst({
                where: {
                    attendanceId: activeAttendance.id,
                    recordedAt: { gte: new Date(Date.now() - 5000) }
                },
                orderBy: { recordedAt: 'desc' }
            });

            if (recentPoint) {
                const distance = this.calculateDistanceKm(
                    recentPoint.latitude, recentPoint.longitude,
                    location.lat, location.lng
                );
                if (distance < 0.005) return; // Skip if < 5 meters
            }

            // Check if first point (home location)
            const existingCount = await prisma.salesmanRouteLog.count({
                where: { attendanceId: activeAttendance.id }
            });

            const isFirstPoint = existingCount === 0;
            const shouldMarkAsHome = isFirstPoint || location.isHomeLocation === true;

            // Store the point
            try {
                await prisma.salesmanRouteLog.create({
                    data: {
                        employeeId: salesmanId,
                        attendanceId: activeAttendance.id,
                        latitude: location.lat,
                        longitude: location.lng,
                        speed: location.speed,
                        accuracy: location.accuracy,
                        recordedAt: new Date(location.timestamp),
                        isHomeLocation: shouldMarkAsHome
                    }
                });
            } catch (createError) {
                // Fallback without isHomeLocation if column doesn't exist
                if (createError.code === 'P2022') {
                    await prisma.salesmanRouteLog.create({
                        data: {
                            employeeId: salesmanId,
                            attendanceId: activeAttendance.id,
                            latitude: location.lat,
                            longitude: location.lng,
                            speed: location.speed,
                            accuracy: location.accuracy,
                            recordedAt: new Date(location.timestamp)
                        }
                    });
                } else {
                    throw createError;
                }
            }

            // Update attendance with total distance
            await prisma.attendance.update({
                where: { id: activeAttendance.id },
                data: { totalDistanceKm: Math.round(totalDistanceKm * 100) / 100 }
            });

            console.log(`💾 Stored: ${salesmanId}${shouldMarkAsHome ? ' (HOME)' : ''}`);
        } catch (error) {
            console.error(`❌ DB error for ${salesmanId}:`, error.message);
        }
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
            console.log(`📡 Broadcast to ${sentCount} admin(s)`);
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
     * Handle disconnection
     */
    handleDisconnection(ws) {
        const userId = ws.userId;
        const userRole = ws.userRole;

        if (userRole === 'admin') {
            this.adminSockets.delete(ws);
            console.log(`🔌 Admin disconnected: ${userId}`);

        } else if (userRole === 'salesman') {
            this.salesmanSockets.delete(userId);

            // Keep location data for reconnection, clear route after some time
            const locationData = this.salesmanLocations.get(userId);
            if (locationData) {
                console.log(`🔌 Salesman ${userId} disconnected | ${locationData.totalDistanceKm.toFixed(2)} km | ${locationData.route.length} pts`);
            }
        }
    }

    /**
     * Handle WebSocket errors
     */
    handleError(ws, error) {
        console.error(`❌ WebSocket error for ${ws.userId}:`, error.message);
    }

    /**
     * Start heartbeat monitoring
     */
    startHeartbeat() {
        this.heartbeatInterval = setInterval(() => {
            const now = Date.now();

            this.wss.clients.forEach((ws) => {
                if (!ws.isAlive || (now - ws.lastPong) > this.CONNECTION_TIMEOUT) {
                    console.log(`💔 Terminating stale: ${ws.userId}`);
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
                .reduce((total, data) => total + (data.route?.length || 0), 0)
        };
    }

    /**
     * Shutdown server
     */
    shutdown() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
        }

        if (this.wss) {
            this.wss.close();
        }

        console.log('🛑 Live Tracking WebSocket Server shutdown');
    }
}

export default LiveTrackingServer;
