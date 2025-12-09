import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Use a real employee ID from your system
const testEmployeeId = 'cm8rvqxqh0000uy8iqxqxqxqx'; // Replace with actual employee ID
const testEmployeeName = 'Test Salesman';

async function testPunchInToday() {
    console.log('\n🟢 Testing Punch In for Today...');
    try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
            employeeId: testEmployeeId,
            employeeName: testEmployeeName,
            punchInLatitude: 28.6139,
            punchInLongitude: 77.2090,
            punchInPhoto: 'data:image/png;base64,test',
            punchInAddress: 'Test Location',
            bikeKmStart: '12345'
        });

        console.log('✅ Punch In Success:');
        console.log('   ID:', response.data.data.id);
        console.log('   Employee:', response.data.data.employeeName);
        console.log('   Time:', response.data.data.punchInTime);
        console.log('   Status:', response.data.data.status);
        return response.data.data;
    } catch (error) {
        if (error.response?.status === 400 && error.response?.data?.message?.includes('Already punched in')) {
            console.log('⚠️  Already punched in today - this is expected');
            return null;
        }
        console.error('❌ Punch In Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testGetTodayAttendance() {
    console.log('\n📅 Testing Get Today Attendance...');
    try {
        const response = await axios.get(`${BASE_URL}/attendance/today/${testEmployeeId}`);

        if (response.data.data) {
            console.log('✅ Today Attendance Found:');
            console.log('   ID:', response.data.data.id);
            console.log('   Employee:', response.data.data.employeeName);
            console.log('   Punch In:', response.data.data.punchInTime);
            console.log('   Status:', response.data.data.status);
            console.log('   Punch Out:', response.data.data.punchOutTime || 'Not yet');
        } else {
            console.log('ℹ️  No attendance record for today');
        }
        return response.data.data;
    } catch (error) {
        console.error('❌ Get Today Attendance Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testPunchOut(attendanceId) {
    console.log('\n🔴 Testing Punch Out...');
    try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
            attendanceId: attendanceId,
            punchOutLatitude: 28.7041,
            punchOutLongitude: 77.1025,
            punchOutPhoto: 'data:image/png;base64,test',
            punchOutAddress: 'End Location',
            bikeKmEnd: '12445'
        });

        console.log('✅ Punch Out Success:');
        console.log('   Status:', response.data.data.status);
        console.log('   Work Hours:', response.data.data.totalWorkHours);
        console.log('   Distance:', response.data.data.totalDistanceKm, 'km');
        return response.data.data;
    } catch (error) {
        console.error('❌ Punch Out Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function runTests() {
    console.log('🚀 Testing Attendance System...');
    console.log('='.repeat(50));
    console.log('Employee ID:', testEmployeeId);
    console.log('='.repeat(50));

    try {
        // Test 1: Check if already punched in today
        const todayAttendance = await testGetTodayAttendance();

        if (todayAttendance && todayAttendance.status === 'active') {
            console.log('\n✅ Already punched in today!');
            console.log('   You can test punch out with ID:', todayAttendance.id);

            // Optionally test punch out
            const readline = require('readline').createInterface({
                input: process.stdin,
                output: process.stdout
            });

            readline.question('\nDo you want to punch out? (yes/no): ', async (answer) => {
                if (answer.toLowerCase() === 'yes') {
                    await testPunchOut(todayAttendance.id);
                }
                readline.close();
                console.log('\n' + '='.repeat(50));
                console.log('✅ Tests completed!');
            });
        } else if (todayAttendance && todayAttendance.status === 'completed') {
            console.log('\n✅ Already completed attendance for today!');
            console.log('   Punch In:', todayAttendance.punchInTime);
            console.log('   Punch Out:', todayAttendance.punchOutTime);
            console.log('   Work Hours:', todayAttendance.totalWorkHours);
            console.log('   Distance:', todayAttendance.totalDistanceKm, 'km');
            console.log('\n' + '='.repeat(50));
            console.log('✅ Tests completed!');
        } else {
            // Test 2: Punch in
            const punchInData = await testPunchInToday();

            if (punchInData) {
                // Test 3: Verify today's attendance
                await testGetTodayAttendance();

                console.log('\n' + '='.repeat(50));
                console.log('✅ Tests completed!');
                console.log('   Attendance ID:', punchInData.id);
                console.log('   Use this ID to test punch out later');
            }
        }
    } catch (error) {
        console.log('\n' + '='.repeat(50));
        console.log('❌ Tests failed!');
        process.exit(1);
    }
}

runTests();
