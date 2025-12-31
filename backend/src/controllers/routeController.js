import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

/**
 * Calculate distance between two GPS points using Haversine formula
 * @param {number} lat1 - Latitude of first point
 * @param {number} lng1 - Longitude of first point
 * @param {number} lat2 - Latitude of second point
 * @param {number} lng2 - Longitude of second point
 * @returns {number} Distance in kilometers
 */
const calculateDistance = (lat1, lng1, lat2, lng2) => {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

/**
 * Calculate total distance for a route from GPS points
 * @param {Array} routePoints - Array of route points with latitude/longitude
 * @returns {number} Total distance in kilometers
 */
const calculateTotalRouteDistance = (routePoints) => {
    if (!routePoints || routePoints.length < 2) return 0;

    let totalDistance = 0;
    for (let i = 1; i < routePoints.length; i++) {
        const prev = routePoints[i - 1];
        const curr = routePoints[i];
        totalDistance += calculateDistance(
            prev.latitude, prev.longitude,
            curr.latitude, curr.longitude
        );
    }
    return totalDistance;
};

/**
 * Store GPS route point for active attendance session
 * Only accepts points when attendance status is 'active'
 * Lightweight endpoint optimized for frequent GPS updates
 * Automatically marks first point as home location
 * Calculates and stores cumulative distance traveled
 */
const storeRoutePoint = async (req, res) => {
    try {
        const { employeeId, attendanceId, latitude, longitude, speed, accuracy, isHomeLocation } = req.body;

        // Validate required fields
        if (!employeeId || !attendanceId || !latitude || !longitude) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: employeeId, attendanceId, latitude, longitude'
            });
        }

        // Validate coordinate ranges
        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            return res.status(400).json({
                success: false,
                message: 'Invalid GPS coordinates'
            });
        }

        // Check if attendance session exists and is active
        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId },
            select: { status: true, employeeId: true, punchInTime: true }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        // Verify attendance belongs to the employee
        if (attendance.employeeId !== employeeId) {
            return res.status(403).json({
                success: false,
                message: 'Attendance session does not belong to this employee'
            });
        }

        // Reject route points if attendance is completed
        if (attendance.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'Cannot store route points for completed attendance session'
            });
        }

        // Get existing route points to calculate distance and check for home location
        const existingPoints = await prisma.salesmanRouteLog.findMany({
            where: { attendanceId },
            orderBy: { recordedAt: 'asc' },
            select: { latitude: true, longitude: true }
        });

        const isFirstPoint = existingPoints.length === 0;
        const shouldMarkAsHome = isFirstPoint || isHomeLocation === true;

        // Calculate distance from last point (if exists)
        let distanceFromLast = 0;
        if (existingPoints.length > 0) {
            const lastPoint = existingPoints[existingPoints.length - 1];
            distanceFromLast = calculateDistance(
                lastPoint.latitude, lastPoint.longitude,
                parseFloat(latitude), parseFloat(longitude)
            );

            // Skip storing if movement is less than 5 meters (GPS noise filter)
            if (distanceFromLast < 0.005 && !shouldMarkAsHome) {
                return res.status(200).json({
                    success: true,
                    message: 'Point skipped - insufficient movement',
                    data: { skipped: true, distanceFromLast: distanceFromLast * 1000 }
                });
            }
        }

        // Store the GPS route point
        // Try with isHomeLocation first, fallback without it if column doesn't exist
        let routePoint;
        try {
            routePoint = await prisma.salesmanRouteLog.create({
                data: {
                    employeeId,
                    attendanceId,
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
                    speed: speed ? parseFloat(speed) : null,
                    accuracy: accuracy ? parseFloat(accuracy) : null,
                    recordedAt: new Date(),
                    isHomeLocation: shouldMarkAsHome
                }
            });
        } catch (columnError) {
            // Fallback: If isHomeLocation column doesn't exist, create without it
            if (columnError.code === 'P2022' || columnError.message?.includes('isHomeLocation')) {
                console.log('isHomeLocation column not found, storing route point without it');
                routePoint = await prisma.salesmanRouteLog.create({
                    data: {
                        employeeId,
                        attendanceId,
                        latitude: parseFloat(latitude),
                        longitude: parseFloat(longitude),
                        speed: speed ? parseFloat(speed) : null,
                        accuracy: accuracy ? parseFloat(accuracy) : null,
                        recordedAt: new Date()
                    }
                });
                routePoint.isHomeLocation = shouldMarkAsHome; // Add for response
            } else {
                throw columnError;
            }
        }

        // Calculate total distance traveled so far
        const allPoints = [...existingPoints, { latitude: parseFloat(latitude), longitude: parseFloat(longitude) }];
        const totalDistanceKm = calculateTotalRouteDistance(allPoints);

        res.status(201).json({
            success: true,
            message: shouldMarkAsHome ? 'Home location marked and route point stored' : 'Route point stored successfully',
            data: {
                id: routePoint.id,
                recordedAt: routePoint.recordedAt,
                isHomeLocation: shouldMarkAsHome,
                totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
                distanceFromLastKm: Math.round(distanceFromLast * 100) / 100,
                totalPoints: allPoints.length
            }
        });

    } catch (error) {
        console.error('Error storing route point:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while storing route point'
        });
    }
};

