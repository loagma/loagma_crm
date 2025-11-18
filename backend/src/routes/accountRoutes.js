import express from 'express';
import {
  getAllAccounts,
  getAccountById,
  createAccount,
  updateAccount,
  deleteAccount,
  approveAccount,
  rejectAccount,
  getAccountStats,
  bulkAssignAccounts,
  bulkApproveAccounts
} from '../controllers/accountController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// ==================== ACCOUNT ROUTES ====================
router.get('/', authMiddleware, getAllAccounts);
router.get('/stats', authMiddleware, getAccountStats);
router.get('/:id', authMiddleware, getAccountById);
router.post('/', authMiddleware, createAccount);
router.put('/:id', authMiddleware, updateAccount);
router.delete('/:id', authMiddleware, deleteAccount);

// ==================== APPROVAL ROUTES ====================
router.post('/:id/approve', authMiddleware, approveAccount);
router.post('/:id/reject', authMiddleware, rejectAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk/assign', authMiddleware, bulkAssignAccounts);
router.post('/bulk/approve', authMiddleware, bulkApproveAccounts);

export default router;
