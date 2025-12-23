import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

async function runMigration() {
    try {
        console.log('🔄 Starting home location migration...');
        
        // Read the SQL migration file
        const migrationSQL = fs.readFileSync(
            path.join(process.cwd(), 'add_home_location_migration.sql'),
            'utf8'
        );
        
        // Split SQL commands and execute them
        const commands = migrationSQL
            .split(';')
            .map(cmd => cmd.trim())
            .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));
        
        for (const command of commands) {
            if (command.trim()) {
                console.log(`📝 Executing: ${command.substring(0, 50)}...`);
                await prisma.$executeRawUnsafe(command);
            }
        }
        
        // Verify the migration worked
        const result = await prisma.$queryRaw`
            SELECT 
                COUNT(*) as total_points,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations
            FROM "SalesmanRouteLog"
        `;
        
        console.log('✅ Migration completed successfully!');
        console.log('📊 Results:', result[0]);
        
        // Test that the column exists by running a simple query
        const testQuery = await prisma.salesmanRouteLog.findFirst({
            select: {
                id: true,
                isHomeLocation: true
            }
        });
        
        console.log('✅ Column verification successful');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
runMigration();