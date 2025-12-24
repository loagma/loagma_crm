import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function runWorkingHoursMigration() {
    try {
        console.log('🚀 Starting working hours migration...');

        // Check if columns exist and add them if they don't
        const columns = [
            { name: 'workStartTime', type: 'TEXT', defaultValue: '09:00:00' },
            { name: 'workEndTime', type: 'TEXT', defaultValue: '18:00:00' },
            { name: 'latePunchInGraceMinutes', type: 'INTEGER', defaultValue: 45 },
            { name: 'earlyPunchOutGraceMinutes', type: 'INTEGER', defaultValue: 30 }
        ];

        for (const column of columns) {
            try {
                console.log(`📝 Adding column ${column.name}...`);
                await prisma.$executeRawUnsafe(
                    `ALTER TABLE "User" ADD COLUMN "${column.name}" ${column.type} DEFAULT '${column.defaultValue}'`
                );
                console.log(`✅ Column ${column.name} added successfully`);
            } catch (error) {
                if (error.message.includes('already exists')) {
                    console.log(`ℹ️ Column ${column.name} already exists, skipping`);
                } else {
                    console.log(`⚠️ Error adding column ${column.name}:`, error.message);
                }
            }
        }

        // Update existing users with default working hours where NULL
        console.log('📝 Updating existing users with default working hours...');
        
        const updateQueries = [
            `UPDATE "User" SET "workStartTime" = '09:00:00' WHERE "workStartTime" IS NULL`,
            `UPDATE "User" SET "workEndTime" = '18:00:00' WHERE "workEndTime" IS NULL`,
            `UPDATE "User" SET "latePunchInGraceMinutes" = 45 WHERE "latePunchInGraceMinutes" IS NULL`,
            `UPDATE "User" SET "earlyPunchOutGraceMinutes" = 30 WHERE "earlyPunchOutGraceMinutes" IS NULL`
        ];

        for (const query of updateQueries) {
            try {
                const result = await prisma.$executeRawUnsafe(query);
                console.log(`✅ Updated ${result} users`);
            } catch (error) {
                console.log(`⚠️ Update query failed:`, error.message);
            }
        }

        console.log('✅ Working hours migration completed successfully!');

        // Verify the migration by checking a few users
        const sampleUsers = await prisma.user.findMany({
            take: 3,
            select: {
                id: true,
                name: true,
                workStartTime: true,
                workEndTime: true,
                latePunchInGraceMinutes: true,
                earlyPunchOutGraceMinutes: true
            }
        });

        console.log('📊 Sample users with working hours:');
        sampleUsers.forEach(user => {
            console.log(`  - ${user.name}: ${user.workStartTime} - ${user.workEndTime} (Grace: +${user.latePunchInGraceMinutes}min, -${user.earlyPunchOutGraceMinutes}min)`);
        });

    } catch (error) {
        console.error('❌ Migration failed:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
runWorkingHoursMigration()
    .then(() => {
        console.log('🎉 Migration process completed!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Migration process failed:', error);
        process.exit(1);
    });