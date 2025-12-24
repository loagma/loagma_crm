import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

/**
 * POST /api/migration/add-home-location-column
 * 
 * Safely adds the isHomeLocation column to SalesmanRouteLog table
 * This endpoint can be called to fix the production database
 */
router.post('/add-home-location-column', async (req, res) => {
    try {
        console.log('🚀 Starting database migration via API...');
        
        // Check if column already exists
        let columnExists = false;
        try {
            await prisma.$queryRaw`
                SELECT "isHomeLocation" 
                FROM "SalesmanRouteLog" 
                LIMIT 1
            `;
            columnExists = true;
        } catch (error) {
            if (error.message.includes('does not exist') || error.code === 'P2021') {
                columnExists = false;
            } else {
                throw error;
            }
        }
        
        if (columnExists) {
            return res.status(200).json({
                success: true,
                message: 'Column already exists! No migration needed.',
                alreadyExists: true
            });
        }
        
        // Add the column
        await prisma.$executeRaw`
            ALTER TABLE "SalesmanRouteLog" 
            ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false
        `;
        
        // Create index
        try {
            await prisma.$executeRaw`
                CREATE INDEX "SalesmanRouteLog_isHomeLocation_idx" 
                ON "SalesmanRouteLog"("isHomeLocation")
            `;
        } catch (indexError) {
            console.log('Index creation warning:', indexError.message);
        }
        
        // Mark existing first points as home locations
        const updateResult = await prisma.$executeRaw`
            UPDATE "SalesmanRouteLog" 
            SET "isHomeLocation" = true 
            WHERE id IN (
                SELECT DISTINCT ON ("attendanceId") id 
                FROM "SalesmanRouteLog" 
                ORDER BY "attendanceId", "recordedAt" ASC
            )
        `;
        
        // Get statistics
        const stats = await prisma.$queryRaw`
            SELECT 
                COUNT(*) as total_records,
                COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
                COUNT(DISTINCT "attendanceId") as unique_sessions
            FROM "SalesmanRouteLog"
        `;
        
        // Test column access
        const testQuery = await prisma.salesmanRouteLog.findFirst({
            where: { isHomeLocation: true },
            select: { id: true, isHomeLocation: true }
        });
        
        console.log('✅ Database migration completed successfully via API');
        
        res.status(200).json({
            success: true,
            message: 'Database migration completed successfully!',
            results: {
                columnAdded: true,
                homeLocationsMarked: Number(updateResult),
                statistics: stats[0],
                testPassed: testQuery !== null
            }
        });
        
    } catch (error) {
        console.error('❌ Migration API error:', error);
        
        res.status(500).json({
            success: false,
            message: 'Migration failed',
            error: {
                code: error.code,
                message: error.message,
                details: process.env.NODE_ENV === 'development' ? error.stack : undefined
            }
        });
    }
});

/**
 * GET /api/migration/check-schema
 * 
 * Checks the current database schema status
 */
router.get('/check-schema', async (req, res) => {
    try {
        // Check if isHomeLocation column exists
        let columnExists = false;
        let columnInfo = null;
        
        try {
            const schemaInfo = await prisma.$queryRaw`
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'SalesmanRouteLog' 
                AND column_name = 'isHomeLocation'
            `;
            
            if (schemaInfo.length > 0) {
                columnExists = true;
                columnInfo = schemaInfo[0];
            }
        } catch (error) {
            console.log('Schema check error:', error.message);
        }
        
        // Get route statistics
        let routeStats = null;
        if (columnExists) {
            try {
                const stats = await prisma.$queryRaw`
                    SELECT 
                        COUNT(*) as total_records,
                        COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
                        COUNT(DISTINCT "attendanceId") as unique_sessions,
                        COUNT(DISTINCT "employeeId") as unique_employees
                    FROM "SalesmanRouteLog"
                `;
                routeStats = stats[0];
            } catch (error) {
                console.log('Route stats error:', error.message);
            }
        }
        
        // Check active attendances
        const activeAttendances = await prisma.attendance.count({
            where: { status: 'active' }
        });
        
        res.status(200).json({
            success: true,
            schema: {
                isHomeLocationColumnExists: columnExists,
                columnInfo: columnInfo,
                needsMigration: !columnExists
            },
            data: {
                routeStatistics: routeStats,
                activeAttendances: activeAttendances
            },
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ Schema check error:', error);
        
        res.status(500).json({
            success: false,
            message: 'Schema check failed',
            error: error.message
        });
    }
});

export default router;