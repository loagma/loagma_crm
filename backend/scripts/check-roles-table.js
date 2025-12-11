import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkRolesTable() {
  try {
    console.log('🔍 Checking roles table...\n');
    
    const roles = await prisma.role.findMany();
    
    console.log('📋 All roles in database:');
    roles.forEach(role => {
      console.log(`   ${role.id} | ${role.name}`);
    });
    
    // Now check users with their role relations
    console.log('\n👥 Users with their role details:');
    const users = await prisma.user.findMany({
      include: {
        role: true
      }
    });
    
    users.forEach(user => {
      console.log(`   ${user.id} | ${user.name} | Role: ${user.role?.name || 'No role'} | RoleId: ${user.roleId}`);
    });
    
    // Find salesmen by roleId
    const salesmen = users.filter(user => user.roleId === 'R002');
    console.log(`\n✅ Found ${salesmen.length} salesmen (roleId = R002):`);
    salesmen.forEach(salesman => {
      console.log(`   - ${salesman.id} | ${salesman.name} | ${salesman.contactNumber}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkRolesTable();