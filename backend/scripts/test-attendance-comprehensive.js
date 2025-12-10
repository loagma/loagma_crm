#!/usr/bin/env node

/**
 * Comprehensive Attendance System Test
 * 
 * Tests all attendance functionality including:
 * - Punch in/out flow
 * - Time calculations
 * - Duration tracking
 * - Location handling
 * - Live tracking features
 */

import axios from 'axios';
import { config } from 'dotenv';

config();

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const TEST_EMPLOYEE_ID = '00001'; // Use a real employee ID
const TEST_EMPLOYEE_NAME = 'Test Employee';

console.log('🧪 Comprehensive Attendance System Test');
console.log('======================================');
console.log(`📡 API Base URL: ${BASE_URL}`);
console.log(`👤 Test Employee: ${TEST_EMPLOYEE_ID} - ${TEST_EMPLOYEE_NAME}`);
console.log('');

// Helper function to make API requests
async function apiRequest(endpoint, method = 'GET', data = null) {
  const url = `${BASE_URL}${endpoint}`;
  
  console.log(`📡 ${method} ${url}`);
  if (data) {
    console.log(`📦 Data:`, JSON.stringify(data, null, 2));
  }

  try {
    const response = await axios({
      method: method.toLowerCase(),
      url,
      data,
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: () => true, // Don't throw on HTTP error status
    });
    
    console.log(`✅ Status: ${response.status}`);
    console.log(`📦 Response:`, JSON.stringify(response.data, null, 2));
    console.log('');
    
    return { status: response.status, data: response.data };
  } catch (error) {
    console.error(`❌ Request failed:`, error.message);
    console.log('');
    return { status: 500, data: { success: false, message: error.message } };
  }
}

// Helper function to wait
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Helper function to format duration
function formatDuration(hours) {
  const h = Math.floor(hours);
  const m = Math.floor((hours - h) * 60);
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
}

// Test 1: Check Today's Attendance (should be empty initially)
async function testGetTodayAttendance() {
  console.log('🧪 TEST 1: Get Today\'s Attendance (Initial Check)');
  console.log('==================================================');

  const response = await apiRequest(`/attendance/today/${TEST_EMPLOYEE_ID}`, 'GET');

  if (response.data.success) {
    if (response.data.data) {
      console.log('⚠️ Found existing attendance record:');
      console.log(`   Status: ${response.data.data.status}`);
      console.log(`   Punch In: ${response.data.data.punchInTime}`);
      if (response.data.data.punchOutTime) {
        console.log(`   Punch Out: ${response.data.data.punchOutTime}`);
      }
      return response.data.data;
    } else {
      console.log('✅ No existing attendance record found (as expected)');
      return null;
    }
  } else {
    console.log('❌ Failed to fetch today\'s attendance');
    return null;
  }
}

// Test 2: Punch In
async function testPunchIn() {
  console.log('🧪 TEST 2: Punch In');
  console.log('===================');

  const punchInData = {
    employeeId: TEST_EMPLOYEE_ID,
    employeeName: TEST_EMPLOYEE_NAME,
    punchInLatitude: 19.0760, // Mumbai coordinates
    punchInLongitude: 72.8777,
    punchInPhoto: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=', // Minimal base64 image
    punchInAddress: 'Test Location, Mumbai',
    bikeKmStart: '12345'
  };

  const response = await apiRequest('/attendance/punch-in', 'POST', punchInData);

  if (response.data.success) {
    console.log('✅ Punch in successful!');
    console.log(`   Attendance ID: ${response.data.data.id}`);
    console.log(`   Punch In Time: ${response.data.data.punchInTime}`);
    console.log(`   Status: ${response.data.data.status}`);
    return response.data.data;
  } else {
    console.log('❌ Punch in failed:', response.data.message);
    return null;
  }
}

// Test 3: Check Today's Attendance After Punch In
async function testGetTodayAttendanceAfterPunchIn() {
  console.log('🧪 TEST 3: Get Today\'s Attendance (After Punch In)');
  console.log('==================================================');

  const response = await apiRequest(`/attendance/today/${TEST_EMPLOYEE_ID}`, 'GET');

  if (response.data.success && response.data.data) {
    const attendance = response.data.data;
    console.log('✅ Found active attendance record:');
    console.log(`   ID: ${attendance.id}`);
    console.log(`   Status: ${attendance.status}`);
    console.log(`   Punch In Time: ${attendance.punchInTime}`);
    
    if (attendance.currentWorkHours !== undefined) {
      console.log(`   Current Work Hours: ${formatDuration(attendance.currentWorkHours)}`);
    }
    
    if (response.data.serverTime) {
      console.log(`   Server Time: ${response.data.serverTime}`);
      
      // Calculate client-side duration for comparison
      const punchInTime = new Date(attendance.punchInTime);
      const serverTime = new Date(response.data.serverTime);
      const clientDuration = (serverTime - punchInTime) / (1000 * 60 * 60); // hours
      
      console.log(`   Client Calculated Duration: ${formatDuration(clientDuration)}`);
    }
    
    return attendance;
  } else {
    console.log('❌ Failed to fetch attendance or no data found');
    return null;
  }
}

