import express from 'express';
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

const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// GET /api/area-assignments - Get all area assignments (admin only)
router.get('/', getAllAreaAssignments);

// GET /api/area-assignments/search - Search area assignments by location
router.get('/search', searchAreaAssignments);

// GET /api/area-assignments/salesman/:salesmanId - Get area assignments for specific salesman
router.get('/salesman/:salesmanId', getSalesmanAreaAssignments);

// GET /api/area-assignments/:id - Get area assignment by ID
router.get('/:id', getAreaAssignmentById);

// POST /api/area-assignments - Create new area assignment
router.post('/', createAreaAssignment);

// PUT /api/area-assignments/:id - Update area assignment
router.put('/:id', updateAreaAssignment);

// DELETE /api/area-assignments/:id - Delete area assignment
router.delete('/:id', deleteAreaAssignment);

export default router;