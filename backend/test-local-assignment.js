import axios from 'axios';

// Test against LOCAL backend
const BASE_URL = 'http://localhost:3000';

async function testLocalAssignment() {
  console.log('🧪 Testing LOCAL Assignment API\n');
  console.log('=' .repeat(80));

  try {
    // Test if server is running
    console.log('\n📋 Step 1: Checking if local server is running...');
    try {
      await axios.get(`${BASE_URL}/health`);
      console.log('✅ Local server is running');
    } catch (error) {
      console.log('❌ Local server is NOT running');
      console.log('💡 Start the backend with: cd backend && npm start');
      return;
    }

    // Fetch salesmen
    console.log('\n📋 Step 2: Fetching Salesmen...');
    const salesmenResponse = await axios.get(`${BASE_URL}/task-assignments/salesmen`);
    console.log('✅ Status:', salesmenResponse.status);
    console.log('📊 Salesmen Count:', salesmenResponse.data.count);

    const salesman = salesmenResponse.data.salesmen[0];
    console.log(`\n🎯 Using Salesman: ${salesman.name} (${salesman.id})`);

    // Assign areas
    console.log('\n📋 Step 3: Assigning Areas to Salesman...');
    const assignmentPayload = {
      salesmanId: salesman.id,
      salesmanName: salesman.name,
      pincode: '482002',
      country: 'India',
      state: 'Madhya Pradesh',
      district: 'Jabalpur',
      city: 'Jabalpur',
      areas: ['Ganjipura', 'Wright Town'],
      businessTypes: ['grocery', 'cafe'],
      totalBusinesses: 0
    };

    console.log('📤 Assignment Payload:', JSON.stringify(assignmentPayload, null, 2));

    const assignmentResponse = await axios.post(
      `${BASE_URL}/task-assignments/assignments/areas`,
      assignmentPayload,
      { headers: { 'Content-Type': 'application/json' } }
    );

    console.log('✅ Status:', assignmentResponse.status);
    console.log('📊 Assignment Response:', JSON.stringify(assignmentResponse.data, null, 2));

    // Verify assignment
    console.log('\n📋 Step 4: Verifying Assignment...');
    const verifyResponse = await axios.get(
      `${BASE_URL}/task-assignments/assignments/salesman/${salesman.id}`
    );
    console.log('✅ Status:', verifyResponse.status);
    console.log('📊 Assignments Count:', verifyResponse.data.assignments.length);

    console.log('\n' + '='.repeat(80));
    console.log('✅ LOCAL TEST COMPLETED SUCCESSFULLY');

  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    if (error.response) {
      console.error('📡 Response Status:', error.response.status);
      console.error('📡 Response Data:', JSON.stringify(error.response.data, null, 2));
    }
    console.log('\n' + '='.repeat(80));
    console.log('❌ LOCAL TEST FAILED');
  }
}

testLocalAssignment();
