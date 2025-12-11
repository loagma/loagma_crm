import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function testUsersEndpoint() {
  try {
    console.log('🧪 Testing /users/get-all endpoint...\n');
    
    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: '9876543210'
    });
    
    const loginResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: '9876543210',
      otp: '5555'
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Login successful, token available:', !!token);
    
    // Step 2: Test the endpoint
    console.log('\n2️⃣ Testing /users/get-all endpoint...');
    const response = await axios.get(`${BASE_URL}/users/get-all`, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    });
    
    console.log('📡 Status:', response.status);
    console.log('📋 Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      const users = response.data.data;
      console.log(`\n👥 Found ${users.length} users:`);
      
      users.forEach(user => {
        console.log(`   ${user.id} | ${user.name} | RoleId: ${user.roleId} | Role: ${user.role?.name || 'No role'}`);
      });
      
      // Filter salesmen
      const salesmen = users.filter(user => 
        user.roleId === 'R002' || (user.role && user.role.name === 'salesman')
      );
      
      console.log(`\n👨‍💼 Salesmen (${salesmen.length}):`);
      salesmen.forEach(salesman => {
        console.log(`   ${salesman.id} | ${salesman.name} | ${salesman.contactNumber}`);
      });
      
      if (salesmen.length === 0) {
        console.log('\n⚠️  No salesmen found!');
        console.log('💡 Check if users have roleId = "R002" or role.name = "salesman"');
      }
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response) {
      console.log('📡 Status:', error.response.status);
      console.log('📋 Response:', error.response.data);
    }
  }
}

testUsersEndpoint();