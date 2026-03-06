import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // Seed Admin User (one-time)
  const adminPhone = '8019500007'; // Change this to your admin phone
  
  const existingAdmin = await prisma.user.findUnique({
    where: { contactNumber: adminPhone },
  });

  if (!existingAdmin) {
    // Create Admin role if not exists
    const adminRole = await prisma.role.upsert({
      where: { id: 'admin' },
      update: {},
      create: {
        id: 'admin',
        name: 'Admin',
      },
    });

    // Create Admin user
    await prisma.user.create({
      data: {
        id: randomUUID(),
        contactNumber: adminPhone,
        roleId: adminRole.id,
        name: 'Lohiya Admin ',
        isActive: true,
      },
    });
    console.log('✅ Admin user created with phone:', adminPhone);
  } else {
    console.log('ℹ️  Admin user already exists');
  }

  // Seed default roles
  const roles = [
    { id: 'admin', name: 'Admin' },
    { id: 'manager', name: 'Manager' },
    { id: 'salesman', name: 'Salesman' },
    { id: 'telecaller', name: 'Telecaller' },
  ];

  for (const role of roles) {
    await prisma.role.upsert({
      where: { id: role.id },
      update: { name: role.name },
      create: role,
    });
  }
  console.log('✅ Roles seeded');

  console.log('🎉 Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