/**
 * Fetch all route points for a specific attendance session
 * Returns ordered GPS points with start/end locations for Admin map view
 * Optimized response for map rendering and route playback
 * Includes home location identification
 */
const getAttendanceRoute = async (req, res) => {
    try {
        const { attendanceId } = req.params;

        if (!attendanceId) {
            return res.status(400).json({
                success: false,
                message: 'Attendance ID is required'
            });
        }

        // Fetch attendance details with route points
        // Note: Using try-catch for backward compatibility if isHomeLocation column doesn't exist
        let attendance;
        try {
            attendance = await prisma.attendance.findUnique({
                where: { id: attendanceId },
                include: {
                    routeLogs: {
                        orderBy: { recordedAt: 'asc' }, // Chronological order for route playback
                        select: {
                            id: true,
                            latitude: true,
                            longitude: true,
                            speed: true,
                            accuracy: true,
                            recordedAt: true,
                            isHomeLocation: true
                        }
                    }
                }
            });
        } catch (columnError) {
            // Fallback: If isHomeLocation column doesn't exist, query without it
            if (columnError.code === 'P2022') {
                console.log('isHomeLocation column not found, using fallback query');
                attendance = await prisma.attendance.findUnique({
                    where: { id: attendanceId },
                    include: {
                        routeLogs: {
                            orderBy: { recordedAt: 'asc' },
                            select: {
                                id: true,
                                latitude: true,
                                longitude: true,
                                speed: true,
                                accuracy: true,
                                recordedAt: true
                            }
                        }
                    }
                });
                // Add isHomeLocation: false to all points, mark first as home
                if (attendance && attendance.routeLogs) {
                    attendance.routeLogs = attendance.routeLogs.map((point, index) => ({
                        ...point,
                        isHomeLocation: index === 0
                    }));
                }
            } else {
                throw columnError;
            }
        }

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        // Find home location (first point or explicitly marked)
        const homeLocation = attendance.routeLogs.find(point => point.isHomeLocation) ||
            (attendance.routeLogs.length > 0 ? attendance.routeLogs[0] : null);

        // Calculate total distance traveled
        const totalDistanceKm = calculateTotalRouteDistance(attendance.routeLogs);

        // Prepare response optimized for map rendering
        const response = {
            success: true,
            data: {
                attendanceId: attendance.id,
                employeeId: attendance.employeeId,
                employeeName: attendance.employeeName,
                date: attendance.date,
                status: attendance.status,

                // Home location (where salesman started working)
                homeLocation: homeLocation ? {
                    latitude: homeLocation.latitude,
                    longitude: homeLocation.longitude,
                    time: homeLocation.recordedAt,
                    isMarked: true
                } : null,

                // Start location (punch-in)
                startLocation: {
                    latitude: attendance.punchInLatitude,
                    longitude: attendance.punchInLongitude,
                    time: attendance.punchInTime,
                    address: attendance.punchInAddress
                },

                // End location (punch-out) - only if completed
                endLocation: attendance.punchOutTime ? {
                    latitude: attendance.punchOutLatitude,
                    longitude: attendance.punchOutLongitude,
                    time: attendance.punchOutTime,
                    address: attendance.punchOutAddress
                } : null,

                // Route points for polyline and animation
                routePoints: attendance.routeLogs.map(point => ({
                    id: point.id,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    speed: point.speed,
                    accuracy: point.accuracy,
                    timestamp: point.recordedAt,
                    isHomeLocation: point.isHomeLocation || false
                })),

                // Summary statistics with distance
                summary: {
                    totalPoints: attendance.routeLogs.length,
                    totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
                    duration: attendance.punchOutTime ?
                        Math.round((new Date(attendance.punchOutTime) - new Date(attendance.punchInTime)) / (1000 * 60)) : // minutes
                        null,
                    totalWorkHours: attendance.totalWorkHours,
                    hasHomeLocation: homeLocation !== null
                }
            }
        };

        res.status(200).json(response);

    } catch (error) {
        console.error('Error fetching attendance route:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching route data'
        });
    }
};

