import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkUserRoles() {
  try {
    console.log('🔍 Checking user roles in database...\n');
    
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        contactNumber: true,
        roles: true,
        roleId: true,
      }
    });
    
    console.log('📋 All users and their roles:');
    users.forEach(user => {
      console.log(`   ${user.id} | ${user.name} | Roles: ${JSON.stringify(user.roles)} | RoleId: ${user.roleId}`);
    });
    
    // Check if any users have salesman role
    const salesmen = users.filter(user => 
      user.roles && user.roles.includes('salesman')
    );
    
    console.log(`\n✅ Found ${salesmen.length} users with 'salesman' role`);
    
    if (salesmen.length === 0) {
      console.log('\n💡 No users have "salesman" in their roles array');
      console.log('💡 You may need to update user roles or check the role field name');
      
      // Check what roles exist
      const allRoles = users.map(u => u.roles).flat().filter(Boolean);
      const uniqueRoles = [...new Set(allRoles)];
      console.log('💡 Available roles:', uniqueRoles);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUserRoles();