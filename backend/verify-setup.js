import { PrismaClient } from '@prisma/client';
import axios from 'axios';

const prisma = new PrismaClient();

async function verifySetup() {
  console.log('🔍 Verifying Account Master Setup...\n');
  
  let allGood = true;

  // 1. Check database connection
  try {
    console.log('1️⃣  Checking database connection...');
    await prisma.$connect();
    console.log('   ✅ Database connected\n');
  } catch (error) {
    console.log('   ❌ Database connection failed:', error.message);
    allGood = false;
  }

  // 2. Check Account table structure
  try {
    console.log('2️⃣  Checking Account table structure...');
    const account = await prisma.account.findFirst();
    
    const requiredFields = [
      'businessName', 'gstNumber', 'panCard', 'ownerImage', 
      'shopImage', 'isActive', 'pincode', 'country', 'state',
      'district', 'city', 'area', 'address'
    ];
    
    const missingFields = [];
    if (account) {
      for (const field of requiredFields) {
        if (!(field in account)) {
          missingFields.push(field);
        }
      }
    }
    
    if (missingFields.length === 0) {
      console.log('   ✅ All new fields exist\n');
    } else {
      console.log('   ❌ Missing fields:', missingFields.join(', '));
      console.log('   Run: node apply-migration.js\n');
      allGood = false;
    }
  } catch (error) {
    console.log('   ❌ Table check failed:', error.message);
    console.log('   Run: node apply-migration.js\n');
    allGood = false;
  }

  // 3. Check existing accounts
  try {
    console.log('3️⃣  Checking existing accounts...');
    const count = await prisma.account.count();
    console.log(`   ℹ️  Found ${count} account(s)`);
    
    if (count > 0) {
      const accountsWithoutBusinessName = await prisma.account.count({
        where: { businessName: null }
      });
      
      if (accountsWithoutBusinessName > 0) {
        console.log(`   ⚠️  ${accountsWithoutBusinessName} account(s) missing businessName`);
        console.log('   Run: node apply-migration.js to fix\n');
      } else {
        console.log('   ✅ All accounts have businessName\n');
      }
    } else {
      console.log('   ✅ No existing accounts (fresh start)\n');
    }
  } catch (error) {
    console.log('   ❌ Account check failed:', error.message, '\n');
    allGood = false;
  }

  // 4. Check indexes
  try {
    console.log('4️⃣  Checking database indexes...');
    const indexes = await prisma.$queryRaw`
      SELECT indexname 
      FROM pg_indexes 
      WHERE tablename = 'Account' 
      AND indexname LIKE '%pincode%' 
      OR indexname LIKE '%isActive%'
    `;
    
    if (indexes.length >= 2) {
      console.log('   ✅ Indexes created\n');
    } else {
      console.log('   ⚠️  Some indexes missing (not critical)\n');
    }
  } catch (error) {
    console.log('   ⚠️  Could not check indexes (not critical)\n');
  }

  // 5. Check Prisma Client
  try {
    console.log('5️⃣  Checking Prisma Client...');
    const clientVersion = prisma._clientVersion;
    console.log(`   ✅ Prisma Client version: ${clientVersion}\n`);
  } catch (error) {
    console.log('   ❌ Prisma Client issue');
    console.log('   Run: npx prisma generate\n');
    allGood = false;
  }

  // 6. Check pincode service (if backend is running)
  try {
    console.log('6️⃣  Checking pincode service...');
    const response = await axios.get('http://localhost:5000/pincode/400001', {
      timeout: 3000
    });
    
    if (response.data.success) {
      console.log('   ✅ Pincode service working');
      console.log(`   📍 Test: ${response.data.data.city}, ${response.data.data.state}\n`);
    } else {
      console.log('   ⚠️  Pincode service returned error\n');
    }
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.log('   ⚠️  Backend not running (start with: npm run dev)\n');
    } else {
      console.log('   ⚠️  Pincode service not accessible\n');
    }
  }

  // Summary
  console.log('========================================');
  if (allGood) {
    console.log('✨ Setup Verification: PASSED');
    console.log('========================================\n');
    console.log('Everything looks good! You can now:');
    console.log('1. Start backend: npm run dev');
    console.log('2. Test Account Master screen');
    console.log('3. Create accounts with new fields\n');
  } else {
    console.log('⚠️  Setup Verification: ISSUES FOUND');
    console.log('========================================\n');
    console.log('Please fix the issues above and run again.\n');
    console.log('Quick fixes:');
    console.log('1. Run: node apply-migration.js');
    console.log('2. Run: npx prisma generate');
    console.log('3. Check DATABASE_URL in .env\n');
  }

  await prisma.$disconnect();
}

verifySetup().catch(console.error);
