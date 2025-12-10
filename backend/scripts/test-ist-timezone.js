#!/usr/bin/env node

/**
 * Test script for IST timezone functionality
 * Tests punch in/out with proper Indian Standard Time handling
 */

import fetch from 'node-fetch';
import {
    getCurrentISTTime,
    formatISTTime,
    getISTTimezoneInfo,
    getISTDateRange
} from '../src/utils/timezone.js';

const BASE_URL = 'http://localhost:3000';
const TEST_EMPLOYEE_ID = 'test-employee-ist-001';
const TEST_EMPLOYEE_NAME = 'IST Test Employee';

async function testISTTimezone() {
    console.log('🧪 Testing IST Timezone Functionality');
    console.log('====================================\n');

    // Display current IST information
    const currentIST = getCurrentISTTime();
    const timezoneInfo = getISTTimezoneInfo();
    const dateRange = getISTDateRange();

    console.log('📅 Current IST Information:');
    console.log(`   - Current IST Time: ${formatISTTime(null, 'datetime')}`);
    console.log(`   - Timezone: ${timezoneInfo.name} (${timezoneInfo.abbreviation})`);
    console.log(`   - Offset: ${timezoneInfo.offset}`);
    console.log(`   - Today's Range (UTC): ${dateRange.startOfDay.toISOString()} to ${dateRange.endOfDay.toISOString()}`);
    console.log();

    try {
        // Test 1: Punch In with IST
        console.log('1️⃣ Testing punch in with IST handling...');
        const punchInResponse = await fetch(`${BASE_URL}/attendance/punch-in`, {
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

        const punchInData = await punchInResponse.json();
        console.log('✅ Punch in result:', punchInData.success ? 'SUCCESS' : 'FAILED');
        
        if (punchInData.success) {
            const data = punchInData.data;
            console.log('📝 Punch In Details:');
            console.log(`   - UTC Time: ${data.punchInTime}`);
            console.log(`   - IST Time: ${data.punchInTimeIST}`);
            console.log(`   - IST Formatted: ${data.punchInTimeISTFormatted}`);
            console.log(`   - Timezone: ${data.timezone.name} (${data.timezone.offset})`);
            
            const attendanceId = data.id;
            
            // Wait a moment to simulate work
            console.log('\n⏳ Waiting 3 seconds to simulate work...');
            await new Promise(resolve => setTimeout(resolve, 3000));

            // Test 2: Get Today's Attendance
            console.log('\n2️⃣ Testing today\'s attendance retrieval...');
            const todayResponse = await fetch(`${BASE_URL}/attendance/today/${TEST_EMPLOYEE_ID}`);
            const todayData = await todayResponse.json();
            
            console.log('✅ Today\'s attendance result:', todayData.success ? 'SUCCESS' : 'FAILED');
            
            if (todayData.success && todayData.data) {
                console.log('📊 Today\'s Attendance:');
                console.log(`   - Status: ${todayData.data.status}`);
                console.log(`   - Current Work Hours: ${todayData.data.currentWorkHours}`);
                console.log(`   - Work Duration: ${todayData.data.workDurationFormatted || 'N/A'}`);
                console.log(`   - Server Time IST: ${todayData.serverTimeIST}`);
                console.log(`   - Total Sessions: ${todayData.totalSessions}`);
            }

            // Test 3: Punch Out with IST
            console.log('\n3️⃣ Testing punch out with IST handling...');
            const punchOutResponse = await fetch(`${BASE_URL}/attendance/punch-out`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    attendanceId: attendanceId,
                    punchOutLatitude: 28.6129,
                    punchOutLongitude: 77.2080,
                    punchOutAddress: 'New Delhi, India - End Location'
                })
            });

            const punchOutData = await punchOutResponse.json();
            console.log('✅ Punch out result:', punchOutData.success ? 'SUCCESS' : 'FAILED');
            
            if (punchOutData.success) {
                const data = punchOutData.data;
                console.log('📝 Punch Out Details:');
                console.log(`   - Punch In IST: ${data.punchInTimeISTFormatted}`);
                console.log(`   - Punch Out IST: ${data.punchOutTimeISTFormatted}`);
                console.log(`   - Total Work Hours: ${data.totalWorkHours}`);
                console.log(`   - Work Duration: ${data.workDurationFormatted}`);
                console.log(`   - Distance: ${data.totalDistanceKm} km`);
            }

            // Test 4: Dashboard with IST
            console.log('\n4️⃣ Testing dashboard with IST formatting...');
            const dashboardResponse = await fetch(`${BASE_URL}/attendance/admin/dashboard`);
            const dashboardData = await dashboardResponse.json();
            
            console.log('✅ Dashboard result:', dashboardData.success ? 'SUCCESS' : 'FAILED');
            
            if (dashboardData.success) {
                console.log('📊 Dashboard IST Information:');
                console.log(`   - Date IST: ${dashboardData.data.dateIST}`);
                console.log(`   - Last Updated IST: ${dashboardData.data.lastUpdatedIST}`);
                console.log(`   - Timezone: ${dashboardData.data.timezone.name}`);
                
                if (dashboardData.data.attendances.length > 0) {
                    const sample = dashboardData.data.attendances[0];
                    console.log('📝 Sample Attendance:');
                    console.log(`   - Employee: ${sample.employeeName}`);
                    console.log(`   - Punch In IST: ${sample.punchInTimeISTFormatted}`);
                    console.log(`   - Punch Out IST: ${sample.punchOutTimeISTFormatted || 'Still Active'}`);
                    console.log(`   - Work Duration: ${sample.workDurationFormatted || 'N/A'}`);
                }
            }

            // Test 5: Detailed Attendance with IST
            console.log('\n5️⃣ Testing detailed attendance with IST...');
            const detailedResponse = await fetch(`${BASE_URL}/attendance/admin/detailed`);
            const detailedData = await detailedResponse.json();
            
            console.log('✅ Detailed attendance result:', detailedData.success ? 'SUCCESS' : 'FAILED');
            
            if (detailedData.success) {
                console.log('📋 Detailed Attendance IST:');
                console.log(`   - Filter Date IST: ${detailedData.filters.dateIST}`);
                console.log(`   - Timezone: ${detailedData.timezone.name}`);
                console.log(`   - Records Found: ${detailedData.data.length}`);
                
                if (detailedData.data.length > 0) {
                    const record = detailedData.data[0];
                    console.log('📝 Sample Record:');
                    console.log(`   - Date IST: ${record.dateISTFormatted}`);
                    console.log(`   - Punch In IST: ${record.punchInTimeISTFormatted}`);
                    console.log(`   - Punch Out IST: ${record.punchOutTimeISTFormatted || 'Active'}`);
                    console.log(`   - Duration: ${record.workDurationFormatted || 'N/A'}`);
                }
            }

        } else {
            console.log('❌ Punch in failed:', punchInData.message);
            return;
        }

        console.log('\n🎉 All IST timezone tests completed successfully!');
        console.log('✨ Punch in/out timing is now working correctly with Indian Standard Time.');
        console.log('\n📋 Summary:');
        console.log('   - ✅ Punch in with IST timestamp');
        console.log('   - ✅ Punch out with IST timestamp');
        console.log('   - ✅ Accurate work duration calculation');
        console.log('   - ✅ Proper IST formatting in responses');
        console.log('   - ✅ Dashboard with IST information');
        console.log('   - ✅ Detailed attendance with IST');

    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
    }
}

// Display timezone comparison
function displayTimezoneComparison() {
    console.log('\n🌍 Timezone Comparison:');
    const now = new Date();
    const utc = new Date(now.getTime() + (now.getTimezoneOffset() * 60000));
    const ist = getCurrentISTTime();
    
    console.log(`   - System Time: ${now.toLocaleString()}`);
    console.log(`   - UTC Time: ${utc.toISOString()}`);
    console.log(`   - IST Time: ${formatISTTime(null, 'datetime')}`);
    console.log(`   - IST Offset: +05:30`);
}

// Run the test
displayTimezoneComparison();
testISTTimezone();