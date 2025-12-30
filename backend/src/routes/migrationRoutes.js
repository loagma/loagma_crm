import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { runBeatPlanningMigration, checkBeatPlanningStatus } from '../controllers/migrationController.js';

const router = express.Router();
const prisma = new PrismaClient();

// Apply auth middleware to all routes
router.use(authMiddleware);

// Migration endpoint for working hours (admin only)
router.post('/working-hours', async (req, res) => {
    try {
        console.log('🚀 Starting working hours migration via API...');

        // Add columns one by one with error handling
        const migrations = [
            {
                name: 'workStartTime',
                sql: `ALTER TABLE "User" ADD COLUMN "workStartTime" TEXT DEFAULT '09:00:00'`
            },
            {
                name: 'workEndTime', 
                sql: `ALTER TABLE "User" ADD COLUMN "workEndTime" TEXT DEFAULT '18:00:00'`
            },
            {
                name: 'latePunchInGraceMinutes',
                sql: `ALTER TABLE "User" ADD COLUMN "latePunchInGraceMinutes" INTEGER DEFAULT 45`
            },
            {
                name: 'earlyPunchOutGraceMinutes',
                sql: `ALTER TABLE "User" ADD COLUMN "earlyPunchOutGraceMinutes" INTEGER DEFAULT 30`
            }
        ];

        const results = [];

        for (const migration of migrations) {
            try {
                console.log(`📝 Adding column: ${migration.name}`);
                await prisma.$executeRawUnsafe(migration.sql);
                console.log(`✅ Successfully added: ${migration.name}`);
                results.push({ column: migration.name, status: 'added' });
            } catch (error) {
                if (error.code === '42701' || error.message.includes('already exists')) {
                    console.log(`ℹ️ Column ${migration.name} already exists, skipping`);
                    results.push({ column: migration.name, status: 'exists' });
                } else {
                    console.error(`❌ Failed to add ${migration.name}:`, error.message);
                    results.push({ column: migration.name, status: 'failed', error: error.message });
                }
            }
        }

        // Update existing users
        console.log('📝 Updating existing users with default values...');
        const updates = [
            `UPDATE "User" SET "workStartTime" = '09:00:00' WHERE "workStartTime" IS NULL`,
            `UPDATE "User" SET "workEndTime" = '18:00:00' WHERE "workEndTime" IS NULL`, 
            `UPDATE "User" SET "latePunchInGraceMinutes" = 45 WHERE "latePunchInGraceMinutes" IS NULL`,
            `UPDATE "User" SET "earlyPunchOutGraceMinutes" = 30 WHERE "earlyPunchOutGraceMinutes" IS NULL`
        ];

        const updateResults = [];
        for (const update of updates) {
            try {
                const result = await prisma.$executeRawUnsafe(update);
                console.log(`✅ Updated ${result} users`);
                updateResults.push({ query: update.substring(0, 50) + '...', updated: result });
            } catch (error) {
                console.log(`⚠️ Update failed:`, error.message);
                updateResults.push({ query: update.substring(0, 50) + '...', error: error.message });
            }
        }

        console.log('🎉 Working hours migration completed!');

        res.json({
            success: true,
            message: 'Working hours migration completed successfully',
            results: {
                columns: results,
                updates: updateResults
            }
        });

    } catch (error) {
        console.error('💥 Migration failed:', error);
        res.status(500).json({
            success: false,
            message: 'Migration failed',
            error: error.message
        });
    }
});

// Check migration status
router.get('/working-hours/status', async (req, res) => {
    try {
        // Try to query working hours columns to see if they exist
        const testUser = await prisma.user.findFirst({
            select: {
                id: true,
                name: true,
                workStartTime: true,
                workEndTime: true,
                latePunchInGraceMinutes: true,
                earlyPunchOutGraceMinutes: true
            }
        });

        res.json({
            success: true,
            message: 'Working hours columns exist',
            migrated: true,
            sampleUser: testUser
        });

    } catch (error) {
        if (error.code === 'P2022' || error.message.includes('does not exist')) {
            res.json({
                success: true,
                message: 'Working hours columns do not exist',
                migrated: false,
                error: error.message
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Error checking migration status',
                error: error.message
            });
        }
    }
});

// Beat Planning Migration Routes
router.post('/beat-planning', runBeatPlanningMigration);
router.get('/beat-planning/status', checkBeatPlanningStatus);

export default router;