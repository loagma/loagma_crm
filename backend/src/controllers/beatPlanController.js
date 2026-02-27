import BeatPlanService from '../services/beatPlanService.js';
import prisma from '../config/db.js';
import NotificationService from '../services/notificationService.js';

/**
 * @desc Generate weekly beat plan for a salesman
 * @route POST /beat-plans/generate
 * @access Admin only
 */
export const generateWeeklyBeatPlan = async (req, res) => {
    try {
        const { salesmanId, weekStartDate, pincodes } = req.body;
        const generatedBy = req.user.id;

        // Validate required fields
        if (!salesmanId || !weekStartDate || !pincodes || !Array.isArray(pincodes)) {
            return res.status(400).json({
                success: false,
                message: 'salesmanId, weekStartDate, and pincodes array are required'
            });
        }

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can generate beat plans'
            });
        }

        const result = await BeatPlanService.generateWeeklyBeatPlan(
            salesmanId,
            new Date(weekStartDate),
            pincodes,
            generatedBy
        );

        // Create notification for salesman
        await NotificationService.createNotification({
            title: 'New Beat Plan Generated',
            message: `Your weekly beat plan has been generated for ${new Date(weekStartDate).toLocaleDateString()}`,
            type: 'beat_plan',
            priority: 'normal',
            targetUserId: salesmanId,
            data: {
                weeklyBeatId: result.weeklyPlan.id,
                weekStartDate: result.weeklyPlan.weekStartDate,
                totalAreas: result.totalAreas
            }
        });

        res.json({
            success: true,
            message: 'Weekly beat plan generated successfully',
            data: result
        });

    } catch (error) {
        console.error('❌ Error generating beat plan:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to generate beat plan'
        });
    }
};

/**
 * @desc Generate beat plan from allotted customers (day-wise assignment)
 * @route POST /beat-plans/generate-from-customers
 * @access Admin only
 */
export const generateFromCustomers = async (req, res) => {
    try {
        const { salesmanId, weekStartDate, dayAssignments } = req.body;
        const generatedBy = req.user.id;

        if (!salesmanId || !weekStartDate || !dayAssignments || typeof dayAssignments !== 'object') {
            return res.status(400).json({
                success: false,
                message: 'salesmanId, weekStartDate, and dayAssignments object are required'
            });
        }

        const result = await BeatPlanService.generateFromCustomers(
            salesmanId,
            new Date(weekStartDate),
            dayAssignments,
            generatedBy
        );

        await NotificationService.createNotification({
            title: 'New Beat Plan (Customers)',
            message: `Your weekly beat plan has been created for ${new Date(weekStartDate).toLocaleDateString()}`,
            type: 'beat_plan',
            priority: 'normal',
            targetUserId: salesmanId,
            data: {
                weeklyBeatId: result.weeklyPlan.id,
                totalCustomers: result.totalAreas
            }
        });

        res.json({
            success: true,
            message: 'Beat plan created from customers successfully',
            data: result
        });
    } catch (error) {
        console.error('❌ Error generating beat plan from customers:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to create beat plan'
        });
    }
};

/**
 * @desc Get today's beat plan for salesman
 * @route GET /beat-plans/today
 * @access Salesman only
 */
export const getTodaysBeatPlan = async (req, res) => {
    try {
        const salesmanId = req.user.id;

        const todaysPlan = await BeatPlanService.getTodaysBeatPlan(salesmanId);

        if (!todaysPlan) {
            return res.json({
                success: true,
                message: 'No beat plan found for today',
                data: null
            });
        }

        res.json({
            success: true,
            message: 'Today\'s beat plan retrieved successfully',
            data: todaysPlan
        });

    } catch (error) {
        console.error('❌ Error getting today\'s beat plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get today\'s beat plan'
        });
    }
};

/**
 * @desc Mark beat area as complete
 * @route POST /beat-plans/complete-area
 * @access Salesman only
 */
