import prisma from '../config/db.js';
import LeaveService from '../services/leaveService.js';
import NotificationService from '../services/notificationService.js';

// Apply for leave (Salesman)
export const applyLeave = async (req, res) => {
    try {
        const { leaveType, startDate, endDate, reason } = req.body;
        const employeeId = req.user?.id;

        if (!employeeId) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated'
            });
        }

        // Validation
        if (!leaveType || !startDate || !endDate) {
            return res.status(400).json({
                success: false,
                message: 'Leave type, start date, and end date are required'
            });
        }

        const start = new Date(startDate);
        const end = new Date(endDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Validate dates
        if (start > end) {
            return res.status(400).json({
                success: false,
                message: 'Start date cannot be after end date'
            });
        }

        if (start < today) {
            return res.status(400).json({
                success: false,
                message: 'Cannot apply for leave on past dates'
            });
        }

        // Calculate working days
        const numberOfDays = LeaveService.calculateWorkingDays(start, end);

        if (numberOfDays <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Leave must be for at least one working day'
            });
        }

        // Check for overlapping leaves
        const hasOverlap = await LeaveService.checkOverlappingLeaves(employeeId, start, end);
        if (hasOverlap) {
            return res.status(400).json({
                success: false,
                message: 'You already have a leave request for overlapping dates'
            });
        }

        // Validate leave balance (except for unpaid/emergency leaves)
        const balanceValidation = await LeaveService.validateLeaveBalance(employeeId, leaveType, numberOfDays);
        if (!balanceValidation.isValid) {
            return res.status(400).json({
                success: false,
                message: balanceValidation.message,
                data: {
                    availableLeaves: balanceValidation.availableLeaves,
                    requestedDays: balanceValidation.requestedDays
                }
            });
        }

        // Get employee details
        const employee = await prisma.user.findUnique({
            where: { id: employeeId },
            select: { id: true, name: true, email: true, contactNumber: true }
        });

        // Create leave request
        const leave = await prisma.leave.create({
            data: {
                employeeId,
                employeeName: employee.name || 'Unknown',
                leaveType,
                startDate: start,
                endDate: end,
                numberOfDays,
                reason: reason || null,
                status: 'PENDING'
            },
            include: {
                employee: {
                    select: { id: true, name: true, email: true }
                }
            }
        });

        // Create notification for admin
        await NotificationService.createLeaveRequestNotification(leave);

        res.status(201).json({
            success: true,
            message: 'Leave request submitted successfully',
            data: leave
        });

    } catch (error) {
        console.error('❌ Apply Leave Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to submit leave request',
            error: error.message
        });
    }
};

// Get my leaves (Salesman)
export const getMyLeaves = async (req, res) => {
    try {
        const employeeId = req.user?.id;
        const { status, page = 1, limit = 10 } = req.query;

        if (!employeeId) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated'
            });
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);

        const whereClause = { employeeId };
        if (status && status !== 'ALL') {
            whereClause.status = status;
        }

        const [leaves, totalCount] = await Promise.all([
            prisma.leave.findMany({
                where: whereClause,
                orderBy: { requestedAt: 'desc' },
                skip,
                take: parseInt(limit),
                include: {
                    approver: {
                        select: { id: true, name: true }
                    }
                }
            }),
            prisma.leave.count({ where: whereClause })
        ]);

        // Get leave statistics
        const statistics = await LeaveService.getLeaveStatistics(employeeId);

        res.json({
            success: true,
            message: 'Leaves retrieved successfully',
            data: {
                leaves,
                pagination: {
                    currentPage: parseInt(page),
                    totalPages: Math.ceil(totalCount / parseInt(limit)),
                    totalCount,
                    hasNext: skip + leaves.length < totalCount,
                    hasPrev: parseInt(page) > 1
                },
                statistics
            }
        });

    } catch (error) {
        console.error('❌ Get My Leaves Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve leaves',
            error: error.message
        });
    }
};

// Get all leaves (Admin)
export const getAllLeaves = async (req, res) => {
    try {
        const { status, employeeId, page = 1, limit = 20, leaveType } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const whereClause = {};
        if (status && status !== 'ALL') {
            whereClause.status = status;
        }
        if (employeeId) {
            whereClause.employeeId = employeeId;
        }
        if (leaveType && leaveType !== 'ALL') {
            whereClause.leaveType = leaveType;
        }

        const [leaves, totalCount] = await Promise.all([
            prisma.leave.findMany({
                where: whereClause,
                orderBy: { requestedAt: 'desc' },
                skip,
                take: parseInt(limit),
                include: {
                    employee: {
                        select: { id: true, name: true, email: true, contactNumber: true }
                    },
                    approver: {
                        select: { id: true, name: true }
                    }
                }
            }),
            prisma.leave.count({ where: whereClause })
        ]);

        res.json({
            success: true,
            message: 'All leaves retrieved successfully',
            data: {
                leaves,
                pagination: {
                    currentPage: parseInt(page),
                    totalPages: Math.ceil(totalCount / parseInt(limit)),
                    totalCount,
                    hasNext: skip + leaves.length < totalCount,
                    hasPrev: parseInt(page) > 1
                }
            }
        });

    } catch (error) {
        console.error('❌ Get All Leaves Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve leaves',
            error: error.message
        });
    }
};

