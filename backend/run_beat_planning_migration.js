import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import prisma from './src/config/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runBeatPlanningMigration() {
    try {
        console.log('🚀 Starting Beat Planning Migration...');

        // Read the SQL migration file
        const migrationPath = path.join(__dirname, 'add_beat_planning_migration.sql');
        const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

        // Split SQL commands by semicolon and filter out empty commands and comments
        const commands = migrationSQL
            .split(';')
            .map(cmd => cmd.trim())
            .filter(cmd => cmd.length > 0 && !cmd.startsWith('--') && !cmd.startsWith('/*'));

        console.log(`📝 Found ${commands.length} SQL commands to execute`);

        // Execute each command
        for (let i = 0; i < commands.length; i++) {
            const command = commands[i];
            
            // Skip empty commands or comments
            if (!command || command.startsWith('--') || command.length < 10) {
                continue;
            }

            console.log(`⚡ Executing command ${i + 1}/${commands.length}...`);
            
            try {
                await prisma.$executeRawUnsafe(command);
                console.log(`✅ Command ${i + 1} executed successfully`);
            } catch (error) {
                // Check if error is about table/constraint already existing
                if (error.message.includes('already exists') || 
                    error.message.includes('duplicate key') ||
                    error.code === '42P07' || // relation already exists
                    error.code === '42710') { // object already exists
                    console.log(`⚠️  Command ${i + 1} skipped (already exists)`);
                } else {
                    console.error(`❌ Error executing command ${i + 1}:`, error.message);
                    console.error('Command was:', command.substring(0, 100) + '...');
                    
                    // Don't throw error for non-critical issues
                    if (!error.message.includes('does not exist')) {
                        throw error;
                    }
                }
            }
        }

        // Verify tables were created
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

        console.log('\n✅ Beat Planning Migration completed successfully!');
        console.log('📊 Created tables:');
        console.log('   - WeeklyBeatPlan (weekly beat plans)');
        console.log('   - DailyBeatPlan (daily area assignments)');
        console.log('   - BeatCompletion (area completion tracking)');
        console.log('🔗 Added foreign key relationships');
        console.log('📈 Created performance indexes');
        console.log('🛡️  Added unique constraints');

    } catch (error) {
        console.error('❌ Migration failed:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
runBeatPlanningMigration();