export const markBeatAreaComplete = async (req, res) => {
    try {
        const salesmanId = req.user.id;
        const { dailyBeatId, areaName, accountsVisited, latitude, longitude, notes } = req.body;

        if (!dailyBeatId || !areaName) {
            return res.status(400).json({
                success: false,
                message: 'dailyBeatId and areaName are required'
            });
        }

        const completion = await BeatPlanService.markBeatComplete(
            salesmanId,
            dailyBeatId,
            areaName,
            { accountsVisited, latitude, longitude, notes }
        );

        res.json({
            success: true,
            message: 'Beat area marked as complete',
            data: completion
        });

    } catch (error) {
        console.error('❌ Error marking beat complete:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to mark beat area as complete'
        });
    }
};

/**
 * @desc Get weekly beat plans (admin view)
 * @route GET /beat-plans
 * @access Admin only
 */
export const getWeeklyBeatPlans = async (req, res) => {
    try {
        const { page = 1, limit = 10, salesmanId, status, weekStartDate } = req.query;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can view all beat plans'
            });
        }

        const whereClause = {};
        if (salesmanId) whereClause.salesmanId = salesmanId;
        if (status) whereClause.status = status;
        if (weekStartDate) {
            const startDate = new Date(weekStartDate);
            whereClause.weekStartDate = startDate;
        }

        const [beatPlans, totalCount] = await Promise.all([
            prisma.weeklyBeatPlan.findMany({
                where: whereClause,
                include: {
                    salesman: {
                        select: { name: true, employeeCode: true, contactNumber: true }
                    },
                    dailyPlans: {
                        include: {
                            beatCompletions: true
                        }
                    },
                    generator: {
                        select: { name: true }
                    }
                },
                orderBy: { weekStartDate: 'desc' },
                skip: (parseInt(page) - 1) * parseInt(limit),
                take: parseInt(limit)
            }),
            prisma.weeklyBeatPlan.count({ where: whereClause })
        ]);

        // Calculate completion stats for each plan
        const plansWithStats = beatPlans.map(plan => {
            const totalAreas = plan.totalAreas;
            const completedAreas = plan.dailyPlans.reduce((sum, dp) => sum + dp.beatCompletions.length, 0);
            const completionRate = totalAreas > 0 ? Math.round((completedAreas / totalAreas) * 100) : 0;

            return {
                ...plan,
                stats: {
                    totalAreas,
                    completedAreas,
                    completionRate,
                    totalDays: plan.dailyPlans.length,
                    completedDays: plan.dailyPlans.filter(dp => dp.status === 'COMPLETED').length
                }
            };
        });

        res.json({
            success: true,
            message: 'Beat plans retrieved successfully',
            data: plansWithStats,
            pagination: {
                total: totalCount,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(totalCount / parseInt(limit))
            }
        });

    } catch (error) {
        console.error('❌ Error getting beat plans:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get beat plans'
        });
    }
};

/**
 * @desc Get specific weekly beat plan details
 * @route GET /beat-plans/:id
 * @access Admin and assigned salesman
 */
