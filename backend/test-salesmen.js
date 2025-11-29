import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testSalesmen() {
  try {
    console.log('🔍 Checking for salesmen in database...\n');

    // Check all users
    const allUsers = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        roles: true,
        isActive: true
      }
    });

    console.log(`📊 Total users in database: ${allUsers.length}\n`);

    // Check for salesmen
    const salesmen = await prisma.user.findMany({
      where: {
        OR: [
          { roles: { has: 'salesman' } },
          { roles: { has: 'Salesman' } }
        ],
        isActive: true
      },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        email: true,
        roles: true
      }
    });

    console.log(`👥 Salesmen found: ${salesmen.length}\n`);

    if (salesmen.length > 0) {
      console.log('✅ Salesmen in database:');
      salesmen.forEach((s, i) => {
        console.log(`${i + 1}. ${s.name} (${s.employeeCode}) - Roles: ${s.roles.join(', ')}`);
      });
    } else {
      console.log('⚠️  No salesmen found in database!');
      console.log('\n📝 Available users and their roles:');
      allUsers.forEach((u, i) => {
        console.log(`${i + 1}. ${u.name || 'No name'} (${u.employeeCode || 'No code'}) - Roles: ${u.roles.join(', ')}`);
      });

      console.log('\n💡 To add a salesman role to a user, run:');
      console.log('node add-salesman-role.js <userId>');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testSalesmen();
