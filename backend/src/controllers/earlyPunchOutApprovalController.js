import prisma from '../config/db.js';
import {
    getCurrentISTTime,
    getISTDateRange,
    formatISTTime
} from '../utils/timezone.js';
import NotificationService from '../services/notificationService.js';



// Request Early Punch-Out Approval
export const requestEarlyPunchOutApproval = async (req, res) => {
    try {
        const { employeeId, employeeName, attendanceId, reason } = req.body;

        // Validate required fields
        if (!employeeId || !employeeName || !attendanceId || !reason) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: employeeId, employeeName, attendanceId, reason'
            });
        }

        // Validate reason length
        if (reason.trim().length < 10) {
            return res.status(400).json({
                success: false,
                message: 'Reason must be at least 10 characters long'
            });
        }

        // Verify attendance session exists and is active
        const attendance = await prisma.attendance.findUnique({
            where: { id: attendanceId }
        });

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance session not found'
            });
        }

        if (attendance.employeeId !== employeeId) {
            return res.status(403).json({
                success: false,
                message: 'Attendance session does not belong to this employee'
            });
        }

        if (attendance.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'Attendance session is not active'
            });
        }

        // Get current IST time and date range for today
        const currentIST = getCurrentISTTime();
        const { startOfDay, endOfDay } = getISTDateRange();

        // Check if there's already a pending request for today
        const existingRequest = await prisma.earlyPunchOutApproval.findFirst({
            where: {
                employeeId,
                attendanceId,
                status: 'PENDING',
                requestDate: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            }
        });

        if (existingRequest) {
            return res.status(400).json({
                success: false,
                message: 'You already have a pending early punch-out request for this session'
            });
        }

        // Create approval request
        const approvalRequest = await prisma.earlyPunchOutApproval.create({
            data: {
                employeeId,
                employeeName,
                attendanceId,
                punchOutDate: currentIST,
                reason: reason.trim(),
                status: 'PENDING'
            },
            include: {
                employee: {
                    select: {
                        name: true,
                        contactNumber: true,
                        employeeCode: true
                    }
                }
            }
        });

        // Send notification to admin
        try {
            await NotificationService.createEarlyPunchOutApprovalNotification(approvalRequest);
            console.log('✅ Early punch-out approval notification sent to admin');
        } catch (notificationError) {
            console.error('❌ Failed to send notification:', notificationError);
            // Don't fail the request if notification fails
        }

        console.log('✅ Early punch-out approval request created:', {
            id: approvalRequest.id,
            employeeId,
            attendanceId,
            reason: reason.substring(0, 50) + '...'
        });

        res.status(201).json({
            success: true,
            message: 'Early punch-out approval request submitted successfully. Please wait for admin approval.',
            data: {
                id: approvalRequest.id,
                status: approvalRequest.status,
                requestDate: approvalRequest.requestDate,
                reason: approvalRequest.reason
            }
        });

    } catch (error) {
        console.error('❌ Error creating early punch-out approval request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to submit approval request'
        });
    }
};

// Get Employee's Early Punch-Out Approval Status
export const getEmployeeEarlyPunchOutStatus = async (req, res) => {
    try {
        const { employeeId } = req.params;
        const { attendanceId } = req.query;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Get current IST date range
        const { startOfDay, endOfDay } = getISTDateRange();

        let whereClause = {
            employeeId,
            requestDate: {
                gte: startOfDay,
                lt: endOfDay
            }
        };

        // If attendanceId is provided, filter by it
        if (attendanceId) {
            whereClause.attendanceId = attendanceId;
        }

        // Get today's approval request
        const approvalRequest = await prisma.earlyPunchOutApproval.findFirst({
            where: whereClause,
            orderBy: { createdAt: 'desc' },
            include: {
                approver: {
                    select: {
                        name: true
                    }
                }
            }
        });

        if (!approvalRequest) {
            return res.status(200).json({
                success: true,
                message: 'No early punch-out approval request found for today',
                data: null
            });
        }

        const responseData = {
            id: approvalRequest.id,
            status: approvalRequest.status,
            reason: approvalRequest.reason,
            requestDate: approvalRequest.requestDate,
            approvedBy: approvalRequest.approver?.name,
            approvedAt: approvalRequest.approvedAt,
            adminRemarks: approvalRequest.adminRemarks
        };

        res.status(200).json({
            success: true,
            data: responseData,
            message: `Early punch-out request status: ${approvalRequest.status}`
        });

    } catch (error) {
        console.error('❌ Error fetching early punch-out approval status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch approval status'
        });
    }
};

// Admin: Get Pending Early Punch-Out Approval Requests
export const getPendingEarlyPunchOutRequests = async (req, res) => {
    try {
        const { page = 1, limit = 20, date } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        let dateFilter = {};
        if (date) {
            const targetDate = new Date(date);
            const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
            const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));
            dateFilter = {
                requestDate: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            };
        }

        const where = {
            status: 'PENDING',
            ...dateFilter
        };

        const [requests, total] = await Promise.all([
            prisma.earlyPunchOutApproval.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip,
                take: parseInt(limit),
                include: {
                    employee: {
                        select: {
                            name: true,
                            contactNumber: true,
                            employeeCode: true
                        }
                    }
                }
            }),
            prisma.earlyPunchOutApproval.count({ where })
        ]);

        res.status(200).json({
            success: true,
            data: requests,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            }
        });

    } catch (error) {
        console.error('❌ Error fetching pending early punch-out requests:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending requests'
        });
    }
};

