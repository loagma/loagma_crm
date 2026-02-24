import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import prisma from '../config/db.js';
import { ensureRedisConnection, getRedisClient, isRedisEnabled } from '../config/redis.js';

let io;

// Store active connections for monitoring
const activeConnections = new Map();
const adminConnections = new Set();
const activeSessions = new Map();
const sessionMetrics = new Map();
const runtimeStats = {
    pointsReceived: 0,
    pointsAccepted: 0,
    pointsDuplicate: 0,
    pointsRejected: 0,
    pointsPersistFailed: 0,
    lastAcceptedAt: null,
};

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
        socket.attendanceId = data.attendanceId?.toString() || null;
        const attendanceId = data.attendanceId?.toString() || null;
        activeSessions.set(employeeId.toString(), attendanceId);
        if (attendanceId) {
            sessionMetrics.set(_sessionKey(employeeId, attendanceId), {
                totalDistanceKm: 0,
                pointCount: 0,
                startedAt: new Date(),
                lastSeenAt: new Date(),
            });
        }
        io.to('admin-room').emit('employee-session-started', {
            employeeId: employeeId.toString(),
            employeeName: data.employeeName || employeeId.toString(),
            attendanceId,
            startedAt: data.startedAt || new Date().toISOString(),
        });
    });

    // Handle attendance session end
    socket.on('session-end', (data = {}) => {
        console.log(`🔴 Session ended: ${employeeId}`);
        const endedAttendanceId = (data.attendanceId || socket.attendanceId)?.toString() || null;
        socket.attendanceId = null;
        activeSessions.delete(employeeId.toString());
        if (endedAttendanceId) {
            sessionMetrics.delete(_sessionKey(employeeId, endedAttendanceId));
        }
        io.to('admin-room').emit('employee-session-ended', {
            employeeId: employeeId.toString(),
            attendanceId: endedAttendanceId,
            endedAt: data.endedAt || new Date().toISOString(),
        });
    });
};

/**
 * Handle location updates from mobile app
 */
