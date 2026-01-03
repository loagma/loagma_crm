import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkAllData() {
    try {
        console.log('🔍 Checking all data in the database...');

        // Check all employees
        const employees = await prisma.user.findMany({
            where: {
                roles: {
                    has: 'salesman'
                }
            },
            select: {
                id: true,
                name: true,
                email: true,
                roles: true
            }
        });

        console.log(`👥 Found ${employees.length} salesmen:`);
        employees.forEach((emp, index) => {
            console.log(`${index + 1}. ${emp.name} (${emp.id}) - ${emp.email}`);
        });

        // Check all attendance records
        const attendanceRecords = await prisma.attendance.findMany({
            orderBy: { date: 'desc' },
            take: 20,
            include: {
                routeLogs: true
            }
        });

        console.log(`\n📊 Found ${attendanceRecords.length} attendance records:`);
        attendanceRecords.forEach((record, index) => {
            console.log(`${index + 1}. ${record.employeeName} - ${record.date.toISOString().split('T')[0]} - Status: ${record.status} - Route Points: ${record.routeLogs.length}`);
        });

        // Check route logs
        const routeLogs = await prisma.salesmanRouteLog.findMany({
            take: 10,
            orderBy: { recordedAt: 'desc' }
        });

        console.log(`\n🗺️ Found ${routeLogs.length} route log entries (showing latest 10)`);

        // Check for today's date (Jan 3, 2026)
        const today = new Date('2026-01-03');
        const startOfDay = new Date(today.setHours(0, 0, 0, 0));
        const endOfDay = new Date(today.setHours(23, 59, 59, 999));

        const todayRecords = await prisma.attendance.findMany({
            where: {
                date: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            },
            include: {
                routeLogs: true
            }
        });

        console.log(`\n📅 Records for Jan 3, 2026: ${todayRecords.length}`);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkAllData();