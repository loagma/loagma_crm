import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import prisma from '../config/db.js';

let io;

// Store active connections for monitoring
const activeConnections = new Map();
const adminConnections = new Set();

/**
 * Initialize Socket.IO server
 * @param {Object} httpServer - HTTP server instance
 */
export const initializeSocketServer = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: process.env.CORS_ORIGIN || '*',
            methods: ['GET', 'POST'],
            credentials: true,
        },
        transports: ['websocket'], // Force WebSocket only (no polling)
        pingTimeout: 60000,
        pingInterval: 25000,
    });

    // Authentication middleware
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth.token;

            if (!token) {
                return next(new Error('Authentication token required'));
            }

            // Verify JWT token
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

            // JWT payload has 'id' and 'roleId', not 'userId' and 'role'
            socket.userId = decoded.id;
            socket.roleId = decoded.roleId;

            // Fetch user details to get role name
            const user = await prisma.user.findUnique({
                where: { id: decoded.id },
                include: { role: true },
            });

            if (!user) {
                return next(new Error('User not found'));
            }

            socket.userRole = user.role?.name?.toLowerCase() || 'unknown';
            socket.employeeId = user.employeeId;

            console.log(`✅ Socket authenticated: ${socket.userId} (${socket.userRole}) - Employee: ${socket.employeeId}`);
            next();
        } catch (error) {
            console.error('❌ Socket authentication failed:', error.message);
            next(new Error('Authentication failed'));
        }
    });

    // Connection handler
    io.on('connection', (socket) => {
        console.log(`🔌 Client connected: ${socket.id} (User: ${socket.userId})`);

        // Handle different user types
        if (socket.userRole === 'admin' || socket.userRole === 'manager') {
            handleAdminConnection(socket);
        } else if (socket.userRole === 'salesman') {
            handleSalesmanConnection(socket);
        }

        // Handle disconnection
        socket.on('disconnect', (reason) => {
            handleDisconnection(socket, reason);
        });

        // Handle errors
        socket.on('error', (error) => {
            console.error(`❌ Socket error for ${socket.id}:`, error);
        });
    });

    console.log('🚀 Socket.IO server initialized');
    return io;
};

/**
 * Handle admin/manager connections
 */
const handleAdminConnection = (socket) => {
    // Join admin room to receive all location updates
    socket.join('admin-room');
    adminConnections.add(socket.id);

    console.log(`👔 Admin joined: ${socket.userId} (Total admins: ${adminConnections.size})`);

    // Send current active employees
    socket.emit('active-employees', Array.from(activeConnections.keys()));

    // Handle request for specific employee's latest location
    socket.on('request-location', async (employeeId) => {
        try {
            const latest = await prisma.salesmanTrackingPoint.findFirst({
                where: { employeeId: employeeId.toString() },
                orderBy: { recordedAt: 'desc' },
            });

            if (latest) {
                socket.emit('location-update', {
                    employeeId: latest.employeeId,
                    latitude: latest.latitude,
                    longitude: latest.longitude,
                    speed: latest.speed,
                    accuracy: latest.accuracy,
                    recordedAt: latest.recordedAt,
                });
            }
        } catch (error) {
            console.error('Error fetching location:', error);
        }
    });
};

/**
 * Handle salesman connections
 */
const handleSalesmanConnection = (socket) => {
    const employeeId = socket.employeeId || socket.userId;

    // Store connection info
    activeConnections.set(employeeId, {
        socketId: socket.id,
        connectedAt: new Date(),
        lastUpdate: null,
    });

    // Join employee-specific room
    socket.join(`employee-${employeeId}`);

    console.log(`📱 Salesman connected: ${employeeId} (Total active: ${activeConnections.size})`);

    // Notify admins about new active employee
    io.to('admin-room').emit('employee-connected', {
        employeeId,
        connectedAt: new Date(),
    });

    // Handle location updates from mobile app
    socket.on('location-update', async (data) => {
        await handleLocationUpdate(socket, data);
    });

    // Handle attendance session start
    socket.on('session-start', (data) => {
        console.log(`🟢 Session started: ${employeeId}, Attendance: ${data.attendanceId}`);
        socket.attendanceId = data.attendanceId;
    });

    // Handle attendance session end
    socket.on('session-end', () => {
        console.log(`🔴 Session ended: ${employeeId}`);
        socket.attendanceId = null;
    });
};

/**
 * Handle location updates from mobile app
 */
