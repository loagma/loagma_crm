import axios from 'axios';

async function testUsersSalesmen() {
  try {
    console.log('🧪 Testing /users/salesmen endpoint...');
    
    const response = await axios.get('http://localhost:5000/users/salesmen');
    
    console.log('✅ Success!');
    console.log('📋 Response:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Data:', error.response.data);
    }
  }
}

testUsersSalesmen();