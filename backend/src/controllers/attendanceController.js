import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper function to calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of Earth in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in kilometers
}

// Helper function to calculate work hours
function calculateWorkHours(punchInTime, punchOutTime) {
    const diff = new Date(punchOutTime) - new Date(punchInTime);
    return diff / (1000 * 60 * 60); // Convert milliseconds to hours
}

// Punch In
export const punchIn = async (req, res) => {
    try {
        const {
            employeeId,
            employeeName,
            punchInLatitude,
            punchInLongitude,
            punchInPhoto,
            punchInAddress,
            bikeKmStart
        } = req.body;

        // Validation
        if (!employeeId || !employeeName || !punchInLatitude || !punchInLongitude) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields'
            });
        }

        // Check if already punched in today
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const existingAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                punchInTime: {
                    gte: today,
                    lt: tomorrow
                }
            }
        });

        if (existingAttendance) {
            return res.status(400).json({
                success: false,
                message: 'Already punched in today',
                data: existingAttendance
            });
        }

        // Create attendance record
        const attendance = await prisma.attendance.create({
            data: {
                employeeId,
                employeeName,
                punchInTime: new Date(),
                punchInLatitude: parseFloat(punchInLatitude),
                punchInLongitude: parseFloat(punchInLongitude),
                punchInPhoto,
                punchInAddress,
                bikeKmStart,
                status: 'active'
            }
        });

        res.status(201).json({
            success: true,
            message: 'Punched in successfully',
            data: attendance
        });
    } catch (error) {
        console.error('Punch in error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to punch in',
            error: error.message
        });
    }
};

// Punch Out
export const punchOut = async (req, res) => {
    try {
        const {
            attendanceId,
            punchOutLatitude,
            punchOutLongitude,
            punchOutPhoto,
            punchOutAddress,
            bikeKmEnd
        } = req.body;

        // Validation
        if (!attendanceId || !punchOutLatitude || !punchOutLongitude) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields'
            });
        }

        // Get existing attendance record
        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance record not found'
            });
        }

        if (attendance.status === 'completed') {
            return res.status(400).json({
                success: false,
                message: 'Already punched out'
            });
        }

        // Calculate distance and work hours
        const distance = calculateDistance(
            attendance.punchInLatitude,
            attendance.punchInLongitude,
            parseFloat(punchOutLatitude),
            parseFloat(punchOutLongitude)
        );

        const punchOutTime = new Date();
        const workHours = calculateWorkHours(attendance.punchInTime, punchOutTime);

        // Update attendance record
        const updatedAttendance = await prisma.attendance.update({
            where: { id: attendanceId },
            data: {
                punchOutTime,
                punchOutLatitude: parseFloat(punchOutLatitude),
                punchOutLongitude: parseFloat(punchOutLongitude),
                punchOutPhoto,
                punchOutAddress,
                bikeKmEnd,
                totalDistanceKm: distance,
                totalWorkHours: workHours,
                status: 'completed'
            }
        });

        res.status(200).json({
            success: true,
            message: 'Punched out successfully',
            data: updatedAttendance
        });
    } catch (error) {
        console.error('Punch out error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to punch out',
            error: error.message
        });
    }
};

// Get Today's Attendance
export const getTodayAttendance = async (req, res) => {
    try {
        const { employeeId } = req.params;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const attendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                punchInTime: {
                    gte: today,
                    lt: tomorrow
                }
            },
            orderBy: {
                punchInTime: 'desc'
            }
        });

        res.status(200).json({
            success: true,
            data: attendance
        });
    } catch (error) {
        console.error('Get today attendance error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch attendance',
            error: error.message
        });
    }
};

// Get Attendance History
export const getAttendanceHistory = async (req, res) => {
    try {
        const { employeeId } = req.params;
        const { startDate, endDate, page = 1, limit = 30 } = req.query;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const where = { employeeId };

        // Add date filters if provided
        if (startDate || endDate) {
            where.punchInTime = {};
            if (startDate) where.punchInTime.gte = new Date(startDate);
            if (endDate) {
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                where.punchInTime.lte = end;
            }
        }

        const [attendances, total] = await Promise.all([
            prisma.attendance.findMany({
                where,
                orderBy: { punchInTime: 'desc' },
                skip,
                take: parseInt(limit)
            }),
            prisma.attendance.count({ where })
        ]);

        res.status(200).json({
            success: true,
            data: attendances,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            }
        });
    } catch (error) {
        console.error('Get attendance history error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch attendance history',
            error: error.message
        });
    }
};

// Get Attendance Statistics
export const getAttendanceStats = async (req, res) => {
    try {
        const { employeeId } = req.params;
        const { month, year } = req.query;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Default to current month/year
        const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
        const targetYear = year ? parseInt(year) : new Date().getFullYear();

        // Calculate date range
        const startDate = new Date(targetYear, targetMonth - 1, 1);
        const endDate = new Date(targetYear, targetMonth, 0, 23, 59, 59, 999);

        const attendances = await prisma.attendance.findMany({
            where: {
                employeeId,
                punchInTime: {
                    gte: startDate,
                    lte: endDate
                }
            }
        });

        // Calculate statistics
        const totalDays = attendances.length;
        const completedDays = attendances.filter(a => a.status === 'completed').length;
        const totalWorkHours = attendances.reduce((sum, a) => sum + (a.totalWorkHours || 0), 0);
        const totalDistance = attendances.reduce((sum, a) => sum + (a.totalDistanceKm || 0), 0);
        const avgWorkHours = totalDays > 0 ? totalWorkHours / completedDays : 0;

        res.status(200).json({
            success: true,
            data: {
                month: targetMonth,
                year: targetYear,
                totalDays,
                completedDays,
                activeDays: totalDays - completedDays,
                totalWorkHours: parseFloat(totalWorkHours.toFixed(2)),
                avgWorkHours: parseFloat(avgWorkHours.toFixed(2)),
                totalDistance: parseFloat(totalDistance.toFixed(2)),
                attendances
            }
        });
    } catch (error) {
        console.error('Get attendance stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch attendance statistics',
            error: error.message
        });
    }
};

// Get All Employees Attendance (Admin)
export const getAllAttendance = async (req, res) => {
    try {
        const { date, status, page = 1, limit = 50 } = req.query;

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const where = {};

        // Filter by date
        if (date) {
            const targetDate = new Date(date);
            targetDate.setHours(0, 0, 0, 0);
            const nextDay = new Date(targetDate);
            nextDay.setDate(nextDay.getDate() + 1);

            where.punchInTime = {
                gte: targetDate,
                lt: nextDay
            };
        }

        // Filter by status
        if (status) {
            where.status = status;
        }

        const [attendances, total] = await Promise.all([
            prisma.attendance.findMany({
                where,
                orderBy: { punchInTime: 'desc' },
                skip,
                take: parseInt(limit)
            }),
            prisma.attendance.count({ where })
        ]);

        res.status(200).json({
            success: true,
            data: attendances,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            }
        });
    } catch (error) {
        console.error('Get all attendance error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch attendance records',
            error: error.message
        });
    }
};

export default {
    punchIn,
    punchOut,
    getTodayAttendance,
    getAttendanceHistory,
    getAttendanceStats,
    getAllAttendance
};