// Admin: Approve Early Punch-Out Request
export const approveEarlyPunchOutRequest = async (req, res) => {
    try {
        const { requestId } = req.params;
        const { adminId, adminRemarks } = req.body;

        if (!adminId) {
            return res.status(400).json({
                success: false,
                message: 'Admin ID is required'
            });
        }

        // Get the approval request
        const approvalRequest = await prisma.earlyPunchOutApproval.findUnique({
            where: { id: requestId },
            include: {
                employee: {
                    select: {
                        name: true,
                        contactNumber: true
                    }
                }
            }
        });

        if (!approvalRequest) {
            return res.status(404).json({
                success: false,
                message: 'Approval request not found'
            });
        }

        if (approvalRequest.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: 'Request has already been processed'
            });
        }

        // Update approval request
        const currentIST = getCurrentISTTime();
        const updatedRequest = await prisma.earlyPunchOutApproval.update({
            where: { id: requestId },
            data: {
                status: 'APPROVED',
                approvedBy: adminId,
                approvedAt: currentIST,
                adminRemarks: adminRemarks?.trim() || null
            },
            include: {
                employee: {
                    select: {
                        name: true,
                        contactNumber: true
                    }
                },
                approver: {
                    select: {
                        name: true
                    }
                }
            }
        });

        // Send notification to employee
        try {
            await NotificationService.createEarlyPunchOutApprovalResponseNotification(
                updatedRequest,
                'APPROVED'
            );
            console.log('✅ Early punch-out approval notification sent to employee');
        } catch (notificationError) {
            console.error('❌ Failed to send notification:', notificationError);
        }

        console.log('✅ Early punch-out request approved:', {
            requestId,
            employeeId: updatedRequest.employeeId
        });

        res.status(200).json({
            success: true,
            message: 'Early punch-out request approved successfully',
            data: {
                id: updatedRequest.id,
                status: updatedRequest.status,
                adminRemarks: updatedRequest.adminRemarks,
                approvedBy: updatedRequest.approver?.name,
                approvedAt: updatedRequest.approvedAt
            }
        });

    } catch (error) {
        console.error('❌ Error approving early punch-out request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve request'
        });
    }
};

// Admin: Reject Early Punch-Out Request
export const rejectEarlyPunchOutRequest = async (req, res) => {
    try {
        const { requestId } = req.params;
        const { adminId, adminRemarks } = req.body;

        if (!adminId || !adminRemarks) {
            return res.status(400).json({
                success: false,
                message: 'Admin ID and remarks are required for rejection'
            });
        }

        // Get the approval request
        const approvalRequest = await prisma.earlyPunchOutApproval.findUnique({
            where: { id: requestId },
            include: {
                employee: {
                    select: {
                        name: true,
                        contactNumber: true
                    }
                }
            }
        });

        if (!approvalRequest) {
            return res.status(404).json({
                success: false,
                message: 'Approval request not found'
            });
        }

        if (approvalRequest.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: 'Request has already been processed'
            });
        }

        // Update approval request
        const currentIST = getCurrentISTTime();
        const updatedRequest = await prisma.earlyPunchOutApproval.update({
            where: { id: requestId },
            data: {
                status: 'REJECTED',
                approvedBy: adminId,
                approvedAt: currentIST,
                adminRemarks: adminRemarks.trim()
            },
            include: {
                employee: {
                    select: {
                        name: true,
                        contactNumber: true
                    }
                },
                approver: {
                    select: {
                        name: true
                    }
                }
            }
        });

        // Send notification to employee
        try {
            await NotificationService.createEarlyPunchOutApprovalResponseNotification(
                updatedRequest,
                'REJECTED'
            );
            console.log('✅ Early punch-out rejection notification sent to employee');
        } catch (notificationError) {
            console.error('❌ Failed to send notification:', notificationError);
        }

        console.log('✅ Early punch-out request rejected:', {
            requestId,
            employeeId: updatedRequest.employeeId,
            adminRemarks
        });

        res.status(200).json({
            success: true,
            message: 'Early punch-out request rejected successfully',
            data: {
                id: updatedRequest.id,
                status: updatedRequest.status,
                adminRemarks: updatedRequest.adminRemarks,
                approvedBy: updatedRequest.approver?.name,
                approvedAt: updatedRequest.approvedAt
            }
        });

    } catch (error) {
        console.error('❌ Error rejecting early punch-out request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject request'
        });
    }
};

// Admin: Get All Early Punch-Out Approval Requests (with filters)
export const getAllEarlyPunchOutRequests = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            employeeId,
            startDate,
            endDate
        } = req.query;

        const skip = (parseInt(page) - 1) * parseInt(limit);

        let where = {};

        // Status filter
        if (status) {
            where.status = status;
        }

        // Employee filter
        if (employeeId) {
            where.employeeId = employeeId;
        }

        // Date range filter
        if (startDate || endDate) {
            where.requestDate = {};
            if (startDate) where.requestDate.gte = new Date(startDate);
            if (endDate) {
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                where.requestDate.lte = end;
            }
        }

        const [requests, total] = await Promise.all([
            prisma.earlyPunchOutApproval.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip,
                take: parseInt(limit),
                include: {
                    employee: {
                        select: {
                            name: true,
                            contactNumber: true,
                            employeeCode: true
                        }
                    },
                    approver: {
                        select: {
                            name: true
                        }
                    }
                }
            }),
            prisma.earlyPunchOutApproval.count({ where })
        ]);

        res.status(200).json({
            success: true,
            data: requests,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            },
            filters: {
                status,
                employeeId,
                startDate,
                endDate
            }
        });

    } catch (error) {
        console.error('❌ Error fetching all early punch-out requests:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch approval requests'
        });
    }
};

export default {
    requestEarlyPunchOutApproval,
    getEmployeeEarlyPunchOutStatus,
    validateEarlyPunchOutCode,
    getPendingEarlyPunchOutRequests,
    approveEarlyPunchOutRequest,
    rejectEarlyPunchOutRequest,
    getAllEarlyPunchOutRequests
};