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
                punchInDate: new Date(), // Add the missing required field
                reason: 'Late punch-in request',
                status: 'PENDING'
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

// Admin: Approve/Reject request (legacy endpoint)
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

// Admin: Approve late punch-in request
router.post('/approve/:requestId', async (req, res) => {
    try {
        const { requestId } = req.params;
        const { adminId, adminRemarks } = req.body;

        if (!requestId) {
            return res.status(400).json({
                success: false,
                message: 'Request ID is required'
            });
        }

        // Check if request exists
        const existingRequest = await prisma.latePunchApproval.findUnique({
            where: { id: requestId }
        });

        if (!existingRequest) {
            return res.status(404).json({
                success: false,
                message: 'Approval request not found'
            });
        }

        if (existingRequest.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Request is already ${existingRequest.status.toLowerCase()}`
            });
        }

        const updatedRequest = await prisma.latePunchApproval.update({
            where: { id: requestId },
            data: {
                status: 'APPROVED',
                approvedBy: adminId,
                adminRemarks: adminRemarks || 'Approved',
                approvedAt: new Date()
            }
        });

        res.json({
            success: true,
            message: 'Late punch-in request approved successfully',
            data: updatedRequest
        });

    } catch (error) {
        console.error('Error approving late punch request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve request'
        });
    }
});

// Admin: Reject late punch-in request
router.post('/reject/:requestId', async (req, res) => {
    try {
        const { requestId } = req.params;
        const { adminId, adminRemarks } = req.body;

        if (!requestId) {
            return res.status(400).json({
                success: false,
                message: 'Request ID is required'
            });
        }

        // Check if request exists
        const existingRequest = await prisma.latePunchApproval.findUnique({
            where: { id: requestId }
        });

        if (!existingRequest) {
            return res.status(404).json({
                success: false,
                message: 'Approval request not found'
            });
        }

        if (existingRequest.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Request is already ${existingRequest.status.toLowerCase()}`
            });
        }

        const updatedRequest = await prisma.latePunchApproval.update({
            where: { id: requestId },
            data: {
                status: 'REJECTED',
                approvedBy: adminId,
                adminRemarks: adminRemarks || 'Rejected',
                approvedAt: new Date()
            }
        });

        res.json({
            success: true,
            message: 'Late punch-in request rejected',
            data: updatedRequest
        });

    } catch (error) {
        console.error('Error rejecting late punch request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject request'
        });
    }
});

export default router;