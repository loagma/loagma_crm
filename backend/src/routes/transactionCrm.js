import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Helper function to calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
        Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in meters
}

// Visit In - Create new transaction
router.post('/visit-in', async (req, res) => {
    try {
        console.log('=== Visit In Request ===');
        console.log('Request body:', req.body);

        const {
            accountId,
            salesmanId,
            latitude,
            longitude,
            accountLatitude,
            accountLongitude,
            beatNo,
        } = req.body;

        // Validate required fields
        if (!accountId || !salesmanId || !latitude || !longitude) {
            console.log('Missing required fields');
            return res.status(400).json({
                success: false,
                message: 'Missing required fields',
            });
        }

        // Check if account location is available
        if (!accountLatitude || !accountLongitude) {
            console.log('Account location not available');
            return res.status(400).json({
                success: false,
                message: 'Account location not available',
            });
        }

        // Calculate distance between salesman and account
        const distance = calculateDistance(
            latitude,
            longitude,
            accountLatitude,
            accountLongitude
        );

        console.log('Distance calculated:', distance, 'meters');

        // Check if within 10000 meters (temporarily increased for testing)
        // TODO: Change back to 10 meters for production
        if (distance > 10000) {
            console.log('Distance too far:', distance);
            return res.status(400).json({
                success: false,
                message: `You must be within 10000 meters of the account location. Current distance: ${Math.round(distance)}m`,
                distance: Math.round(distance),
            });
        }

        // Check if there's an active visit (visit in without visit out)
        const activeVisit = await prisma.transactionCrm.findFirst({
            where: {
                accountId,
                salesmanId,
                visitInTime: { not: null },
                visitOutTime: null,
            },
            orderBy: { visitInTime: 'desc' },
        });

        console.log('Active visit check:', activeVisit);

        if (activeVisit) {
            console.log('Active visit found');
            return res.status(400).json({
                success: false,
                message: 'You have an active visit. Please complete Visit Out first.',
                activeVisit,
            });
        }

        // Get the next transaction number for this account
        const lastTransaction = await prisma.transactionCrm.findFirst({
            where: { accountId },
            orderBy: { transactionNo: 'desc' },
        });

        const transactionNo = lastTransaction ? lastTransaction.transactionNo + 1 : 1;

        console.log('Creating transaction with transactionNo:', transactionNo);

        // Create new transaction with visit in
        const transaction = await prisma.transactionCrm.create({
            data: {
                accountId,
                salesmanId,
                transactionNo,
                beatNo: beatNo || null,
                visitInTime: new Date(),
                visitInLatitude: latitude,
                visitInLongitude: longitude,
            },
        });

        console.log('Transaction created:', transaction);

        res.json({
            success: true,
            message: 'Visit In recorded successfully',
            transaction,
            distance: Math.round(distance),
        });
    } catch (error) {
        console.error('Visit In error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to record Visit In',
            error: error.message,
        });
    }
});

// Visit Out - Update existing transaction
router.post('/visit-out', async (req, res) => {
    try {
        console.log('=== Visit Out Request ===');
        console.log('Request body:', req.body);

        const {
            accountId,
            salesmanId,
            latitude,
            longitude,
            accountLatitude,
            accountLongitude,
            orderFunnel,
            notes,
            notesRelatedTo,
            merchandiseImage1,
            merchandiseImage2,
        } = req.body;

        console.log('Extracted data:');
        console.log('- orderFunnel:', orderFunnel);
        console.log('- notes:', notes);
        console.log('- notesRelatedTo:', notesRelatedTo);
        console.log('- merchandiseImage1:', merchandiseImage1 ? 'Present' : 'None');
        console.log('- merchandiseImage2:', merchandiseImage2 ? 'Present' : 'None');

        // Validate required fields
        if (!accountId || !salesmanId || !latitude || !longitude) {
            console.log('Missing required fields');
            return res.status(400).json({
                success: false,
                message: 'Missing required fields',
            });
        }

        // Check if account location is available
        if (!accountLatitude || !accountLongitude) {
            console.log('Account location not available');
            return res.status(400).json({
                success: false,
                message: 'Account location not available',
            });
        }

        // Calculate distance
        const distance = calculateDistance(
            latitude,
            longitude,
            accountLatitude,
            accountLongitude
        );

        console.log('Distance calculated:', distance, 'meters');

        // Check if within 10000 meters (temporarily increased for testing)
        // TODO: Change back to 10 meters for production
        if (distance > 10000) {
            console.log('Distance too far:', distance);
            return res.status(400).json({
                success: false,
                message: `You must be within 10000 meters of the account location. Current distance: ${Math.round(distance)}m`,
                distance: Math.round(distance),
            });
        }

        // Find the active visit (visit in without visit out)
        const activeVisit = await prisma.transactionCrm.findFirst({
            where: {
                accountId,
                salesmanId,
                visitInTime: { not: null },
                visitOutTime: null,
            },
            orderBy: { visitInTime: 'desc' },
        });

        console.log('Active visit found:', activeVisit);

        if (!activeVisit) {
            console.log('No active visit found');
            return res.status(400).json({
                success: false,
                message: 'No active visit found. Please do Visit In first.',
            });
        }

        console.log('Updating transaction with ID:', activeVisit.id);
        console.log('Update data:', {
            visitOutTime: 'new Date()',
            visitOutLatitude: latitude,
            visitOutLongitude: longitude,
            orderFunnel: orderFunnel || null,
            notes: notes || null,
            notesRelatedTo: notesRelatedTo || null,
            merchandiseImage1: merchandiseImage1 ? 'Present' : null,
            merchandiseImage2: merchandiseImage2 ? 'Present' : null,
        });

        // Update transaction with visit out and other details
        const transaction = await prisma.transactionCrm.update({
            where: { id: activeVisit.id },
            data: {
                visitOutTime: new Date(),
                visitOutLatitude: latitude,
                visitOutLongitude: longitude,
                orderFunnel: orderFunnel || null,
                notes: notes || null,
                notesRelatedTo: notesRelatedTo || null,
                merchandiseImage1: merchandiseImage1 || null,
                merchandiseImage2: merchandiseImage2 || null,
            },
        });

        console.log('Transaction updated:', transaction);

        res.json({
            success: true,
            message: 'Visit Out recorded successfully',
            transaction,
            distance: Math.round(distance),
        });
    } catch (error) {
        console.error('Visit Out error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to record Visit Out',
            error: error.message,
        });
    }
});

