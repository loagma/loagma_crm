import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { randomUUID } from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

const prisma = new PrismaClient();

async function testCreateAccount() {
  try {
    const testContactNumber = '9876543210'; // Different from existing ones
    
    console.log(`Testing account creation with contact number: ${testContactNumber}\n`);
    
    // Check if it exists first
    const existing = await prisma.account.findFirst({
      where: { contactNumber: testContactNumber }
    });
    
    if (existing) {
      console.log('❌ Account with this contact number already exists:');
      console.log(JSON.stringify(existing, null, 2));
      return;
    }
    
    console.log('✅ Contact number is available\n');
    
    // Generate account code
    const prefix = 'ACC';
    const date = new Date();
    const year = date.getFullYear().toString().slice(-2);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    
    const startOfDay = new Date(date.setHours(0, 0, 0, 0));
    const endOfDay = new Date(date.setHours(23, 59, 59, 999));
    
    const count = await prisma.account.count({
      where: {
        createdAt: {
          gte: startOfDay,
          lte: endOfDay
        }
      }
    });
    
    const sequence = (count + 1).toString().padStart(4, '0');
    const accountCode = `${prefix}${year}${month}${sequence}`;
    
    console.log(`Generated account code: ${accountCode}\n`);
    
    // Create account
    const account = await prisma.account.create({
      data: {
        id: randomUUID(),
        accountCode,
        personName: 'Test Person',
        contactNumber: testContactNumber,
        businessName: 'Test Business',
        isActive: true,
        isApproved: false
      }
    });
    
    console.log('✅ Account created successfully:');
    console.log(JSON.stringify(account, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Error code:', error.code);
    console.error('Full error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testCreateAccount();
