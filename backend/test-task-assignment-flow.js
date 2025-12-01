import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testTaskAssignmentFlow() {
  console.log('🧪 Testing Task Assignment Flow\n');
  console.log('='.repeat(60));

  try {
    // -------------------------------------------------------------------
    // ✅ TEST 1: Fetch all ACTIVE SALESMEN
    // -------------------------------------------------------------------
    console.log('\n📋 Test 1: Fetching Salesmen');
    console.log('-'.repeat(60));

    // ❗ Best way: let Prisma filter (roles[] OR roleId === "salesman")
    const salesmanUsers = await prisma.user.findMany({
      where: {
        isActive: true,
        OR: [
          { roles: { has: "salesman" } },
          { roleId: "salesman" }
        ]
      },
      select: {
        id: true,
        name: true,
        employeeCode: true,
        roles: true,
        roleId: true
      }
    });

    console.log(`✅ Salesmen found: ${salesmanUsers.length}`);
    salesmanUsers.forEach((s, i) => {
      console.log(`   ${i + 1}. ${s.name} (${s.employeeCode}) | roleId: ${s.roleId} | roles: ${JSON.stringify(s.roles)}`);
    });

    if (salesmanUsers.length === 0) {
      console.log('\n⚠️  No salesmen found. Please add a salesman first.');
      return;
    }

    // -------------------------------------------------------------------
    // ✅ TEST 2: Fetch recent task assignments
    // -------------------------------------------------------------------
    console.log('\n📋 Test 2: Checking Task Assignments');
    console.log('-'.repeat(60));

    const assignments = await prisma.taskAssignment.findMany({
      orderBy: { assignedDate: 'desc' },
      take: 10
    });

    console.log(`✅ Total assignments: ${assignments.length}`);
    if (assignments.length > 0) {
      console.log('\nRecent assignments:');
      assignments.forEach((a, i) => {
        console.log(`   ${i + 1}. ${a.salesmanName} - ${a.city} (${a.pincode})`);
        console.log(`      Areas: ${a.areas.length}, Businesses: ${a.totalBusinesses || 0}`);
        console.log(`      Types: ${a.businessTypes.join(', ')}`);
      });
    } else {
      console.log('   No assignments yet.');
    }

    // -------------------------------------------------------------------
    // ✅ TEST 3: Fetch top recent shops
    // -------------------------------------------------------------------
    console.log('\n📋 Test 3: Checking Shops');
    console.log('-'.repeat(60));

    const shops = await prisma.shop.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    console.log(`✅ Total shops fetched: ${shops.length}`);

    if (shops.length > 0) {
      console.log('\nRecent shops:');
      shops.forEach((s, i) => {
        console.log(`   ${i + 1}. ${s.name} (${s.businessType})`);
        console.log(`      ${s.pincode} - ${s.city || 'N/A'}`);
        console.log(`      Stage: ${s.stage}, Assigned: ${s.assignedTo ? 'Yes' : 'No'}`);
      });

      // Group by pincode
      const shopsByPincode = {};
      shops.forEach(shop => {
        shopsByPincode[shop.pincode] = (shopsByPincode[shop.pincode] || 0) + 1;
      });

      console.log('\n📊 Shops by Pincode:');
      Object.entries(shopsByPincode).forEach(([pincode, count]) => {
        console.log(`   ${pincode}: ${count} shops`);
      });

      // Group by stage
      const shopsByStage = {};
      shops.forEach(shop => {
        shopsByStage[shop.stage] = (shopsByStage[shop.stage] || 0) + 1;
      });

      console.log('\n📊 Shops by Stage:');
      Object.entries(shopsByStage).forEach(([stage, count]) => {
        console.log(`   ${stage}: ${count}`);
      });
    } else {
      console.log('   No shops yet.');
    }

    // -------------------------------------------------------------------
    // ✅ TEST 4: Validate assignments vs shop count
    // -------------------------------------------------------------------
    console.log('\n📋 Test 4: Assignments vs Actual Shops');
    console.log('-'.repeat(60));

    for (const assignment of assignments.slice(0, 5)) {
      const shopsForAssignment = await prisma.shop.count({
        where: {
          pincode: assignment.pincode,
          assignedTo: assignment.salesmanId
        }
      });

      const match = shopsForAssignment === assignment.totalBusinesses;
      const icon = match ? '✅' : '⚠️';

      console.log(`${icon} ${assignment.salesmanName} - ${assignment.pincode}`);
      console.log(`   Recorded: ${assignment.totalBusinesses || 0}, Actual: ${shopsForAssignment}`);
    }

    // -------------------------------------------------------------------
    console.log('\n' + '='.repeat(60));
    console.log('✅ Test completed successfully!');

  } catch (error) {
    console.error('\n❌ Test error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testTaskAssignmentFlow();
