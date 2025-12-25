import { PrismaClient } from '@prisma/client';
import { formatISTTime } from '../utils/timezone.js';

const prisma = new PrismaClient();

class NotificationService {
    /**
     * Create a new notification
     * @param {Object} notificationData - Notification data
     * @param {string} notificationData.title - Notification title
     * @param {string} notificationData.message - Notification message
     * @param {string} notificationData.type - Notification type (punch_in, punch_out, general, alert)
     * @param {string} [notificationData.priority] - Priority level (low, normal, high, urgent)
     * @param {string} [notificationData.targetRole] - Target role (admin, salesman, etc.)
     * @param {string} [notificationData.targetUserId] - Specific target user ID
     * @param {Object} [notificationData.data] - Additional data
     */
    static async createNotification({
        title,
        message,
        type,
        priority = 'normal',
        targetRole = null,
        targetUserId = null,
        data = null
    }) {
        try {
            const notification = await prisma.notification.create({
                data: {
                    title,
                    message,
                    type,
                    priority,
                    targetRole,
                    targetUserId,
                    data: data ? JSON.stringify(data) : null
                }
            });

            console.log('✅ Notification created:', {
                id: notification.id,
                title: notification.title,
                type: notification.type,
                targetRole: notification.targetRole,
                targetUserId: notification.targetUserId
            });

            return notification;
        } catch (error) {
            console.error('❌ Error creating notification:', error);
            throw error;
        }
    }

    /**
     * Create punch-in notification
     * @param {Object} attendanceData - Attendance data
     */
    static async createPunchInNotification(attendanceData) {
        // Since punchInTime is already stored in IST, use formatISTTime for consistent formatting
        const punchInTime = new Date(attendanceData.punchInTime);
        const timeString = formatISTTime(punchInTime, 'time');
        const dateTimeString = formatISTTime(punchInTime, 'datetime');

        const title = 'Salesman Punched In';
        const message = `${attendanceData.employeeName} punched in at ${timeString}`;

        return await this.createNotification({
            title,
            message,
            type: 'punch_in',
            priority: 'normal',
            targetRole: 'admin',
            data: {
                employeeId: attendanceData.employeeId,
                employeeName: attendanceData.employeeName,
                attendanceId: attendanceData.id,
                punchInTime: attendanceData.punchInTime,
                punchInTimeIST: dateTimeString,
                punchInTimeFormatted: timeString,
                location: {
                    latitude: attendanceData.punchInLatitude,
                    longitude: attendanceData.punchInLongitude,
                    address: attendanceData.punchInAddress
                }
            }
        });
    }

    /**
     * Create punch-out notification
     * @param {Object} attendanceData - Attendance data
     */
    static async createPunchOutNotification(attendanceData) {
        // Since both times are already stored in IST, use formatISTTime for consistent formatting
        const punchInTime = new Date(attendanceData.punchInTime);
        const punchOutTime = new Date(attendanceData.punchOutTime);

        const punchInTimeString = formatISTTime(punchInTime, 'time');
        const punchOutTimeString = formatISTTime(punchOutTime, 'time');
        const punchInDateTimeString = formatISTTime(punchInTime, 'datetime');
        const punchOutDateTimeString = formatISTTime(punchOutTime, 'datetime');

        const workHours = attendanceData.totalWorkHours || 0;
        const workDurationFormatted = `${Math.floor(workHours)}h ${Math.round((workHours % 1) * 60)}m`;

        const title = 'Salesman Punched Out';
        const message = `${attendanceData.employeeName} punched out at ${punchOutTimeString} after working ${workDurationFormatted}`;

        return await this.createNotification({
            title,
            message,
            type: 'punch_out',
            priority: 'normal',
            targetRole: 'admin',
            data: {
                employeeId: attendanceData.employeeId,
                employeeName: attendanceData.employeeName,
                attendanceId: attendanceData.id,
                punchInTime: attendanceData.punchInTime,
                punchOutTime: attendanceData.punchOutTime,
                punchInTimeIST: punchInDateTimeString,
                punchOutTimeIST: punchOutDateTimeString,
                punchInTimeFormatted: punchInTimeString,
                punchOutTimeFormatted: punchOutTimeString,
                totalWorkHours: attendanceData.totalWorkHours,
                workDurationFormatted,
                totalDistanceKm: attendanceData.totalDistanceKm,
                location: {
                    punchIn: {
                        latitude: attendanceData.punchInLatitude,
                        longitude: attendanceData.punchInLongitude,
                        address: attendanceData.punchInAddress
                    },
                    punchOut: {
                        latitude: attendanceData.punchOutLatitude,
                        longitude: attendanceData.punchOutLongitude,
                        address: attendanceData.punchOutAddress
                    }
                }
            }
        });
    }

