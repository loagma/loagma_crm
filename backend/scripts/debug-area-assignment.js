import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Test with the actual user ID from database
const TEST_CREDENTIALS = {
  contactNumber: '7974772962', // Sparsh Sahu's number
  otp: '5555'
};

let authToken = '';

async function login() {
  try {
    console.log('🔐 Logging in with Sparsh Sahu...');
    
    // Request OTP
    const otpResponse = await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: TEST_CREDENTIALS.contactNumber
    });
    
    console.log('📱 OTP requested:', otpResponse.data.message);
    
    // Verify OTP
    const loginResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: TEST_CREDENTIALS.contactNumber,
      otp: TEST_CREDENTIALS.otp
    });
    
    authToken = loginResponse.data.token;
    console.log('✅ Login successful');
    console.log('👤 User Data:', JSON.stringify(loginResponse.data, null, 2));
    
    return loginResponse.data.data || loginResponse.data;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    throw error;
  }
}

async function debugAreaAssignment() {
  try {
    const user = await login();
    
    console.log('\n🔍 Debugging Area Assignment...\n');
    
    // Test with the actual user ID from login response
    const actualUserId = user.id;
    console.log('🆔 Actual User ID from login:', actualUserId);
    
    // Try creating area assignment with actual user ID
    console.log('\n1️⃣ Creating area assignment with actual user ID...');
    const createResponse = await axios.post(`${BASE_URL}/area-assignments`, {
      salesmanId: actualUserId,
      pinCode: '482001',
      country: 'India',
      state: 'Madhya Pradesh',
      district: 'Jabalpur',
      city: 'Jabalpur',
      areas: ['Adhartal', 'Cantt Area'],
      businessTypes: ['store', 'restaurant'],
      totalBusinesses: 15
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ Area assignment created successfully!');
    console.log('📋 Assignment:', JSON.stringify(createResponse.data, null, 2));
    
    // Clean up - delete the test assignment
    const assignmentId = createResponse.data.assignment.id;
    await axios.delete(`${BASE_URL}/area-assignments/${assignmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    console.log('🗑️ Test assignment cleaned up');
    
  } catch (error) {
    console.error('❌ Debug failed:', error.response?.data || error.message);
    
    if (error.response?.data?.message === 'Salesman not found') {
      console.log('\n🔍 Debugging salesman lookup...');
      console.log('💡 The user ID might not match what\'s expected');
      console.log('💡 Check if the user ID format is correct');
    }
  }
}

// Also test direct database query
async function testDirectUserLookup() {
  try {
    console.log('\n🔍 Testing direct user lookup...');
    
    // Test with different possible user IDs
    const testIds = ['00002', '2', 'sparsh@gmail.com'];
    
    for (const testId of testIds) {
      try {
        const response = await axios.get(`${BASE_URL}/users/${testId}`, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log(`✅ Found user with ID "${testId}":`, response.data.user?.name);
      } catch (error) {
        console.log(`❌ No user found with ID "${testId}"`);
      }
    }
    
  } catch (error) {
    console.log('⚠️ Direct user lookup test failed:', error.message);
  }
}

// Run debug
debugAreaAssignment().then(() => {
  return testDirectUserLookup();
});