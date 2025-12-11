#!/usr/bin/env node

/**
 * Quick Timezone Test - Verify the initialization fix
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function quickTest() {
  console.log('🧪 Quick Timezone Initialization Test');
  console.log('═'.repeat(40));
  
  try {
    console.log('📍 Testing punch in with timezone fix...');
    
    const response = await axios.post(`${BASE_URL}/attendance/punch-in`, {
      employeeId: 'quick-test-001',
      employeeName: 'Quick Test User',
      punchInLatitude: 19.0760,
      punchInLongitude: 72.8777,
      punchInAddress: 'Mumbai Test Location'
    });

    if (response.status === 201 && response.data.success) {
      console.log('✅ SUCCESS: Punch in worked!');
      console.log(`   📅 Stored Time: ${response.data.data.punchInTime}`);
      console.log(`   🇮🇳 IST Format: ${response.data.data.punchInTimeIST || 'Not provided'}`);
      console.log(`   🆔 Attendance ID: ${response.data.data.id}`);
      
      // Test punch out immediately
      console.log('\n📍 Testing punch out...');
      
      const punchOutResponse = await axios.post(`${BASE_URL}/attendance/punch-out`, {
        attendanceId: response.data.data.id,
        punchOutLatitude: 19.0760,
        punchOutLongitude: 72.8777,
        punchOutAddress: 'Mumbai Test Location'
      });
      
      if (punchOutResponse.status === 200 && punchOutResponse.data.success) {
        console.log('✅ SUCCESS: Punch out worked!');
        console.log(`   📅 Punch Out Time: ${punchOutResponse.data.data.punchOutTime}`);
        console.log(`   ⏱️ Work Duration: ${punchOutResponse.data.data.totalWorkHours} hours`);
        console.log(`   📏 Distance: ${punchOutResponse.data.data.totalDistanceKm} km`);
      } else {
        console.log('❌ FAILED: Punch out failed');
        console.log(`   Error: ${punchOutResponse.data.message}`);
      }
      
    } else {
      console.log('❌ FAILED: Punch in failed');
      console.log(`   Status: ${response.status}`);
      console.log(`   Message: ${response.data.message}`);
    }
    
  } catch (error) {
    console.log('❌ ERROR:', error.response?.data?.message || error.message);
    
    if (error.message.includes('Cannot access') && error.message.includes('before initialization')) {
      console.log('\n🔧 DIAGNOSIS: Still have initialization error');
      console.log('   Check variable naming conflicts in attendanceController.js');
    } else if (error.code === 'ECONNREFUSED') {
      console.log('\n🔧 DIAGNOSIS: Server not running');
      console.log('   Start the backend server first: npm start');
    } else {
      console.log('\n🔧 DIAGNOSIS: Other error occurred');
      console.log(`   Full error: ${error.message}`);
    }
  }
}

// Run the quick test
quickTest();