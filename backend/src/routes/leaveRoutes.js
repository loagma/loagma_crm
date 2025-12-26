import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { roleGuard } from '../middleware/roleGuard.js';
import * as leaveController from '../controllers/leaveController.js';

const router = express.Router();

// Employee routes (Salesman can apply for leave, view their leaves, cancel pending leaves)
router.post('/', authMiddleware, leaveController.applyLeave);
router.get('/my', authMiddleware, leaveController.getMyLeaves);
router.get('/balance', authMiddleware, leaveController.getLeaveBalance);
router.patch('/:id/cancel', authMiddleware, leaveController.cancelLeave);

// Admin routes (Admin can view all leaves, approve/reject leaves)
router.get('/all', authMiddleware, roleGuard(['ADMIN', 'NSM', 'RSM', 'ASM']), leaveController.getAllLeaves);
router.get('/pending', authMiddleware, roleGuard(['ADMIN', 'NSM', 'RSM', 'ASM']), leaveController.getPendingLeaves);
router.patch('/:id/approve', authMiddleware, roleGuard(['ADMIN', 'NSM', 'RSM', 'ASM']), leaveController.approveLeave);
router.patch('/:id/reject', authMiddleware, roleGuard(['ADMIN', 'NSM', 'RSM', 'ASM']), leaveController.rejectLeave);

export default router;