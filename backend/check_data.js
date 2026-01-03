import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkData() {
    try {
        console.log('🔍 Checking data for Sparsh sahu...');

        // Find the employee
        const employee = await prisma.user.findFirst({
            where: {
                OR: [
                    { name: { contains: 'Sparsh', mode: 'insensitive' } },
                    { name: { contains: 'sahu', mode: 'insensitive' } }
                ]
            }
        });

        if (!employee) {
            console.log('❌ Employee "Sparsh sahu" not found');
            return;
        }

        console.log('✅ Found employee:', employee.name, 'ID:', employee.id);

        // Check attendance records for this employee
        const attendanceRecords = await prisma.attendance.findMany({
            where: {
                employeeId: employee.id
            },
            orderBy: { date: 'desc' },
            take: 10,
            include: {
                routeLogs: true
            }
        });

        console.log(`📊 Found ${attendanceRecords.length} attendance records`);

        attendanceRecords.forEach((record, index) => {
            console.log(`${index + 1}. Date: ${record.date.toISOString().split('T')[0]}, Status: ${record.status}, Route Points: ${record.routeLogs.length}`);
        });

        // Check for Jan 3, 2026 specifically
        const jan3Record = attendanceRecords.find(record => {
            const recordDate = record.date.toISOString().split('T')[0];
            return recordDate === '2026-01-03';
        });

        if (jan3Record) {
            console.log('✅ Found record for Jan 3, 2026:', jan3Record.id);
            console.log('   Route points:', jan3Record.routeLogs.length);
        } else {
            console.log('❌ No record found for Jan 3, 2026');
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkData();