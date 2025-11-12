import express from 'express';
import {
  getAllAccounts,
  getAccountById,
  createAccount,
  updateAccount,
  deleteAccount,
  getAccountStats,
  bulkAssignAccounts
} from '../controllers/accountController.js';

const router = express.Router();

// ==================== ACCOUNT ROUTES ====================
router.get('/', getAllAccounts);
router.get('/stats', getAccountStats);
router.get('/:id', getAccountById);
router.post('/', createAccount);
router.put('/:id', updateAccount);
router.delete('/:id', deleteAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk/assign', bulkAssignAccounts);

export default router;
