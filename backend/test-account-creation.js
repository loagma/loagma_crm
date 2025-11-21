import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

const prisma = new PrismaClient();

async function testAccountCreation() {
  try {
    console.log('Testing account creation with contact number: 2135468757\n');
    
    // Check if account exists
    const existing = await prisma.account.findFirst({
      where: { contactNumber: '2135468757' }
    });
    
    if (existing) {
      console.log('✅ Account with this contact number EXISTS:');
      console.log(`   ID: ${existing.id}`);
      console.log(`   Code: ${existing.accountCode}`);
      console.log(`   Name: ${existing.personName}`);
      console.log(`   Contact: ${existing.contactNumber}`);
      console.log(`   Created: ${existing.createdAt}`);
      console.log('\n💡 This is why you\'re getting the duplicate error!');
      console.log('   Try using a different contact number like: 1234567890');
    } else {
      console.log('✅ Contact number 2135468757 is AVAILABLE');
      console.log('   You should be able to create an account with this number');
    }
    
    // Show all existing accounts
    console.log('\n📋 All existing accounts:');
    const allAccounts = await prisma.account.findMany({
      select: {
        accountCode: true,
        personName: true,
        contactNumber: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });
    
    allAccounts.forEach((acc, i) => {
      console.log(`${i + 1}. ${acc.accountCode} | ${acc.personName} | ${acc.contactNumber}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testAccountCreation();
