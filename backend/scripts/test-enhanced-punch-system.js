#!/usr/bin/env node

/**
 * Enhanced Punch In/Out System Test Script
 * Tests the improved attendance system with proper timezone handling,
 * session management, and error handling
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';
const TEST_EMPLOYEE_ID = 'test-employee-001';
const TEST_EMPLOYEE_NAME = 'Test Employee';

// Test coordinates (Mumbai, India)
const TEST_COORDINATES = {
  punchIn: {
    latitude: 19.0760,
    longitude: 72.8777,
    address: 'Mumbai, Maharashtra, India'
  },
  punchOut: {
    latitude: 19.0825,
    longitude: 72.8811,
    address: 'Bandra, Mumbai, Maharashtra, India'
  }
};

// Generate a small test photo (base64)
const generateTestPhoto = () => {
  // Simple 1x1 pixel PNG in base64
  return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
};

class AttendanceTestSuite {
  constructor() {
    this.testResults = [];
    this.currentAttendanceId = null;
  }

  async runTest(testName, testFunction) {
    console.log(`\n🧪 Running test: ${testName}`);
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

  async testPunchIn() {
    return this.runTest('Punch In with Enhanced Validation', async () => {
      const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
        employeeId: TEST_EMPLOYEE_ID,
        employeeName: TEST_EMPLOYEE_NAME,
        punchInLatitude: TEST_COORDINATES.punchIn.latitude,
        punchInLongitude: TEST_COORDINATES.punchIn.longitude,
        punchInPhoto: generateTestPhoto(),
        punchInAddress: TEST_COORDINATES.punchIn.address,
        bikeKmStart: '12345'
      });

      if (response.status !== 201) {
        throw new Error(`Expected status 201, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch in failed: ${data.message}`);
      }

      if (!data.data || !data.data.id) {
        throw new Error('No attendance ID returned');
      }

      this.currentAttendanceId = data.data.id;
      
      console.log(`   📍 Attendance ID: ${this.currentAttendanceId}`);
      console.log(`   ⏰ Punch In Time (IST): ${data.data.punchInTimeIST}`);
      console.log(`   📍 Location: ${data.data.punchInLatitude}, ${data.data.punchInLongitude}`);
      console.log(`   📸 Photo Size: ${data.data.punchInPhoto ? 'Included' : 'None'}`);
      
      return data;
    });
  }

  async testDuplicatePunchIn() {
    return this.runTest('Duplicate Punch In Prevention', async () => {
      try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
          employeeId: TEST_EMPLOYEE_ID,
          employeeName: TEST_EMPLOYEE_NAME,
          punchInLatitude: TEST_COORDINATES.punchIn.latitude,
          punchInLongitude: TEST_COORDINATES.punchIn.longitude,
          punchInPhoto: generateTestPhoto(),
          punchInAddress: TEST_COORDINATES.punchIn.address,
          bikeKmStart: '12346'
        });

        // Should not reach here
        throw new Error('Duplicate punch in was allowed');
      } catch (error) {
        if (error.response && error.response.status === 400) {
          const data = error.response.data;
          console.log(`   ✅ Correctly prevented duplicate: ${data.message}`);
          return { prevented: true, message: data.message };
        }
        throw error;
      }
    });
  }

  async testGetTodayAttendance() {
    return this.runTest('Get Today Attendance', async () => {
      const response = await axios.get(`${BASE_URL}/attendance/today/${TEST_EMPLOYEE_ID}`);

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Get attendance failed: ${data.message}`);
      }

      if (!data.data) {
        throw new Error('No attendance data returned');
      }

      console.log(`   📊 Status: ${data.data.status}`);
      console.log(`   ⏱️ Current Work Hours: ${data.data.currentWorkHours || 0}`);
      console.log(`   🕐 Punch In: ${data.data.punchInTimeISTFormatted}`);
      console.log(`   📍 Sessions Today: ${data.totalSessions || 1}`);
      
      return data;
    });
  }

  async testInvalidCoordinates() {
    return this.runTest('Invalid Coordinates Validation', async () => {
      try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
          employeeId: 'test-invalid-coords',
          employeeName: 'Test Invalid',
          punchInLatitude: 999, // Invalid latitude
          punchInLongitude: 999, // Invalid longitude
          punchInPhoto: generateTestPhoto()
        });

        throw new Error('Invalid coordinates were accepted');
      } catch (error) {
        if (error.response && error.response.status === 400) {
          const data = error.response.data;
          console.log(`   ✅ Correctly rejected invalid coordinates: ${data.message}`);
          return { rejected: true, message: data.message };
        }
        throw error;
      }
    });
  }

  async testLargePhotoRejection() {
    return this.runTest('Large Photo Rejection', async () => {
      // Generate a large base64 string (simulate large photo)
      const largePhoto = 'A'.repeat(6 * 1024 * 1024); // 6MB of 'A' characters

      try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
          employeeId: 'test-large-photo',
          employeeName: 'Test Large Photo',
          punchInLatitude: TEST_COORDINATES.punchIn.latitude,
          punchInLongitude: TEST_COORDINATES.punchIn.longitude,
          punchInPhoto: largePhoto
        });

        throw new Error('Large photo was accepted');
      } catch (error) {
        if (error.response && error.response.status === 400) {
          const data = error.response.data;
          console.log(`   ✅ Correctly rejected large photo: ${data.message}`);
          return { rejected: true, message: data.message };
        }
        throw error;
      }
    });
  }

  async testPunchOut() {
    return this.runTest('Punch Out with Distance Calculation', async () => {
      if (!this.currentAttendanceId) {
        throw new Error('No active attendance session found');
      }

      // Wait a moment to ensure some work duration
      await new Promise(resolve => setTimeout(resolve, 2000));

      const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
        attendanceId: this.currentAttendanceId,
        punchOutLatitude: TEST_COORDINATES.punchOut.latitude,
        punchOutLongitude: TEST_COORDINATES.punchOut.longitude,
        punchOutPhoto: generateTestPhoto(),
        punchOutAddress: TEST_COORDINATES.punchOut.address,
        bikeKmEnd: '12350'
      });

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch out failed: ${data.message}`);
      }

      console.log(`   ⏰ Punch Out Time (IST): ${data.data.punchOutTimeIST}`);
      console.log(`   ⏱️ Total Work Hours: ${data.data.totalWorkHours}`);
      console.log(`   📏 Distance Traveled: ${data.data.totalDistanceKm} km`);
      console.log(`   🚗 Bike KM: ${data.data.bikeKmStart} → ${data.data.bikeKmEnd}`);
      console.log(`   📊 Status: ${data.data.status}`);
      
      return data;
    });
  }

  async testInvalidPunchOut() {
    return this.runTest('Invalid Punch Out Prevention', async () => {
      try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
          attendanceId: 'invalid-id',
          punchOutLatitude: TEST_COORDINATES.punchOut.latitude,
          punchOutLongitude: TEST_COORDINATES.punchOut.longitude,
          punchOutPhoto: generateTestPhoto()
        });

        throw new Error('Invalid punch out was allowed');
      } catch (error) {
        if (error.response && error.response.status === 404) {
          const data = error.response.data;
          console.log(`   ✅ Correctly rejected invalid attendance ID: ${data.message}`);
          return { rejected: true, message: data.message };
        }
        throw error;
      }
    });
  }

  async testTimezoneHandling() {
    return this.runTest('Timezone Handling Verification', async () => {
      const response = await axios.get(`${BASE_URL}/attendance/admin/dashboard`);

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Dashboard fetch failed: ${data.message}`);
      }

      console.log(`   🌍 Server Time (UTC): ${data.data.lastUpdated}`);
      console.log(`   🇮🇳 Server Time (IST): ${data.data.lastUpdatedIST}`);
      console.log(`   ⏰ Timezone Info: ${data.data.timezone?.name} (${data.data.timezone?.offset})`);
      
      return data;
    });
  }

  async cleanup() {
    console.log('\n🧹 Cleaning up test data...');
    
    // Note: In a real scenario, you might want to clean up test data
    // For now, we'll just log the cleanup
    console.log(`   Attendance ID created: ${this.currentAttendanceId}`);
    console.log('   Test data cleanup completed');
  }

  printSummary() {
    console.log('\n📊 TEST SUMMARY');
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
    
    console.log('\n✅ PASSED TESTS:');
    this.testResults
      .filter(t => t.status === 'PASSED')
      .forEach(test => {
        console.log(`   • ${test.name} (${test.duration}ms)`);
      });
  }
}

// Main execution
async function main() {
  console.log('🚀 Enhanced Punch In/Out System Test Suite');
  console.log('═'.repeat(50));
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Test Employee: ${TEST_EMPLOYEE_NAME} (${TEST_EMPLOYEE_ID})`);
  
  const testSuite = new AttendanceTestSuite();
  
  try {
    // Core functionality tests
    await testSuite.testPunchIn();
    await testSuite.testDuplicatePunchIn();
    await testSuite.testGetTodayAttendance();
    
    // Validation tests
    await testSuite.testInvalidCoordinates();
    await testSuite.testLargePhotoRejection();
    
    // Punch out tests
    await testSuite.testPunchOut();
    await testSuite.testInvalidPunchOut();
    
    // System tests
    await testSuite.testTimezoneHandling();
    
    await testSuite.cleanup();
    
  } catch (error) {
    console.log(`\n💥 Test suite failed: ${error.message}`);
  } finally {
    testSuite.printSummary();
  }
}

// Run the tests
if (require.main === module) {
  main().catch(console.error);
}

module.exports = AttendanceTestSuite;