import axios from 'axios';

const BASE_URL = 'https://loagma-crm.onrender.com';

async function checkDeploymentStatus() {
  console.log('🔍 Checking Deployment Status\n');
  console.log('=' .repeat(80));

  let attempt = 1;
  const maxAttempts = 10;
  const delaySeconds = 15;

  while (attempt <= maxAttempts) {
    console.log(`\n📡 Attempt ${attempt}/${maxAttempts} - Testing assignment API...`);
    
    try {
      // Try to create a test assignment
      const testPayload = {
        salesmanId: '000007',
        salesmanName: 'SEENU',
        pincode: '482002',
        country: 'India',
        state: 'Madhya Pradesh',
        district: 'Jabalpur',
        city: 'Jabalpur',
        areas: ['Test Area'],
        businessTypes: ['grocery'],
        totalBusinesses: 0
      };

      const response = await axios.post(
        `${BASE_URL}/task-assignments/assignments/areas`,
        testPayload,
        { 
          headers: { 'Content-Type': 'application/json' },
          timeout: 10000
        }
      );

      if (response.status === 200 || response.status === 201) {
        console.log('\n' + '='.repeat(80));
        console.log('✅ DEPLOYMENT SUCCESSFUL!');
        console.log('✅ Assignment API is working correctly');
        console.log('📊 Response:', JSON.stringify(response.data, null, 2));
        console.log('=' .repeat(80));
        
        // Clean up test assignment
        console.log('\n🧹 Cleaning up test assignment...');
        if (response.data.assignment?.id) {
          try {
            await axios.delete(
              `${BASE_URL}/task-assignments/assignments/${response.data.assignment.id}`
            );
            console.log('✅ Test assignment deleted');
          } catch (e) {
            console.log('⚠️  Could not delete test assignment (not critical)');
          }
        }
        
        return;
      }
    } catch (error) {
      if (error.response?.status === 500) {
        const errorMsg = error.response.data?.message || '';
        if (errorMsg.includes('primaryRole')) {
          console.log('❌ Still getting primaryRole error - deployment not complete yet');
        } else {
          console.log('❌ Different 500 error:', errorMsg.substring(0, 100));
        }
      } else if (error.code === 'ECONNABORTED') {
        console.log('⏱️  Request timeout - server might be restarting');
      } else {
        console.log('⚠️  Error:', error.message);
      }
    }

    if (attempt < maxAttempts) {
      console.log(`⏳ Waiting ${delaySeconds} seconds before next attempt...`);
      await new Promise(resolve => setTimeout(resolve, delaySeconds * 1000));
    }
    
    attempt++;
  }

  console.log('\n' + '='.repeat(80));
  console.log('⏰ Deployment check timed out');
  console.log('💡 The deployment might take longer. Check Render dashboard:');
  console.log('   https://dashboard.render.com/');
  console.log('=' .repeat(80));
}

checkDeploymentStatus();
