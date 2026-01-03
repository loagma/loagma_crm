import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testRouteAPI() {
    try {
        console.log('🧪 Final Route API Test...');

        // 1. Check what data exists for Sparsh sahu on Jan 3, 2026
        const attendanceRecord = await prisma.attendance.findFirst({
            where: {
                employeeName: 'Sparsh sahu',
                date: {
                    gte: new Date('2026-01-03T00:00:00.000Z'),
                    lte: new Date('2026-01-03T23:59:59.999Z')
                }
            },
            include: {
                routeLogs: true
            }
        });

        if (!attendanceRecord) {
            console.log('❌ No attendance record found for Sparsh sahu on Jan 3, 2026');
            return;
        }

        console.log('✅ Found attendance record:');
        console.log(`   - ID: ${attendanceRecord.id}`);
        console.log(`   - Employee ID: ${attendanceRecord.employeeId}`);
        console.log(`   - Employee Name: ${attendanceRecord.employeeName}`);
        console.log(`   - Date: ${attendanceRecord.date}`);
        console.log(`   - Route Points: ${attendanceRecord.routeLogs.length}`);

        // 2. Test the API endpoint directly
        const fetch = (await import('node-fetch')).default;
        const url = `http://localhost:5000/api/routes/historical?employeeId=${attendanceRecord.employeeId}&date=2026-01-03`;

        console.log(`\n📡 Testing API: ${url}`);

        try {
            const response = await fetch(url);
            const data = await response.json();

            console.log(`📊 API Response Status: ${response.status}`);

            if (data.success && data.data && data.data.routes && data.data.routes.length > 0) {
                console.log('✅ API working correctly!');
                console.log(`   - Found ${data.data.routes.length} routes`);
                const route = data.data.routes[0];
                console.log(`   - Route has ${route.routeSummary.totalPoints} points`);
                console.log(`   - Distance: ${route.routeSummary.totalDistanceKm} km`);
            } else {
                console.log('❌ API returned no routes');
                console.log('Response:', JSON.stringify(data, null, 2));
            }
        } catch (apiError) {
            console.log('❌ API call failed:', apiError.message);
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testRouteAPI();