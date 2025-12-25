import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Request early punch-out approval
router.post('/request', async (req, res) => {
    try {
        const { employeeId, employeeName, attendanceId, reason, requestTime } = req.body;

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
                punchOutDate: new Date(),
                reason: reason || 'Early punch-out request',
                status: 'PENDING'
            }
        });

        console.log(`✅ Early punch-out approval request created for: ${employeeName}`);

        res.status(201).json({
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

// Check approval status - returns any existing request (PENDING, APPROVED, or REJECTED)
router.get('/status/:attendanceId', async (req, res) => {
    try {
        const { attendanceId } = req.params;

        // Find the most recent approval request for this attendance
        const approval = await prisma.earlyPunchOutApproval.findFirst({
            where: {
                attendanceId: attendanceId
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        if (approval) {
            // Check if code is expired
            const isCodeExpired = approval.codeExpiresAt ? new Date() > approval.codeExpiresAt : false;
            
            res.json({
                success: true,
                data: {
                    hasApproval: approval.status === 'APPROVED',
                    status: approval.status,
                    reason: approval.reason,
                    requestTime: approval.requestDate,
                    approvedBy: approval.approvedBy,
                    approvedAt: approval.approvedAt,
                    adminRemarks: approval.adminRemarks,
                    // OTP related fields
                    hasApprovalCode: !!approval.approvalCode,
                    approvalCode: approval.approvalCode,
                    codeExpired: isCodeExpired,
                    codeExpiresAt: approval.codeExpiresAt,
                    codeUsed: approval.codeUsed || false,
                    codeUsedAt: approval.codeUsedAt,
                    approval: approval
                }
            });
        } else {
            res.json({
                success: true,
                data: null
            });
        }

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
            },
            include: {
                employee: {
                    select: {
                        id: true,
                        name: true,
                        employeeCode: true,
                        contactNumber: true,
                        department: {
                            select: { name: true }
                        }
                    }
                }
            }
        });

        res.json({
            success: true,
            data: pendingRequests,
            pagination: {
                total: pendingRequests.length
            }
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

// Admin: Approve early punch-out request
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
        const existingRequest = await prisma.earlyPunchOutApproval.findUnique({
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

        // Generate 6-digit approval code
        const approvalCode = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Code expires in 2 hours
        const codeExpiresAt = new Date();
        codeExpiresAt.setHours(codeExpiresAt.getHours() + 2);

        const updatedRequest = await prisma.earlyPunchOutApproval.update({
            where: { id: requestId },
            data: {
                status: 'APPROVED',
                approvedBy: adminId,
                adminRemarks: adminRemarks || 'Approved',
                approvedAt: new Date(),
                approvalCode: approvalCode,
                codeExpiresAt: codeExpiresAt,
                codeUsed: false
            }
        });

        console.log(`✅ Early punch-out approval approved. Code: ${approvalCode} for employee: ${existingRequest.employeeName}`);

        res.json({
            success: true,
            message: `Early punch-out request approved. Approval code: ${approvalCode}`,
            data: {
                ...updatedRequest,
                approvalCode: approvalCode
            }
        });

    } catch (error) {
        console.error('Error approving early punch-out request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve request'
        });
    }
});

// Admin: Reject early punch-out request
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
        const existingRequest = await prisma.earlyPunchOutApproval.findUnique({
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

        const updatedRequest = await prisma.earlyPunchOutApproval.update({
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
            message: 'Early punch-out request rejected',
            data: updatedRequest
        });

    } catch (error) {
        console.error('Error rejecting early punch-out request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject request'
        });
    }
});

export default router;