import axios from 'axios';

const RENDER_URL = 'https://loagma-crm.onrender.com';

async function checkRenderUsers() {
  try {
    console.log('🌍 Checking users on Render backend...\n');
    
    // Test users endpoint
    const usersResponse = await axios.get(`${RENDER_URL}/users/get-all`);
    console.log('📋 Users response:', JSON.stringify(usersResponse.data, null, 2));
    
    if (usersResponse.data.success && usersResponse.data.data) {
      const users = usersResponse.data.data;
      console.log(`\n👥 Found ${users.length} users on Render backend:`);
      
      users.forEach(user => {
        console.log(`   - ${user.id} | ${user.name} | RoleId: ${user.roleId} | Role: ${user.role?.name || 'No role'}`);
      });
      
      // Check for potential salesmen
      const potentialSalesmen = users.filter(user => 
        user.roleId === 'R002' || 
        (user.role && user.role.name === 'salesman') ||
        (user.roles && user.roles.includes('salesman'))
      );
      
      console.log(`\n👨‍💼 Potential salesmen: ${potentialSalesmen.length}`);
      potentialSalesmen.forEach(salesman => {
        console.log(`   - ${salesman.id} | ${salesman.name}`);
      });
      
      if (potentialSalesmen.length === 0) {
        console.log('\n💡 No salesmen found on Render backend');
        console.log('💡 You need to create salesman users on Render or sync data from local');
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

checkRenderUsers();