import prisma from '../config/db.js';

class BeatPlanService {
    /**
     * Generate weekly beat plan for a salesman
     * Auto-distributes areas across Monday-Saturday (6 days)
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
            monday.setHours(0, 0, 0, 0);
            const dayOfWeek = monday.getDay();
            if (dayOfWeek !== 1) {
                monday.setDate(monday.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
            }
            
            const saturday = new Date(monday);
            saturday.setDate(saturday.getDate() + 5); // Monday + 5 = Saturday

            // Check if plan already exists for this week
            const existingPlan = await prisma.weeklyBeatPlan.findFirst({
                where: {
                    salesmanId,
                    weekStartDate: {
                        gte: monday,
                        lt: new Date(monday.getTime() + 24 * 60 * 60 * 1000)
                    }
                }
            });

            if (existingPlan) {
                throw new Error('Beat plan already exists for this week. Delete the existing plan first.');
            }

            // Get salesman details
            const salesman = await prisma.user.findUnique({
                where: { id: salesmanId },
                select: { name: true, roles: true }
            });

            if (!salesman) {
                throw new Error('Salesman not found');
            }

            // Get all areas from AreaAssignment for this salesman
            let areas = await this.getAreasFromAssignments(salesmanId, pincodes);
            
            // If no areas from assignments, try getting from accounts
            if (areas.length === 0) {
                areas = await this.getAreasByPincodes(pincodes);
            }
            
            if (areas.length === 0) {
                throw new Error('No areas found. Please ensure the salesman has area assignments or accounts exist for the given pincodes.');
            }

            console.log(`📍 Found ${areas.length} areas for distribution:`, areas);

            // Auto-distribute areas across 6 days (Monday-Saturday)
            const dailyDistribution = this.distributeAreasAcrossDays(areas, 6);
            
            console.log('📅 Daily distribution:', dailyDistribution);

            // Create weekly beat plan with ACTIVE status (simplified)
            const weeklyBeatPlan = await prisma.weeklyBeatPlan.create({
                data: {
                    salesmanId,
                    salesmanName: salesman.name || 'Unknown',
                    weekStartDate: monday,
                    weekEndDate: saturday,
                    pincodes,
                    totalAreas: areas.length,
                    status: 'ACTIVE', // Simplified - directly active
                    generatedBy
                }
            });

            // Create daily beat plans for Monday-Saturday (6 days)
            const dailyPlans = [];
            const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            
            for (let day = 1; day <= 6; day++) {
                const dayDate = new Date(monday);
                dayDate.setDate(dayDate.getDate() + (day - 1));

                const assignedAreas = dailyDistribution[day - 1] || [];
                const plannedVisits = await this.calculatePlannedVisits(assignedAreas, pincodes);

                console.log(`📆 ${dayNames[day-1]}: ${assignedAreas.length} areas - ${assignedAreas.join(', ')}`);

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
     * Get areas from AreaAssignment table for a salesman
     * @param {string} salesmanId - Salesman ID
     * @param {string[]} pincodes - Array of pincodes
     * @returns {string[]} Array of unique area names
     */
    static async getAreasFromAssignments(salesmanId, pincodes) {
        const assignments = await prisma.areaAssignment.findMany({
            where: {
                salesmanId,
                ...(pincodes.length > 0 ? { pinCode: { in: pincodes } } : {})
            },
            select: { areas: true, city: true, district: true }
        });

        const allAreas = [];
        
        assignments.forEach(assignment => {
            // Add areas array if exists
            if (assignment.areas && Array.isArray(assignment.areas)) {
                assignment.areas.forEach(area => {
                    if (area && !allAreas.includes(area)) {
                        allAreas.push(area);
                    }
                });
            }
            // Also add city as an area if no specific areas
            if (assignment.city && !allAreas.includes(assignment.city)) {
                allAreas.push(assignment.city);
            }
        });

        console.log(`📍 Areas from assignments for salesman ${salesmanId}:`, allAreas);
        return allAreas.sort();
    }

    /**
     * Get areas by pincodes from existing accounts
     * @param {string[]} pincodes - Array of pincodes
     * @returns {string[]} Array of unique area names
     */
    static async getAreasByPincodes(pincodes) {
        if (!pincodes || pincodes.length === 0) return [];

        const accounts = await prisma.account.findMany({
            where: {
                pincode: { in: pincodes },
                isActive: true
            },
            select: { area: true },
            distinct: ['area']
        });

        const areas = accounts
            .map(account => account.area)
            .filter(area => area && area.trim() !== '')
            .sort();

        console.log(`📍 Areas from accounts for pincodes ${pincodes.join(', ')}:`, areas);
        return areas;
    }

