import express from 'express';
import prisma from '../config/db.js';

const router = express.Router();


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

// Check approval status - returns any existing request for today (PENDING, APPROVED, or REJECTED)
router.get('/status/:employeeId', async (req, res) => {
    try {
        const { employeeId } = req.params;

        // Check for today's approval request
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
                }
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
                    approvalCode: approval.approvalCode, // Include the actual code for display
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
        const pendingRequests = await prisma.latePunchApproval.findMany({
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

        // Generate 6-digit approval code
        const approvalCode = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Code expires in 2 hours
        const codeExpiresAt = new Date();
        codeExpiresAt.setHours(codeExpiresAt.getHours() + 2);

        const updatedRequest = await prisma.latePunchApproval.update({
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

        console.log(`✅ Late punch approval approved. Code: ${approvalCode} for employee: ${existingRequest.employeeName}`);

        res.json({
            success: true,
            message: `Late punch-in request approved. Approval code: ${approvalCode}`,
            data: {
                ...updatedRequest,
                approvalCode: approvalCode
            }
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

// Validate Approval Code for Punch-In
router.post('/validate-code', async (req, res) => {
    try {
        const { employeeId, approvalCode } = req.body;

        if (!employeeId || !approvalCode) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID and approval code are required'
            });
        }

        // Get today's date range
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        // Find the approval request
        const approvalRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId,
                approvalCode: approvalCode.trim(),
                status: 'APPROVED',
                requestDate: {
                    gte: today,
                    lt: tomorrow
                }
            }
        });

        if (!approvalRequest) {
            return res.status(400).json({
                success: false,
                message: 'Invalid approval code or no approved request found for today'
            });
        }

        // Check if code is already used
        if (approvalRequest.codeUsed) {
            return res.status(400).json({
                success: false,
                message: 'Approval code has already been used'
            });
        }

        // Check if code is expired
        if (approvalRequest.codeExpiresAt && new Date() > approvalRequest.codeExpiresAt) {
            return res.status(400).json({
                success: false,
                message: 'Approval code has expired. Please request a new approval.'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Approval code is valid. You can now punch in.',
            data: {
                requestId: approvalRequest.id,
                approvalCode: approvalRequest.approvalCode,
                expiresAt: approvalRequest.codeExpiresAt
            }
        });
    } catch (error) {
        console.error('Error validating approval code:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to validate approval code'
        });
    }
});

export default router;