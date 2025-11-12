import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function seedLocations() {
  console.log("🌍 Starting Location Master seeding...");

  try {
    // Create India
    const india = await prisma.country.upsert({
      where: { name: "India" },
      update: {},
      create: { name: "India" }
    });
    console.log("✅ Country: India created");

    // Create States
    const gujarat = await prisma.state.upsert({
      where: { id: "gujarat-state" },
      update: {},
      create: {
        id: "gujarat-state",
        name: "Gujarat",
        countryId: india.id
      }
    });

    const maharashtra = await prisma.state.upsert({
      where: { id: "maharashtra-state" },
      update: {},
      create: {
        id: "maharashtra-state",
        name: "Maharashtra",
        countryId: india.id
      }
    });
    console.log("✅ States: Gujarat, Maharashtra created");

    // Create Districts in Gujarat
    const ahmedabad = await prisma.district.upsert({
      where: { id: "ahmedabad-district" },
      update: {},
      create: {
        id: "ahmedabad-district",
        name: "Ahmedabad",
        stateId: gujarat.id
      }
    });

    const surat = await prisma.district.upsert({
      where: { id: "surat-district" },
      update: {},
      create: {
        id: "surat-district",
        name: "Surat",
        stateId: gujarat.id
      }
    });

    // Create Districts in Maharashtra
    const mumbai = await prisma.district.upsert({
      where: { id: "mumbai-district" },
      update: {},
      create: {
        id: "mumbai-district",
        name: "Mumbai",
        stateId: maharashtra.id
      }
    });

    const pune = await prisma.district.upsert({
      where: { id: "pune-district" },
      update: {},
      create: {
        id: "pune-district",
        name: "Pune",
        stateId: maharashtra.id
      }
    });
    console.log("✅ Districts created");

    // Create Cities in Ahmedabad
    const ahmedabadCity = await prisma.city.upsert({
      where: { id: "ahmedabad-city" },
      update: {},
      create: {
        id: "ahmedabad-city",
        name: "Ahmedabad City",
        districtId: ahmedabad.id
      }
    });

    // Create Cities in Surat
    const suratCity = await prisma.city.upsert({
      where: { id: "surat-city" },
      update: {},
      create: {
        id: "surat-city",
        name: "Surat City",
        districtId: surat.id
      }
    });

    // Create Cities in Mumbai
    const mumbaiCity = await prisma.city.upsert({
      where: { id: "mumbai-city" },
      update: {},
      create: {
        id: "mumbai-city",
        name: "Mumbai City",
        districtId: mumbai.id
      }
    });

    // Create Cities in Pune
    const puneCity = await prisma.city.upsert({
      where: { id: "pune-city" },
      update: {},
      create: {
        id: "pune-city",
        name: "Pune City",
        districtId: pune.id
      }
    });
    console.log("✅ Cities created");

    // Create Zones in Ahmedabad
    const westZone = await prisma.zone.upsert({
      where: { id: "ahmedabad-west-zone" },
      update: {},
      create: {
        id: "ahmedabad-west-zone",
        name: "West Zone",
        cityId: ahmedabadCity.id
      }
    });

    const eastZone = await prisma.zone.upsert({
      where: { id: "ahmedabad-east-zone" },
      update: {},
      create: {
        id: "ahmedabad-east-zone",
        name: "East Zone",
        cityId: ahmedabadCity.id
      }
    });

    // Create Zones in Surat
    const suratWestZone = await prisma.zone.upsert({
      where: { id: "surat-west-zone" },
      update: {},
      create: {
        id: "surat-west-zone",
        name: "West Zone",
        cityId: suratCity.id
      }
    });

    // Create Zones in Mumbai
    const mumbaiSouthZone = await prisma.zone.upsert({
      where: { id: "mumbai-south-zone" },
      update: {},
      create: {
        id: "mumbai-south-zone",
        name: "South Mumbai",
        cityId: mumbaiCity.id
      }
    });

    const mumbaiCentralZone = await prisma.zone.upsert({
      where: { id: "mumbai-central-zone" },
      update: {},
      create: {
        id: "mumbai-central-zone",
        name: "Central Mumbai",
        cityId: mumbaiCity.id
      }
    });
    console.log("✅ Zones created");

    // Create Areas in West Zone Ahmedabad
    await prisma.area.createMany({
      data: [
        { name: "Vastrapur", zoneId: westZone.id },
        { name: "Bodakdev", zoneId: westZone.id },
        { name: "Satellite", zoneId: westZone.id },
        { name: "Navrangpura", zoneId: westZone.id }
      ],
      skipDuplicates: true
    });

    // Create Areas in East Zone Ahmedabad
    await prisma.area.createMany({
      data: [
        { name: "Maninagar", zoneId: eastZone.id },
        { name: "Nikol", zoneId: eastZone.id },
        { name: "Vastral", zoneId: eastZone.id }
      ],
      skipDuplicates: true
    });

    // Create Areas in Surat West Zone
    await prisma.area.createMany({
      data: [
        { name: "Adajan", zoneId: suratWestZone.id },
        { name: "Vesu", zoneId: suratWestZone.id },
        { name: "Pal", zoneId: suratWestZone.id }
      ],
      skipDuplicates: true
    });

    // Create Areas in Mumbai South
    await prisma.area.createMany({
      data: [
        { name: "Colaba", zoneId: mumbaiSouthZone.id },
        { name: "Nariman Point", zoneId: mumbaiSouthZone.id },
        { name: "Churchgate", zoneId: mumbaiSouthZone.id }
      ],
      skipDuplicates: true
    });

    // Create Areas in Mumbai Central
    await prisma.area.createMany({
      data: [
        { name: "Dadar", zoneId: mumbaiCentralZone.id },
        { name: "Parel", zoneId: mumbaiCentralZone.id },
        { name: "Byculla", zoneId: mumbaiCentralZone.id }
      ],
      skipDuplicates: true
    });

    console.log("✅ Areas created");
    console.log("🎉 Location Master seeding completed successfully!");

  } catch (error) {
    console.error("❌ Location seeding failed:", error);
    throw error;
  }
}

seedLocations()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
