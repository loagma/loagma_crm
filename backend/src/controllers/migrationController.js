import prisma from '../config/db.js';

/**
 * @desc Run Beat Planning Migration
 * @route POST /api/migration/beat-planning
 * @access Admin only
 */
export const runBeatPlanningMigration = async (req, res) => {
    try {
        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can run migrations'
            });
        }

        console.log('🚀 Starting Beat Planning Migration via API...');

        // Step 1: Check if tables already exist
        try {
            await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan" LIMIT 1`;
            return res.json({
                success: true,
                message: 'Beat planning tables already exist',
                data: {
                    status: 'already_exists',
                    tables: ['WeeklyBeatPlan', 'DailyBeatPlan', 'BeatCompletion']
                }
            });
        } catch (error) {
            console.log('📝 Tables do not exist. Proceeding with migration...');
        }

        // Step 2: Create tables
        const tables = [
            {
                name: 'WeeklyBeatPlan',
                sql: `
                    CREATE TABLE IF NOT EXISTS "WeeklyBeatPlan" (
                        "id" TEXT NOT NULL,
                        "salesmanId" TEXT NOT NULL,
                        "salesmanName" TEXT NOT NULL,
                        "weekStartDate" TIMESTAMP(3) NOT NULL,
                        "weekEndDate" TIMESTAMP(3) NOT NULL,
                        "pincodes" TEXT[],
                        "totalAreas" INTEGER NOT NULL DEFAULT 0,
                        "status" TEXT NOT NULL DEFAULT 'DRAFT',
                        "generatedBy" TEXT,
                        "approvedBy" TEXT,
                        "approvedAt" TIMESTAMP(3),
                        "lockedBy" TEXT,
                        "lockedAt" TIMESTAMP(3),
                        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT "WeeklyBeatPlan_pkey" PRIMARY KEY ("id")
                    )
                `
            },
            {
                name: 'DailyBeatPlan',
                sql: `
                    CREATE TABLE IF NOT EXISTS "DailyBeatPlan" (
                        "id" TEXT NOT NULL,
                        "weeklyBeatId" TEXT NOT NULL,
                        "dayOfWeek" INTEGER NOT NULL,
                        "dayDate" TIMESTAMP(3) NOT NULL,
                        "assignedAreas" TEXT[],
                        "plannedVisits" INTEGER NOT NULL DEFAULT 0,
                        "actualVisits" INTEGER NOT NULL DEFAULT 0,
                        "status" TEXT NOT NULL DEFAULT 'PLANNED',
                        "completedAt" TIMESTAMP(3),
                        "carriedFromDate" TIMESTAMP(3),
                        "carriedToDate" TIMESTAMP(3),
                        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT "DailyBeatPlan_pkey" PRIMARY KEY ("id")
                    )
                `
            },
            {
                name: 'BeatCompletion',
                sql: `
                    CREATE TABLE IF NOT EXISTS "BeatCompletion" (
                        "id" TEXT NOT NULL,
                        "dailyBeatId" TEXT NOT NULL,
                        "salesmanId" TEXT NOT NULL,
                        "areaName" TEXT NOT NULL,
                        "accountsVisited" INTEGER NOT NULL DEFAULT 0,
                        "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "latitude" DOUBLE PRECISION,
                        "longitude" DOUBLE PRECISION,
                        "notes" TEXT,
                        "isVerified" BOOLEAN NOT NULL DEFAULT false,
                        "verifiedBy" TEXT,
                        "verifiedAt" TIMESTAMP(3),
                        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT "BeatCompletion_pkey" PRIMARY KEY ("id")
                    )
                `
            }
        ];

        const createdTables = [];
        for (const table of tables) {
            try {
                await prisma.$executeRawUnsafe(table.sql);
                createdTables.push(table.name);
                console.log(`✅ ${table.name} table created`);
            } catch (error) {
                console.error(`❌ Error creating ${table.name}:`, error.message);
                throw error;
            }
        }

        // Step 3: Add constraints and indexes
        const constraints = [
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_weekStartDate_key" UNIQUE ("salesmanId", "weekStartDate")',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_dayOfWeek_key" UNIQUE ("weeklyBeatId", "dayOfWeek")'
        ];

        const indexes = [
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_salesmanId_idx" ON "WeeklyBeatPlan"("salesmanId")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_weekStartDate_idx" ON "WeeklyBeatPlan"("weekStartDate")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_status_idx" ON "WeeklyBeatPlan"("status")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_weeklyBeatId_idx" ON "DailyBeatPlan"("weeklyBeatId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_dailyBeatId_idx" ON "BeatCompletion"("dailyBeatId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_salesmanId_idx" ON "BeatCompletion"("salesmanId")'
        ];

        const foreignKeys = [
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_fkey" FOREIGN KEY ("weeklyBeatId") REFERENCES "WeeklyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_dailyBeatId_fkey" FOREIGN KEY ("dailyBeatId") REFERENCES "DailyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE'
        ];

        // Execute constraints, indexes, and foreign keys (with error handling)
        const allStatements = [...constraints, ...indexes, ...foreignKeys];
        const executedStatements = [];

        for (const statement of allStatements) {
            try {
                await prisma.$executeRawUnsafe(statement);
                executedStatements.push(statement.split(' ')[1]); // Get the type (ALTER/CREATE)
            } catch (error) {
                if (!error.message.includes('already exists')) {
                    console.error(`⚠️  Statement failed: ${error.message}`);
                }
            }
        }

        // Step 4: Verify tables
        try {
            await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan"`;
            await prisma.$queryRaw`SELECT COUNT(*) FROM "DailyBeatPlan"`;
            await prisma.$queryRaw`SELECT COUNT(*) FROM "BeatCompletion"`;
        } catch (error) {
            throw new Error('Table verification failed: ' + error.message);
        }

        console.log('✅ Beat Planning Migration completed successfully via API');

        res.json({
            success: true,
            message: 'Beat planning migration completed successfully',
            data: {
                status: 'completed',
                createdTables,
                executedStatements: executedStatements.length,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('❌ Beat Planning Migration failed via API:', error);
        res.status(500).json({
            success: false,
            message: 'Migration failed: ' + error.message,
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};

/**
 * @desc Check Beat Planning Migration Status
 * @route GET /api/migration/beat-planning/status
 * @access Admin only
 */
export const checkBeatPlanningStatus = async (req, res) => {
    try {
        // Validate admin role
        if (!req.user.roles?.includes('admin') && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admins can check migration status'
            });
        }

        const tableStatus = {};
        const tables = ['WeeklyBeatPlan', 'DailyBeatPlan', 'BeatCompletion'];

        for (const table of tables) {
            try {
                const result = await prisma.$queryRaw`SELECT COUNT(*) FROM ${prisma.Prisma.raw(`"${table}"`)}`;
                tableStatus[table] = {
                    exists: true,
                    count: Number(result[0].count)
                };
            } catch (error) {
                tableStatus[table] = {
                    exists: false,
                    error: error.message
                };
            }
        }

        const allTablesExist = Object.values(tableStatus).every(status => status.exists);

        res.json({
            success: true,
            message: allTablesExist ? 'Beat planning tables exist' : 'Beat planning tables missing',
            data: {
                migrationRequired: !allTablesExist,
                tableStatus,
                timestamp: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('❌ Error checking beat planning status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to check migration status: ' + error.message
        });
    }
};