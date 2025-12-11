#!/usr/bin/env node

/**
 * Test Punch Out Now - Complete the current active session
 */

import axios from 'axios';

const BASE_URL = 'http://localhost:5000';
const TEST_EMPLOYEE_ID = 'timezone-test-001';

// Test coordinates (Mumbai, India)
const TEST_COORDINATES = {
  latitude: 19.0760,
  longitude: 72.8777,
  address: 'Mumbai, Maharashtra, India'
};

async function punchOutActiveSession() {
    console.log('🚪 Punching Out Active Session');
    console.log('═'.repeat(50));
    
    try {
        // Check for active session
        console.log('\n🔍 Checking for active attendance...');
        const response = await axios.get(`${BASE_URL}/attendance/today/${TEST_EMPLOYEE_ID}`);
        
        if (response.data.success && response.data.data && response.data.data.isActive) {
            const attendance = response.data.data;
            console.log(`✅ Found active session: ${attendance.id}`);
            console.log(`Punch In Time: ${attendance.punchInTimeIST || attendance.punchInTime}`);
            console.log(`Current Duration: ${attendance.currentWorkHours || 0} hours`);
            
            // Punch out
            console.log('\n🚪 Punching out...');
            const punchOutResponse = await axios.post(`${BASE_URL}/attendance/punch-out`, {
                attendanceId: attendance.id,
                punchOutLatitude: TEST_COORDINATES.latitude,
                punchOutLongitude: TEST_COORDINATES.longitude,
                punchOutAddress: TEST_COORDINATES.address,
                bikeKmEnd: '12350'
            });
            
            if (punchOutResponse.data.success) {
                const completedAttendance = punchOutResponse.data.data;
                console.log('✅ Successfully punched out!');
                console.log(`Total Work Hours: ${completedAttendance.totalWorkHours}`);
                console.log(`Punch Out Time: ${completedAttendance.punchOutTimeIST || completedAttendance.punchOutTime}`);
                console.log(`Status: ${completedAttendance.status}`);
                
                return completedAttendance;
            } else {
                throw new Error(`Punch out failed: ${punchOutResponse.data.message}`);
            }
        } else {
            console.log('ℹ️ No active session found');
            return null;
        }
        
    } catch (error) {
        console.error('❌ Error:', error.response?.data?.message || error.message);
        throw error;
    }
}

// Run the punch out
punchOutActiveSession()
    .then((result) => {
        if (result) {
            console.log('\n🎯 Punch Out Summary:');
            console.log(`• Session ID: ${result.id}`);
            console.log(`• Employee: ${result.employeeName}`);
            console.log(`• Total Work Hours: ${result.totalWorkHours}`);
            console.log(`• Status: ${result.status}`);
            console.log('\n✅ Ready for new punch in tests!');
        } else {
            console.log('\n✅ No active session to punch out. Ready for tests!');
        }
    })
    .catch(console.error);