import axios from 'axios';

async function simpleSalesmenTest() {
  try {
    console.log('🧪 Simple test of salesmen endpoint...');
    
    const response = await axios.get('http://localhost:5000/task-assignments/salesmen');
    
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

simpleSalesmenTest();