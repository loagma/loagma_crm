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

// GET /api/area-assignments/my-assignments - Get area assignments for current authenticated user
router.get('/my-assignments', async (req, res) => {
  try {
    const salesmanId = req.user.id; // Get from authenticated token

    console.log('🔍 My assignments - authenticated user ID:', salesmanId);
    console.log('🔍 User ID type:', typeof salesmanId);

    // Get all area assignments to debug
    const allAssignments = await prisma.areaAssignment.findMany({
      select: {
        id: true,
        salesmanId: true,
        city: true,
        district: true,
      },
    });
    console.log('📊 All area assignments in database:', allAssignments);

    const assignments = await prisma.areaAssignment.findMany({
      where: {
        salesmanId: salesmanId,
      },
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
      orderBy: {
        assignedDate: 'desc',
      },
    });

    console.log('📊 Found assignments for authenticated user:', assignments.length);

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      })),
    });
  } catch (error) {
    console.error('Error fetching my area assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch area assignments',
      error: error.message,
    });
  }
});

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