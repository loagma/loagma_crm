import { PrismaClient } from '../src/generated/prisma/index.js';
const prisma = new PrismaClient();


async function main() {
  console.log("🌱 Starting CRM database seeding...");

  // 1️⃣ Create Sales Role Hierarchy
  await prisma.role.createMany({
    data: [
      { code: "R1", name: "NSM - National Sales Manager", level: 1 },
      { code: "R2", name: "RSM - Regional Sales Manager", level: 2 },
      { code: "R3", name: "ASM - Area Sales Manager", level: 3 },
      { code: "R4", name: "TSM - Territory Sales Manager", level: 4 },
    ],
    skipDuplicates: true, // avoids errors if rerun
  });

  // 2️⃣ Create Departments
  await prisma.department.createMany({
    data: [
      { name: "Sales" },
      { name: "Marketing" },
      { name: "Telecalling" },
      { name: "Support" },
    ],
    skipDuplicates: true,
  });

  // 3️⃣ Create Functional Roles
  const marketingDept = await prisma.department.findUnique({ where: { name: "Marketing" } });
  const teleDept = await prisma.department.findUnique({ where: { name: "Telecalling" } });

  if (marketingDept && teleDept) {
    await prisma.functionalRole.createMany({
      data: [
        { name: "Digital Marketing Head", departmentId: marketingDept.id },
        { name: "Digital Marketer", departmentId: marketingDept.id },
        { name: "Telecaller Lead", departmentId: teleDept.id },
        { name: "Telecaller", departmentId: teleDept.id },
      ],
      skipDuplicates: true,
    });
  } else {
    console.warn("⚠️ Departments not found. Skipping functional roles creation.");
  }

  // 4️⃣ Seed Default NSM
  const nsmRole = await prisma.role.findUnique({ where: { code: "R1" } });

  if (nsmRole) {
    await prisma.user.upsert({
      where: { email: "nsm@crm.com" },
      update: {},
      create: {
        name: "Default NSM",
        email: "nsm@crm.com",
        contactNumber: "9999999999",
        roleId: nsmRole.id,
      },
    });
  } else {
    console.warn("⚠️ NSM role not found. User creation skipped.");
  }

  console.log("✅ Seed data created successfully!");
}

main()
  .catch((e) => {
    console.error("❌ Seeding failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
