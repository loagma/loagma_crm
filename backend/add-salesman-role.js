import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function addSalesmanRole() {
  try {
    const userId = process.argv[2];

    if (!userId) {
      console.log('❌ Please provide a user ID');
      console.log('Usage: node add-salesman-role.js <userId>');
      
      // Show available users
      const users = await prisma.user.findMany({
        select: {
          id: true,
          name: true,
          contactNumber: true,
          employeeCode: true,
          roles: true
        }
      });

      console.log('\n📋 Available users:');
      users.forEach((u, i) => {
        console.log(`${i + 1}. ID: ${u.id}`);
        console.log(`   Name: ${u.name || 'No name'}`);
        console.log(`   Code: ${u.employeeCode || 'No code'}`);
        console.log(`   Contact: ${u.contactNumber}`);
        console.log(`   Current Roles: ${u.roles.join(', ')}`);
        console.log('');
      });

      return;
    }

    // Get user
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      console.log(`❌ User with ID ${userId} not found`);
      return;
    }

    console.log(`\n👤 User found: ${user.name || 'No name'} (${user.contactNumber})`);
    console.log(`📋 Current roles: ${user.roles.join(', ')}`);

    // Check if already has salesman role
    if (user.roles.includes('salesman') || user.roles.includes('Salesman')) {
      console.log('✅ User already has salesman role!');
      return;
    }

    // Add salesman role
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        roles: [...user.roles, 'salesman']
      }
    });

    console.log(`\n✅ Successfully added salesman role!`);
    console.log(`📋 New roles: ${updatedUser.roles.join(', ')}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

addSalesmanRole();
