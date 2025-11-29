import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function testEndpoint() {
  try {
    console.log('🧪 Testing Task Assignment Endpoints\n');

    // Test 1: Health check
    console.log('1️⃣ Testing health endpoint...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health check:', healthResponse.data);
    console.log('');

    // Test 2: Salesmen endpoint (without auth - should fail)
    console.log('2️⃣ Testing salesmen endpoint (without auth)...');
    try {
      await axios.get(`${BASE_URL}/task-assignments/salesmen`);
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Correctly requires authentication (401)');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }
    console.log('');

    // Test 3: Login to get token
    console.log('3️⃣ Attempting login...');
    console.log('⚠️  You need to provide valid credentials');
    console.log('   Edit this file and add your admin credentials\n');

    // Uncomment and add your credentials:
    /*
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      contactNumber: 'YOUR_ADMIN_PHONE',
      password: 'YOUR_PASSWORD' // or use OTP flow
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Login successful, got token');
    console.log('');

    // Test 4: Salesmen endpoint (with auth)
    console.log('4️⃣ Testing salesmen endpoint (with auth)...');
    const salesmenResponse = await axios.get(
      `${BASE_URL}/task-assignments/salesmen`,
      {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      }
    );
    
    console.log('✅ Salesmen endpoint works!');
    console.log('📊 Response:', JSON.stringify(salesmenResponse.data, null, 2));
    console.log(`\n👥 Found ${salesmenResponse.data.salesmen?.length || 0} salesmen`);
    */

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
  }
}

console.log('🚀 Starting endpoint tests...\n');
console.log('⚠️  Make sure backend is running: npm run dev\n');

testEndpoint();
