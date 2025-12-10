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

// Helper function to calculate work hours with proper timezone handling
function calculateWorkHours(punchInTime, punchOutTime) {
    const punchIn = new Date(punchInTime);
    const punchOut = new Date(punchOutTime);
    
    // Validate dates
    if (isNaN(punchIn.getTime()) || isNaN(punchOut.getTime())) {
        console.error('Invalid date provided for work hours calculation');
        return 0;
    }
    
    // Calculate difference in milliseconds
    const diffMs = punchOut.getTime() - punchIn.getTime();
    
    // Convert to hours with precision
    const hours = diffMs / (1000 * 60 * 60);
    
    // Round to 2 decimal places and ensure positive
    return Math.max(0, Math.round(hours * 100) / 100);
}

// Helper function to get current work duration for active attendance
function getCurrentWorkDuration(punchInTime) {
    const now = new Date();
    const punchIn = new Date(punchInTime);
    
    if (isNaN(punchIn.getTime())) {
        return 0;
    }
    
    const diffMs = now.getTime() - punchIn.getTime();
    const hours = diffMs / (1000 * 60 * 60);
    
    return Math.max(0, Math.round(hours * 100) / 100);
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

        // Check if user has any active (not punched out) attendance
        const activeAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                status: 'active'
            }
        });

        console.log('Checking active attendance for:', employeeId);
        console.log('Active attendance:', activeAttendance ? activeAttendance.id : 'none');

        if (activeAttendance) {
            return res.status(400).json({
                success: false,
                message: 'Please punch out from your current session before starting a new one',
                data: activeAttendance
            });
        }

        // Create attendance record with proper date handling
        const punchInTime = new Date();
        const attendance = await prisma.attendance.create({
            data: {
                employeeId,
                employeeName,
                date: new Date(punchInTime.getFullYear(), punchInTime.getMonth(), punchInTime.getDate()),
                punchInTime,
                punchInLatitude: parseFloat(punchInLatitude),
                punchInLongitude: parseFloat(punchInLongitude),
                punchInPhoto,
                punchInAddress,
                bikeKmStart,
                status: 'active',
                totalWorkHours: 0, // Initialize to 0
                totalDistanceKm: 0 // Initialize to 0
            }
        });

        console.log('✅ Attendance created:', {
            id: attendance.id,
            employeeId: attendance.employeeId,
            punchInTime: attendance.punchInTime.toISOString(),
            status: attendance.status
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

        // Update attendance record with proper calculations
        const updatedAttendance = await prisma.attendance.update({
            where: { id: attendanceId },
            data: {
                punchOutTime,
                punchOutLatitude: parseFloat(punchOutLatitude),
                punchOutLongitude: parseFloat(punchOutLongitude),
                punchOutPhoto,
                punchOutAddress,
                bikeKmEnd,
                totalDistanceKm: Math.round(distance * 100) / 100, // Round to 2 decimal places
                totalWorkHours: workHours,
                status: 'completed'
            }
        });

        console.log('✅ Attendance completed:', {
            id: updatedAttendance.id,
            employeeId: updatedAttendance.employeeId,
            punchInTime: updatedAttendance.punchInTime.toISOString(),
            punchOutTime: updatedAttendance.punchOutTime.toISOString(),
            totalWorkHours: updatedAttendance.totalWorkHours,
            totalDistanceKm: updatedAttendance.totalDistanceKm,
            status: updatedAttendance.status
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

// Get Today's Attendance (Latest Active or All Today's Sessions)
export const getTodayAttendance = async (req, res) => {
    try {
        const { employeeId } = req.params;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Get today's date range in UTC
        const now = new Date();
        const today = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0));
        const tomorrow = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0));

        console.log('Fetching attendance for:', employeeId);
        console.log('Date range:', today.toISOString(), 'to', tomorrow.toISOString());

        // Get all today's attendance sessions
        const todayAttendances = await prisma.attendance.findMany({
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

        // Get the latest active session or the most recent one
        const activeAttendance = todayAttendances.find(a => a.status === 'active');
        const latestAttendance = todayAttendances[0] || null;

        console.log('Found attendances:', todayAttendances.length);
        console.log('Active attendance:', activeAttendance ? activeAttendance.id : 'none');

        // Prepare response data
        let responseData = activeAttendance || latestAttendance;
        if (responseData && responseData.status === 'active') {
            const currentWorkHours = getCurrentWorkDuration(responseData.punchInTime);
            responseData = {
                ...responseData,
                currentWorkHours: currentWorkHours,
                isActive: true
            };
            
            console.log('Active attendance - current work hours:', currentWorkHours);
        }

        res.status(200).json({
            success: true,
            data: responseData,
            allTodaySessions: todayAttendances,
            totalSessions: todayAttendances.length,
            serverTime: now.toISOString()
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

// Get Live Attendance Dashboard (Admin)
export const getLiveAttendanceDashboard = async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        // Get today's attendance records with enhanced data
        const todayAttendances = await prisma.attendance.findMany({
            where: {
                punchInTime: {
                    gte: today,
                    lt: tomorrow
                }
            },
            orderBy: { punchInTime: 'desc' }
        });

        // Get all employees for comparison
        const allEmployees = await prisma.user.findMany({
            where: {
                isActive: true,
                roles: {
                    hasSome: ['salesman', 'telecaller', 'marketing']
                }
            },
            select: {
                id: true,
                name: true,
                employeeCode: true,
                roles: true,
                departmentId: true,
                department: {
                    select: {
                        name: true
                    }
                }
            }
        });

        // Group attendances by employee to handle multiple sessions
        const employeeAttendanceMap = {};
        todayAttendances.forEach(attendance => {
            if (!employeeAttendanceMap[attendance.employeeId]) {
                employeeAttendanceMap[attendance.employeeId] = [];
            }
            employeeAttendanceMap[attendance.employeeId].push(attendance);
        });

        // Calculate enhanced statistics
        const totalEmployees = allEmployees.length;
        const uniquePresentEmployees = Object.keys(employeeAttendanceMap).length;
        const absentEmployees = totalEmployees - uniquePresentEmployees;
        const activeEmployees = todayAttendances.filter(a => a.status === 'active').length;
        const completedEmployees = todayAttendances.filter(a => a.status === 'completed').length;
        const totalSessions = todayAttendances.length;

        // Calculate average work hours for completed attendances
        const completedAttendances = todayAttendances.filter(a => a.totalWorkHours && a.totalWorkHours > 0);
        const avgWorkHours = completedAttendances.length > 0
            ? completedAttendances.reduce((sum, a) => sum + a.totalWorkHours, 0) / completedAttendances.length
            : 0;

        // Calculate total work hours for today
        const totalWorkHours = completedAttendances.reduce((sum, a) => sum + a.totalWorkHours, 0);

        // Get absent employees with their details
        const presentEmployeeIds = Object.keys(employeeAttendanceMap);
        const absentEmployeesList = allEmployees.filter(emp => !presentEmployeeIds.includes(emp.id));

        // Enhance attendance records with current work duration for active sessions
        const enhancedAttendances = todayAttendances.map(attendance => {
            let currentWorkHours = 0;
            if (attendance.status === 'active') {
                currentWorkHours = getCurrentWorkDuration(attendance.punchInTime);
            }

            return {
                ...attendance,
                currentWorkHours,
                isActive: attendance.status === 'active',
                isPunchedOut: attendance.status === 'completed',
                workDuration: attendance.totalWorkHours || currentWorkHours,
                punchInFormatted: attendance.punchInTime.toISOString(),
                punchOutFormatted: attendance.punchOutTime ? attendance.punchOutTime.toISOString() : null
            };
        });

        // Calculate attendance percentage
        const attendancePercentage = totalEmployees > 0 ? (uniquePresentEmployees / totalEmployees) * 100 : 0;

        res.status(200).json({
            success: true,
            data: {
                statistics: {
                    totalEmployees,
                    presentEmployees: uniquePresentEmployees,
                    absentEmployees,
                    activeEmployees,
                    completedEmployees,
                    totalSessions,
                    avgWorkHours: parseFloat(avgWorkHours.toFixed(2)),
                    totalWorkHours: parseFloat(totalWorkHours.toFixed(2)),
                    attendancePercentage: parseFloat(attendancePercentage.toFixed(2))
                },
                attendances: enhancedAttendances,
                absentEmployees: absentEmployeesList,
                allEmployees,
                employeeAttendanceMap,
                date: today.toISOString(),
                lastUpdated: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Get live dashboard error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch live dashboard data',
            error: error.message
        });
    }
};

// Get Attendance Analytics (Admin)
export const getAttendanceAnalytics = async (req, res) => {
    try {
        const { startDate, endDate, employeeId } = req.query;

        let dateFilter = {};
        if (startDate && endDate) {
            dateFilter = {
                punchInTime: {
                    gte: new Date(startDate),
                    lte: new Date(endDate)
                }
            };
        } else {
            // Default to last 30 days
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            dateFilter = {
                punchInTime: {
                    gte: thirtyDaysAgo
                }
            };
        }

        const where = { ...dateFilter };
        if (employeeId) {
            where.employeeId = employeeId;
        }

        const attendances = await prisma.attendance.findMany({
            where,
            orderBy: { punchInTime: 'desc' }
        });

        // Group by date for daily analytics
        const dailyStats = {};
        attendances.forEach(attendance => {
            const date = attendance.punchInTime.toISOString().split('T')[0];
            if (!dailyStats[date]) {
                dailyStats[date] = {
                    date,
                    totalEmployees: 0,
                    activeEmployees: 0,
                    completedEmployees: 0,
                    totalWorkHours: 0,
                    totalDistance: 0,
                    attendances: []
                };
            }

            dailyStats[date].totalEmployees++;
            if (attendance.status === 'active') dailyStats[date].activeEmployees++;
            if (attendance.status === 'completed') dailyStats[date].completedEmployees++;
            if (attendance.totalWorkHours) dailyStats[date].totalWorkHours += attendance.totalWorkHours;
            if (attendance.totalDistanceKm) dailyStats[date].totalDistance += attendance.totalDistanceKm;
            dailyStats[date].attendances.push(attendance);
        });

        // Convert to array and sort by date
        const dailyAnalytics = Object.values(dailyStats).sort((a, b) => new Date(a.date) - new Date(b.date));

        // Calculate overall statistics
        const totalAttendances = attendances.length;
        const completedAttendances = attendances.filter(a => a.status === 'completed');
        const totalWorkHours = completedAttendances.reduce((sum, a) => sum + (a.totalWorkHours || 0), 0);
        const totalDistance = attendances.reduce((sum, a) => sum + (a.totalDistanceKm || 0), 0);
        const avgWorkHours = completedAttendances.length > 0 ? totalWorkHours / completedAttendances.length : 0;

        res.status(200).json({
            success: true,
            data: {
                summary: {
                    totalAttendances,
                    completedAttendances: completedAttendances.length,
                    activeAttendances: attendances.filter(a => a.status === 'active').length,
                    totalWorkHours: parseFloat(totalWorkHours.toFixed(2)),
                    avgWorkHours: parseFloat(avgWorkHours.toFixed(2)),
                    totalDistance: parseFloat(totalDistance.toFixed(2))
                },
                dailyAnalytics,
                attendances
            }
        });
    } catch (error) {
        console.error('Get attendance analytics error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch attendance analytics',
            error: error.message
        });
    }
};

// Get Detailed Attendance with Full Information (Admin)
export const getDetailedAttendance = async (req, res) => {
    try {
        const { date, employeeId, page = 1, limit = 50 } = req.query;

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const where = {};

        // Filter by date (default to today)
        if (date) {
            const targetDate = new Date(date);
            targetDate.setHours(0, 0, 0, 0);
            const nextDay = new Date(targetDate);
            nextDay.setDate(nextDay.getDate() + 1);

            where.punchInTime = {
                gte: targetDate,
                lt: nextDay
            };
        } else {
            // Default to today
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const tomorrow = new Date(today);
            tomorrow.setDate(tomorrow.getDate() + 1);

            where.punchInTime = {
                gte: today,
                lt: tomorrow
            };
        }

        // Filter by employee
        if (employeeId) {
            where.employeeId = employeeId;
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

        // Enhance attendance data with calculated fields
        const enhancedAttendances = attendances.map(attendance => {
            let currentWorkHours = 0;
            if (attendance.status === 'active') {
                currentWorkHours = getCurrentWorkDuration(attendance.punchInTime);
            }

            return {
                ...attendance,
                currentWorkHours,
                isActive: attendance.status === 'active',
                isPunchedOut: attendance.status === 'completed',
                workDuration: attendance.totalWorkHours || currentWorkHours,
                punchInFormatted: attendance.punchInTime.toISOString(),
                punchOutFormatted: attendance.punchOutTime ? attendance.punchOutTime.toISOString() : null,
                dateFormatted: attendance.punchInTime.toISOString().split('T')[0]
            };
        });

        res.status(200).json({
            success: true,
            data: enhancedAttendances,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            },
            filters: {
                date: date || new Date().toISOString().split('T')[0],
                employeeId: employeeId || 'all'
            }
        });
    } catch (error) {
        console.error('Get detailed attendance error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch detailed attendance',
            error: error.message
        });
    }
};

// Get Employee Attendance Report (Admin)
export const getEmployeeAttendanceReport = async (req, res) => {
    try {
        const { month, year } = req.query;

        const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
        const targetYear = year ? parseInt(year) : new Date().getFullYear();

        const startDate = new Date(targetYear, targetMonth - 1, 1);
        const endDate = new Date(targetYear, targetMonth, 0, 23, 59, 59, 999);

        // Get all employees
        const employees = await prisma.user.findMany({
            where: {
                isActive: true,
                roles: {
                    hasSome: ['salesman', 'telecaller', 'marketing']
                }
            },
            select: {
                id: true,
                name: true,
                employeeCode: true,
                roles: true,
                department: {
                    select: {
                        name: true
                    }
                }
            }
        });

        // Get attendance records for the month
        const attendances = await prisma.attendance.findMany({
            where: {
                punchInTime: {
                    gte: startDate,
                    lte: endDate
                }
            }
        });

        // Group attendances by employee
        const employeeAttendances = {};
        attendances.forEach(attendance => {
            if (!employeeAttendances[attendance.employeeId]) {
                employeeAttendances[attendance.employeeId] = [];
            }
            employeeAttendances[attendance.employeeId].push(attendance);
        });

        // Calculate report for each employee
        const employeeReports = employees.map(employee => {
            const empAttendances = employeeAttendances[employee.id] || [];
            const presentDays = empAttendances.length;
            const completedDays = empAttendances.filter(a => a.status === 'completed').length;
            const totalWorkHours = empAttendances.reduce((sum, a) => sum + (a.totalWorkHours || 0), 0);
            const totalDistance = empAttendances.reduce((sum, a) => sum + (a.totalDistanceKm || 0), 0);
            const avgWorkHours = completedDays > 0 ? totalWorkHours / completedDays : 0;

            // Calculate working days in month (excluding weekends)
            const daysInMonth = new Date(targetYear, targetMonth, 0).getDate();
            let workingDays = 0;
            for (let day = 1; day <= daysInMonth; day++) {
                const date = new Date(targetYear, targetMonth - 1, day);
                const dayOfWeek = date.getDay();
                if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Not Sunday or Saturday
                    workingDays++;
                }
            }

            const attendancePercentage = workingDays > 0 ? (presentDays / workingDays) * 100 : 0;

            return {
                employee: {
                    id: employee.id,
                    name: employee.name,
                    employeeCode: employee.employeeCode,
                    roles: employee.roles,
                    department: employee.department?.name
                },
                statistics: {
                    presentDays,
                    completedDays,
                    workingDays,
                    absentDays: workingDays - presentDays,
                    attendancePercentage: parseFloat(attendancePercentage.toFixed(2)),
                    totalWorkHours: parseFloat(totalWorkHours.toFixed(2)),
                    avgWorkHours: parseFloat(avgWorkHours.toFixed(2)),
                    totalDistance: parseFloat(totalDistance.toFixed(2))
                },
                attendances: empAttendances
            };
        });

        res.status(200).json({
            success: true,
            data: {
                month: targetMonth,
                year: targetYear,
                employeeReports: employeeReports.sort((a, b) => b.statistics.attendancePercentage - a.statistics.attendancePercentage)
            }
        });
    } catch (error) {
        console.error('Get employee attendance report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch employee attendance report',
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
    getAllAttendance,
    getLiveAttendanceDashboard,
    getAttendanceAnalytics,
    getDetailedAttendance,
    getEmployeeAttendanceReport
};