// Get pending leaves (Admin)
export const getPendingLeaves = async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [leaves, totalCount] = await Promise.all([
            prisma.leave.findMany({
                where: { status: 'PENDING' },
                orderBy: { requestedAt: 'asc' }, // Oldest first for admin review
                skip,
                take: parseInt(limit),
                include: {
                    employee: {
                        select: { id: true, name: true, email: true, contactNumber: true }
                    }
                }
            }),
            prisma.leave.count({ where: { status: 'PENDING' } })
        ]);

        res.json({
            success: true,
            message: 'Pending leaves retrieved successfully',
            data: {
                leaves,
                pagination: {
                    currentPage: parseInt(page),
                    totalPages: Math.ceil(totalCount / parseInt(limit)),
                    totalCount,
                    hasNext: skip + leaves.length < totalCount,
                    hasPrev: parseInt(page) > 1
                }
            }
        });

    } catch (error) {
        console.error('❌ Get Pending Leaves Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve pending leaves',
            error: error.message
        });
    }
};

// Approve leave (Admin)
export const approveLeave = async (req, res) => {
    try {
        const { id } = req.params;
        const { adminRemarks } = req.body;
        const adminId = req.user?.id;

        if (!adminId) {
            return res.status(401).json({
                success: false,
                message: 'Admin not authenticated'
            });
        }

        // Find the leave request
        const leave = await prisma.leave.findUnique({
            where: { id },
            include: {
                employee: {
                    select: { id: true, name: true, email: true }
                }
            }
        });

        if (!leave) {
            return res.status(404).json({
                success: false,
                message: 'Leave request not found'
            });
        }

        if (leave.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Leave request is already ${leave.status.toLowerCase()}`
            });
        }

        // Update leave balance
        await LeaveService.updateLeaveBalance(
            leave.employeeId,
            leave.leaveType,
            leave.numberOfDays,
            'deduct'
        );

        // Update leave request
        const updatedLeave = await prisma.leave.update({
            where: { id },
            data: {
                status: 'APPROVED',
                approvedBy: adminId,
                approvedAt: new Date(),
                adminRemarks: adminRemarks || null
            },
            include: {
                employee: {
                    select: { id: true, name: true, email: true }
                },
                approver: {
                    select: { id: true, name: true }
                }
            }
        });

        // Create notification for employee
        await NotificationService.createLeaveApprovedNotification(updatedLeave);

        res.json({
            success: true,
            message: 'Leave request approved successfully',
            data: updatedLeave
        });

    } catch (error) {
        console.error('❌ Approve Leave Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve leave request',
            error: error.message
        });
    }
};

// Reject leave (Admin)
export const rejectLeave = async (req, res) => {
    try {
        const { id } = req.params;
        const { rejectionReason, adminRemarks } = req.body;
        const adminId = req.user?.id;

        if (!adminId) {
            return res.status(401).json({
                success: false,
                message: 'Admin not authenticated'
            });
        }

        if (!rejectionReason) {
            return res.status(400).json({
                success: false,
                message: 'Rejection reason is required'
            });
        }

        // Find the leave request
        const leave = await prisma.leave.findUnique({
            where: { id },
            include: {
                employee: {
                    select: { id: true, name: true, email: true }
                }
            }
        });

        if (!leave) {
            return res.status(404).json({
                success: false,
                message: 'Leave request not found'
            });
        }

        if (leave.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Leave request is already ${leave.status.toLowerCase()}`
            });
        }

        // Update leave request
        const updatedLeave = await prisma.leave.update({
            where: { id },
            data: {
                status: 'REJECTED',
                approvedBy: adminId,
                approvedAt: new Date(),
                rejectionReason,
                adminRemarks: adminRemarks || null
            },
            include: {
                employee: {
                    select: { id: true, name: true, email: true }
                },
                approver: {
                    select: { id: true, name: true }
                }
            }
        });

        // Create notification for employee
        await NotificationService.createLeaveRejectedNotification(updatedLeave);

        res.json({
            success: true,
            message: 'Leave request rejected successfully',
            data: updatedLeave
        });

    } catch (error) {
        console.error('❌ Reject Leave Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject leave request',
            error: error.message
        });
    }
};

// Cancel leave (Employee - only pending leaves)
export const cancelLeave = async (req, res) => {
    try {
        const { id } = req.params;
        const employeeId = req.user?.id;

        if (!employeeId) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated'
            });
        }

        // Find the leave request
        const leave = await prisma.leave.findUnique({
            where: { id },
            include: {
                employee: {
                    select: { id: true, name: true }
                }
            }
        });

        if (!leave) {
            return res.status(404).json({
                success: false,
                message: 'Leave request not found'
            });
        }

        // Check if user owns this leave request
        if (leave.employeeId !== employeeId) {
            return res.status(403).json({
                success: false,
                message: 'You can only cancel your own leave requests'
            });
        }

        if (leave.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Cannot cancel ${leave.status.toLowerCase()} leave request`
            });
        }

        // Update leave request
        const updatedLeave = await prisma.leave.update({
            where: { id },
            data: {
                status: 'CANCELLED',
                updatedAt: new Date()
            },
            include: {
                employee: {
                    select: { id: true, name: true }
                }
            }
        });

        res.json({
            success: true,
            message: 'Leave request cancelled successfully',
            data: updatedLeave
        });

    } catch (error) {
        console.error('❌ Cancel Leave Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to cancel leave request',
            error: error.message
        });
    }
};

// Get leave balance (Employee)
export const getLeaveBalance = async (req, res) => {
    try {
        const employeeId = req.user?.id;
        const { year } = req.query;

        if (!employeeId) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated'
            });
        }

        const targetYear = year ? parseInt(year) : new Date().getFullYear();
        const statistics = await LeaveService.getLeaveStatistics(employeeId, targetYear);

        res.json({
            success: true,
            message: 'Leave balance retrieved successfully',
            data: statistics
        });

    } catch (error) {
        console.error('❌ Get Leave Balance Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve leave balance',
            error: error.message
        });
    }
};