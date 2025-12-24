import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get employee working hours configuration
// NOTE: This returns hardcoded defaults until migration is run
router.get('/:employeeId', async (req, res) => {
    try {
        const { employeeId } = req.params;

        const employee = await prisma.user.findUnique({
            where: { id: employeeId },
            select: {
                id: true,
                name: true
            }
        });

        if (!employee) {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        // Use hardcoded defaults for now (will be dynamic after migration)
        const workStartTime = '09:00:00';
        const workEndTime = '18:00:00';
        const latePunchInGrace = 45;
        const earlyPunchOutGrace = 30;

        // Parse times and calculate cutoffs
        const [startHour, startMinute] = workStartTime.split(':').map(Number);
        const [endHour, endMinute] = workEndTime.split(':').map(Number);

        // Late punch-in cutoff = work start time + grace minutes
        const latePunchInCutoffMinutes = startHour * 60 + startMinute + latePunchInGrace;
        const latePunchInCutoffHour = Math.floor(latePunchInCutoffMinutes / 60);
        const latePunchInCutoffMin = latePunchInCutoffMinutes % 60;

        // Early punch-out cutoff = work end time - grace minutes
        const earlyPunchOutCutoffMinutes = endHour * 60 + endMinute - earlyPunchOutGrace;
        const earlyPunchOutCutoffHour = Math.floor(earlyPunchOutCutoffMinutes / 60);
        const earlyPunchOutCutoffMin = earlyPunchOutCutoffMinutes % 60;

        res.json({
            success: true,
            data: {
                employeeId: employee.id,
                employeeName: employee.name,
                workStartTime,
                workEndTime,
                latePunchInGraceMinutes: latePunchInGrace,
                earlyPunchOutGraceMinutes: earlyPunchOutGrace,
                latePunchInCutoffTime: `${latePunchInCutoffHour.toString().padStart(2, '0')}:${latePunchInCutoffMin.toString().padStart(2, '0')}:00`,
                earlyPunchOutCutoffTime: `${earlyPunchOutCutoffHour.toString().padStart(2, '0')}:${earlyPunchOutCutoffMin.toString().padStart(2, '0')}:00`
            }
        });

    } catch (error) {
        console.error('Error fetching employee working hours:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch employee working hours'
        });
    }
});

// Update employee working hours (admin only)
// NOTE: This is disabled until migration is run
router.put('/:employeeId', async (req, res) => {
    res.status(503).json({
        success: false,
        message: 'Working hours update is not available yet. Please run the migration first via POST /api/migration/working-hours'
    });
});

export default router;