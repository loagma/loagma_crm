import express from 'express';
import {
  createExpense,
  getMyExpenses,
  getAllExpenses,
  updateExpense,
  deleteExpense,
  updateExpenseStatus,
  getExpenseStatistics,
} from '../controllers/expenseController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Employee routes (requires authentication)
router.post('/expenses', authenticateToken, createExpense);
router.get('/expenses/my', authenticateToken, getMyExpenses);
router.get('/expenses/statistics', authenticateToken, getExpenseStatistics);
router.put('/expenses/:id', authenticateToken, updateExpense);
router.delete('/expenses/:id', authenticateToken, deleteExpense);

// Admin/Manager routes (requires authentication + admin role)
router.get('/expenses/all', authenticateToken, getAllExpenses);
router.patch('/expenses/:id/status', authenticateToken, updateExpenseStatus);

export default router;
