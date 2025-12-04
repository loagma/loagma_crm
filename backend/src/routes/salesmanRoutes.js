import express from 'express';
import {
  getAllAccounts,
  getAccountById,
  createAccount,
  updateAccount,
  getAccountStats
} from '../controllers/accountController.js';
import {
  getMyTaskAssignments,
  getTaskAssignmentStats
} from '../controllers/salesmanController.js';

const router = express.Router();

// ==================== SALESMAN ACCOUNT ROUTES ====================
// These routes automatically filter by createdById from auth middleware
router.get('/accounts', async (req, res, next) => {
  // Add createdById filter from authenticated user
  req.query.createdById = req.user?.id;
  return getAllAccounts(req, res, next);
});

router.get('/accounts/stats', async (req, res, next) => {
  // Add createdById filter from authenticated user
  req.query.createdById = req.user?.id;
  return getAccountStats(req, res, next);
});

router.get('/accounts/:id', getAccountById);
router.post('/accounts', createAccount);
router.put('/accounts/:id', updateAccount);

// ==================== SALESMAN TASK ASSIGNMENT ROUTES ====================
router.get('/assignments', getMyTaskAssignments);
router.get('/assignments/stats', getTaskAssignmentStats);

export default router;
