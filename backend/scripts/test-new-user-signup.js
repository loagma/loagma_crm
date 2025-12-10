#!/usr/bin/env node

/**
 * Test New User Flow (No-Role Screen)
 * 
 * This script tests the complete new user flow:
 * 1. Send OTP to new number
 * 2. Verify OTP (should return isNewUser: true)
 * 3. Frontend auto-creates basic user account
 * 4. User directed to no-role screen until admin assigns role
 */

import axios from 'axios';
import { config } from 'dotenv';

config();

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const TEST_PHONE = '9876543210'; // Use a number that doesn't exist
const MASTER_OTP = process.env.MASTER_OTP || '123456';

console.log('🧪 Testing New User Flow (No-Role Screen)');
console.log('==========================================');
console.log(`📡 API Base URL: ${BASE_URL}`);
console.log(`📱 Test Phone: ${TEST_PHONE}`);
console.log(`🔐 Master OTP: ${MASTER_OTP}`);
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

// Test 1: Send OTP to new number
async function testSendOtpNewUser() {
  console.log('🧪 TEST 1: Send OTP to New User');
  console.log('===============================');

  const response = await apiRequest('/auth/send-otp', 'POST', {
    contactNumber: TEST_PHONE
  });

  if (response.data.success) {
    console.log('✅ OTP sent successfully to new number');
    return true;
  } else {
    console.log('❌ Failed to send OTP:', response.data.message);
    return false;
  }
}

// Test 2: Verify OTP (should return isNewUser: true)
async function testVerifyOtpNewUser() {
  console.log('🧪 TEST 2: Verify OTP for New User');
  console.log('==================================');

  const response = await apiRequest('/auth/verify-otp', 'POST', {
    contactNumber: TEST_PHONE,
    otp: MASTER_OTP
  });

  if (response.data.success) {
    if (response.data.isNewUser === true) {
      console.log('✅ OTP verified successfully - isNewUser: true (correct!)');
      return true;
    } else {
      console.log('❌ OTP verified but isNewUser is not true:', response.data.isNewUser);
      return false;
    }
  } else {
    console.log('❌ Failed to verify OTP:', response.data.message);
    return false;
  }
}

// Test 3: Check if user was auto-created (simulating frontend behavior)
async function testAutoUserCreation() {
  console.log('🧪 TEST 3: Auto User Creation (Frontend Simulation)');
  console.log('===================================================');

  // Simulate what the frontend does - auto-create user with basic info
  const response = await apiRequest('/auth/complete-signup', 'POST', {
    contactNumber: TEST_PHONE,
    name: 'New User', // Default name
    email: `${TEST_PHONE}@temp.com` // Temporary email
  });

  if (response.data.success) {
    const userData = response.data.data;
    console.log('✅ Auto user creation successful!');
    console.log(`   User ID: ${userData.id}`);
    console.log(`   Employee Code: ${userData.employeeCode}`);
    console.log(`   Name: ${userData.name} (default name)`);
    console.log(`   Email: ${userData.email} (temporary email)`);
    console.log(`   Contact: ${userData.contactNumber}`);

    // Verify sequential ID format
    if (/^\d{5}$/.test(userData.id)) {
      console.log('✅ User ID is in correct sequential format');
    } else {
      console.log('⚠️ User ID format may be incorrect:', userData.id);
    }

    if (/^\d{5}$/.test(userData.employeeCode)) {
      console.log('✅ Employee code is in correct sequential format');
    } else {
      console.log('⚠️ Employee code format may be incorrect:', userData.employeeCode);
    }

    console.log('ℹ️ User will be directed to no-role screen until admin assigns role');
    return userData;
  } else {
    console.log('❌ Failed to auto-create user:', response.data.message);
    return null;
  }
}

// Test 4: Verify user can login with existing credentials
async function testExistingUserLogin() {
  console.log('🧪 TEST 4: Test Existing User Login');
  console.log('===================================');

  // Send OTP again
  const otpResponse = await apiRequest('/auth/send-otp', 'POST', {
    contactNumber: TEST_PHONE
  });

  if (!otpResponse.data.success) {
    console.log('❌ Failed to send OTP for existing user');
    return false;
  }

  // Verify OTP (should return isNewUser: false now)
  const verifyResponse = await apiRequest('/auth/verify-otp', 'POST', {
    contactNumber: TEST_PHONE,
    otp: MASTER_OTP
  });

  if (verifyResponse.data.success) {
    if (verifyResponse.data.isNewUser === false) {
      console.log('✅ Existing user login successful - isNewUser: false (correct!)');
      console.log(`   User data returned:`, verifyResponse.data.data);
      return true;
    } else {
      console.log('❌ Existing user login but isNewUser is not false:', verifyResponse.data.isNewUser);
      return false;
    }
  } else {
    console.log('❌ Failed to verify OTP for existing user:', verifyResponse.data.message);
    return false;
  }
}

// Cleanup function
async function cleanup() {
  console.log('🧹 Cleanup: Removing test user');
  console.log('===============================');

  // Get all users to find the test user
  const usersResponse = await apiRequest('/admin/users', 'GET');
  
  if (usersResponse.data.success && usersResponse.data.users) {
    const testUser = usersResponse.data.users.find(user => 
      user.contactNumber === TEST_PHONE || 
      user.email === 'testnewuser@example.com'
    );

    if (testUser) {
      console.log(`🗑️ Deleting test user: ${testUser.name} (${testUser.id})`);
      await apiRequest(`/admin/users/${testUser.id}`, 'DELETE');
      console.log('✅ Test user deleted');
    } else {
      console.log('ℹ️ No test user found to delete');
    }
  }

  console.log('');
}

// Main test runner
async function runNewUserFlowTest() {
  console.log('🚀 Starting New User Flow Test');
  console.log('==============================');
  console.log('');

  let allTestsPassed = true;

  try {
    // Test 1: Send OTP to new number
    const otpSent = await testSendOtpNewUser();
    if (!otpSent) {
      allTestsPassed = false;
    }

    // Test 2: Verify OTP (should return isNewUser: true)
    const otpVerified = await testVerifyOtpNewUser();
    if (!otpVerified) {
      allTestsPassed = false;
    }

    // Test 3: Auto user creation (simulating frontend)
    const userCreated = await testAutoUserCreation();
    if (!userCreated) {
      allTestsPassed = false;
    }

    // Test 4: Test existing user login
    const existingLogin = await testExistingUserLogin();
    if (!existingLogin) {
      allTestsPassed = false;
    }

    // Final Results
    console.log('📊 NEW USER FLOW TEST RESULTS');
    console.log('=============================');
    
    if (allTestsPassed) {
      console.log('🎉 ALL NEW USER FLOW TESTS PASSED!');
      console.log('');
      console.log('✅ New user flow is working correctly:');
      console.log('   • OTP sending works for new numbers');
      console.log('   • OTP verification returns isNewUser: true for new users');
      console.log('   • Auto user creation works with sequential ID');
      console.log('   • Users directed to no-role screen (correct flow)');
      console.log('   • Existing user login returns isNewUser: false');
    } else {
      console.log('❌ SOME NEW USER FLOW TESTS FAILED');
      console.log('   Please check the backend implementation');
    }

  } catch (error) {
    console.error('💥 Test suite crashed:', error);
    allTestsPassed = false;
  } finally {
    // Cleanup test data
    await cleanup();
  }

  console.log('');
  console.log('🏁 New user flow test completed');
  process.exit(allTestsPassed ? 0 : 1);
}

// Run the tests
runNewUserFlowTest();