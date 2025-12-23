// Direct database test for approval flow
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testApprovalFlow() {
    try {
        console.log('🧪 Testing approval flow directly...\n');

        // 1. Check if there's an existing request for EMP001
        const existingRequest = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId: 'EMP001',
                requestDate: {
                    gte: new Date(new Date().setHours(0, 0, 0, 0)),
                    lt: new Date(new Date().setHours(23, 59, 59, 999))
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        console.log('Existing request:', existingRequest);

        if (!existingRequest) {
            // Create a test request
            console.log('\n📝 Creating test approval request...');
            const newRequest = await prisma.latePunchApproval.create({
                data: {
                    employeeId: 'EMP001',
                    employeeName: 'Test Employee',
                    requestDate: new Date(),
                    punchInDate: new Date(),
                    reason: 'Testing OTP flow - traffic jam caused delay',
                    status: 'PENDING'
                }
            });
            console.log('Created request:', newRequest);

            // Approve it with code 108767
            console.log('\n✅ Approving request with code 108767...');
            const approvedRequest = await prisma.latePunchApproval.update({
                where: { id: newRequest.id },
                data: {
                    status: 'APPROVED',
                    approvedBy: 'ADMIN001',
                    approvedAt: new Date(),
                    approvalCode: '108767',
                    codeExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000) // 2 hours from now
                }
            });
            console.log('Approved request:', approvedRequest);
        } else if (existingRequest.status === 'PENDING') {
            // Approve existing pending request
            console.log('\n✅ Approving existing pending request with code 108767...');
            const approvedRequest = await prisma.latePunchApproval.update({
                where: { id: existingRequest.id },
                data: {
                    status: 'APPROVED',
                    approvedBy: 'ADMIN001',
                    approvedAt: new Date(),
                    approvalCode: '108767',
                    codeExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000) // 2 hours from now
                }
            });
            console.log('Approved request:', approvedRequest);
        } else {
            console.log('\n✅ Request already approved with status:', existingRequest.status);
            if (existingRequest.approvalCode !== '108767') {
                // Update the approval code to 108767 for testing
                console.log('🔄 Updating approval code to 108767...');
                const updatedRequest = await prisma.latePunchApproval.update({
                    where: { id: existingRequest.id },
                    data: {
                        approvalCode: '108767',
                        codeExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
                        codeUsed: false // Reset used flag
                    }
                });
                console.log('Updated request:', updatedRequest);
            }
        }

        // 2. Check final status
        console.log('\n📊 Final status check...');
        const finalStatus = await prisma.latePunchApproval.findFirst({
            where: {
                employeeId: 'EMP001',
                requestDate: {
                    gte: new Date(new Date().setHours(0, 0, 0, 0)),
                    lt: new Date(new Date().setHours(23, 59, 59, 999))
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        console.log('Final status:', finalStatus);
        console.log('\n🎉 Test completed! Code 108767 should now work in the app.');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

testApprovalFlow();