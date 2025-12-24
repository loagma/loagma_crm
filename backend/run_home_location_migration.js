#!/usr/bin/env node

/**
 * Migration Script: Add isHomeLocation column to SalesmanRouteLog
 * 
 * This script fixes the database schema mismatch where the Prisma schema
 * defines isHomeLocation but the production database doesn't have this column.
 * 
 * Usage:
 *   node run_home_location_migration.js
 * 
 * Or via npm:
 *   npm run migrate:home-location
 */

import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const prisma = new PrismaClient();

async function runMigration() {
    try {
        console.log('🚀 Starting isHomeLocation column migration...');
        
        // Read the SQL migration file
        const sqlPath = path.join(__dirname, 'add_home_location_column_migration.sql');
        const migrationSQL = fs.readFileSync(sqlPath, 'utf8');
        
        // Split SQL commands (remove comments and empty lines)
        const commands = migrationSQL
            .split(';')
            .map(cmd => cmd.trim())
            .filter(cmd => cmd && !cmd.startsWith('--'));
        
        console.log(`📝 Executing ${commands.length} SQL commands...`);
        
        // Execute each command
        for (let i = 0; i < commands.length; i++) {
            const command = commands[i];
            if (command) {
                console.log(`⚡ Executing command ${i + 1}/${commands.length}...`);
                await prisma.$executeRawUnsafe(command);
            }
        }
        
        // Verify the migration worked
        console.log('🔍 Verifying migration...');
        
        const result = await prisma.$queryRaw`
            SELECT 
                COUNT(*) as total_records,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
                COUNT(DISTINCT "attendanceId") as unique_attendance_sessions
            FROM "SalesmanRouteLog"
        `;
        
        console.log('✅ Migration completed successfully!');
        console.log('📊 Migration Results:');
        console.log(`   - Total route records: ${result[0].total_records}`);
        console.log(`   - Home locations marked: ${result[0].home_locations}`);
        console.log(`   - Unique attendance sessions: ${result[0].unique_attendance_sessions}`);
        
        // Test that the column now works
        console.log('🧪 Testing column access...');
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
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        
        if (error.code === 'P2010') {
            console.log('💡 This might be a connection issue. Make sure your DATABASE_URL is correct.');
        } else if (error.message.includes('column "isHomeLocation" of relation "SalesmanRouteLog" already exists')) {
            console.log('✅ Column already exists! Migration may have been run before.');
            
            // Still verify it works
            try {
                const testQuery = await prisma.salesmanRouteLog.findFirst({
                    select: { id: true, isHomeLocation: true }
                });
                console.log('✅ Column is working correctly!');
            } catch (testError) {
                console.error('❌ Column exists but not accessible:', testError);
            }
        }
        
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
runMigration();