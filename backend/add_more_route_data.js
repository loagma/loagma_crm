import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function addMoreRouteData() {
    try {
        console.log('🗺️ Adding more route data for better playback...');

        // Find Sparsh sahu's attendance record for Jan 3, 2026
        const attendanceRecord = await prisma.attendance.findFirst({
            where: {
                employeeName: 'Sparsh sahu',
                date: {
                    gte: new Date('2026-01-03T00:00:00.000Z'),
                    lte: new Date('2026-01-03T23:59:59.999Z')
                }
            }
        });

        if (!attendanceRecord) {
            console.log('❌ No attendance record found');
            return;
        }

        console.log(`✅ Found attendance record: ${attendanceRecord.id}`);

        // Add several route points to simulate movement
        const baseTime = new Date('2026-01-03T09:00:00.000Z');
        const routePoints = [
            { lat: 28.6139, lng: 77.2090, time: 0 },   // Delhi center
            { lat: 28.6149, lng: 77.2100, time: 5 },   // Move northeast
            { lat: 28.6159, lng: 77.2110, time: 10 },  // Continue northeast
            { lat: 28.6169, lng: 77.2120, time: 15 },  // Continue northeast
            { lat: 28.6179, lng: 77.2130, time: 20 },  // Continue northeast
            { lat: 28.6189, lng: 77.2140, time: 25 },  // Continue northeast
            { lat: 28.6199, lng: 77.2150, time: 30 },  // Continue northeast
            { lat: 28.6209, lng: 77.2160, time: 35 },  // Continue northeast
        ];

        // Delete existing route logs for this attendance
        await prisma.salesmanRouteLog.deleteMany({
            where: {
                attendanceId: attendanceRecord.id
            }
        });

        console.log('🗑️ Cleared existing route logs');

        // Add new route points
        for (const point of routePoints) {
            const recordedAt = new Date(baseTime.getTime() + (point.time * 60 * 1000)); // Add minutes

            await prisma.salesmanRouteLog.create({
                data: {
                    employeeId: attendanceRecord.employeeId,
                    attendanceId: attendanceRecord.id,
                    latitude: point.lat,
                    longitude: point.lng,
                    speed: Math.random() * 20 + 10, // Random speed between 10-30 km/h
                    accuracy: Math.random() * 10 + 5, // Random accuracy between 5-15m
                    recordedAt: recordedAt,
                    isHomeLocation: point.time === 0 // First point is home
                }
            });
        }

        console.log(`✅ Added ${routePoints.length} route points`);

        // Verify the data
        const routeLogs = await prisma.salesmanRouteLog.findMany({
            where: {
                attendanceId: attendanceRecord.id
            },
            orderBy: {
                recordedAt: 'asc'
            }
        });

        console.log(`📊 Verification: Found ${routeLogs.length} route logs`);
        console.log(`   - First point: ${routeLogs[0].latitude}, ${routeLogs[0].longitude} at ${routeLogs[0].recordedAt}`);
        console.log(`   - Last point: ${routeLogs[routeLogs.length - 1].latitude}, ${routeLogs[routeLogs.length - 1].longitude} at ${routeLogs[routeLogs.length - 1].recordedAt}`);

        console.log('\n🎉 Route data enhanced! Now the playback will show:');
        console.log('   - 8 GPS points showing movement');
        console.log('   - 35-minute journey');
        console.log('   - Realistic speeds and accuracy');
        console.log('   - Home location marked');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

addMoreRouteData();