const handleLocationUpdate = async (socket, data) => {
    const employeeId = socket.employeeId || socket.userId;
    const now = Date.now();

    console.log(`📥 Received location update from ${employeeId}:`, {
        latitude: data.latitude,
        longitude: data.longitude,
        attendanceId: data.attendanceId,
        speed: data.speed,
        accuracy: data.accuracy,
    });

    // Rate limiting: Max 1 update every 3 seconds
    const connectionInfo = activeConnections.get(employeeId);
    if (connectionInfo?.lastUpdate && (now - connectionInfo.lastUpdate) < 3000) {
        console.log(`⏭️ Skipping update for ${employeeId} - too frequent (${now - connectionInfo.lastUpdate}ms ago)`);
        return;
    }

    try {
        const {
            latitude,
            longitude,
            speed,
            accuracy,
            attendanceId,
            employeeName,
        } = data;

        // Validate required fields
        if (!latitude || !longitude || !attendanceId) {
            console.error(`❌ Missing required fields for ${employeeId}:`, { latitude, longitude, attendanceId });
            socket.emit('error', { message: 'Missing required fields' });
            return;
        }

        // Validate coordinates
        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            console.error(`❌ Invalid coordinates for ${employeeId}:`, { latitude, longitude });
            socket.emit('error', { message: 'Invalid coordinates' });
            return;
        }

        // Check if movement threshold is met (5 meters for smoother routes)
        const lastLocation = await getLastLocation(employeeId);
        if (lastLocation) {
            const distance = calculateDistance(
                lastLocation.latitude,
                lastLocation.longitude,
                latitude,
                longitude
            );

            if (distance < 0.005) { // 5 meters in kilometers
                console.log(`⏭️ Skipping update for ${employeeId} - movement too small (${(distance * 1000).toFixed(1)}m)`);
                return;
            }
        }

        console.log(`💾 Saving location point for ${employeeId} to database...`);

        // Save to PostgreSQL (permanent storage)
        const savedPoint = await prisma.salesmanTrackingPoint.create({
            data: {
                employeeId: employeeId.toString(),
                attendanceId: attendanceId.toString(),
                latitude: parseFloat(latitude),
                longitude: parseFloat(longitude),
                speed: speed ? parseFloat(speed) : null,
                accuracy: accuracy ? parseFloat(accuracy) : null,
                recordedAt: new Date(),
            },
        });

        console.log(`✅ Saved tracking point: ID=${savedPoint.id}, Employee=${employeeId}, Attendance=${attendanceId}`);

        // Update connection info
        connectionInfo.lastUpdate = now;
        activeConnections.set(employeeId, connectionInfo);

        // Prepare broadcast payload (compressed)
        const payload = {
            employeeId,
            employeeName: employeeName || employeeId,
            latitude: parseFloat(latitude),
            longitude: parseFloat(longitude),
            speed: speed ? parseFloat(speed) : 0,
            accuracy: accuracy ? parseFloat(accuracy) : 0,
            recordedAt: savedPoint.recordedAt.toISOString(),
            attendanceId,
        };

        // Broadcast to all admins in real-time
        const adminCount = io.sockets.adapter.rooms.get('admin-room')?.size || 0;
        console.log(`📡 Broadcasting location to ${adminCount} admin(s) in admin-room`);
        io.to('admin-room').emit('location-update', payload);

        // Send acknowledgment to mobile app
        socket.emit('location-ack', {
            success: true,
            timestamp: savedPoint.recordedAt,
        });

        console.log(`📍 Location updated: ${employeeId} (${latitude.toFixed(6)}, ${longitude.toFixed(6)})`);
    } catch (error) {
        console.error('❌ Error handling location update:', error);
        console.error('Error details:', error.message);
        console.error('Stack trace:', error.stack);
        socket.emit('error', { message: 'Failed to save location', error: error.message });
    }
};

/**
 * Handle disconnection
 */
const handleDisconnection = (socket, reason) => {
    const employeeId = socket.employeeId || socket.userId;

    console.log(`🔌 Client disconnected: ${socket.id} (${employeeId}) - Reason: ${reason}`);

    // Remove from active connections
    if (activeConnections.has(employeeId)) {
        activeConnections.delete(employeeId);

        // Notify admins
        io.to('admin-room').emit('employee-disconnected', {
            employeeId,
            disconnectedAt: new Date(),
        });
    }

    // Remove from admin connections
    if (adminConnections.has(socket.id)) {
        adminConnections.delete(socket.id);
        console.log(`👔 Admin left (Total admins: ${adminConnections.size})`);
    }
};

/**
 * Get last known location for employee
 */
const getLastLocation = async (employeeId) => {
    try {
        const latest = await prisma.salesmanTrackingPoint.findFirst({
            where: { employeeId: employeeId.toString() },
            orderBy: { recordedAt: 'desc' },
            select: { latitude: true, longitude: true },
        });
        return latest;
    } catch (error) {
        console.error('Error fetching last location:', error);
        return null;
    }
};

/**
 * Check if location has moved significantly (5 meters threshold for smoother routes)
 */
const hasMovedSignificantly = (lastLocation, newLocation) => {
    const distance = calculateDistance(
        lastLocation.latitude,
        lastLocation.longitude,
        newLocation.latitude,
        newLocation.longitude
    );
    return distance >= 0.005; // 5 meters in kilometers
};

/**
 * Calculate distance between two coordinates (Haversine formula)
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth's radius in km
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadians(lat1)) *
        Math.cos(toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

const toRadians = (degrees) => degrees * (Math.PI / 180);

/**
 * Get Socket.IO instance
 */
export const getIO = () => {
    if (!io) {
        throw new Error('Socket.IO not initialized');
    }
    return io;
};

/**
 * Get active connections count
 */
export const getActiveConnectionsCount = () => ({
    salesmen: activeConnections.size,
    admins: adminConnections.size,
    total: activeConnections.size + adminConnections.size,
});

export default { initializeSocketServer, getIO, getActiveConnectionsCount };
