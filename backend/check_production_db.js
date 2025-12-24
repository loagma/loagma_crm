#!/usr/bin/env node

/**
 * Check Production Database Status
 * 
 * This script checks the current status of the production database
 * and identifies what needs to be fixed.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkProductionDatabase() {
    try {
        console.log('🔍 Checking production database status...');
        console.log('🌍 Environment:', process.env.NODE_ENV || 'development');
        
        // Step 1: Check if SalesmanRouteLog table exists
        console.log('\n📋 Step 1: Checking SalesmanRouteLog table...');
        
        try {
            const tableCount = await prisma.salesmanRouteLog.count();
            console.log(`✅ SalesmanRouteLog table exists with ${tableCount} records`);
        } catch (error) {
            console.log('❌ SalesmanRouteLog table issue:', error.message);
            return;
        }
        
        // Step 2: Check if isHomeLocation column exists
        console.log('\n📋 Step 2: Checking isHomeLocation column...');
        
        let columnExists = false;
        try {
            // Try to query the column
            await prisma.$queryRaw`
                SELECT "isHomeLocation" 
                FROM "SalesmanRouteLog" 
                LIMIT 1
            `;
            columnExists = true;
            console.log('✅ isHomeLocation column exists');
        } catch (error) {
            if (error.message.includes('does not exist') || error.code === 'P2021' || error.code === 'P2022') {
                console.log('❌ isHomeLocation column does NOT exist');
                columnExists = false;
            } else {
                console.log('❌ Error checking column:', error.message);
                return;
            }
        }
        
        // Step 3: Check database schema info
        console.log('\n📋 Step 3: Checking database schema...');
        
        try {
            const schemaInfo = await prisma.$queryRaw`
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'SalesmanRouteLog'
                ORDER BY ordinal_position
            `;
            
            console.log('📊 SalesmanRouteLog columns:');
            schemaInfo.forEach((col, index) => {
                const isHomeLocationCol = col.column_name === 'isHomeLocation';
                const status = isHomeLocationCol ? '✅' : '  ';
                console.log(`   ${status} ${index + 1}. ${col.column_name} (${col.data_type})`);
            });
            
            const hasHomeLocationColumn = schemaInfo.some(col => col.column_name === 'isHomeLocation');
            console.log(`\n📋 isHomeLocation column in schema: ${hasHomeLocationColumn ? '✅' : '❌'}`);
            
        } catch (error) {
            console.log('⚠️ Could not check schema info:', error.message);
        }
        
        // Step 4: Check active attendances
        console.log('\n📋 Step 4: Checking active attendances...');
        
        const activeAttendances = await prisma.attendance.findMany({
            where: { status: 'active' },
            select: {
                id: true,
                employeeId: true,
                employeeName: true,
                punchInTime: true
            }
        });
        
        console.log(`📊 Found ${activeAttendances.length} active attendance sessions:`);
        activeAttendances.forEach((attendance, index) => {
            console.log(`   ${index + 1}. ${attendance.employeeName} (${attendance.employeeId}) - ${attendance.punchInTime.toISOString()}`);
        });
        
        // Step 5: Try to test getCurrentPositions logic
        console.log('\n📋 Step 5: Testing getCurrentPositions logic...');
        
        if (columnExists) {
            try {
                // Test the logic that's failing in production
                const testResult = await prisma.salesmanRouteLog.findFirst({
                    where: {
                        attendanceId: activeAttendances[0]?.id || 'test'
                    },
                    orderBy: {
                        recordedAt: 'desc'
                    }
                });
                
                console.log('✅ getCurrentPositions logic test passed');
                console.log(`   - Found route point: ${testResult ? 'Yes' : 'No'}`);
                
            } catch (error) {
                console.log('❌ getCurrentPositions logic test failed:', error.message);
            }
        } else {
            console.log('⚠️ Cannot test getCurrentPositions - isHomeLocation column missing');
        }
        
        // Step 6: Summary and recommendations
        console.log('\n📋 Summary:');
        console.log('=' .repeat(50));
        
        if (columnExists) {
            console.log('✅ Database is properly configured');
            console.log('✅ isHomeLocation column exists');
            console.log('✅ getCurrentPositions should work');
            console.log('✅ Route visualization should work');
            
            console.log('\n🎯 Next steps:');
            console.log('   1. Test the admin live tracking screen');
            console.log('   2. Check WebSocket connections');
            console.log('   3. Verify route lines appear on map');
            
        } else {
            console.log('❌ Database needs migration');
            console.log('❌ isHomeLocation column is missing');
            console.log('❌ getCurrentPositions will fail');
            console.log('❌ Route visualization will not work');
            
            console.log('\n🔧 Required fix:');
            console.log('   Run this SQL command on the production database:');
            console.log('   ALTER TABLE "SalesmanRouteLog" ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false;');
            console.log('   CREATE INDEX "SalesmanRouteLog_isHomeLocation_idx" ON "SalesmanRouteLog"("isHomeLocation");');
            
            console.log('\n💡 Alternative solutions:');
            console.log('   1. Deploy the migration API endpoint and call it');
            console.log('   2. Run the migration script directly on the server');
            console.log('   3. Use Prisma migrate deploy command');
        }
        
    } catch (error) {
        console.error('❌ Database check failed:', error);
        console.log('\n🔍 Error details:');
        console.log('   Code:', error.code);
        console.log('   Message:', error.message);
        
        if (error.code === 'P2010') {
            console.log('\n💡 Database connection failed. Check DATABASE_URL environment variable.');
        }
    } finally {
        await prisma.$disconnect();
    }
}

// Run the check
console.log('🔍 Production Database Status Check');
console.log('=' .repeat(40));

checkProductionDatabase();