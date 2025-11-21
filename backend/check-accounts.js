import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

const prisma = new PrismaClient();

async function checkAccounts() {
  try {
    console.log('Checking all accounts in database...\n');
    
    const accounts = await prisma.account.findMany({
      select: {
        id: true,
        accountCode: true,
        personName: true,
        contactNumber: true,
        businessName: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });
    
    console.log(`Total accounts: ${accounts.length}\n`);
    
    if (accounts.length > 0) {
      console.log('Existing accounts:');
      console.log('='.repeat(80));
      accounts.forEach((acc, index) => {
        console.log(`${index + 1}. ${acc.accountCode} | ${acc.personName} | ${acc.contactNumber}`);
        console.log(`   Business: ${acc.businessName || 'N/A'}`);
        console.log(`   Created: ${acc.createdAt.toISOString()}`);
        console.log('-'.repeat(80));
      });
      
      // Check for duplicates
      const contactNumbers = accounts.map(a => a.contactNumber);
      const duplicates = contactNumbers.filter((num, index) => 
        contactNumbers.indexOf(num) !== index
      );
      
      if (duplicates.length > 0) {
        console.log('\n⚠️  Duplicate contact numbers found:');
        duplicates.forEach(num => console.log(`   - ${num}`));
      } else {
        console.log('\n✅ No duplicate contact numbers found');
      }
    } else {
      console.log('No accounts found in database.');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkAccounts();
