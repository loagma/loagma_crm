import axios from 'axios';

const RENDER_URL = 'https://loagma-crm.onrender.com';

async function testRenderSalesmen() {
  try {
    console.log('🌍 Testing Render backend salesmen endpoint...\n');
    
    // Test 1: Check if server is running
    console.log('1️⃣ Checking if Render server is running...');
    const healthResponse = await axios.get(`${RENDER_URL}/health`);
    console.log('✅ Render server is running:', healthResponse.data.message);
    
    // Test 2: Try to access salesmen endpoint without auth
    console.log('\n2️⃣ Testing /task-assignments/salesmen endpoint...');
    try {
      const salesmenResponse = await axios.get(`${RENDER_URL}/task-assignments/salesmen`);
      console.log('✅ Salesmen endpoint accessible!');
      console.log('📋 Response:', JSON.stringify(salesmenResponse.data, null, 2));
      
      if (salesmenResponse.data.success && salesmenResponse.data.salesmen) {
        console.log(`\n👨‍💼 Found ${salesmenResponse.data.salesmen.length} salesmen on Render backend`);
        salesmenResponse.data.salesmen.forEach(salesman => {
          console.log(`   - ${salesman.id} | ${salesman.name} | ${salesman.contactNumber}`);
        });
      }
    } catch (salesmenError) {
      console.log('❌ Salesmen endpoint error:', salesmenError.response?.status, salesmenError.response?.data?.message);
      
      if (salesmenError.response?.status === 404) {
        console.log('💡 The /task-assignments/salesmen endpoint does not exist on Render backend');
      }
    }
    
    // Test 3: Try alternative endpoints
    console.log('\n3️⃣ Testing alternative endpoints...');
    
    const endpoints = [
      '/users/get-all',
      '/users/salesmen', 
      '/salesman',
      '/employees'
    ];
    
    for (const endpoint of endpoints) {
      try {
        const response = await axios.get(`${RENDER_URL}${endpoint}`);
        console.log(`✅ ${endpoint} - Status: ${response.status}`);
      } catch (error) {
        console.log(`❌ ${endpoint} - Status: ${error.response?.status || 'Network Error'}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Render backend test failed:', error.message);
    
    if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      console.log('💡 Render backend might be sleeping or unavailable');
      console.log('💡 Try accessing https://loagma-crm.onrender.com in browser to wake it up');
    }
  }
}

testRenderSalesmen();