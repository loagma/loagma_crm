import express from 'express';
import { PrismaClient } from '@prisma/client';
import {
  getAllTaskAssignments,
  getSalesmanTaskAssignments,
  getMyTaskAssignments,
  getTaskAssignmentById,
  createTaskAssignment,
  updateTaskAssignment,
  deleteTaskAssignment,
  searchTaskAssignments,
} from '../controllers/taskAssignmentController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const prisma = new PrismaClient();
const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// GET /api/task-assignments - Get all task assignments (admin only)
router.get('/', getAllTaskAssignments);

// GET /api/task-assignments/search - Search task assignments by location
router.get('/search', searchTaskAssignments);

// GET /api/task-assignments/salesman/:salesmanId - Get task assignments for specific salesman
router.get('/salesman/:salesmanId', getSalesmanTaskAssignments);

// GET /api/task-assignments/my-assignments - Get task assignments for current authenticated user
router.get('/my-assignments', getMyTaskAssignments);

// GET /api/task-assignments/debug/:salesmanId - Debug endpoint to check data
router.get('/debug/:salesmanId', async (req, res) => {
  try {
    const { salesmanId } = req.params;

    // Get all task assignments
    const allAssignments = await prisma.taskAssignment.findMany({
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

// GET /api/task-assignments/:id - Get task assignment by ID
router.get('/:id', getTaskAssignmentById);

// POST /api/task-assignments - Create new task assignment
router.post('/', createTaskAssignment);

// PUT /api/task-assignments/:id - Update task assignment
router.put('/:id', updateTaskAssignment);

// DELETE /api/task-assignments/:id - Delete task assignment
router.delete('/:id', deleteTaskAssignment);

export default router;