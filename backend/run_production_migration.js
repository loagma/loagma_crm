#!/usr/bin/env node

/**
 * Run Production Migration via API
 * 
 * This script calls the migration API endpoint to fix the production database
 * without needing direct database access.
 */

const PRODUCTION_URL = 'https://loagma-crm.onrender.com';

async function runProductionMigration() {
    try {
        console.log('🚀 Running production database migration...');
        console.log(`🌍 Target: ${PRODUCTION_URL}`);
        
        // Step 1: Check current schema status
        console.log('\n📋 Step 1: Checking current database schema...');
        
        const checkResponse = await fetch(`${PRODUCTION_URL}/api/migration/check-schema`);
        const checkData = await checkResponse.json();
        
        if (!checkResponse.ok) {
            throw new Error(`Schema check failed: ${checkData.message}`);
        }
        
        console.log('📊 Current Schema Status:');
        console.log(`   - isHomeLocation column exists: ${checkData.schema.isHomeLocationColumnExists ? '✅' : '❌'}`);
        console.log(`   - Needs migration: ${checkData.schema.needsMigration ? '✅' : '❌'}`);
        console.log(`   - Active attendances: ${checkData.data.activeAttendances}`);
        
        if (checkData.data.routeStatistics) {
            const stats = checkData.data.routeStatistics;
            console.log(`   - Total route records: ${stats.total_records}`);
            console.log(`   - Home locations: ${stats.home_locations}`);
            console.log(`   - Unique sessions: ${stats.unique_sessions}`);
        }
        
        if (!checkData.schema.needsMigration) {
            console.log('\n✅ Migration not needed! Column already exists.');
            return;
        }
        
        // Step 2: Run the migration
        console.log('\n📋 Step 2: Running database migration...');
        
        const migrationResponse = await fetch(`${PRODUCTION_URL}/api/migration/add-home-location-column`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const migrationData = await migrationResponse.json();
        
        if (!migrationResponse.ok) {
            throw new Error(`Migration failed: ${migrationData.message}`);
        }
        
        console.log('✅ Migration completed successfully!');
        console.log('📊 Migration Results:');
        console.log(`   - Column added: ${migrationData.results.columnAdded ? '✅' : '❌'}`);
        console.log(`   - Home locations marked: ${migrationData.results.homeLocationsMarked}`);
        console.log(`   - Test passed: ${migrationData.results.testPassed ? '✅' : '❌'}`);
        
        if (migrationData.results.statistics) {
            const stats = migrationData.results.statistics;
            console.log(`   - Total route records: ${stats.total_records}`);
            console.log(`   - Home locations: ${stats.home_locations}`);
            console.log(`   - Unique sessions: ${stats.unique_sessions}`);
        }
        
        // Step 3: Verify the fix
        console.log('\n📋 Step 3: Verifying the fix...');
        
        const verifyResponse = await fetch(`${PRODUCTION_URL}/api/migration/check-schema`);
        const verifyData = await verifyResponse.json();
        
        if (verifyResponse.ok && !verifyData.schema.needsMigration) {
            console.log('✅ Verification passed! Database is now fixed.');
        } else {
            console.log('⚠️ Verification failed. Migration may need to be run again.');
        }
        
        console.log('\n🎉 Production database migration completed!');
        console.log('\n📋 Next Steps:');
        console.log('   1. Test the admin live tracking screen');
        console.log('   2. Check that getCurrentPositions API works without errors');
        console.log('   3. Verify route visualization shows route lines');
        console.log('   4. Test WebSocket live tracking system');
        
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.log('💡 Connection failed. Make sure the production server is running.');
        } else if (error.message.includes('404')) {
            console.log('💡 Migration endpoint not found. Make sure the updated code is deployed.');
        }
        
        process.exit(1);
    }
}

// Run the migration
console.log('🔧 Production Database Migration via API');
console.log('=' .repeat(50));

runProductionMigration();