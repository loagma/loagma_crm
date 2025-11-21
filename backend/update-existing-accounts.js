import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function updateExistingAccounts() {
  try {
    console.log('🔄 Updating existing accounts...');

    // Get all accounts without businessName
    const accountsToUpdate = await prisma.account.findMany({
      where: {
        OR: [
          { businessName: null },
          { businessName: '' }
        ]
      }
    });

    console.log(`📊 Found ${accountsToUpdate.length} accounts to update`);

    // Update each account
    for (const account of accountsToUpdate) {
      await prisma.account.update({
        where: { id: account.id },
        data: {
          businessName: account.personName + "'s Business", // Use person name as default
          isActive: account.isActive ?? true, // Ensure isActive has a value
        }
      });
      console.log(`✅ Updated account: ${account.accountCode}`);
    }

    console.log('✨ All accounts updated successfully!');
  } catch (error) {
    console.error('❌ Error updating accounts:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateExistingAccounts();
