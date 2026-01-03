import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testAPI() {
    try {
        console.log('🔍 Testing Route API endpoints...');

        // Find Sparsh sahu's attendance record for Jan 3, 2026
        const today = new Date('2026-01-03');
        const startOfDay = new Date(today.setHours(0, 0, 0, 0));
        const endOfDay = new Date(today.setHours(23, 59, 59, 999));

        const attendanceRecord = await prisma.attendance.findFirst({
            where: {
                employeeName: 'Sparsh sahu',
                date: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            },
            include: {
                routeLogs: {
                    orderBy: { recordedAt: 'asc' }
                }
            }
        });

        if (!attendanceRecord) {
            console.log('❌ No attendance record found for Sparsh sahu on Jan 3, 2026');
            return;
        }

        console.log('✅ Found attendance record:', attendanceRecord.id);
        console.log('   Employee ID:', attendanceRecord.employeeId);
        console.log('   Status:', attendanceRecord.status);
        console.log('   Route Points:', attendanceRecord.routeLogs.length);

        // Test the getRouteAnalytics logic
        console.log('\n🧪 Testing route analytics logic...');

        const routePoints = attendanceRecord.routeLogs;

        if (routePoints.length === 0) {
            console.log('❌ No route points found - this explains the error');
            return;
        }

        console.log('✅ Route points found:');
        routePoints.forEach((point, index) => {
            console.log(`   ${index + 1}. Lat: ${point.latitude}, Lng: ${point.longitude}, Time: ${point.recordedAt}`);
        });

        // Test historical routes API logic
        console.log('\n🧪 Testing historical routes logic...');

        const historicalResult = await prisma.attendance.findMany({
            where: {
                employeeId: attendanceRecord.employeeId,
                date: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            },
            include: {
                routeLogs: {
                    orderBy: { recordedAt: 'asc' }
                }
            },
            orderBy: { date: 'desc' }
        });

        console.log(`✅ Historical routes query returned ${historicalResult.length} records`);

        if (historicalResult.length > 0) {
            const record = historicalResult[0];
            console.log(`   Record ID: ${record.id}`);
            console.log(`   Employee: ${record.employeeName}`);
            console.log(`   Route Points: ${record.routeLogs.length}`);
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testAPI();