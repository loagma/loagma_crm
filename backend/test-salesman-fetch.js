import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testSalesmanFetch() {
  console.log('🔍 Testing Salesman Fetch Logic\n');

  try {
    // Test 1: Get all active users
    const allUsers = await prisma.user.findMany({
      where: { isActive: true },
      select: {
        id: true,
        name: true,
        employeeCode: true,
        roles: true
      }
    });

    console.log(`📊 Total active users: ${allUsers.length}\n`);

    // Test 2: Filter salesmen (case-insensitive)
    const salesmen = allUsers.filter(user => {
      if (!user.roles || user.roles.length === 0) return false;
      return user.roles.some(role => role.toLowerCase() === 'salesman');
    });

    console.log(`✅ Salesmen found: ${salesmen.length}\n`);

    // Test 3: Display all users with their roles
    console.log('👥 All Users and Their Roles:');
    console.log('─'.repeat(60));
    allUsers.forEach((user, index) => {
      const rolesList = user.roles && user.roles.length > 0 
        ? user.roles.join(', ') 
        : 'No roles';
      const isSalesman = user.roles && user.roles.some(r => r.toLowerCase() === 'salesman');
      const marker = isSalesman ? '✓ SALESMAN' : '';
      console.log(`${index + 1}. ${user.name} (${user.employeeCode})`);
      console.log(`   Roles: ${rolesList} ${marker}`);
    });

    console.log('\n' + '─'.repeat(60));
    console.log(`\n📈 Summary:`);
    console.log(`   Total Users: ${allUsers.length}`);
    console.log(`   Salesmen: ${salesmen.length}`);
    console.log(`   Others: ${allUsers.length - salesmen.length}`);

    // Test 4: Show salesmen details
    if (salesmen.length > 0) {
      console.log('\n🎯 Salesmen Details:');
      console.log('─'.repeat(60));
      salesmen.forEach((salesman, index) => {
        console.log(`${index + 1}. ${salesman.name} (${salesman.employeeCode})`);
        console.log(`   ID: ${salesman.id}`);
        console.log(`   Roles: ${salesman.roles.join(', ')}`);
      });
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testSalesmanFetch();
