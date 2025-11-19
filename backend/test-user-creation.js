import prisma from './src/config/db.js';
import { randomUUID } from 'crypto';

async function testUserCreation() {
  try {
    console.log('🔄 Testing user creation with new fields...\n');
    
    // Create a test user with all new fields
    const testUser = await prisma.user.create({
      data: {
        id: randomUUID(),
        contactNumber: '9999999999',
        name: 'Test User',
        email: 'test@example.com',
        alternativeNumber: '8888888888',
        gender: 'Male',
        address: '123 Test Street',
        city: 'Test City',
        state: 'Test State',
        pincode: '123456',
        aadharCard: '123456789012',
        panCard: 'ABCDE1234F',
        password: 'test123',
        notes: 'This is a test user',
        roles: ['role1', 'role2'],
        isActive: true,
      },
    });

    console.log('✅ User created successfully!');
    console.log('📋 User details:');
    console.log('   ID:', testUser.id);
    console.log('   Name:', testUser.name);
    console.log('   Email:', testUser.email);
    console.log('   Contact:', testUser.contactNumber);
    console.log('   Alternative:', testUser.alternativeNumber);
    console.log('   Address:', testUser.address);
    console.log('   City:', testUser.city);
    console.log('   State:', testUser.state);
    console.log('   Pincode:', testUser.pincode);
    console.log('   Aadhar:', testUser.aadharCard);
    console.log('   PAN:', testUser.panCard);
    console.log('   Roles:', testUser.roles);
    console.log('   Notes:', testUser.notes);
    console.log('\n✅ All fields are working correctly!');
    
    // Clean up - delete test user
    await prisma.user.delete({
      where: { id: testUser.id },
    });
    console.log('🗑️  Test user deleted\n');
    
    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\nFull error:', error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

testUserCreation();
