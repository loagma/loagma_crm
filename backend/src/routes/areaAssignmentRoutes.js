import express from 'express';
import { PrismaClient } from '@prisma/client';
import {
  getAllAreaAssignments,
  getSalesmanAreaAssignments,
  getAreaAssignmentById,
  createAreaAssignment,
  updateAreaAssignment,
  deleteAreaAssignment,
  searchAreaAssignments,
} from '../controllers/areaAssignmentController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const prisma = new PrismaClient();

const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// GET /api/area-assignments - Get all area assignments (admin only)
router.get('/', getAllAreaAssignments);

// GET /api/area-assignments/search - Search area assignments by location
router.get('/search', searchAreaAssignments);

// GET /api/area-assignments/salesman/:salesmanId - Get area assignments for specific salesman
router.get('/salesman/:salesmanId', getSalesmanAreaAssignments);

// GET /api/area-assignments/debug/:salesmanId - Debug endpoint to check data
router.get('/debug/:salesmanId', async (req, res) => {
  try {
    const { salesmanId } = req.params;
    
    // Get all area assignments
    const allAssignments = await prisma.areaAssignment.findMany({
      select: {
        id: true,
        salesmanId: true,
        city: true,
        district: true,
      },
    });
    
    // Get user info
    const user = await prisma.user.findUnique({
      where: { id: salesmanId },
      select: {
        id: true,
        name: true,
        contactNumber: true,
      },
    });
    
    res.json({
      success: true,
      debug: {
        requestedSalesmanId: salesmanId,
        salesmanIdType: typeof salesmanId,
        userFound: user,
        allAssignments: allAssignments,
        matchingAssignments: allAssignments.filter(a => a.salesmanId === salesmanId),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Debug failed',
      error: error.message,
    });
  }
});

// GET /api/area-assignments/:id - Get area assignment by ID
router.get('/:id', getAreaAssignmentById);

// POST /api/area-assignments - Create new area assignment
router.post('/', createAreaAssignment);

// PUT /api/area-assignments/:id - Update area assignment
router.put('/:id', updateAreaAssignment);

// DELETE /api/area-assignments/:id - Delete area assignment
router.delete('/:id', deleteAreaAssignment);

export default router;