import axios from 'axios';

const API_URL = 'http://localhost:5000';

console.log('🧪 Testing Send OTP API Endpoint...\n');

const testSendOtp = async () => {
  try {
    const response = await axios.post(`${API_URL}/auth/send-otp`, {
      contactNumber: '9285543488'
    });

    console.log('✅ API Response:');
    console.log(JSON.stringify(response.data, null, 2));
    console.log('\n✅ OTP sent successfully!');
    console.log('📱 Check the backend console for the OTP (Mock SMS mode)');
  } catch (error) {
    if (error.response) {
      console.error('❌ API Error:', error.response.status);
      console.error('Response:', error.response.data);
    } else if (error.request) {
      console.error('❌ No response from server. Is the backend running?');
      console.error('Start backend with: npm run dev');
    } else {
      console.error('❌ Error:', error.message);
    }
  }
};

testSendOtp();
