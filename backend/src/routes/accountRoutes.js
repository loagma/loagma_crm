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
  bulkCreateAccounts,
  bulkAssignAccounts,
  bulkApproveAccounts,
  getWeeklyAssignmentsView,
  autoAssignNextUnassignedAccounts,
  manualAssignWeeklyAccounts,
  checkContactNumber,
  debugDateFiltering,
  getAccountCountByPincode,
} from '../controllers/accountController.js';
// import {  } from '../middleware/.js';

const router = express.Router();

// ==================== ACCOUNT ROUTES ====================
router.get('/', getAllAccounts);
router.get('/stats', getAccountStats);
router.get('/weekly/view', getWeeklyAssignmentsView);
router.get('/debug-date-filtering', debugDateFiltering); // DEBUG ENDPOINT
router.post('/check-contact', checkContactNumber);
router.get('/pincode/:pincode/count', getAccountCountByPincode);
router.get('/:id', getAccountById);
router.post('/', createAccount);
router.put('/:id', updateAccount);
router.delete('/:id', deleteAccount);

// ==================== APPROVAL ROUTES ====================
router.post('/:id/approve', approveAccount);
router.post('/:id/reject', rejectAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk', bulkCreateAccounts);
router.post('/bulk/assign', bulkAssignAccounts);
router.post('/bulk/approve', bulkApproveAccounts);
router.post('/weekly/auto-assign-next', autoAssignNextUnassignedAccounts);
router.post('/weekly/manual-assign', manualAssignWeeklyAccounts);

export default router;
