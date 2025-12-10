#!/usr/bin/env node

/**
 * Database Migration Script: User ID Consistency
 * 
 * This script helps migrate existing users with random UUIDs to sequential IDs
 * and ensures consistency in the database.
 */

import prisma from '../src/config/db.js';
import { generateSequentialUserId, generateSequentialEmployeeCode } from '../src/utils/idGenerator.js';
import { config } from 'dotenv';

config();

console.log('🔄 User ID Migration Script');
console.log('===========================');

// Helper function to check if a string is a UUID
function isUUID(str) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}

// Helper function to check if a string is already in sequential format
function isSequentialId(str) {
  return /^\d{5}$/.test(str);
}

// Analyze current database state
async function analyzeDatabase() {
  console.log('🔍 Analyzing current database state...');
  console.log('');

  try {
    const allUsers = await prisma.user.findMany({
      select: { 
        id: true, 
        employeeCode: true, 
        name: true, 
        contactNumber: true,
        createdAt: true 
      },
      orderBy: { createdAt: 'asc' }
    });

    console.log(`📊 Total users in database: ${allUsers.length}`);
    console.log('');

    // Categorize users by ID type
    const sequentialIds = [];
    const uuidIds = [];
    const otherIds = [];

    const sequentialEmployeeCodes = [];
    const nullEmployeeCodes = [];
    const otherEmployeeCodes = [];

    allUsers.forEach(user => {
      // Analyze user IDs
      if (isSequentialId(user.id)) {
        sequentialIds.push(user);
      } else if (isUUID(user.id)) {
        uuidIds.push(user);
      } else {
        otherIds.push(user);
      }

      // Analyze employee codes
      if (!user.employeeCode) {
        nullEmployeeCodes.push(user);
      } else if (isSequentialId(user.employeeCode)) {
        sequentialEmployeeCodes.push(user);
      } else {
        otherEmployeeCodes.push(user);
      }
    });

    console.log('📋 USER ID ANALYSIS:');
    console.log(`   ✅ Sequential IDs (00001 format): ${sequentialIds.length}`);
    console.log(`   🔀 UUID IDs (random): ${uuidIds.length}`);
    console.log(`   ❓ Other ID formats: ${otherIds.length}`);
    console.log('');

    console.log('📋 EMPLOYEE CODE ANALYSIS:');
    console.log(`   ✅ Sequential codes (00001 format): ${sequentialEmployeeCodes.length}`);
    console.log(`   ❌ Null/missing codes: ${nullEmployeeCodes.length}`);
    console.log(`   ❓ Other code formats: ${otherEmployeeCodes.length}`);
    console.log('');

    // Show examples
    if (sequentialIds.length > 0) {
      console.log('✅ SEQUENTIAL ID EXAMPLES:');
      sequentialIds.slice(0, 3).forEach(user => {
        console.log(`   ${user.id} | ${user.employeeCode || 'NULL'} | ${user.name || 'No Name'}`);
      });
      console.log('');
    }

    if (uuidIds.length > 0) {
      console.log('🔀 UUID ID EXAMPLES:');
      uuidIds.slice(0, 3).forEach(user => {
        console.log(`   ${user.id} | ${user.employeeCode || 'NULL'} | ${user.name || 'No Name'}`);
      });
      console.log('');
    }

    return {
      total: allUsers.length,
      sequentialIds,
      uuidIds,
      otherIds,
      sequentialEmployeeCodes,
      nullEmployeeCodes,
      otherEmployeeCodes
    };

  } catch (error) {
    console.error('❌ Error analyzing database:', error);
    throw error;
  }
}

// Migrate UUID users to sequential IDs
async function migrateUuidUsers(uuidUsers) {
  console.log('🔄 Starting UUID to Sequential ID migration...');
  console.log(`📝 Will migrate ${uuidUsers.length} users`);
  console.log('');

  if (uuidUsers.length === 0) {
    console.log('✅ No UUID users to migrate');
    return [];
  }

  const migrationResults = [];

  for (let i = 0; i < uuidUsers.length; i++) {
    const user = uuidUsers[i];
    
    try {
      console.log(`🔄 Migrating user ${i + 1}/${uuidUsers.length}: ${user.name || 'No Name'}`);
      console.log(`   Old ID: ${user.id}`);

      // Generate new sequential IDs
      const newUserId = await generateSequentialUserId();
      const newEmployeeCode = user.employeeCode && isSequentialId(user.employeeCode) 
        ? user.employeeCode 
        : await generateSequentialEmployeeCode();

      console.log(`   New ID: ${newUserId}`);
      console.log(`   Employee Code: ${newEmployeeCode}`);

      // Update user with new IDs
      const updatedUser = await prisma.user.update({
        where: { id: user.id },
        data: {
          id: newUserId,
          employeeCode: newEmployeeCode,
        },
      });

      migrationResults.push({
        oldId: user.id,
        newId: newUserId,
        employeeCode: newEmployeeCode,
        name: user.name,
        success: true
      });

      console.log(`   ✅ Migration successful`);
      console.log('');

    } catch (error) {
      console.error(`   ❌ Migration failed: ${error.message}`);
      migrationResults.push({
        oldId: user.id,
        newId: null,
        employeeCode: null,
        name: user.name,
        success: false,
        error: error.message
      });
      console.log('');
    }
  }

  return migrationResults;
}