    /**
     * Distribute areas evenly across specified number of days
     * Ensures no area appears on multiple days
     * @param {string[]} areas - Array of area names
     * @param {number} numDays - Number of days to distribute across (default 6 for Mon-Sat)
     * @returns {Array<string[]>} Array of arrays (one for each day)
     */
    static distributeAreasAcrossDays(areas, numDays = 6) {
        const distribution = Array.from({ length: numDays }, () => []);
        
        if (areas.length === 0) return distribution;

        // Shuffle areas for random distribution
        const shuffledAreas = [...areas].sort(() => Math.random() - 0.5);
        
        // Distribute areas round-robin across days
        shuffledAreas.forEach((area, index) => {
            const dayIndex = index % numDays;
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

        try {
            const accountCount = await prisma.account.count({
                where: {
                    OR: [
                        { area: { in: areas } },
                        ...(pincodes.length > 0 ? [{ pincode: { in: pincodes } }] : [])
                    ],
                    isActive: true
                }
            });
            return accountCount;
        } catch (e) {
            return areas.length; // Fallback to area count
        }
    }

    /**
     * Get today's beat plan for a salesman
     * @param {string} salesmanId - Salesman ID
     * @returns {Object|null} Today's beat plan or null
     */
    static async getTodaysBeatPlan(salesmanId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        let dayOfWeek = today.getDay(); // 0=Sunday, 1=Monday, etc.
        
        // Sunday (0) has no beat plan, return null
        if (dayOfWeek === 0) {
            return null;
        }
        
        // dayOfWeek is already 1-6 for Mon-Sat

        // Get current week's Monday
        const monday = new Date(today);
        monday.setDate(monday.getDate() - (dayOfWeek - 1));
        monday.setHours(0, 0, 0, 0);

        console.log(`🔍 Looking for beat plan: salesmanId=${salesmanId}, monday=${monday.toISOString()}, dayOfWeek=${dayOfWeek}`);

        // Find the weekly plan for this week
        const weeklyPlan = await prisma.weeklyBeatPlan.findFirst({
            where: {
                salesmanId,
                weekStartDate: {
                    gte: monday,
                    lt: new Date(monday.getTime() + 24 * 60 * 60 * 1000)
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

        console.log(`📋 Found weekly plan:`, weeklyPlan ? weeklyPlan.id : 'null');

        if (!weeklyPlan || weeklyPlan.dailyPlans.length === 0) {
            // Fallback: get customers by assignedDays (customer-based beat plan)
            const customersByDay = await prisma.account.findMany({
                where: {
                    assignedToId: salesmanId,
                    assignedDays: { has: dayOfWeek },
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
                },
                take: 100
            });
            if (customersByDay.length > 0) {
                return {
                    weeklyPlan: {
                        id: 'customer-based',
                        weekStartDate: monday,
                        weekEndDate: new Date(monday.getTime() + 6 * 24 * 60 * 60 * 1000),
                        status: 'ACTIVE',
                        totalAreas: customersByDay.length
                    },
                    dailyPlan: {
                        id: 'customer-based',
                        assignedAreas: [...new Set(customersByDay.map(a => a.area).filter(Boolean))],
                        plannedVisits: customersByDay.length
                    },
                    accounts: customersByDay,
                    completedAreas: []
                };
            }
            return null;
        }

        const todaysPlan = weeklyPlan.dailyPlans[0];
        
        console.log(`📅 Today's plan areas:`, todaysPlan.assignedAreas);

        // Get accounts for today's areas
        const accounts = await prisma.account.findMany({
            where: {
                OR: [
                    { area: { in: todaysPlan.assignedAreas } },
                    { pincode: { in: weeklyPlan.pincodes } }
                ],
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
            },
            take: 100 // Limit for performance
        });

        return {
            weeklyPlan: {
                id: weeklyPlan.id,
                weekStartDate: weeklyPlan.weekStartDate,
                weekEndDate: weeklyPlan.weekEndDate,
                status: weeklyPlan.status,
                totalAreas: weeklyPlan.totalAreas
            },
            dailyPlan: todaysPlan,
            accounts,
            completedAreas: todaysPlan.beatCompletions.map(bc => bc.areaName)
        };
    }

    /**
     * Generate beat plan from allotted customers - assign customers day-wise
     * @param {string} salesmanId - Salesman ID
     * @param {Date} weekStartDate - Monday of the week
     * @param {Object} dayAssignments - { "1": [accountIds], "2": [accountIds], ... } (1=Mon..6=Sat)
     * @param {string} generatedBy - Admin ID
     */
    static async generateFromCustomers(salesmanId, weekStartDate, dayAssignments, generatedBy) {
        const monday = new Date(weekStartDate);
        monday.setHours(0, 0, 0, 0);
        const saturday = new Date(monday);
        saturday.setDate(saturday.getDate() + 5);

        const salesman = await prisma.user.findUnique({
            where: { id: salesmanId },
            select: { name: true }
        });
        if (!salesman) throw new Error('Salesman not found');

        const allAssignedIds = new Set();
        for (let day = 1; day <= 6; day++) {
            const ids = dayAssignments[day.toString()] || [];
            ids.forEach(id => allAssignedIds.add(id));
        }

        // Clear assignedDays for allotted accounts not in any day
        await prisma.account.updateMany({
            where: {
                assignedToId: salesmanId,
                id: { notIn: Array.from(allAssignedIds) }
            },
            data: { assignedDays: [] }
        });

        // Update Account.assignedDays for each customer (only if allotted to this salesman)
        let totalCustomers = 0;
        for (let day = 1; day <= 6; day++) {
            const accountIds = dayAssignments[day.toString()] || [];
            for (const accountId of accountIds) {
                await prisma.account.updateMany({
                    where: { id: accountId, assignedToId: salesmanId },
                    data: { assignedDays: [day] }
                });
                totalCustomers += 1;
            }
        }

        // Delete existing beat plan for this week if any
        const existing = await prisma.weeklyBeatPlan.findFirst({
            where: {
                salesmanId,
                weekStartDate: {
                    gte: monday,
                    lt: new Date(monday.getTime() + 24 * 60 * 60 * 1000)
                }
            }
        });
        if (existing) {
            await BeatPlanService.deleteWeeklyBeatPlan(existing.id);
        }

        // Create WeeklyBeatPlan + DailyBeatPlans (customer-based)
        const weeklyBeatPlan = await prisma.weeklyBeatPlan.create({
            data: {
                salesmanId,
                salesmanName: salesman.name || 'Unknown',
                weekStartDate: monday,
                weekEndDate: saturday,
                pincodes: [],
                totalAreas: totalCustomers,
                status: 'ACTIVE',
                generatedBy
            }
        });

        const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const distribution = [];

        for (let day = 1; day <= 6; day++) {
            const accountIds = dayAssignments[day.toString()] || [];
            const dayDate = new Date(monday);
            dayDate.setDate(dayDate.getDate() + (day - 1));

            // Get areas from these accounts for backward compatibility
            const accounts = await prisma.account.findMany({
                where: { id: { in: accountIds } },
                select: { area: true }
            });
            const areas = accounts.map(a => a.area).filter(Boolean);

            await prisma.dailyBeatPlan.create({
                data: {
                    weeklyBeatId: weeklyBeatPlan.id,
                    dayOfWeek: day,
                    dayDate,
                    assignedAreas: areas,
                    plannedVisits: accountIds.length,
                    status: 'PLANNED'
                }
            });
            distribution.push(accountIds);
        }

        return {
            weeklyPlan: weeklyBeatPlan,
            totalAreas: totalCustomers,
            distribution
        };
    }

    /**
     * Get this week's beat plan for a salesman (all days)
     * @param {string} salesmanId - Salesman ID
     * @returns {Object|null} This week's beat plan or null
     */
    static async getThisWeeksBeatPlan(salesmanId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const dayOfWeek = today.getDay();
        
        // Get current week's Monday
        const monday = new Date(today);
        monday.setDate(monday.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
        monday.setHours(0, 0, 0, 0);

        const weeklyPlan = await prisma.weeklyBeatPlan.findFirst({
            where: {
                salesmanId,
                weekStartDate: {
                    gte: monday,
                    lt: new Date(monday.getTime() + 24 * 60 * 60 * 1000)
                }
            },
            include: {
                dailyPlans: {
                    include: {
                        beatCompletions: true
                    },
                    orderBy: { dayOfWeek: 'asc' }
                }
            }
        });

        return weeklyPlan;
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
     * Delete a weekly beat plan
     * @param {string} weeklyBeatId - Weekly beat plan ID
     * @returns {Object} Deletion result
     */
    static async deleteWeeklyBeatPlan(weeklyBeatId) {
        // Delete beat completions first
        await prisma.beatCompletion.deleteMany({
            where: {
                dailyBeat: {
                    weeklyBeatId
                }
            }
        });

        // Delete daily plans
        await prisma.dailyBeatPlan.deleteMany({
            where: { weeklyBeatId }
        });

        // Delete weekly plan
        await prisma.weeklyBeatPlan.delete({
            where: { id: weeklyBeatId }
        });

        return { success: true, message: 'Beat plan deleted successfully' };
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

        const analytics = {
            totalPlans: weeklyPlans.length,
            totalAreas: weeklyPlans.reduce((sum, wp) => sum + wp.totalAreas, 0),
            completedAreas: 0,
            completionRate: 0
        };

        weeklyPlans.forEach(weeklyPlan => {
            weeklyPlan.dailyPlans.forEach(dailyPlan => {
                analytics.completedAreas += dailyPlan.beatCompletions.length;
            });
        });

        if (analytics.totalAreas > 0) {
            analytics.completionRate = Math.round((analytics.completedAreas / analytics.totalAreas) * 100);
        }

        return analytics;
    }
}

export default BeatPlanService;
