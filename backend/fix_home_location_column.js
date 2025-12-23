import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function fixHomeLocationColumn() {
    try {
        console.log('🔄 Checking if isHomeLocation column exists...');
        
        // Try to query the column to see if it exists
        try {
            await prisma.$queryRaw`SELECT "isHomeLocation" FROM "SalesmanRouteLog" LIMIT 1`;
            console.log('✅ Column already exists, no migration needed');
            return;
        } catch (error) {
            if (error.message.includes('does not exist')) {
                console.log('📝 Column does not exist, adding it...');
            } else {
                throw error;
            }
        }
        
        // Add the column
        console.log('🔧 Adding isHomeLocation column...');
        await prisma.$executeRaw`
            ALTER TABLE "SalesmanRouteLog" 
            ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false
        `;
        
        // Create index
        console.log('📊 Creating index...');
        await prisma.$executeRaw`
            CREATE INDEX "SalesmanRouteLog_isHomeLocation_idx" 
            ON "SalesmanRouteLog"("isHomeLocation")
        `;
        
        // Update existing records to mark first point as home location
        console.log('🏠 Marking first GPS points as home locations...');
        await prisma.$executeRaw`
            WITH first_points AS (
                SELECT DISTINCT ON ("attendanceId") 
                    "id",
                    "attendanceId",
                    "recordedAt"
                FROM "SalesmanRouteLog"
                ORDER BY "attendanceId", "recordedAt" ASC
            )
            UPDATE "SalesmanRouteLog" 
            SET "isHomeLocation" = true
            WHERE "id" IN (SELECT "id" FROM first_points)
        `;
        
        // Verify the results
        const result = await prisma.$queryRaw`
            SELECT 
                COUNT(*)::int as total_points,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true)::int as home_locations
            FROM "SalesmanRouteLog"
        `;
        
        console.log('✅ Migration completed successfully!');
        console.log('📊 Results:', result[0]);
        
        // Test the column works with Prisma
        const testQuery = await prisma.salesmanRouteLog.findFirst({
            select: {
                id: true,
                isHomeLocation: true,
                employeeId: true,
                attendanceId: true
            }
        });
        
        console.log('✅ Prisma query test successful');
        if (testQuery) {
            console.log('📍 Sample record:', {
                id: testQuery.id,
                isHomeLocation: testQuery.isHomeLocation,
                employeeId: testQuery.employeeId
            });
        }
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the fix
fixHomeLocationColumn();