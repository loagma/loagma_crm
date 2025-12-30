import express from 'express';
import prisma from '../config/db.js';

const router = express.Router();

// Quick migration endpoint - no auth required for emergency use
router.post('/beat-planning-quick', async (req, res) => {
    try {
        console.log('🚀 Quick Beat Planning Migration...');

        // Check if tables exist
        try {
            await prisma.$queryRaw`SELECT 1 FROM "WeeklyBeatPlan" LIMIT 1`;
            return res.json({
                success: true,
                message: 'Beat planning tables already exist',
                status: 'already_exists'
            });
        } catch (error) {
            if (!error.message.includes('does not exist')) {
                throw error;
            }
        }

        // Create tables quickly
        const tables = [
            `CREATE TABLE IF NOT EXISTS "WeeklyBeatPlan" (
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
            )`,
            `CREATE TABLE IF NOT EXISTS "DailyBeatPlan" (
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
            )`,
            `CREATE TABLE IF NOT EXISTS "BeatCompletion" (
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
            )`
        ];

        for (const tableSQL of tables) {
            await prisma.$executeRawUnsafe(tableSQL);
        }

        // Add essential constraints
        const constraints = [
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_weekStartDate_key" UNIQUE ("salesmanId", "weekStartDate")',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_dayOfWeek_key" UNIQUE ("weeklyBeatId", "dayOfWeek")',
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_fkey" FOREIGN KEY ("weeklyBeatId") REFERENCES "WeeklyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_dailyBeatId_fkey" FOREIGN KEY ("dailyBeatId") REFERENCES "DailyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE'
        ];

        for (const constraint of constraints) {
            try {
                await prisma.$executeRawUnsafe(constraint);
            } catch (error) {
                if (!error.message.includes('already exists')) {
                    console.log(`⚠️  Constraint warning: ${error.message}`);
                }
            }
        }

        // Verify
        await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan"`;
        await prisma.$queryRaw`SELECT COUNT(*) FROM "DailyBeatPlan"`;
        await prisma.$queryRaw`SELECT COUNT(*) FROM "BeatCompletion"`;

        res.json({
            success: true,
            message: 'Beat planning tables created successfully',
            status: 'created',
            tables: ['WeeklyBeatPlan', 'DailyBeatPlan', 'BeatCompletion'],
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Quick migration failed:', error);
        res.status(500).json({
            success: false,
            message: 'Migration failed: ' + error.message,
            error: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
});

// Check status endpoint
router.get('/beat-planning-status', async (req, res) => {
    try {
        const tables = ['WeeklyBeatPlan', 'DailyBeatPlan', 'BeatCompletion'];
        const status = {};

        for (const table of tables) {
            try {
                const result = await prisma.$queryRaw`SELECT COUNT(*) FROM ${prisma.Prisma.raw(`"${table}"`)}`;
                status[table] = { exists: true, count: Number(result[0].count) };
            } catch (error) {
                status[table] = { exists: false, error: error.message };
            }
        }

        const allExist = Object.values(status).every(s => s.exists);

        res.json({
            success: true,
            message: allExist ? 'All tables exist' : 'Some tables missing',
            migrationNeeded: !allExist,
            tables: status,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Status check failed: ' + error.message
        });
    }
});

export default router;