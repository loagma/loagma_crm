import prisma from '../config/db.js';

class BeatPlanService {
    /**
     * Generate weekly beat plan for a salesman
     * Auto-distributes areas across 7 days to avoid overlaps
     * @param {string} salesmanId - Salesman ID
     * @param {Date} weekStartDate - Monday of the week
     * @param {string[]} pincodes - Array of pincodes assigned to salesman
     * @param {string} generatedBy - Admin ID who generated the plan
     * @returns {Object} Generated beat plan
     */
    static async generateWeeklyBeatPlan(salesmanId, weekStartDate, pincodes, generatedBy) {
        try {
            // Ensure weekStartDate is Monday
            const monday = new Date(weekStartDate);
            monday.setDate(monday.getDate() - monday.getDay() + 1);
            
            const sunday = new Date(monday);
            sunday.setDate(sunday.getDate() + 6);

            // Check if plan already exists for this week
            const existingPlan = await prisma.weeklyBeatPlan.findUnique({
                where: {
                    salesmanId_weekStartDate: {
                        salesmanId,
                        weekStartDate: monday
                    }
                }
            });

            if (existingPlan) {
                throw new Error('Beat plan already exists for this week');
            }

            // Get salesman details
            const salesman = await prisma.user.findUnique({
                where: { id: salesmanId },
                select: { name: true, roles: true }
            });

            if (!salesman) {
                throw new Error('Salesman not found');
            }

            // Get all areas for the assigned pincodes
            const areas = await this.getAreasByPincodes(pincodes);
            
            if (areas.length === 0) {
                throw new Error('No areas found for the assigned pincodes');
            }

            // Auto-distribute areas across 7 days
            const dailyDistribution = this.distributeAreasAcrossDays(areas);

            // Create weekly beat plan
            const weeklyBeatPlan = await prisma.weeklyBeatPlan.create({
                data: {
                    salesmanId,
                    salesmanName: salesman.name || 'Unknown',
                    weekStartDate: monday,
                    weekEndDate: sunday,
                    pincodes,
                    totalAreas: areas.length,
                    status: 'DRAFT',
                    generatedBy
                }
            });

            // Create daily beat plans
            const dailyPlans = [];
            for (let day = 1; day <= 7; day++) {
                const dayDate = new Date(monday);
                dayDate.setDate(dayDate.getDate() + (day - 1));

                const assignedAreas = dailyDistribution[day - 1] || [];
                const plannedVisits = await this.calculatePlannedVisits(assignedAreas, pincodes);

                const dailyPlan = await prisma.dailyBeatPlan.create({
                    data: {
                        weeklyBeatId: weeklyBeatPlan.id,
                        dayOfWeek: day,
                        dayDate,
                        assignedAreas,
                        plannedVisits,
                        status: 'PLANNED'
                    }
                });

                dailyPlans.push(dailyPlan);
            }

            return {
                weeklyPlan: weeklyBeatPlan,
                dailyPlans,
                totalAreas: areas.length,
                distribution: dailyDistribution
            };

        } catch (error) {
            console.error('❌ Error generating beat plan:', error);
            throw error;
        }
    }

    /**
     * Get areas by pincodes from existing accounts
     * @param {string[]} pincodes - Array of pincodes
     * @returns {string[]} Array of unique area names
     */
    static async getAreasByPincodes(pincodes) {
        const accounts = await prisma.account.findMany({
            where: {
                pincode: { in: pincodes },
                isActive: true
            },
            select: { area: true },
            distinct: ['area']
        });

        return accounts
            .map(account => account.area)
            .filter(area => area && area.trim() !== '')
            .sort();
    }

    /**
     * Distribute areas evenly across 7 days
     * Ensures no area appears on multiple days
     * @param {string[]} areas - Array of area names
     * @returns {Array<string[]>} Array of 7 arrays (one for each day)
     */
    static distributeAreasAcrossDays(areas) {
        const distribution = [[], [], [], [], [], [], []]; // 7 days
        
        // Shuffle areas for random distribution
        const shuffledAreas = [...areas].sort(() => Math.random() - 0.5);
        
        // Distribute areas round-robin across days
        shuffledAreas.forEach((area, index) => {
            const dayIndex = index % 7;
            distribution[dayIndex].push(area);
        });

        return distribution;
    }

    /**
     * Calculate planned visits for given areas
     * @param {string[]} areas - Array of area names
     * @param {string[]} pincodes - Array of pincodes
     * @returns {number} Number of planned visits
     */
    static async calculatePlannedVisits(areas, pincodes) {
        if (areas.length === 0) return 0;

        const accountCount = await prisma.account.count({
            where: {
                area: { in: areas },
                pincode: { in: pincodes },
                isActive: true
            }
        });

        return accountCount;
    }

