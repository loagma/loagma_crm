/**
 * PUNCH STATUS CONTROLLER - Single Source of Truth for UI State
 * 
 * This controller implements a deterministic state machine for punch operations.
 * The UI should NEVER calculate time rules - it should only render based on this response.
 * 
 * STATE MACHINE:
 * ┌─────────────────────────────────────────────────────────────────────────────┐
 * │                           PUNCH STATE MACHINE                               │
 * ├─────────────────────────────────────────────────────────────────────────────┤
 * │  IDLE ──────────────────────────────────────────────────────────────────►   │
 * │    │                                                                        │
 * │    ├── [On Time] ──► CAN_PUNCH_IN ──► PUNCH_IN ──► SESSION_ACTIVE          │
 * │    │                                                                        │
 * │    └── [Late] ──► REQUIRES_LATE_APPROVAL ──► WAITING_APPROVAL              │
 * │                         │                                                   │
 * │                         ├── [Approved] ──► CAN_PUNCH_IN ──► SESSION_ACTIVE │
 * │                         └── [Rejected/Expired] ──► REQUIRES_LATE_APPROVAL  │
 * │                                                                             │
 * │  SESSION_ACTIVE ────────────────────────────────────────────────────────►   │
 * │    │                                                                        │
 * │    ├── [Normal Time] ──► CAN_PUNCH_OUT ──► PUNCH_OUT ──► SESSION_CLOSED   │
 * │    │                                                                        │
 * │    └── [Early] ──► REQUIRES_EARLY_APPROVAL ──► WAITING_APPROVAL            │
 * │                         │                                                   │
 * │                         ├── [Approved] ──► CAN_PUNCH_OUT ──► SESSION_CLOSED│
 * │                         └── [Rejected/Expired] ──► REQUIRES_EARLY_APPROVAL │
 * │                                                                             │
 * │  SESSION_CLOSED ──► Can start new cycle (IDLE)                             │
 * └─────────────────────────────────────────────────────────────────────────────┘
 */

import { PrismaClient } from '@prisma/client';
import {
    getCurrentISTTime,
    getISTDateRange,
    formatISTTime,
    convertUTCToIST
} from '../utils/timezone.js';

const prisma = new PrismaClient();

// Approval expiry duration in minutes
const APPROVAL_EXPIRY_MINUTES = 30;

/**
 * Helper: Check if a time is late for punch-in
 */
function isLatePunchIn(currentTime, workStartTime, graceMinutes) {
    const [startHour, startMinute] = workStartTime.split(':').map(Number);
    const cutoffTime = new Date(currentTime);
    cutoffTime.setHours(startHour, startMinute + graceMinutes, 0, 0);
    return currentTime > cutoffTime;
}

/**
 * Helper: Check if a time is early for punch-out
 */
function isEarlyPunchOut(currentTime, workEndTime, graceMinutes) {
    const [endHour, endMinute] = workEndTime.split(':').map(Number);
    const cutoffTime = new Date(currentTime);
    cutoffTime.setHours(endHour, endMinute - graceMinutes, 0, 0);
    return currentTime < cutoffTime;
}

/**
 * Helper: Check if approval request has expired
 */
function isApprovalExpired(approval) {
    if (!approval) return true;
    if (approval.status === 'EXPIRED' || approval.status === 'USED') return true;

    // Check expiresAt if set
    if (approval.codeExpiresAt) {
        return new Date() > new Date(approval.codeExpiresAt);
    }

    // Default: expire after APPROVAL_EXPIRY_MINUTES from creation
    const expiryTime = new Date(approval.createdAt);
    expiryTime.setMinutes(expiryTime.getMinutes() + APPROVAL_EXPIRY_MINUTES);
    return new Date() > expiryTime;
}

/**
 * Helper: Get employee working hours config
 */
async function getEmployeeWorkingHours(employeeId) {
    const employee = await prisma.user.findUnique({
        where: { id: employeeId },
        select: {
            name: true,
            workStartTime: true,
            workEndTime: true,
            latePunchInGraceMinutes: true,
            earlyPunchOutGraceMinutes: true
        }
    });

    if (!employee) return null;

    return {
        name: employee.name,
        workStartTime: employee.workStartTime || '09:00:00',
        workEndTime: employee.workEndTime || '18:00:00',
        startGraceMinutes: employee.latePunchInGraceMinutes || 45,
        endGraceMinutes: employee.earlyPunchOutGraceMinutes || 30
    };
}

