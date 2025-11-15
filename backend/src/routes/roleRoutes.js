import express from 'express';
import {
  getAllRoles,
  createRole,
  updateRole,
  deleteRole,
} from '../controllers/roleController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

// Only Admin can manage roles
// router.get('/', getAllRoles);
// router.post('/', authMiddleware, roleGuard(['Admin']), createRole);
// router.put('/:id', authMiddleware, roleGuard(['Admin']), updateRole);
// router.delete('/:id', authMiddleware, roleGuard(['Admin']), deleteRole);
router.get('/', getAllRoles);
router.post('/', authMiddleware,  createRole);
router.put('/:id', authMiddleware,  updateRole);
router.delete('/:id', authMiddleware,  deleteRole);

export default router;
