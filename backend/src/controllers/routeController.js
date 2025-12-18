import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

/**
 * Store GPS route point for active attendance session
 * Only accepts points when attendance status is 'active'
 * Lightweight endpoint optimized for frequent GPS updates
 */
const storeRoutePoint = async (req, res) => {
    try {
        const { employeeId, attendanceId, latitude, longitude, speed, accuracy } = req.body;

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
            select: { status: true, employeeId: true }
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

        // Store the GPS route point
        const routePoint = await prisma.salesmanRouteLog.create({
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

        res.status(201).json({
            success: true,
            message: 'Route point stored successfully',
            data: {
                id: routePoint.id,
                recordedAt: routePoint.recordedAt
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
        const attendance = await prisma.attendance.findUnique({
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
                        recordedAt: true
                    }
                }
            }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        // Prepare response optimized for map rendering
        const response = {
            success: true,
            data: {
                attendanceId: attendance.id,
                employeeId: attendance.employeeId,
                employeeName: attendance.employeeName,
                date: attendance.date,
                status: attendance.status,

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
                    timestamp: point.recordedAt
                })),

                // Summary statistics
                summary: {
                    totalPoints: attendance.routeLogs.length,
                    duration: attendance.punchOutTime ?
                        Math.round((new Date(attendance.punchOutTime) - new Date(attendance.punchInTime)) / (1000 * 60)) : // minutes
                        null,
                    totalWorkHours: attendance.totalWorkHours
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

export {
    storeRoutePoint,
    getAttendanceRoute,
    getRouteSummary
};