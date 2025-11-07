import express from 'express';
import { createUser, getAllUsers } from '../controllers/userController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

// Only NSM can create users
router.post('/', authMiddleware, roleGuard(['NSM']), createUser);
router.get('/', authMiddleware, getAllUsers);

export default router;
