import prisma from '../config/db.js';

class LeaveService {
    /**
     * Calculate number of working days between two dates (excluding weekends)
     * @param {Date} startDate - Leave start date
     * @param {Date} endDate - Leave end date
     * @returns {number} Number of working days
     */
    static calculateWorkingDays(startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        let workingDays = 0;

        const currentDate = new Date(start);
        while (currentDate <= end) {
            const dayOfWeek = currentDate.getDay();
            // Skip weekends (0 = Sunday, 6 = Saturday)
            if (dayOfWeek !== 0 && dayOfWeek !== 6) {
                workingDays++;
            }
            currentDate.setDate(currentDate.getDate() + 1);
        }

        return workingDays;
    }

    /**
     * Get or create leave balance for employee
     * @param {string} employeeId - Employee ID
     * @param {number} year - Year for leave balance
     * @returns {Object} Leave balance record
     */
    static async getOrCreateLeaveBalance(employeeId, year = new Date().getFullYear()) {
        let leaveBalance = await prisma.leaveBalance.findUnique({
            where: { employeeId }
        });

        if (!leaveBalance) {
            leaveBalance = await prisma.leaveBalance.create({
                data: {
                    employeeId,
                    year,
                    sickLeaves: 12,
                    casualLeaves: 10,
                    earnedLeaves: 20,
                    usedSickLeaves: 0,
                    usedCasualLeaves: 0,
                    usedEarnedLeaves: 0
                }
            });
        }

        return leaveBalance;
    }

    /**
     * Validate if employee has sufficient leave balance
     * @param {string} employeeId - Employee ID
     * @param {string} leaveType - Type of leave
     * @param {number} numberOfDays - Number of days requested
     * @returns {Object} Validation result with balance info
     */
    static async validateLeaveBalance(employeeId, leaveType, numberOfDays) {
        const leaveBalance = await this.getOrCreateLeaveBalance(employeeId);

        const leaveTypeMap = {
            'Sick': { allocated: leaveBalance.sickLeaves, used: leaveBalance.usedSickLeaves },
            'Casual': { allocated: leaveBalance.casualLeaves, used: leaveBalance.usedCasualLeaves },
            'Earned': { allocated: leaveBalance.earnedLeaves, used: leaveBalance.usedEarnedLeaves }
        };

        // For unpaid leaves, always allow
        if (leaveType === 'Unpaid' || leaveType === 'Emergency') {
            return {
                isValid: true,
                availableLeaves: 999,
                message: `${leaveType} leave request - no balance check required`
            };
        }

        const leaveInfo = leaveTypeMap[leaveType];
        if (!leaveInfo) {
            return {
                isValid: false,
                availableLeaves: 0,
                message: `Invalid leave type: ${leaveType}`
            };
        }

        const availableLeaves = leaveInfo.allocated - leaveInfo.used;
        const isValid = availableLeaves >= numberOfDays;

        return {
            isValid,
            availableLeaves,
            requestedDays: numberOfDays,
            message: isValid
                ? `Sufficient balance available (${availableLeaves} days remaining)`
                : `Insufficient balance. Available: ${availableLeaves} days, Requested: ${numberOfDays} days`
        };
    }

    /**
     * Update leave balance after approval/rejection
     * @param {string} employeeId - Employee ID
     * @param {string} leaveType - Type of leave
     * @param {number} numberOfDays - Number of days
     * @param {string} action - 'deduct' or 'restore'
     */
    static async updateLeaveBalance(employeeId, leaveType, numberOfDays, action = 'deduct') {
        if (leaveType === 'Unpaid' || leaveType === 'Emergency') {
            return; // No balance update needed for unpaid/emergency leaves
        }

        const leaveBalance = await this.getOrCreateLeaveBalance(employeeId);

        const fieldMap = {
            'Sick': 'usedSickLeaves',
            'Casual': 'usedCasualLeaves',
            'Earned': 'usedEarnedLeaves'
        };

        const field = fieldMap[leaveType];
        if (!field) return;

        const increment = action === 'deduct' ? numberOfDays : -numberOfDays;

        await prisma.leaveBalance.update({
            where: { employeeId },
            data: {
                [field]: {
                    increment: increment
                }
            }
        });
    }

    /**
     * Check for overlapping leave requests
     * @param {string} employeeId - Employee ID
     * @param {Date} startDate - Leave start date
     * @param {Date} endDate - Leave end date
     * @param {string} excludeLeaveId - Leave ID to exclude from check (for updates)
     * @returns {boolean} True if overlap exists
     */
    static async checkOverlappingLeaves(employeeId, startDate, endDate, excludeLeaveId = null) {
        const whereClause = {
            employeeId,
            status: {
                in: ['PENDING', 'APPROVED']
            },
            OR: [
                {
                    startDate: {
                        lte: endDate
                    },
                    endDate: {
                        gte: startDate
                    }
                }
            ]
        };

        if (excludeLeaveId) {
            whereClause.id = {
                not: excludeLeaveId
            };
        }

        const overlappingLeaves = await prisma.leave.findMany({
            where: whereClause,
            select: {
                id: true,
                startDate: true,
                endDate: true,
                leaveType: true,
                status: true
            }
        });

        return overlappingLeaves.length > 0;
    }

    /**
     * Get leave statistics for employee
     * @param {string} employeeId - Employee ID
     * @param {number} year - Year for statistics
     * @returns {Object} Leave statistics
     */
    static async getLeaveStatistics(employeeId, year = new Date().getFullYear()) {
        const leaveBalance = await this.getOrCreateLeaveBalance(employeeId, year);

        const leaves = await prisma.leave.findMany({
            where: {
                employeeId,
                status: 'APPROVED',
                startDate: {
                    gte: new Date(year, 0, 1),
                    lt: new Date(year + 1, 0, 1)
                }
            }
        });

        const leavesByType = leaves.reduce((acc, leave) => {
            acc[leave.leaveType] = (acc[leave.leaveType] || 0) + leave.numberOfDays;
            return acc;
        }, {});

        return {
            balance: leaveBalance,
            usedLeaves: leavesByType,
            totalLeavesUsed: leaves.reduce((sum, leave) => sum + leave.numberOfDays, 0),
            totalLeavesAvailable: leaveBalance.sickLeaves + leaveBalance.casualLeaves + leaveBalance.earnedLeaves,
            pendingRequests: await prisma.leave.count({
                where: { employeeId, status: 'PENDING' }
            })
        };
    }
}

export default LeaveService;