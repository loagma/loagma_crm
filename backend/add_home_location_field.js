import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function addHomeLocationField() {
    try {
        console.log('🔄 Adding isHomeLocation field to SalesmanRouteLog table...');

        // Add the isHomeLocation column with default false
        await prisma.$executeRaw`
            ALTER TABLE "SalesmanRouteLog" 
            ADD COLUMN IF NOT EXISTS "isHomeLocation" BOOLEAN DEFAULT false;
        `;

        console.log('✅ Successfully added isHomeLocation field');

        // Create index for better performance
        await prisma.$executeRaw`
            CREATE INDEX IF NOT EXISTS "SalesmanRouteLog_isHomeLocation_idx" 
            ON "SalesmanRouteLog"("isHomeLocation");
        `;

        console.log('✅ Successfully created index for isHomeLocation');

        // Mark first route point of each attendance as home location
        console.log('🔄 Marking first route points as home locations...');

        const result = await prisma.$executeRaw`
            UPDATE "SalesmanRouteLog" 
            SET "isHomeLocation" = true 
            WHERE id IN (
                SELECT DISTINCT ON ("attendanceId") id 
                FROM "SalesmanRouteLog" 
                ORDER BY "attendanceId", "recordedAt" ASC
            );
        `;

        console.log(`✅ Updated ${result} route points as home locations`);

        console.log('🎉 Migration completed successfully!');

    } catch (error) {
        console.error('❌ Error during migration:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
addHomeLocationField()
    .then(() => {
        console.log('✅ Migration script completed');
        process.exit(0);
    })
    .catch((error) => {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    });