import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testHomeLocationColumn() {
    try {
        console.log('🔍 Testing isHomeLocation column...');
        
        // Test that the column works with Prisma
        const testQuery = await prisma.salesmanRouteLog.findFirst({
            select: {
                id: true,
                isHomeLocation: true,
                employeeId: true,
                attendanceId: true,
                latitude: true,
                longitude: true,
                recordedAt: true
            }
        });
        
        console.log('✅ Prisma query test successful');
        if (testQuery) {
            console.log('📍 Sample record:', {
                id: testQuery.id,
                isHomeLocation: testQuery.isHomeLocation,
                employeeId: testQuery.employeeId,
                latitude: testQuery.latitude,
                longitude: testQuery.longitude
            });
        } else {
            console.log('📍 No route records found in database');
        }
        
        // Test creating a new record with isHomeLocation
        console.log('🧪 Testing record creation...');
        
        // First check if we have any attendance records
        const attendance = await prisma.attendance.findFirst({
            select: { id: true, employeeId: true }
        });
        
        if (attendance) {
            const testRecord = await prisma.salesmanRouteLog.create({
                data: {
                    employeeId: attendance.employeeId,
                    attendanceId: attendance.id,
                    latitude: 28.6139,
                    longitude: 77.2090,
                    isHomeLocation: true
                }
            });
            
            console.log('✅ Test record created successfully:', {
                id: testRecord.id,
                isHomeLocation: testRecord.isHomeLocation
            });
            
            // Clean up test record
            await prisma.salesmanRouteLog.delete({
                where: { id: testRecord.id }
            });
            console.log('🧹 Test record cleaned up');
        } else {
            console.log('⚠️ No attendance records found, skipping creation test');
        }
        
        console.log('✅ All tests passed! The isHomeLocation column is working correctly.');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the test
testHomeLocationColumn();