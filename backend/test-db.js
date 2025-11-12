import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

console.log('DATABASE_URL exists:', !!process.env.DATABASE_URL);

const prisma = new PrismaClient();

async function testDatabase() {
  try {
    console.log('Testing database connection...\n');
    
    // Test Countries
    const countries = await prisma.country.findMany();
    console.log('✅ Countries found:', countries.length);
    console.log(JSON.stringify(countries, null, 2));
    
    // Test States
    const states = await prisma.state.findMany();
    console.log('\n✅ States found:', states.length);
    console.log(JSON.stringify(states.slice(0, 3), null, 2));
    
    // Test Districts
    const districts = await prisma.district.findMany();
    console.log('\n✅ Districts found:', districts.length);
    
    // Test Cities
    const cities = await prisma.city.findMany();
    console.log('\n✅ Cities found:', cities.length);
    
    // Test Zones
    const zones = await prisma.zone.findMany();
    console.log('\n✅ Zones found:', zones.length);
    
    // Test Areas
    const areas = await prisma.area.findMany();
    console.log('\n✅ Areas found:', areas.length);
    
    // Test Accounts
    const accounts = await prisma.account.findMany();
    console.log('\n✅ Accounts found:', accounts.length);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testDatabase();
