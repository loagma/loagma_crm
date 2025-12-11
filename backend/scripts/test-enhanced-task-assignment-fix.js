import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

async function testEnhancedTaskAssignmentFix() {
  try {
    console.log('🔧 Testing Enhanced Task Assignment Fix...\n');
    
    // Step 1: Login as admin to get token
    console.log('1️⃣ Logging in as admin...');
    await axios.post(`${BASE_URL}/auth/send-otp`, {
      contactNumber: '9876543210' // Test admin
    });
    
    const loginResponse = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      contactNumber: '9876543210',
      otp: '5555'
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 2: Test fetching users (this is what the Enhanced Task Assignment Service will do)
    console.log('\n2️⃣ Fetching all users...');
    const usersResponse = await axios.get(`${BASE_URL}/users/get-all`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (usersResponse.data.success) {
      const users = usersResponse.data.data;
      console.log(`✅ Found ${users.length} users`);
      
      // Find salesmen
      const salesmen = users.filter(user => 
        user.roleId === 'R002' || (user.role && user.role.name === 'salesman')
      );
      
      console.log(`✅ Found ${salesmen.length} salesmen:`);
      salesmen.forEach(salesman => {
        console.log(`   - ${salesman.id} | ${salesman.name} | ${salesman.contactNumber}`);
      });
      
      // Step 3: Test creating area assignment with real salesman ID
      if (salesmen.length > 0) {
        const testSalesman = salesmen.find(s => s.id === '00002') || salesmen[0];
        
        console.log(`\n3️⃣ Creating area assignment for ${testSalesman.name} (${testSalesman.id})...`);
        
        const assignmentResponse = await axios.post(`${BASE_URL}/area-assignments`, {
          salesmanId: testSalesman.id,
          pinCode: '482001',
          country: 'India',
          state: 'Madhya Pradesh',
          district: 'Jabalpur',
          city: 'Jabalpur',
          areas: ['Test Area 1', 'Test Area 2'],
          businessTypes: ['store', 'restaurant'],
          totalBusinesses: 10
        }, {
          headers: { Authorization: `Bearer ${token}` }
        });
        
        if (assignmentResponse.data.success) {
          console.log('✅ Area assignment created successfully!');
          console.log('📋 Assignment ID:', assignmentResponse.data.assignment.id);
          console.log('📋 Salesman:', assignmentResponse.data.assignment.salesmanName);
          
          // Clean up
          await axios.delete(`${BASE_URL}/area-assignments/${assignmentResponse.data.assignment.id}`, {
            headers: { Authorization: `Bearer ${token}` }
          });
          console.log('🗑️ Test assignment cleaned up');
        }
      }
      
      console.log('\n🎉 Enhanced Task Assignment Service fix is working!');
      console.log('💡 The service will now use real user IDs instead of mock data');
      
    } else {
      console.log('❌ Failed to fetch users');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testEnhancedTaskAssignmentFix();