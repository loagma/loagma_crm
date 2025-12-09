import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Test data
const testEmployeeId = 'test-emp-001';
const testEmployeeName = 'Test Employee';
let attendanceId = null;

async function testPunchIn() {
    console.log('\n🟢 Testing Punch In...');
    try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
            employeeId: testEmployeeId,
            employeeName: testEmployeeName,
            punchInLatitude: 28.6139,
            punchInLongitude: 77.2090,
            punchInPhoto: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
            punchInAddress: 'New Delhi, India',
            bikeKmStart: '12345'
        });

        console.log('✅ Punch In Success:', response.data);
        attendanceId = response.data.data.id;
        return response.data;
    } catch (error) {
        console.error('❌ Punch In Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testGetTodayAttendance() {
    console.log('\n📅 Testing Get Today Attendance...');
    try {
        const response = await axios.get(`${BASE_URL}/attendance/today/${testEmployeeId}`);
        console.log('✅ Get Today Attendance Success:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ Get Today Attendance Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testPunchOut() {
    console.log('\n🔴 Testing Punch Out...');

    if (!attendanceId) {
        console.error('❌ No attendance ID available. Run punch in first.');
        return;
    }

    try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
            attendanceId: attendanceId,
            punchOutLatitude: 28.7041,
            punchOutLongitude: 77.1025,
            punchOutPhoto: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
            punchOutAddress: 'Gurugram, India',
            bikeKmEnd: '12445'
        });

        console.log('✅ Punch Out Success:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ Punch Out Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testGetAttendanceHistory() {
    console.log('\n📜 Testing Get Attendance History...');
    try {
        const response = await axios.get(`${BASE_URL}/attendance/history/${testEmployeeId}`, {
            params: {
                page: 1,
                limit: 10
            }
        });
        console.log('✅ Get Attendance History Success:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ Get Attendance History Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function testGetAttendanceStats() {
    console.log('\n📊 Testing Get Attendance Stats...');
    try {
        const now = new Date();
        const response = await axios.get(`${BASE_URL}/attendance/stats/${testEmployeeId}`, {
            params: {
                month: now.getMonth() + 1,
                year: now.getFullYear()
            }
        });
        console.log('✅ Get Attendance Stats Success:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ Get Attendance Stats Failed:', error.response?.data || error.message);
        throw error;
    }
}

async function runTests() {
    console.log('🚀 Starting Attendance API Tests...');
    console.log('='.repeat(50));

    try {
        // Test 1: Punch In
        await testPunchIn();
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 2: Get Today Attendance
        await testGetTodayAttendance();
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 3: Punch Out
        await testPunchOut();
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 4: Get Attendance History
        await testGetAttendanceHistory();
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 5: Get Attendance Stats
        await testGetAttendanceStats();

        console.log('\n' + '='.repeat(50));
        console.log('✅ All tests completed successfully!');
    } catch (error) {
        console.log('\n' + '='.repeat(50));
        console.log('❌ Tests failed!');
        process.exit(1);
    }
}

runTests();