// Get active visit for an account
router.get('/active-visit/:accountId/:salesmanId', async (req, res) => {
    try {
        const { accountId, salesmanId } = req.params;

        const activeVisit = await prisma.transactionCrm.findFirst({
            where: {
                accountId,
                salesmanId,
                visitInTime: { not: null },
                visitOutTime: null,
            },
            orderBy: { visitInTime: 'desc' },
        });

        res.json({
            success: true,
            hasActiveVisit: !!activeVisit,
            activeVisit,
        });
    } catch (error) {
        console.error('Get active visit error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get active visit',
            error: error.message,
        });
    }
});

// Get transaction history for an account
router.get('/history/:accountId', async (req, res) => {
    try {
        const { accountId } = req.params;
        const { limit = 50, offset = 0 } = req.query;

        const transactions = await prisma.transactionCrm.findMany({
            where: { accountId },
            orderBy: { visitInTime: 'desc' },
            take: parseInt(limit),
            skip: parseInt(offset),
        });

        const total = await prisma.transactionCrm.count({
            where: { accountId },
        });

        res.json({
            success: true,
            transactions,
            total,
            limit: parseInt(limit),
            offset: parseInt(offset),
        });
    } catch (error) {
        console.error('Get transaction history error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get transaction history',
            error: error.message,
        });
    }
});

// Update transaction during active visit (PUT /update)
router.put('/update', async (req, res) => {
    try {
        console.log('=== Update Transaction Request ===');
        console.log('Request body:', req.body);

        const {
            transactionId,
            orderFunnel,
            notes,
            notesRelatedTo,
            merchandiseImage1,
            merchandiseImage2,
        } = req.body;

        if (!transactionId) {
            return res.status(400).json({
                success: false,
                message: 'Transaction ID is required',
            });
        }

        // Check if transaction exists and is active (has visit in but no visit out)
        const existingTransaction = await prisma.transactionCrm.findUnique({
            where: { id: transactionId },
        });

        if (!existingTransaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found',
            });
        }

        if (existingTransaction.visitOutTime) {
            return res.status(400).json({
                success: false,
                message: 'Cannot update completed visit',
            });
        }

        console.log('Updating transaction:', transactionId);

        const transaction = await prisma.transactionCrm.update({
            where: { id: transactionId },
            data: {
                orderFunnel: orderFunnel || null,
                notes: notes || null,
                notesRelatedTo: notesRelatedTo || null,
                merchandiseImage1: merchandiseImage1 || null,
                merchandiseImage2: merchandiseImage2 || null,
            },
        });

        console.log('Transaction updated successfully');

        res.json({
            success: true,
            message: 'Transaction updated successfully',
            transaction,
        });
    } catch (error) {
        console.error('Update transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update transaction',
            error: error.message,
        });
    }
});

// Update order funnel and notes (can be done separately)
router.patch('/update/:transactionId', async (req, res) => {
    try {
        const { transactionId } = req.params;
        const {
            orderFunnel,
            notes,
            notesRelatedTo,
            merchandiseImage1,
            merchandiseImage2,
        } = req.body;

        const transaction = await prisma.transactionCrm.update({
            where: { id: parseInt(transactionId) },
            data: {
                orderFunnel: orderFunnel || undefined,
                notes: notes || undefined,
                notesRelatedTo: notesRelatedTo || undefined,
                merchandiseImage1: merchandiseImage1 || undefined,
                merchandiseImage2: merchandiseImage2 || undefined,
            },
        });

        res.json({
            success: true,
            message: 'Transaction updated successfully',
            transaction,
        });
    } catch (error) {
        console.error('Update transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update transaction',
            error: error.message,
        });
    }
});

export default router;
