import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrateRoleFields() {
  console.log('🔄 Starting role fields migration...\n');

  try {
    // Get all users
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        employeeCode: true,
        roles: true,
      }
    });

    console.log(`📊 Found ${users.length} users to migrate\n`);

    let migratedCount = 0;

    for (const user of users) {
      if (user.roles && user.roles.length > 0) {
        // Set primaryRole as first role, otherRoles as remaining
        const primaryRole = user.roles[0];
        const otherRoles = user.roles.slice(1);

        await prisma.user.update({
          where: { id: user.id },
          data: {
            primaryRole: primaryRole,
            otherRoles: otherRoles,
          }
        });

        console.log(`✅ ${user.name} (${user.employeeCode})`);
        console.log(`   Primary: ${primaryRole}`);
        console.log(`   Other: ${otherRoles.length > 0 ? otherRoles.join(', ') : 'None'}\n`);
        
        migratedCount++;
      } else {
        console.log(`⚠️  ${user.name} (${user.employeeCode}) - No roles to migrate\n`);
      }
    }

    console.log('─'.repeat(60));
    console.log(`\n✅ Migration completed!`);
    console.log(`   Total users: ${users.length}`);
    console.log(`   Migrated: ${migratedCount}`);
    console.log(`   Skipped: ${users.length - migratedCount}`);

  } catch (error) {
    console.error('❌ Migration error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

migrateRoleFields();