/**
 * Get route summary for multiple attendance sessions
 * Used for Admin dashboard route overview
 */
const getRouteSummary = async (req, res) => {
    try {
        const { employeeId, startDate, endDate, limit = 50 } = req.query;

        const whereClause = {};

        if (employeeId) {
            whereClause.employeeId = employeeId;
        }

        if (startDate || endDate) {
            whereClause.date = {};
            if (startDate) whereClause.date.gte = new Date(startDate);
            if (endDate) whereClause.date.lte = new Date(endDate);
        }

        const attendanceSessions = await prisma.attendance.findMany({
            where: whereClause,
            include: {
                _count: {
                    select: { routeLogs: true }
                }
            },
            orderBy: { date: 'desc' },
            take: parseInt(limit)
        });

        const summary = attendanceSessions.map(session => ({
            attendanceId: session.id,
            employeeId: session.employeeId,
            employeeName: session.employeeName,
            date: session.date,
            status: session.status,
            routePointsCount: session._count.routeLogs,
            totalWorkHours: session.totalWorkHours,
            hasRoute: session._count.routeLogs > 0
        }));

        res.status(200).json({
            success: true,
            data: summary
        });

    } catch (error) {
        console.error('Error fetching route summary:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching route summary'
        });
    }
};

/**
 * Get historical routes for date-wise tracking
 * Returns routes grouped by date with home locations marked
 */
