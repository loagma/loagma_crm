/**
 * Migration script to fix existing attendance records with timezone issues
 * This converts IST timestamps that were stored as UTC back to proper UTC
 */

import { PrismaClient } from '@prisma/client';
import { convertISTToUTC } from './src/utils/timezone.js';

const prisma = new PrismaClient();

async function fixTimezoneData() {
    console.log('🔧 Starting timezone fix migration...');

    try {
        // Get all attendance records
        const attendances = await prisma.attendance.findMany({
            orderBy: { createdAt: 'desc' }
        });

        console.log(`📊 Found ${attendances.length} attendance records to check`);

        let fixedCount = 0;

        for (const attendance of attendances) {
            // Check if this record needs fixing by comparing with createdAt
            // If punchInTime is significantly different from createdAt, it might need fixing
            const timeDiff = Math.abs(attendance.punchInTime.getTime() - attendance.createdAt.getTime());
            const hoursDiff = timeDiff / (1000 * 60 * 60);

            // If the difference is around 5.5 hours, this record likely needs fixing
            if (hoursDiff >= 5 && hoursDiff <= 6) {
                console.log(`🔍 Checking record ${attendance.id}:`);
                console.log(`  Original punchInTime: ${attendance.punchInTime.toISOString()}`);
                console.log(`  CreatedAt: ${attendance.createdAt.toISOString()}`);
                console.log(`  Time difference: ${hoursDiff.toFixed(2)} hours`);

                // Convert the IST time (stored as UTC) back to proper UTC
                const correctedPunchInTime = convertISTToUTC(attendance.punchInTime);
                const correctedDate = convertISTToUTC(attendance.date);

                let updateData = {
                    punchInTime: correctedPunchInTime,
                    date: correctedDate
                };

                // Also fix punchOutTime if it exists
                if (attendance.punchOutTime) {
                    const correctedPunchOutTime = convertISTToUTC(attendance.punchOutTime);
                    updateData.punchOutTime = correctedPunchOutTime;
                    console.log(`  Original punchOutTime: ${attendance.punchOutTime.toISOString()}`);
                    console.log(`  Corrected punchOutTime: ${correctedPunchOutTime.toISOString()}`);
                }

                console.log(`  Corrected punchInTime: ${correctedPunchInTime.toISOString()}`);
                console.log(`  Corrected date: ${correctedDate.toISOString()}`);

                // Update the record
                await prisma.attendance.update({
                    where: { id: attendance.id },
                    data: updateData
                });

                fixedCount++;
                console.log(`  ✅ Fixed record ${attendance.id}`);
            }
        }

        console.log(`\n🎉 Migration completed!`);
        console.log(`📊 Fixed ${fixedCount} out of ${attendances.length} records`);

    } catch (error) {
        console.error('❌ Migration failed:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

// Run the migration
fixTimezoneData()
    .then(() => {
        console.log('✅ Timezone fix migration completed successfully');
        process.exit(0);
    })
    .catch((error) => {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    });