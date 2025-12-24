// TEMPORARY FIX for production database missing isHomeLocation column
// This version of getCurrentPositions works without the isHomeLocation column

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

// FIXED VERSION: Get Current Positions of Active Employees (Admin - Live Tracking)
// This version works without the isHomeLocation column
export const getCurrentPositionsFixed = async (req, res) => {
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
                    // Get the most recent route point (WITHOUT isHomeLocation filter)
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
                            recordedAt: true,
                            speed: true
                        }
                    });

                    // Calculate current travel distance
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
                lastUpdatedIST: formatISTTime(convertISTToUTC(getCurrentISTTime()), 'datetime'),
                note: 'Using fixed version without isHomeLocation column'
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