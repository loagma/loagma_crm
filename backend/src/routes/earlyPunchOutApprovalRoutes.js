import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Request early punch-out approval
router.post('/request', async (req, res) => {
    try {
        const { employeeId, employeeName, attendanceId, requestTime } = req.body;

        if (!employeeId || !employeeName || !attendanceId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID, name, and attendance ID are required'
            });
        }

        // Check if there's already a pending request for this attendance
        const existingRequest = await prisma.earlyPunchOutApproval.findFirst({
            where: {
                attendanceId: attendanceId,
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
        const approvalRequest = await prisma.earlyPunchOutApproval.create({
            data: {
                employeeId,
                employeeName,
                attendanceId,
                requestDate: new Date(),
                requestTime: requestTime || new Date().toISOString(),
                status: 'PENDING',
                reason: 'Early punch-out request'
            }
        });

        res.json({
            success: true,
            message: 'Early punch-out approval request submitted successfully',
            data: approvalRequest
        });

    } catch (error) {
        console.error('Error requesting early punch-out approval:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to submit approval request'
        });
    }
});

// Check approval status
router.get('/status/:attendanceId', async (req, res) => {
    try {
        const { attendanceId } = req.params;

        const approval = await prisma.earlyPunchOutApproval.findFirst({
            where: {
                attendanceId: parseInt(attendanceId),
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
        const pendingRequests = await prisma.earlyPunchOutApproval.findMany({
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

        const updatedRequest = await prisma.earlyPunchOutApproval.update({
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