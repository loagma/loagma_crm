/**
 * Migration script to add isHomeLocation column to SalesmanRouteLog table
 * Run this on production to fix the missing column error
 * 
 * Usage: node run_is_home_location_migration.js
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function runMigration() {
    console.log('🚀 Starting isHomeLocation column migration...');
    console.log('Database URL:', process.env.DATABASE_URL?.substring(0, 30) + '...');

    try {
        // Check if column already exists
        console.log('\n📋 Checking if isHomeLocation column exists...');

        const checkColumnQuery = `
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'SalesmanRouteLog' 
            AND column_name = 'isHomeLocation';
        `;

        const existingColumn = await prisma.$queryRawUnsafe(checkColumnQuery);

        if (existingColumn.length > 0) {
            console.log('✅ Column isHomeLocation already exists. No migration needed.');
            return;
        }

        console.log('⚠️ Column isHomeLocation does not exist. Adding it now...');

        // Add the isHomeLocation column
        const addColumnQuery = `
            ALTER TABLE "SalesmanRouteLog" 
            ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false;
        `;

        await prisma.$executeRawUnsafe(addColumnQuery);
        console.log('✅ Added isHomeLocation column successfully');

        // Create index for better query performance
        console.log('\n📊 Creating index on isHomeLocation...');

        const createIndexQuery = `
            CREATE INDEX IF NOT EXISTS "SalesmanRouteLog_isHomeLocation_idx" 
            ON "SalesmanRouteLog"("isHomeLocation");
        `;

        await prisma.$executeRawUnsafe(createIndexQuery);
        console.log('✅ Created index successfully');

        // Mark first route point of each attendance as home location
        console.log('\n🏠 Marking first route points as home locations...');

        const updateHomeLocationsQuery = `
            WITH first_points AS (
                SELECT DISTINCT ON ("attendanceId") id
                FROM "SalesmanRouteLog"
                ORDER BY "attendanceId", "recordedAt" ASC
            )
            UPDATE "SalesmanRouteLog"
            SET "isHomeLocation" = true
            WHERE id IN (SELECT id FROM first_points);
        `;

        const result = await prisma.$executeRawUnsafe(updateHomeLocationsQuery);
        console.log(`✅ Marked ${result} route points as home locations`);

        // Verify the migration
        console.log('\n🔍 Verifying migration...');

        const verifyQuery = `
            SELECT 
                COUNT(*) as total_routes,
                COUNT(CASE WHEN "isHomeLocation" = true THEN 1 END) as home_locations
            FROM "SalesmanRouteLog";
        `;

        const verification = await prisma.$queryRawUnsafe(verifyQuery);
        console.log('📊 Verification results:', verification[0]);

        console.log('\n✅ Migration completed successfully!');
        console.log('🎉 Route tracking should now work properly.');

    } catch (error) {
        console.error('\n❌ Migration failed:', error.message);
        console.error('Full error:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

runMigration()
    .then(() => {
        console.log('\n👋 Migration script finished.');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n💥 Migration script failed:', error);
        process.exit(1);
    });
