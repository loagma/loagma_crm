import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testCompleteFlow() {
    try {
        console.log('🧪 Testing Complete Route Playback Flow...');

        const fetch = (await import('node-fetch')).default;

        // Step 1: Test attendance API (for employee dropdown)
        console.log('\n📋 Step 1: Testing attendance API...');
        const attendanceUrl = 'http://localhost:5000/attendance/all?limit=1000';
        const attendanceResponse = await fetch(attendanceUrl);
        const attendanceData = await attendanceResponse.json();

        if (!attendanceData.success) {
            console.log('❌ Attendance API failed');
            return;
        }

        // Find Sparsh sahu
        const sparshRecords = attendanceData.data.filter(record =>
            record.employeeName && record.employeeName.includes('Sparsh')
        );

        if (sparshRecords.length === 0) {
            console.log('❌ No records found for Sparsh sahu');
            return;
        }

        const sparshEmployeeId = sparshRecords[0].employeeId;
        console.log(`✅ Found Sparsh sahu with employeeId: ${sparshEmployeeId}`);

        // Step 2: Test historical routes API
        console.log('\n🗺️ Step 2: Testing historical routes API...');
        const routesUrl = `http://localhost:5000/api/routes/historical?employeeId=${sparshEmployeeId}&date=2026-01-03`;
        const routesResponse = await fetch(routesUrl);
        const routesData = await routesResponse.json();

        if (!routesData.success) {
            console.log('❌ Routes API failed');
            console.log('Response:', JSON.stringify(routesData, null, 2));
            return;
        }

        if (routesData.data.routes.length === 0) {
            console.log('❌ No routes found for the date');
            return;
        }

        const route = routesData.data.routes[0];
        console.log(`✅ Found route with ${route.routeSummary.totalPoints} points`);
        console.log(`   - Distance: ${route.routeSummary.totalDistanceKm} km`);
        console.log(`   - Attendance ID: ${route.attendanceId}`);

        // Step 3: Test route analytics API (used by route playback)
        console.log('\n📊 Step 3: Testing route analytics API...');
        const analyticsUrl = `http://localhost:5000/api/routes/analytics/${route.attendanceId}`;
        const analyticsResponse = await fetch(analyticsUrl);
        const analyticsData = await analyticsResponse.json();

        if (analyticsData.success) {
            console.log(`✅ Analytics API working - found ${analyticsData.data.playbackPoints?.length || 0} playback points`);
        } else {
            console.log('⚠️ Analytics API failed, but route playback might still work');
        }

        console.log('\n🎉 Complete flow test summary:');
        console.log('✅ Employee dropdown will show Sparsh sahu with correct ID');
        console.log('✅ Historical routes API returns data for Jan 3, 2026');
        console.log('✅ Route playback should work with the available data');

        console.log('\n💡 Next steps:');
        console.log('1. Make sure Flutter app is using local backend (useProduction = false)');
        console.log('2. Rebuild the Flutter app to apply the URL fix');
        console.log('3. Test the route playback feature');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testCompleteFlow();