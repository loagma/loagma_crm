import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
  getAllAccounts,
  getAccountById,
  createAccount,
  updateAccount,
  deleteAccount,
  approveAccount,
  teleadminVerifyAccount,
  rejectAccount,
  getAccountStats,
  bulkCreateAccounts,
  bulkAssignAccounts,
  bulkApproveAccounts,
  getWeeklyAssignmentsView,
  autoAssignNextUnassignedAccounts,
  manualAssignWeeklyAccounts,
  getPlanningWeekView,
  assignPlanningWeekAccounts,
  updatePlanningWeekAccount,
  getMultiVisitWeekAccounts,
  getTodayPlannedAccounts,
  unassignWeeklyAccountsGlobal,
  checkContactNumber,
  debugDateFiltering,
  getAccountCountByPincode,
} from '../controllers/accountController.js';
// import {  } from '../middleware/.js';

const router = express.Router();

router.use(authMiddleware);

// ==================== ACCOUNT ROUTES ====================
router.get('/', getAllAccounts);
router.get('/stats', getAccountStats);
router.get('/weekly/view', getWeeklyAssignmentsView);
router.get('/planning/week', getPlanningWeekView);
router.get('/planning/week/multi-visit', getMultiVisitWeekAccounts);
router.get('/planning/today', getTodayPlannedAccounts);
router.get('/debug-date-filtering', debugDateFiltering); // DEBUG ENDPOINT
router.post('/check-contact', checkContactNumber);
router.get('/pincode/:pincode/count', getAccountCountByPincode);
router.get('/:id', getAccountById);
router.post('/', createAccount);
router.put('/:id', updateAccount);
router.delete('/:id', deleteAccount);

// ==================== APPROVAL ROUTES ====================
router.post('/:id/approve', approveAccount);
router.post('/:id/teleadmin-verify', teleadminVerifyAccount);
router.post('/:id/reject', rejectAccount);

// ==================== BULK OPERATIONS ====================
router.post('/bulk', bulkCreateAccounts);
router.post('/bulk/assign', bulkAssignAccounts);
router.post('/bulk/approve', bulkApproveAccounts);
router.post('/weekly/auto-assign-next', autoAssignNextUnassignedAccounts);
router.post('/weekly/manual-assign', manualAssignWeeklyAccounts);
router.post('/weekly/unassign-global', unassignWeeklyAccountsGlobal);
router.post('/planning/week/assign', assignPlanningWeekAccounts);
router.patch('/planning/week/account/:accountId', updatePlanningWeekAccount);

export default router;
