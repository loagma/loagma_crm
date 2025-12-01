import axios from 'axios';

const BASE_URL = 'http://localhost:3000/api/task-assignments';

async function testAssignmentAPI() {
  console.log('🧪 Testing Task Assignment API\n');
  console.log('='.repeat(60));

  try {
    // Test 1: Check if backend is running
    console.log('\n📡 Test 1: Checking if backend is running...');
    try {
      const healthCheck = await axios.get('http://localhost:3000/health');
      console.log('✅ Backend is running');
    } catch (e) {
      console.log('❌ Backend is NOT running!');
      console.log('   Please start backend with: cd backend && npm start');
      return;
    }

    // Test 2: Fetch salesmen
    console.log('\n👥 Test 2: Fetching salesmen...');
    const salesmenResponse = await axios.get(`${BASE_URL}/salesmen`);
    console.log(`✅ Status: ${salesmenResponse.status}`);
    console.log(`✅ Found ${salesmenResponse.data.salesmen.length} salesmen`);
    
    if (salesmenResponse.data.salesmen.length === 0) {
      console.log('❌ No salesmen found. Create a salesman first.');
      return;
    }

    const salesman = salesmenResponse.data.salesmen[0];
    console.log(`   Using: ${salesman.name} (${salesman.id})`);

    // Test 3: Assign areas
    console.log('\n📝 Test 3: Creating assignment...');
    const assignmentData = {
      salesmanId: salesman.id,
      salesmanName: salesman.name,
      pincode: '110001',
      country: 'India',
      state: 'Delhi',
      district: 'Central Delhi',
      city: 'New Delhi',
      areas: ['Connaught Place', 'Karol Bagh'],
      businessTypes: ['grocery', 'cafe'],
      totalBusinesses: 5
    };

    console.log('📤 Sending:', JSON.stringify(assignmentData, null, 2));

    const assignResponse = await axios.post(
      `${BASE_URL}/assignments/areas`,
      assignmentData
    );

    console.log(`✅ Status: ${assignResponse.status}`);
    console.log(`✅ Response:`, assignResponse.data);

    // Test 4: Fetch assignments
    console.log('\n📜 Test 4: Fetching assignments...');
    const fetchResponse = await axios.get(
      `${BASE_URL}/assignments/salesman/${salesman.id}`
    );

    console.log(`✅ Status: ${fetchResponse.status}`);
    console.log(`✅ Found ${fetchResponse.data.assignments.length} assignments`);

    if (fetchResponse.data.assignments.length > 0) {
      const latest = fetchResponse.data.assignments[0];
      console.log('\n📋 Latest Assignment:');
      console.log(`   ID: ${latest.id}`);
      console.log(`   Pincode: ${latest.pincode}`);
      console.log(`   City: ${latest.city}`);
      console.log(`   Areas: ${latest.areas.join(', ')}`);
      console.log(`   Business Types: ${latest.businessTypes.join(', ')}`);
      console.log(`   Total Businesses: ${latest.totalBusinesses}`);
    }

    console.log('\n' + '='.repeat(60));
    console.log('✅ All API tests passed!');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
    if (error.code === 'ECONNREFUSED') {
      console.error('\n⚠️  Backend is not running!');
      console.error('   Start it with: cd backend && npm start');
    }
  }
}

testAssignmentAPI();
