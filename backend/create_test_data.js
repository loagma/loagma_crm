// Simple script to create test approval data
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createTestApproval() {
    try {
        console.log('🧪 Creating test approval for user 00002...');

        // Delete existing requests for today
        const deleted = await prisma.latePunchApproval.deleteMany({
            where: {
                employeeId: '00002',
                requestDate: {
                    gte: new Date(new Date().setHours(0, 0, 0, 0)),
                    lt: new Date(new Date().setHours(23, 59, 59, 999))
                }
            }
        });
        console.log(`🗑️ Deleted ${deleted.count} existing requests`);

        // Create approved request with code 108767
        const approval = await prisma.latePunchApproval.create({
            data: {
                employeeId: '00002',
                employeeName: 'Test Employee',
                requestDate: new Date(),
                punchInDate: new Date(),
                reason: 'Testing OTP flow - traffic jam caused delay',
                status: 'APPROVED',
                approvedBy: 'ADMIN001',
                approvedAt: new Date(),
                adminRemarks: 'Approved for testing OTP flow',
                approvalCode: '108767',
                codeExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
                codeUsed: false
            }
        });

        console.log('✅ Test approval created:', {
            id: approval.id,
            employeeId: approval.employeeId,
            approvalCode: approval.approvalCode,
            status: approval.status
        });

        console.log('\n🎉 Test data created successfully!');
        console.log('📱 You can now test OTP code 108767 in the Flutter app');

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await prisma.$disconnect();
    }
}

createTestApproval();