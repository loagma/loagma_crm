import express from 'express';
import { createUser, getAllUsers } from '../controllers/userController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// Only NSM can create users
router.post('/', createUser);
router.get('/get-all', getAllUsers);

// Get salesmen only
router.get('/salesmen', async (req, res) => {
  try {
    const salesmen = await prisma.user.findMany({
      where: {
        isActive: true,
        OR: [
          { roleId: 'R002' },
          { role: { name: 'salesman' } }
        ]
      },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        email: true,
        roleId: true,
        role: {
          select: {
            id: true,
            name: true
          }
        }
      }
    });

    res.json({
      success: true,
      count: salesmen.length,
      salesmen
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
