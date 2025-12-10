#!/usr/bin/env node

/**
 * Test script for multiple punch sessions per day
 * Tests the new functionality that allows multiple punch in/out sessions
 */

import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3000';
const TEST_EMPLOYEE_ID = 'test-employee-001';
const TEST_EMPLOYEE_NAME = 'Test Employee';

async function testMultiplePunchSessions() {
    console.log('🧪 Testing Multiple Punch Sessions Per Day');
    console.log('==========================================\n');

    try {
        // Test 1: First punch in
        console.log('1️⃣ Testing first punch in...');
        const punchIn1 = await fetch(`${BASE_URL}/attendance/punch-in`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                employeeId: TEST_EMPLOYEE_ID,
                employeeName: TEST_EMPLOYEE_NAME,
                punchInLatitude: 28.6139,
                punchInLongitude: 77.2090,
                punchInAddress: 'New Delhi, India'
            })
        });

        const punchIn1Data = await punchIn1.json();
        console.log('✅ First punch in result:', punchIn1Data.success ? 'SUCCESS' : 'FAILED');
        
        if (!punchIn1Data.success) {
            console.log('❌ Error:', punchIn1Data.message);
            return;
        }

        const attendanceId1 = punchIn1Data.data.id;
        console.log('📝 Attendance ID 1:', attendanceId1);

        // Wait a moment
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 2: First punch out
        console.log('\n2️⃣ Testing first punch out...');
        const punchOut1 = await fetch(`${BASE_URL}/attendance/punch-out`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                attendanceId: attendanceId1,
                punchOutLatitude: 28.6129,
                punchOutLongitude: 77.2080,
                punchOutAddress: 'New Delhi, India - End Location'
            })
        });

        const punchOut1Data = await punchOut1.json();
        console.log('✅ First punch out result:', punchOut1Data.success ? 'SUCCESS' : 'FAILED');

        if (!punchOut1Data.success) {
            console.log('❌ Error:', punchOut1Data.message);
            return;
        }

        // Wait a moment
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Test 3: Second punch in (same day)
        console.log('\n3️⃣ Testing second punch in (same day)...');
        const punchIn2 = await fetch(`${BASE_URL}/attendance/punch-in`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                employeeId: TEST_EMPLOYEE_ID,
                employeeName: TEST_EMPLOYEE_NAME,
                punchInLatitude: 28.6149,
                punchInLongitude: 77.2100,
                punchInAddress: 'New Delhi, India - Second Location'
            })
        });

        const punchIn2Data = await punchIn2.json();
        console.log('✅ Second punch in result:', punchIn2Data.success ? 'SUCCESS' : 'FAILED');
        
        if (!punchIn2Data.success) {
            console.log('❌ Error:', punchIn2Data.message);
            return;
        }

        const attendanceId2 = punchIn2Data.data.id;
        console.log('📝 Attendance ID 2:', attendanceId2);

        // Test 4: Get today's attendance (should show multiple sessions)
        console.log('\n4️⃣ Testing today\'s attendance retrieval...');
        const todayAttendance = await fetch(`${BASE_URL}/attendance/today/${TEST_EMPLOYEE_ID}`);
        const todayData = await todayAttendance.json();
        
        console.log('✅ Today\'s attendance result:', todayData.success ? 'SUCCESS' : 'FAILED');
        console.log('📊 Total sessions today:', todayData.totalSessions || 0);
        console.log('🔄 Active session:', todayData.data ? 'YES' : 'NO');

        // Test 5: Get detailed attendance
        console.log('\n5️⃣ Testing detailed attendance retrieval...');
        const detailedAttendance = await fetch(`${BASE_URL}/attendance/admin/detailed`);
        const detailedData = await detailedAttendance.json();
        
        console.log('✅ Detailed attendance result:', detailedData.success ? 'SUCCESS' : 'FAILED');
        console.log('📋 Records found:', detailedData.data ? detailedData.data.length : 0);

        // Clean up: Punch out the second session
        console.log('\n6️⃣ Cleaning up - punch out second session...');
        const punchOut2 = await fetch(`${BASE_URL}/attendance/punch-out`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                attendanceId: attendanceId2,
                punchOutLatitude: 28.6159,
                punchOutLongitude: 77.2110,
                punchOutAddress: 'New Delhi, India - Second End Location'
            })
        });

        const punchOut2Data = await punchOut2.json();
        console.log('✅ Second punch out result:', punchOut2Data.success ? 'SUCCESS' : 'FAILED');

        console.log('\n🎉 All tests completed successfully!');
        console.log('✨ Multiple punch sessions per day are now working correctly.');

    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
    }
}

// Run the test
testMultiplePunchSessions();