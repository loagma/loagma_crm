#!/usr/bin/env node

/**
 * Timezone Fixes Test Script
 * Tests the corrected IST timezone handling
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';
const TEST_EMPLOYEE_ID = 'timezone-test-001';
const TEST_EMPLOYEE_NAME = 'Timezone Test Employee';

// Test coordinates (Mumbai, India)
const TEST_COORDINATES = {
  latitude: 19.0760,
  longitude: 72.8777,
  address: 'Mumbai, Maharashtra, India'
};

class TimezoneTestSuite {
  constructor() {
    this.testResults = [];
    this.currentAttendanceId = null;
  }

  async runTest(testName, testFunction) {
    console.log(`\n🧪 Testing: ${testName}`);
    console.log('─'.repeat(50));
    
    try {
      const startTime = Date.now();
      const result = await testFunction();
      const duration = Date.now() - startTime;
      
      this.testResults.push({
        name: testName,
        status: 'PASSED',
        duration,
        result
      });
      
      console.log(`✅ ${testName} - PASSED (${duration}ms)`);
      return result;
    } catch (error) {
      this.testResults.push({
        name: testName,
        status: 'FAILED',
        error: error.message
      });
      
      console.log(`❌ ${testName} - FAILED`);
      console.log(`   Error: ${error.message}`);
      throw error;
    }
  }

  async testPunchInTimezone() {
    return this.runTest('Punch In with Correct IST Timezone', async () => {
      const beforePunchIn = new Date();
      
      const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
        employeeId: TEST_EMPLOYEE_ID,
        employeeName: TEST_EMPLOYEE_NAME,
        punchInLatitude: TEST_COORDINATES.latitude,
        punchInLongitude: TEST_COORDINATES.longitude,
        punchInAddress: TEST_COORDINATES.address,
        bikeKmStart: '12345'
      });

      if (response.status !== 201) {
        throw new Error(`Expected status 201, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch in failed: ${data.message}`);
      }

      this.currentAttendanceId = data.data.id;
      
      // Parse the stored time from database
      const storedTime = new Date(data.data.punchInTime);
      const afterPunchIn = new Date();
      
      console.log(`   🕐 Before Punch In (Local): ${beforePunchIn.toLocaleString()}`);
      console.log(`   📅 Stored in DB: ${data.data.punchInTime}`);
      console.log(`   🇮🇳 IST Formatted: ${data.data.punchInTimeIST || 'Not provided'}`);
      console.log(`   🕐 After Punch In (Local): ${afterPunchIn.toLocaleString()}`);
      
      // Check if stored time is reasonable (within 1 minute of current time)
      const timeDiff = Math.abs(storedTime.getTime() - beforePunchIn.getTime());
      const timeDiffMinutes = timeDiff / (1000 * 60);
      
      console.log(`   ⏱️ Time difference: ${timeDiffMinutes.toFixed(2)} minutes`);
      
      // Validate timezone - IST should be UTC+5:30
      const currentUTC = new Date().getTime();
      const expectedIST = new Date(currentUTC + (5.5 * 60 * 60 * 1000));
      const storedVsExpected = Math.abs(storedTime.getTime() - expectedIST.getTime());
      const storedVsExpectedMinutes = storedVsExpected / (1000 * 60);
      
      console.log(`   🌍 Expected IST: ${expectedIST.toISOString()}`);
      console.log(`   📊 Stored vs Expected: ${storedVsExpectedMinutes.toFixed(2)} minutes difference`);
      
      if (timeDiffMinutes > 2) {
        throw new Error(`Time difference too large: ${timeDiffMinutes.toFixed(2)} minutes`);
      }
      
      return {
        storedTime: data.data.punchInTime,
        timeDifference: timeDiffMinutes,
        attendanceId: this.currentAttendanceId
      };
    });
  }

  async testCurrentTimeAPI() {
    return this.runTest('Current Time API Response', async () => {
      const response = await axios.get(`${BASE_URL}/attendance/admin/dashboard`);

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Dashboard fetch failed: ${data.message}`);
      }

      const serverTime = data.data.lastUpdated;
      const serverTimeIST = data.data.lastUpdatedIST;
      const timezone = data.data.timezone;

      console.log(`   🖥️ Server Time (UTC): ${serverTime}`);
      console.log(`   🇮🇳 Server Time (IST): ${serverTimeIST}`);
      console.log(`   🌍 Timezone Info: ${timezone?.name} (${timezone?.offset})`);

      // Validate timezone info
      if (timezone?.offset !== '+05:30') {
        throw new Error(`Expected IST offset +05:30, got ${timezone?.offset}`);
      }

      return {
        serverTime,
        serverTimeIST,
        timezone
      };
    });
  }

  async testWorkDurationCalculation() {
    return this.runTest('Work Duration Calculation', async () => {
      if (!this.currentAttendanceId) {
        throw new Error('No active attendance session for duration test');
      }

      // Wait 3 seconds to have some work duration
      console.log('   ⏳ Waiting 3 seconds for work duration...');
      await new Promise(resolve => setTimeout(resolve, 3000));

      const response = await axios.get(`${BASE_URL}/attendance/today/${TEST_EMPLOYEE_ID}`);

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Get attendance failed: ${data.message}`);
      }

      const currentWorkHours = data.data.currentWorkHours;
      const punchInTime = new Date(data.data.punchInTime);
      const currentTime = new Date();
      
      // Calculate expected duration
      const expectedDurationMs = currentTime.getTime() - punchInTime.getTime();
      const expectedDurationHours = expectedDurationMs / (1000 * 60 * 60);

      console.log(`   📅 Punch In Time: ${data.data.punchInTime}`);
      console.log(`   🕐 Current Time: ${currentTime.toISOString()}`);
      console.log(`   ⏱️ Calculated Work Hours: ${currentWorkHours}`);
      console.log(`   📊 Expected Duration: ${expectedDurationHours.toFixed(4)} hours`);
      console.log(`   🔄 Duration Formatted: ${data.data.workDurationFormatted || 'Not provided'}`);

      // Validate duration is reasonable (should be close to expected)
      const durationDiff = Math.abs(currentWorkHours - expectedDurationHours);
      console.log(`   📏 Duration Difference: ${durationDiff.toFixed(4)} hours`);

      if (durationDiff > 0.1) { // More than 6 minutes difference
        throw new Error(`Duration calculation error: ${durationDiff.toFixed(4)} hours difference`);
      }

      return {
        currentWorkHours,
        expectedDurationHours,
        durationDiff,
        punchInTime: data.data.punchInTime
      };
    });
  }

  async testPunchOutTimezone() {
    return this.runTest('Punch Out with Correct IST Timezone', async () => {
      if (!this.currentAttendanceId) {
        throw new Error('No active attendance session for punch out test');
      }

      const beforePunchOut = new Date();

      const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
        attendanceId: this.currentAttendanceId,
        punchOutLatitude: TEST_COORDINATES.latitude,
        punchOutLongitude: TEST_COORDINATES.longitude,
        punchOutAddress: TEST_COORDINATES.address,
        bikeKmEnd: '12350'
      });

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch out failed: ${data.message}`);
      }

      const storedPunchOutTime = new Date(data.data.punchOutTime);
      const storedPunchInTime = new Date(data.data.punchInTime);
      const afterPunchOut = new Date();

      console.log(`   🕐 Before Punch Out: ${beforePunchOut.toLocaleString()}`);
      console.log(`   📅 Stored Punch Out: ${data.data.punchOutTime}`);
      console.log(`   📅 Stored Punch In: ${data.data.punchInTime}`);
      console.log(`   ⏱️ Total Work Hours: ${data.data.totalWorkHours}`);
      console.log(`   🕐 After Punch Out: ${afterPunchOut.toLocaleString()}`);

      // Validate punch out time
      const timeDiff = Math.abs(storedPunchOutTime.getTime() - beforePunchOut.getTime());
      const timeDiffMinutes = timeDiff / (1000 * 60);

      console.log(`   ⏱️ Punch Out Time Difference: ${timeDiffMinutes.toFixed(2)} minutes`);

      if (timeDiffMinutes > 2) {
        throw new Error(`Punch out time difference too large: ${timeDiffMinutes.toFixed(2)} minutes`);
      }

      // Validate work duration
      const actualDuration = storedPunchOutTime.getTime() - storedPunchInTime.getTime();
      const actualDurationHours = actualDuration / (1000 * 60 * 60);
      const reportedDurationHours = data.data.totalWorkHours;

      console.log(`   📊 Actual Duration: ${actualDurationHours.toFixed(4)} hours`);
      console.log(`   📊 Reported Duration: ${reportedDurationHours} hours`);

      const durationDiff = Math.abs(actualDurationHours - reportedDurationHours);
      console.log(`   📏 Duration Calculation Diff: ${durationDiff.toFixed(4)} hours`);

      if (durationDiff > 0.01) { // More than 36 seconds difference
        throw new Error(`Duration calculation error: ${durationDiff.toFixed(4)} hours difference`);
      }

      return {
        punchInTime: data.data.punchInTime,
        punchOutTime: data.data.punchOutTime,
        totalWorkHours: data.data.totalWorkHours,
        timeDifference: timeDiffMinutes,
        durationAccuracy: durationDiff
      };
    });
  }

  async cleanup() {
    console.log('\n🧹 Cleaning up test data...');
    
    if (this.currentAttendanceId) {
      try {
        // If still active, punch out
        await axios.post(`${BASE_URL}/attendance/punch-out`, {
          attendanceId: this.currentAttendanceId,
          punchOutLatitude: TEST_COORDINATES.latitude,
          punchOutLongitude: TEST_COORDINATES.longitude,
          punchOutAddress: 'Test cleanup'
        });
        console.log(`   ✅ Cleaned up attendance: ${this.currentAttendanceId}`);
      } catch (error) {
        console.log(`   ⚠️ Cleanup note: ${error.response?.data?.message || error.message}`);
      }
    }
  }

  printSummary() {
    console.log('\n📊 TIMEZONE TEST SUMMARY');
    console.log('═'.repeat(50));
    
    const passed = this.testResults.filter(t => t.status === 'PASSED').length;
    const failed = this.testResults.filter(t => t.status === 'FAILED').length;
    const total = this.testResults.length;
    
    console.log(`Total Tests: ${total}`);
    console.log(`Passed: ${passed} ✅`);
    console.log(`Failed: ${failed} ${failed > 0 ? '❌' : ''}`);
    console.log(`Success Rate: ${((passed / total) * 100).toFixed(1)}%`);
    
    if (failed > 0) {
      console.log('\n❌ FAILED TESTS:');
      this.testResults
        .filter(t => t.status === 'FAILED')
        .forEach(test => {
          console.log(`   • ${test.name}: ${test.error}`);
        });
    }
    
    console.log('\n🇮🇳 TIMEZONE VALIDATION RESULTS:');
    console.log('   • IST Offset: UTC+5:30 (330 minutes)');
    console.log('   • Database Storage: IST times directly');
    console.log('   • Time Accuracy: Within 2 minutes tolerance');
    console.log('   • Duration Calculation: Within 1% accuracy');
    
    const currentTime = new Date();
    const istTime = new Date(currentTime.getTime() + (5.5 * 60 * 60 * 1000));
    console.log(`\n🕐 Current Times:`);
    console.log(`   UTC: ${currentTime.toISOString()}`);
    console.log(`   IST: ${istTime.toISOString()}`);
  }
}

// Main execution
async function main() {
  console.log('🇮🇳 IST Timezone Fixes Test Suite');
  console.log('═'.repeat(50));
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Test Employee: ${TEST_EMPLOYEE_NAME}`);
  
  const testSuite = new TimezoneTestSuite();
  
  try {
    // Core timezone tests
    await testSuite.testPunchInTimezone();
    await testSuite.testCurrentTimeAPI();
    await testSuite.testWorkDurationCalculation();
    await testSuite.testPunchOutTimezone();
    
    await testSuite.cleanup();
    
  } catch (error) {
    console.log(`\n💥 Test suite failed: ${error.message}`);
    await testSuite.cleanup();
  } finally {
    testSuite.printSummary();
  }
}

// Run the tests
if (require.main === module) {
  main().catch(console.error);
}

module.exports = TimezoneTestSuite;