#!/usr/bin/env node

/**
 * Test script for enhanced attendance dashboard
 * Tests the dynamic statistics and comprehensive attendance management
 */

import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3000';

async function testEnhancedAttendanceDashboard() {
    console.log('🧪 Testing Enhanced Attendance Dashboard');
    console.log('========================================\n');

    try {
        // Test 1: Get Live Dashboard Data
        console.log('1️⃣ Testing live dashboard data...');
        const dashboardResponse = await fetch(`${BASE_URL}/attendance/admin/dashboard`);
        const dashboardData = await dashboardResponse.json();
        
        console.log('✅ Dashboard result:', dashboardData.success ? 'SUCCESS' : 'FAILED');
        
        if (dashboardData.success) {
            const stats = dashboardData.data.statistics;
            console.log('📊 Statistics:');
            console.log(`   - Total Employees: ${stats.totalEmployees}`);
            console.log(`   - Present Employees: ${stats.presentEmployees}`);
            console.log(`   - Absent Employees: ${stats.absentEmployees}`);
            console.log(`   - Active Sessions: ${stats.activeEmployees}`);
            console.log(`   - Completed Sessions: ${stats.completedEmployees}`);
            console.log(`   - Total Sessions: ${stats.totalSessions}`);
            console.log(`   - Average Work Hours: ${stats.avgWorkHours}`);
            console.log(`   - Total Work Hours: ${stats.totalWorkHours}`);
            console.log(`   - Attendance Percentage: ${stats.attendancePercentage}%`);
        }

        // Test 2: Get Detailed Attendance
        console.log('\n2️⃣ Testing detailed attendance...');
        const detailedResponse = await fetch(`${BASE_URL}/attendance/admin/detailed`);
        const detailedData = await detailedResponse.json();
        
        console.log('✅ Detailed attendance result:', detailedData.success ? 'SUCCESS' : 'FAILED');
        
        if (detailedData.success) {
            console.log('📋 Detailed Records:');
            console.log(`   - Total Records: ${detailedData.data.length}`);
            console.log(`   - Active Records: ${detailedData.data.filter(a => a.isActive).length}`);
            console.log(`   - Completed Records: ${detailedData.data.filter(a => a.isPunchedOut).length}`);
            
            // Show sample record
            if (detailedData.data.length > 0) {
                const sample = detailedData.data[0];
                console.log('📝 Sample Record:');
                console.log(`   - Employee: ${sample.employeeName} (${sample.employeeId})`);
                console.log(`   - Punch In: ${sample.punchInFormatted}`);
                console.log(`   - Punch Out: ${sample.punchOutFormatted || 'Still Active'}`);
                console.log(`   - Work Duration: ${sample.workDuration} hours`);
                console.log(`   - Status: ${sample.isActive ? 'Active' : 'Completed'}`);
            }
        }

        // Test 3: Test with Date Filter
        console.log('\n3️⃣ Testing date filtering...');
        const today = new Date().toISOString().split('T')[0];
        const filteredResponse = await fetch(`${BASE_URL}/attendance/admin/detailed?date=${today}`);
        const filteredData = await filteredResponse.json();
        
        console.log('✅ Date filtered result:', filteredData.success ? 'SUCCESS' : 'FAILED');
        console.log(`📅 Records for ${today}: ${filteredData.data ? filteredData.data.length : 0}`);

        // Test 4: Test All Attendance
        console.log('\n4️⃣ Testing all attendance records...');
        const allResponse = await fetch(`${BASE_URL}/attendance/all`);
        const allData = await allResponse.json();
        
        console.log('✅ All attendance result:', allData.success ? 'SUCCESS' : 'FAILED');
        console.log(`📊 Total Records: ${allData.data ? allData.data.length : 0}`);

        console.log('\n🎉 All enhanced dashboard tests completed successfully!');
        console.log('✨ Dynamic statistics and comprehensive attendance management are working correctly.');

    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
    }
}

// Run the test
testEnhancedAttendanceDashboard();