import axios from 'axios';

const BASE_URL = 'https://loagma-crm.onrender.com';

async function testFullAssignmentFlow() {
  console.log('🧪 Testing Full Assignment Flow\n');
  console.log('=' .repeat(80));

  try {
    // Step 1: Fetch salesmen
    console.log('\n📋 Step 1: Fetching Salesmen...');
    const salesmenResponse = await axios.get(`${BASE_URL}/task-assignments/salesmen`);
    console.log('✅ Status:', salesmenResponse.status);
    console.log('📊 Salesmen Count:', salesmenResponse.data.count);
    console.log('👥 Salesmen:', JSON.stringify(salesmenResponse.data.salesmen, null, 2));

    const salesman = salesmenResponse.data.salesmen[0];
    console.log(`\n🎯 Using Salesman: ${salesman.name} (${salesman.id})`);

    // Step 2: Get location by pincode
    console.log('\n📋 Step 2: Getting Location for Pincode 482002...');
    const locationResponse = await axios.get(`${BASE_URL}/task-assignments/location/pincode/482002`);
    console.log('✅ Status:', locationResponse.status);
    console.log('📍 Location:', JSON.stringify(locationResponse.data, null, 2));

    const location = locationResponse.data.location;

    // Step 3: Assign areas to salesman
    console.log('\n📋 Step 3: Assigning Areas to Salesman...');
    const assignmentPayload = {
      salesmanId: salesman.id,
      salesmanName: salesman.name,
      pincode: location.pincode,
      country: location.country,
      state: location.state,
      district: location.district,
      city: location.city,
      areas: location.areas.slice(0, 2), // Take first 2 areas
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

    // Step 4: Verify assignment was created
    console.log('\n📋 Step 4: Verifying Assignment...');
    const verifyResponse = await axios.get(
      `${BASE_URL}/task-assignments/assignments/salesman/${salesman.id}`
    );
    console.log('✅ Status:', verifyResponse.status);
    console.log('📊 Assignments:', JSON.stringify(verifyResponse.data, null, 2));

    console.log('\n' + '='.repeat(80));
    console.log('✅ FULL FLOW TEST COMPLETED SUCCESSFULLY');

  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    if (error.response) {
      console.error('📡 Response Status:', error.response.status);
      console.error('📡 Response Data:', JSON.stringify(error.response.data, null, 2));
    }
    console.log('\n' + '='.repeat(80));
    console.log('❌ FULL FLOW TEST FAILED');
  }
}

testFullAssignmentFlow();
