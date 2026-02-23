import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get employee working hours configuration
// Now queries actual database columns after migration
router.get('/:employeeId', async (req, res) => {
    try {
        const { employeeId } = req.params;

        const employee = await prisma.user.findUnique({
            where: { id: employeeId },
            select: {
                id: true,
                name: true,
                workStartTime: true,
                workEndTime: true,
                latePunchInGraceMinutes: true,
                earlyPunchOutGraceMinutes: true
            }
        });

        if (!employee) {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }

        // Use employee's working hours or defaults
        const workStartTime = employee.workStartTime || '09:00:00';
        const workEndTime = employee.workEndTime || '18:00:00';
        const latePunchInGrace = employee.latePunchInGraceMinutes || 45;
        const earlyPunchOutGrace = employee.earlyPunchOutGraceMinutes || 30;

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

        console.log('📋 Employee working hours fetched:', {
            employeeId: employee.id,
            employeeName: employee.name,
            workStartTime,
            workEndTime,
            latePunchInGrace,
            earlyPunchOutGrace
        });

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
router.put('/:employeeId', async (req, res) => {
    try {
        const { employeeId } = req.params;
        const { workStartTime, workEndTime, latePunchInGraceMinutes, earlyPunchOutGraceMinutes } = req.body;

        // Validate input
        if (!workStartTime || !workEndTime) {
            return res.status(400).json({
                success: false,
                message: 'workStartTime and workEndTime are required'
            });
        }

        // Validate time format (HH:MM:SS)
        const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/;
        if (!timeRegex.test(workStartTime) || !timeRegex.test(workEndTime)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid time format. Use HH:MM:SS format'
            });
        }

        const updatedEmployee = await prisma.user.update({
            where: { id: employeeId },
            data: {
                workStartTime,
                workEndTime,
                latePunchInGraceMinutes: latePunchInGraceMinutes || 45,
                earlyPunchOutGraceMinutes: earlyPunchOutGraceMinutes || 30
            },
            select: {
                id: true,
                name: true,
                workStartTime: true,
                workEndTime: true,
                latePunchInGraceMinutes: true,
                earlyPunchOutGraceMinutes: true
            }
        });

        console.log('✅ Employee working hours updated:', {
            employeeId: updatedEmployee.id,
            employeeName: updatedEmployee.name,
            workStartTime: updatedEmployee.workStartTime,
            workEndTime: updatedEmployee.workEndTime
        });

        res.json({
            success: true,
            message: 'Working hours updated successfully',
            data: updatedEmployee
        });

    } catch (error) {
        console.error('Error updating employee working hours:', error);
        
        if (error.code === 'P2025') {
            return res.status(404).json({
                success: false,
                message: 'Employee not found'
            });
        }
        
        res.status(500).json({
            success: false,
            message: 'Failed to update employee working hours'
        });
    }
});

export default router;