import axios from 'axios';

const BASE_URL = 'https://loagma-crm.onrender.com';

async function testBusinessSearch() {
  console.log('🧪 Testing Business Search by Type\n');
  console.log('=' .repeat(80));

  const testCases = [
    { pincode: '482002', types: ['Hotel'], expected: 'hotels/lodging' },
    { pincode: '482002', types: ['Cafe'], expected: 'cafes' },
    { pincode: '482002', types: ['Grocery'], expected: 'grocery stores' },
    { pincode: '482002', types: ['Schools'], expected: 'schools' },
    { pincode: '482002', types: ['Hospitals'], expected: 'hospitals' },
    { pincode: '482002', types: ['Restaurant'], expected: 'restaurants' },
  ];

  for (const testCase of testCases) {
    console.log(`\n📋 Test: Searching for ${testCase.types[0]} in ${testCase.pincode}`);
    console.log(`   Expected: ${testCase.expected}`);
    console.log('─'.repeat(60));

    try {
      const response = await axios.post(
        `${BASE_URL}/task-assignments/businesses/search`,
        {
          pincode: testCase.pincode,
          areas: [],
          businessTypes: testCase.types
        },
        { 
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000
        }
      );

      if (response.status === 200 && response.data.success) {
        const businesses = response.data.businesses || [];
        console.log(`✅ Status: ${response.status}`);
        console.log(`📊 Found: ${businesses.length} businesses`);
        
        if (businesses.length > 0) {
          console.log(`\n   Sample results (first 5):`);
          businesses.slice(0, 5).forEach((business, index) => {
            console.log(`   ${index + 1}. ${business.name}`);
            console.log(`      Address: ${business.address}`);
            console.log(`      Type: ${business.businessType}`);
            if (business.rating) {
              console.log(`      Rating: ${business.rating} ⭐`);
            }
          });
        } else {
          console.log(`   ⚠️  No businesses found (might be valid for this area)`);
        }
      } else {
        console.log(`❌ Failed: ${response.data.message || 'Unknown error'}`);
      }

      // Add delay between requests
      await new Promise(resolve => setTimeout(resolve, 2000));

    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Message: ${error.response.data?.message || 'Unknown'}`);
      }
    }
  }

  console.log('\n' + '='.repeat(80));
  console.log('✅ BUSINESS SEARCH TEST COMPLETED');
  console.log('=' .repeat(80));
}

testBusinessSearch();