export const getWeeklyBeatPlanDetails = async (req, res) => {
    try {
        const { id } = req.params;

        const beatPlan = await prisma.weeklyBeatPlan.findUnique({
            where: { id },
            include: {
                salesman: {
                    select: { name: true, employeeCode: true, contactNumber: true }
                },
                dailyPlans: {
                    include: {
                        beatCompletions: {
                            include: {
                                salesman: { select: { name: true } }
                            }
                        }
                    },
                    orderBy: { dayOfWeek: 'asc' }
                },
                generator: { select: { name: true } },
                approver: { select: { name: true } },
                locker: { select: { name: true } }
            }
        });

        if (!beatPlan) {
            return res.status(404).json({
                success: false,
                message: 'Beat plan not found'
            });
        }

        // Check access permissions
        const isAdmin = req.user.roles?.includes('admin') || req.user.role === 'admin';
        const isAssignedSalesman = beatPlan.salesmanId === req.user.id;

        if (!isAdmin && !isAssignedSalesman) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Get accounts for each day's areas / assigned customers
        const dailyPlansWithAccounts = await Promise.all(
            beatPlan.dailyPlans.map(async (dailyPlan) => {
                let accounts;

                // For customer-based beat plans (generated from allotted customers),
                // we don't store pincodes on the weekly plan. Instead, customers are
                // linked via Account.assignedToId + assignedDays.
                const isCustomerBasedPlan =
                    !beatPlan.pincodes || beatPlan.pincodes.length === 0;

                if (isCustomerBasedPlan) {
                    // Fetch accounts allotted to this salesman for this specific day
                    accounts = await prisma.account.findMany({
                        where: {
                            assignedToId: beatPlan.salesmanId,
                            // assignedDays is an Int[] - use `has` to match current day
                            assignedDays: {
                                array_contains: dailyPlan.dayOfWeek
                            },
                            isActive: true
                        },
                        select: {
                            id: true,
                            accountCode: true,
                            personName: true,
                            businessName: true,
                            contactNumber: true,
                            area: true,
                            address: true,
                            latitude: true,
                            longitude: true
                        }
                    });
                } else {
                    // Original pincode/area-based plans
                    accounts = await prisma.account.findMany({
                        where: {
                            area: { in: dailyPlan.assignedAreas },
                            pincode: { in: beatPlan.pincodes },
                            isActive: true
                        },
                        select: {
                            id: true,
                            accountCode: true,
                            personName: true,
                            businessName: true,
                            contactNumber: true,
                            area: true,
                            address: true,
                            latitude: true,
                            longitude: true
                        }
                    });
                }

                return {
                    ...dailyPlan,
                    accounts
                };
            })
        );

        res.json({
            success: true,
            message: 'Beat plan details retrieved successfully',
            data: {
                ...beatPlan,
                dailyPlans: dailyPlansWithAccounts
            }
        });

    } catch (error) {
        console.error('❌ Error getting beat plan details:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get beat plan details'
        });
    }
};

/**
 * @desc Update weekly beat plan (admin only)
 * @route PUT /beat-plans/:id
 * @access Admin only
 */
export const updateWeeklyBeatPlan = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, pincodes, dailyPlans } = req.body;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can update beat plans'
            });
        }

        // Check if plan exists and is not locked
        const existingPlan = await prisma.weeklyBeatPlan.findUnique({
            where: { id }
        });

        if (!existingPlan) {
            return res.status(404).json({
                success: false,
                message: 'Beat plan not found'
            });
        }

        if (existingPlan.status === 'LOCKED') {
            return res.status(400).json({
                success: false,
                message: 'Cannot update locked beat plan'
            });
        }

        // Update weekly plan
        const updateData = {};
        if (status) updateData.status = status;
        if (pincodes) updateData.pincodes = pincodes;
        if (status === 'ACTIVE') {
            updateData.approvedBy = req.user.id;
            updateData.approvedAt = new Date();
        }

        const updatedPlan = await prisma.weeklyBeatPlan.update({
            where: { id },
            data: updateData
        });

        // Update daily plans if provided
        if (dailyPlans && Array.isArray(dailyPlans)) {
            await Promise.all(
                dailyPlans.map(async (dailyPlan) => {
                    if (dailyPlan.id) {
                        await prisma.dailyBeatPlan.update({
                            where: { id: dailyPlan.id },
                            data: {
                                assignedAreas: dailyPlan.assignedAreas || [],
                                plannedVisits: dailyPlan.plannedVisits || 0
                            }
                        });
                    }
                })
            );
        }

        res.json({
            success: true,
            message: 'Beat plan updated successfully',
            data: updatedPlan
        });

    } catch (error) {
        console.error('❌ Error updating beat plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update beat plan'
        });
    }
};

/**
 * @desc Lock/unlock beat plan
 * @route POST /beat-plans/:id/toggle-lock
 * @access Admin only
 */
export const toggleBeatPlanLock = async (req, res) => {
    try {
        const { id } = req.params;
        const { lock = true } = req.body;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can lock/unlock beat plans'
            });
        }

        const updatedPlan = await BeatPlanService.toggleBeatPlanLock(id, req.user.id, lock);

        res.json({
            success: true,
            message: `Beat plan ${lock ? 'locked' : 'unlocked'} successfully`,
            data: updatedPlan
        });

    } catch (error) {
        console.error('❌ Error toggling beat plan lock:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to toggle beat plan lock'
        });
    }
};

