import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkUserData() {
  try {
    console.log('🔍 Checking user data in database...\n');
    
    // Find user by contact number
    const userByPhone = await prisma.user.findUnique({
      where: { contactNumber: '7974772962' }
    });
    
    if (userByPhone) {
      console.log('✅ Found user by phone number:');
      console.log('   ID:', userByPhone.id);
      console.log('   Name:', userByPhone.name);
      console.log('   Email:', userByPhone.email);
      console.log('   Employee Code:', userByPhone.employeeCode);
      console.log('   Contact:', userByPhone.contactNumber);
      console.log('   Active:', userByPhone.isActive);
    } else {
      console.log('❌ No user found with phone number 7974772962');
    }
    
    // Find user by ID 00002
    const userById = await prisma.user.findUnique({
      where: { id: '00002' }
    });
    
    if (userById) {
      console.log('\n✅ Found user by ID 00002:');
      console.log('   ID:', userById.id);
      console.log('   Name:', userById.name);
      console.log('   Email:', userById.email);
      console.log('   Contact:', userById.contactNumber);
    } else {
      console.log('\n❌ No user found with ID 00002');
    }
    
    // List all users to see what IDs exist
    const allUsers = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        isActive: true
      },
      take: 10
    });
    
    console.log('\n📋 All users in database:');
    allUsers.forEach(user => {
      console.log(`   ${user.id} | ${user.name} | ${user.contactNumber} | ${user.employeeCode} | Active: ${user.isActive}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUserData();