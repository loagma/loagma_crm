import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkEmployeeIds() {
    try {
        console.log('🔍 Checking employee IDs in attendance records...');

        // Check attendance records for Jan 3, 2026
        const attendanceRecords = await prisma.attendance.findMany({
            where: {
                date: {
                    gte: new Date('2026-01-03T00:00:00.000Z'),
                    lte: new Date('2026-01-03T23:59:59.999Z')
                }
            },
            select: {
                id: true,
                employeeId: true,
                employeeName: true,
                date: true
            }
        });

        console.log(`📊 Found ${attendanceRecords.length} attendance records for Jan 3, 2026:`);
        attendanceRecords.forEach((record, index) => {
            console.log(`${index + 1}. ID: ${record.id}, EmployeeId: "${record.employeeId}", Name: "${record.employeeName}"`);
        });

        // Also check all unique employee IDs
        const allEmployeeIds = await prisma.attendance.findMany({
            select: {
                employeeId: true,
                employeeName: true
            },
            distinct: ['employeeId']
        });

        console.log(`\n👥 All unique employee IDs in database:`);
        allEmployeeIds.forEach((emp, index) => {
            console.log(`${index + 1}. EmployeeId: "${emp.employeeId}", Name: "${emp.employeeName}"`);
        });

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkEmployeeIds();