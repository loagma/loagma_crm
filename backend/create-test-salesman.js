import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createTestSalesman() {
  console.log('👤 Creating Test Salesman...\n');

  try {
    // Create a test salesman
    const salesman = await prisma.user.create({
      data: {
        id: 'test-salesman-001',
        employeeCode: 'SAL001',
        name: 'Test Salesman',
        email: 'salesman@test.com',
        contactNumber: '9999999999',
        roles: ['salesman'],
        isActive: true,
      }
    });

    console.log('✅ Test salesman created successfully!');
    console.log(`   ID: ${salesman.id}`);
    console.log(`   Name: ${salesman.name}`);
    console.log(`   Code: ${salesman.employeeCode}`);
    console.log(`   Roles: ${salesman.roles.join(', ')}`);

  } catch (error) {
    if (error.code === 'P2002') {
      console.log('⚠️  Test salesman already exists');
      
      // Update existing user to be a salesman
      console.log('\n🔄 Updating existing user to salesman...');
      const updated = await prisma.user.update({
        where: { employeeCode: 'SAL001' },
        data: {
          roles: ['salesman'],
        }
      });
      console.log('✅ Updated successfully!');
      console.log(`   Name: ${updated.name}`);
    } else {
      console.error('❌ Error:', error.message);
    }
  } finally {
    await prisma.$disconnect();
  }
}

createTestSalesman();
