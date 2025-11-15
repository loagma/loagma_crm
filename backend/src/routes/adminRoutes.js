import express from 'express';
import {
  createUserByAdmin,
  getAllUsersByAdmin,
  updateUserByAdmin,
  deleteUserByAdmin,
} from '../controllers/adminController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

// Only Admin can access these routes
router.post('/users', authMiddleware, roleGuard(['Admin']), createUserByAdmin);
router.get('/users', authMiddleware, roleGuard(['Admin']), getAllUsersByAdmin);
router.put('/users/:id', authMiddleware, roleGuard(['Admin']), updateUserByAdmin);
router.delete('/users/:id', authMiddleware, roleGuard(['Admin']), deleteUserByAdmin);

export default router;