    /**
     * Create late punch-in approval request notification (to admin)
     * @param {Object} approvalData - Approval request data
     */
    static async createLatePunchApprovalNotification(approvalData) {
        // Use the punchInDate which is the actual time the user wants to punch in
        const requestTime = new Date(approvalData.createdAt);
        
        // Format time in IST using formatISTTime utility
        const timeString = formatISTTime(requestTime, 'time');
        const dateTimeString = formatISTTime(requestTime, 'datetime');

        const title = 'Late Punch-In Approval Request';
        const message = `${approvalData.employeeName} requested approval for late punch-in at ${timeString}`;

        return await this.createNotification({
            title,
            message,
            type: 'late_punch_approval',
            priority: 'high',
            targetRole: 'admin',
            data: {
                requestId: approvalData.id,
                employeeId: approvalData.employeeId,
                employeeName: approvalData.employeeName,
                reason: approvalData.reason,
                requestTime: approvalData.createdAt,
                requestTimeFormatted: timeString,
                requestTimeIST: dateTimeString,
                status: approvalData.status,
                actionRequired: true
            }
        });
    }

    /**
     * Create late punch-in approval granted notification (to employee)
     * @param {Object} approvalData - Approval request data
     * @param {string} approvalCode - Generated approval code
     */
    static async createLatePunchApprovedNotification(approvalData, approvalCode) {
        const approvedTime = new Date(approvalData.approvedAt);
        const timeString = approvedTime.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });

        const expiryTime = new Date(approvalData.codeExpiresAt);
        const expiryTimeString = expiryTime.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });

        const title = 'Late Punch-In Approved';
        const message = `Your late punch-in request has been approved. Use code: ${approvalCode} (expires at ${expiryTimeString})`;

        return await this.createNotification({
            title,
            message,
            type: 'late_punch_approval',
            priority: 'high',
            targetUserId: approvalData.employeeId,
            data: {
                requestId: approvalData.id,
                approvalCode: approvalCode,
                approvedBy: approvalData.approver?.name,
                approvedAt: approvalData.approvedAt,
                approvedTimeFormatted: timeString,
                codeExpiresAt: approvalData.codeExpiresAt,
                codeExpiresAtFormatted: expiryTimeString,
                adminRemarks: approvalData.adminRemarks,
                status: 'APPROVED',
                actionRequired: true
            }
        });
    }

    /**
     * Create late punch-in rejection notification (to employee)
     * @param {Object} approvalData - Approval request data
     */
    static async createLatePunchRejectedNotification(approvalData) {
        const rejectedTime = new Date(approvalData.approvedAt);
        const timeString = rejectedTime.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });

        const title = 'Late Punch-In Request Rejected';
        const message = `Your late punch-in request has been rejected at ${timeString}`;

        return await this.createNotification({
            title,
            message,
            type: 'late_punch_approval',
            priority: 'normal',
            targetUserId: approvalData.employeeId,
            data: {
                requestId: approvalData.id,
                rejectedBy: approvalData.approver?.name,
                rejectedAt: approvalData.approvedAt,
                rejectedTimeFormatted: timeString,
                adminRemarks: approvalData.adminRemarks,
                reason: approvalData.reason,
                status: 'REJECTED'
            }
        });
    }

    /**
     * Create early punch-out approval request notification (to admin)
     * @param {Object} approvalData - Approval request data
     */
    static async createEarlyPunchOutApprovalNotification(approvalData) {
        const requestTime = new Date(approvalData.createdAt);
        
        // Format time in IST using formatISTTime utility
        const timeString = formatISTTime(requestTime, 'time');
        const dateTimeString = formatISTTime(requestTime, 'datetime');

        const title = 'Early Punch-Out Approval Request';
        const message = `${approvalData.employeeName} requested approval for early punch-out at ${timeString}`;

        return await this.createNotification({
            title,
            message,
            type: 'early_punch_out_approval',
            priority: 'high',
            targetRole: 'admin',
            data: {
                requestId: approvalData.id,
                employeeId: approvalData.employeeId,
                employeeName: approvalData.employeeName,
                attendanceId: approvalData.attendanceId,
                reason: approvalData.reason,
                requestTime: approvalData.createdAt,
                requestTimeFormatted: timeString,
                requestTimeIST: dateTimeString,
                status: approvalData.status,
                actionRequired: true
            }
        });
    }

    /**
     * Create early punch-out approval response notification (to employee)
     * @param {Object} approvalData - Updated approval request data
     * @param {string} decision - 'APPROVED' or 'REJECTED'
     */
    static async createEarlyPunchOutApprovalResponseNotification(approvalData, decision) {
        const isApproved = decision === 'APPROVED';
        const responseTime = new Date(approvalData.approvedAt);
        const timeString = responseTime.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });

        let title, message;
        if (isApproved) {
            const expiryTime = new Date(approvalData.codeExpiresAt);
            const expiryTimeString = expiryTime.toLocaleTimeString('en-IN', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            });

            title = 'Early Punch-Out Approved';
            message = `Your early punch-out request has been approved. Code: ${approvalData.approvalCode} (expires at ${expiryTimeString})`;
        } else {
            title = 'Early Punch-Out Request Rejected';
            message = `Your early punch-out request has been rejected at ${timeString}`;
        }

        return await this.createNotification({
            title,
            message,
            type: 'early_punch_out_approval',
            priority: isApproved ? 'high' : 'normal',
            targetUserId: approvalData.employeeId,
            data: {
                requestId: approvalData.id,
                attendanceId: approvalData.attendanceId,
                status: decision,
                approvalCode: isApproved ? approvalData.approvalCode : null,
                approvedBy: approvalData.approver?.name,
                approvedAt: approvalData.approvedAt,
                approvedTimeFormatted: timeString,
                codeExpiresAt: isApproved ? approvalData.codeExpiresAt : null,
                codeExpiresAtFormatted: isApproved ? expiryTimeString : null,
                adminRemarks: approvalData.adminRemarks,
                reason: approvalData.reason,
                actionRequired: isApproved
            }
        });
    }

    /**
     * Get notifications for a specific user or role
     * @param {Object} filters - Filter options
     * @param {string} [filters.userId] - User ID
     * @param {string} [filters.role] - User role
     * @param {boolean} [filters.unreadOnly] - Get only unread notifications
     * @param {number} [filters.limit] - Limit number of results
     * @param {number} [filters.offset] - Offset for pagination
     * @param {Date} [filters.startDate] - Start date for filtering
     * @param {Date} [filters.endDate] - End date for filtering
     */
    static async getNotifications({
        userId = null,
        role = null,
        unreadOnly = false,
        limit = 50,
        offset = 0,
        startDate = null,
        endDate = null
    }) {
        try {
            const where = {
                OR: []
            };

            // Add conditions for user-specific or role-based notifications
            if (userId) {
                where.OR.push({ targetUserId: userId });
            }

            if (role) {
                where.OR.push({ targetRole: role });
            }

            // Add condition for global notifications (no specific target)
            where.OR.push({
                AND: [
                    { targetUserId: null },
                    { targetRole: null }
                ]
            });

            // Filter for unread only
            if (unreadOnly) {
                where.isRead = false;
            }

            // Date range filtering
            if (startDate || endDate) {
                where.createdAt = {};
                if (startDate) {
                    where.createdAt.gte = startDate;
                }
                if (endDate) {
                    where.createdAt.lte = endDate;
                }
            }

            const notifications = await prisma.notification.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip: offset,
                include: {
                    targetUser: {
                        select: {
                            id: true,
                            name: true,
                            employeeCode: true
                        }
                    }
                }
            });

            // Parse JSON data field
            const enhancedNotifications = notifications.map(notification => ({
                ...notification,
                data: notification.data ? JSON.parse(notification.data) : null,
                createdAtIST: formatISTTime(notification.createdAt, 'datetime'),
                readAtIST: notification.readAt ? formatISTTime(notification.readAt, 'datetime') : null
            }));

            return enhancedNotifications;
        } catch (error) {
            console.error('❌ Error fetching notifications:', error);
            throw error;
        }
    }

    /**
     * Get notification count with filters (for pagination)
     * @param {Object} filters - Filter options
     * @param {string} [filters.userId] - User ID
     * @param {string} [filters.role] - User role
     * @param {Date} [filters.startDate] - Start date for filtering
     * @param {Date} [filters.endDate] - End date for filtering
     */
    static async getNotificationCountWithFilters({
        userId = null,
        role = null,
        startDate = null,
        endDate = null
    }) {
        try {
            const where = {
                OR: []
            };

            if (userId) {
                where.OR.push({ targetUserId: userId });
            }

            if (role) {
                where.OR.push({ targetRole: role });
            }

            // Include global notifications
            where.OR.push({
                AND: [
                    { targetUserId: null },
                    { targetRole: null }
                ]
            });

            // Date range filtering
            if (startDate || endDate) {
                where.createdAt = {};
                if (startDate) {
                    where.createdAt.gte = startDate;
                }
                if (endDate) {
                    where.createdAt.lte = endDate;
                }
            }

            const count = await prisma.notification.count({ where });
            return count;
        } catch (error) {
            console.error('❌ Error getting notification count:', error);
            throw error;
        }
    }

    /**
     * Mark notification as read
     * @param {string} notificationId - Notification ID
     * @param {string} [userId] - User ID (for verification)
     */
    static async markAsRead(notificationId, userId = null) {
        try {
            const where = { id: notificationId };

            // If userId provided, ensure user can only mark their own notifications
            if (userId) {
                where.OR = [
                    { targetUserId: userId },
                    { targetUserId: null } // Global notifications
                ];
            }

            const notification = await prisma.notification.update({
                where,
                data: {
                    isRead: true,
                    readAt: new Date()
                }
            });

            return notification;
        } catch (error) {
            console.error('❌ Error marking notification as read:', error);
            throw error;
        }
    }

    /**
     * Mark all notifications as read for a user/role
     * @param {Object} filters - Filter options
     * @param {string} [filters.userId] - User ID
     * @param {string} [filters.role] - User role
     */
    static async markAllAsRead({ userId = null, role = null }) {
        try {
            const where = {
                isRead: false,
                OR: []
            };

            if (userId) {
                where.OR.push({ targetUserId: userId });
            }

            if (role) {
                where.OR.push({ targetRole: role });
            }

            // Include global notifications
            where.OR.push({
                AND: [
                    { targetUserId: null },
                    { targetRole: null }
                ]
            });

            const result = await prisma.notification.updateMany({
                where,
                data: {
                    isRead: true,
                    readAt: new Date()
                }
            });

            return result;
        } catch (error) {
            console.error('❌ Error marking all notifications as read:', error);
            throw error;
        }
    }

    /**
     * Get notification counts
     * @param {Object} filters - Filter options
     * @param {string} [filters.userId] - User ID
     * @param {string} [filters.role] - User role
     */
    static async getNotificationCounts({ userId = null, role = null }) {
        try {
            const where = {
                OR: []
            };

            if (userId) {
                where.OR.push({ targetUserId: userId });
            }

            if (role) {
                where.OR.push({ targetRole: role });
            }

            // Include global notifications
            where.OR.push({
                AND: [
                    { targetUserId: null },
                    { targetRole: null }
                ]
            });

            const [total, unread] = await Promise.all([
                prisma.notification.count({ where }),
                prisma.notification.count({
                    where: { ...where, isRead: false }
                })
            ]);

            return { total, unread, read: total - unread };
        } catch (error) {
            console.error('❌ Error getting notification counts:', error);
            throw error;
        }
    }

    /**
     * Delete old notifications (cleanup)
     * @param {number} daysOld - Delete notifications older than this many days
     */
    static async cleanupOldNotifications(daysOld = 30) {
        try {
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - daysOld);

            const result = await prisma.notification.deleteMany({
                where: {
                    createdAt: {
                        lt: cutoffDate
                    },
                    isRead: true // Only delete read notifications
                }
            });

            console.log(`🧹 Cleaned up ${result.count} old notifications`);
            return result;
        } catch (error) {
            console.error('❌ Error cleaning up notifications:', error);
            throw error;
        }
    }
}

export default NotificationService;