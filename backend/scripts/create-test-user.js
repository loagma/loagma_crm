import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function createTestUser() {
  try {
    console.log('👤 Creating test user...');
    
    // Step 1: Send OTP
    const otpResponse = await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: '9876543210'
    });
    
    console.log('📱 OTP sent:', otpResponse.data.message);
    
    // Step 2: Verify OTP
    const verifyResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: '9876543210',
      otp: '5555'
    });
    
    console.log('✅ OTP verified:', verifyResponse.data.message);
    
    if (verifyResponse.data.isNewUser) {
      // Step 3: Complete signup
      const signupResponse = await axios.post(`${BASE_URL}/auth/complete-signup`, {
        contactNumber: '9876543210',
        name: 'Test Salesman',
        email: 'test.salesman@example.com',
        roles: ['salesman'],
        departmentId: 'sales'
      });
      
      console.log('🎉 User created:', signupResponse.data.data.name);
      console.log('📋 Full response:', JSON.stringify(signupResponse.data, null, 2));
      return signupResponse.data;
    } else {
      console.log('👤 User already exists');
      return verifyResponse.data;
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

createTestUser();