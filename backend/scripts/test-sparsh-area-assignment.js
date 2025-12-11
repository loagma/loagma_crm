import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function testWithSparshUser() {
  try {
    console.log('🔐 Testing area assignment with Sparsh Sahu (00002)...\n');
    
    // Step 1: Login with Sparsh's credentials
    console.log('1️⃣ Sending OTP to Sparsh...');
    await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: '7974772962'
    });
    
    console.log('2️⃣ Verifying OTP...');
    const loginResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: '7974772962',
      otp: '5555'
    });
    
    const token = loginResponse.data.token;
    const userData = loginResponse.data.data;
    
    console.log('✅ Login successful!');
    console.log('👤 User ID:', userData.id);
    console.log('👤 User Name:', userData.name);
    
    // Step 2: Create area assignment with the correct user ID
    console.log('\n3️⃣ Creating area assignment...');
    const createResponse = await axios.post(`${BASE_URL}/area-assignments`, {
      salesmanId: userData.id, // This should be "00002"
      pinCode: '482001',
      country: 'India',
      state: 'Madhya Pradesh',
      district: 'Jabalpur',
      city: 'Jabalpur',
      areas: ['Adhartal', 'Cantt Area', 'Civil Lines'],
      businessTypes: ['store', 'restaurant', 'supermarket'],
      totalBusinesses: 25
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('✅ Area assignment created successfully!');
    console.log('📋 Assignment ID:', createResponse.data.assignment.id);
    console.log('📋 Salesman Name:', createResponse.data.assignment.salesmanName);
    console.log('📋 City:', createResponse.data.assignment.city);
    console.log('📋 Areas:', createResponse.data.assignment.areas);
    
    // Step 3: Fetch the assignment back
    console.log('\n4️⃣ Fetching salesman\'s area assignments...');
    const fetchResponse = await axios.get(`${BASE_URL}/area-assignments/salesman/${userData.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('✅ Found', fetchResponse.data.assignments.length, 'assignments for Sparsh');
    
    // Step 4: Clean up
    const assignmentId = createResponse.data.assignment.id;
    console.log('\n5️⃣ Cleaning up test assignment...');
    await axios.delete(`${BASE_URL}/area-assignments/${assignmentId}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('✅ Test completed successfully! 🎉');
    console.log('\n💡 The API works correctly with user ID:', userData.id);
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.data) {
      console.log('\n🔍 Error details:');
      console.log('   Status:', error.response.status);
      console.log('   Message:', error.response.data.message);
      console.log('   Error:', error.response.data.error);
    }
  }
}

testWithSparshUser();