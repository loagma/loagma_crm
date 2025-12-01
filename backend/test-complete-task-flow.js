import { PrismaClient } from '@prisma/client';
import axios from 'axios';

const prisma = new PrismaClient();
const BASE_URL = 'http://localhost:3000/api/task-assignments';

async function testCompleteFlow() {
  console.log('🧪 Testing Complete Task Assignment Flow\n');
  console.log('='.repeat(60));

  try {
    // Test 1: Fetch Salesmen
    console.log('\n📋 Test 1: Fetching Salesmen...');
    const salesmenResponse = await axios.get(`${BASE_URL}/salesmen`);
    console.log(`✅ Status: ${salesmenResponse.status}`);
    console.log(`✅ Found ${salesmenResponse.data.salesmen.length} salesmen`);
    
    if (salesmenResponse.data.salesmen.length > 0) {
      const salesman = salesmenResponse.data.salesmen[0];
      console.log(`   First salesman: ${salesman.name} (${salesman.employeeCode})`);
      
      // Test 2: Fetch Location by Pincode
      console.log('\n📍 Test 2: Fetching Location for Pincode 110001...');
      const locationResponse = await axios.get(`${BASE_URL}/location/pincode/110001`);
      console.log(`✅ Status: ${locationResponse.status}`);
      if (locationResponse.data.success) {
        const location = locationResponse.data.location;
        console.log(`   City: ${location.city}`);
        console.log(`   State: ${location.state}`);
        console.log(`   Areas: ${location.areas.length}`);
      }

      // Test 3: Search Businesses
      console.log('\n🔍 Test 3: Searching Businesses...');
      const searchResponse = await axios.post(`${BASE_URL}/businesses/search`, {
        pincode: '110001',
        areas: [],
        businessTypes: ['grocery', 'cafe']
      });
      console.log(`✅ Status: ${searchResponse.status}`);
      if (searchResponse.data.success) {
        console.log(`   Total businesses: ${searchResponse.data.totalBusinesses}`);
        console.log(`   Breakdown:`, searchResponse.data.breakdown);
      }

      // Test 4: Assign Areas
      console.log('\n📝 Test 4: Assigning Areas to Salesman...');
      const assignResponse = await axios.post(`${BASE_URL}/assignments/areas`, {
        salesmanId: salesman.id,
        salesmanName: salesman.name,
        pincode: '110001',
        country: 'India',
        state: 'Delhi',
        district: 'Central Delhi',
        city: 'New Delhi',
        areas: ['Connaught Place', 'Karol Bagh'],
        businessTypes: ['grocery', 'cafe']
      });
      console.log(`✅ Status: ${assignResponse.status}`);
      console.log(`✅ ${assignResponse.data.message}`);

      // Test 5: Get Assignments
      console.log('\n📜 Test 5: Fetching Assignments...');
      const assignmentsResponse = await axios.get(
        `${BASE_URL}/assignments/salesman/${salesman.id}`
      );
      console.log(`✅ Status: ${assignmentsResponse.status}`);
      console.log(`✅ Found ${assignmentsResponse.data.assignments.length} assignments`);

      // Test 6: Save Shops (if businesses were found)
      if (searchResponse.data.businesses && searchResponse.data.businesses.length > 0) {
        console.log('\n🏪 Test 6: Saving Shops...');
        const shops = searchResponse.data.businesses.slice(0, 3); // Save first 3
        const saveResponse = await axios.post(`${BASE_URL}/shops`, {
          shops: shops,
          salesmanId: salesman.id
        });
        console.log(`✅ Status: ${saveResponse.status}`);
        console.log(`✅ ${saveResponse.data.message}`);
      }

      // Test 7: Get Shops by Salesman
      console.log('\n🏬 Test 7: Fetching Shops by Salesman...');
      const shopsResponse = await axios.get(
        `${BASE_URL}/shops/salesman/${salesman.id}`
      );
      console.log(`✅ Status: ${shopsResponse.status}`);
      console.log(`✅ Found ${shopsResponse.data.shops.length} shops`);
    }

    console.log('\n' + '='.repeat(60));
    console.log('✅ All tests passed successfully!');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    if (error.response) {
      console.error('   Response:', error.response.data);
    }
  } finally {
    await prisma.$disconnect();
  }
}

testCompleteFlow();