const handleLocationUpdate = async (socket, data) => {
    const employeeId = socket.employeeId || socket.userId;
    const now = Date.now();
    runtimeStats.pointsReceived += 1;

    if (!data || typeof data !== 'object') {
        runtimeStats.pointsRejected += 1;
        socket.emit('error', { message: 'Invalid location payload' });
        return;
    }

    console.log(`📥 Received location update from ${employeeId}:`, {
        latitude: data.latitude,
        longitude: data.longitude,
        attendanceId: data.attendanceId,
        speed: data.speed,
        accuracy: data.accuracy,
    });

    // Lightweight anti-spam rate limiting: do not drop valid 5s cadence.
    const connectionInfo = activeConnections.get(employeeId) || {
        socketId: socket.id,
        connectedAt: new Date(),
        lastUpdate: null,
    };
    if (connectionInfo?.lastUpdate && (now - connectionInfo.lastUpdate) < 700) {
        console.log(`⏭️ Skipping update for ${employeeId} - too frequent (${now - connectionInfo.lastUpdate}ms ago)`);
        runtimeStats.pointsRejected += 1;
        return;
    }

    try {
        const {
            latitude,
            longitude,
            speed,
            accuracy,
            attendanceId: rawAttendanceId,
            employeeName,
            clientPointId,
            recordedAt,
        } = data;

        const latitudeValue = Number(latitude);
        const longitudeValue = Number(longitude);
        const speedValue = speed === null || speed === undefined ? null : Number(speed);
        const accuracyValue = accuracy === null || accuracy === undefined ? null : Number(accuracy);
        const recordedAtValue = recordedAt ? new Date(recordedAt) : null;
        const persistedAt =
            recordedAtValue && !Number.isNaN(recordedAtValue.getTime())
                ? recordedAtValue
                : new Date();
        const attendanceId = (rawAttendanceId || socket.attendanceId || activeSessions.get(employeeId.toString()))?.toString();

        // Validate required fields
        if (!Number.isFinite(latitudeValue) || !Number.isFinite(longitudeValue) || !attendanceId) {
            console.error(`❌ Missing required fields for ${employeeId}:`, {
                latitude,
                longitude,
                attendanceId,
            });
            runtimeStats.pointsRejected += 1;
            socket.emit('error', { message: 'Missing required fields' });
            return;
        }

        // Validate coordinates
        if (latitudeValue < -90 || latitudeValue > 90 || longitudeValue < -180 || longitudeValue > 180) {
            console.error(`❌ Invalid coordinates for ${employeeId}:`, { latitude: latitudeValue, longitude: longitudeValue });
            runtimeStats.pointsRejected += 1;
            socket.emit('error', { message: 'Invalid coordinates' });
            return;
        }

        // Calculate segment distance for metrics, but do not drop stationary points.
        let lastSegmentKm = 0;
        const lastLocation = await getLastLocation(employeeId, attendanceId);
        if (lastLocation) {
            const distance = calculateDistance(
                lastLocation.latitude,
                lastLocation.longitude,
                latitudeValue,
                longitudeValue
            );
            lastSegmentKm = distance;
        }

        console.log(`💾 Saving location point for ${employeeId} to database...`);
        const persistStartedAt = Date.now();

        // Save to PostgreSQL (permanent storage)
        let savedPoint;
        let wasDuplicate = false;
        try {
            savedPoint = await prisma.salesmanTrackingPoint.create({
                data: {
                    clientPointId: clientPointId ? clientPointId.toString() : null,
                    employeeId: employeeId.toString(),
                    attendanceId: attendanceId.toString(),
                    latitude: latitudeValue,
                    longitude: longitudeValue,
                    speed: Number.isFinite(speedValue) ? speedValue : null,
                    accuracy: Number.isFinite(accuracyValue) ? accuracyValue : null,
                    recordedAt: persistedAt,
                },
            });
        } catch (createError) {
            if (createError?.code === 'P2002' && clientPointId) {
                wasDuplicate = true;
                savedPoint = await prisma.salesmanTrackingPoint.findFirst({
                    where: { clientPointId: clientPointId.toString() },
                });
                runtimeStats.pointsDuplicate += 1;
            } else {
                runtimeStats.pointsPersistFailed += 1;
                throw createError;
            }
        }

        console.log(`✅ Saved tracking point: ID=${savedPoint.id}, Employee=${employeeId}, Attendance=${attendanceId}`);

        // Update connection info
        connectionInfo.lastUpdate = now;
        activeConnections.set(employeeId, connectionInfo);
        const sessionKey = _sessionKey(employeeId, attendanceId);
        const metric = sessionMetrics.get(sessionKey) || {
            totalDistanceKm: 0,
            pointCount: 0,
            startedAt: savedPoint.recordedAt,
            lastSeenAt: savedPoint.recordedAt,
        };

        if (!wasDuplicate) {
            metric.pointCount += 1;
            metric.totalDistanceKm += lastSegmentKm;
            runtimeStats.pointsAccepted += 1;
            runtimeStats.lastAcceptedAt = savedPoint.recordedAt.toISOString();
        }
        metric.lastSeenAt = savedPoint.recordedAt;
        sessionMetrics.set(sessionKey, metric);

        // Prepare broadcast payload (compressed)
        const payload = {
            employeeId,
            employeeName: employeeName || employeeId,
            latitude: latitudeValue,
            longitude: longitudeValue,
            speed: Number.isFinite(speedValue) ? speedValue : 0,
            accuracy: Number.isFinite(accuracyValue) ? accuracyValue : 0,
            recordedAt: savedPoint.recordedAt.toISOString(),
            attendanceId,
            clientPointId: clientPointId ? clientPointId.toString() : null,
            totalDistanceKm: Number(metric.totalDistanceKm.toFixed(3)),
            lastSegmentMeters: Number((lastSegmentKm * 1000).toFixed(1)),
            lastSeenAt: savedPoint.recordedAt.toISOString(),
            status: _deriveFreshnessStatus(savedPoint.recordedAt),
        };

        // Best-effort Redis latest snapshot for fast live reads.
        await persistLatestToRedis(payload);

        // Broadcast to all admins in real-time
        const adminCount = io.sockets.adapter.rooms.get('admin-room')?.size || 0;
        console.log(`📡 Broadcasting location to ${adminCount} admin(s) in admin-room`);
        io.to('admin-room').emit('location-update', payload);

        // Send acknowledgment to mobile app
        socket.emit('location-ack', {
            accepted: true,
            clientPointId: clientPointId ? clientPointId.toString() : null,
            serverPointId: savedPoint.id,
            recordedAt: savedPoint.recordedAt.toISOString(),
        });

        const persistMs = Date.now() - persistStartedAt;
        console.log(
            JSON.stringify({
                event: 'tracking_point_ingested',
                employeeId: employeeId.toString(),
                attendanceId: attendanceId.toString(),
                clientPointId: clientPointId ? clientPointId.toString() : null,
                accepted: true,
                duplicate: wasDuplicate,
                persistMs,
                recordedAt: savedPoint.recordedAt.toISOString(),
            })
        );
    } catch (error) {
        console.error('❌ Error handling location update:', error);
        console.error('Error details:', error.message);
        console.error('Stack trace:', error.stack);
        runtimeStats.pointsPersistFailed += 1;
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
        activeSessions.delete(employeeId.toString());

        // Notify admins
        io.to('admin-room').emit('employee-disconnected', {
            employeeId,
            disconnectedAt: new Date(),
            status: 'OFFLINE',
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
const getLastLocation = async (employeeId, attendanceId) => {
    try {
        const latest = await prisma.salesmanTrackingPoint.findFirst({
            where: {
                employeeId: employeeId.toString(),
                ...(attendanceId ? { attendanceId: attendanceId.toString() } : {}),
            },
            orderBy: { recordedAt: 'desc' },
            select: { latitude: true, longitude: true },
        });
        return latest;
    } catch (error) {
        console.error('Error fetching last location:', error);
        return null;
    }
};

const _sessionKey = (employeeId, attendanceId) =>
    `${employeeId.toString()}::${attendanceId.toString()}`;

const _deriveFreshnessStatus = (lastSeenAt) => {
    const ageMs = Date.now() - new Date(lastSeenAt).getTime();
    if (ageMs <= 20 * 1000) return 'LIVE';
    if (ageMs <= 120 * 1000) return 'DEGRADED';
    return 'OFFLINE';
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

export const getTrackingRuntimeStats = () => ({
    ...runtimeStats,
    redisEnabled: isRedisEnabled(),
    activeSessions: activeSessions.size,
});

const persistLatestToRedis = async (payload) => {
    if (!isRedisEnabled()) return;
    const ready = await ensureRedisConnection();
    if (!ready) return;
    const redis = getRedisClient();
    if (!redis) return;
    const key = `tracking:latest:${payload.employeeId}`;
    await redis.set(key, JSON.stringify(payload), 'EX', 60 * 60 * 12);
};

export default {
    initializeSocketServer,
    getIO,
    getActiveConnectionsCount,
    getTrackingRuntimeStats,
};
