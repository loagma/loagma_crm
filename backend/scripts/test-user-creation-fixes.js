#!/usr/bin/env node

/**
 * Test Script: User Creation Fixes Verification
 * 
 * This script tests the fixed authentication flow and sequential ID generation
 * to ensure the backend issues have been resolved.
 */

import axios from 'axios';
import { config } from 'dotenv';

config();

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const TEST_PHONE = '9999999999';
const TEST_PHONE_2 = '8888888888';
const MASTER_OTP = process.env.MASTER_OTP || '123456';

console.log('🧪 Testing User Creation Fixes');
console.log('================================');
console.log(`📡 API Base URL: ${BASE_URL}`);
console.log(`📱 Test Phone: ${TEST_PHONE}`);
console.log(`🔐 Master OTP: ${MASTER_OTP}`);
console.log('');

// Helper function to make API requests
async function apiRequest(endpoint, method = 'GET', body = null) {
  const url = `${BASE_URL}${endpoint}`;

  console.log(`📡 ${method} ${url}`);
  if (body) {
    console.log(`📦 Body:`, JSON.stringify(body, null, 2));
  }

  try {
    const response = await axios({
      method: method.toLowerCase(),
      url,
      data: body,
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

// Test 1: New User Signup Flow
async function testNewUserSignupFlow() {
  console.log('🧪 TEST 1: New User Signup Flow');
  console.log('================================');

  // Step 1: Send OTP for new user (should NOT create user)
  console.log('📞 Step 1: Send OTP for new user');
  const otpResponse = await apiRequest('/auth/send-otp', 'POST', {
    contactNumber: TEST_PHONE
  });

  if (!otpResponse.data.success) {
    console.log('❌ TEST 1 FAILED: Could not send OTP');
    return false;
  }

  // Step 2: Verify OTP (should return isNewUser: true)
  console.log('🔐 Step 2: Verify OTP for new user');
  const verifyResponse = await apiRequest('/auth/verify-otp', 'POST', {
    contactNumber: TEST_PHONE,
    otp: MASTER_OTP
  });

  if (!verifyResponse.data.success || !verifyResponse.data.isNewUser) {
    console.log('❌ TEST 1 FAILED: OTP verification should return isNewUser: true');
    console.log(`   Expected: isNewUser = true`);
    console.log(`   Actual: isNewUser = ${verifyResponse.data.isNewUser}`);
    return false;
  }

  // Step 3: Complete signup (should create user with sequential ID)
  console.log('📝 Step 3: Complete signup');
  const signupResponse = await apiRequest('/auth/complete-signup', 'POST', {
    contactNumber: TEST_PHONE,
    name: 'Test User 1',
    email: 'test1@example.com'
  });

  if (!signupResponse.data.success) {
    console.log('❌ TEST 1 FAILED: Could not complete signup');
    return false;
  }

  const userId = signupResponse.data.data.id;
  const employeeCode = signupResponse.data.data.employeeCode;

  console.log(`✅ User created with ID: ${userId}`);
  console.log(`✅ Employee code: ${employeeCode}`);

  // Verify sequential ID format (5 digits)
  if (!/^\d{5}$/.test(userId)) {
    console.log('❌ TEST 1 FAILED: User ID is not in 5-digit format');
    console.log(`   Expected format: 00001, 00002, etc.`);
    console.log(`   Actual: ${userId}`);
    return false;
  }

  if (!/^\d{5}$/.test(employeeCode)) {
    console.log('❌ TEST 1 FAILED: Employee code is not in 5-digit format');
    console.log(`   Expected format: 00001, 00002, etc.`);
    console.log(`   Actual: ${employeeCode}`);
    return false;
  }

  console.log('✅ TEST 1 PASSED: New user signup flow works correctly');
  console.log('');
  return { userId, employeeCode };
}

// Test 2: Existing User Login Flow
async function testExistingUserLoginFlow() {
  console.log('🧪 TEST 2: Existing User Login Flow');
  console.log('===================================');

  // Step 1: Send OTP for existing user
  console.log('📞 Step 1: Send OTP for existing user');
  const otpResponse = await apiRequest('/auth/send-otp', 'POST', {
    contactNumber: TEST_PHONE
  });

  if (!otpResponse.data.success) {
    console.log('❌ TEST 2 FAILED: Could not send OTP');
    return false;
  }

  // Step 2: Verify OTP (should return isNewUser: false)
  console.log('🔐 Step 2: Verify OTP for existing user');
  const verifyResponse = await apiRequest('/auth/verify-otp', 'POST', {
    contactNumber: TEST_PHONE,
    otp: MASTER_OTP
  });

  if (!verifyResponse.data.success || verifyResponse.data.isNewUser !== false) {
    console.log('❌ TEST 2 FAILED: OTP verification should return isNewUser: false');
    console.log(`   Expected: isNewUser = false`);
    console.log(`   Actual: isNewUser = ${verifyResponse.data.isNewUser}`);
    return false;
  }

  if (!verifyResponse.data.data || !verifyResponse.data.data.id) {
    console.log('❌ TEST 2 FAILED: Should return user data for existing user');
    return false;
  }

  console.log('✅ TEST 2 PASSED: Existing user login flow works correctly');
  console.log('');
  return true;
}

// Test 3: Admin User Creation with Sequential IDs
async function testAdminUserCreation() {
  console.log('🧪 TEST 3: Admin User Creation');
  console.log('==============================');

  const adminUserData = {
    contactNumber: TEST_PHONE_2,
    name: 'Admin Created User',
    email: 'admin-test@example.com',
    salaryPerMonth: 50000,
    roleId: null, // Will be set if roles exist
    departmentId: null, // Will be set if departments exist
    gender: 'Male',
    isActive: true
  };

  console.log('👤 Creating user via admin endpoint');
  const createResponse = await apiRequest('/admin/users', 'POST', adminUserData);

  if (!createResponse.data.success) {
    console.log('❌ TEST 3 FAILED: Could not create user via admin');
    return false;
  }

  const userId = createResponse.data.user.id;
  const employeeCode = createResponse.data.user.employeeCode;

  console.log(`✅ Admin created user with ID: ${userId}`);
  console.log(`✅ Employee code: ${employeeCode}`);

  // Verify sequential ID format
  if (!/^\d{5}$/.test(userId)) {
    console.log('❌ TEST 3 FAILED: Admin created user ID is not in 5-digit format');
    return false;
  }

  if (!/^\d{5}$/.test(employeeCode)) {
    console.log('❌ TEST 3 FAILED: Admin created employee code is not in 5-digit format');
    return false;
  }

  console.log('✅ TEST 3 PASSED: Admin user creation works correctly');
  console.log('');
  return { userId, employeeCode };
}

// Test 4: Sequential ID Increment
async function testSequentialIdIncrement(firstUserId, secondUserId) {
  console.log('🧪 TEST 4: Sequential ID Increment');
  console.log('==================================');

  const firstId = parseInt(firstUserId);
  const secondId = parseInt(secondUserId);

  console.log(`First user ID: ${firstUserId} (${firstId})`);
  console.log(`Second user ID: ${secondUserId} (${secondId})`);

  if (secondId !== firstId + 1) {
    console.log('❌ TEST 4 FAILED: IDs are not sequential');
    console.log(`   Expected: ${firstId + 1}`);
    console.log(`   Actual: ${secondId}`);
    return false;
  }

  console.log('✅ TEST 4 PASSED: Sequential ID increment works correctly');
  console.log('');
  return true;
}

// Test 5: Duplicate Contact Number Prevention
async function testDuplicateContactPrevention() {
  console.log('🧪 TEST 5: Duplicate Contact Number Prevention');
  console.log('==============================================');

  // Try to create another user with same contact number
  const duplicateUserData = {
    contactNumber: TEST_PHONE,
    name: 'Duplicate User',
    email: 'duplicate@example.com',
    salaryPerMonth: 30000
  };

  console.log('🚫 Attempting to create duplicate user');
  const duplicateResponse = await apiRequest('/admin/users', 'POST', duplicateUserData);

  if (duplicateResponse.data.success) {
    console.log('❌ TEST 5 FAILED: Should not allow duplicate contact numbers');
    return false;
  }

  if (!duplicateResponse.data.message.includes('already exists')) {
    console.log('❌ TEST 5 FAILED: Error message should mention user already exists');
    return false;
  }

  console.log('✅ TEST 5 PASSED: Duplicate contact number prevention works');
  console.log('');
  return true;
}

// Cleanup function
async function cleanup() {
  console.log('🧹 Cleanup: Removing test users');
  console.log('================================');

  // Get all users to find test users
  const usersResponse = await apiRequest('/admin/users', 'GET');
  
  if (usersResponse.data.success && usersResponse.data.users) {
    const testUsers = usersResponse.data.users.filter(user => 
      user.contactNumber === TEST_PHONE || 
      user.contactNumber === TEST_PHONE_2 ||
      user.email?.includes('test') ||
      user.email?.includes('admin-test')
    );

    for (const user of testUsers) {
      console.log(`🗑️ Deleting user: ${user.name} (${user.id})`);
      await apiRequest(`/admin/users/${user.id}`, 'DELETE');
    }
  }

  console.log('✅ Cleanup completed');
  console.log('');
}

// Main test runner
async function runAllTests() {
  console.log('🚀 Starting User Creation Fixes Test Suite');
  console.log('===========================================');
  console.log('');

  let allTestsPassed = true;

  try {
    // Test 1: New User Signup Flow
    const newUserResult = await testNewUserSignupFlow();
    if (!newUserResult) {
      allTestsPassed = false;
    }

    // Test 2: Existing User Login Flow
    if (newUserResult) {
      const existingUserResult = await testExistingUserLoginFlow();
      if (!existingUserResult) {
        allTestsPassed = false;
      }
    }

    // Test 3: Admin User Creation
    const adminUserResult = await testAdminUserCreation();
    if (!adminUserResult) {
      allTestsPassed = false;
    }

    // Test 4: Sequential ID Increment
    if (newUserResult && adminUserResult) {
      const sequentialResult = await testSequentialIdIncrement(
        newUserResult.userId, 
        adminUserResult.userId
      );
      if (!sequentialResult) {
        allTestsPassed = false;
      }
    }

    // Test 5: Duplicate Prevention
    const duplicateResult = await testDuplicateContactPrevention();
    if (!duplicateResult) {
      allTestsPassed = false;
    }

    // Final Results
    console.log('📊 TEST RESULTS SUMMARY');
    console.log('=======================');
    
    if (allTestsPassed) {
      console.log('🎉 ALL TESTS PASSED!');
      console.log('');
      console.log('✅ Backend user creation issues have been fixed:');
      console.log('   • OTP flow no longer auto-creates users');
      console.log('   • Sequential employee IDs (00001, 00002, etc.)');
      console.log('   • Proper isNewUser flag handling');
      console.log('   • Duplicate contact number prevention');
      console.log('   • Admin user creation with sequential IDs');
    } else {
      console.log('❌ SOME TESTS FAILED');
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
  console.log('🏁 Test suite completed');
  process.exit(allTestsPassed ? 0 : 1);
}

// Run the tests
runAllTests();