/**
 * GET /punch/status - Single Source of Truth for UI
 * 
 * Returns the complete state needed for UI rendering.
 * UI should NEVER calculate time rules locally.
 */
export const getPunchStatus = async (req, res) => {
    try {
        const { employeeId } = req.params;

        if (!employeeId) {
            return res.status(400).json({
                success: false,
                message: 'Employee ID is required'
            });
        }

        // Get employee config
        const employeeConfig = await getEmployeeWorkingHours(employeeId);
        if (!employeeConfig) {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        const currentTime = getCurrentISTTime();
        const { startOfDay, endOfDay } = getISTDateRange();

        // 1. Check for active session (PUNCH_IN without PUNCH_OUT)
        const activeSession = await prisma.attendance.findFirst({
            where: {
                employeeId,
                status: 'active'
            },
            orderBy: { punchInTime: 'desc' }
        });

        // 2. Get today's completed sessions count
        const todaySessionsCount = await prisma.attendance.count({
            where: {
                employeeId,
                punchInTime: { gte: startOfDay, lt: endOfDay }
            }
        });

        // 3. Check for pending/approved late punch-in approval
        const latePunchApproval = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId,
                requestDate: { gte: startOfDay, lt: endOfDay },
                status: { in: ['PENDING', 'APPROVED'] },
                codeUsed: false
            },
            orderBy: { createdAt: 'desc' }
        });

        // 4. Check for pending/approved early punch-out approval (if session active)
        let earlyPunchOutApproval = null;
        if (activeSession) {
            earlyPunchOutApproval = await prisma.earlyPunchOutApproval.findFirst({
                where: {
                    employeeId,
                    attendanceId: activeSession.id,
                    status: { in: ['PENDING', 'APPROVED'] },
                    codeUsed: false
                },
                orderBy: { createdAt: 'desc' }
            });
        }

        // Build response state
        const response = {
            success: true,
            employeeId,
            employeeName: employeeConfig.name,
            serverTime: currentTime.toISOString(),
            serverTimeIST: formatISTTime(currentTime, 'datetime'),

            // Working hours config (for display only, not for calculation)
            workingHours: {
                startTime: employeeConfig.workStartTime,
                endTime: employeeConfig.workEndTime,
                startGraceMinutes: employeeConfig.startGraceMinutes,
                endGraceMinutes: employeeConfig.endGraceMinutes
            },

            // Session state
            activeSession: activeSession ? {
                id: activeSession.id,
                punchInTime: activeSession.punchInTime.toISOString(),
                punchInTimeIST: formatISTTime(convertUTCToIST(activeSession.punchInTime), 'datetime'),
                status: 'OPEN'
            } : null,

            todaySessionsCount,

            // Core UI state flags
            canPunchIn: false,
            canPunchOut: false,
            requiresApproval: false,
            approvalType: null,        // 'LATE_PUNCH_IN' | 'EARLY_PUNCH_OUT' | null
            approvalStatus: null,      // 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED' | null
            approvalId: null,

            // UI message
            message: '',
            uiState: 'IDLE'  // IDLE | CAN_PUNCH_IN | WAITING_APPROVAL | SESSION_ACTIVE | CAN_PUNCH_OUT
        };

        // CASE 1: Has active session - determine punch-out state
        if (activeSession) {
            response.uiState = 'SESSION_ACTIVE';

            const needsEarlyApproval = isEarlyPunchOut(
                currentTime,
                employeeConfig.workEndTime,
                employeeConfig.endGraceMinutes
            );

            if (needsEarlyApproval) {
                // Check if we have valid approval
                if (earlyPunchOutApproval && !isApprovalExpired(earlyPunchOutApproval)) {
                    if (earlyPunchOutApproval.status === 'APPROVED') {
                        response.canPunchOut = true;
                        response.approvalType = 'EARLY_PUNCH_OUT';
                        response.approvalStatus = 'APPROVED';
                        response.approvalId = earlyPunchOutApproval.id;
                        response.uiState = 'CAN_PUNCH_OUT';
                        response.message = 'Early punch-out approved. You can punch out now.';
                    } else if (earlyPunchOutApproval.status === 'PENDING') {
                        response.requiresApproval = true;
                        response.approvalType = 'EARLY_PUNCH_OUT';
                        response.approvalStatus = 'PENDING';
                        response.approvalId = earlyPunchOutApproval.id;
                        response.uiState = 'WAITING_APPROVAL';
                        response.message = 'Waiting for admin approval for early punch-out.';
                    }
                } else {
                    response.requiresApproval = true;
                    response.approvalType = 'EARLY_PUNCH_OUT';
                    response.approvalStatus = earlyPunchOutApproval ? 'EXPIRED' : null;
                    response.uiState = 'SESSION_ACTIVE';
                    response.message = 'Early punch-out requires admin approval.';
                }
            } else {
                // Normal punch-out time
                response.canPunchOut = true;
                response.uiState = 'CAN_PUNCH_OUT';
                response.message = 'You can punch out now.';
            }
        }

        // CASE 2: No active session - determine punch-in state
        else {
            const needsLateApproval = isLatePunchIn(
                currentTime,
                employeeConfig.workStartTime,
                employeeConfig.startGraceMinutes
            );

            if (needsLateApproval) {
                // Check if we have valid approval
                if (latePunchApproval && !isApprovalExpired(latePunchApproval)) {
                    if (latePunchApproval.status === 'APPROVED') {
                        response.canPunchIn = true;
                        response.approvalType = 'LATE_PUNCH_IN';
                        response.approvalStatus = 'APPROVED';
                        response.approvalId = latePunchApproval.id;
                        response.uiState = 'CAN_PUNCH_IN';
                        response.message = 'Late punch-in approved. You can punch in now.';
                    } else if (latePunchApproval.status === 'PENDING') {
                        response.requiresApproval = true;
                        response.approvalType = 'LATE_PUNCH_IN';
                        response.approvalStatus = 'PENDING';
                        response.approvalId = latePunchApproval.id;
                        response.uiState = 'WAITING_APPROVAL';
                        response.message = 'Waiting for admin approval for late punch-in.';
                    }
                } else {
                    response.requiresApproval = true;
                    response.approvalType = 'LATE_PUNCH_IN';
                    response.approvalStatus = latePunchApproval ? 'EXPIRED' : null;
                    response.uiState = 'IDLE';
                    response.message = 'Late punch-in requires admin approval.';
                }
            } else {
                // Normal punch-in time
                response.canPunchIn = true;
                response.uiState = 'CAN_PUNCH_IN';
                response.message = 'You can punch in now.';
            }
        }

        return res.status(200).json(response);

    } catch (error) {
        console.error('❌ Get punch status error:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to get punch status',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * POST /approval/request - Request approval for late punch-in or early punch-out
 */
export const requestApproval = async (req, res) => {
    try {
        const { employeeId, employeeName, type, reason, attendanceId } = req.body;

        // Validation
        if (!employeeId || !employeeName || !type || !reason) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: employeeId, employeeName, type, reason'
            });
        }

        if (!['LATE_PUNCH_IN', 'EARLY_PUNCH_OUT'].includes(type)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid approval type. Must be LATE_PUNCH_IN or EARLY_PUNCH_OUT'
            });
        }

        if (reason.trim().length < 10) {
            return res.status(400).json({
                success: false,
                message: 'Reason must be at least 10 characters long'
            });
        }

        const currentTime = getCurrentISTTime();
        const { startOfDay, endOfDay } = getISTDateRange();
        const expiresAt = new Date(currentTime);
        expiresAt.setMinutes(expiresAt.getMinutes() + APPROVAL_EXPIRY_MINUTES);

        if (type === 'LATE_PUNCH_IN') {
            // Check for existing pending request today
            const existingRequest = await prisma.latePunchApproval.findFirst({
                where: {
                    employeeId,
                    requestDate: { gte: startOfDay, lt: endOfDay },
                    status: 'PENDING'
                }
            });

            if (existingRequest) {
                return res.status(400).json({
                    success: false,
                    message: 'You already have a pending late punch-in request for today',
                    data: { requestId: existingRequest.id }
                });
            }

            // Check if already punched in today
            const activeSession = await prisma.attendance.findFirst({
                where: { employeeId, status: 'active' }
            });

            if (activeSession) {
                return res.status(400).json({
                    success: false,
                    message: 'You already have an active session. Cannot request late punch-in.'
                });
            }

            // Create late punch-in approval request
            const approval = await prisma.latePunchApproval.create({
                data: {
                    employeeId,
                    employeeName,
                    requestDate: currentTime,
                    punchInDate: currentTime,
                    reason: reason.trim(),
                    status: 'PENDING',
                    codeExpiresAt: expiresAt
                }
            });

            return res.status(201).json({
                success: true,
                message: 'Late punch-in approval request submitted',
                data: {
                    id: approval.id,
                    type: 'LATE_PUNCH_IN',
                    status: 'PENDING',
                    expiresAt: expiresAt.toISOString()
                }
            });
        }

        else if (type === 'EARLY_PUNCH_OUT') {
            if (!attendanceId) {
                return res.status(400).json({
                    success: false,
                    message: 'attendanceId is required for early punch-out approval'
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

            // Check for existing pending request
            const existingRequest = await prisma.earlyPunchOutApproval.findFirst({
                where: {
                    employeeId,
                    attendanceId,
                    status: 'PENDING'
                }
            });

            if (existingRequest) {
                return res.status(400).json({
                    success: false,
                    message: 'You already have a pending early punch-out request for this session',
                    data: { requestId: existingRequest.id }
                });
            }

            // Create early punch-out approval request
            const approval = await prisma.earlyPunchOutApproval.create({
                data: {
                    employeeId,
                    employeeName,
                    attendanceId,
                    requestDate: currentTime,
                    punchOutDate: currentTime,
                    reason: reason.trim(),
                    status: 'PENDING',
                    codeExpiresAt: expiresAt
                }
            });

            return res.status(201).json({
                success: true,
                message: 'Early punch-out approval request submitted',
                data: {
                    id: approval.id,
                    type: 'EARLY_PUNCH_OUT',
                    status: 'PENDING',
                    expiresAt: expiresAt.toISOString()
                }
            });
        }

    } catch (error) {
        console.error('❌ Request approval error:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to submit approval request',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * POST /approval/approve - Admin approves a request
 */
export const approveRequest = async (req, res) => {
    try {
        const { requestId, type, adminId, adminRemarks } = req.body;

        if (!requestId || !type || !adminId) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: requestId, type, adminId'
            });
        }

        const currentTime = getCurrentISTTime();
        const codeExpiresAt = new Date(currentTime);
        codeExpiresAt.setHours(codeExpiresAt.getHours() + 2); // Code valid for 2 hours

        // Generate 6-digit approval code
        const approvalCode = Math.floor(100000 + Math.random() * 900000).toString();

        if (type === 'LATE_PUNCH_IN') {
            const approval = await prisma.latePunchApproval.findUnique({
                where: { id: requestId }
            });

            if (!approval) {
                return res.status(404).json({
                    success: false,
                    message: 'Approval request not found'
                });
            }

            if (approval.status !== 'PENDING') {
                return res.status(400).json({
                    success: false,
                    message: `Request already ${approval.status.toLowerCase()}`
                });
            }

            // Check if request has expired
            if (isApprovalExpired(approval)) {
                await prisma.latePunchApproval.update({
                    where: { id: requestId },
                    data: { status: 'EXPIRED' }
                });
                return res.status(400).json({
                    success: false,
                    message: 'Request has expired'
                });
            }

            const updated = await prisma.latePunchApproval.update({
                where: { id: requestId },
                data: {
                    status: 'APPROVED',
                    approvedBy: adminId,
                    approvedAt: currentTime,
                    adminRemarks: adminRemarks || null,
                    approvalCode,
                    codeExpiresAt
                }
            });

            return res.status(200).json({
                success: true,
                message: 'Late punch-in request approved',
                data: {
                    id: updated.id,
                    employeeId: updated.employeeId,
                    status: 'APPROVED',
                    approvalCode,
                    codeExpiresAt: codeExpiresAt.toISOString()
                }
            });
        }

        else if (type === 'EARLY_PUNCH_OUT') {
            const approval = await prisma.earlyPunchOutApproval.findUnique({
                where: { id: requestId }
            });

            if (!approval) {
                return res.status(404).json({
                    success: false,
                    message: 'Approval request not found'
                });
            }

            if (approval.status !== 'PENDING') {
                return res.status(400).json({
                    success: false,
                    message: `Request already ${approval.status.toLowerCase()}`
                });
            }

            // Check if request has expired
            if (isApprovalExpired(approval)) {
                await prisma.earlyPunchOutApproval.update({
                    where: { id: requestId },
                    data: { status: 'EXPIRED' }
                });
                return res.status(400).json({
                    success: false,
                    message: 'Request has expired'
                });
            }

            // Verify attendance session is still active
            const attendance = await prisma.attendance.findUnique({
                where: { id: approval.attendanceId }
            });

            if (!attendance || attendance.status !== 'active') {
                return res.status(400).json({
                    success: false,
                    message: 'Attendance session is no longer active'
                });
            }

            const updated = await prisma.earlyPunchOutApproval.update({
                where: { id: requestId },
                data: {
                    status: 'APPROVED',
                    approvedBy: adminId,
                    approvedAt: currentTime,
                    adminRemarks: adminRemarks || null,
                    approvalCode,
                    codeExpiresAt
                }
            });

            return res.status(200).json({
                success: true,
                message: 'Early punch-out request approved',
                data: {
                    id: updated.id,
                    employeeId: updated.employeeId,
                    attendanceId: updated.attendanceId,
                    status: 'APPROVED',
                    approvalCode,
                    codeExpiresAt: codeExpiresAt.toISOString()
                }
            });
        }

        return res.status(400).json({
            success: false,
            message: 'Invalid approval type'
        });

    } catch (error) {
        console.error('❌ Approve request error:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to approve request',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * POST /approval/reject - Admin rejects a request
 */
export const rejectRequest = async (req, res) => {
    try {
        const { requestId, type, adminId, adminRemarks } = req.body;

        if (!requestId || !type || !adminId) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: requestId, type, adminId'
            });
        }

        const currentTime = getCurrentISTTime();

        if (type === 'LATE_PUNCH_IN') {
            const approval = await prisma.latePunchApproval.findUnique({
                where: { id: requestId }
            });

            if (!approval) {
                return res.status(404).json({
                    success: false,
                    message: 'Approval request not found'
                });
            }

            if (approval.status !== 'PENDING') {
                return res.status(400).json({
                    success: false,
                    message: `Request already ${approval.status.toLowerCase()}`
                });
            }

            const updated = await prisma.latePunchApproval.update({
                where: { id: requestId },
                data: {
                    status: 'REJECTED',
                    approvedBy: adminId,
                    approvedAt: currentTime,
                    adminRemarks: adminRemarks || 'Request rejected by admin'
                }
            });

            return res.status(200).json({
                success: true,
                message: 'Late punch-in request rejected',
                data: { id: updated.id, status: 'REJECTED' }
            });
        }

        else if (type === 'EARLY_PUNCH_OUT') {
            const approval = await prisma.earlyPunchOutApproval.findUnique({
                where: { id: requestId }
            });

            if (!approval) {
                return res.status(404).json({
                    success: false,
                    message: 'Approval request not found'
                });
            }

            if (approval.status !== 'PENDING') {
                return res.status(400).json({
                    success: false,
                    message: `Request already ${approval.status.toLowerCase()}`
                });
            }

            const updated = await prisma.earlyPunchOutApproval.update({
                where: { id: requestId },
                data: {
                    status: 'REJECTED',
                    approvedBy: adminId,
                    approvedAt: currentTime,
                    adminRemarks: adminRemarks || 'Request rejected by admin'
                }
            });

            return res.status(200).json({
                success: true,
                message: 'Early punch-out request rejected',
                data: { id: updated.id, status: 'REJECTED' }
            });
        }

        return res.status(400).json({
            success: false,
            message: 'Invalid approval type'
        });

    } catch (error) {
        console.error('❌ Reject request error:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to reject request',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

/**
 * Cron job / Background task: Expire stale approvals
 * Call this periodically (e.g., every 5 minutes)
 */
export const expireStaleApprovals = async () => {
    try {
        const currentTime = new Date();

        // Expire late punch-in approvals
        const expiredLate = await prisma.latePunchApproval.updateMany({
            where: {
                status: 'PENDING',
                OR: [
                    { codeExpiresAt: { lt: currentTime } },
                    {
                        codeExpiresAt: null,
                        createdAt: { lt: new Date(currentTime.getTime() - APPROVAL_EXPIRY_MINUTES * 60 * 1000) }
                    }
                ]
            },
            data: { status: 'EXPIRED' }
        });

        // Expire early punch-out approvals
        const expiredEarly = await prisma.earlyPunchOutApproval.updateMany({
            where: {
                status: 'PENDING',
                OR: [
                    { codeExpiresAt: { lt: currentTime } },
                    {
                        codeExpiresAt: null,
                        createdAt: { lt: new Date(currentTime.getTime() - APPROVAL_EXPIRY_MINUTES * 60 * 1000) }
                    }
                ]
            },
            data: { status: 'EXPIRED' }
        });

        // Also expire approved but unused codes
        const expiredLateApproved = await prisma.latePunchApproval.updateMany({
            where: {
                status: 'APPROVED',
                codeUsed: false,
                codeExpiresAt: { lt: currentTime }
            },
            data: { status: 'EXPIRED' }
        });

        const expiredEarlyApproved = await prisma.earlyPunchOutApproval.updateMany({
            where: {
                status: 'APPROVED',
                codeUsed: false,
                codeExpiresAt: { lt: currentTime }
            },
            data: { status: 'EXPIRED' }
        });

        const totalExpired = expiredLate.count + expiredEarly.count +
            expiredLateApproved.count + expiredEarlyApproved.count;

        if (totalExpired > 0) {
            console.log(`🕐 Expired ${totalExpired} stale approval requests`);
        }

        return { success: true, expiredCount: totalExpired };

    } catch (error) {
        console.error('❌ Expire stale approvals error:', error);
        return { success: false, error: error.message };
    }
};

/**
 * GET /approval/pending - Get all pending approvals for admin
 */
export const getPendingApprovals = async (req, res) => {
    try {
        const { type, page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        let latePunchApprovals = [];
        let earlyPunchOutApprovals = [];

        if (!type || type === 'LATE_PUNCH_IN' || type === 'all') {
            latePunchApprovals = await prisma.latePunchApproval.findMany({
                where: { status: 'PENDING' },
                orderBy: { createdAt: 'desc' },
                skip: type === 'LATE_PUNCH_IN' ? skip : 0,
                take: type === 'LATE_PUNCH_IN' ? parseInt(limit) : 50,
                include: {
                    employee: {
                        select: { name: true, contactNumber: true, employeeCode: true }
                    }
                }
            });
        }

        if (!type || type === 'EARLY_PUNCH_OUT' || type === 'all') {
            earlyPunchOutApprovals = await prisma.earlyPunchOutApproval.findMany({
                where: { status: 'PENDING' },
                orderBy: { createdAt: 'desc' },
                skip: type === 'EARLY_PUNCH_OUT' ? skip : 0,
                take: type === 'EARLY_PUNCH_OUT' ? parseInt(limit) : 50,
                include: {
                    employee: {
                        select: { name: true, contactNumber: true, employeeCode: true }
                    }
                }
            });
        }

        return res.status(200).json({
            success: true,
            data: {
                latePunchIn: latePunchApprovals.map(a => ({ ...a, type: 'LATE_PUNCH_IN' })),
                earlyPunchOut: earlyPunchOutApprovals.map(a => ({ ...a, type: 'EARLY_PUNCH_OUT' }))
            }
        });

    } catch (error) {
        console.error('❌ Get pending approvals error:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to get pending approvals'
        });
    }
};

export default {
    getPunchStatus,
    requestApproval,
    approveRequest,
    rejectRequest,
    expireStaleApprovals,
    getPendingApprovals
};
