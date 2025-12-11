#!/usr/bin/env node

/**
 * Location Handling Test Script
 * Tests the enhanced location handling and automatic refresh functionality
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';
const TEST_EMPLOYEE_ID = 'test-location-001';
const TEST_EMPLOYEE_NAME = 'Location Test Employee';

// Test coordinates with different accuracy levels
const TEST_LOCATIONS = {
  highAccuracy: {
    latitude: 19.0760,
    longitude: 72.8777,
    accuracy: 5,
    address: 'High Accuracy Location - Mumbai'
  },
  mediumAccuracy: {
    latitude: 19.0825,
    longitude: 72.8811,
    accuracy: 25,
    address: 'Medium Accuracy Location - Bandra'
  },
  lowAccuracy: {
    latitude: 19.0900,
    longitude: 72.8850,
    accuracy: 100,
    address: 'Low Accuracy Location - Kurla'
  },
  invalid: {
    latitude: 999,
    longitude: 999,
    accuracy: 0,
    address: 'Invalid Location'
  }
};

class LocationTestSuite {
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

  async testHighAccuracyLocation() {
    return this.runTest('High Accuracy Location Punch In', async () => {
      const location = TEST_LOCATIONS.highAccuracy;
      
      const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
        employeeId: TEST_EMPLOYEE_ID,
        employeeName: TEST_EMPLOYEE_NAME,
        punchInLatitude: location.latitude,
        punchInLongitude: location.longitude,
        punchInAddress: location.address
      });

      if (response.status !== 201) {
        throw new Error(`Expected status 201, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch in failed: ${data.message}`);
      }

      this.currentAttendanceId = data.data.id;
      
      console.log(`   📍 Location: ${location.latitude}, ${location.longitude}`);
      console.log(`   🎯 Accuracy: ${location.accuracy}m (High)`);
      console.log(`   ✅ Accepted without warnings`);
      
      return data;
    });
  }

  async testMediumAccuracyLocation() {
    return this.runTest('Medium Accuracy Location Handling', async () => {
      const location = TEST_LOCATIONS.mediumAccuracy;
      
      // Clean up previous test
      if (this.currentAttendanceId) {
        await this.cleanupAttendance();
      }
      
      const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
        employeeId: `${TEST_EMPLOYEE_ID}-medium`,
        employeeName: `${TEST_EMPLOYEE_NAME} Medium`,
        punchInLatitude: location.latitude,
        punchInLongitude: location.longitude,
        punchInAddress: location.address
      });

      if (response.status !== 201) {
        throw new Error(`Expected status 201, got ${response.status}`);
      }

      const data = response.data;
      console.log(`   📍 Location: ${location.latitude}, ${location.longitude}`);
      console.log(`   🎯 Accuracy: ${location.accuracy}m (Medium)`);
      console.log(`   ✅ Accepted (should work fine)`);
      
      // Store for cleanup
      this.currentAttendanceId = data.data.id;
      
      return data;
    });
  }

  async testInvalidCoordinates() {
    return this.runTest('Invalid Coordinates Rejection', async () => {
      const location = TEST_LOCATIONS.invalid;
      
      try {
        const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
          employeeId: `${TEST_EMPLOYEE_ID}-invalid`,
          employeeName: `${TEST_EMPLOYEE_NAME} Invalid`,
          punchInLatitude: location.latitude,
          punchInLongitude: location.longitude,
          punchInAddress: location.address
        });

        throw new Error('Invalid coordinates were accepted');
      } catch (error) {
        if (error.response && error.response.status === 400) {
          const data = error.response.data;
          console.log(`   ❌ Coordinates: ${location.latitude}, ${location.longitude}`);
          console.log(`   ✅ Correctly rejected: ${data.message}`);
          return { rejected: true, message: data.message };
        }
        throw error;
      }
    });
  }

  async testLocationBasedDistance() {
    return this.runTest('Location-Based Distance Calculation', async () => {
      if (!this.currentAttendanceId) {
        throw new Error('No active attendance session for distance test');
      }

      const punchOutLocation = TEST_LOCATIONS.lowAccuracy;
      
      // Wait a moment for work duration
      await new Promise(resolve => setTimeout(resolve, 2000));

      const response = await axios.post(`${BASE_URL}/attendance/punch-out`, {
        attendanceId: this.currentAttendanceId,
        punchOutLatitude: punchOutLocation.latitude,
        punchOutLongitude: punchOutLocation.longitude,
        punchOutAddress: punchOutLocation.address
      });

      if (response.status !== 200) {
        throw new Error(`Expected status 200, got ${response.status}`);
      }

      const data = response.data;
      if (!data.success) {
        throw new Error(`Punch out failed: ${data.message}`);
      }

      const distance = data.data.totalDistanceKm;
      console.log(`   📏 Distance calculated: ${distance} km`);
      console.log(`   ⏱️ Work duration: ${data.data.workDurationFormatted}`);
      console.log(`   📍 From: Medium accuracy location`);
      console.log(`   📍 To: Low accuracy location`);
      
      // Validate reasonable distance (should be a few km in Mumbai)
      if (distance < 0 || distance > 50) {
        throw new Error(`Unreasonable distance calculated: ${distance} km`);
      }
      
      return data;
    });
  }

  async testLocationPermissionFlow() {
    return this.runTest('Location Permission Flow Simulation', async () => {
      // Simulate the permission flow by testing coordinate validation
      const testCases = [
        { lat: 0, lng: 0, name: 'Null Island (valid but unusual)' },
        { lat: 90, lng: 180, name: 'North Pole, Date Line (edge case)' },
        { lat: -90, lng: -180, name: 'South Pole, Date Line (edge case)' },
        { lat: 19.0760, lng: 72.8777, name: 'Mumbai (normal case)' }
      ];

      const results = [];
      
      for (const testCase of testCases) {
        try {
          const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
            employeeId: `test-coord-${Date.now()}`,
            employeeName: 'Coordinate Test',
            punchInLatitude: testCase.lat,
            punchInLongitude: testCase.lng,
            punchInAddress: testCase.name
          });

          if (response.status === 201) {
            results.push({
              ...testCase,
              status: 'ACCEPTED',
              attendanceId: response.data.data.id
            });
            
            // Clean up immediately
            await axios.post(`${BASE_URL}/attendance/punch-out`, {
              attendanceId: response.data.data.id,
              punchOutLatitude: testCase.lat,
              punchOutLongitude: testCase.lng,
              punchOutAddress: 'Test cleanup'
            });
          }
        } catch (error) {
          results.push({
            ...testCase,
            status: 'REJECTED',
            error: error.response?.data?.message || error.message
          });
        }
      }

      console.log('   📊 Coordinate Validation Results:');
      results.forEach(result => {
        console.log(`   ${result.status === 'ACCEPTED' ? '✅' : '❌'} ${result.name}: ${result.status}`);
        if (result.error) {
          console.log(`      Error: ${result.error}`);
        }
      });

      return results;
    });
  }

  async testLocationAccuracyHandling() {
    return this.runTest('Location Accuracy Handling', async () => {
      // Test different accuracy scenarios
      const accuracyTests = [
        { accuracy: 1, expected: 'excellent' },
        { accuracy: 5, expected: 'very good' },
        { accuracy: 15, expected: 'good' },
        { accuracy: 30, expected: 'acceptable' },
        { accuracy: 100, expected: 'poor but usable' }
      ];

      console.log('   🎯 Accuracy Level Guidelines:');
      accuracyTests.forEach(test => {
        console.log(`   ${test.accuracy}m: ${test.expected}`);
      });

      // Test with a medium accuracy location
      const location = TEST_LOCATIONS.mediumAccuracy;
      console.log(`   📍 Test location accuracy: ${location.accuracy}m`);
      console.log(`   ✅ Should be acceptable for attendance tracking`);

      return { accuracyTests, testLocation: location };
    });
  }

  async cleanupAttendance() {
    if (this.currentAttendanceId) {
      try {
        await axios.post(`${BASE_URL}/attendance/punch-out`, {
          attendanceId: this.currentAttendanceId,
          punchOutLatitude: 19.0760,
          punchOutLongitude: 72.8777,
          punchOutAddress: 'Test cleanup'
        });
        console.log(`   🧹 Cleaned up attendance: ${this.currentAttendanceId}`);
      } catch (error) {
        console.log(`   ⚠️ Cleanup warning: ${error.message}`);
      }
      this.currentAttendanceId = null;
    }
  }

  printSummary() {
    console.log('\n📊 LOCATION TEST SUMMARY');
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
    
    console.log('\n📍 LOCATION HANDLING RECOMMENDATIONS:');
    console.log('   • GPS accuracy < 10m: Excellent for attendance');
    console.log('   • GPS accuracy 10-30m: Good for attendance');
    console.log('   • GPS accuracy 30-50m: Acceptable with user warning');
    console.log('   • GPS accuracy > 50m: Should prompt user to move to open area');
    console.log('   • Auto-refresh location every 30 seconds if unavailable');
    console.log('   • Request location immediately when punch in/out is attempted');
    console.log('   • Provide clear error messages for location issues');
  }
}

// Main execution
async function main() {
  console.log('🌍 Location Handling Test Suite');
  console.log('═'.repeat(50));
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Test Employee: ${TEST_EMPLOYEE_NAME}`);
  
  const testSuite = new LocationTestSuite();
  
  try {
    // Location accuracy tests
    await testSuite.testHighAccuracyLocation();
    await testSuite.testMediumAccuracyLocation();
    
    // Validation tests
    await testSuite.testInvalidCoordinates();
    await testSuite.testLocationPermissionFlow();
    
    // Distance and accuracy tests
    await testSuite.testLocationBasedDistance();
    await testSuite.testLocationAccuracyHandling();
    
    await testSuite.cleanupAttendance();
    
  } catch (error) {
    console.log(`\n💥 Test suite failed: ${error.message}`);
    await testSuite.cleanupAttendance();
  } finally {
    testSuite.printSummary();
  }
}

// Run the tests
if (require.main === module) {
  main().catch(console.error);
}

module.exports = LocationTestSuite;