const getHistoricalRoutes = async (req, res) => {
    try {
        const { employeeId, date, startDate, endDate } = req.query;

        const whereClause = {};

        // Handle single date or date range
        if (date) {
            const targetDate = new Date(date);
            const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
            const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));
            whereClause.date = {
                gte: startOfDay,
                lte: endOfDay
            };
        } else if (startDate || endDate) {
            whereClause.date = {};
            if (startDate) whereClause.date.gte = new Date(startDate);
            if (endDate) whereClause.date.lte = new Date(endDate);
        }

        // Add employeeId filter only if provided
        if (employeeId) {
            whereClause.employeeId = employeeId;
        }

        // Fetch attendance sessions with route data
        // Try with isHomeLocation first, fallback without it
        let attendanceSessions;
        try {
            attendanceSessions = await prisma.attendance.findMany({
                where: whereClause,
                include: {
                    routeLogs: {
                        orderBy: { recordedAt: 'asc' },
                        select: {
                            id: true,
                            latitude: true,
                            longitude: true,
                            speed: true,
                            accuracy: true,
                            recordedAt: true,
                            isHomeLocation: true
                        }
                    }
                },
                orderBy: { date: 'desc' }
            });
        } catch (columnError) {
            if (columnError.code === 'P2022') {
                console.log('isHomeLocation column not found in getHistoricalRoutes, using fallback');
                attendanceSessions = await prisma.attendance.findMany({
                    where: whereClause,
                    include: {
                        routeLogs: {
                            orderBy: { recordedAt: 'asc' },
                            select: {
                                id: true,
                                latitude: true,
                                longitude: true,
                                speed: true,
                                accuracy: true,
                                recordedAt: true
                            }
                        }
                    },
                    orderBy: { date: 'desc' }
                });
                // Add isHomeLocation to first point of each session
                attendanceSessions = attendanceSessions.map(session => ({
                    ...session,
                    routeLogs: session.routeLogs.map((point, index) => ({
                        ...point,
                        isHomeLocation: index === 0
                    }))
                }));
            } else {
                throw columnError;
            }
        }

        // Group and format the data with distance calculation
        const historicalRoutes = attendanceSessions.map(session => {
            const homeLocation = session.routeLogs.find(point => point.isHomeLocation) ||
                (session.routeLogs.length > 0 ? session.routeLogs[0] : null);

            // Calculate total distance for this route
            const totalDistanceKm = calculateTotalRouteDistance(session.routeLogs);

            return {
                attendanceId: session.id,
                employeeId: session.employeeId,
                employeeName: session.employeeName,
                date: session.date,
                status: session.status,

                // Home location where salesman started
                homeLocation: homeLocation ? {
                    latitude: homeLocation.latitude,
                    longitude: homeLocation.longitude,
                    time: homeLocation.recordedAt,
                    isMarked: true
                } : null,

                // Punch locations
                startLocation: {
                    latitude: session.punchInLatitude,
                    longitude: session.punchInLongitude,
                    time: session.punchInTime,
                    address: session.punchInAddress
                },

                endLocation: session.punchOutTime ? {
                    latitude: session.punchOutLatitude,
                    longitude: session.punchOutLongitude,
                    time: session.punchOutTime,
                    address: session.punchOutAddress
                } : null,

                // Route summary with distance
                routeSummary: {
                    totalPoints: session.routeLogs.length,
                    totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
                    hasRoute: session.routeLogs.length > 0,
                    hasHomeLocation: homeLocation !== null,
                    duration: session.punchOutTime ?
                        Math.round((new Date(session.punchOutTime) - new Date(session.punchInTime)) / (1000 * 60)) :
                        null,
                    totalWorkHours: session.totalWorkHours
                },

                // All route points for full visualization
                routePoints: session.routeLogs.map(point => ({
                    latitude: point.latitude,
                    longitude: point.longitude,
                    timestamp: point.recordedAt,
                    speed: point.speed,
                    isHomeLocation: point.isHomeLocation || false
                }))
            };
        });

        res.status(200).json({
            success: true,
            data: {
                routes: historicalRoutes,
                totalSessions: historicalRoutes.length,
                dateRange: {
                    from: startDate || date,
                    to: endDate || date
                }
            }
        });

    } catch (error) {
        console.error('Error fetching historical routes:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching historical routes'
        });
    }
};

/**
 * Get real-time distance for a salesman's current active session
 * Returns total distance traveled in the current attendance session
 */
const getCurrentDistance = async (req, res) => {
    try {
        const { employeeId } = req.params;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Find active attendance session
        const activeAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                status: 'active'
            },
            orderBy: {
                punchInTime: 'desc'
            }
        });

        if (!activeAttendance) {
            return res.status(404).json({
                success: false,
                message: 'No active attendance session found'
            });
        }

        // Get all route points for this session
        // Try with isHomeLocation first, fallback without it
        let routePoints;
        try {
            routePoints = await prisma.salesmanRouteLog.findMany({
                where: { attendanceId: activeAttendance.id },
                orderBy: { recordedAt: 'asc' },
                select: {
                    latitude: true,
                    longitude: true,
                    recordedAt: true,
                    isHomeLocation: true
                }
            });
        } catch (columnError) {
            if (columnError.code === 'P2022') {
                console.log('isHomeLocation column not found in getCurrentDistance, using fallback');
                routePoints = await prisma.salesmanRouteLog.findMany({
                    where: { attendanceId: activeAttendance.id },
                    orderBy: { recordedAt: 'asc' },
                    select: {
                        latitude: true,
                        longitude: true,
                        recordedAt: true
                    }
                });
                // Mark first point as home
                routePoints = routePoints.map((point, index) => ({
                    ...point,
                    isHomeLocation: index === 0
                }));
            } else {
                throw columnError;
            }
        }

        // Calculate total distance
        const totalDistanceKm = calculateTotalRouteDistance(routePoints);

        // Find home location
        const homeLocation = routePoints.find(p => p.isHomeLocation) || routePoints[0];

        // Get last location
        const lastLocation = routePoints.length > 0 ? routePoints[routePoints.length - 1] : null;

        res.status(200).json({
            success: true,
            data: {
                employeeId,
                attendanceId: activeAttendance.id,
                totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
                totalPoints: routePoints.length,
                homeLocation: homeLocation ? {
                    latitude: homeLocation.latitude,
                    longitude: homeLocation.longitude,
                    time: homeLocation.recordedAt
                } : null,
                lastLocation: lastLocation ? {
                    latitude: lastLocation.latitude,
                    longitude: lastLocation.longitude,
                    time: lastLocation.recordedAt
                } : null,
                punchInTime: activeAttendance.punchInTime,
                workingDurationMinutes: Math.round(
                    (new Date() - new Date(activeAttendance.punchInTime)) / (1000 * 60)
                )
            }
        });

    } catch (error) {
        console.error('Error fetching current distance:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching current distance'
        });
    }
};

