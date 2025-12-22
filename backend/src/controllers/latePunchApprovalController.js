import { PrismaClient } from '@prisma/client';
import {
    getCurrentISTTime,
    formatISTTime,
    getISTDateRange
} from '../utils/timezone.js';
import NotificationService from '../services/notificationService.js';
import crypto from 'crypto';

const prisma = new PrismaClient();

// Helper function to generate approval code
function generateApprovalCode() {
    return crypto.randomInt(100000, 999999).toString(); // 6-digit code
}

// Helper function to check if current time is after 9:45 AM
function isAfterCutoffTime() {
    const currentIST = getCurrentISTTime();
    const cutoffTime = new Date(currentIST);
    cutoffTime.setHours(9, 45, 0, 0); // 9:45 AM

    return currentIST > cutoffTime;
}

// Request Late Punch-In Approval
export const requestLatePunchApproval = async (req, res) => {
    try {
        const { employeeId, employeeName, reason } = req.body;

        // Validation
        if (!employeeId || !employeeName || !reason) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: employeeId, employeeName, reason'
            });
        }

        if (reason.trim().length < 10) {
            return res.status(400).json({
                success: false,
                message: 'Reason must be at least 10 characters long'
            });
        }

        // Check if it's actually after cutoff time
        if (!isAfterCutoffTime()) {
            return res.status(400).json({
                success: false,
                message: 'Punch-in is still allowed. No approval needed before 9:45 AM.'
            });
        }

        // Get today's date range
        const { startOfDay, endOfDay } = getISTDateRange();

        // Check if employee already has an active attendance today
        const existingAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId,
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
                },
                status: 'active'
            }
        });

        if (existingAttendance) {
            return res.status(400).json({
                success: false,
                message: 'You already have an active attendance session today.'
            });
        }

        // Check if there's already a pending request for today
        const existingRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId,
                requestDate: {
                    gte: startOfDay,
                    lt: endOfDay
                },
                status: 'PENDING'
            }
        });

        if (existingRequest) {
            return res.status(400).json({
                success: false,
                message: 'You already have a pending approval request for today.',
                data: {
                    requestId: existingRequest.id,
                    requestTime: formatISTTime(existingRequest.createdAt, 'datetime'),
                    reason: existingRequest.reason
                }
            });
        }

        // Create approval request
        const currentIST = getCurrentISTTime();
        const approvalRequest = await prisma.latePunchApproval.create({
            data: {
                employeeId,
                employeeName,
                requestDate: currentIST,
                punchInDate: currentIST,
                reason: reason.trim(),
                status: 'PENDING'
            }
        });

        console.log('✅ Late punch approval request created:', {
            id: approvalRequest.id,
            employeeId: approvalRequest.employeeId,
            employeeName: approvalRequest.employeeName,
            reason: approvalRequest.reason
        });

        // Send notification to admin
        try {
            await NotificationService.createLatePunchApprovalNotification(approvalRequest);
            console.log('✅ Late punch approval notification sent to admin');
        } catch (notificationError) {
            console.error('⚠️ Failed to send late punch approval notification:', notificationError);
            // Don't fail the request if notification fails
        }

        res.status(201).json({
            success: true,
            message: 'Late punch-in approval request submitted successfully. Please wait for admin approval.',
            data: {
                requestId: approvalRequest.id,
                status: approvalRequest.status,
                requestTime: formatISTTime(approvalRequest.createdAt, 'datetime'),
                reason: approvalRequest.reason
            }
        });
    } catch (error) {
        console.error('❌ Request late punch approval error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to submit approval request. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Get Pending Approval Requests (Admin)
export const getPendingApprovalRequests = async (req, res) => {
    try {
        const { page = 1, limit = 20, date } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        let dateFilter = {};
        if (date) {
            const targetDate = new Date(date);
            const { startOfDay, endOfDay } = getISTDateRange(targetDate);
            dateFilter = {
                requestDate: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            };
        }

        const where = {
            status: 'PENDING',
            ...dateFilter
        };

        const [requests, total] = await Promise.all([
            prisma.latePunchApproval.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip,
                take: parseInt(limit),
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
            }),
            prisma.latePunchApproval.count({ where })
        ]);

        // Enhance requests with IST formatting
        const enhancedRequests = requests.map(request => ({
            ...request,
            requestTimeIST: formatISTTime(request.createdAt, 'datetime'),
            punchInDateIST: formatISTTime(request.punchInDate, 'datetime'),
            timeAgo: getTimeAgo(request.createdAt)
        }));

        res.status(200).json({
            success: true,
            data: enhancedRequests,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            }
        });
    } catch (error) {
        console.error('❌ Get pending approval requests error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending approval requests',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Approve Late Punch-In Request (Admin)
export const approveLatePunchRequest = async (req, res) => {
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
        const approvalRequest = await prisma.latePunchApproval.findUnique({
            where: { id: requestId },
            include: {
                employee: {
                    select: {
                        id: true,
                        name: true,
                        employeeCode: true
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
                message: `Request is already ${approvalRequest.status.toLowerCase()}`
            });
        }

        // Generate approval code and set expiry (valid for 2 hours)
        const approvalCode = generateApprovalCode();
        const currentIST = getCurrentISTTime();
        const codeExpiresAt = new Date(currentIST.getTime() + 2 * 60 * 60 * 1000); // 2 hours from now

        // Update approval request
        const updatedRequest = await prisma.latePunchApproval.update({
            where: { id: requestId },
            data: {
                status: 'APPROVED',
                approvedBy: adminId,
                approvedAt: currentIST,
                adminRemarks: adminRemarks?.trim() || null,
                approvalCode,
                codeExpiresAt
            },
            include: {
                employee: {
                    select: {
                        id: true,
                        name: true,
                        employeeCode: true
                    }
                },
                approver: {
                    select: {
                        id: true,
                        name: true
                    }
                }
            }
        });

        console.log('✅ Late punch approval request approved:', {
            requestId: updatedRequest.id,
            employeeName: updatedRequest.employeeName,
            approvalCode: approvalCode,
            approvedBy: updatedRequest.approver?.name
        });

        // Send approval notification to employee
        try {
            await NotificationService.createLatePunchApprovedNotification(updatedRequest, approvalCode);
            console.log('✅ Late punch approval notification sent to employee');
        } catch (notificationError) {
            console.error('⚠️ Failed to send approval notification:', notificationError);
            // Don't fail the approval if notification fails
        }

        res.status(200).json({
            success: true,
            message: `Late punch-in request approved. Approval code sent to ${updatedRequest.employeeName}.`,
            data: {
                requestId: updatedRequest.id,
                status: updatedRequest.status,
                approvalCode: approvalCode, // Include in response for admin reference
                codeExpiresAt: formatISTTime(updatedRequest.codeExpiresAt, 'datetime'),
                approvedBy: updatedRequest.approver?.name,
                approvedAt: formatISTTime(updatedRequest.approvedAt, 'datetime'),
                adminRemarks: updatedRequest.adminRemarks
            }
        });
    } catch (error) {
        console.error('❌ Approve late punch request error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve request. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Reject Late Punch-In Request (Admin)
export const rejectLatePunchRequest = async (req, res) => {
    try {
        const { requestId } = req.params;
        const { adminId, adminRemarks } = req.body;

        if (!adminId) {
            return res.status(400).json({
                success: false,
                message: 'Admin ID is required'
            });
        }

        if (!adminRemarks || adminRemarks.trim().length < 5) {
            return res.status(400).json({
                success: false,
                message: 'Rejection reason is required (minimum 5 characters)'
            });
        }

        // Get the approval request
        const approvalRequest = await prisma.latePunchApproval.findUnique({
            where: { id: requestId },
            include: {
                employee: {
                    select: {
                        id: true,
                        name: true,
                        employeeCode: true
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
                message: `Request is already ${approvalRequest.status.toLowerCase()}`
            });
        }

        // Update approval request
        const currentIST = getCurrentISTTime();
        const updatedRequest = await prisma.latePunchApproval.update({
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
                        id: true,
                        name: true,
                        employeeCode: true
                    }
                },
                approver: {
                    select: {
                        id: true,
                        name: true
                    }
                }
            }
        });

        console.log('✅ Late punch approval request rejected:', {
            requestId: updatedRequest.id,
            employeeName: updatedRequest.employeeName,
            rejectedBy: updatedRequest.approver?.name,
            reason: updatedRequest.adminRemarks
        });

        // Send rejection notification to employee
        try {
            await NotificationService.createLatePunchRejectedNotification(updatedRequest);
            console.log('✅ Late punch rejection notification sent to employee');
        } catch (notificationError) {
            console.error('⚠️ Failed to send rejection notification:', notificationError);
            // Don't fail the rejection if notification fails
        }

        res.status(200).json({
            success: true,
            message: `Late punch-in request rejected. Notification sent to ${updatedRequest.employeeName}.`,
            data: {
                requestId: updatedRequest.id,
                status: updatedRequest.status,
                rejectedBy: updatedRequest.approver?.name,
                rejectedAt: formatISTTime(updatedRequest.approvedAt, 'datetime'),
                adminRemarks: updatedRequest.adminRemarks
            }
        });
    } catch (error) {
        console.error('❌ Reject late punch request error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject request. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Get Employee's Approval Request Status
export const getEmployeeApprovalStatus = async (req, res) => {
    try {
        const { employeeId } = req.params;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Get today's date range
        const { startOfDay, endOfDay } = getISTDateRange();

        // Get today's approval request
        const approvalRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId,
                requestDate: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            },
            orderBy: { createdAt: 'desc' },
            include: {
                approver: {
                    select: {
                        id: true,
                        name: true
                    }
                }
            }
        });

        if (!approvalRequest) {
            return res.status(200).json({
                success: true,
                data: null,
                message: 'No approval request found for today'
            });
        }

        // Check if code is expired for approved requests
        let isCodeExpired = false;
        if (approvalRequest.status === 'APPROVED' && approvalRequest.codeExpiresAt) {
            isCodeExpired = getCurrentISTTime() > approvalRequest.codeExpiresAt;
        }

        const responseData = {
            requestId: approvalRequest.id,
            status: approvalRequest.status,
            reason: approvalRequest.reason,
            requestTime: formatISTTime(approvalRequest.createdAt, 'datetime'),
            approvedBy: approvalRequest.approver?.name,
            approvedAt: approvalRequest.approvedAt ? formatISTTime(approvalRequest.approvedAt, 'datetime') : null,
            adminRemarks: approvalRequest.adminRemarks,
            hasApprovalCode: !!approvalRequest.approvalCode,
            codeExpired: isCodeExpired,
            codeExpiresAt: approvalRequest.codeExpiresAt ? formatISTTime(approvalRequest.codeExpiresAt, 'datetime') : null,
            codeUsed: approvalRequest.codeUsed,
            codeUsedAt: approvalRequest.codeUsedAt ? formatISTTime(approvalRequest.codeUsedAt, 'datetime') : null
        };

        res.status(200).json({
            success: true,
            data: responseData
        });
    } catch (error) {
        console.error('❌ Get employee approval status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch approval status',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Validate Approval Code for Punch-In
export const validateApprovalCode = async (req, res) => {
    try {
        const { employeeId, approvalCode } = req.body;

        if (!employeeId || !approvalCode) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID and approval code are required'
            });
        }

        // Get today's date range
        const { startOfDay, endOfDay } = getISTDateRange();

        // Find the approval request
        const approvalRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId,
                approvalCode: approvalCode.trim(),
                status: 'APPROVED',
                requestDate: {
                    gte: startOfDay,
                    lt: endOfDay
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
        const currentIST = getCurrentISTTime();
        if (approvalRequest.codeExpiresAt && currentIST > approvalRequest.codeExpiresAt) {
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
                expiresAt: formatISTTime(approvalRequest.codeExpiresAt, 'datetime')
            }
        });
    } catch (error) {
        console.error('❌ Validate approval code error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to validate approval code',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Get All Approval Requests (Admin - with filters)
export const getAllApprovalRequests = async (req, res) => {
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
        const where = {};

        // Status filter
        if (status && ['PENDING', 'APPROVED', 'REJECTED'].includes(status.toUpperCase())) {
            where.status = status.toUpperCase();
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
            prisma.latePunchApproval.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip,
                take: parseInt(limit),
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
                    },
                    approver: {
                        select: {
                            id: true,
                            name: true
                        }
                    }
                }
            }),
            prisma.latePunchApproval.count({ where })
        ]);

        // Enhance requests with IST formatting
        const enhancedRequests = requests.map(request => ({
            ...request,
            requestTimeIST: formatISTTime(request.createdAt, 'datetime'),
            punchInDateIST: formatISTTime(request.punchInDate, 'datetime'),
            approvedAtIST: request.approvedAt ? formatISTTime(request.approvedAt, 'datetime') : null,
            codeExpiresAtIST: request.codeExpiresAt ? formatISTTime(request.codeExpiresAt, 'datetime') : null,
            codeUsedAtIST: request.codeUsedAt ? formatISTTime(request.codeUsedAt, 'datetime') : null,
            timeAgo: getTimeAgo(request.createdAt),
            isCodeExpired: request.codeExpiresAt ? getCurrentISTTime() > request.codeExpiresAt : false
        }));

        res.status(200).json({
            success: true,
            data: enhancedRequests,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / parseInt(limit))
            },
            filters: {
                status: status || 'all',
                employeeId: employeeId || 'all',
                startDate: startDate || null,
                endDate: endDate || null
            }
        });
    } catch (error) {
        console.error('❌ Get all approval requests error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch approval requests',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
        });
    }
};

// Helper function to get time ago
function getTimeAgo(dateTime) {
    const now = getCurrentISTTime();
    const diff = now.getTime() - dateTime.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days > 0) return `${days} day${days > 1 ? 's' : ''} ago`;
    if (hours > 0) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    if (minutes > 0) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    return 'Just now';
}

export default {
    requestLatePunchApproval,
    getPendingApprovalRequests,
    approveLatePunchRequest,
    rejectLatePunchRequest,
    getEmployeeApprovalStatus,
    validateApprovalCode,
    getAllApprovalRequests
};