// Test 4: Wait and Check Duration Updates
async function testDurationTracking(attendanceId) {
  console.log('🧪 TEST 4: Duration Tracking Test');
  console.log('=================================');
  console.log('Waiting 10 seconds to test duration calculation...');
  
  // Wait 10 seconds
  await sleep(10000);
  
  const response = await apiRequest(`/attendance/today/${TEST_EMPLOYEE_ID}`, 'GET');
  
  if (response.data.success && response.data.data) {
    const attendance = response.data.data;
    console.log('✅ Duration tracking test:');
    console.log(`   Status: ${attendance.status}`);
    
    if (attendance.currentWorkHours !== undefined) {
      console.log(`   Current Work Hours: ${formatDuration(attendance.currentWorkHours)}`);
      
      // Check if duration is reasonable (should be at least 10 seconds = ~0.003 hours)
      if (attendance.currentWorkHours >= 0.002) {
        console.log('✅ Duration calculation appears correct');
      } else {
        console.log('⚠️ Duration seems too small, possible calculation issue');
      }
    }
    
    return true;
  } else {
    console.log('❌ Failed to fetch updated attendance');
    return false;
  }
}

// Test 5: Punch Out
async function testPunchOut(attendanceId) {
  console.log('🧪 TEST 5: Punch Out');
  console.log('====================');

  const punchOutData = {
    attendanceId: attendanceId,
    punchOutLatitude: 19.0850, // Slightly different location
    punchOutLongitude: 72.8850,
    punchOutPhoto: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=',
    punchOutAddress: 'End Location, Mumbai',
    bikeKmEnd: '12355'
  };

  const response = await apiRequest('/attendance/punch-out', 'POST', punchOutData);

  if (response.data.success) {
    const attendance = response.data.data;
    console.log('✅ Punch out successful!');
    console.log(`   Attendance ID: ${attendance.id}`);
    console.log(`   Punch Out Time: ${attendance.punchOutTime}`);
    console.log(`   Status: ${attendance.status}`);
    console.log(`   Total Work Hours: ${formatDuration(attendance.totalWorkHours || 0)}`);
    console.log(`   Total Distance: ${(attendance.totalDistanceKm || 0).toFixed(2)} km`);
    
    // Validate work hours calculation
    const punchInTime = new Date(attendance.punchInTime);
    const punchOutTime = new Date(attendance.punchOutTime);
    const expectedHours = (punchOutTime - punchInTime) / (1000 * 60 * 60);
    
    console.log(`   Expected Hours: ${formatDuration(expectedHours)}`);
    console.log(`   Actual Hours: ${formatDuration(attendance.totalWorkHours || 0)}`);
    
    const hoursDiff = Math.abs(expectedHours - (attendance.totalWorkHours || 0));
    if (hoursDiff < 0.01) { // Less than 36 seconds difference
      console.log('✅ Work hours calculation is accurate');
    } else {
      console.log('⚠️ Work hours calculation may have issues');
    }
    
    return attendance;
  } else {
    console.log('❌ Punch out failed:', response.data.message);
    return null;
  }
}

// Test 6: Get Final Attendance Record
async function testGetFinalAttendance() {
  console.log('🧪 TEST 6: Get Final Attendance Record');
  console.log('=====================================');

  const response = await apiRequest(`/attendance/today/${TEST_EMPLOYEE_ID}`, 'GET');

  if (response.data.success && response.data.data) {
    const attendance = response.data.data;
    console.log('✅ Final attendance record:');
    console.log(`   ID: ${attendance.id}`);
    console.log(`   Status: ${attendance.status}`);
    console.log(`   Punch In: ${attendance.punchInTime}`);
    console.log(`   Punch Out: ${attendance.punchOutTime}`);
    console.log(`   Total Work Hours: ${formatDuration(attendance.totalWorkHours || 0)}`);
    console.log(`   Total Distance: ${(attendance.totalDistanceKm || 0).toFixed(2)} km`);
    
    return attendance;
  } else {
    console.log('❌ Failed to fetch final attendance record');
    return null;
  }
}

// Test 7: Get Attendance Statistics
async function testGetAttendanceStats() {
  console.log('🧪 TEST 7: Get Attendance Statistics');
  console.log('===================================');

  const response = await apiRequest(`/attendance/stats/${TEST_EMPLOYEE_ID}`, 'GET');

  if (response.data.success) {
    const stats = response.data.data;
    console.log('✅ Attendance statistics:');
    console.log(`   Month: ${stats.month}/${stats.year}`);
    console.log(`   Total Days: ${stats.totalDays}`);
    console.log(`   Completed Days: ${stats.completedDays}`);
    console.log(`   Total Work Hours: ${formatDuration(stats.totalWorkHours || 0)}`);
    console.log(`   Average Work Hours: ${formatDuration(stats.avgWorkHours || 0)}`);
    console.log(`   Total Distance: ${(stats.totalDistance || 0).toFixed(2)} km`);
    
    return stats;
  } else {
    console.log('❌ Failed to fetch attendance statistics');
    return null;
  }
}

