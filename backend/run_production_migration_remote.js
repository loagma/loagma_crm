// This script can be run via Render's shell or as a one-time job
// to migrate the production database with working hours columns

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function runProductionMigration() {
    console.log('🚀 Starting production migration for working hours...');
    console.log('🌍 Environment:', process.env.NODE_ENV || 'development');
    console.log('🗄️ Database connected:', !!process.env.DATABASE_URL);

    try {
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

        for (const migration of migrations) {
            try {
                console.log(`📝 Adding column: ${migration.name}`);
                await prisma.$executeRawUnsafe(migration.sql);
                console.log(`✅ Successfully added: ${migration.name}`);
            } catch (error) {
                if (error.code === '42701' || error.message.includes('already exists')) {
                    console.log(`ℹ️ Column ${migration.name} already exists, skipping`);
                } else {
                    console.error(`❌ Failed to add ${migration.name}:`, error.message);
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

        for (const update of updates) {
            try {
                const result = await prisma.$executeRawUnsafe(update);
                console.log(`✅ Updated ${result} users`);
            } catch (error) {
                console.log(`⚠️ Update failed:`, error.message);
            }
        }

        console.log('🎉 Production migration completed successfully!');
        console.log('📝 Please restart the server to refresh Prisma client cache');

    } catch (error) {
        console.error('💥 Migration failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

runProductionMigration();