// Fix missing employee codes
async function fixMissingEmployeeCodes(usersWithoutCodes) {
  console.log('🔧 Fixing missing employee codes...');
  console.log(`📝 Will fix ${usersWithoutCodes.length} users`);
  console.log('');

  if (usersWithoutCodes.length === 0) {
    console.log('✅ No missing employee codes to fix');
    return [];
  }

  const fixResults = [];

  for (let i = 0; i < usersWithoutCodes.length; i++) {
    const user = usersWithoutCodes[i];
    
    try {
      console.log(`🔧 Fixing user ${i + 1}/${usersWithoutCodes.length}: ${user.name || 'No Name'}`);
      console.log(`   User ID: ${user.id}`);

      // Generate new employee code
      const newEmployeeCode = await generateSequentialEmployeeCode();
      console.log(`   New Employee Code: ${newEmployeeCode}`);

      // Update user with new employee code
      await prisma.user.update({
        where: { id: user.id },
        data: { employeeCode: newEmployeeCode },
      });

      fixResults.push({
        userId: user.id,
        employeeCode: newEmployeeCode,
        name: user.name,
        success: true
      });

      console.log(`   ✅ Fix successful`);
      console.log('');

    } catch (error) {
      console.error(`   ❌ Fix failed: ${error.message}`);
      fixResults.push({
        userId: user.id,
        employeeCode: null,
        name: user.name,
        success: false,
        error: error.message
      });
      console.log('');
    }
  }

  return fixResults;
}

// Main migration function
async function runMigration() {
  console.log('🚀 Starting User ID Migration');
  console.log('==============================');
  console.log('');

  try {
    // Step 1: Analyze current state
    const analysis = await analyzeDatabase();

    // Step 2: Ask for confirmation if there are UUIDs to migrate
    if (analysis.uuidIds.length > 0) {
      console.log('⚠️  WARNING: This will modify user IDs in the database!');
      console.log('   Make sure you have a backup before proceeding.');
      console.log('');
      console.log(`📝 Migration Plan:`);
      console.log(`   • Migrate ${analysis.uuidIds.length} UUID users to sequential IDs`);
      console.log(`   • Fix ${analysis.nullEmployeeCodes.length} missing employee codes`);
      console.log('');

      // In a real scenario, you'd want user confirmation here
      // For now, we'll proceed automatically
      console.log('🔄 Proceeding with migration...');
      console.log('');

      // Step 3: Migrate UUID users
      const migrationResults = await migrateUuidUsers(analysis.uuidIds);

      // Step 4: Fix missing employee codes
      const fixResults = await fixMissingEmployeeCodes(analysis.nullEmployeeCodes);

      // Step 5: Final analysis
      console.log('📊 MIGRATION RESULTS');
      console.log('===================');
      
      const successfulMigrations = migrationResults.filter(r => r.success).length;
      const failedMigrations = migrationResults.filter(r => !r.success).length;
      
      const successfulFixes = fixResults.filter(r => r.success).length;
      const failedFixes = fixResults.filter(r => !r.success).length;

      console.log(`✅ Successful ID migrations: ${successfulMigrations}`);
      console.log(`❌ Failed ID migrations: ${failedMigrations}`);
      console.log(`✅ Successful employee code fixes: ${successfulFixes}`);
      console.log(`❌ Failed employee code fixes: ${failedFixes}`);
      console.log('');

      if (failedMigrations > 0 || failedFixes > 0) {
        console.log('❌ Some migrations failed. Check the logs above for details.');
      } else {
        console.log('🎉 All migrations completed successfully!');
      }

      // Step 6: Final database analysis
      console.log('');
      console.log('📊 FINAL DATABASE STATE');
      console.log('======================');
      await analyzeDatabase();

    } else {
      console.log('✅ Database is already consistent!');
      console.log('   All users have sequential IDs in the correct format.');
      
      if (analysis.nullEmployeeCodes.length > 0) {
        console.log('');
        console.log('🔧 Fixing missing employee codes...');
        await fixMissingEmployeeCodes(analysis.nullEmployeeCodes);
      }
    }

  } catch (error) {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }

  console.log('');
  console.log('🏁 Migration completed');
}

// Run the migration
runMigration();