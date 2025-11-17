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
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// ==================== ACCOUNT ROUTES ====================
router.get('/', authenticateToken, getAllAccounts);
router.get('/stats', authenticateToken, getAccountStats);
router.get('/:id', authenticateToken, getAccountById);
router.post('/', authenticateToken, createAccount);
router.put('/:id', authenticateToken, updateAccount);
router.delete('/:id', authenticateToken, deleteAccount);

// ==================== APPROVAL ROUTES ====================
router.post('/:id/approve', authenticateToken, approveAccount);
router.post('/:id/reject', authenticateToken, rejectAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk/assign', authenticateToken, bulkAssignAccounts);
router.post('/bulk/approve', authenticateToken, bulkApproveAccounts);

export default router;
