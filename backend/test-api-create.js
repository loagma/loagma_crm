import axios from 'axios';

async function testCreateAccount() {
  try {
    console.log('🧪 Testing account creation via API...\n');
    
    const accountData = {
      businessName: 'Test Business Ltd',
      businessType: 'Retail',
      personName: 'Test Person',
      contactNumber: '9999888877',
      customerStage: 'Lead',
      funnelStage: 'Awareness',
      gstNumber: '22AAAAA0000A1Z5',
      panCard: 'ABCDE1234F',
      isActive: true,
      pincode: '400001',
      country: 'India',
      state: 'Maharashtra',
      district: 'Mumbai',
      city: 'Mumbai',
      area: 'Andheri',
      address: '123 Test Street'
    };
    
    console.log('📤 Sending request to: http://localhost:5000/accounts');
    console.log('📋 Data:', JSON.stringify(accountData, null, 2));
    console.log('\n⏳ Creating account...\n');
    
    const response = await axios.post('http://localhost:5000/accounts', accountData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ SUCCESS! Account created:');
    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ ERROR creating account:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Error:', error.message);
    }
  }
}

testCreateAccount();