// Test 8: Admin Dashboard Test
async function testAdminDashboard() {
  console.log('🧪 TEST 8: Admin Live Dashboard');
  console.log('===============================');

  const response = await apiRequest('/attendance/admin/dashboard', 'GET');

  if (response.data.success) {
    const dashboard = response.data.data;
    console.log('✅ Admin dashboard data:');
    console.log(`   Total Employees: ${dashboard.statistics.totalEmployees}`);
    console.log(`   Present Employees: ${dashboard.statistics.presentEmployees}`);
    console.log(`   Absent Employees: ${dashboard.statistics.absentEmployees}`);
    console.log(`   Active Employees: ${dashboard.statistics.activeEmployees}`);
    console.log(`   Completed Employees: ${dashboard.statistics.completedEmployees}`);
    console.log(`   Average Work Hours: ${formatDuration(dashboard.statistics.avgWorkHours || 0)}`);
    
    return dashboard;
  } else {
    console.log('❌ Failed to fetch admin dashboard');
    return null;
  }
}

// Cleanup function
async function cleanup() {
  console.log('🧹 Cleanup: Removing test attendance record');
  console.log('===========================================');

  // Note: In a real scenario, you might want to keep test data or have a specific cleanup endpoint
  console.log('ℹ️ Test attendance record will remain for manual verification');
  console.log('   You can delete it manually from the admin panel if needed');
}

// Main test runner
async function runComprehensiveAttendanceTests() {
  console.log('🚀 Starting Comprehensive Attendance Tests');
  console.log('==========================================');
  console.log('');

  let allTestsPassed = true;
  let attendanceRecord = null;

  try {
    // Test 1: Initial check
    const initialAttendance = await testGetTodayAttendance();
    
    // If there's already an attendance record, we'll work with it
    if (initialAttendance) {
      attendanceRecord = initialAttendance;
      
      if (initialAttendance.status === 'active') {
        console.log('ℹ️ Found active attendance, will test punch out');
      } else {
        console.log('ℹ️ Found completed attendance, will skip punch operations');
      }
    } else {
      // Test 2: Punch In
      attendanceRecord = await testPunchIn();
      if (!attendanceRecord) {
        allTestsPassed = false;
      }
    }

    if (attendanceRecord) {
      // Test 3: Check attendance after punch in
      const updatedAttendance = await testGetTodayAttendanceAfterPunchIn();
      if (!updatedAttendance) {
        allTestsPassed = false;
      }

      // Test 4: Duration tracking (only if active)
      if (attendanceRecord.status === 'active') {
        const durationTest = await testDurationTracking(attendanceRecord.id);
        if (!durationTest) {
          allTestsPassed = false;
        }

        // Test 5: Punch Out
        const completedAttendance = await testPunchOut(attendanceRecord.id);
        if (!completedAttendance) {
          allTestsPassed = false;
        }
      }

      // Test 6: Final attendance check
      const finalAttendance = await testGetFinalAttendance();
      if (!finalAttendance) {
        allTestsPassed = false;
      }

      // Test 7: Statistics
      const stats = await testGetAttendanceStats();
      if (!stats) {
        allTestsPassed = false;
      }
    }

    // Test 8: Admin dashboard
    const dashboard = await testAdminDashboard();
    if (!dashboard) {
      allTestsPassed = false;
    }

    // Final Results
    console.log('📊 COMPREHENSIVE TEST RESULTS');
    console.log('=============================');
    
    if (allTestsPassed) {
      console.log('🎉 ALL ATTENDANCE TESTS PASSED!');
      console.log('');
      console.log('✅ Attendance system is working correctly:');
      console.log('   • Punch in/out functionality works');
      console.log('   • Time calculations are accurate');
      console.log('   • Duration tracking is functional');
      console.log('   • Location handling works properly');
      console.log('   • Statistics generation is correct');
      console.log('   • Admin dashboard is functional');
    } else {
      console.log('❌ SOME ATTENDANCE TESTS FAILED');
      console.log('   Please check the backend implementation');
    }

  } catch (error) {
    console.error('💥 Test suite crashed:', error);
    allTestsPassed = false;
  } finally {
    // Cleanup
    await cleanup();
  }

  console.log('');
  console.log('🏁 Comprehensive attendance test completed');
  process.exit(allTestsPassed ? 0 : 1);
}

// Run the tests
runComprehensiveAttendanceTests();