import NotificationService from '../services/notificationService.js';

// Get notifications for current user
export const getNotifications = async (req, res) => {
    try {
        const { userId, role } = req.user || {}; // Assuming user info is in req.user from auth middleware
        const {
            unreadOnly = false,
            limit = 50,
            offset = 0,
            type
        } = req.query;

        // If no user info, try to get from query params (for admin)
        const targetUserId = req.query.userId || userId;
        const targetRole = req.query.role || role;

        const notifications = await NotificationService.getNotifications({
            userId: targetUserId,
            role: targetRole,
            unreadOnly: unreadOnly === 'true',
            limit: parseInt(limit),
            offset: parseInt(offset)
        });

        // Filter by type if specified
        const filteredNotifications = type
            ? notifications.filter(n => n.type === type)
            : notifications;

        res.status(200).json({
            success: true,
            data: filteredNotifications,
            pagination: {
                limit: parseInt(limit),
                offset: parseInt(offset),
                total: filteredNotifications.length
            }
        });
    } catch (error) {
        console.error('❌ Get notifications error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch notifications',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Get notification counts
export const getNotificationCounts = async (req, res) => {
    try {
        const { userId, role } = req.user || {};

        // If no user info, try to get from query params (for admin)
        const targetUserId = req.query.userId || userId;
        const targetRole = req.query.role || role;

        const counts = await NotificationService.getNotificationCounts({
            userId: targetUserId,
            role: targetRole
        });

        res.status(200).json({
            success: true,
            data: counts
        });
    } catch (error) {
        console.error('❌ Get notification counts error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch notification counts',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Mark notification as read
export const markNotificationAsRead = async (req, res) => {
    try {
        const { notificationId } = req.params;
        const { userId } = req.user || {};

        if (!notificationId) {
            return res.status(400).json({
                success: false,
                message: 'Notification ID is required'
            });
        }

        const notification = await NotificationService.markAsRead(notificationId, userId);

        res.status(200).json({
            success: true,
            message: 'Notification marked as read',
            data: notification
        });
    } catch (error) {
        console.error('❌ Mark notification as read error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark notification as read',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Mark all notifications as read
export const markAllNotificationsAsRead = async (req, res) => {
    try {
        const { userId, role } = req.user || {};

        // If no user info, try to get from query params (for admin)
        const targetUserId = req.query.userId || userId;
        const targetRole = req.query.role || role;

        const result = await NotificationService.markAllAsRead({
            userId: targetUserId,
            role: targetRole
        });

        res.status(200).json({
            success: true,
            message: `Marked ${result.count} notifications as read`,
            data: result
        });
    } catch (error) {
        console.error('❌ Mark all notifications as read error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark all notifications as read',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Create notification (Admin only)
export const createNotification = async (req, res) => {
    try {
        const {
            title,
            message,
            type = 'general',
            priority = 'normal',
            targetRole,
            targetUserId,
            data
        } = req.body;

        if (!title || !message) {
            return res.status(400).json({
                success: false,
                message: 'Title and message are required'
            });
        }

        const notification = await NotificationService.createNotification({
            title,
            message,
            type,
            priority,
            targetRole,
            targetUserId,
            data
        });

        res.status(201).json({
            success: true,
            message: 'Notification created successfully',
            data: notification
        });
    } catch (error) {
        console.error('❌ Create notification error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create notification',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Test notification with current time (for debugging)
export const createTestNotification = async (req, res) => {
    try {
        const currentTime = new Date();
        const timeString = currentTime.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });
        const dateTimeString = currentTime.toLocaleString('en-IN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        });

        const testAttendanceData = {
            id: 'test-attendance-id',
            employeeId: 'test-employee-id',
            employeeName: 'Test Employee',
            punchInTime: currentTime,
            punchOutTime: new Date(currentTime.getTime() + 2 * 60 * 60 * 1000), // 2 hours later
            totalWorkHours: 2.0,
            totalDistanceKm: 5.5,
            punchInLatitude: 28.6139,
            punchInLongitude: 77.2090,
            punchInAddress: 'Test Location, Delhi',
            punchOutLatitude: 28.6200,
            punchOutLongitude: 77.2150,
            punchOutAddress: 'Test End Location, Delhi'
        };

        // Create both punch-in and punch-out test notifications
        const punchInNotification = await NotificationService.createPunchInNotification(testAttendanceData);
        const punchOutNotification = await NotificationService.createPunchOutNotification(testAttendanceData);

        res.status(201).json({
            success: true,
            message: 'Test notifications created successfully',
            data: {
                currentTime: dateTimeString,
                timeString: timeString,
                punchInNotification,
                punchOutNotification
            }
        });
    } catch (error) {
        console.error('❌ Create test notification error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create test notification',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Get admin dashboard notifications (recent punch-in/punch-out activities)
export const getAdminDashboardNotifications = async (req, res) => {
    try {
        const { limit = 20, type } = req.query;

        const notifications = await NotificationService.getNotifications({
            role: 'admin',
            unreadOnly: false,
            limit: parseInt(limit),
            offset: 0
        });

        // Filter by type if specified (punch_in, punch_out)
        const filteredNotifications = type
            ? notifications.filter(n => n.type === type)
            : notifications;

        // Get counts for different types
        const punchInCount = notifications.filter(n => n.type === 'punch_in' && !n.isRead).length;
        const punchOutCount = notifications.filter(n => n.type === 'punch_out' && !n.isRead).length;
        const totalUnread = notifications.filter(n => !n.isRead).length;

        res.status(200).json({
            success: true,
            data: {
                notifications: filteredNotifications,
                counts: {
                    punchIn: punchInCount,
                    punchOut: punchOutCount,
                    totalUnread,
                    total: notifications.length
                }
            }
        });
    } catch (error) {
        console.error('❌ Get admin dashboard notifications error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch admin dashboard notifications',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

export default {
    getNotifications,
    getNotificationCounts,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    createNotification,
    getAdminDashboardNotifications,
    createTestNotification
};