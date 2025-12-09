import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Current active attendance ID from database
const ATTENDANCE_ID = 'cmiyi03oh0000b43xzcg8jfeo'; // om's attendance
const EMPLOYEE_ID = '000013';

async function testPunchOut() {
    console.log('🔴 Testing Punch Out...\n');
    console.log('Attendance ID:', ATTENDANCE_ID);
    console.log('Employee ID:', EMPLOYEE_ID);
    console.log('');

    try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
            attendanceId: ATTENDANCE_ID,
            punchOutLatitude: 37.42299,
            punchOutLongitude: -122.08424,
            punchOutPhoto: 'data:image/png;base64,test_punch_out_photo',
            punchOutAddress: 'End Location, Test City',
            bikeKmEnd: '12500'
        });

        console.log('✅ Punch Out Success!\n');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        console.log('');
        console.log('Summary:');
        console.log('  Status:', response.data.data.status);
        console.log('  Work Hours:', response.data.data.totalWorkHours?.toFixed(2), 'hours');
        console.log('  Distance:', response.data.data.totalDistanceKm?.toFixed(2), 'km');
        console.log('  Punch In:', new Date(response.data.data.punchInTime).toLocaleString());
        console.log('  Punch Out:', new Date(response.data.data.punchOutTime).toLocaleString());

    } catch (error) {
        console.error('❌ Punch Out Failed!');
        console.error('Error:', error.response?.data || error.message);
    }
}

async function checkCurrentStatus() {
    console.log('📊 Checking Current Status...\n');

    try {
        const response = await axios.get(`${BASE_URL}/attendance/today/${EMPLOYEE_ID}`);

        if (response.data.data) {
            const att = response.data.data;
            console.log('Current Attendance:');
            console.log('  ID:', att.id);
            console.log('  Employee:', att.employeeName);
            console.log('  Status:', att.status);
            console.log('  Punch In:', new Date(att.punchInTime).toLocaleString());
            console.log('  Punch Out:', att.punchOutTime ? new Date(att.punchOutTime).toLocaleString() : 'Not yet');
            console.log('');

            if (att.status === 'active') {
                console.log('✅ Ready to punch out!');
                return true;
            } else {
                console.log('⚠️  Already punched out');
                return false;
            }
        } else {
            console.log('❌ No attendance record found');
            return false;
        }
    } catch (error) {
        console.error('❌ Failed to check status:', error.message);
        return false;
    }
}

async function main() {
    console.log('🚀 Punch Out Test Script\n');
    console.log('='.repeat(50));
    console.log('');

    // Check current status first
    const canPunchOut = await checkCurrentStatus();
    console.log('');
    console.log('='.repeat(50));
    console.log('');

    if (canPunchOut) {
        // Ask for confirmation
        const readline = require('readline').createInterface({
            input: process.stdin,
            output: process.stdout
        });

        readline.question('Do you want to punch out now? (yes/no): ', async (answer) => {
            if (answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y') {
                console.log('');
                await testPunchOut();
            } else {
                console.log('\n❌ Punch out cancelled');
            }
            readline.close();
        });
    } else {
        console.log('Cannot punch out at this time');
    }
}

main();
