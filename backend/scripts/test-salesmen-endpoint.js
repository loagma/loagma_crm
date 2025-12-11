import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function testSalesmenEndpoint() {
  try {
    console.log('🧪 Testing /task-assignments/salesmen endpoint...\n');
    
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
    console.log('✅ Login successful');
    
    // Step 2: Test the salesmen endpoint
    console.log('\n2️⃣ Testing /task-assignments/salesmen endpoint...');
    const response = await axios.get(`${BASE_URL}/task-assignments/salesmen`, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    });
    
    console.log('📡 Status:', response.status);
    console.log('📋 Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      const salesmen = response.data.salesmen;
      console.log(`\n👨‍💼 Found ${salesmen.length} salesmen:`);
      
      salesmen.forEach(salesman => {
        console.log(`   ${salesman.id} | ${salesman.name} | ${salesman.contactNumber} | RoleId: ${salesman.roleId}`);
      });
      
      if (salesmen.length === 0) {
        console.log('\n⚠️  No salesmen found!');
        console.log('💡 Check the filtering logic in getAllSalesmen');
      } else {
        console.log('\n✅ Salesmen endpoint is working correctly!');
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

testSalesmenEndpoint();