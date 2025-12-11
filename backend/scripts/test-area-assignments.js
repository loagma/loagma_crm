import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Test credentials (replace with actual test user)
const TEST_CREDENTIALS = {
  contactNumber: '9876543210', // Replace with actual test salesman number
  otp: '5555' // Master OTP
};

let authToken = '';

async function login() {
  try {
    console.log('🔐 Logging in...');
    
    // Request OTP
    const otpResponse = await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: TEST_CREDENTIALS.contactNumber
    });
    
    console.log('📱 OTP requested:', otpResponse.data.message);
    
    // Verify OTP
    const loginResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: TEST_CREDENTIALS.contactNumber,
      otp: TEST_CREDENTIALS.otp
    });
    
    authToken = loginResponse.data.token;
    console.log('✅ Login successful');
    console.log('👤 User:', loginResponse.data.data?.name || 'Unknown');
    
    return loginResponse.data.data || { id: loginResponse.data.userId };
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    throw error;
  }
}

async function testAreaAssignments() {
  try {
    const user = await login();
    
    console.log('\n📍 Testing Area Assignments API...\n');
    
    // Test 1: Create area assignment
    console.log('1️⃣ Creating area assignment...');
    const createResponse = await axios.post(`${BASE_URL}/area-assignments`, {
      salesmanId: user.id,
      pinCode: '400001',
      country: 'India',
      state: 'Maharashtra',
      district: 'Mumbai',
      city: 'Mumbai',
      areas: ['Colaba', 'Fort', 'Churchgate'],
      businessTypes: ['store', 'restaurant', 'bank'],
      totalBusinesses: 25
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ Area assignment created:', createResponse.data.assignment.id);
    const assignmentId = createResponse.data.assignment.id;
    
    // Test 2: Get all area assignments
    console.log('\n2️⃣ Getting all area assignments...');
    const allResponse = await axios.get(`${BASE_URL}/area-assignments`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log(`✅ Found ${allResponse.data.assignments.length} area assignments`);
    
    // Test 3: Get salesman's area assignments
    console.log('\n3️⃣ Getting salesman area assignments...');
    const salesmanResponse = await axios.get(`${BASE_URL}/area-assignments/salesman/${user.id}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log(`✅ Found ${salesmanResponse.data.assignments.length} assignments for salesman`);
    
    // Test 4: Get area assignment by ID
    console.log('\n4️⃣ Getting area assignment by ID...');
    const byIdResponse = await axios.get(`${BASE_URL}/area-assignments/${assignmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ Area assignment details:', byIdResponse.data.assignment.city);
    
    // Test 5: Update area assignment
    console.log('\n5️⃣ Updating area assignment...');
    const updateResponse = await axios.put(`${BASE_URL}/area-assignments/${assignmentId}`, {
      totalBusinesses: 30,
      areas: ['Colaba', 'Fort', 'Churchgate', 'Marine Drive']
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ Area assignment updated:', updateResponse.data.assignment.totalBusinesses);
    
    // Test 6: Search area assignments
    console.log('\n6️⃣ Searching area assignments...');
    const searchResponse = await axios.get(`${BASE_URL}/area-assignments/search?city=Mumbai`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log(`✅ Found ${searchResponse.data.assignments.length} assignments in Mumbai`);
    
    // Test 7: Delete area assignment
    console.log('\n7️⃣ Deleting area assignment...');
    await axios.delete(`${BASE_URL}/area-assignments/${assignmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ Area assignment deleted');
    
    console.log('\n🎉 All area assignment tests passed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    if (error.response?.status === 404) {
      console.log('💡 Note: Make sure the backend server is running and the database is migrated');
    }
  }
}

// Run tests
testAreaAssignments();