import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkAttendance() {
    console.log('🔍 Checking Attendance Database...\n');

    try {
        // Get all attendance records
        const allAttendance = await prisma.attendance.findMany({
            orderBy: { punchInTime: 'desc' },
            take: 10
        });

        console.log(`Found ${allAttendance.length} attendance records:\n`);

        allAttendance.forEach((att, index) => {
            console.log(`${index + 1}. ID: ${att.id}`);
            console.log(`   Employee: ${att.employeeName} (${att.employeeId})`);
            console.log(`   Punch In: ${att.punchInTime}`);
            console.log(`   Punch Out: ${att.punchOutTime || 'Not yet'}`);
            console.log(`   Status: ${att.status}`);
            console.log(`   Date: ${att.date}`);
            console.log('');
        });

        // Check today's records
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
        const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0);

        console.log('📅 Today\'s Date Range:');
        console.log(`   From: ${today.toISOString()}`);
        console.log(`   To: ${tomorrow.toISOString()}\n`);

        const todayAttendance = await prisma.attendance.findMany({
            where: {
                punchInTime: {
                    gte: today,
                    lt: tomorrow
                }
            }
        });

        console.log(`Found ${todayAttendance.length} attendance records for today:\n`);

        todayAttendance.forEach((att, index) => {
            console.log(`${index + 1}. Employee: ${att.employeeName} (${att.employeeId})`);
            console.log(`   Punch In: ${att.punchInTime}`);
            console.log(`   Status: ${att.status}`);
            console.log('');
        });

        // Group by employee
        const groupedByEmployee = {};
        allAttendance.forEach(att => {
            if (!groupedByEmployee[att.employeeId]) {
                groupedByEmployee[att.employeeId] = [];
            }
            groupedByEmployee[att.employeeId].push(att);
        });

        console.log('👥 Attendance by Employee:');
        Object.keys(groupedByEmployee).forEach(empId => {
            const records = groupedByEmployee[empId];
            console.log(`\n   ${records[0].employeeName} (${empId}): ${records.length} records`);
        });

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkAttendance();
