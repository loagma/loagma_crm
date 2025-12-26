// Initialize leave balances for existing users
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function initializeLeaveBalances() {
    console.log('🔄 Initializing leave balances for existing users...');

    try {
        // Get all active users
        const users = await prisma.user.findMany({
            where: {
                isActive: true,
                roleId: {
                    not: null
                }
            },
            select: {
                id: true,
                name: true,
                role: {
                    select: {
                        name: true
                    }
                }
            }
        });

        console.log(`📊 Found ${users.length} active users`);

        const currentYear = new Date().getFullYear();
        let created = 0;
        let existing = 0;

        for (const user of users) {
            // Check if leave balance already exists
            const existingBalance = await prisma.leaveBalance.findUnique({
                where: { employeeId: user.id }
            });

            if (existingBalance) {
                console.log(`⏭️  Leave balance already exists for ${user.name} (${user.role?.name})`);
                existing++;
                continue;
            }

            // Create leave balance
            await prisma.leaveBalance.create({
                data: {
                    employeeId: user.id,
                    year: currentYear,
                    sickLeaves: 12,
                    casualLeaves: 10,
                    earnedLeaves: 20,
                    usedSickLeaves: 0,
                    usedCasualLeaves: 0,
                    usedEarnedLeaves: 0
                }
            });

            console.log(`✅ Created leave balance for ${user.name} (${user.role?.name})`);
            created++;
        }

        console.log('\n📈 Summary:');
        console.log(`   Created: ${created} new leave balances`);
        console.log(`   Existing: ${existing} leave balances`);
        console.log(`   Total Users: ${users.length}`);
        console.log('\n✅ Leave balance initialization completed!');

    } catch (error) {
        console.error('❌ Error initializing leave balances:', error);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the initialization
initializeLeaveBalances();