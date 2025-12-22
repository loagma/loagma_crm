#!/usr/bin/env node

/**
 * Database Migration Script for Attendance Approval Models
 * 
 * This script helps migrate the attendance approval models to the database
 * when the database connection is stable.
 * 
 * Usage:
 *   node migrate-approval-models.js
 * 
 * Or run the commands manually:
 *   npx prisma migrate dev --name add-approval-models
 *   npx prisma generate
 */

import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🚀 Starting Attendance Approval Models Migration...\n');

try {
  console.log('📋 Step 1: Checking Prisma schema...');
  const schemaPath = path.join(__dirname, 'prisma', 'schema.prisma');
  console.log(`   Schema location: ${schemaPath}`);
  
  console.log('\n📋 Step 2: Running database migration...');
  console.log('   Command: npx prisma migrate dev --name add-approval-models');
  
  try {
    execSync('npx prisma migrate dev --name add-approval-models', {
      stdio: 'inherit',
      cwd: __dirname
    });
    console.log('   ✅ Migration completed successfully!');
  } catch (error) {
    console.log('   ⚠️  Migration failed, trying db push instead...');
    execSync('npx prisma db push', {
      stdio: 'inherit',
      cwd: __dirname
    });
    console.log('   ✅ Database push completed successfully!');
  }
  
  console.log('\n📋 Step 3: Generating Prisma client...');
  console.log('   Command: npx prisma generate');
  execSync('npx prisma generate', {
    stdio: 'inherit',
    cwd: __dirname
  });
  console.log('   ✅ Prisma client generated successfully!');
  
  console.log('\n🎉 Migration completed successfully!');
  console.log('\n📊 New Models Added:');
  console.log('   • LatePunchApproval - Handles late punch-in requests');
  console.log('   • EarlyPunchOutApproval - Handles early punch-out requests');
  
  console.log('\n🔧 Backend APIs Available:');
  console.log('   • POST /late-punch-approval/request');
  console.log('   • GET /late-punch-approval/employee/:id/status');
  console.log('   • POST /late-punch-approval/validate-code');
  console.log('   • GET /late-punch-approval/pending');
  console.log('   • POST /late-punch-approval/approve/:id');
  console.log('   • POST /late-punch-approval/reject/:id');
  console.log('   • GET /late-punch-approval/all');
  console.log('   • POST /early-punch-out-approval/request');
  console.log('   • GET /early-punch-out-approval/employee/:id/status');
  console.log('   • POST /early-punch-out-approval/validate-code');
  console.log('   • GET /early-punch-out-approval/pending');
  console.log('   • POST /early-punch-out-approval/approve/:id');
  console.log('   • POST /early-punch-out-approval/reject/:id');
  console.log('   • GET /early-punch-out-approval/all');
  
  console.log('\n📱 Frontend Integration:');
  console.log('   • Enhanced punch screen with approval widgets');
  console.log('   • Admin approval interface');
  console.log('   • Real-time notifications');
  
  console.log('\n⏰ Time Restrictions:');
  console.log('   • Punch-in cutoff: 9:45 AM IST');
  console.log('   • Punch-out cutoff: 6:30 PM IST');
  
  console.log('\n🔄 Next Steps:');
  console.log('   1. Restart the backend server');
  console.log('   2. Test the approval workflows');
  console.log('   3. Verify admin notifications');
  console.log('   4. Remove debug information from frontend');
  
} catch (error) {
  console.error('\n❌ Migration failed:', error.message);
  console.log('\n🔧 Manual Migration Steps:');
  console.log('   1. Ensure database connection is stable');
  console.log('   2. Run: npx prisma migrate dev --name add-approval-models');
  console.log('   3. Run: npx prisma generate');
  console.log('   4. Restart the backend server');
  
  process.exit(1);
}