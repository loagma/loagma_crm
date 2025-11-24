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
  bulkApproveAccounts,
  checkContactNumber
} from '../controllers/accountController.js';
// import {  } from '../middleware/.js';

const router = express.Router();

// ==================== ACCOUNT ROUTES ====================
router.get('/', getAllAccounts);
router.get('/stats',  getAccountStats);
router.post('/check-contact', checkContactNumber);
router.get('/:id',  getAccountById);
router.post('/', createAccount);
router.put('/:id',  updateAccount);
router.delete('/:id', deleteAccount);

// ==================== APPROVAL ROUTES ====================
router.post('/:id/approve',  approveAccount);
router.post('/:id/reject',  rejectAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk/assign',  bulkAssignAccounts);
router.post('/bulk/approve',  bulkApproveAccounts);

export default router;
