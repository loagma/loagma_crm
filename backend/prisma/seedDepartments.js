import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding departments...');

  const departments = [
    { name: 'Sales' },
    { name: 'Marketing' },
    { name: 'Human Resources' },
    { name: 'Information Technology' },
    { name: 'Finance' },
    { name: 'Operations' },
    { name: 'Customer Service' },
    { name: 'Product Development' },
    { name: 'Quality Assurance' },
    { name: 'Administration' },
  ];

  for (const dept of departments) {
    const existing = await prisma.department.findUnique({
      where: { name: dept.name },
    });

    if (!existing) {
      await prisma.department.create({
        data: dept,
      });
      console.log(`✅ Created department: ${dept.name}`);
    } else {
      console.log(`⏭️  Department already exists: ${dept.name}`);
    }
  }

  console.log('✅ Department seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding departments:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
