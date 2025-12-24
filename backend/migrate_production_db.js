#!/usr/bin/env node

/**
 * Production Database Migration Script
 * 
 * This script safely adds the missing isHomeLocation column to the production database
 * on Render. It handles the case where the column might already exist.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrateProductionDatabase() {
    try {
        console.log('🚀 Starting production database migration...');
        console.log('🌍 Environment:', process.env.NODE_ENV || 'development');
        console.log('🔗 Database URL:', process.env.DATABASE_URL ? 'Connected' : 'Not found');
        
        // Step 1: Check if the column already exists
        console.log('\n📋 Step 1: Checking if isHomeLocation column exists...');
        
        try {
            // Try to query the column - if it fails, column doesn't exist
            await prisma.$queryRaw`
                SELECT "isHomeLocation" 
                FROM "SalesmanRouteLog" 
                LIMIT 1
            `;
            console.log('✅ Column already exists! No migration needed.');
            return;
        } catch (error) {
            if (error.message.includes('does not exist') || error.code === 'P2021') {
                console.log('❌ Column does not exist. Proceeding with migration...');
            } else {
                throw error;
            }
        }
        
        // Step 2: Add the missing column
        console.log('\n📋 Step 2: Adding isHomeLocation column...');
        
        await prisma.$executeRaw`
            ALTER TABLE "SalesmanRouteLog" 
            ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false
        `;
        
        console.log('✅ Column added successfully!');
        
        // Step 3: Create index for performance
        console.log('\n📋 Step 3: Creating index...');
        
        try {
            await prisma.$executeRaw`
                CREATE INDEX "SalesmanRouteLog_isHomeLocation_idx" 
                ON "SalesmanRouteLog"("isHomeLocation")
            `;
            console.log('✅ Index created successfully!');
        } catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ Index already exists!');
            } else {
                console.log('⚠️ Index creation failed (non-critical):', error.message);
            }
        }
        
        // Step 4: Mark existing first points as home locations
        console.log('\n📋 Step 4: Marking existing home locations...');
        
        const updateResult = await prisma.$executeRaw`
            UPDATE "SalesmanRouteLog" 
            SET "isHomeLocation" = true 
            WHERE id IN (
                SELECT DISTINCT ON ("attendanceId") id 
                FROM "SalesmanRouteLog" 
                ORDER BY "attendanceId", "recordedAt" ASC
            )
        `;
        
        console.log(`✅ Marked ${updateResult} records as home locations`);
        
        // Step 5: Verify the migration
        console.log('\n📋 Step 5: Verifying migration...');
        
        const verificationResult = await prisma.$queryRaw`
            SELECT 
                COUNT(*) as total_records,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
                COUNT(DISTINCT "attendanceId") as unique_sessions
            FROM "SalesmanRouteLog"
        `;
        
        const stats = verificationResult[0];
        console.log('📊 Migration Results:');
        console.log(`   - Total route records: ${stats.total_records}`);
        console.log(`   - Home locations marked: ${stats.home_locations}`);
        console.log(`   - Unique attendance sessions: ${stats.unique_sessions}`);
        
        // Step 6: Test the column access
        console.log('\n📋 Step 6: Testing column access...');
        
        const testQuery = await prisma.salesmanRouteLog.findFirst({
            where: { isHomeLocation: true },
            select: { id: true, isHomeLocation: true, recordedAt: true }
        });
        
        if (testQuery) {
            console.log('✅ Column access test passed!');
            console.log(`   - Found home location record: ${testQuery.id}`);
        } else {
            console.log('⚠️ No home location records found (this might be normal if no routes exist)');
        }
        
        console.log('\n🎉 Production database migration completed successfully!');
        console.log('\n📋 Next Steps:');
        console.log('   1. The getCurrentPositions API should now work without errors');
        console.log('   2. Route visualization should work in the admin app');
        console.log('   3. WebSocket location storage should work properly');
        console.log('   4. Test the live tracking system');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        
        if (error.code === 'P2010') {
            console.log('💡 Database connection failed. Check your DATABASE_URL environment variable.');
        } else if (error.message.includes('already exists')) {
            console.log('✅ Migration may have already been applied successfully.');
        } else {
            console.log('🔍 Error details:', {
                code: error.code,
                message: error.message,
                meta: error.meta
            });
        }
        
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
console.log('🔧 Production Database Migration for SalesmanRouteLog.isHomeLocation');
console.log('=' .repeat(70));

migrateProductionDatabase();