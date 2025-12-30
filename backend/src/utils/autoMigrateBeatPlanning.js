import prisma from '../config/db.js';

async function autoMigrateBeatPlanning() {
    try {
        console.log('🚀 Auto-migrating Beat Planning tables...');
        console.log('🌐 Environment:', process.env.NODE_ENV || 'development');

        // Check if we're in production and tables don't exist
        let needsMigration = false;

        try {
            await prisma.$queryRaw`SELECT 1 FROM "WeeklyBeatPlan" LIMIT 1`;
            console.log('✅ Beat planning tables already exist');
            return;
        } catch (error) {
            if (error.code === 'P2021' || error.message.includes('does not exist')) {
                needsMigration = true;
                console.log('📝 Beat planning tables do not exist, creating...');
            } else {
                throw error;
            }
        }

        if (!needsMigration) {
            console.log('✅ No migration needed');
            return;
        }

        // Create tables
        console.log('📊 Creating WeeklyBeatPlan table...');
        await prisma.$executeRawUnsafe(`
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
        `);

        console.log('📅 Creating DailyBeatPlan table...');
        await prisma.$executeRawUnsafe(`
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
        `);

        console.log('✅ Creating BeatCompletion table...');
        await prisma.$executeRawUnsafe(`
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
        `);

        // Add constraints and indexes (with error handling)
        const statements = [
            // Unique constraints
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_weekStartDate_key" UNIQUE ("salesmanId", "weekStartDate")',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_dayOfWeek_key" UNIQUE ("weeklyBeatId", "dayOfWeek")',

            // Indexes
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_salesmanId_idx" ON "WeeklyBeatPlan"("salesmanId")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_weekStartDate_idx" ON "WeeklyBeatPlan"("weekStartDate")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_status_idx" ON "WeeklyBeatPlan"("status")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_weeklyBeatId_idx" ON "DailyBeatPlan"("weeklyBeatId")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_dayOfWeek_idx" ON "DailyBeatPlan"("dayOfWeek")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_status_idx" ON "DailyBeatPlan"("status")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_dailyBeatId_idx" ON "BeatCompletion"("dailyBeatId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_salesmanId_idx" ON "BeatCompletion"("salesmanId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_areaName_idx" ON "BeatCompletion"("areaName")',

            // Foreign keys
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE',
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_generatedBy_fkey" FOREIGN KEY ("generatedBy") REFERENCES "User"("id") ON DELETE SET NULL',
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "User"("id") ON DELETE SET NULL',
            'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_lockedBy_fkey" FOREIGN KEY ("lockedBy") REFERENCES "User"("id") ON DELETE SET NULL',
            'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_fkey" FOREIGN KEY ("weeklyBeatId") REFERENCES "WeeklyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_dailyBeatId_fkey" FOREIGN KEY ("dailyBeatId") REFERENCES "DailyBeatPlan"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE',
            'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_verifiedBy_fkey" FOREIGN KEY ("verifiedBy") REFERENCES "User"("id") ON DELETE SET NULL'
        ];

        console.log('🔗 Adding constraints and indexes...');
        for (const statement of statements) {
            try {
                await prisma.$executeRawUnsafe(statement);
            } catch (error) {
                if (!error.message.includes('already exists') && !error.message.includes('duplicate')) {
                    console.log(`⚠️  Statement warning: ${error.message}`);
                }
            }
        }

        // Verify tables
        await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan"`;
        await prisma.$queryRaw`SELECT COUNT(*) FROM "DailyBeatPlan"`;
        await prisma.$queryRaw`SELECT COUNT(*) FROM "BeatCompletion"`;

        console.log('🎉 Beat Planning auto-migration completed successfully!');
        console.log('📊 Created tables: WeeklyBeatPlan, DailyBeatPlan, BeatCompletion');
        console.log('🔗 Added foreign keys, indexes, and constraints');
        console.log('✨ Beat Planning module is ready!');

    } catch (error) {
        console.error('❌ Auto-migration failed:', error.message);
        // Don't crash the app in production
        if (process.env.NODE_ENV === 'production') {
            console.log('⚠️  Continuing without beat planning tables');
        }
    } finally {
        await prisma.$disconnect();
    }
}

// Auto-run migration
autoMigrateBeatPlanning();
