import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Request late punch-in approval
router.post('/request', async (req, res) => {
    try {
        const { employeeId, employeeName, requestTime } = req.body;

        if (!employeeId || !employeeName) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID and name are required'
            });
        }

        // Check if there's already a pending request for today
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const existingRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId: employeeId,
                requestDate: {
                    gte: today,
                    lt: tomorrow
                },
                status: {
                    in: ['PENDING', 'APPROVED']
                }
            }
        });

        if (existingRequest) {
            if (existingRequest.status === 'APPROVED') {
                return res.json({
                    success: true,
                    message: 'Request already approved',
                    data: existingRequest
                });
            } else {
                return res.json({
                    success: true,
                    message: 'Request already submitted and pending approval',
                    data: existingRequest
                });
            }
        }

        // Create new approval request
        const approvalRequest = await prisma.latePunchApproval.create({
            data: {
                employeeId,
                employeeName,
                requestDate: new Date(),
                requestTime: requestTime || new Date().toISOString(),
                status: 'PENDING',
                reason: 'Late punch-in request'
            }
        });

        res.json({
            success: true,
            message: 'Late punch-in approval request submitted successfully',
            data: approvalRequest
        });

    } catch (error) {
        console.error('Error requesting late punch approval:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to submit approval request'
        });
    }
});

// Check approval status
router.get('/status/:employeeId', async (req, res) => {
    try {
        const { employeeId } = req.params;

        // Check for today's approval
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const approval = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId: employeeId,
                requestDate: {
                    gte: today,
                    lt: tomorrow
                },
                status: 'APPROVED'
            }
        });

        res.json({
            success: true,
            data: {
                hasApproval: !!approval,
                approval: approval
            }
        });

    } catch (error) {
        console.error('Error checking approval status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to check approval status'
        });
    }
});

// Admin: Get pending requests
router.get('/pending', async (req, res) => {
    try {
        const pendingRequests = await prisma.latePunchApproval.findMany({
            where: {
                status: 'PENDING'
            },
            orderBy: {
                requestDate: 'desc'
            }
        });

        res.json({
            success: true,
            data: pendingRequests
        });

    } catch (error) {
        console.error('Error fetching pending requests:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending requests'
        });
    }
});

// Admin: Approve/Reject request
router.post('/admin/action', async (req, res) => {
    try {
        const { requestId, action, adminId, adminName } = req.body;

        if (!requestId || !action || !['APPROVED', 'REJECTED'].includes(action)) {
            return res.status(400).json({
                success: false,
                message: 'Valid request ID and action (APPROVED/REJECTED) are required'
            });
        }

        const updatedRequest = await prisma.latePunchApproval.update({
            where: { id: requestId },
            data: {
                status: action,
                approvedBy: adminId,
                approvedByName: adminName,
                approvedAt: new Date()
            }
        });

        res.json({
            success: true,
            message: `Request ${action.toLowerCase()} successfully`,
            data: updatedRequest
        });

    } catch (error) {
        console.error('Error updating approval request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update approval request'
        });
    }
});

export default router;