/**
 * @desc Handle missed beats
 * @route POST /beat-plans/handle-missed/:dailyBeatId
 * @access Admin only
 */
export const handleMissedBeat = async (req, res) => {
    try {
        const { dailyBeatId } = req.params;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can handle missed beats'
            });
        }

        const result = await BeatPlanService.handleMissedBeat(dailyBeatId);

        res.json({
            success: true,
            message: result.message,
            data: result
        });

    } catch (error) {
        console.error('❌ Error handling missed beat:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to handle missed beat'
        });
    }
};

/**
 * @desc Get beat plan analytics
 * @route GET /beat-plans/analytics
 * @access Admin only
 */
export const getBeatPlanAnalytics = async (req, res) => {
    try {
        const { salesmanId, startDate, endDate } = req.query;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can view beat plan analytics'
            });
        }

        const analytics = await BeatPlanService.getBeatPlanAnalytics({
            salesmanId,
            startDate,
            endDate
        });

        res.json({
            success: true,
            message: 'Beat plan analytics retrieved successfully',
            data: analytics
        });

    } catch (error) {
        console.error('❌ Error getting beat plan analytics:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get beat plan analytics'
        });
    }
};

/**
 * @desc Delete weekly beat plan
 * @route DELETE /beat-plans/:id
 * @access Admin only
 */
export const deleteWeeklyBeatPlan = async (req, res) => {
    try {
        const { id } = req.params;

        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can delete beat plans'
            });
        }

        await BeatPlanService.deleteWeeklyBeatPlan(id);

        res.json({
            success: true,
            message: 'Beat plan deleted successfully'
        });

    } catch (error) {
        console.error('❌ Error deleting beat plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete beat plan'
        });
    }
};

/**
 * @desc Get this week's beat plan for salesman
 * @route GET /beat-plans/this-week
 * @access Salesman only
 */
export const getThisWeeksBeatPlan = async (req, res) => {
    try {
        const salesmanId = req.user.id;

        const weeklyPlan = await BeatPlanService.getThisWeeksBeatPlan(salesmanId);

        if (!weeklyPlan) {
            return res.json({
                success: true,
                message: 'No beat plan found for this week',
                data: null
            });
        }

        res.json({
            success: true,
            message: 'This week\'s beat plan retrieved successfully',
            data: weeklyPlan
        });

    } catch (error) {
        console.error('❌ Error getting this week\'s beat plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get this week\'s beat plan'
        });
    }
};

/**
 * @desc Get salesman's beat plan history
 * @route GET /beat-plans/salesman/history
 * @access Salesman only
 */
export const getSalesmanBeatHistory = async (req, res) => {
    try {
        const salesmanId = req.user.id;
        const { page = 1, limit = 10 } = req.query;

        const [beatPlans, totalCount] = await Promise.all([
            prisma.weeklyBeatPlan.findMany({
                where: { salesmanId },
                include: {
                    dailyPlans: {
                        include: {
                            beatCompletions: true
                        }
                    }
                },
                orderBy: { weekStartDate: 'desc' },
                skip: (parseInt(page) - 1) * parseInt(limit),
                take: parseInt(limit)
            }),
            prisma.weeklyBeatPlan.count({ where: { salesmanId } })
        ]);

        // Calculate stats for each plan
        const plansWithStats = beatPlans.map(plan => {
            const totalAreas = plan.totalAreas;
            const completedAreas = plan.dailyPlans.reduce((sum, dp) => sum + dp.beatCompletions.length, 0);
            const completionRate = totalAreas > 0 ? Math.round((completedAreas / totalAreas) * 100) : 0;

            return {
                ...plan,
                stats: {
                    totalAreas,
                    completedAreas,
                    completionRate
                }
            };
        });

        res.json({
            success: true,
            message: 'Beat plan history retrieved successfully',
            data: plansWithStats,
            pagination: {
                total: totalCount,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(totalCount / parseInt(limit))
            }
        });

    } catch (error) {
        console.error('❌ Error getting salesman beat history:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get beat plan history'
        });
    }
};