import prisma from './src/config/db.js';

async function updateDatabase() {
  try {
    console.log('🔄 Checking database connection...');
    
    // Test connection
    await prisma.$connect();
    console.log('✅ Connected to database');
    
    // Check if User table has new columns
    const result = await prisma.$queryRaw`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'User' 
      AND column_name IN ('alternativeNumber', 'address', 'city', 'state', 'pincode', 'aadharCard', 'panCard', 'notes', 'roles')
    `;
    
    console.log('📊 Found columns:', result);
    
    if (result.length === 0) {
      console.log('⚠️  New columns not found. Running migration...');
      console.log('Please run: npx prisma migrate deploy');
    } else {
      console.log('✅ Database schema is up to date!');
    }
    
    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

updateDatabase();
