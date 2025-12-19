import express from 'express';
import {
    getNotifications,
    getNotificationCounts,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    createNotification,
    getAdminDashboardNotifications,
    createTestNotification
} from '../controllers/notificationController.js';

const router = express.Router();

// Get notifications for current user
router.get('/', getNotifications);

// Get notification counts
router.get('/counts', getNotificationCounts);

// Get admin dashboard notifications (recent activities)
router.get('/admin/dashboard', getAdminDashboardNotifications);

// Mark specific notification as read
router.patch('/:notificationId/read', markNotificationAsRead);

// Mark all notifications as read
router.patch('/mark-all-read', markAllNotificationsAsRead);

// Create notification (Admin only)
router.post('/', createNotification);

// Create test notification (for debugging)
router.post('/test', createTestNotification);

export default router;