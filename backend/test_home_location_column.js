#!/usr/bin/env node

/**
 * Test Script: Verify isHomeLocation column exists and works
 * 
 * This script tests if the isHomeLocation column exists in the SalesmanRouteLog table
 * and can be queried properly.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testColumn() {
    try {
        console.log('🧪 Testing isHomeLocation column...');
        
        // Test 1: Check if we can query the column
        console.log('📋 Test 1: Basic column query...');
        const allRecords = await prisma.salesmanRouteLog.findMany({
            select: {
                id: true,
                isHomeLocation: true,
                recordedAt: true,
                attendanceId: true
            },
            take: 5
        });
        
        console.log(`✅ Found ${allRecords.length} route records`);
        if (allRecords.length > 0) {
            console.log('📄 Sample records:');
            allRecords.forEach((record, index) => {
                console.log(`   ${index + 1}. ID: ${record.id}, Home: ${record.isHomeLocation}, Date: ${record.recordedAt.toISOString()}`);
            });
        }
        
        // Test 2: Check home locations specifically
        console.log('\n📋 Test 2: Home location query...');
        const homeLocations = await prisma.salesmanRouteLog.findMany({
            where: { isHomeLocation: true },
            select: {
                id: true,
                attendanceId: true,
                recordedAt: true,
                employee: {
                    select: { name: true }
                }
            },
            take: 5
        });
        
        console.log(`✅ Found ${homeLocations.length} home location records`);
        if (homeLocations.length > 0) {
            console.log('🏠 Home locations:');
            homeLocations.forEach((record, index) => {
                console.log(`   ${index + 1}. Employee: ${record.employee.name}, Attendance: ${record.attendanceId}, Date: ${record.recordedAt.toISOString()}`);
            });
        }
        
        // Test 3: Check database schema
        console.log('\n📋 Test 3: Database schema check...');
        const schemaInfo = await prisma.$queryRaw`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'SalesmanRouteLog' 
            AND column_name = 'isHomeLocation'
        `;
        
        if (schemaInfo.length > 0) {
            console.log('✅ Column exists in database schema:');
            console.log(`   - Name: ${schemaInfo[0].column_name}`);
            console.log(`   - Type: ${schemaInfo[0].data_type}`);
            console.log(`   - Nullable: ${schemaInfo[0].is_nullable}`);
            console.log(`   - Default: ${schemaInfo[0].column_default}`);
        } else {
            console.log('❌ Column NOT found in database schema!');
        }
        
        // Test 4: Statistics
        console.log('\n📋 Test 4: Route statistics...');
        const stats = await prisma.$queryRaw`
            SELECT 
                COUNT(*) as total_routes,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
                COUNT(DISTINCT "attendanceId") as unique_sessions,
                COUNT(DISTINCT "employeeId") as unique_employees
            FROM "SalesmanRouteLog"
        `;
        
        if (stats.length > 0) {
            const stat = stats[0];
            console.log('📊 Route Statistics:');
            console.log(`   - Total route points: ${stat.total_routes}`);
            console.log(`   - Home locations: ${stat.home_locations}`);
            console.log(`   - Unique sessions: ${stat.unique_sessions}`);
            console.log(`   - Unique employees: ${stat.unique_employees}`);
            
            if (stat.total_routes > 0 && stat.home_locations === 0) {
                console.log('⚠️ Warning: Route points exist but no home locations marked!');
                console.log('💡 Consider running the migration to mark home locations.');
            }
        }
        
        console.log('\n✅ All tests completed successfully!');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
        
        if (error.code === 'P2021' || error.message.includes('does not exist')) {
            console.log('💡 The isHomeLocation column does not exist in the database.');
            console.log('🔧 Run the migration script: node run_home_location_migration.js');
        }
        
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the test
testColumn();