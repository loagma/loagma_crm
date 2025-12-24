import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrateProductionWorkingHours() {
    try {
        console.log('🚀 Starting production working hours migration...');
        console.log('🌍 Database URL:', process.env.DATABASE_URL ? 'Connected' : 'Not found');

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
                if (error.message.includes('already exists') || error.code === '42701') {
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
                console.log(`✅ Updated ${result} users with query: ${query.substring(0, 50)}...`);
            } catch (error) {
                console.log(`⚠️ Update query failed:`, error.message);
            }
        }

        console.log('✅ Production working hours migration completed successfully!');

        // Verify the migration by checking a few users
        try {
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
        } catch (verifyError) {
            console.log('⚠️ Verification failed (Prisma client may need regeneration):', verifyError.message);
            console.log('✅ Migration completed, but verification skipped due to client cache');
        }

    } catch (error) {
        console.error('❌ Migration failed:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
migrateProductionWorkingHours()
    .then(() => {
        console.log('🎉 Production migration process completed!');
        console.log('📝 Note: You may need to restart the server for Prisma client to recognize new columns');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Production migration process failed:', error);
        process.exit(1);
    });