    /**
     * Get today's beat plan for a salesman
     * @param {string} salesmanId - Salesman ID
     * @returns {Object|null} Today's beat plan or null
     */
    static async getTodaysBeatPlan(salesmanId) {
        const today = new Date();
        const dayOfWeek = today.getDay() === 0 ? 7 : today.getDay(); // Convert Sunday from 0 to 7

        // Get current week's Monday
        const monday = new Date(today);
        monday.setDate(monday.getDate() - monday.getDay() + 1);

        const weeklyPlan = await prisma.weeklyBeatPlan.findUnique({
            where: {
                salesmanId_weekStartDate: {
                    salesmanId,
                    weekStartDate: monday
                }
            },
            include: {
                dailyPlans: {
                    where: { dayOfWeek },
                    include: {
                        beatCompletions: true
                    }
                }
            }
        });

        if (!weeklyPlan || weeklyPlan.dailyPlans.length === 0) {
            return null;
        }

        const todaysPlan = weeklyPlan.dailyPlans[0];
        
        // Get accounts for today's areas
        const accounts = await prisma.account.findMany({
            where: {
                area: { in: todaysPlan.assignedAreas },
                pincode: { in: weeklyPlan.pincodes },
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

        return {
            weeklyPlan: {
                id: weeklyPlan.id,
                weekStartDate: weeklyPlan.weekStartDate,
                weekEndDate: weeklyPlan.weekEndDate,
                status: weeklyPlan.status
            },
            dailyPlan: todaysPlan,
            accounts,
            completedAreas: todaysPlan.beatCompletions.map(bc => bc.areaName)
        };
    }

    /**
     * Mark beat area as complete
     * @param {string} salesmanId - Salesman ID
     * @param {string} dailyBeatId - Daily beat plan ID
     * @param {string} areaName - Area name to mark complete
     * @param {Object} completionData - Completion details
     * @returns {Object} Beat completion record
     */
    static async markBeatComplete(salesmanId, dailyBeatId, areaName, completionData) {
        const { accountsVisited = 0, latitude, longitude, notes } = completionData;

        // Check if already completed
        const existingCompletion = await prisma.beatCompletion.findFirst({
            where: {
                dailyBeatId,
                salesmanId,
                areaName
            }
        });

        if (existingCompletion) {
            throw new Error('Beat area already marked as complete');
        }

        // Create completion record
        const completion = await prisma.beatCompletion.create({
            data: {
                dailyBeatId,
                salesmanId,
                areaName,
                accountsVisited,
                latitude,
                longitude,
                notes
            }
        });

        // Update daily plan actual visits
        await prisma.dailyBeatPlan.update({
            where: { id: dailyBeatId },
            data: {
                actualVisits: {
                    increment: accountsVisited
                }
            }
        });

        // Check if all areas for the day are completed
        const dailyPlan = await prisma.dailyBeatPlan.findUnique({
            where: { id: dailyBeatId },
            include: { beatCompletions: true }
        });

        if (dailyPlan && dailyPlan.beatCompletions.length === dailyPlan.assignedAreas.length) {
            await prisma.dailyBeatPlan.update({
                where: { id: dailyBeatId },
                data: {
                    status: 'COMPLETED',
                    completedAt: new Date()
                }
            });
        }

        return completion;
    }

    /**
     * Handle missed beats - carry forward to next available day
     * @param {string} dailyBeatId - Daily beat plan ID that was missed
     * @returns {Object} Carry forward result
     */
    static async handleMissedBeat(dailyBeatId) {
        const dailyPlan = await prisma.dailyBeatPlan.findUnique({
            where: { id: dailyBeatId },
            include: {
                weeklyBeat: true,
                beatCompletions: true
            }
        });

        if (!dailyPlan) {
            throw new Error('Daily beat plan not found');
        }

        // Get incomplete areas
        const completedAreas = dailyPlan.beatCompletions.map(bc => bc.areaName);
        const incompleteAreas = dailyPlan.assignedAreas.filter(area => !completedAreas.includes(area));

        if (incompleteAreas.length === 0) {
            return { message: 'No incomplete areas to carry forward' };
        }

        // Find next available day in the same week
        const nextDay = await prisma.dailyBeatPlan.findFirst({
            where: {
                weeklyBeatId: dailyPlan.weeklyBeatId,
                dayOfWeek: { gt: dailyPlan.dayOfWeek },
                status: 'PLANNED'
            },
            orderBy: { dayOfWeek: 'asc' }
        });

        if (!nextDay) {
            // Mark as missed if no next day available
            await prisma.dailyBeatPlan.update({
                where: { id: dailyBeatId },
                data: { status: 'MISSED' }
            });

            return { 
                message: 'No available day to carry forward. Marked as missed.',
                missedAreas: incompleteAreas
            };
        }

        // Add incomplete areas to next day
        await prisma.dailyBeatPlan.update({
            where: { id: nextDay.id },
            data: {
                assignedAreas: {
                    push: incompleteAreas
                },
                carriedFromDate: dailyPlan.dayDate
            }
        });

        // Update current day status
        await prisma.dailyBeatPlan.update({
            where: { id: dailyBeatId },
            data: {
                status: 'MISSED',
                carriedToDate: nextDay.dayDate
            }
        });

        return {
            message: 'Incomplete areas carried forward to next day',
            carriedAreas: incompleteAreas,
            carriedToDate: nextDay.dayDate
        };
    }

    /**
     * Get beat plan analytics for admin
     * @param {Object} filters - Filter options
     * @returns {Object} Analytics data
     */
    static async getBeatPlanAnalytics(filters = {}) {
        const { salesmanId, startDate, endDate } = filters;

        const whereClause = {};
        if (salesmanId) whereClause.salesmanId = salesmanId;
        if (startDate && endDate) {
            whereClause.weekStartDate = {
                gte: new Date(startDate),
                lte: new Date(endDate)
            };
        }

        // Get weekly plans with daily breakdown
        const weeklyPlans = await prisma.weeklyBeatPlan.findMany({
            where: whereClause,
            include: {
                dailyPlans: {
                    include: {
                        beatCompletions: true
                    }
                },
                salesman: {
                    select: { name: true, employeeCode: true }
                }
            },
            orderBy: { weekStartDate: 'desc' }
        });

        // Calculate analytics
        const analytics = {
            totalPlans: weeklyPlans.length,
            completedPlans: weeklyPlans.filter(wp => wp.status === 'COMPLETED').length,
            activePlans: weeklyPlans.filter(wp => wp.status === 'ACTIVE').length,
            totalAreas: weeklyPlans.reduce((sum, wp) => sum + wp.totalAreas, 0),
            completedAreas: 0,
            missedBeats: 0,
            completionRate: 0,
            salesmanPerformance: {}
        };

        weeklyPlans.forEach(weeklyPlan => {
            const salesmanName = weeklyPlan.salesman.name || 'Unknown';
            
            if (!analytics.salesmanPerformance[salesmanName]) {
                analytics.salesmanPerformance[salesmanName] = {
                    totalPlans: 0,
                    completedAreas: 0,
                    totalAreas: 0,
                    missedBeats: 0
                };
            }

            analytics.salesmanPerformance[salesmanName].totalPlans++;
            analytics.salesmanPerformance[salesmanName].totalAreas += weeklyPlan.totalAreas;

            weeklyPlan.dailyPlans.forEach(dailyPlan => {
                const completedAreasCount = dailyPlan.beatCompletions.length;
                analytics.completedAreas += completedAreasCount;
                analytics.salesmanPerformance[salesmanName].completedAreas += completedAreasCount;

                if (dailyPlan.status === 'MISSED') {
                    const missedCount = dailyPlan.assignedAreas.length - completedAreasCount;
                    analytics.missedBeats += missedCount;
                    analytics.salesmanPerformance[salesmanName].missedBeats += missedCount;
                }
            });
        });

        // Calculate completion rate
        if (analytics.totalAreas > 0) {
            analytics.completionRate = Math.round((analytics.completedAreas / analytics.totalAreas) * 100);
        }

        // Calculate individual completion rates
        Object.keys(analytics.salesmanPerformance).forEach(salesmanName => {
            const perf = analytics.salesmanPerformance[salesmanName];
            if (perf.totalAreas > 0) {
                perf.completionRate = Math.round((perf.completedAreas / perf.totalAreas) * 100);
            } else {
                perf.completionRate = 0;
            }
        });

        return analytics;
    }

    /**
     * Lock/unlock beat plan (admin only)
     * @param {string} weeklyBeatId - Weekly beat plan ID
     * @param {string} adminId - Admin ID
     * @param {boolean} lock - true to lock, false to unlock
     * @returns {Object} Updated beat plan
     */
    static async toggleBeatPlanLock(weeklyBeatId, adminId, lock = true) {
        const updateData = lock 
            ? { status: 'LOCKED', lockedBy: adminId, lockedAt: new Date() }
            : { status: 'ACTIVE', lockedBy: null, lockedAt: null };

        const updatedPlan = await prisma.weeklyBeatPlan.update({
            where: { id: weeklyBeatId },
            data: updateData,
            include: {
                salesman: { select: { name: true } },
                dailyPlans: true
            }
        });

        return updatedPlan;
    }
}

export default BeatPlanService;