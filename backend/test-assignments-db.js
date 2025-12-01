import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testAssignments() {
  console.log('🔍 Testing Task Assignments in Database\n');

  try {
    // Get all task assignments
    const assignments = await prisma.taskAssignment.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    console.log(`📊 Total assignments in database: ${assignments.length}\n`);

    if (assignments.length > 0) {
      console.log('📋 Recent Assignments:');
      console.log('─'.repeat(80));
      
      assignments.forEach((assignment, index) => {
        console.log(`\n${index + 1}. Assignment ID: ${assignment.id}`);
        console.log(`   Salesman: ${assignment.salesmanName} (${assignment.salesmanId})`);
        console.log(`   Pincode: ${assignment.pincode}`);
        console.log(`   City: ${assignment.city}, ${assignment.state}`);
        console.log(`   Areas: ${assignment.areas.join(', ')}`);
        console.log(`   Business Types: ${assignment.businessTypes.join(', ')}`);
        console.log(`   Total Businesses: ${assignment.totalBusinesses}`);
        console.log(`   Assigned Date: ${assignment.assignedDate}`);
      });
    } else {
      console.log('❌ No assignments found in database');
    }

    // Get all shops
    const shops = await prisma.shop.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    console.log(`\n\n🏪 Total shops in database: ${shops.length}\n`);

    if (shops.length > 0) {
      console.log('📋 Recent Shops:');
      console.log('─'.repeat(80));
      
      shops.forEach((shop, index) => {
        console.log(`\n${index + 1}. ${shop.name}`);
        console.log(`   Type: ${shop.businessType}`);
        console.log(`   Pincode: ${shop.pincode}`);
        console.log(`   Assigned To: ${shop.assignedTo || 'Not assigned'}`);
        console.log(`   Stage: ${shop.stage}`);
      });
    } else {
      console.log('❌ No shops found in database');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testAssignments();
