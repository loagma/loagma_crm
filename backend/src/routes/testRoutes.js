import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Simple test endpoint
router.get('/hello', (req, res) => {
    console.log('🧪 Test endpoint called');
    res.json({ success: true, message: 'Test endpoint working!' });
});

// Create test approval via GET for easy browser testing
router.get('/create-test-approval', async (req, res) => {
    try {
        console.log('🧪 Creating test approval record via GET...');
        const employeeId = '00002';
        console.log('🧪 Employee ID:', employeeId);

        // Delete existing requests for today
        const deleted = await prisma.latePunchApproval.deleteMany({
            where: {
                employeeId,
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
                employeeId,
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

        console.log('✅ Test approval created:', approval);

        res.json({
            success: true,
            message: 'Test approval record created successfully',
            data: {
                id: approval.id,
                employeeId: approval.employeeId,
                approvalCode: approval.approvalCode,
                status: approval.status,
                expiresAt: approval.codeExpiresAt
            }
        });
    } catch (error) {
        console.error('❌ Error creating test approval:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create test approval',
            error: error.message
        });
    }
});

// Create test approval record with code 108767
router.post('/create-test-approval', async (req, res) => {
    try {
        console.log('🧪 Creating test approval record...');
        const { employeeId = '00002' } = req.body;
        console.log('🧪 Employee ID:', employeeId);

        // Delete existing requests for today
        await prisma.latePunchApproval.deleteMany({
            where: {
                employeeId,
                requestDate: {
                    gte: new Date(new Date().setHours(0, 0, 0, 0)),
                    lt: new Date(new Date().setHours(23, 59, 59, 999))
                }
            }
        });

        // Create approved request with code 108767
        const approval = await prisma.latePunchApproval.create({
            data: {
                employeeId,
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

        res.json({
            success: true,
            message: 'Test approval record created successfully',
            data: approval
        });
    } catch (error) {
        console.error('Error creating test approval:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create test approval',
            error: error.message
        });
    }
});

export default router;