/**
 * Get detailed route analytics for playback and graphs
 * Includes idle time detection, distance vs time data, movement timeline
 */
const getRouteAnalytics = async (req, res) => {
    try {
        const { attendanceId } = req.params;

        if (!attendanceId) {
            return res.status(400).json({
                success: false,
                message: 'Attendance ID is required'
            });
        }

        // Fetch attendance with route points
        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId },
            include: {
                routeLogs: {
                    orderBy: { recordedAt: 'asc' }
                }
            }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        const routePoints = attendance.routeLogs;

        if (routePoints.length === 0) {
            return res.status(200).json({
                success: true,
                data: {
                    attendanceId,
                    hasData: false,
                    message: 'No route data available'
                }
            });
        }

        // Calculate analytics
        const IDLE_DISTANCE_THRESHOLD = 0.05; // 50 meters in km
        const IDLE_TIME_THRESHOLD = 5 * 60 * 1000; // 5 minutes in ms

        let totalIdleTimeMs = 0;
        let idlePeriods = [];
        let distanceVsTime = [];
        let movementTimeline = [];
        let cumulativeDistance = 0;

        const startTime = new Date(routePoints[0].recordedAt).getTime();

        // First point
        distanceVsTime.push({
            timestamp: routePoints[0].recordedAt,
            timeElapsedMinutes: 0,
            distanceKm: 0,
            latitude: routePoints[0].latitude,
            longitude: routePoints[0].longitude
        });

        movementTimeline.push({
            type: 'start',
            timestamp: routePoints[0].recordedAt,
            latitude: routePoints[0].latitude,
            longitude: routePoints[0].longitude,
            description: 'Route started'
        });

        let currentIdleStart = null;
        let currentIdleLocation = null;

        for (let i = 1; i < routePoints.length; i++) {
            const prev = routePoints[i - 1];
            const curr = routePoints[i];

            const distance = calculateDistance(
                prev.latitude, prev.longitude,
                curr.latitude, curr.longitude
            );

            const timeDiff = new Date(curr.recordedAt).getTime() - new Date(prev.recordedAt).getTime();
            cumulativeDistance += distance;

            const timeElapsedMinutes = (new Date(curr.recordedAt).getTime() - startTime) / (1000 * 60);

            // Distance vs time data point
            distanceVsTime.push({
                timestamp: curr.recordedAt,
                timeElapsedMinutes: Math.round(timeElapsedMinutes * 100) / 100,
                distanceKm: Math.round(cumulativeDistance * 100) / 100,
                latitude: curr.latitude,
                longitude: curr.longitude,
                speed: curr.speed
            });

            // Idle detection
            if (distance < IDLE_DISTANCE_THRESHOLD && timeDiff >= IDLE_TIME_THRESHOLD) {
                if (!currentIdleStart) {
                    currentIdleStart = prev.recordedAt;
                    currentIdleLocation = { latitude: prev.latitude, longitude: prev.longitude };
                }
                totalIdleTimeMs += timeDiff;
            } else if (currentIdleStart) {
                // End of idle period
                idlePeriods.push({
                    startTime: currentIdleStart,
                    endTime: prev.recordedAt,
                    durationMinutes: Math.round((new Date(prev.recordedAt).getTime() - new Date(currentIdleStart).getTime()) / (1000 * 60)),
                    latitude: currentIdleLocation.latitude,
                    longitude: currentIdleLocation.longitude
                });

                movementTimeline.push({
                    type: 'idle',
                    timestamp: currentIdleStart,
                    endTimestamp: prev.recordedAt,
                    latitude: currentIdleLocation.latitude,
                    longitude: currentIdleLocation.longitude,
                    description: `Idle for ${Math.round((new Date(prev.recordedAt).getTime() - new Date(currentIdleStart).getTime()) / (1000 * 60))} minutes`
                });

                currentIdleStart = null;
                currentIdleLocation = null;
            }

            // Add movement events for significant movements
            if (distance > 0.5) { // More than 500m movement
                movementTimeline.push({
                    type: 'movement',
                    timestamp: curr.recordedAt,
                    latitude: curr.latitude,
                    longitude: curr.longitude,
                    distanceKm: Math.round(distance * 100) / 100,
                    description: `Moved ${Math.round(distance * 1000)}m`
                });
            }
        }

        // Close any remaining idle period
        if (currentIdleStart) {
            const lastPoint = routePoints[routePoints.length - 1];
            idlePeriods.push({
                startTime: currentIdleStart,
                endTime: lastPoint.recordedAt,
                durationMinutes: Math.round((new Date(lastPoint.recordedAt).getTime() - new Date(currentIdleStart).getTime()) / (1000 * 60)),
                latitude: currentIdleLocation.latitude,
                longitude: currentIdleLocation.longitude
            });
        }

        // Add end point to timeline
        const lastPoint = routePoints[routePoints.length - 1];
        movementTimeline.push({
            type: 'end',
            timestamp: lastPoint.recordedAt,
            latitude: lastPoint.latitude,
            longitude: lastPoint.longitude,
            description: 'Route ended'
        });

        // Calculate total duration
        const totalDurationMs = new Date(lastPoint.recordedAt).getTime() - startTime;
        const totalDurationMinutes = Math.round(totalDurationMs / (1000 * 60));
        const activeTimeMinutes = totalDurationMinutes - Math.round(totalIdleTimeMs / (1000 * 60));

        // Prepare playback points (simplified for animation)
        const playbackPoints = routePoints.map((point, index) => ({
            index,
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.recordedAt,
            speed: point.speed,
            cumulativeDistanceKm: distanceVsTime[index]?.distanceKm || 0
        }));

        res.status(200).json({
            success: true,
            data: {
                attendanceId,
                employeeId: attendance.employeeId,
                employeeName: attendance.employeeName,
                date: attendance.date,
                hasData: true,

                // Summary stats
                summary: {
                    totalDistanceKm: Math.round(cumulativeDistance * 100) / 100,
                    totalDurationMinutes,
                    activeTimeMinutes,
                    idleTimeMinutes: Math.round(totalIdleTimeMs / (1000 * 60)),
                    totalPoints: routePoints.length,
                    averageSpeedKmh: totalDurationMinutes > 0
                        ? Math.round((cumulativeDistance / (totalDurationMinutes / 60)) * 100) / 100
                        : 0,
                    idlePeriodsCount: idlePeriods.length
                },

                // For graphs
                distanceVsTime,

                // Idle analysis
                idlePeriods,

                // Timeline events
                movementTimeline,

                // For playback animation
                playbackPoints,

                // Start and end info
                startLocation: {
                    latitude: routePoints[0].latitude,
                    longitude: routePoints[0].longitude,
                    timestamp: routePoints[0].recordedAt
                },
                endLocation: {
                    latitude: lastPoint.latitude,
                    longitude: lastPoint.longitude,
                    timestamp: lastPoint.recordedAt
                }
            }
        });

    } catch (error) {
        console.error('Error fetching route analytics:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching route analytics'
        });
    }
};

