import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testAttendanceAPI() {
    try {
        console.log('🧪 Testing Attendance API for employee dropdown...');

        // Test the getAllAttendance API that populates the dropdown
        const fetch = (await import('node-fetch')).default;
        const url = 'http://localhost:5000/attendance/all?limit=1000';

        console.log(`📡 Testing: ${url}`);

        const response = await fetch(url);
        const data = await response.json();

        console.log(`📊 Response Status: ${response.status}`);

        if (data.success && data.data) {
            console.log(`✅ Found ${data.data.length} attendance records`);

            // Look for Sparsh sahu
            const sparshRecords = data.data.filter(record =>
                record.employeeName && record.employeeName.includes('Sparsh')
            );

            if (sparshRecords.length > 0) {
                console.log(`✅ Found ${sparshRecords.length} records for Sparsh sahu:`);
                sparshRecords.forEach((record, index) => {
                    console.log(`   ${index + 1}. ID: ${record.employeeId}, Name: "${record.employeeName}"`);
                });
            } else {
                console.log('❌ No records found for Sparsh sahu');
                console.log('Available employees:');
                const uniqueEmployees = {};
                data.data.forEach(record => {
                    if (record.employeeId && record.employeeName) {
                        uniqueEmployees[record.employeeId] = record.employeeName;
                    }
                });
                Object.entries(uniqueEmployees).forEach(([id, name]) => {
                    console.log(`   - ${id}: ${name}`);
                });
            }
        } else {
            console.log('❌ API failed or returned no data');
            console.log('Response:', JSON.stringify(data, null, 2));
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testAttendanceAPI();