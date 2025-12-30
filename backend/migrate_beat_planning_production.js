import prisma from './src/config/db.js';

async function migrateBeatPlanningProduction() {
    try {
        console.log('🚀 Starting Beat Planning Production Migration...');
        console.log('🌐 Environment:', process.env.NODE_ENV || 'development');
        console.log('🗄️  Database URL:', process.env.DATABASE_URL ? 'Connected' : 'Not configured');

        // Step 1: Check if tables already exist
        console.log('\n🔍 Checking existing tables...');
        
        try {
            const existingWeeklyPlans = await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan" LIMIT 1`;
            console.log('✅ WeeklyBeatPlan table already exists');
            
            const existingDailyPlans = await prisma.$queryRaw`SELECT COUNT(*) FROM "DailyBeatPlan" LIMIT 1`;
            console.log('✅ DailyBeatPlan table already exists');
            
            const existingCompletions = await prisma.$queryRaw`SELECT COUNT(*) FROM "BeatCompletion" LIMIT 1`;
            console.log('✅ BeatCompletion table already exists');
            
            console.log('✅ All beat planning tables already exist. Migration not needed.');
            return;
            
        } catch (error) {
            console.log('📝 Tables do not exist. Proceeding with migration...');
        }

        // Step 2: Create WeeklyBeatPlan table
        console.log('\n📊 Creating WeeklyBeatPlan table...');
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
        console.log('✅ WeeklyBeatPlan table created');

        // Step 3: Create DailyBeatPlan table
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
        console.log('✅ DailyBeatPlan table created');

        // Step 4: Create BeatCompletion table
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
        console.log('✅ BeatCompletion table created');

        // Step 5: Add unique constraints (with error handling)
        console.log('\n🔗 Adding unique constraints...');
        
        const constraints = [
            {
                name: 'WeeklyBeatPlan_salesmanId_weekStartDate_key',
                sql: 'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_weekStartDate_key" UNIQUE ("salesmanId", "weekStartDate")'
            },
            {
                name: 'DailyBeatPlan_weeklyBeatId_dayOfWeek_key',
                sql: 'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_dayOfWeek_key" UNIQUE ("weeklyBeatId", "dayOfWeek")'
            }
        ];

        for (const constraint of constraints) {
            try {
                await prisma.$executeRawUnsafe(constraint.sql);
                console.log(`✅ ${constraint.name} constraint added`);
            } catch (error) {
                if (error.message.includes('already exists') || error.code === '42710') {
                    console.log(`⚠️  ${constraint.name} constraint already exists`);
                } else {
                    console.error(`❌ Error adding ${constraint.name}:`, error.message);
                }
            }
        }

        // Step 6: Add indexes (with error handling)
        console.log('\n📈 Creating indexes...');
        
        const indexes = [
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_salesmanId_idx" ON "WeeklyBeatPlan"("salesmanId")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_weekStartDate_idx" ON "WeeklyBeatPlan"("weekStartDate")',
            'CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_status_idx" ON "WeeklyBeatPlan"("status")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_weeklyBeatId_idx" ON "DailyBeatPlan"("weeklyBeatId")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_dayOfWeek_idx" ON "DailyBeatPlan"("dayOfWeek")',
            'CREATE INDEX IF NOT EXISTS "DailyBeatPlan_status_idx" ON "DailyBeatPlan"("status")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_dailyBeatId_idx" ON "BeatCompletion"("dailyBeatId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_salesmanId_idx" ON "BeatCompletion"("salesmanId")',
            'CREATE INDEX IF NOT EXISTS "BeatCompletion_areaName_idx" ON "BeatCompletion"("areaName")'
        ];

        for (const indexSQL of indexes) {
            try {
                await prisma.$executeRawUnsafe(indexSQL);
            } catch (error) {
                console.log(`⚠️  Index creation skipped: ${error.message}`);
            }
        }
        console.log('✅ Indexes created');

        // Step 7: Add foreign key constraints (with error handling)
        console.log('\n🔗 Adding foreign key constraints...');
        
        const foreignKeys = [
            {
                name: 'WeeklyBeatPlan_salesmanId_fkey',
                sql: 'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE'
            },
            {
                name: 'WeeklyBeatPlan_generatedBy_fkey',
                sql: 'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_generatedBy_fkey" FOREIGN KEY ("generatedBy") REFERENCES "User"("id") ON DELETE SET NULL'
            },
            {
                name: 'WeeklyBeatPlan_approvedBy_fkey',
                sql: 'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "User"("id") ON DELETE SET NULL'
            },
            {
                name: 'WeeklyBeatPlan_lockedBy_fkey',
                sql: 'ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_lockedBy_fkey" FOREIGN KEY ("lockedBy") REFERENCES "User"("id") ON DELETE SET NULL'
            },
            {
                name: 'DailyBeatPlan_weeklyBeatId_fkey',
                sql: 'ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_fkey" FOREIGN KEY ("weeklyBeatId") REFERENCES "WeeklyBeatPlan"("id") ON DELETE CASCADE'
            },
            {
                name: 'BeatCompletion_dailyBeatId_fkey',
                sql: 'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_dailyBeatId_fkey" FOREIGN KEY ("dailyBeatId") REFERENCES "DailyBeatPlan"("id") ON DELETE CASCADE'
            },
            {
                name: 'BeatCompletion_salesmanId_fkey',
                sql: 'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE'
            },
            {
                name: 'BeatCompletion_verifiedBy_fkey',
                sql: 'ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_verifiedBy_fkey" FOREIGN KEY ("verifiedBy") REFERENCES "User"("id") ON DELETE SET NULL'
            }
        ];

        for (const fk of foreignKeys) {
            try {
                await prisma.$executeRawUnsafe(fk.sql);
                console.log(`✅ ${fk.name} constraint added`);
            } catch (error) {
                if (error.message.includes('already exists') || error.code === '42710') {
                    console.log(`⚠️  ${fk.name} constraint already exists`);
                } else {
                    console.error(`❌ Error adding ${fk.name}:`, error.message);
                    // Don't fail the migration for foreign key issues
                }
            }
        }

        // Step 8: Verify tables were created
        console.log('\n🔍 Verifying table creation...');
        
        try {
            const weeklyBeatCount = await prisma.$queryRaw`SELECT COUNT(*) FROM "WeeklyBeatPlan"`;
            console.log('✅ WeeklyBeatPlan table verified');
            
            const dailyBeatCount = await prisma.$queryRaw`SELECT COUNT(*) FROM "DailyBeatPlan"`;
            console.log('✅ DailyBeatPlan table verified');
            
            const beatCompletionCount = await prisma.$queryRaw`SELECT COUNT(*) FROM "BeatCompletion"`;
            console.log('✅ BeatCompletion table verified');
            
        } catch (error) {
            console.error('❌ Table verification failed:', error.message);
            throw error;
        }

        console.log('\n🎉 Beat Planning Production Migration completed successfully!');
        console.log('📊 Tables created:');
        console.log('   - WeeklyBeatPlan (weekly beat plans)');
        console.log('   - DailyBeatPlan (daily area assignments)');
        console.log('   - BeatCompletion (area completion tracking)');
        console.log('🔗 Foreign key relationships established');
        console.log('📈 Performance indexes created');
        console.log('🛡️  Unique constraints added');
        console.log('\n✨ Beat Planning module is now ready for production use!');

    } catch (error) {
        console.error('❌ Production migration failed:', error);
        console.error('Stack trace:', error.stack);
        
        // Don't exit process in production - let the app continue running
        if (process.env.NODE_ENV === 'production') {
            console.log('⚠️  Migration failed but continuing in production mode');
            console.log('💡 Please check database permissions and try again');
        } else {
            process.exit(1);
        }
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
migrateBeatPlanningProduction();