/**
 * Get route completion summary for punch-out
 * Provides final stats when salesman completes their day
 */
const getRouteCompletionSummary = async (req, res) => {
    try {
        const { attendanceId } = req.params;

        if (!attendanceId) {
            return res.status(400).json({
                success: false,
                message: 'Attendance ID is required'
            });
        }

        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId },
            include: {
                routeLogs: {
                    orderBy: { recordedAt: 'asc' }
                }
            }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        const routePoints = attendance.routeLogs;
        const totalDistanceKm = calculateTotalRouteDistance(routePoints);

        // Calculate idle time
        let totalIdleTimeMs = 0;
        const IDLE_DISTANCE_THRESHOLD = 0.05;
        const IDLE_TIME_THRESHOLD = 5 * 60 * 1000;

        for (let i = 1; i < routePoints.length; i++) {
            const prev = routePoints[i - 1];
            const curr = routePoints[i];
            const distance = calculateDistance(
                prev.latitude, prev.longitude,
                curr.latitude, curr.longitude
            );
            const timeDiff = new Date(curr.recordedAt).getTime() - new Date(prev.recordedAt).getTime();

            if (distance < IDLE_DISTANCE_THRESHOLD && timeDiff >= IDLE_TIME_THRESHOLD) {
                totalIdleTimeMs += timeDiff;
            }
        }

        // Find unique locations (clusters within 100m)
        const uniqueLocations = [];
        const CLUSTER_THRESHOLD = 0.1; // 100m

        for (const point of routePoints) {
            const isNearExisting = uniqueLocations.some(loc =>
                calculateDistance(loc.latitude, loc.longitude, point.latitude, point.longitude) < CLUSTER_THRESHOLD
            );
            if (!isNearExisting) {
                uniqueLocations.push({
                    latitude: point.latitude,
                    longitude: point.longitude,
                    timestamp: point.recordedAt
                });
            }
        }

        // Calculate duration
        const startTime = attendance.punchInTime;
        const endTime = attendance.punchOutTime || new Date();
        const totalDurationMinutes = Math.round((new Date(endTime).getTime() - new Date(startTime).getTime()) / (1000 * 60));

        // Route preview (simplified path for quick display)
        const routePreview = routePoints.length > 20
            ? routePoints.filter((_, i) => i % Math.ceil(routePoints.length / 20) === 0)
            : routePoints;

        res.status(200).json({
            success: true,
            data: {
                attendanceId,
                employeeId: attendance.employeeId,
                employeeName: attendance.employeeName,
                date: attendance.date,
                status: attendance.status,

                // Summary
                totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
                totalDurationMinutes,
                idleTimeMinutes: Math.round(totalIdleTimeMs / (1000 * 60)),
                activeTimeMinutes: totalDurationMinutes - Math.round(totalIdleTimeMs / (1000 * 60)),
                uniqueLocationsCount: uniqueLocations.length,
                totalRoutePoints: routePoints.length,

                // Locations
                startLocation: {
                    latitude: attendance.punchInLatitude,
                    longitude: attendance.punchInLongitude,
                    address: attendance.punchInAddress,
                    time: attendance.punchInTime
                },
                endLocation: attendance.punchOutTime ? {
                    latitude: attendance.punchOutLatitude,
                    longitude: attendance.punchOutLongitude,
                    address: attendance.punchOutAddress,
                    time: attendance.punchOutTime
                } : null,

                // Unique locations visited
                uniqueLocations: uniqueLocations.slice(0, 10), // Limit to 10 for summary

                // Route preview for quick map display
                routePreview: routePreview.map(p => ({
                    latitude: p.latitude,
                    longitude: p.longitude
                }))
            }
        });

    } catch (error) {
        console.error('Error fetching route completion summary:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error while fetching route completion summary'
        });
    }
};

export {
    storeRoutePoint,
    getAttendanceRoute,
    getRouteSummary,
    getHistoricalRoutes,
    getCurrentDistance,
    getRouteAnalytics,
    getRouteCompletionSummary
};