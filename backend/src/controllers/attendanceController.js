import { PrismaClient } from '@prisma/client';
import {
    getCurrentISTTime,
    convertUTCToIST,
    convertISTToUTC,
    getISTDateRange,
    formatISTTime,
    getISTTimestamp,
    calculateWorkHoursIST,
    getCurrentWorkDurationIST,
    getISTTimezoneInfo
} from '../utils/timezone.js';
import NotificationService from '../services/notificationService.js';

// kiranastore hostel caterers sweets 
//  date filter in list of aaccoumts

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

        // Enhanced validation
        if (!employeeId || !employeeName || !punchInLatitude || !punchInLongitude) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: employeeId, employeeName, latitude, longitude'
            });
        }

        // Validate coordinates
        const lat = parseFloat(punchInLatitude);
        const lng = parseFloat(punchInLongitude);
        if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            return res.status(400).json({
                success: false,
                message: 'Invalid coordinates provided'
            });
        }

        // Get current IST time and date range for today
        const currentISTTime = getCurrentISTTime();
        const { startOfDay, endOfDay } = getISTDateRange();

        // Get employee's working hours configuration from database
        let employee;
        try {
            employee = await prisma.user.findUnique({
                where: { id: employeeId },
                select: {
                    name: true,
                    workStartTime: true,
                    workEndTime: true,
                    latePunchInGraceMinutes: true,
                    earlyPunchOutGraceMinutes: true
                }
            });
        } catch (error) {
            console.log('⚠️ Error fetching employee:', error.message);
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        if (!employee) {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        // Use employee's working hours or defaults
        const workStartTime = employee.workStartTime || '09:00:00';
        const graceMinutes = employee.latePunchInGraceMinutes || 45;

        // Create cutoff time based on employee's schedule
        const [startHour, startMinute] = workStartTime.split(':').map(Number);
        const cutoffTime = new Date(currentISTTime);
        cutoffTime.setHours(startHour, startMinute + graceMinutes, 0, 0);

        const isAfterCutoff = currentISTTime > cutoffTime;

        console.log('⏰ Employee working hours check:', {
            employeeId,
            employeeName: employee.name,
            workStartTime,
            graceMinutes,
            cutoffTime: `${cutoffTime.getHours()}:${cutoffTime.getMinutes().toString().padStart(2, '0')}`,
            currentTime: `${currentISTTime.getHours()}:${currentISTTime.getMinutes().toString().padStart(2, '0')}`,
            isAfterCutoff
        });

        let isLatePunchIn = false;
        let lateApprovalId = null;

        // If after cutoff time, validate approval
        if (isAfterCutoff) {
            // Check if user has any approved request for today
            const approvalRequest = await prisma.latePunchApproval.findFirst({
                where: {
                    employeeId,
                    status: 'APPROVED',
                    requestDate: {
                        gte: startOfDay,
                        lt: endOfDay
                    }
                }
            });

            if (!approvalRequest) {
                return res.status(400).json({
                    success: false,
                    message: `Punch-in is blocked after ${cutoffTime.getHours()}:${cutoffTime.getMinutes().toString().padStart(2, '0')}. Please request approval from admin first.`,
                    requiresApproval: true,
                    cutoffTime: `${cutoffTime.getHours()}:${cutoffTime.getMinutes().toString().padStart(2, '0')}`,
                    workStartTime: workStartTime,
                    graceMinutes: graceMinutes
                });
            }

            // Set approval details for attendance record
            isLatePunchIn = true;
            lateApprovalId = approvalRequest.id;

            console.log('✅ Late punch-in approval validated:', {
                employeeId,
                approvalRequestId: lateApprovalId
            });
        }

        // Check for any active attendance (not just today)
        const activeAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                status: 'active'
            },
            orderBy: {
                punchInTime: 'desc'
            }
        });

        console.log('🔍 Checking active attendance for:', employeeId);
        console.log('📅 IST Date range:', {
            startOfDay: startOfDay.toISOString(),
            endOfDay: endOfDay.toISOString(),
            currentIST: currentISTTime.toISOString(),
            isAfterCutoff,
            isLatePunchIn
        });

        if (activeAttendance) {
            console.log('❌ Active attendance found:', {
                id: activeAttendance.id,
                punchInTime: activeAttendance.punchInTime.toISOString(),
                status: activeAttendance.status
            });

            return res.status(400).json({
                success: false,
                message: 'You have an active session. Please punch out first before starting a new session.',
                data: {
                    ...activeAttendance,
                    punchInTimeIST: formatISTTime(activeAttendance.punchInTime, 'datetime'),
                    currentWorkHours: getCurrentWorkDurationIST(activeAttendance.punchInTime)
                }
            });
        }

        // Check for multiple sessions today (optional limit)
        const todaySessionsCount = await prisma.attendance.count({
            where: {
                employeeId,
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            }
        });

        console.log('📊 Today sessions count:', todaySessionsCount);

        // Optional: Limit sessions per day (uncomment if needed)
        // if (todaySessionsCount >= 3) {
        //     return res.status(400).json({
        //         success: false,
        //         message: 'Maximum 3 sessions allowed per day. Contact admin if needed.'
        //     });
        // }

        // Validate photo size if provided (prevent crashes)
        if (punchInPhoto && punchInPhoto.length > 5 * 1024 * 1024) { // 5MB limit
            return res.status(400).json({
                success: false,
                message: 'Photo size too large. Please use a smaller image.'
            });
        }

        // Create attendance record with proper UTC handling
        // getCurrentISTTime() now returns current UTC time directly
        const punchInTimeUTC = getCurrentISTTime();

        // Get today's date in IST for the date field
        const todayIST = new Date();
        const istDateOnly = new Date(todayIST.getFullYear(), todayIST.getMonth(), todayIST.getDate());

        const attendance = await prisma.attendance.create({
            data: {
                employeeId,
                employeeName,
                date: istDateOnly,
                punchInTime: punchInTimeUTC, // Store UTC time in database
                punchInLatitude: lat,
                punchInLongitude: lng,
                punchInPhoto: punchInPhoto || null,
                punchInAddress: punchInAddress || null,
                bikeKmStart: bikeKmStart || null,
                status: 'active',
                totalWorkHours: 0,
                totalDistanceKm: 0,
                // Late punch-in fields
                isLatePunchIn,
                lateApprovalId
            }
        });

        console.log('✅ Attendance created successfully:', {
            id: attendance.id,
            employeeId: attendance.employeeId,
            punchInTimeUTC: attendance.punchInTime.toISOString(),
            punchInTimeIST: formatISTTime(convertUTCToIST(attendance.punchInTime), 'datetime'),
            status: attendance.status,
            sessionNumber: todaySessionsCount + 1,
            isLatePunchIn: attendance.isLatePunchIn,
            lateApprovalId: attendance.lateApprovalId
        });

        // Mark approval code as used AFTER attendance is created successfully
        if (isLatePunchIn && lateApprovalId) {
            try {
                await prisma.latePunchApproval.update({
                    where: { id: lateApprovalId },
                    data: {
                        status: 'USED',  // Mark as USED to prevent reuse
                        codeUsed: true,
                        codeUsedAt: currentISTTime
                    }
                });
                console.log('✅ Late punch-in approval marked as USED:', {
                    approvalRequestId: lateApprovalId
                });
            } catch (updateError) {
                console.error('⚠️ Failed to mark approval as used:', updateError);
                // Don't fail the punch-in if this update fails
            }
        }

        // Enhance response with IST information and session details
        const responseData = {
            ...attendance,
            punchInTimeIST: formatISTTime(convertUTCToIST(attendance.punchInTime), 'datetime'),
            punchInTimeISTFormatted: formatISTTime(convertUTCToIST(attendance.punchInTime), 'time'),
            sessionNumber: todaySessionsCount + 1,
            timezone: getISTTimezoneInfo(),
            serverTime: {
                utc: new Date().toISOString(),
                ist: formatISTTime(getCurrentISTTime(), 'datetime')
            }
        };

        // Create punch-in notification for admin
        try {
            await NotificationService.createPunchInNotification(attendance);
            console.log('✅ Punch-in notification sent to admin');
        } catch (notificationError) {
            console.error('⚠️ Failed to send punch-in notification:', notificationError);
            // Don't fail the punch-in if notification fails
        }

        const successMessage = isLatePunchIn
            ? `Late punch-in approved and completed! Session ${todaySessionsCount + 1} started.`
            : `Punched in successfully! Session ${todaySessionsCount + 1} started.`;

        res.status(201).json({
            success: true,
            message: successMessage,
            data: responseData
        });
    } catch (error) {
        console.error('❌ Punch in error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to punch in. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
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

        // Enhanced validation
        if (!attendanceId || !punchOutLatitude || !punchOutLongitude) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: attendanceId, latitude, longitude'
            });
        }

        // Validate coordinates
        const lat = parseFloat(punchOutLatitude);
        const lng = parseFloat(punchOutLongitude);
        if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            return res.status(400).json({
                success: false,
                message: 'Invalid coordinates provided'
            });
        }

        // Get existing attendance record
        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance record not found. Please contact admin.'
            });
        }

        if (attendance.status === 'completed') {
            return res.status(400).json({
                success: false,
                message: 'Session already completed. Cannot punch out again.',
                data: {
                    ...attendance,
                    punchInTimeIST: formatISTTime(attendance.punchInTime, 'datetime'),
                    punchOutTimeIST: attendance.punchOutTime ? formatISTTime(attendance.punchOutTime, 'datetime') : null
                }
            });
        }

        // Validate photo size if provided (prevent crashes)
        if (punchOutPhoto && punchOutPhoto.length > 5 * 1024 * 1024) { // 5MB limit
            return res.status(400).json({
                success: false,
                message: 'Photo size too large. Please use a smaller image.'
            });
        }

        // Get current IST time
        const currentISTTime = getCurrentISTTime();
        const punchOutTimeUTC = currentISTTime; // getCurrentISTTime now returns UTC directly

        // Get employee's working hours configuration from database
        let employee;
        try {
            employee = await prisma.user.findUnique({
                where: { id: attendance.employeeId },
                select: {
                    name: true,
                    workStartTime: true,
                    workEndTime: true,
                    latePunchInGraceMinutes: true,
                    earlyPunchOutGraceMinutes: true
                }
            });
        } catch (error) {
            console.log('⚠️ Error fetching employee:', error.message);
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        if (!employee) {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        // Use employee's working hours or defaults
        const workEndTime = employee.workEndTime || '18:00:00';
        const graceMinutes = employee.earlyPunchOutGraceMinutes || 30;

        // Create early punch-out cutoff time based on employee's schedule
        const [endHour, endMinute] = workEndTime.split(':').map(Number);
        const earlyPunchOutCutoff = new Date(currentISTTime);
        earlyPunchOutCutoff.setHours(endHour, endMinute - graceMinutes, 0, 0);

        const isEarlyPunchOut = currentISTTime < earlyPunchOutCutoff;

        console.log('⏰ Employee early punch-out check:', {
            employeeId: attendance.employeeId,
            employeeName: employee.name,
            workEndTime,
            graceMinutes,
            earlyPunchOutCutoff: `${earlyPunchOutCutoff.getHours()}:${earlyPunchOutCutoff.getMinutes().toString().padStart(2, '0')}`,
            currentTime: `${currentISTTime.getHours()}:${currentISTTime.getMinutes().toString().padStart(2, '0')}`,
            isEarlyPunchOut
        });

        let earlyPunchOutApprovalId = null;

        // If before cutoff time, validate approval
        if (isEarlyPunchOut) {
            // Check if user has any approved request for this attendance
            const { startOfDay, endOfDay } = getISTDateRange();
            const approvalRequest = await prisma.earlyPunchOutApproval.findFirst({
                where: {
                    employeeId: attendance.employeeId,
                    attendanceId: attendanceId,
                    status: 'APPROVED',
                    requestDate: {
                        gte: startOfDay,
                        lt: endOfDay
                    }
                }
            });

            if (!approvalRequest) {
                return res.status(400).json({
                    success: false,
                    message: `Punch-out is blocked before ${earlyPunchOutCutoff.getHours()}:${earlyPunchOutCutoff.getMinutes().toString().padStart(2, '0')}. Please request approval from admin first.`,
                    requiresApproval: true,
                    cutoffTime: `${earlyPunchOutCutoff.getHours()}:${earlyPunchOutCutoff.getMinutes().toString().padStart(2, '0')}`,
                    isEarlyPunchOut: true
                });
            }

            // Set approval details
            earlyPunchOutApprovalId = approvalRequest.id;

            console.log('✅ Early punch-out approval validated:', {
                employeeId: attendance.employeeId,
                attendanceId,
                approvalRequestId: earlyPunchOutApprovalId
            });
        }

        // Validate punch out time (should be after punch in)
        if (punchOutTimeUTC <= attendance.punchInTime) {
            return res.status(400).json({
                success: false,
                message: 'Invalid punch out time. Please check your device time.'
            });
        }

        // Calculate work hours - both times should be in UTC for correct calculation
        // attendance.punchInTime is UTC from database, punchOutTimeUTC is also UTC
        const workHours = calculateWorkHoursIST(attendance.punchInTime, punchOutTimeUTC);

        console.log('⏱️ Work hours validation:', {
            punchInTimeUTC: attendance.punchInTime.toISOString(),
            punchOutTimeUTC: punchOutTimeUTC.toISOString(),
            workHours,
            workMinutes: workHours * 60
        });

        // Validate minimum work duration (prevent accidental immediate punch out)
        if (workHours < 0.017) { // Less than 1 minute
            return res.status(400).json({
                success: false,
                message: 'Minimum work duration is 1 minute. Please wait before punching out.'
            });
        }

        // Calculate actual travel distance from route points
        let distance = 0;

        try {
            // Get route points for this attendance session - explicitly select only needed fields
            const routePoints = await prisma.salesmanRouteLog.findMany({
                where: {
                    attendanceId: attendanceId
                },
                orderBy: {
                    recordedAt: 'asc'
                },
                select: {
                    latitude: true,
                    longitude: true
                }
            });

            if (routePoints.length > 1) {
                // Calculate cumulative distance from route points
                for (let i = 1; i < routePoints.length; i++) {
                    const segmentDistance = calculateDistance(
                        routePoints[i - 1].latitude,
                        routePoints[i - 1].longitude,
                        routePoints[i].latitude,
                        routePoints[i].longitude
                    );
                    distance += segmentDistance;
                }

                // Add final segment from last route point to punch out location
                const lastPoint = routePoints[routePoints.length - 1];
                const finalSegment = calculateDistance(
                    lastPoint.latitude,
                    lastPoint.longitude,
                    lat,
                    lng
                );
                distance += finalSegment;

                console.log(`📍 Calculated route distance: ${distance.toFixed(3)} km from ${routePoints.length} points`);
            } else {
                // Fallback to straight-line distance if no route points
                distance = calculateDistance(
                    attendance.punchInLatitude,
                    attendance.punchInLongitude,
                    lat,
                    lng
                );
                console.log(`📍 Using straight-line distance: ${distance.toFixed(3)} km (no route data)`);
            }
        } catch (routeError) {
            console.error('❌ Error calculating route distance:', routeError);
            // Fallback to straight-line distance
            distance = calculateDistance(
                attendance.punchInLatitude,
                attendance.punchInLongitude,
                lat,
                lng
            );
        }

        // Validate reasonable distance (optional check)
        if (distance > 1000) { // More than 1000 km seems unrealistic
            console.log('⚠️ Warning: Large distance calculated:', distance, 'km');
        }

        // Update attendance record with proper calculations
        const updatedAttendance = await prisma.attendance.update({
            where: { id: attendanceId },
            data: {
                punchOutTime: punchOutTimeUTC, // Store UTC time in database
                punchOutLatitude: lat,
                punchOutLongitude: lng,
                punchOutPhoto: punchOutPhoto || null,
                punchOutAddress: punchOutAddress || null,
                bikeKmEnd: bikeKmEnd || null,
                totalDistanceKm: Math.round(distance * 1000) / 1000, // Round to 3 decimal places
                totalWorkHours: Math.round(workHours * 100) / 100, // Round to 2 decimal places
                status: 'completed',
                // Early punch-out fields
                isEarlyPunchOut,
                earlyPunchOutApprovalId
            }
        });

        console.log('✅ Attendance completed successfully:', {
            id: updatedAttendance.id,
            employeeId: updatedAttendance.employeeId,
            punchInTimeUTC: updatedAttendance.punchInTime.toISOString(),
            punchInTimeIST: formatISTTime(convertUTCToIST(updatedAttendance.punchInTime), 'datetime'),
            punchOutTimeUTC: updatedAttendance.punchOutTime.toISOString(),
            punchOutTimeIST: formatISTTime(convertUTCToIST(updatedAttendance.punchOutTime), 'datetime'),
            totalWorkHours: updatedAttendance.totalWorkHours,
            totalDistanceKm: updatedAttendance.totalDistanceKm,
            status: updatedAttendance.status
        });

        // Mark early punch-out approval as USED after successful punch-out
        if (isEarlyPunchOut && earlyPunchOutApprovalId) {
            try {
                await prisma.earlyPunchOutApproval.update({
                    where: { id: earlyPunchOutApprovalId },
                    data: {
                        status: 'USED',  // Mark as USED to prevent reuse
                        codeUsed: true,
                        codeUsedAt: currentISTTime
                    }
                });
                console.log('✅ Early punch-out approval marked as USED:', {
                    approvalRequestId: earlyPunchOutApprovalId
                });
            } catch (updateError) {
                console.error('⚠️ Failed to mark early punch-out approval as used:', updateError);
                // Don't fail the punch-out if this update fails
            }
        }

        // Calculate additional metrics
        const workDurationMinutes = Math.round(workHours * 60);
        const workDurationFormatted = `${Math.floor(workHours)}h ${Math.round((workHours % 1) * 60)}m`;

        // Enhance response with IST information and detailed metrics
        const responseData = {
            ...updatedAttendance,
            punchInTimeIST: formatISTTime(convertUTCToIST(updatedAttendance.punchInTime), 'datetime'),
            punchOutTimeIST: formatISTTime(convertUTCToIST(updatedAttendance.punchOutTime), 'datetime'),
            punchInTimeISTFormatted: formatISTTime(convertUTCToIST(updatedAttendance.punchInTime), 'time'),
            punchOutTimeISTFormatted: formatISTTime(convertUTCToIST(updatedAttendance.punchOutTime), 'time'),
            workDurationFormatted,
            workDurationMinutes,
            distanceFormatted: `${updatedAttendance.totalDistanceKm.toFixed(2)} km`,
            timezone: getISTTimezoneInfo(),
            serverTime: {
                utc: new Date().toISOString(),
                ist: formatISTTime(convertISTToUTC(getCurrentISTTime()), 'datetime')
            }
        };

        // Create punch-out notification for admin
        try {
            await NotificationService.createPunchOutNotification(updatedAttendance);
            console.log('✅ Punch-out notification sent to admin');
        } catch (notificationError) {
            console.error('⚠️ Failed to send punch-out notification:', notificationError);
            // Don't fail the punch-out if notification fails
        }

        res.status(200).json({
            success: true,
            message: `Punched out successfully! Worked for ${workDurationFormatted}, traveled ${updatedAttendance.totalDistanceKm.toFixed(2)} km.`,
            data: responseData
        });
    } catch (error) {
        console.error('❌ Punch out error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to punch out. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
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

        // Get today's date range in IST
        const { startOfDay, endOfDay } = getISTDateRange();

        console.log('Fetching attendance for:', employeeId);
        console.log('IST Date range:', startOfDay.toISOString(), 'to', endOfDay.toISOString());

        // Get all today's attendance sessions
        const todayAttendances = await prisma.attendance.findMany({
            where: {
                employeeId,
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
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

        // Prepare response data with IST formatting
        let responseData = activeAttendance || latestAttendance;
        if (responseData) {
            let currentWorkHours = 0;
            if (responseData.status === 'active') {
                currentWorkHours = getCurrentWorkDurationIST(responseData.punchInTime);
            }

            responseData = {
                ...responseData,
                currentWorkHours,
                isActive: responseData.status === 'active',
                punchInTimeIST: formatISTTime(convertUTCToIST(responseData.punchInTime), 'datetime'),
                punchInTimeISTFormatted: formatISTTime(convertUTCToIST(responseData.punchInTime), 'time'),
                punchOutTimeIST: responseData.punchOutTime ? formatISTTime(convertUTCToIST(responseData.punchOutTime), 'datetime') : null,
                punchOutTimeISTFormatted: responseData.punchOutTime ? formatISTTime(convertUTCToIST(responseData.punchOutTime), 'time') : null,
                workDurationFormatted: currentWorkHours > 0 ? `${Math.floor(currentWorkHours)}h ${Math.round((currentWorkHours % 1) * 60)}m` : null
            };

            console.log('Active attendance - current work hours:', currentWorkHours);
        }

        // Enhance all sessions with IST formatting
        const enhancedSessions = todayAttendances.map(session => ({
            ...session,
            punchInTimeIST: formatISTTime(convertUTCToIST(session.punchInTime), 'datetime'),
            punchInTimeISTFormatted: formatISTTime(convertUTCToIST(session.punchInTime), 'time'),
            punchOutTimeIST: session.punchOutTime ? formatISTTime(convertUTCToIST(session.punchOutTime), 'datetime') : null,
            punchOutTimeISTFormatted: session.punchOutTime ? formatISTTime(convertUTCToIST(session.punchOutTime), 'time') : null,
            currentWorkHours: session.status === 'active' ? getCurrentWorkDurationIST(session.punchInTime) : session.totalWorkHours
        }));

        const currentISTTime = getCurrentISTTime();

        res.status(200).json({
            success: true,
            data: responseData,
            allTodaySessions: enhancedSessions,
            totalSessions: todayAttendances.length,
            serverTime: currentISTTime.toISOString(),
            serverTimeIST: formatISTTime(convertISTToUTC(currentISTTime), 'datetime'),
            timezone: getISTTimezoneInfo()
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
        // Get today's date range in IST
        const { startOfDay, endOfDay } = getISTDateRange();

        // Get today's attendance records with enhanced data
        const todayAttendances = await prisma.attendance.findMany({
            where: {
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
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

        // Enhance attendance records with current work duration for active sessions and IST formatting
        const enhancedAttendances = todayAttendances.map(attendance => {
            let currentWorkHours = 0;
            if (attendance.status === 'active') {
                currentWorkHours = getCurrentWorkDurationIST(attendance.punchInTime);
            }

            return {
                ...attendance,
                currentWorkHours,
                isActive: attendance.status === 'active',
                isPunchedOut: attendance.status === 'completed',
                workDuration: attendance.totalWorkHours || currentWorkHours,
                punchInFormatted: attendance.punchInTime.toISOString(),
                punchOutFormatted: attendance.punchOutTime ? attendance.punchOutTime.toISOString() : null,
                punchInTimeIST: formatISTTime(attendance.punchInTime, 'datetime'),
                punchInTimeISTFormatted: formatISTTime(attendance.punchInTime, 'time'),
                punchOutTimeIST: attendance.punchOutTime ? formatISTTime(attendance.punchOutTime, 'datetime') : null,
                punchOutTimeISTFormatted: attendance.punchOutTime ? formatISTTime(attendance.punchOutTime, 'time') : null,
                workDurationFormatted: currentWorkHours > 0 || attendance.totalWorkHours > 0 ?
                    `${Math.floor(attendance.totalWorkHours || currentWorkHours)}h ${Math.round(((attendance.totalWorkHours || currentWorkHours) % 1) * 60)}m` : null
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
                date: startOfDay.toISOString(),
                dateIST: formatISTTime(startOfDay, 'date'),
                lastUpdated: new Date().toISOString(),
                lastUpdatedIST: formatISTTime(convertISTToUTC(getCurrentISTTime()), 'datetime'),
                timezone: getISTTimezoneInfo()
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

        // Filter by date (default to today) with proper IST handling
        let dateRange;
        if (date) {
            // Parse the provided date and get IST range
            const targetDate = new Date(date);
            dateRange = getISTDateRange(targetDate);
        } else {
            // Default to today in IST
            dateRange = getISTDateRange();
        }

        where.punchInTime = {
            gte: dateRange.startOfDay,
            lt: dateRange.endOfDay
        };

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

        // Enhance attendance data with calculated fields and IST formatting
        const enhancedAttendances = attendances.map(attendance => {
            let currentWorkHours = 0;
            if (attendance.status === 'active') {
                currentWorkHours = getCurrentWorkDurationIST(attendance.punchInTime);
            }

            return {
                ...attendance,
                currentWorkHours,
                isActive: attendance.status === 'active',
                isPunchedOut: attendance.status === 'completed',
                workDuration: attendance.totalWorkHours || currentWorkHours,
                punchInFormatted: attendance.punchInTime.toISOString(),
                punchOutFormatted: attendance.punchOutTime ? attendance.punchOutTime.toISOString() : null,
                dateFormatted: attendance.punchInTime.toISOString().split('T')[0],
                // IST formatted fields
                punchInTimeIST: formatISTTime(attendance.punchInTime, 'datetime'),
                punchInTimeISTFormatted: formatISTTime(attendance.punchInTime, 'time'),
                punchOutTimeIST: attendance.punchOutTime ? formatISTTime(attendance.punchOutTime, 'datetime') : null,
                punchOutTimeISTFormatted: attendance.punchOutTime ? formatISTTime(attendance.punchOutTime, 'time') : null,
                dateISTFormatted: formatISTTime(attendance.punchInTime, 'date'),
                workDurationFormatted: (attendance.totalWorkHours || currentWorkHours) > 0 ?
                    `${Math.floor(attendance.totalWorkHours || currentWorkHours)}h ${Math.round(((attendance.totalWorkHours || currentWorkHours) % 1) * 60)}m` : null
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
                dateIST: formatISTTime(dateRange.startOfDay, 'date'),
                employeeId: employeeId || 'all'
            },
            timezone: getISTTimezoneInfo()
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

// Get Current Positions of Active Employees (Admin - Live Tracking)
export const getCurrentPositions = async (req, res) => {
    try {
        // Get today's active attendance sessions
        const { startOfDay, endOfDay } = getISTDateRange();

        const activeAttendances = await prisma.attendance.findMany({
            where: {
                status: 'active',
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            },
            select: {
                id: true,
                employeeId: true,
                employeeName: true,
                punchInTime: true,
                punchInLatitude: true,
                punchInLongitude: true
            }
        });

        // Get latest route points for each active employee
        const employeePositions = await Promise.all(
            activeAttendances.map(async (attendance) => {
                try {
                    // Get the most recent route point - explicitly select only needed fields
                    const latestRoutePoint = await prisma.salesmanRouteLog.findFirst({
                        where: {
                            attendanceId: attendance.id
                        },
                        orderBy: {
                            recordedAt: 'desc'
                        },
                        select: {
                            latitude: true,
                            longitude: true,
                            speed: true,
                            recordedAt: true
                        }
                    });

                    // Calculate current travel distance - explicitly select only needed fields
                    let currentDistance = 0;
                    const routePoints = await prisma.salesmanRouteLog.findMany({
                        where: {
                            attendanceId: attendance.id
                        },
                        orderBy: {
                            recordedAt: 'asc'
                        },
                        select: {
                            latitude: true,
                            longitude: true
                        }
                    });

                    if (routePoints.length > 1) {
                        for (let i = 1; i < routePoints.length; i++) {
                            const segmentDistance = calculateDistance(
                                routePoints[i - 1].latitude,
                                routePoints[i - 1].longitude,
                                routePoints[i].latitude,
                                routePoints[i].longitude
                            );
                            currentDistance += segmentDistance;
                        }
                    }

                    return {
                        attendanceId: attendance.id,
                        employeeId: attendance.employeeId,
                        employeeName: attendance.employeeName,
                        punchInTime: attendance.punchInTime,
                        punchInTimeIST: formatISTTime(attendance.punchInTime, 'datetime'),
                        currentWorkHours: getCurrentWorkDurationIST(attendance.punchInTime),
                        // Current position (latest route point or punch-in location)
                        currentLatitude: latestRoutePoint?.latitude || attendance.punchInLatitude,
                        currentLongitude: latestRoutePoint?.longitude || attendance.punchInLongitude,
                        lastPositionUpdate: latestRoutePoint?.recordedAt || attendance.punchInTime,
                        lastPositionUpdateIST: latestRoutePoint
                            ? formatISTTime(latestRoutePoint.recordedAt, 'datetime')
                            : formatISTTime(attendance.punchInTime, 'datetime'),
                        // Travel metrics
                        currentDistanceKm: Math.round(currentDistance * 1000) / 1000,
                        totalRoutePoints: routePoints.length,
                        isMoving: latestRoutePoint &&
                            (Date.now() - latestRoutePoint.recordedAt.getTime()) < 120000, // Moved in last 2 minutes
                        speed: latestRoutePoint?.speed || 0
                    };
                } catch (error) {
                    console.error(`Error getting position for employee ${attendance.employeeId}:`, error);
                    return {
                        attendanceId: attendance.id,
                        employeeId: attendance.employeeId,
                        employeeName: attendance.employeeName,
                        punchInTime: attendance.punchInTime,
                        punchInTimeIST: formatISTTime(attendance.punchInTime, 'datetime'),
                        currentWorkHours: getCurrentWorkDurationIST(attendance.punchInTime),
                        currentLatitude: attendance.punchInLatitude,
                        currentLongitude: attendance.punchInLongitude,
                        lastPositionUpdate: attendance.punchInTime,
                        lastPositionUpdateIST: formatISTTime(attendance.punchInTime, 'datetime'),
                        currentDistanceKm: 0,
                        totalRoutePoints: 0,
                        isMoving: false,
                        speed: 0,
                        error: 'Failed to load route data'
                    };
                }
            })
        );

        res.status(200).json({
            success: true,
            data: {
                activeEmployees: employeePositions.length,
                positions: employeePositions,
                lastUpdated: new Date().toISOString(),
                lastUpdatedIST: formatISTTime(convertISTToUTC(getCurrentISTTime()), 'datetime')
            }
        });
    } catch (error) {
        console.error('Get current positions error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch current positions',
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
    getCurrentPositions,
    getEmployeeAttendanceReport
};
