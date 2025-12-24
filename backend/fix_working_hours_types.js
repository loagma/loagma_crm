import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function fixWorkingHoursTypes() {
    try {
        console.log('🔧 Fixing working hours column types...');

        // Convert TIME columns to TEXT and update values
        const queries = [
            `ALTER TABLE "User" ALTER COLUMN "workStartTime" TYPE TEXT`,
            `ALTER TABLE "User" ALTER COLUMN "workEndTime" TYPE TEXT`,
            `UPDATE "User" SET "workStartTime" = '09:00:00' WHERE "workStartTime" IS NOT NULL`,
            `UPDATE "User" SET "workEndTime" = '18:00:00' WHERE "workEndTime" IS NOT NULL`
        ];

        for (const query of queries) {
            try {
                console.log(`📝 Executing: ${query}`);
                await prisma.$executeRawUnsafe(query);
                console.log('✅ Success');
            } catch (error) {
                console.log(`⚠️ Query failed:`, error.message);
            }
        }

        console.log('✅ Working hours types fixed!');

        // Test by fetching a user
        const testUser = await prisma.user.findFirst({
            select: {
                id: true,
                name: true,
                workStartTime: true,
                workEndTime: true,
                latePunchInGraceMinutes: true,
                earlyPunchOutGraceMinutes: true
            }
        });

        console.log('📊 Test user:', testUser);

    } catch (error) {
        console.error('❌ Fix failed:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

// Run the fix
fixWorkingHoursTypes()
    .then(() => {
        console.log('🎉 Fix completed!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Fix failed:', error);
        process.exit(1);
    });