import axios from 'axios';

const BASE_URL = 'https://loagma-crm.onrender.com';

async function testCompleteHistory() {
  console.log('🧪 Testing Complete History Flow\n');
  console.log('=' .repeat(80));

  try {
    // Step 1: Get all salesmen
    console.log('\n📋 Step 1: Fetching All Salesmen...');
    const salesmenResponse = await axios.get(`${BASE_URL}/task-assignments/salesmen`);
    console.log('✅ Found', salesmenResponse.data.count, 'salesmen');
    
    const salesmen = salesmenResponse.data.salesmen;
    
    // Step 2: Check history for each salesman
    console.log('\n📋 Step 2: Checking History for Each Salesman...\n');
    
    for (const salesman of salesmen) {
      console.log(`\n👤 ${salesman.name} (${salesman.id})`);
      console.log('─'.repeat(60));
      
      const historyResponse = await axios.get(
        `${BASE_URL}/task-assignments/assignments/salesman/${salesman.id}`
      );
      
      const assignments = historyResponse.data.assignments || [];
      console.log(`📊 Assignments: ${assignments.length}`);
      
      if (assignments.length > 0) {
        assignments.forEach((assignment, index) => {
          console.log(`\n   ${index + 1}. Pincode: ${assignment.pincode}`);
          console.log(`      City: ${assignment.city}, ${assignment.state}`);
          console.log(`      Areas: ${assignment.areas.join(', ')}`);
          console.log(`      Business Types: ${assignment.businessTypes.join(', ')}`);
          console.log(`      Total Businesses: ${assignment.totalBusinesses}`);
          console.log(`      Assigned: ${new Date(assignment.assignedDate).toLocaleString()}`);
        });
      } else {
        console.log('   ℹ️  No assignments found');
      }
      
      // Check shops for this salesman
      const shopsResponse = await axios.get(
        `${BASE_URL}/task-assignments/shops/salesman/${salesman.id}`
      );
      
      const shops = shopsResponse.data.shops || [];
      console.log(`\n   🏪 Shops: ${shops.length}`);
      
      if (shops.length > 0) {
        // Group shops by pincode
        const shopsByPincode = {};
        shops.forEach(shop => {
          if (!shopsByPincode[shop.pincode]) {
            shopsByPincode[shop.pincode] = [];
          }
          shopsByPincode[shop.pincode].push(shop);
        });
        
        Object.entries(shopsByPincode).forEach(([pincode, pincodeShops]) => {
          console.log(`      Pincode ${pincode}: ${pincodeShops.length} shops`);
        });
      }
    }
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ HISTORY TEST COMPLETED');
    console.log('=' .repeat(80));

  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    if (error.response) {
      console.error('📡 Response Status:', error.response.status);
      console.error('📡 Response Data:', JSON.stringify(error.response.data, null, 2));
    }
    console.log('\n' + '='.repeat(80));
    console.log('❌ HISTORY TEST FAILED');
  }
}

testCompleteHistory();
